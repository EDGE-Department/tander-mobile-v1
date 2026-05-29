import 'dart:async';

import 'package:flutter/foundation.dart'
    show TargetPlatform, defaultTargetPlatform;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:tander_flutter_v3/core/providers/core_providers.dart';
import 'package:tander_flutter_v3/core/utils/app_logger.dart';
import 'package:tander_flutter_v3/features/calls/services/twilio_native_bridge.dart';
import 'package:tander_flutter_v3/features/calls/v2/v2_active_call_state.dart';

/// Full-screen in-call UI — the "maximized" presentation of an active call.
///
/// Rendered as an overlay layer in `V2IncomingCallOverlayHost`'s Stack (NOT a
/// router push) so it shares one lifecycle with [v2ActiveCallProvider]. The
/// previous router-pushed version fought the Twilio/WPS-driven call state and
/// caused a ref-after-dispose crash ("redirected to debug"). The user reaches
/// this by tapping the island bubble (or automatically when a video call
/// connects) and leaves it via the minimize button, dropping back to the
/// bubble — the call itself is unaffected either way.
///
/// Phase A: audio-style layout (avatar + timer + controls). Real camera
/// capture + remote/local video rendering is Phase B (Stage-3 native work);
/// until then a video call shows an honest "camera not yet available" note.
class V2InCallScreen extends ConsumerStatefulWidget {
  const V2InCallScreen({super.key});

  @override
  ConsumerState<V2InCallScreen> createState() => _V2InCallScreenState();
}

class _V2InCallScreenState extends ConsumerState<V2InCallScreen> {
  Timer? _ticker;
  bool _hangingUp = false;

  @override
  void dispose() {
    _ticker?.cancel();
    super.dispose();
  }

  void _ensureTicker(bool active) {
    if (active && _ticker == null) {
      _ticker = Timer.periodic(const Duration(seconds: 1), (_) {
        if (mounted) setState(() {});
      });
    } else if (!active && _ticker != null) {
      _ticker!.cancel();
      _ticker = null;
    }
  }

