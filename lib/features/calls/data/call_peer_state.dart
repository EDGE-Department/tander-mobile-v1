import 'dart:async';

import 'package:flutter_webrtc/flutter_webrtc.dart';

import 'package:tander_flutter_v3/core/realtime/stomp_client_manager.dart';
import 'package:tander_flutter_v3/core/utils/app_logger.dart';
import 'package:tander_flutter_v3/features/calls/data/datasources/webrtc_peer.dart';
import 'package:tander_flutter_v3/features/calls/domain/call_types.dart';

// ---------------------------------------------------------------------------
// Buffered offer — SDP offer that arrives before user taps Accept
// ---------------------------------------------------------------------------

final class BufferedOffer {
  const BufferedOffer({required this.roomName, required this.sdp});
  final String roomName;
  final String sdp;
}

// ---------------------------------------------------------------------------
// Pending offer buffer — module-level, read by listener, drained by manager
// ---------------------------------------------------------------------------

BufferedOffer? _pendingOfferBuffer;

BufferedOffer? getPendingOfferBuffer() => _pendingOfferBuffer;

void setPendingOfferBuffer(BufferedOffer? offer) {
  _pendingOfferBuffer = offer;
}

BufferedOffer? drainPendingOfferBuffer() {
  final offer = _pendingOfferBuffer;
  _pendingOfferBuffer = null;
  return offer;
}

// ---------------------------------------------------------------------------
// Shared call refs — singleton, survives widget rebuild/navigation
// ---------------------------------------------------------------------------

/// Mutable call peer state that lives outside the widget tree.
///
/// Persists across Riverpod rebuilds and screen navigation so the WebRTC
/// peer connection stays alive when navigating from messages to call screen.
final class CallRefs {
  WebrtcPeer? peer;
  StompUnsubscribeCallback? unsubRoom;
  Timer? durationTimer;
  Timer? timeoutTimer;
  List<IceCandidateInfo> pendingIceCandidates = [];

  /// Buffered SDP offer received during ringing (before acceptCall).
  BufferedOffer? pendingOffer;

  MediaStream? localStream;
  MediaStream? remoteStream;
  void Function(MediaStream stream)? onLocalStream;
  void Function(MediaStream stream)? onRemoteStream;

  /// Guard against accept/decline being called multiple times.
  bool isProcessingAction = false;
}

// ---------------------------------------------------------------------------
// Singleton access
// ---------------------------------------------------------------------------

CallRefs? _sharedRefs;

CallRefs getCallRefs() {
  _sharedRefs ??= CallRefs();
  return _sharedRefs!;
}

/// Clears all timers tracked in [CallRefs].
///
/// Must be called before [disposeCallRefs] — timer cleanup is kept separate
/// so the peer-state module stays free of timer concerns.
void clearCallTimers() {
  final refs = getCallRefs();
  refs.durationTimer?.cancel();
  refs.durationTimer = null;
  refs.timeoutTimer?.cancel();
  refs.timeoutTimer = null;
}

/// Stops all media tracks, disposes the peer connection, unsubscribes from
/// room signals, and resets every field back to initial state.
Future<void> disposeCallRefs() async {
  final refs = getCallRefs();

  // Stop local media tracks
  if (refs.localStream != null) {
    for (final track in refs.localStream!.getTracks()) {
      await track.stop();
    }
    await refs.localStream!.dispose();
  }

  // Stop remote media tracks
  if (refs.remoteStream != null) {
    for (final track in refs.remoteStream!.getTracks()) {
      await track.stop();
    }
    await refs.remoteStream!.dispose();
  }

  // Dispose the peer connection
  try {
    await refs.peer?.dispose();
  } on Exception catch (error, stackTrace) {
    AppLogger.error(
      'Failed to dispose peer connection',
      operation: 'disposeCallRefs',
      error: error,
      stackTrace: stackTrace,
    );
  }

  // Unsubscribe from room signals
  try {
    refs.unsubRoom?.call();
  } on Exception catch (error, stackTrace) {
    AppLogger.error(
      'Failed to unsubscribe room signals',
      operation: 'disposeCallRefs',
      error: error,
      stackTrace: stackTrace,
    );
  }

  // Reset all fields
  refs.peer = null;
  refs.unsubRoom = null;
  refs.pendingIceCandidates = [];
  refs.pendingOffer = null;
  refs.localStream = null;
  refs.remoteStream = null;
  refs.onLocalStream = null;
  refs.onRemoteStream = null;
  refs.isProcessingAction = false;
}
