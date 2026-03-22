import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:tander_flutter_v3/features/calls/domain/call_types.dart';
import 'package:tander_flutter_v3/features/calls/presentation/states/call_state.dart';

// ---------------------------------------------------------------------------
// Provider
// ---------------------------------------------------------------------------

final callNotifierProvider =
    NotifierProvider<CallNotifier, CallState>(CallNotifier.new);

// ---------------------------------------------------------------------------
// Notifier
// ---------------------------------------------------------------------------

/// Riverpod state holder for the active call.
///
/// Thin wrapper that only manages state transitions — all orchestration
/// logic lives in [CallManager] and [CallListener], which read/write
/// this notifier via its provider.
final class CallNotifier extends Notifier<CallState> {
  @override
  CallState build() => CallState.initial;

  // -----------------------------------------------------------------------
  // Status transitions
  // -----------------------------------------------------------------------

  void setStatus(CallStatus status) {
    state = state.copyWith(status: status);
  }

  void setCallInfo(CallInfo callInfo) {
    state = state.copyWith(callInfo: callInfo);
  }

  // -----------------------------------------------------------------------
  // Media
  // -----------------------------------------------------------------------

  void toggleMute() {
    state = state.copyWith(
      media: state.media.copyWith(isMuted: !state.media.isMuted),
    );
  }

  void toggleCamera() {
    state = state.copyWith(
      media: state.media.copyWith(isCameraOn: !state.media.isCameraOn),
    );
  }

  void setRemoteMedia(RemoteMediaState remoteMedia) {
    state = state.copyWith(remoteMedia: remoteMedia);
  }

  // -----------------------------------------------------------------------
  // Duration
  // -----------------------------------------------------------------------

  void tickDuration() {
    state = state.copyWith(durationSeconds: state.durationSeconds + 1);
  }

  // -----------------------------------------------------------------------
  // End call
  // -----------------------------------------------------------------------

  void endCall(CallEndReason reason, [String? errorMessage]) {
    final endStatus =
        reason == CallEndReason.failed ? const CallFailed() : const CallEnded();

    state = state.copyWith(
      status: endStatus,
      endReason: reason,
      errorMessage: errorMessage,
    );
  }

  // -----------------------------------------------------------------------
  // Reset
  // -----------------------------------------------------------------------

  void resetToIdle() {
    state = CallState.initial;
  }
}
