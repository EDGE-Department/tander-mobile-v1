import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';

import 'package:tander_flutter_v3/features/calls/data/call_peer_state.dart';
import 'package:tander_flutter_v3/features/calls/data/datasources/call_signaling.dart';
import 'package:tander_flutter_v3/features/calls/domain/call_constants.dart';
import 'package:tander_flutter_v3/features/calls/domain/call_types.dart';
import 'package:tander_flutter_v3/features/calls/presentation/notifiers/call_notifier.dart';

/// Handles incoming WebRTC / call lifecycle signals.
///
/// Extracted from CallManager to keep the orchestrator under 400 lines.
/// Contains the signal dispatch switch and ICE state handler.
final class CallSignalHandler {
  CallSignalHandler({
    required Ref ref,
    required Future<void> Function(String roomName, String sdp) onProcessOffer,
    required Future<void> Function(String sdp) onProcessAnswer,
    required void Function(
      String reason,
      CallEndReason endReason, [
      String? errorMessage,
    ])
    onTerminate,
    required Future<void> Function() onCleanup,
    required void Function() onScheduleIdleReset,
    required void Function() onStartDurationTimer,
  }) : _ref = ref,
       _onProcessOffer = onProcessOffer,
       _onProcessAnswer = onProcessAnswer,
       _onTerminate = onTerminate,
       _onCleanup = onCleanup,
       _onScheduleIdleReset = onScheduleIdleReset,
       _onStartDurationTimer = onStartDurationTimer;

  final Ref _ref;
  final Future<void> Function(String roomName, String sdp) _onProcessOffer;
  final Future<void> Function(String sdp) _onProcessAnswer;
  final void Function(String, CallEndReason, [String?]) _onTerminate;
  final Future<void> Function() _onCleanup;
  final void Function() _onScheduleIdleReset;
  final void Function() _onStartDurationTimer;

  /// Routes an incoming signal event to the correct handler.
  void handleSignalEvent(CallSignalEvent event) {
    final callRefs = getCallRefs();
    final notifier = _ref.read(callNotifierProvider.notifier);

    switch (event) {
      case OfferEvent(:final roomName, :final sdp):
        if (callRefs.peer == null || !callRefs.peer!.isAlive) {
          callRefs.pendingOffer = BufferedOffer(roomName: roomName, sdp: sdp);
          return;
        }
        unawaited(_onProcessOffer(roomName, sdp));

      case AnswerEvent(:final sdp):
        if (callRefs.peer == null || !callRefs.peer!.isAlive) return;
        unawaited(_onProcessAnswer(sdp));

      case IceCandidateEvent(:final candidate):
        if (callRefs.peer != null &&
            callRefs.peer!.isAlive &&
            callRefs.peer!.hasRemoteDescription) {
          unawaited(callRefs.peer!.addIceCandidate(candidate));
        } else {
          callRefs.pendingIceCandidates.add(candidate);
        }

      case HangupEvent() || CallEndedEvent():
        unawaited(_onCleanup());
        notifier.endCall(CallEndReason.hangup);
        _onScheduleIdleReset();

      case BusyEvent():
        unawaited(_onCleanup());
        notifier.endCall(CallEndReason.busy);
        _onScheduleIdleReset();

      case CallCancelledEvent():
        unawaited(_onCleanup());
        notifier.endCall(CallEndReason.cancelled);
        _onScheduleIdleReset();

      case CallAnsweredElsewhereEvent():
        unawaited(_onCleanup());
        notifier.endCall(CallEndReason.answeredElsewhere);
        _onScheduleIdleReset();

      case CallDeclinedElsewhereEvent():
        unawaited(_onCleanup());
        notifier.endCall(CallEndReason.declinedElsewhere);
        _onScheduleIdleReset();

      case CallAnsweredEvent():
        clearCallTimers();
        notifier.setStatus(const CallConnecting());
        callRefs.timeoutTimer = Timer(CallTimeouts.connecting, () {
          final freshStatus = _ref.read(callNotifierProvider).status;
          if (freshStatus is CallConnecting) {
            _onTerminate(
              'timeout',
              CallEndReason.timeout,
              'Connection timed out',
            );
          }
        });

      case MediaStateEvent(:final audioMuted, :final videoOff):
        notifier.setRemoteMedia(
          RemoteMediaState(
            isAudioMuted: audioMuted ?? false,
            isVideoOff: videoOff ?? false,
          ),
        );

      case CallDeclinedEvent():
        unawaited(_onCleanup());
        notifier.endCall(CallEndReason.declined);
        _onScheduleIdleReset();

      case IncomingCallEvent():
        break; // Handled by CallListener
    }
  }

  /// Handles ICE connection state changes from the WebRTC peer.
  void handleIceStateChange(RTCIceConnectionState iceState) {
    final notifier = _ref.read(callNotifierProvider.notifier);

    switch (iceState) {
      case RTCIceConnectionState.RTCIceConnectionStateConnected ||
          RTCIceConnectionState.RTCIceConnectionStateCompleted:
        clearCallTimers();
        notifier.setStatus(const CallConnected());
        _onStartDurationTimer();

        final freshState = _ref.read(callNotifierProvider);
        if (freshState.callInfo != null) {
          sendMediaStateSignal(
            freshState.callInfo!.roomName,
            freshState.media.isMuted,
            !freshState.media.isCameraOn,
            freshState.callInfo!.remoteUserId,
          );
        }

      case RTCIceConnectionState.RTCIceConnectionStateDisconnected:
        notifier.setStatus(const CallReconnecting());

      case RTCIceConnectionState.RTCIceConnectionStateFailed:
        unawaited(_onCleanup());
        notifier.endCall(
          CallEndReason.failed,
          'Connection failed — please try again',
        );
        _onScheduleIdleReset();

      case RTCIceConnectionState.RTCIceConnectionStateNew ||
          RTCIceConnectionState.RTCIceConnectionStateChecking ||
          RTCIceConnectionState.RTCIceConnectionStateClosed ||
          RTCIceConnectionState.RTCIceConnectionStateCount:
        break;
    }
  }
}
