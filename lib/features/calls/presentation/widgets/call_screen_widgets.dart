import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import 'package:tander_flutter_v3/features/calls/domain/call_types.dart';
import 'package:tander_flutter_v3/features/calls/presentation/states/call_state.dart';

// ---------------------------------------------------------------------------
// Gradient used across call screen layouts
// bg gradient(160deg, #1A0800 0%, #0D0A06 40%, #06100E 100%)
// ---------------------------------------------------------------------------

const LinearGradient callBackgroundGradient = LinearGradient(
  begin: Alignment(-0.4, -1),
  end: Alignment(0.4, 1),
  colors: [Color(0xFF1A0800), Color(0xFF0D0A06), Color(0xFF06100E)],
  stops: [0.0, 0.4, 1.0],
);

// ---------------------------------------------------------------------------
// Status text helper
// ---------------------------------------------------------------------------

String callStatusText(CallState callState) {
  return switch (callState.status) {
    CallInitiating() => 'Starting call...',
    CallRinging() => 'Ringing...',
    CallConnecting() => 'Connecting...',
    CallConnected() => callState.formattedDuration,
    CallReconnecting() => 'Reconnecting...',
    CallEnded() => 'Call ended',
    CallFailed() => 'Call failed',
    CallIdle() => '',
  };
}

// ---------------------------------------------------------------------------
// Avatar with fallback
// w-28 h-28(112px) radius-full border 3px white/12, shadow 0 8px 32px rgba(0,0,0,0.40)
// ---------------------------------------------------------------------------

class CallAvatar extends StatelessWidget {
  const CallAvatar({
    required this.photoUrl,
    required this.displayName,
    required this.radius,
    super.key,
  });

  final String? photoUrl;
  final String displayName;
  final double radius;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: radius * 2,
      height: radius * 2,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.12),
          width: 3,
        ),
        boxShadow: const [
          BoxShadow(
            blurRadius: 32,
            color: Color(0x66000000),
            offset: Offset(0, 8),
          ),
        ],
      ),
      child: ClipOval(
        child: photoUrl != null
            ? Image.network(
                photoUrl!,
                fit: BoxFit.cover,
                errorBuilder: (_, _, _) =>
                    _AvatarFallback(displayName: displayName, radius: radius),
              )
            : _AvatarFallback(displayName: displayName, radius: radius),
      ),
    );
  }
}

class _AvatarFallback extends StatelessWidget {
  const _AvatarFallback({required this.displayName, required this.radius});

