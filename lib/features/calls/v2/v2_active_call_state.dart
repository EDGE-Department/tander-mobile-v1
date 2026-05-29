import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:tander_flutter_v3/core/utils/app_logger.dart';
import 'package:tander_flutter_v3/features/calls/services/twilio_native_bridge.dart';

/// Lifecycle phase of an active v2 call.
enum V2CallPhase { connecting, active, reconnecting, ended }

/// State of the in-progress v2 call, surfaced by the app-root active-call
/// banner. Lives in a provider (not a widget) so it survives navigation —
/// the user can move freely around the app while the banner floats on top.
class V2ActiveCall {
  const V2ActiveCall({
    required this.callId,
    required this.roomName,
    required this.peerName,
    required this.callType,
    required this.phase,
    this.peerPhotoUrl,
    this.connectedAt,
    this.muted = false,
    this.speakerOn = false,
    this.maximized = false,
    this.remoteVideoSid,
    this.localVideoOn = false,
    this.cameraEnabled = true,
    this.remoteVideoEnabled = true,
  });

  final String callId;
  final String roomName;
  final String peerName;
  final String callType; // AUDIO | VIDEO
  final V2CallPhase phase;
  final String? peerPhotoUrl;
  final DateTime? connectedAt; // set when peer joins → drives the timer
  final bool muted;
  final bool speakerOn;

  /// Whether the full-screen in-call UI is showing (vs the minimized island
  /// bubble). Only ever changed by the user (tap bubble / minimize button) or
  /// once at [V2ActiveCallNotifier.start] for video — deliberately never by a
  /// Twilio event, so a mid-call reconnect can't yank the user back to
  /// full-screen while they're reading a chat.
  final bool maximized;

  /// Participant SID of the remote peer whose video track is subscribed, or
  /// null if no remote video (audio call, peer camera off, or not yet joined).
  /// Drives whether [V2InCallScreen] mounts the remote video PlatformView.
  final String? remoteVideoSid;

  /// Whether the local camera track is live (mirrors the native
  /// `localVideoTrackPublished` event). Drives the self-view PIP.
  final bool localVideoOn;

  /// Whether the LOCAL camera is enabled (B4 toggle). False → hide the
  /// self-view PIP + stop sending frames to the peer.
  final bool cameraEnabled;

  /// Whether the REMOTE peer's camera is sending frames. False after their
  /// onVideoTrackDisabled → show their avatar, not a frozen frame.
  final bool remoteVideoEnabled;

  bool get isVideo => callType.toUpperCase() == 'VIDEO';

  /// The remote video PlatformView should mount only when the peer's track is
  /// subscribed AND currently enabled.
  bool get showRemoteVideo =>
      isVideo && remoteVideoSid != null && remoteVideoEnabled;

  V2ActiveCall copyWith({
    V2CallPhase? phase,
    DateTime? connectedAt,
    bool? muted,
    bool? speakerOn,
    bool? maximized,
    String? remoteVideoSid,
    bool clearRemoteVideo = false,
    bool? localVideoOn,
    bool? cameraEnabled,
    bool? remoteVideoEnabled,
  }) => V2ActiveCall(
    callId: callId,
    roomName: roomName,
    peerName: peerName,
    callType: callType,
    peerPhotoUrl: peerPhotoUrl,
    phase: phase ?? this.phase,
    connectedAt: connectedAt ?? this.connectedAt,
    muted: muted ?? this.muted,
    speakerOn: speakerOn ?? this.speakerOn,
    maximized: maximized ?? this.maximized,
    remoteVideoSid: clearRemoteVideo
        ? null
        : (remoteVideoSid ?? this.remoteVideoSid),
    localVideoOn: localVideoOn ?? this.localVideoOn,
    cameraEnabled: cameraEnabled ?? this.cameraEnabled,
    remoteVideoEnabled: remoteVideoEnabled ?? this.remoteVideoEnabled,
  );
}

/// Tracks the active v2 call. Subscribes to [TwilioNativeBridge] events at
/// construction (provider is created eagerly in app bootstrap), so it never
/// misses a roomConnected/participantConnected event due to a late
/// subscription — the failure mode the full-screen call screen hit.
class V2ActiveCallNotifier extends StateNotifier<V2ActiveCall?> {
  V2ActiveCallNotifier({required TwilioNativeBridge bridge}) : super(null) {
    _sub = bridge.events.listen(_onTwilioEvent);
  }

