import 'dart:async';

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import 'package:tander_flutter_v3/features/calls/domain/call_types.dart';
import 'package:tander_flutter_v3/features/calls/presentation/notifiers/call_manager.dart';
import 'package:tander_flutter_v3/features/calls/presentation/notifiers/call_notifier.dart';
import 'package:tander_flutter_v3/shared/constants/routes.dart';

// ---------------------------------------------------------------------------
// Incoming call overlay — full-screen when ringing + incoming
// ---------------------------------------------------------------------------

/// Full-screen overlay shown when an incoming call is ringing.
///
/// Displays caller avatar with pulse animation, accept/decline buttons,
/// and plays a ringtone via audioplayers. Auto-dismisses after timeout
/// (handled by [CallListener]).
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

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2200),
    )..repeat();

    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.6).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeOut),
    );
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

    // Play a simple tone-burst pattern (every 2.5 seconds)
    Future<void> playTone() async {
      try {
        // Use a generated tone via ToneGenerator-style short beep
        await _audioPlayer?.play(
          AssetSource('audio/ringtone.mp3'),
          volume: 0.5,
        );
      } on Exception {
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
          child: Column(
            children: [
              const Spacer(flex: 2),

              // Caller info header
              Text(
                'Incoming ${isVideo ? 'Video' : 'Audio'} Call',
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.5),
                  fontSize: 11,
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
                    // Pulse ring
                    AnimatedBuilder(
                      animation: _pulseAnimation,
                      builder: (_, __) {
                        return Container(
                          width: 140,
                          height: 140,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: const Color(0xFFE67E22)
                                  .withValues(alpha: 1.0 - (_pulseAnimation.value - 1.0) / 0.6),
                              width: 2,
                            ),
                          ),
                          transform: Matrix4.identity()
                            ..scale(_pulseAnimation.value),
                          transformAlignment: Alignment.center,
                        );
                      },
                    ),

                    // Avatar
                    Container(
                      width: 112,
                      height: 112,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white.withValues(alpha: 0.15), width: 2),
                      ),
                      child: ClipOval(
                        child: callerPhoto != null
                            ? Image.network(
                                callerPhoto,
                                fit: BoxFit.cover,
                                errorBuilder: (_, __, ___) =>
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

              Text(
                'Tander ${isVideo ? 'Video' : 'Audio'} Call',
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.45),
                  fontSize: 14,
                ),
              ),

              const Spacer(flex: 3),

              // Accept / Decline buttons
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 48),
                child: Row(
                  children: [
                    // Decline
                    Expanded(
                      child: _CallActionButton(
                        onTap: () {
                          ref.read(callManagerProvider).declineCall();
                        },
                        backgroundColor: Colors.red.shade700.withValues(alpha: 0.2),
                        iconColor: Colors.red.shade400,
                        icon: PhosphorIconsFill.phoneSlash,
                        label: 'Decline',
                      ),
                    ),

                    const SizedBox(width: 16),

                    // Accept
                    Expanded(
                      child: _CallActionButton(
                        onTap: _isAccepting
                            ? null
                            : () {
                                setState(() => _isAccepting = true);
                                final callManager =
                                    ref.read(callManagerProvider);
                                callManager.acceptCall().then((_) {
                                  if (mounted && callInfo.roomName.isNotEmpty) {
                                    context.push(
                                        AppRoutes.call(callInfo.roomName));
                                  }
                                }).catchError((_) {
                                  if (mounted) {
                                    setState(() => _isAccepting = false);
                                  }
                                });
                              },
                        backgroundColor: const Color(0xFF16A34A),
                        iconColor: Colors.white,
                        icon: isVideo
                            ? PhosphorIconsFill.videoCamera
                            : PhosphorIconsFill.phone,
                        label: _isAccepting ? 'Connecting...' : 'Accept',
                        boxShadow: BoxShadow(
                          color: const Color(0xFF16A34A).withValues(alpha: 0.35),
                          blurRadius: 16,
                          offset: const Offset(0, 4),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 48),
            ],
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
// Action button
// ---------------------------------------------------------------------------

class _CallActionButton extends StatelessWidget {
  const _CallActionButton({
    required this.onTap,
    required this.backgroundColor,
    required this.iconColor,
    required this.icon,
    required this.label,
    this.boxShadow,
  });

  final VoidCallback? onTap;
  final Color backgroundColor;
  final Color iconColor;
  final IconData icon;
  final String label;
  final BoxShadow? boxShadow;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
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
                color: iconColor,
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