  final String displayName;
  final double radius;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xFF2D1F14),
      child: Center(
        child: Text(
          displayName.isNotEmpty ? displayName[0].toUpperCase() : '?',
          style: TextStyle(
            color: const Color(0xFFE67E22),
            fontSize: radius * 0.6,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Audio layout
// Ambient glow: radial-gradient(circle, #E67E22 0%, transparent 70%) opacity 0.06
// Pulse ring (pre-connect): -inset-4 border 2px rgba(230,126,34,0.30), scale 1->1.15 opacity 0.25->0.08 2.5s
// Connected ring: -inset-3 border-2 green-400/30, glow 3s
// Name: font-display bold clamp(1.25rem,3vw,1.75rem) white
// Status: white/50 sm tabular-nums
// ---------------------------------------------------------------------------

class CallAudioLayout extends StatelessWidget {
  const CallAudioLayout({
    required this.callState,
    required this.displayName,
    super.key,
  });

  final CallState callState;
  final String displayName;

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // Ambient glow
        Center(
          child: Transform.translate(
            offset: const Offset(0, -40),
            child: Container(
              width: 400,
              height: 400,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    const Color(0xFFE67E22).withValues(alpha: 0.06),
                    Colors.transparent,
                  ],
                  stops: const [0.0, 0.7],
                ),
              ),
            ),
          ),
        ),

        // Avatar + info
        Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Avatar with pulse/connected ring
              _AnimatedAvatarRing(
                callState: callState,
                displayName: displayName,
              ),
              const SizedBox(height: 16),
              // Name
              Text(
                displayName,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  letterSpacing: -0.5,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              // Status
              Text(
                callStatusText(callState),
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.5),
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
              // Remote mute indicator
              if (callState.remoteMedia.isAudioMuted &&
                  callState.isConnected) ...[
                const SizedBox(height: 8),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      PhosphorIconsFill.microphoneSlash,
                      size: 13,
                      color: Colors.white.withValues(alpha: 0.3),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      '$displayName is muted',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.3),
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Animated avatar ring — pulse during pre-connect, green glow when connected
// ---------------------------------------------------------------------------

class _AnimatedAvatarRing extends StatefulWidget {
  const _AnimatedAvatarRing({
    required this.callState,
    required this.displayName,
  });

  final CallState callState;
  final String displayName;

  @override
  State<_AnimatedAvatarRing> createState() => _AnimatedAvatarRingState();
}

class _AnimatedAvatarRingState extends State<_AnimatedAvatarRing>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _scaleAnimation;
  late final Animation<double> _opacityAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2500),
    )..repeat();

    _scaleAnimation = Tween<double>(begin: 1.0, end: 1.15).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );

    _opacityAnimation = Tween<double>(begin: 0.25, end: 0.08).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isPreConnect = widget.callState.isPreConnect;
    final isConnected = widget.callState.isConnected;

    return SizedBox(
      width: 144,
      height: 144,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Pre-connect pulse ring
          if (isPreConnect)
            AnimatedBuilder(
              animation: _controller,
              builder: (_, _) {
                return Transform.scale(
                  scale: _scaleAnimation.value,
                  child: Container(
                    width: 144,
                    height: 144,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: const Color(0xFFE67E22)
                            .withValues(alpha: _opacityAnimation.value),
                        width: 2,
                      ),
                    ),
                  ),
                );
              },
            ),

          // Connected green glow ring
          if (isConnected)
            Container(
              width: 136,
              height: 136,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: const Color(0xFF4ADE80).withValues(alpha: 0.3),
                  width: 2,
                ),
              ),
            ),

          // Avatar
          CallAvatar(
            photoUrl: widget.callState.callInfo?.remotePhotoUrl,
            displayName: widget.displayName,
            radius: 56,
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Pre-connect overlay (video calls only)
// ---------------------------------------------------------------------------

class CallPreConnectOverlay extends StatelessWidget {
  const CallPreConnectOverlay({
    required this.callState,
    required this.displayName,
    super.key,
  });

  final CallState callState;
  final String displayName;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(gradient: callBackgroundGradient),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // 96px diameter avatar with border
            Container(
              width: 96,
              height: 96,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: Colors.white.withValues(alpha: 0.15),
                  width: 2,
                ),
              ),
              child: ClipOval(
                child: callState.callInfo?.remotePhotoUrl != null
                    ? Image.network(
                        callState.callInfo!.remotePhotoUrl!,
                        fit: BoxFit.cover,
                        errorBuilder: (_, _, _) =>
                            _AvatarFallback(displayName: displayName, radius: 48),
                      )
                    : _AvatarFallback(displayName: displayName, radius: 48),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              displayName,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              callStatusText(callState),
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.5),
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Ended overlay
// ---------------------------------------------------------------------------

class CallEndedOverlay extends StatelessWidget {
  const CallEndedOverlay({
    required this.callState,
    required this.onReturn,
    super.key,
  });

  final CallState callState;
  final VoidCallback onReturn;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(gradient: callBackgroundGradient),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // w-20 h-20 rounded-full bg-white/5
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.05),
                shape: BoxShape.circle,
              ),
              child: Icon(
                PhosphorIconsFill.phoneSlash,
                size: 36,
                color: Colors.red.withValues(alpha: 0.8),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              callState.status is CallFailed ? 'Call failed' : 'Call ended',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            if (callState.errorMessage != null) ...[
              const SizedBox(height: 8),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 40),
                child: Text(
                  callState.errorMessage!,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.4),
                    fontSize: 14,
                  ),
                ),
              ),
            ],
            if (callState.durationSeconds > 0) ...[
              const SizedBox(height: 8),
              Text(
                callState.formattedDuration,
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.5),
                  fontSize: 14,
                ),
              ),
            ],
            const SizedBox(height: 20),
            // Return button: px-8 py-3 bg-white/10 rounded-2xl
            TextButton(
              onPressed: onReturn,
              style: TextButton.styleFrom(
                backgroundColor: Colors.white.withValues(alpha: 0.1),
                padding:
                    const EdgeInsets.symmetric(horizontal: 32, vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              child: const Text(
                'Return',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Control buttons
// Mute/Camera: w-14 h-14(56px) radius-full, muted bg-white text-black, unmuted bg-white/15 text-white
// ---------------------------------------------------------------------------

class CallControlButton extends StatelessWidget {
  const CallControlButton({
    required this.onTap,
    required this.isActive,
    required this.icon,
    required this.label,
    super.key,
  });

  final VoidCallback onTap;
  final bool isActive;
  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 56,
        height: 56,
        decoration: BoxDecoration(
          color:
              isActive ? Colors.white : Colors.white.withValues(alpha: 0.15),
          shape: BoxShape.circle,
        ),
        child: Icon(
          icon,
          size: 22,
          color: isActive ? Colors.black : Colors.white,
          semanticLabel: label,
        ),
      ),
    );
  }
}

/// Hangup: w-16 h-16(64px) radius-full bg-red-600, shadow 0 4px 24px rgba(220,38,38,0.35)
class CallHangupButton extends StatelessWidget {
  const CallHangupButton({required this.onTap, super.key});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 64,
        height: 64,
        decoration: const BoxDecoration(
          color: Color(0xFFDC2626),
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: Color(0x59DC2626),
              blurRadius: 24,
              offset: Offset(0, 4),
            ),
          ],
        ),
        child: const Icon(
          PhosphorIconsFill.phoneSlash,
          size: 26,
          color: Colors.white,
          semanticLabel: 'End call',
        ),
      ),
    );
  }
}
