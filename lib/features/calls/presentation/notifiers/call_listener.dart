import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:tander_flutter_v3/core/realtime/stomp_client_manager.dart';
import 'package:tander_flutter_v3/core/utils/app_logger.dart';
import 'package:tander_flutter_v3/features/calls/data/call_peer_state.dart';
import 'package:tander_flutter_v3/features/calls/data/datasources/call_signaling.dart';
import 'package:tander_flutter_v3/features/calls/domain/call_constants.dart';
import 'package:tander_flutter_v3/features/calls/domain/call_types.dart';
import 'package:tander_flutter_v3/features/calls/presentation/notifiers/call_notifier.dart';
import 'package:tander_flutter_v3/features/calls/presentation/providers/call_providers.dart';
import 'package:tander_flutter_v3/features/calls/presentation/states/call_state.dart';
import 'package:tander_flutter_v3/features/messaging/presentation/providers/messaging_providers.dart';

// ---------------------------------------------------------------------------
// Provider — mount once at app root (AppShell or OnboardingGuard)
// ---------------------------------------------------------------------------

final callListenerProvider = Provider<CallListener>((ref) {
  final callListener = CallListener(ref: ref);
  callListener.start();

  ref.onDispose(callListener.dispose);
  return callListener;
});

// ---------------------------------------------------------------------------
// Listener
// ---------------------------------------------------------------------------

/// Global incoming call STOMP listener.
///
/// Subscribes to call lifecycle events (incoming_call, call_cancelled, etc.)
/// on both topic and queue destinations. Mounts once at the app root and
/// stays active for the entire authenticated session.
///
/// Key behaviors:
/// - Sends "busy" if already in a call when incoming_call arrives.
/// - Normalizes backend callType ("voice"/"video") to [CallType].
/// - Early-subscribes to room signals so SDP offer is buffered before Accept.
/// - Sends ring acknowledgment back to the caller.
/// - Auto-dismisses ringing after [CallTimeouts.ringing].
final class CallListener {
  CallListener({required Ref ref}) : _ref = ref;

  static const String _tag = 'CallListener';

  final Ref _ref;
  StompUnsubscribeCallback? _callEventUnsub;
  StompUnsubscribeCallback? _earlySignalUnsub;
  Timer? _ringingTimeout;

  void start() {
    final userId = _ref.read(currentUserIdProvider);

    _callEventUnsub = subscribeToCallEvents(userId, _handleCallEvent);

    // Check for active incoming calls on boot (push recovery)
    _checkForActiveIncomingCall();

    AppLogger.info(
      'Call listener started',
      operation: _tag,
      context: {'userId': userId},
    );
  }

  /// Check backend for an active incoming call that was pushed while
  /// the app was closed. If found, inject the call state so the overlay shows.
  Future<void> _checkForActiveIncomingCall() async {
    try {
      final datasource = _ref.read(callsRemoteDatasourceProvider);
      final activeCall = await datasource.getActiveIncomingCall();
      if (activeCall == null) return;

      final currentState = _ref.read(callNotifierProvider);
      if (currentState.status is! CallIdle) return;

      final roomName = activeCall['roomName'] as String? ?? '';
      if (roomName.isEmpty) return;

      final callerName = activeCall['callerName'] as String? ?? 'Unknown';
      final callerPhoto = activeCall['callerPhoto'] as String?;
      final rawCallType = (activeCall['callType'] as String? ?? 'audio')
          .toUpperCase();
      final callType = CallType.fromBackend(rawCallType);
      final callerId = (activeCall['callerId'] ?? '').toString();
      final callerUsername =
          activeCall['callerUsername'] as String? ?? callerName;

      final callInfo = CallInfo(
        callId: roomName,
        roomName: roomName,
        callType: callType,
        direction: CallDirection.incoming,
        remoteUserId: callerId,
        remoteUsername: callerUsername,
        remotePhotoUrl: callerPhoto,
      );

      final notifier = _ref.read(callNotifierProvider.notifier);
      notifier.setCallInfo(callInfo);
      notifier.setStatus(const CallRinging());

      // Send ring ack to caller
      sendRingAck(roomName, callerId);

      // Start ringing timeout
      _ringingTimeout?.cancel();
      _ringingTimeout = Timer(CallTimeouts.ringing, () {
        final state = _ref.read(callNotifierProvider);
        if (state.status is CallRinging &&
            state.callInfo?.roomName == roomName) {
          _ref
              .read(callNotifierProvider.notifier)
              .endCall(CallEndReason.noAnswer);
          Future<void>.delayed(CallTimeouts.endedDisplay, () {
            try {
              _ref.read(callNotifierProvider.notifier).resetToIdle();
            } catch (_) {}
          });
        }
      });

      AppLogger.info(
        'Recovered active incoming call from backend',
        operation: _tag,
        context: {'roomName': roomName, 'callerName': callerName},
      );
    } catch (error) {
      // Best-effort — endpoint may not exist yet
      AppLogger.debug(
        'Active call check failed (expected if no active call)',
        operation: _tag,
      );
    }
  }

