import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:just_audio/just_audio.dart';
import 'package:tander_flutter_v3/features/calls/domain/call_types.dart';
import 'package:tander_flutter_v3/features/calls/presentation/notifiers/call_manager.dart';
import 'package:tander_flutter_v3/features/calls/presentation/notifiers/call_notifier.dart';
import 'package:tander_flutter_v3/shared/constants/routes.dart';

// ---------------------------------------------------------------------------
// Incoming call overlay
//
// Mobile: full-screen centered, matching the warm gradient card design.
// Card: radius 20px, bg gradient(145deg, #1A0800 -> #0D1B2A),
//        shadow 0 24px 80px rgba(0,0,0,0.45)
// Avatar: 52px, border 2px white/15, pulse ring 2.2s scale 1 -> 1.6 opacity 1 -> 0
// Buttons: h48px radius 14px, accept bg-green-600 shadow, decline bg red-600/20
// ---------------------------------------------------------------------------

class IncomingCallOverlay extends ConsumerStatefulWidget {
  const IncomingCallOverlay({super.key});

  @override
  ConsumerState<IncomingCallOverlay> createState() =>
      _IncomingCallOverlayState();
}

class _IncomingCallOverlayState extends ConsumerState<IncomingCallOverlay>
    with SingleTickerProviderStateMixin {
  bool _isAccepting = false;
  AudioPlayer? _audioPlayer;
  Timer? _ringtoneTimer;
  late final AnimationController _pulseController;
  late final Animation<double> _pulseAnimation;
  late final Animation<double> _pulseOpacityAnimation;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2200),
    )..repeat();

    _pulseAnimation = Tween<double>(
      begin: 1.0,
      end: 1.6,
    ).animate(CurvedAnimation(parent: _pulseController, curve: Curves.easeOut));

    _pulseOpacityAnimation = Tween<double>(
      begin: 1.0,
      end: 0.0,
    ).animate(CurvedAnimation(parent: _pulseController, curve: Curves.easeOut));
  }

  @override
  void dispose() {
    _stopRingtone();
    _pulseController.dispose();
    super.dispose();
  }

  void _startRingtone() {
    _stopRingtone();
    _audioPlayer = AudioPlayer();

    Future<void> playTone() async {
      try {
        await _audioPlayer?.setAsset('assets/audio/ringtone.mp3');
        await _audioPlayer?.setVolume(0.5);
        await _audioPlayer?.play();
      } on Object {
        // Audio playback failed — silent fallback
      }
    }

    playTone();
    _ringtoneTimer = Timer.periodic(
      const Duration(milliseconds: 2500),
      (_) => playTone(),
    );
  }

  void _stopRingtone() {
    _ringtoneTimer?.cancel();
    _ringtoneTimer = null;
    _audioPlayer?.dispose();
    _audioPlayer = null;
  }

  @override
  Widget build(BuildContext context) {
    final callState = ref.watch(callNotifierProvider);
    final isVisible = callState.isIncomingRinging;
    final callInfo = callState.callInfo;

    // Start/stop ringtone based on visibility
    if (isVisible && _audioPlayer == null) {
      _startRingtone();
    } else if (!isVisible && _audioPlayer != null) {
      _stopRingtone();
      if (_isAccepting) setState(() => _isAccepting = false);
    }

    if (!isVisible || callInfo == null) return const SizedBox.shrink();

    final callerName = callInfo.remoteUsername;
    final callerPhoto = callInfo.remotePhotoUrl;
    final isVideo = callInfo.callType == CallType.video;

    return Material(
      color: Colors.transparent,
      child: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment(-0.3, -1),
            end: Alignment(0.3, 1),
            colors: [Color(0xFF1A0800), Color(0xFF0D1B2A)],
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Column(
              children: [
                const Spacer(flex: 2),

                // Header label
                Text(
                  'Incoming ${isVideo ? 'Video' : 'Audio'} Call',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.5),
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 2,
                  ),
                ),

                const SizedBox(height: 32),

                // Avatar with pulse ring
                SizedBox(
                  width: 140,
                  height: 140,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      // Pulse ring: 2.2s scale 1 -> 1.6, opacity 1 -> 0
                      AnimatedBuilder(
                        animation: _pulseController,
                        builder: (_, _) {
                          return Transform.scale(
                            scale: _pulseAnimation.value,
                            child: Container(
                              width: 140,
                              height: 140,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: const Color(0xFFE67E22).withValues(
                                    alpha: _pulseOpacityAnimation.value * 0.5,
                                  ),
                                  width: 2,
                                ),
                              ),
                            ),
                          );
                        },
                      ),

                      // Avatar: 52px radius => 112px shown in overlay, border 2px white/15
                      Container(
                        width: 112,
                        height: 112,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: Colors.white.withValues(alpha: 0.15),
                            width: 2,
                          ),
                        ),
                        child: ClipOval(
                          child: callerPhoto != null
                              ? Image.network(
                                  callerPhoto,
                                  fit: BoxFit.cover,
                                  errorBuilder: (_, _, _) =>
                                      _buildFallbackAvatar(callerName),
                                )
                              : _buildFallbackAvatar(callerName),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 24),

                // Caller name
                Text(
                  callerName,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                  ),
                ),

                const SizedBox(height: 8),

                // Subtitle
                Text(
                  'Tander ${isVideo ? 'Video' : 'Audio'} Call',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.45),
                    fontSize: 14,
                  ),
                ),

                // Error message
                if (callState.errorMessage != null) ...[
                  const SizedBox(height: 12),
                  Text(
                    callState.errorMessage!,
                    style: TextStyle(color: Colors.red.shade400, fontSize: 12),
                  ),
                ],

                const Spacer(flex: 3),

                // Accept / Decline buttons: h48px radius 14px
                Row(
                  children: [
                    // Decline: bg red-600/20, text red-400
                    Expanded(
                      child: _OverlayActionButton(
                        onTap: () {
                          ref.read(callManagerProvider).declineCall();
                        },
                        backgroundColor: const Color(
                          0xFFDC2626,
                        ).withValues(alpha: 0.2),
                        iconColor: Colors.red.shade400,
                        textColor: Colors.red.shade400,
                        icon: Icons.phone_disabled,
                        label: 'Decline',
                      ),
                    ),

                    const SizedBox(width: 12),

                    // Accept: bg-green-600, text white, shadow
                    Expanded(
                      child: _OverlayActionButton(
                        onTap: _isAccepting
                            ? null
                            : () {
                                setState(() => _isAccepting = true);
                                final callManager = ref.read(
                                  callManagerProvider,
                                );
                                // Capture router + room before the async gap so
                                // we never touch `context` after acceptCall()
                                // completes (overlay may be disposed by then).
                                final router = GoRouter.of(context);
                                final roomName = callInfo.roomName;
                                callManager
                                    .acceptCall()
                                    .then((_) {
                                      if (mounted && roomName.isNotEmpty) {
                                        router.push(AppRoutes.call(roomName));
                                      }
                                    })
                                    .catchError((_) {
                                      if (mounted) {
                                        setState(() => _isAccepting = false);
                                      }
                                    });
                              },
                        backgroundColor: const Color(0xFF16A34A),
                        iconColor: Colors.white,
                        textColor: Colors.white,
                        icon: isVideo ? Icons.videocam : Icons.phone,
                        label: _isAccepting ? 'Connecting...' : 'Accept',
                        boxShadow: BoxShadow(
                          color: const Color(
                            0xFF16A34A,
                          ).withValues(alpha: 0.35),
                          blurRadius: 16,
                          offset: const Offset(0, 4),
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 48),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFallbackAvatar(String name) {
    return Container(
      color: const Color(0xFF2D1F14),
      child: Center(
        child: Text(
          name.isNotEmpty ? name[0].toUpperCase() : '?',
          style: const TextStyle(
            color: Color(0xFFE67E22),
            fontSize: 40,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Action button — h48px, radius 14px
// ---------------------------------------------------------------------------

class _OverlayActionButton extends StatelessWidget {
  const _OverlayActionButton({
    required this.onTap,
    required this.backgroundColor,
    required this.iconColor,
    required this.textColor,
    required this.icon,
    required this.label,
    this.boxShadow,
  });

  final VoidCallback? onTap;
  final Color backgroundColor;
  final Color iconColor;
  final Color textColor;
  final IconData icon;
  final String label;
  final BoxShadow? boxShadow;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedOpacity(
        opacity: onTap != null ? 1.0 : 0.6,
        duration: const Duration(milliseconds: 150),
        child: Container(
          height: 48,
          decoration: BoxDecoration(
            color: backgroundColor,
            borderRadius: BorderRadius.circular(14),
            boxShadow: boxShadow != null ? [boxShadow!] : null,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 18, color: iconColor),
              const SizedBox(width: 8),
              Text(
                label,
                style: TextStyle(
                  color: textColor,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
