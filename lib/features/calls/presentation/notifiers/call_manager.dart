import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';

import 'package:tander_flutter_v3/features/calls/data/call_peer_state.dart';
import 'package:tander_flutter_v3/features/calls/data/datasources/call_signaling.dart';
import 'package:tander_flutter_v3/features/calls/data/datasources/webrtc_peer.dart';
import 'package:tander_flutter_v3/features/calls/domain/call_constants.dart';
import 'package:tander_flutter_v3/features/calls/domain/call_types.dart';
import 'package:tander_flutter_v3/features/calls/presentation/notifiers/call_notifier.dart';
import 'package:tander_flutter_v3/features/calls/presentation/notifiers/call_setup.dart';
import 'package:tander_flutter_v3/features/calls/presentation/notifiers/call_signal_handler.dart';
import 'package:tander_flutter_v3/features/calls/presentation/providers/call_providers.dart';

// ---------------------------------------------------------------------------
// Provider
// ---------------------------------------------------------------------------

final callManagerProvider = Provider<CallManager>((ref) {
  return CallManager(ref: ref);
});

// ---------------------------------------------------------------------------
// Manager — thin orchestrator delegating to CallSetup + CallSignalHandler
// ---------------------------------------------------------------------------

/// Main call orchestrator — wires WebRTC peer + STOMP signaling + state.
///
/// Mirrors the web's useCallManager lifecycle:
///   Idle -> Initiating -> Ringing -> Connecting -> Connected -> Ended
///
/// Delegates setup to [CallSetup] and signal routing to [CallSignalHandler].
final class CallManager {
  CallManager({required Ref ref}) : _ref = ref {
    _signalHandler = CallSignalHandler(
      ref: ref,
      onProcessOffer: (roomName, sdp) =>
          _setup.processRemoteOffer(roomName, sdp),
      onProcessAnswer: (sdp) => _setup.processRemoteAnswer(sdp),
      onTerminate: _terminateCall,
      onCleanup: _cleanup,
      onScheduleIdleReset: _scheduleIdleReset,
      onStartDurationTimer: _startDurationTimer,
    );

    _setup = CallSetup(
      ref: ref,
      signalHandler: _signalHandler,
      onTerminate: _terminateCall,
      onCleanup: _cleanup,
      onScheduleIdleReset: _scheduleIdleReset,
    );
  }

  final Ref _ref;
  late final CallSignalHandler _signalHandler;
  late final CallSetup _setup;

  // -----------------------------------------------------------------------
  // Public actions
  // -----------------------------------------------------------------------

  /// Initiates an outgoing call to [targetUserId].
  Future<void> initiateCall({
    required String targetUserId,
    required String targetUsername,
    required String? targetPhotoUrl,
    required CallType callType,
  }) async {
    final notifier = _ref.read(callNotifierProvider.notifier);
    final currentState = _ref.read(callNotifierProvider);

    if (currentState.status is! CallIdle) return;
    notifier.setStatus(const CallInitiating());

    if (callType == CallType.audio) {
      notifier.toggleCamera();
    }

    try {
      final datasource = _ref.read(callsRemoteDatasourceProvider);
      final room = await datasource.createRoom(
        receiverId: targetUserId,
        callType: callType,
      );

      final callInfo = CallInfo(
        callId: room.callId,
        roomName: room.roomName,
        callType: callType,
        direction: CallDirection.outgoing,
        remoteUserId: targetUserId,
        remoteUsername: targetUsername,
        remotePhotoUrl: targetPhotoUrl,
      );

      notifier.setCallInfo(callInfo);
      await _setup.setupCall(callInfo, isOutgoing: true);
    } on MediaPermissionException catch (error) {
      await _cleanup();
      notifier.endCall(CallEndReason.permissionDenied, error.message);
      _scheduleIdleReset();
    } on Exception catch (error) {
      await _cleanup();
      notifier.endCall(CallEndReason.failed, error.toString());
      _scheduleIdleReset();
    }
  }

  /// Accepts an incoming call that is currently ringing.
  Future<void> acceptCall() async {
    final callRefs = getCallRefs();
    if (callRefs.isProcessingAction) return;

    final notifier = _ref.read(callNotifierProvider.notifier);
    final currentState = _ref.read(callNotifierProvider);

    if (currentState.status is! CallRinging) return;
    if (currentState.callInfo?.direction != CallDirection.incoming) return;
    if (currentState.callInfo == null) return;

    callRefs.isProcessingAction = true;
    final callInfo = currentState.callInfo!;
    notifier.setStatus(const CallConnecting());

    try {
      // Phase 0 F6-fix: await backend accept before setting up local media.
      // If the backend rejects (race lost, call already ended), do not strand
      // the user with a half-open Twilio session. Phase 1 v2 endpoint will
      // return structured ANSWERED_ELSEWHERE etc.; for now any rejection is
      // treated as a terminal failure.
      final datasource = _ref.read(callsRemoteDatasourceProvider);
      await datasource.acceptCall(callInfo.roomName);
      await _setup.setupCall(callInfo, isOutgoing: false);
    } on MediaPermissionException catch (error) {
      await _cleanup();
      notifier.endCall(CallEndReason.permissionDenied, error.message);
      _scheduleIdleReset();
    } on Exception catch (error) {
      await _cleanup();
      notifier.endCall(CallEndReason.failed, error.toString());
      _scheduleIdleReset();
    } finally {
      callRefs.isProcessingAction = false;
    }
  }