  /// Unsubscribes the early room signal subscription.
  /// Must be called when the call is accepted so that CallSetup's
  /// subscription can receive ICE candidates without dedup conflicts.
  void cancelEarlySignalSubscription() {
    _earlySignalUnsub?.call();
    _earlySignalUnsub = null;
    _ringingTimeout?.cancel();
    _ringingTimeout = null;
    AppLogger.debug('Early signal subscription cancelled', operation: _tag);
  }

  void dispose() {
    _callEventUnsub?.call();
    _callEventUnsub = null;
    _earlySignalUnsub?.call();
    _earlySignalUnsub = null;
    _ringingTimeout?.cancel();
    _ringingTimeout = null;

    AppLogger.info('Call listener disposed', operation: _tag);
  }

  // -----------------------------------------------------------------------
  // Event dispatch
  // -----------------------------------------------------------------------

  void _handleCallEvent(CallSignalEvent event) {
    final notifier = _ref.read(callNotifierProvider.notifier);
    final currentState = _ref.read(callNotifierProvider);

    switch (event) {
      case IncomingCallEvent(:final payload):
        _handleIncomingCall(payload, currentState, notifier);

      case CallAnsweredEvent(:final roomName):
        _handleCallAnswered(roomName, currentState, notifier);

      case CallDeclinedEvent(:final roomName):
        _handleDismissEvent(
          roomName,
          currentState,
          notifier,
          CallEndReason.declined,
        );

      case CallCancelledEvent(:final roomName):
        _handleDismissEvent(
          roomName,
          currentState,
          notifier,
          CallEndReason.cancelled,
        );

      case CallAnsweredElsewhereEvent(:final roomName):
        // Ignore if WE are the one who answered (our own accept triggers this)
        if ((currentState.status is CallConnecting ||
                currentState.status is CallConnected) &&
            currentState.callInfo?.direction == CallDirection.incoming &&
            currentState.callInfo?.roomName == roomName) {
          AppLogger.debug(
            'Ignoring call_answered_elsewhere — we answered this call',
            operation: _tag,
          );
          break;
        }
        _handleDismissEvent(
          roomName,
          currentState,
          notifier,
          CallEndReason.answeredElsewhere,
        );

      case CallDeclinedElsewhereEvent(:final roomName):
        _handleDismissEvent(
          roomName,
          currentState,
          notifier,
          CallEndReason.declinedElsewhere,
        );

      case CallEndedEvent(:final roomName):
        _handleDismissEvent(
          roomName,
          currentState,
          notifier,
          CallEndReason.hangup,
        );

      // Room-level signals are handled by CallManager, not the listener
      case OfferEvent() ||
          AnswerEvent() ||
          IceCandidateEvent() ||
          HangupEvent() ||
          BusyEvent() ||
          MediaStateEvent():
        break;
    }
  }

  // -----------------------------------------------------------------------
  // Incoming call
  // -----------------------------------------------------------------------

