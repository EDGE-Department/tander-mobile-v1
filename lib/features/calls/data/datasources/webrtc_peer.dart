import 'dart:async';

import 'package:flutter_webrtc/flutter_webrtc.dart';

import 'package:tander_flutter_v3/core/utils/app_logger.dart';
import 'package:tander_flutter_v3/features/calls/domain/call_constants.dart';
import 'package:tander_flutter_v3/features/calls/domain/call_types.dart';

// ---------------------------------------------------------------------------
// Callbacks
// ---------------------------------------------------------------------------

/// Callbacks fired by the WebRTC peer during its lifecycle.
final class WebrtcPeerCallbacks {
  const WebrtcPeerCallbacks({
    required this.onIceCandidate,
    required this.onIceStateChange,
    required this.onRemoteStream,
    required this.onConnectionStateChange,
  });

  final void Function(RTCIceCandidate candidate) onIceCandidate;
  final void Function(RTCIceConnectionState iceState) onIceStateChange;
  final void Function(MediaStream stream) onRemoteStream;
  final void Function(RTCPeerConnectionState connectionState)
      onConnectionStateChange;
}

// ---------------------------------------------------------------------------
// Error types
// ---------------------------------------------------------------------------

final class MediaPermissionException implements Exception {
  const MediaPermissionException(this.message);
  final String message;

  @override
  String toString() => 'MediaPermissionException: $message';
}

final class PeerConnectionClosedException implements Exception {
  const PeerConnectionClosedException();

  @override
  String toString() => 'PeerConnectionClosedException: Peer connection is closed';
}

// ---------------------------------------------------------------------------
// WebrtcPeer — flutter_webrtc wrapper
// ---------------------------------------------------------------------------

/// Manages a single WebRTC peer connection with local/remote media streams.
///
/// Mirrors the web's `WebrtcPeer` class: create, acquireMedia, offer/answer,
/// ICE candidates, media toggles, dispose.
final class WebrtcPeer {
  WebrtcPeer({required WebrtcPeerCallbacks callbacks})
      : _callbacks = callbacks;

  static const String _tag = 'WebrtcPeer';

  final WebrtcPeerCallbacks _callbacks;
  RTCPeerConnection? _peerConnection;
  MediaStream? _localStream;

  // -----------------------------------------------------------------------
  // Lifecycle
  // -----------------------------------------------------------------------

  /// Creates the RTCPeerConnection with the given ICE servers.
  Future<void> create(List<IceServerDto> iceServers) async {
    final config = _buildRtcConfig(iceServers);
    _peerConnection = await createPeerConnection(config);

    _peerConnection!.onIceCandidate = (RTCIceCandidate candidate) {
      _callbacks.onIceCandidate(candidate);
    };

    _peerConnection!.onIceConnectionState =
        (RTCIceConnectionState iceState) {
      _callbacks.onIceStateChange(iceState);
    };

    _peerConnection!.onConnectionState =
        (RTCPeerConnectionState connectionState) {
      _callbacks.onConnectionStateChange(connectionState);
    };

    _peerConnection!.onTrack = (RTCTrackEvent event) {
      if (event.streams.isNotEmpty) {
        _callbacks.onRemoteStream(event.streams.first);
      }
    };

    AppLogger.debug('Peer connection created', operation: _tag);
  }

  // -----------------------------------------------------------------------
  // Media acquisition
  // -----------------------------------------------------------------------

  /// Acquires local media with echo/noise cancellation.
  ///
  /// For video calls, falls back to audio-only if camera is denied.
  /// Throws [MediaPermissionException] if microphone is denied.
  Future<MediaStream> acquireMedia({required bool isVideo}) async {
    final audioConstraints = CallMediaConstraints.audioConstraints;
    final videoConstraints = isVideo
        ? CallMediaConstraints.videoConstraints
        : false;

    try {
      _localStream = await navigator.mediaDevices.getUserMedia({
        'audio': audioConstraints,
        'video': videoConstraints,
      });
    } on Exception {
      // If video call and camera denied, fall back to audio-only
      if (isVideo) {
        try {
          _localStream = await navigator.mediaDevices.getUserMedia({
            'audio': audioConstraints,
            'video': false,
          });
        } on Exception {
          throw const MediaPermissionException(
            'Microphone access is required to make calls. '
            'Please allow microphone access in your device settings.',
          );
        }
      } else {
        throw const MediaPermissionException(
          'Microphone access is required to make calls. '
          'Please allow microphone access in your device settings.',
        );
      }
    }

    _requireOpenConnection();

    for (final track in _localStream!.getTracks()) {
      await _peerConnection!.addTrack(track, _localStream!);
    }

    AppLogger.debug(
      'Media acquired (isVideo: $isVideo)',
      operation: _tag,
    );

    return _localStream!;
  }

  // -----------------------------------------------------------------------
  // SDP offer/answer
  // -----------------------------------------------------------------------

  /// Creates an SDP offer and sets it as the local description.
  Future<String> createOffer({required bool isVideo}) async {
    _requireOpenConnection();

    final offer = await _peerConnection!.createOffer({
      'offerToReceiveAudio': true,
      'offerToReceiveVideo': isVideo,
    });

    if (offer.sdp == null || offer.sdp!.isEmpty) {
      throw StateError('createOffer returned empty SDP');
    }

    await _peerConnection!.setLocalDescription(offer);
    return offer.sdp!;
  }