  /// Declines an incoming call.
  void declineCall() {
    final callRefs = getCallRefs();
    if (callRefs.isProcessingAction) return;

    final notifier = _ref.read(callNotifierProvider.notifier);
    final currentState = _ref.read(callNotifierProvider);
    if (currentState.callInfo == null) return;

    callRefs.isProcessingAction = true;
    final callInfo = currentState.callInfo!;

    sendHangup(callInfo.roomName, 'declined', callInfo.remoteUserId);
    final datasource = _ref.read(callsRemoteDatasourceProvider);
    // Phase 0 F6-fix: surface backend failures instead of silent swallow.
    // User wants to terminate locally regardless of backend reachability, so
    // keep optimistic UI cleanup, but log failures (no silent .catchError).
    unawaited(
      datasource.declineCall(callInfo.roomName).catchError((Object err) {
        debugPrint('[CallManager] declineCall failed: $err');
      }),
    );

    unawaited(_cleanup());
    notifier.endCall(CallEndReason.declined);
    _scheduleIdleReset();
  }

  /// Hangs up the current call.
  void hangUp() {
    final notifier = _ref.read(callNotifierProvider.notifier);
    final currentState = _ref.read(callNotifierProvider);
    if (currentState.callInfo == null) return;

    final callInfo = currentState.callInfo!;
    final isCancellingOutgoing =
        currentState.status is CallRinging &&
        callInfo.direction == CallDirection.outgoing;

    sendHangup(
      callInfo.roomName,
      isCancellingOutgoing ? 'cancelled' : 'hangup',
      callInfo.remoteUserId,
    );

    final datasource = _ref.read(callsRemoteDatasourceProvider);
    // Phase 0 F6-fix: surface backend failures instead of silent swallow.
    if (isCancellingOutgoing) {
      unawaited(
        datasource.cancelCall(callInfo.roomName).catchError((Object err) {
          debugPrint('[CallManager] cancelCall failed: $err');
        }),
      );
    } else {
      unawaited(
        datasource.endCall(callInfo.roomName).catchError((Object err) {
          debugPrint('[CallManager] endCall failed: $err');
        }),
      );
    }

    unawaited(_cleanup());
    notifier.endCall(
      isCancellingOutgoing ? CallEndReason.cancelled : CallEndReason.hangup,
    );
    _scheduleIdleReset();
  }

  /// Toggles microphone mute and sends media_state via STOMP.
  void toggleMute() {
    final notifier = _ref.read(callNotifierProvider.notifier);
    final currentState = _ref.read(callNotifierProvider);
    final newMuted = !currentState.media.isMuted;

    getCallRefs().peer?.toggleAudio(enabled: !newMuted);
    notifier.toggleMute();

    _sendCurrentMediaState(overrideMuted: newMuted);
  }

  /// Toggles camera and sends media_state via STOMP.
  void toggleCamera() {
    final notifier = _ref.read(callNotifierProvider.notifier);
    final currentState = _ref.read(callNotifierProvider);
    final newCameraOn = !currentState.media.isCameraOn;

    getCallRefs().peer?.toggleVideo(enabled: newCameraOn);
    notifier.toggleCamera();

    _sendCurrentMediaState(overrideCameraOn: newCameraOn);
  }

  /// Registers stream callbacks for video renderers.
  void setStreamCallbacks({
    required void Function(MediaStream stream) onLocal,
    required void Function(MediaStream stream) onRemote,
  }) {
    final callRefs = getCallRefs();
    callRefs.onLocalStream = onLocal;
    callRefs.onRemoteStream = onRemote;

    if (callRefs.localStream != null) {
      try {
        onLocal(callRefs.localStream!);
      } on Exception {
        /* detached */
      }
    }
    if (callRefs.remoteStream != null) {
      try {
        onRemote(callRefs.remoteStream!);
      } on Exception {
        /* detached */
      }
    }
  }

  // -----------------------------------------------------------------------
  // Private helpers
  // -----------------------------------------------------------------------

  void _sendCurrentMediaState({bool? overrideMuted, bool? overrideCameraOn}) {
    final callState = _ref.read(callNotifierProvider);
    if (callState.callInfo == null) return;

    sendMediaStateSignal(
      callState.callInfo!.roomName,
      overrideMuted ?? callState.media.isMuted,
      !(overrideCameraOn ?? callState.media.isCameraOn),
      callState.callInfo!.remoteUserId,
    );
  }

  void _terminateCall(
    String reason,
    CallEndReason endReason, [
    String? errorMessage,
  ]) {
    final currentState = _ref.read(callNotifierProvider);
    if (currentState.callInfo != null) {
      sendHangup(
        currentState.callInfo!.roomName,
        reason,
        currentState.callInfo!.remoteUserId,
      );
    }

    clearCallTimers();
    unawaited(_cleanup());
    _ref.read(callNotifierProvider.notifier).endCall(endReason, errorMessage);
    _scheduleIdleReset();
  }

  Future<void> _cleanup() async {
    clearCallTimers();
    await disposeCallRefs();
  }

  void _startDurationTimer() {
    final callRefs = getCallRefs();
    if (callRefs.durationTimer != null) return;

    callRefs.durationTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      try {
        _ref.read(callNotifierProvider.notifier).tickDuration();
      } on Exception {
        // Provider disposed
      }
    });
  }

  void _scheduleIdleReset() {
    Future<void>.delayed(CallTimeouts.endedDisplay, () {
      try {
        _ref.read(callNotifierProvider.notifier).resetToIdle();
      } on Exception {
        // Provider may have been disposed
      }
    });
  }
}
