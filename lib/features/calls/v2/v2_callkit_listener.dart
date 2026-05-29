import 'dart:async';
import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:flutter_callkit_incoming/entities/entities.dart';
import 'package:flutter_callkit_incoming/flutter_callkit_incoming.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:tander_flutter_v3/core/utils/app_logger.dart';
import 'package:tander_flutter_v3/features/calls/data/datasources/calls_v2_remote_datasource.dart';
import 'package:tander_flutter_v3/features/calls/domain/pending_cold_start_call.dart';
import 'package:tander_flutter_v3/features/calls/services/call_push_bridge.dart';
import 'package:tander_flutter_v3/features/calls/services/twilio_native_bridge.dart';
import 'package:tander_flutter_v3/features/calls/v2/v2_active_call_state.dart';

/// Bridges `flutter_callkit_incoming` events into the Phase-5 v2 call path.
///
/// When an FCM data-only `incoming_call` push arrives, [CallPushBridge]
/// shows the CallKit/ConnectionService UI. The user's accept/decline
/// surfaces here as a [CallEvent]. We:
///   1. Read v2 fields from the event's `extra` dict (primary) or
///      [PendingColdStartCall] persisted by [CallPushBridge] (fallback
///      when plugin state was lost across a cold start).
///   2. Call the appropriate v2 endpoint:
///      - Accept (in-app, user logged in) → [CallsV2RemoteDatasource.accept]
///      - Accept (action-token if available) → [CallsV2RemoteDatasource.acceptAction]
///      - Decline → [CallsV2RemoteDatasource.decline] (or [declineAction])
///   3. On accept success, connect Twilio via [TwilioNativeBridge].
///
/// Lifecycle: [start] in app bootstrap (after Riverpod is up); call
/// [stop] on tear-down. Idempotent — calling [start] twice is a no-op.
final class V2CallkitListener {
  V2CallkitListener({
    required CallsV2RemoteDatasource datasource,
    required V2ActiveCallNotifier activeCall,
  }) : _datasource = datasource,
       _activeCall = activeCall;

  final CallsV2RemoteDatasource _datasource;
  final V2ActiveCallNotifier _activeCall;
  StreamSubscription<CallEvent?>? _sub;
  StreamSubscription<TwilioRoomEvent>? _twilioSub;

  /// Channel to the native cold-start capture (MainActivity stores the
  /// ACTION_CALL_ACCEPT launch-intent flag; we consume it once on boot).
  static const _coldStartChannel = MethodChannel('com.tander.app/coldstart');

  /// Begin listening. Safe to call multiple times — second call is a no-op.
  void start() {
    if (_sub != null) return;
    _sub = FlutterCallkitIncoming.onEvent.listen(
      _handleEvent,
      onError: (Object e) => AppLogger.warning(
        'onEvent error: $e',
        operation: 'V2CallkitListener',
      ),
    );
    // Notification "Hang Up" (CallStyle, fired while the user is outside the
    // app) surfaces as a HangUpRequested on the Twilio bridge. Handle it here
    // because we hold the datasource (backend end) + the active-call notifier.
    _twilioSub = TwilioNativeBridge.instance.events.listen((event) {
      if (event is HangUpRequested) {
        unawaited(_onNotificationHangUp());
      }
    });
    AppLogger.debug('listening', operation: 'V2CallkitListener.start');
  }

  Future<void> stop() async {
    await _sub?.cancel();
    _sub = null;
    await _twilioSub?.cancel();
    _twilioSub = null;
  }

  /// The CallStyle notification's Hang Up button was tapped (outside the app).
  /// Mirror the in-call hangup button: tell the backend the call ended,
  /// disconnect Twilio, and clear the UI. The backend end is load-bearing —
  /// without it user_call_state stays pinned (caller-busy lockout; no sweeper).
  Future<void> _onNotificationHangUp() async {
    final call = _activeCall.current;
    if (call == null) {
      // Already torn down — just make sure Twilio is down.
      try {
        await TwilioNativeBridge.instance.disconnect();
      } catch (_) {}
      return;
    }
    AppLogger.info(
      'notification hangup callId=${call.callId}',
      operation: 'V2CallkitListener._onNotificationHangUp',
    );
    // Disconnect first so the media stops instantly (matches the in-call
    // hangup button), then settle the backend with the callId captured above.
    try {
      await TwilioNativeBridge.instance.disconnect();
    } catch (_) {}
    try {
      await _datasource.end(call.callId, reason: 'user_hangup');
    } catch (e) {
      AppLogger.warning(
        'notification hangup backend end failed: $e',
        operation: 'V2CallkitListener._onNotificationHangUp',
      );
    }
    _activeCall.clear();
  }

