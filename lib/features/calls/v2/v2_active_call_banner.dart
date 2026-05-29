import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:tander_flutter_v3/core/providers/core_providers.dart';
import 'package:tander_flutter_v3/core/utils/app_logger.dart';
import 'package:tander_flutter_v3/features/calls/services/twilio_native_bridge.dart';
import 'package:tander_flutter_v3/features/calls/v2/v2_active_call_state.dart';

/// Non-blocking active-call banner. Floats at the top of the screen over
/// whatever route the user is on, so they can navigate the app freely
/// during a call (like WhatsApp's "tap to return to call" pill).
///
/// Mounted once at app root via MaterialApp.builder. Renders nothing when
/// there's no active call.
class V2ActiveCallBanner extends ConsumerStatefulWidget {
  const V2ActiveCallBanner({super.key});

  @override
  ConsumerState<V2ActiveCallBanner> createState() => _V2ActiveCallBannerState();
}

class _V2ActiveCallBannerState extends ConsumerState<V2ActiveCallBanner> {
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

  Future<void> _hangUp(V2ActiveCall call) async {
    if (_hangingUp) return;
    setState(() => _hangingUp = true);
    AppLogger.info(
      'hangUp callId=${call.callId}',
      operation: 'V2ActiveCallBanner',
    );
    // Capture refs up front — clearing state will rebuild this widget away.
    final datasource = ref.read(callsV2RemoteDatasourceProvider);
    final notifier = ref.read(v2ActiveCallProvider.notifier);
    try {
      await TwilioNativeBridge.instance.disconnect();
      await datasource.end(call.callId, reason: 'user_hangup');
    } on Object catch (e) {
      AppLogger.warning('hangUp error: $e', operation: 'V2ActiveCallBanner');
    } finally {
      notifier.clear();
      // Reset even though the banner is now ephemeral (defends against a
      // future regression if it's ever made a permanent child again).
      if (mounted) setState(() => _hangingUp = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final call = ref.watch(v2ActiveCallProvider);
    // Hidden when there's no call, or while the call is maximized (the
    // full-screen V2InCallScreen covers the bubble's role).
    if (call == null || call.maximized) {
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

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
        child: Material(
          elevation: 8,
          borderRadius: BorderRadius.circular(16),
          color: const Color(0xFF1F8A4C), // call-green
          child: Padding(
            padding: const EdgeInsets.fromLTRB(12, 8, 8, 8),
            child: Row(
              children: <Widget>[
                // Tapping the bubble body maximizes to the full-screen call
                // UI. The action buttons below stay separate.
                Expanded(
                  child: GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: () =>
                        ref.read(v2ActiveCallProvider.notifier).maximize(),
                    child: Row(
                      children: <Widget>[
                        CircleAvatar(
                          radius: 18,
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
                                    fontWeight: FontWeight.bold,
                                  ),
                                )
                              : null,
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: <Widget>[
                              Text(
                                call.peerName,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              Row(
                                children: <Widget>[
                                  if (call.isVideo) ...<Widget>[
                                    const Icon(
                                      Icons.videocam,
                                      color: Colors.white70,
                                      size: 13,
                                    ),
                                    const SizedBox(width: 4),
                                  ],
                                  Flexible(
                                    child: Text(
                                      '${call.callType.toLowerCase()} · $statusText',
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(
                                        color: Colors.white70,
                                        fontSize: 12,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                _circleAction(
                  icon: call.muted ? Icons.mic_off : Icons.mic,
                  bg: call.muted ? Colors.white : Colors.white24,
                  fg: call.muted ? const Color(0xFF1F8A4C) : Colors.white,
                  onTap: _hangingUp ? null : () => _toggleMute(call),
                ),
                const SizedBox(width: 6),
                _circleAction(
                  icon: call.speakerOn ? Icons.volume_up : Icons.volume_down,
                  bg: call.speakerOn ? Colors.white : Colors.white24,
                  fg: call.speakerOn ? const Color(0xFF1F8A4C) : Colors.white,
                  onTap: _hangingUp ? null : () => _toggleSpeaker(call),
                ),
                const SizedBox(width: 6),
                _circleAction(
                  icon: Icons.call_end,
                  bg: Colors.redAccent,
                  fg: Colors.white,
                  onTap: _hangingUp ? null : () => _hangUp(call),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _circleAction({
    required IconData icon,
    required Color bg,
    required Color fg,
    required VoidCallback? onTap,
  }) {
    return Material(
      color: bg,
      shape: const CircleBorder(),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onTap,
        child: SizedBox(
          width: 38,
          height: 38,
          child: Icon(icon, color: fg, size: 20),
        ),
      ),
    );
  }
}