  StreamSubscription<TwilioRoomEvent>? _sub;

  /// Begin tracking a call (from the accept handler or outgoing start).
  /// The banner appears immediately in `connecting` phase.
  void start({
    required String callId,
    required String roomName,
    required String peerName,
    required String callType,
    String? peerPhotoUrl,
  }) {
    AppLogger.info(
      'active call start callId=$callId',
      operation: 'V2ActiveCallNotifier',
    );
    state = V2ActiveCall(
      callId: callId,
      roomName: roomName,
      peerName: peerName,
      callType: callType,
      peerPhotoUrl: peerPhotoUrl,
      phase: V2CallPhase.connecting,
      // Video opens full-screen from the start (you need the picture);
      // audio stays as the island bubble unless the user taps it.
      maximized: callType.toUpperCase() == 'VIDEO',
    );
  }

  /// Expand to the full-screen in-call UI (user tapped the island bubble).
  void maximize() {
    final s = state;
    if (s != null && !s.maximized) state = s.copyWith(maximized: true);
  }

  /// Collapse to the island bubble (user tapped the minimize button).
  void minimize() {
    final s = state;
    if (s != null && s.maximized) state = s.copyWith(maximized: false);
  }

  void setMuted(bool muted) {
    final s = state;
    if (s != null) state = s.copyWith(muted: muted);
  }

  void setSpeakerOn(bool on) {
    final s = state;
    if (s != null) state = s.copyWith(speakerOn: on);
  }

  void setCameraEnabled(bool on) {
    final s = state;
    if (s != null) state = s.copyWith(cameraEnabled: on);
  }

  /// Clears the banner (called after a local hangup completes).
  void clear() => state = null;

  /// Current call (null if none). Lets non-Riverpod orchestrators read the
  /// active callId — e.g. the notification "Hang Up" path in
  /// [V2CallkitListener], which has the notifier instance but not `ref`.
  V2ActiveCall? get current => state;

  void _onTwilioEvent(TwilioRoomEvent event) {
    final s = state;
    if (s == null) return;
    switch (event) {
      case RoomReconnecting():
        state = s.copyWith(phase: V2CallPhase.reconnecting);
      case RoomReconnected():
        state = s.copyWith(phase: V2CallPhase.active);
      case ParticipantConnected():
        // Peer joined → call is truly active; start the duration clock.
        state = s.copyWith(
          phase: V2CallPhase.active,
          connectedAt: s.connectedAt ?? DateTime.now(),
        );
      case RoomDisconnected():
        AppLogger.info(
          'active call ended (room disconnected) callId=${s.callId}',
          operation: 'V2ActiveCallNotifier',
        );
        state = null;
      case RoomConnectFailure():
        state = null;
      case RemoteVideoTrackSubscribed(:final participantSid):
        // Peer's camera is live → mount the remote video PlatformView.
        state = s.copyWith(
          remoteVideoSid: participantSid,
          remoteVideoEnabled: true,
        );
      case RemoteVideoTrackUnsubscribed():
        state = s.copyWith(clearRemoteVideo: true);
      case ParticipantDisconnected():
        // Peer left → drop their video so we don't render a dead track.
        state = s.copyWith(clearRemoteVideo: true);
      case LocalVideoTrackPublished():
        state = s.copyWith(localVideoOn: true);
      case RemoteVideoEnabled():
        state = s.copyWith(remoteVideoEnabled: true);
      case RemoteVideoDisabled():
        // Peer turned their camera off → fall back to their avatar.
        state = s.copyWith(remoteVideoEnabled: false);
      case RoomConnected():
      case AudioTrackSubscribed():
      case NetworkQualityChanged():
      // Handled by V2CallkitListener (needs the datasource for backend end);
      // the notifier only clears UI, which RoomDisconnected already does.
      case HangUpRequested():
        break;
    }
  }

  @override
  void dispose() {
    _sub?.cancel();
    _sub = null;
    super.dispose();
  }
}

/// App-wide active-call state. Created eagerly in app bootstrap so it's
/// subscribed to Twilio events before any call connects.
final v2ActiveCallProvider =
    StateNotifierProvider<V2ActiveCallNotifier, V2ActiveCall?>((ref) {
      final notifier = V2ActiveCallNotifier(
        bridge: TwilioNativeBridge.instance,
      );
      ref.onDispose(notifier.dispose);
      return notifier;
    });