  String _callkitId(CallEvent event) {
    final body = event.body;
    if (body is Map) {
      final id = body['id'];
      if (id is String) return id;
    }
    return '';
  }

  Future<void> _handleEvent(CallEvent? event) async {
    if (event == null) return;
    AppLogger.debug(
      'event ${event.event}',
      operation: 'V2CallkitListener._handleEvent',
      context: {'body': event.body.toString()},
    );

    switch (event.event) {
      case Event.actionCallAccept:
        await _onAccept(event);
      case Event.actionCallDecline:
        await _onDecline(event);
      case Event.actionCallEnded:
        // CallKit "ended" fires when WE dismiss the notification after accept
        // (and once per duplicate push — so several times). It must NOT drive a
        // Twilio disconnect, or dismissing the notification kills the call we
        // just connected (the cold-start "connects then instantly drops" bug).
        // Real teardown comes from the in-call hangup + WPS terminal events.
        AppLogger.debug(
          'actionCallEnded — ignored (no auto-disconnect)',
          operation: 'V2CallkitListener._handleEvent',
        );
      case Event.actionCallTimeout:
        await _onTerminal(event);
      // Other events (incoming/start/toggleMute/etc) — not relevant to
      // v2 lifecycle bridging today.
      default:
        break;
    }
  }

  Future<void> _onAccept(CallEvent event) async {
    final v2 = await _resolveV2Context(event);
    if (v2 == null) {
      AppLogger.warning(
        'accept event without v2 callId; ignoring (legacy push)',
        operation: 'V2CallkitListener._onAccept',
      );
      return;
    }

    // Suppress any late duplicate incoming-call FCM push for this call.
    unawaited(CallPushBridge.markCallHandled(v2.callId));

    // Mic permission gate — CallKit-accept path. Without this,
    // LocalAudioTrack.create throws "RECORD_AUDIO permission must be granted"
    // and the call hangs forever on "Connecting…". The in-app overlay path
    // already gated this; the CallKit path didn't.
    final micStatus = await Permission.microphone.request();
    if (!micStatus.isGranted) {
      AppLogger.warning(
        'mic permission denied; cannot connect',
        operation: 'V2CallkitListener._onAccept',
      );
      await FlutterCallkitIncoming.endCall(_callkitId(event));
      return;
    }
    if (v2.callType.toLowerCase() == 'video') {
      // Best-effort — native falls back to audio-only if camera is denied.
      await Permission.camera.request();
    }

    try {
      final acceptToken = v2.acceptToken;
      final accept = acceptToken != null
          ? await _datasource.acceptAction(v2.callId, acceptToken)
          : await _datasource.accept(v2.callId);

      AppLogger.debug(
        'accept OK accepted=${accept.accepted} outcome=${accept.outcome}',
        operation: 'V2CallkitListener._onAccept',
      );

      if (!accept.accepted) {
        AppLogger.warning(
          'accept refused outcome=${accept.outcome}',
          operation: 'V2CallkitListener._onAccept',
        );
        await FlutterCallkitIncoming.endCall(_callkitId(event));
        return;
      }

      final twilioToken = accept.twilioToken;
      final roomName = accept.roomName;
      if (twilioToken == null || roomName == null) {
        AppLogger.warning(
          'accept lacked twilioToken/roomName; cannot connect',
          operation: 'V2CallkitListener._onAccept',
        );
        return;
      }

      // Surface the non-blocking active-call banner (CallKit-answer path).
      _activeCall.start(
        callId: v2.callId,
        roomName: roomName,
        peerName: v2.callerName,
        callType: v2.callType,
        peerPhotoUrl: v2.callerPhotoUrl,
      );

      await TwilioNativeBridge.instance.connect(
        roomName: roomName,
        twilioToken: twilioToken,
        isAudioOnly: v2.callType.toLowerCase() != 'video',
        peerName: v2.callerName,
      );
      // Dismiss the CallKit notification on the SAME callkit id we already
      // used. (`endCall` fires actionCallEnded, which we now ignore for
      // disconnect — see _handleEvent.)
      await FlutterCallkitIncoming.endCall(_callkitId(event));
    } catch (e, st) {
      AppLogger.warning(
        'accept failed: $e\n$st',
        operation: 'V2CallkitListener._onAccept',
      );
      _activeCall.clear(); // don't leave the UI stuck on "Connecting…"
      await FlutterCallkitIncoming.endCall(_callkitId(event));
    }
  }