  /// Creates an SDP answer and sets it as the local description.
  Future<String> createAnswer({required bool isVideo}) async {
    _requireOpenConnection();

    final answer = await _peerConnection!.createAnswer({
      'offerToReceiveAudio': true,
      'offerToReceiveVideo': isVideo,
    });

    if (answer.sdp == null || answer.sdp!.isEmpty) {
      throw StateError('createAnswer returned empty SDP');
    }

    await _peerConnection!.setLocalDescription(answer);
    return answer.sdp!;
  }

  /// Sets the remote SDP offer (callee side).
  Future<void> setRemoteOffer(String sdp) async {
    _requireOpenConnection();
    await _peerConnection!.setRemoteDescription(
      RTCSessionDescription(sdp, 'offer'),
    ).timeout(const Duration(seconds: 10), onTimeout: () {
      throw TimeoutException('setRemoteDescription(offer) timed out');
    });
  }

  /// Sets the remote SDP answer (caller side).
  Future<void> setRemoteAnswer(String sdp) async {
    _requireOpenConnection();
    await _peerConnection!.setRemoteDescription(
      RTCSessionDescription(sdp, 'answer'),
    );
  }

  // -----------------------------------------------------------------------
  // ICE candidates
  // -----------------------------------------------------------------------

  /// Adds a remote ICE candidate. Silently skips if peer is closed or
  /// remote description is not yet set.
  Future<void> addIceCandidate(IceCandidateInfo candidateInfo) async {
    if (_peerConnection == null) return;

    final remoteDescription = await _peerConnection!.getRemoteDescription();
    if (remoteDescription == null) return;

    try {
      final candidate = RTCIceCandidate(
        candidateInfo.candidate,
        candidateInfo.sdpMid,
        candidateInfo.sdpMLineIndex,
      );
      await _peerConnection!.addCandidate(candidate);
    } on Exception catch (error) {
      // Non-fatal: some candidates are naturally invalid (end-of-candidates)
      AppLogger.debug(
        'Failed to add ICE candidate (non-fatal)',
        operation: _tag,
        context: {'error': error.toString()},
      );
    }
  }

  // -----------------------------------------------------------------------
  // Media controls
  // -----------------------------------------------------------------------

  void toggleAudio({required bool enabled}) {
    if (_localStream == null) return;
    for (final track in _localStream!.getAudioTracks()) {
      track.enabled = enabled;
    }
  }

  void toggleVideo({required bool enabled}) {
    if (_localStream == null) return;
    for (final track in _localStream!.getVideoTracks()) {
      track.enabled = enabled;
    }
  }

  // -----------------------------------------------------------------------
  // Getters
  // -----------------------------------------------------------------------

  MediaStream? get localStream => _localStream;

  bool get hasRemoteDescription {
    // flutter_webrtc's getRemoteDescription is async, so we track it
    // via the signalingState instead.
    final signalingState = _peerConnection?.signalingState;
    return signalingState == RTCSignalingState.RTCSignalingStateStable ||
        signalingState ==
            RTCSignalingState.RTCSignalingStateHaveRemoteOffer;
  }

  bool get isAlive {
    if (_peerConnection == null) return false;
    final connectionState = _peerConnection!.connectionState;
    return connectionState != RTCPeerConnectionState.RTCPeerConnectionStateClosed;
  }

  // -----------------------------------------------------------------------
  // Cleanup
  // -----------------------------------------------------------------------

  /// Disposes the peer connection and stops all local media tracks.
  Future<void> dispose() async {
    if (_localStream != null) {
      for (final track in _localStream!.getTracks()) {
        await track.stop();
      }
      await _localStream!.dispose();
      _localStream = null;
    }

    if (_peerConnection != null) {
      await _peerConnection!.close();
      await _peerConnection!.dispose();
      _peerConnection = null;
    }

    AppLogger.debug('Peer connection disposed', operation: _tag);
  }

  // -----------------------------------------------------------------------
  // Private
  // -----------------------------------------------------------------------

  void _requireOpenConnection() {
    if (_peerConnection == null) {
      throw StateError(
        'WebrtcPeer: peer connection not created. Call create() first.',
      );
    }
    final connectionState = _peerConnection!.connectionState;
    if (connectionState == RTCPeerConnectionState.RTCPeerConnectionStateClosed) {
      throw const PeerConnectionClosedException();
    }
  }

  Map<String, Object?> _buildRtcConfig(List<IceServerDto> iceServers) {
    final List<Map<String, Object?>> servers = iceServers.map((server) {
      return <String, Object?>{
        'urls': server.urls,
        if (server.username != null) 'username': server.username,
        if (server.credential != null) 'credential': server.credential,
      };
    }).toList();

    final effectiveServers =
        servers.isNotEmpty ? servers : fallbackIceServers;

    return {
      'iceServers': effectiveServers,
      'bundlePolicy': 'max-bundle',
      'rtcpMuxPolicy': 'require',
      'iceCandidatePoolSize': 2,
    };
  }
}