  String _elapsed(DateTime since) {
    final d = DateTime.now().difference(since);
    final m = d.inMinutes.toString().padLeft(2, '0');
    final s = (d.inSeconds % 60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  Future<void> _toggleMute(V2ActiveCall call) async {
    final next = !call.muted;
    ref.read(v2ActiveCallProvider.notifier).setMuted(next);
    await TwilioNativeBridge.instance.setMuted(next);
  }

  Future<void> _toggleSpeaker(V2ActiveCall call) async {
    final next = !call.speakerOn;
    ref.read(v2ActiveCallProvider.notifier).setSpeakerOn(next);
    await TwilioNativeBridge.instance.setSpeakerphoneOn(next);
  }

  Future<void> _toggleCamera(V2ActiveCall call) async {
    final next = !call.cameraEnabled;
    ref.read(v2ActiveCallProvider.notifier).setCameraEnabled(next);
    await TwilioNativeBridge.instance.setVideoEnabled(next);
  }

  Future<void> _hangUp(V2ActiveCall call) async {
    if (_hangingUp) return;
    setState(() => _hangingUp = true);
    AppLogger.info('hangUp callId=${call.callId}', operation: 'V2InCallScreen');
    final datasource = ref.read(callsV2RemoteDatasourceProvider);
    final notifier = ref.read(v2ActiveCallProvider.notifier);
    try {
      await TwilioNativeBridge.instance.disconnect();
      await datasource.end(call.callId, reason: 'user_hangup');
    } on Object catch (e) {
      AppLogger.warning('hangUp error: $e', operation: 'V2InCallScreen');
    } finally {
      notifier.clear();
      if (mounted) setState(() => _hangingUp = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final call = ref.watch(v2ActiveCallProvider);
    if (call == null) {
      _ensureTicker(false);
      return const SizedBox.shrink();
    }
    final isActive =
        call.phase == V2CallPhase.active && call.connectedAt != null;
    _ensureTicker(isActive);

    final statusText = switch (call.phase) {
      V2CallPhase.connecting => 'Connecting…',
      V2CallPhase.reconnecting => 'Reconnecting…',
      V2CallPhase.active =>
        call.connectedAt != null ? _elapsed(call.connectedAt!) : 'Connected',
      V2CallPhase.ended => 'Ended',
    };

    return Material(
      color: const Color(0xFF101314),
      child: SafeArea(
        child: Stack(
          children: <Widget>[
            Column(
              children: <Widget>[
                // Top bar — minimize back to the island bubble.
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  child: Row(
                    children: <Widget>[
                      // Plain InkResponse, NOT IconButton — this screen is mounted
                      // as a Stack sibling of the Navigator, so it has no Overlay
                      // ancestor; IconButton's tooltip (a RawTooltip) needs one and
                      // throws "No Overlay widget found".
                      InkResponse(
                        radius: 26,
                        onTap: () =>
                            ref.read(v2ActiveCallProvider.notifier).minimize(),
                        child: const Padding(
                          padding: EdgeInsets.all(10),
                          child: Icon(
                            Icons.expand_more,
                            color: Colors.white,
                            size: 30,
                          ),
                        ),
                      ),
                      Text(
                        call.isVideo ? 'Video call' : 'Audio call',
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 16,
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: call.showRemoteVideo
                      // Remote peer's camera is live — render it. VideoTextureView
                      // (TextureView) composes via TLHC, so a plain AndroidView is
                      // enough even though this screen is an app-root overlay.
                      ? _twilioVideoView(<String, dynamic>{
                          'kind': 'remote',
                          'participantSid': call.remoteVideoSid,
                        })
                      : Center(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: <Widget>[
                              CircleAvatar(
                                radius: 56,
                                backgroundColor: Colors.white24,
                                backgroundImage: call.peerPhotoUrl != null
                                    ? NetworkImage(call.peerPhotoUrl!)
                                    : null,
                                child: call.peerPhotoUrl == null
                                    ? Text(
                                        call.peerName.characters
                                            .take(1)
                                            .toString()
                                            .toUpperCase(),
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 40,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      )
                                    : null,
                              ),
                              const SizedBox(height: 20),
                              Text(
                                call.peerName,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 24,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                statusText,
                                style: const TextStyle(
                                  color: Colors.white70,
                                  fontSize: 16,
                                ),
                              ),
                              if (call.isVideo) ...<Widget>[
                                const SizedBox(height: 16),
                                const Text(
                                  'Waiting for the other camera…',
                                  style: TextStyle(
                                    color: Colors.white38,
                                    fontSize: 13,
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                ),
                // Controls.
                Padding(
                  padding: const EdgeInsets.only(bottom: 32, top: 16),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: <Widget>[
                      _bigAction(
                        icon: call.muted ? Icons.mic_off : Icons.mic,
                        label: call.muted ? 'Unmute' : 'Mute',
                        bg: call.muted ? Colors.white : Colors.white24,
                        fg: call.muted ? const Color(0xFF101314) : Colors.white,
                        onTap: _hangingUp ? null : () => _toggleMute(call),
                      ),
                      if (call.isVideo)
                        _bigAction(
                          icon: call.cameraEnabled
                              ? Icons.videocam
                              : Icons.videocam_off,
                          label: call.cameraEnabled ? 'Camera' : 'Camera off',
                          bg: call.cameraEnabled
                              ? Colors.white24
                              : Colors.white,
                          fg: call.cameraEnabled
                              ? Colors.white
                              : const Color(0xFF101314),
                          onTap: _hangingUp ? null : () => _toggleCamera(call),
                        ),
                      _bigAction(
                        icon: call.speakerOn
                            ? Icons.volume_up
                            : Icons.volume_down,
                        label: 'Speaker',
                        bg: call.speakerOn ? Colors.white : Colors.white24,
                        fg: call.speakerOn
                            ? const Color(0xFF101314)
                            : Colors.white,
                        onTap: _hangingUp ? null : () => _toggleSpeaker(call),
                      ),
                      _bigAction(
                        icon: Icons.call_end,
                        label: 'End',
                        bg: Colors.redAccent,
                        fg: Colors.white,
                        onTap: _hangingUp ? null : () => _hangUp(call),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            // Self-view PIP — your own mirrored camera, top-right. Shown as
            // soon as the local camera is live (independent of the remote),
            // so you can confirm your camera before the peer's video arrives.
            if (call.localVideoOn && call.cameraEnabled && call.isVideo)
              Positioned(
                top: 12,
                right: 12,
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.white24),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: SizedBox(
                      width: 96,
                      child: AspectRatio(
                        aspectRatio: 9 / 16,
                        child: _twilioVideoView(<String, dynamic>{
                          'kind': 'local',
                        }),
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _bigAction({
    required IconData icon,
    required String label,
    required Color bg,
    required Color fg,
    required VoidCallback? onTap,
  }) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        Material(
          color: bg,
          shape: const CircleBorder(),
          child: InkWell(
            customBorder: const CircleBorder(),
            onTap: onTap,
            child: SizedBox(
              width: 64,
              height: 64,
              child: Icon(icon, color: fg, size: 28),
            ),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          label,
          style: const TextStyle(color: Colors.white70, fontSize: 12),
        ),
      ],
    );
  }
}

/// Native video render surface for the `tander/twilio_video_view` PlatformView.
/// Uses `UiKitView` on iOS and `AndroidView` elsewhere — both register the same
/// viewType + creationParams (`{kind, participantSid}`), so the native factories
/// (TwilioVideoViewFactory.kt / .swift) handle them identically.
Widget _twilioVideoView(Map<String, dynamic> creationParams) {
  const String viewType = 'tander/twilio_video_view';
  if (defaultTargetPlatform == TargetPlatform.iOS) {
    return UiKitView(
      viewType: viewType,
      creationParams: creationParams,
      creationParamsCodec: const StandardMessageCodec(),
    );
  }
  return AndroidView(
    viewType: viewType,
    creationParams: creationParams,
    creationParamsCodec: const StandardMessageCodec(),
  );
}