  /// Consume a cold-start accept captured natively (the app was launched by
  /// tapping Accept while killed; the onEvent accept fired before we could
  /// subscribe, so it was missed). Called from app bootstrap once the session
  /// is authenticated. Idempotent — the native flag is cleared on read.
  Future<void> consumeColdStartFromNative() async {
    final bool accepted;
    try {
      accepted =
          await _coldStartChannel.invokeMethod<bool>('consumeAccept') ?? false;
    } on Object catch (e) {
      AppLogger.warning(
        'cold-start consume failed: $e',
        operation: 'V2CallkitListener.consumeColdStartFromNative',
      );
      return;
    }
    if (!accepted) return;

    final metadata = await CallPushBridge.readPersistedMetadata();
    // Don't gate on isV2 — that requires an acceptToken, which the push
    // currently lacks (device-FK mint gap). We only need the callId; the
    // accept goes through the session (datasource.accept), not the token.
    if (metadata == null || metadata.callId == null) {
      AppLogger.warning(
        'cold-start accept but no callId in metadata',
        operation: 'V2CallkitListener.consumeColdStartFromNative',
      );
      return;
    }
    if (metadata.isStale) {
      await CallPushBridge.clearPersistedMetadata();
      return;
    }
    await processColdStartPending(metadata);
    await CallPushBridge.clearPersistedMetadata();
  }

  /// Accept + connect from persisted cold-start metadata (parallels
  /// [_onAccept], but driven by the metadata instead of a CallEvent).
  Future<void> processColdStartPending(PendingColdStartCall pending) async {
    final callId = pending.callId;
    if (callId == null) return;
    AppLogger.info(
      'cold-start accept callId=$callId',
      operation: 'V2CallkitListener.processColdStartPending',
    );
    unawaited(CallPushBridge.markCallHandled(callId));

    final micStatus = await Permission.microphone.request();
    if (!micStatus.isGranted) {
      AppLogger.warning(
        'mic denied; cannot connect (cold start)',
        operation: 'V2CallkitListener.processColdStartPending',
      );
      await FlutterCallkitIncoming.endAllCalls();
      return;
    }
    if (pending.callType.toLowerCase() == 'video') {
      await Permission.camera.request();
    }

    try {
      final acceptToken = pending.acceptToken;
      final accept = acceptToken != null
          ? await _datasource.acceptAction(callId, acceptToken)
          : await _datasource.accept(callId);
      if (!accept.accepted) {
        AppLogger.warning(
          'cold-start accept refused outcome=${accept.outcome}',
          operation: 'V2CallkitListener.processColdStartPending',
        );
        await FlutterCallkitIncoming.endAllCalls();
        return;
      }
      final twilioToken = accept.twilioToken;
      final roomName = accept.roomName;
      if (twilioToken == null || roomName == null) {
        AppLogger.warning(
          'cold-start accept lacked twilioToken/roomName',
          operation: 'V2CallkitListener.processColdStartPending',
        );
        return;
      }
      _activeCall.start(
        callId: callId,
        roomName: roomName,
        peerName: pending.callerName,
        callType: pending.callType,
        peerPhotoUrl: pending.callerPhoto,
      );
      await TwilioNativeBridge.instance.connect(
        roomName: roomName,
        twilioToken: twilioToken,
        isAudioOnly: pending.callType.toLowerCase() != 'video',
        peerName: pending.callerName,
      );
      // Clear the lingering CallKit notification from the cold-start launch.
      await FlutterCallkitIncoming.endAllCalls();
    } catch (e, st) {
      AppLogger.warning(
        'cold-start accept failed: $e\n$st',
        operation: 'V2CallkitListener.processColdStartPending',
      );
      _activeCall.clear();
      await FlutterCallkitIncoming.endAllCalls();
    }
  }