  void _handleIncomingCall(
    StompIncomingCallPayload payload,
    CallState currentState,
    CallNotifier notifier,
  ) {
    final userId = _ref.read(currentUserIdProvider);

    // Already in a call — send busy
    if (currentState.status is! CallIdle) {
      final callerId = payload.callerId ?? payload.userId ?? '';
      sendBusy(payload.roomName, callerId);
      AppLogger.debug(
        'Incoming call rejected (busy)',
        operation: _tag,
        context: {'roomName': payload.roomName},
      );
      return;
    }

    final callerId = payload.callerId ?? payload.userId ?? '';
    final callerName =
        payload.callerName ?? payload.callerUsername ?? 'Unknown';
    final callerPhoto = payload.callerPhotoUrl ?? payload.callerPhoto;

    // Ignore self-calls
    if (callerId == userId) return;

    // Normalize backend callType ("voice"/"video") to CallType
    final normalizedCallType = CallType.fromBackend(
      payload.callType ?? 'AUDIO',
    );

    final callInfo = CallInfo(
      callId: payload.callId ?? payload.roomName,
      roomName: payload.roomName,
      callType: normalizedCallType,
      direction: CallDirection.incoming,
      remoteUserId: callerId,
      remoteUsername: callerName,
      remotePhotoUrl: callerPhoto,
    );

    notifier.setCallInfo(callInfo);
    notifier.setStatus(const CallRinging());

    // Early-subscribe to room signals so the SDP offer AND ICE candidates
    // are buffered before the user taps Accept.
    _earlySignalUnsub?.call();
    _earlySignalUnsub = subscribeToRoomSignals(payload.roomName, userId, (
      signalEvent,
    ) {
      if (signalEvent is OfferEvent) {
        setPendingOfferBuffer(
          BufferedOffer(roomName: signalEvent.roomName, sdp: signalEvent.sdp),
        );
      } else if (signalEvent is IceCandidateEvent) {
        // Buffer ICE candidates so they can be flushed after accept
        getCallRefs().pendingIceCandidates.add(signalEvent.candidate);
      }
    });

    // Send ring acknowledgment
    sendRingAck(payload.roomName, callerId);

    // Start ringing timeout
    _ringingTimeout?.cancel();
    _ringingTimeout = Timer(CallTimeouts.ringing, () {
      final freshState = _ref.read(callNotifierProvider);
      if (freshState.status is CallRinging &&
          freshState.callInfo?.roomName == payload.roomName) {
        _ref
            .read(callNotifierProvider.notifier)
            .endCall(CallEndReason.noAnswer);
        _scheduleIdleReset();
      }
      _ringingTimeout = null;
    });

    AppLogger.info(
      'Incoming call from $callerName',
      operation: _tag,
      context: {
        'roomName': payload.roomName,
        'callType': normalizedCallType.backendValue,
      },
    );
  }

  // -----------------------------------------------------------------------
  // Call answered (caller side — transition from ringing to connecting)
  // -----------------------------------------------------------------------

  void _handleCallAnswered(
    String roomName,
    CallState currentState,
    CallNotifier notifier,
  ) {
    if (currentState.status is CallRinging &&
        currentState.callInfo?.direction == CallDirection.outgoing) {
      notifier.setStatus(const CallConnecting());
    }
  }

  // -----------------------------------------------------------------------
  // Dismiss events (cancelled, declined, answered elsewhere, ended)
  // -----------------------------------------------------------------------

  void _handleDismissEvent(
    String roomName,
    CallState currentState,
    CallNotifier notifier,
    CallEndReason reason,
  ) {
    _cancelRingingTimeout();

    if (currentState.callInfo?.roomName == roomName) {
      notifier.endCall(reason);
      _scheduleIdleReset();
    }
  }

  // -----------------------------------------------------------------------
  // Helpers
  // -----------------------------------------------------------------------

  void _cancelRingingTimeout() {
    _ringingTimeout?.cancel();
    _ringingTimeout = null;
  }

  void _scheduleIdleReset() {
    Future<void>.delayed(CallTimeouts.endedDisplay, () {
      try {
        _ref.read(callNotifierProvider.notifier).resetToIdle();
      } on Exception {
        // Provider may have been disposed during the delay
      }
    });
  }
}
