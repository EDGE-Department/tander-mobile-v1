import 'package:flutter/material.dart';

import 'package:tander_flutter_v3/core/theme/app_colors.dart';
import 'package:tander_flutter_v3/core/theme/app_typography.dart';

const Color _orange = AppColors.primary;

/// Circle avatar with an animated unread gradient ring and online dot.
///
/// When [hasUnread] is `true`, a pulsing glow ring animates around the avatar
/// matching the web's `m-pulse-ring` keyframes at 2.6 s period.
class ConversationAvatarRing extends StatefulWidget {
  const ConversationAvatarRing({
    super.key,
    required this.photoUrl,
    required this.username,
    required this.hasUnread,
    required this.isOnline,
  });

  final String? photoUrl;
  final String username;
  final bool hasUnread;
  final bool isOnline;

  @override
  State<ConversationAvatarRing> createState() =>
      _ConversationAvatarRingState();
}

class _ConversationAvatarRingState extends State<ConversationAvatarRing>
    with SingleTickerProviderStateMixin {
  AnimationController? _pulseController;

  @override
  void initState() {
    super.initState();
    _startPulseIfNeeded();
  }

  @override
  void didUpdateWidget(ConversationAvatarRing oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.hasUnread != oldWidget.hasUnread) {
      _startPulseIfNeeded();
    }
  }

  void _startPulseIfNeeded() {
    if (widget.hasUnread && _pulseController == null) {
      _pulseController = AnimationController(
        vsync: this,
        duration: const Duration(milliseconds: 2600),
      )..repeat();
    } else if (!widget.hasUnread && _pulseController != null) {
      _pulseController!.dispose();
      _pulseController = null;
    }
  }

  @override
  void dispose() {
    _pulseController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final avatar = CircleAvatar(
      radius: 24,
      backgroundColor: const Color(0xFFFEFAF4),
      backgroundImage:
          widget.photoUrl != null ? NetworkImage(widget.photoUrl!) : null,
      child: widget.photoUrl == null
          ? Text(
              _computeInitials(widget.username),
              style: AppTypography.h3.copyWith(color: _orange),
            )
          : null,
    );

    if (!widget.hasUnread) return avatar;

    return AnimatedBuilder(
      animation: _pulseController!,
      builder: (context, child) {
        final progress = _pulseController!.value;
        // Pulse: 0..55 % shadow grows to 5 px, 55..100 % fades back to 0.
        final shadowRadius = progress < 0.55
            ? (progress / 0.55) * 5.0
            : (1 - ((progress - 0.55) / 0.45)) * 5.0;
        final shadowOpacity = progress < 0.55
            ? 0.40
            : 0.40 * (1 - ((progress - 0.55) / 0.45));

        return Container(
          padding: const EdgeInsets.all(2.5),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [_orange, Color(0xFFF7B23C)],
            ),
            boxShadow: [
              BoxShadow(
                color: _orange.withValues(alpha: shadowOpacity),
                spreadRadius: shadowRadius,
              ),
            ],
          ),
          child: Container(
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              color: Color(0xFFFEFAF4),
            ),
            child: child,
          ),
        );
      },
      child: avatar,
    );
  }
}

/// Computes first + last initials from a display name.
/// "ROBERTO TUBIG DREZ" → "RD", "Alice" → "A", "" → "?"
String _computeInitials(String name) {
  final trimmed = name.trim();
  if (trimmed.isEmpty) return '?';
  final parts = trimmed.split(RegExp(r'\s+')).where((part) => part.isNotEmpty).toList();
  if (parts.isEmpty) return '?';
  if (parts.length == 1) return parts[0][0].toUpperCase();
  return '${parts.first[0]}${parts.last[0]}'.toUpperCase();
}