  Future<void> _onDecline(CallEvent event) async {
    final v2 = await _resolveV2Context(event);
    if (v2 == null) return;
    unawaited(CallPushBridge.markCallHandled(v2.callId));
    try {
      final token = v2.declineToken;
      if (token != null) {
        await _datasource.declineAction(v2.callId, token);
      } else {
        await _datasource.decline(v2.callId, reason: 'user_declined');
      }
      AppLogger.debug('decline OK', operation: 'V2CallkitListener._onDecline');
    } catch (e) {
      AppLogger.warning(
        'decline failed: $e',
        operation: 'V2CallkitListener._onDecline',
      );
    }
  }

  Future<void> _onTerminal(CallEvent event) async {
    // Best-effort cleanup — the call may already be ended by either party.
    // Twilio side gets disconnected; backend call state may be stale and
    // settled by the timeout sweeper. No REST call needed unless we want
    // to short-circuit; skip for MVP.
    try {
      await TwilioNativeBridge.instance.disconnect();
    } catch (_) {}
  }

  /// Pulls v2 fields out of either the CallKit event extras (warm path)
  /// or [PendingColdStartCall] persistence (cold-start fallback).
  /// Returns null when neither carries a v2 callId — caller treats as
  /// legacy notification, leaves it alone.
  Future<_V2CallContext?> _resolveV2Context(CallEvent event) async {
    // Warm path — extras dict carries what we put in CallKitParams.extra.
    final body = event.body;
    final extra = body is Map ? body['extra'] : null;
    if (extra is Map) {
      final m = Map<String, dynamic>.from(extra);
      final callId = m['callId'] as String?;
      if (callId != null && callId.isNotEmpty) {
        return _V2CallContext(
          callId: callId,
          callType: (m['callType'] as String?) ?? 'audio',
          roomName: (m['roomId'] as String?) ?? 'tander-call-$callId',
          callerName:
              (event.body is Map
                  ? (event.body as Map)['nameCaller'] as String?
                  : null) ??
              'Caller',
          callerPhotoUrl: m['callerPhoto'] as String?,
          acceptToken: m['acceptToken'] as String?,
          declineToken: m['declineToken'] as String?,
          dismissToken: m['dismissToken'] as String?,
        );
      }
    }
    // Cold-start fallback — SharedPreferences metadata persisted by
    // CallPushBridge.persistCallMetadata when push arrived.
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.reload();
      final json = prefs.getString(kPendingCallMetadataKey);
      if (json == null) return null;
      final pending = PendingColdStartCall.fromMap(
        jsonDecode(json) as Map<String, dynamic>,
      );
      if (!pending.isV2 || pending.callId == null) return null;
      return _V2CallContext(
        callId: pending.callId!,
        callType: pending.callType,
        roomName: pending.roomId,
        callerName: pending.callerName,
        callerPhotoUrl: pending.callerPhoto,
        acceptToken: pending.acceptToken,
        declineToken: pending.declineToken,
        dismissToken: pending.dismissToken,
      );
    } catch (e) {
      AppLogger.warning(
        'SharedPrefs cold-start fallback failed: $e',
        operation: 'V2CallkitListener._resolveV2Context',
      );
      return null;
    }
  }
}

class _V2CallContext {
  const _V2CallContext({
    required this.callId,
    required this.callType,
    required this.roomName,
    required this.callerName,
    this.callerPhotoUrl,
    this.acceptToken,
    this.declineToken,
    this.dismissToken,
  });
  final String callId;
  final String callType;
  final String roomName;
  final String callerName;
  final String? callerPhotoUrl;
  final String? acceptToken;
  final String? declineToken;
  final String? dismissToken;
}
