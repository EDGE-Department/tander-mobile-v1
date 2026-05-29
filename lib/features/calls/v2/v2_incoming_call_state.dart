import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:tander_flutter_v3/core/auth/session_manager.dart';
import 'package:tander_flutter_v3/core/providers/core_providers.dart';
import 'package:tander_flutter_v3/core/realtime/wps_client.dart';
import 'package:tander_flutter_v3/core/utils/app_logger.dart';
import 'package:tander_flutter_v3/features/calls/services/call_push_bridge.dart';

/// In-flight v2 incoming call. Populated from a WPS CALL_RINGING envelope
/// when the local user is the callee. Cleared on any terminal event.
class V2IncomingCall {
  const V2IncomingCall({
    required this.callId,
    required this.roomName,
    required this.callType,
    required this.callerUserId,
    required this.callerName,
    this.callerPhotoUrl,
  });

  /// Real UUID — what `/api/v2/calls/{callId}/accept` uses.
  final String callId;
  final String roomName;

  /// 'AUDIO' or 'VIDEO'.
  final String callType;
  final String callerUserId;
  final String callerName;
  final String? callerPhotoUrl;
}

/// Riverpod state notifier that subscribes to [WpsClient] events,
/// translates `CALL_RINGING` envelopes to a [V2IncomingCall], and clears
/// state on terminal events.
///
/// Mirrors the web's `useCallListener` in `tander-web/src/modules/calls/
/// hooks/use-call-listener.ts` — same WPS event types, same self-call
/// ignore guard, but Flutter-shaped.
class V2IncomingCallNotifier extends StateNotifier<V2IncomingCall?> {
  V2IncomingCallNotifier({required WpsClient wps, SessionManager? session})
    : _session = session,
      super(null) {
    _unsubscribe = wps.addEventListener(_onEnvelope);
  }

  final SessionManager? _session;
  void Function()? _unsubscribe;

  void _onEnvelope(WpsEnvelope env) {
    final type = (env['type'] as String?)?.toUpperCase();
    if (type == null) return;
    final callId = env['callId'] as String?;

    switch (type) {
      case 'CALL_RINGING':
      case 'INCOMING_CALL':
        _handleRinging(env);
      case 'CALL_CANCELLED':
      case 'CALL_DECLINED':
      case 'CALL_ENDED':
      case 'CALL_MISSED':
      case 'CALL_FAILED':
      case 'CALL_ANSWERED_ELSEWHERE':
      case 'CALL_DECLINED_ELSEWHERE':
      // CALL_ACCEPTING/CONNECTING/ACTIVE also clear the incoming-call
      // state because they mean someone (this device or another)
      // already accepted — the ringing UX is no longer valid. Without
      // this, a late FCM push arriving after WPS-driven accept would
      // re-render CallKit over an already-active call.
      case 'CALL_ACCEPTING':
      case 'CALL_CONNECTING':
      case 'CALL_ACTIVE':
        if (callId != null && state?.callId == callId) {
          final roomName = state!.roomName;
          AppLogger.debug(
            'clearing incoming on $type for callId=$callId',
            operation: 'V2IncomingCallNotifier',
          );
          state = null;
          // Dismiss any pending CallKit/system notification for this
          // call. Covers the race where WPS delivered the terminal/
          // accepting event before a slow FCM push could reach the
          // device — without this, the late push would render an
          // orphan ring notification.
          unawaited(CallPushBridge.dismissNativeCallUI(roomName));
        }
    }
  }

  void _handleRinging(WpsEnvelope env) {
    final callId = env['callId'] as String?;
    final roomName = env['roomName'] as String?;
    // v2 envelopes use actorUserId for caller on CALL_RINGING; tolerate
    // legacy/alternative key names defensively.
    final callerUserId =
        (env['actorUserId'] as String?) ??
        (env['callerUserId'] as String?) ??
        (env['callerId'] as String?);
    if (callId == null || roomName == null || callerUserId == null) {
      AppLogger.warning(
        'CALL_RINGING missing required fields',
        operation: 'V2IncomingCallNotifier._handleRinging',
        context: <String, Object>{
          'callId': callId ?? '(null)',
          'roomName': roomName ?? '(null)',
          'callerUserId': callerUserId ?? '(null)',
        },
      );
      return;
    }

    // Self-call echo guard (multi-device user calling themselves shouldn't
    // ring on the originating device).
    final localUserId = _session?.session?.userId;
    if (localUserId != null && callerUserId == localUserId) {
      AppLogger.debug(
        'self-call echo ignored',
        operation: 'V2IncomingCallNotifier',
      );
      return;
    }

    // Drop duplicates — already showing this call.
    if (state?.callId == callId) return;

    final callType = ((env['callType'] as String?) ?? 'AUDIO').toUpperCase();
    final callerName = (env['callerName'] as String?) ?? 'Unknown';
    final callerPhotoUrl =
        (env['callerPhotoUrl'] as String?) ?? (env['callerPhoto'] as String?);

    AppLogger.info(
      'incoming v2 call ringing',
      operation: 'V2IncomingCallNotifier',
      context: {
        'callId': callId,
        'callerName': callerName,
        'callType': callType,
      },
    );

    state = V2IncomingCall(
      callId: callId,
      roomName: roomName,
      callType: callType == 'VIDEO' ? 'VIDEO' : 'AUDIO',
      callerUserId: callerUserId,
      callerName: callerName,
      callerPhotoUrl: callerPhotoUrl,
    );
  }

  /// Clear state (called after Accept/Decline triggers the REST action).
  void clear() {
    state = null;
  }

  @override
  void dispose() {
    _unsubscribe?.call();
    _unsubscribe = null;
    super.dispose();
  }
}

/// Provider — exposes the current incoming v2 call (null if none).
///
/// The auth state listener in TanderApp ensures WpsClient.connect only
/// fires when AuthAuthenticated, so by the time CALL_RINGING arrives
/// sessionManagerLateProvider is populated. If still null (very brief
/// bootstrap window), self-call guard is skipped — harmless.
final v2IncomingCallProvider =
    StateNotifierProvider<V2IncomingCallNotifier, V2IncomingCall?>((ref) {
      return V2IncomingCallNotifier(
        wps: ref.watch(wpsClientProvider),
        session: ref.watch(sessionManagerLateProvider),
      );
    });
