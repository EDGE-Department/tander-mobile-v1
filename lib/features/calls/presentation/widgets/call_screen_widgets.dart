import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import 'package:tander_flutter_v3/features/calls/domain/call_types.dart';
import 'package:tander_flutter_v3/features/calls/presentation/states/call_state.dart';

// ---------------------------------------------------------------------------
// Gradient used across call screen layouts
// ---------------------------------------------------------------------------

const LinearGradient callBackgroundGradient = LinearGradient(
  begin: Alignment(-0.4, -1),
  end: Alignment(0.4, 1),
  colors: [Color(0xFF1A0800), Color(0xFF0D0A06), Color(0xFF06100E)],
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
        border: Border.all(color: Colors.white12, width: 3),
        boxShadow: const [BoxShadow(blurRadius: 32, color: Colors.black45)],
      ),
      child: ClipOval(
        child: photoUrl != null
            ? Image.network(
                photoUrl!,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) =>
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
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          CallAvatar(
            photoUrl: callState.callInfo?.remotePhotoUrl,
            displayName: displayName,
            radius: 56,
          ),
          const SizedBox(height: 16),
          Text(
            displayName,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.bold,
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            callStatusText(callState),
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.5),
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
          if (callState.remoteMedia.isAudioMuted && callState.isConnected) ...[
            const SizedBox(height: 8),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(PhosphorIconsFill.microphoneSlash,
                    size: 13, color: Colors.white.withValues(alpha: 0.3)),
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
            CallAvatar(
              photoUrl: callState.callInfo?.remotePhotoUrl,
              displayName: displayName,
              radius: 48,
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
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.05),
                shape: BoxShape.circle,
              ),
              child: Icon(PhosphorIconsFill.phoneSlash,
                  size: 36, color: Colors.red.withValues(alpha: 0.8)),
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
            TextButton(
              onPressed: onReturn,
              style: TextButton.styleFrom(
                backgroundColor: Colors.white.withValues(alpha: 0.1),
                padding:
                    const EdgeInsets.symmetric(horizontal: 32, vertical: 14),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16)),
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
          color: isActive ? Colors.white : Colors.white.withValues(alpha: 0.15),
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
        decoration: BoxDecoration(
          color: Colors.red.shade700,
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: Colors.red.withValues(alpha: 0.35),
              blurRadius: 24,
              offset: const Offset(0, 4),
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

