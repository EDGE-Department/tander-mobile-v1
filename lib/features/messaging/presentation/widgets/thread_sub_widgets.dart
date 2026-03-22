import 'package:flutter/material.dart';

import 'package:tander_flutter_v3/core/theme/app_colors.dart';
import 'package:tander_flutter_v3/core/theme/app_radius.dart';
import 'package:tander_flutter_v3/core/theme/app_spacing.dart';
import 'package:tander_flutter_v3/core/theme/app_typography.dart';

const Color _teal = AppColors.secondary;

// ─── Empty thread ─────────────────────────────────────────────────────────

/// Shown when a conversation has no messages yet.
class EmptyThreadWidget extends StatelessWidget {
  const EmptyThreadWidget({
    super.key,
    required this.participantName,
    required this.participantPhotoUrl,
  });

  final String participantName;
  final String? participantPhotoUrl;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 48),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 96,
              height: 96,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  colors: [
                    AppColors.primary.withValues(alpha: 0.3),
                    _teal.withValues(alpha: 0.2),
                  ],
                ),
              ),
              padding: const EdgeInsets.all(3),
              child: CircleAvatar(
                radius: 45,
                backgroundColor: const Color(0xFFFFF8EE),
                backgroundImage: participantPhotoUrl != null
                    ? NetworkImage(participantPhotoUrl!)
                    : null,
                child: participantPhotoUrl == null
                    ? Text(
                        participantName.isNotEmpty
                            ? participantName[0].toUpperCase()
                            : '?',
                        style: AppTypography.h1.copyWith(
                          color: AppColors.primary,
                        ),
                      )
                    : null,
              ),
            ),
            const SizedBox(height: 28),
            Text(
              'Say hello to $participantName',
              style: AppTypography.h3.copyWith(fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 8),
            Text(
              'Start with a quick check-in, a photo, or a voice note.',
              textAlign: TextAlign.center,
              style: AppTypography.bodySm.copyWith(
                color: const Color(0xFF6C6156),
                height: 1.7,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Only you and $participantName can see this conversation.',
              textAlign: TextAlign.center,
              style: AppTypography.caption.copyWith(
                color: const Color(0xFFA09080),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Date separator ───────────────────────────────────────────────────────

/// Centered pill showing the date between message groups.
class DateSeparatorWidget extends StatelessWidget {
  const DateSeparatorWidget({super.key, required this.date});

  final DateTime date;

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final yesterday = DateTime(now.year, now.month, now.day - 1);
    final today = DateTime(now.year, now.month, now.day);
    final dateOnly = DateTime(date.year, date.month, date.day);

    final label = dateOnly == today
        ? 'Today'
        : dateOnly == yesterday
            ? 'Yesterday'
            : '${_monthName(date.month)} ${date.day}, ${date.year}';

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 14),
      child: Row(
        children: [
          const Expanded(child: _GradientLine(toRight: true)),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
              decoration: BoxDecoration(
                borderRadius: AppRadius.borderFull,
                color: const Color(0xFFFFFDF7),
                border: Border.all(color: const Color(0x3DC4A88C)),
              ),
              child: Text(
                label.toUpperCase(),
                style: AppTypography.caption.copyWith(
                  fontSize: 11.5,
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFF927D66),
                  letterSpacing: 0.8,
                ),
              ),
            ),
          ),
          const Expanded(child: _GradientLine(toRight: false)),
        ],
      ),
    );
  }
}

class _GradientLine extends StatelessWidget {
  const _GradientLine({required this.toRight});

  final bool toRight;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 1,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: toRight
              ? [Colors.transparent, const Color(0xFF927D66).withValues(alpha: 0.34)]
              : [const Color(0xFF927D66).withValues(alpha: 0.34), Colors.transparent],
        ),
      ),
    );
  }
}

// ─── Typing bubble ────────────────────────────────────────────────────────

/// Animated dots shown when the other participant is typing.
class TypingBubbleWidget extends StatelessWidget {
  const TypingBubbleWidget({
    super.key,
    required this.participantName,
    required this.participantPhotoUrl,
  });

  final String participantName;
  final String? participantPhotoUrl;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 20),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          CircleAvatar(
            radius: 19,
            backgroundColor: const Color(0xFFEEF9F8),
            backgroundImage: participantPhotoUrl != null
                ? NetworkImage(participantPhotoUrl!)
                : null,
            child: participantPhotoUrl == null
                ? Text(
                    participantName.isNotEmpty
                        ? participantName[0].toUpperCase()
                        : '?',
                    style: AppTypography.caption.copyWith(color: _teal),
                  )
                : null,
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
            decoration: BoxDecoration(
              color: const Color(0xFFF4FCFB),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(26),
                topRight: Radius.circular(26),
                bottomRight: Radius.circular(26),
                bottomLeft: Radius.circular(10),
              ),
              border: Border.all(
                color: _teal.withValues(alpha: 0.14),
                width: 1.5,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: List.generate(3, (index) {
                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 2),
                  child: _TypingDot(delayMs: index * 220),
                );
              }),
            ),
          ),
        ],
      ),
    );
  }
}

class _TypingDot extends StatefulWidget {
  const _TypingDot({required this.delayMs});

  final int delayMs;

  @override
  State<_TypingDot> createState() => _TypingDotState();
}

class _TypingDotState extends State<_TypingDot>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _opacityAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );
    _opacityAnimation = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 0.25, end: 0.80), weight: 50),
      TweenSequenceItem(tween: Tween(begin: 0.80, end: 0.25), weight: 50),
    ]).animate(_controller);

    Future.delayed(Duration(milliseconds: widget.delayMs), () {
      if (mounted) _controller.repeat();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _opacityAnimation,
      child: Container(
        width: 7,
        height: 7,
        decoration: const BoxDecoration(
          shape: BoxShape.circle,
          color: Color(0xFF6C6156),
        ),
      ),
    );
  }
}

// ─── Thread skeleton ──────────────────────────────────────────────────────

/// Shimmer skeleton shown while messages are loading.
class ThreadSkeleton extends StatelessWidget {
  const ThreadSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Column(
        children: List.generate(5, (index) {
          final isRight = index.isEven;
          return Align(
            alignment: isRight ? Alignment.centerRight : Alignment.centerLeft,
            child: Container(
              margin: const EdgeInsets.symmetric(vertical: 6),
              width: 160 + (index % 3) * 40,
              height: 44,
              decoration: BoxDecoration(
                borderRadius: AppRadius.borderLg,
                color: AppColors.borderLight,
              ),
            ),
          );
        }),
      ),
    );
  }
}

// ─── Helpers ──────────────────────────────────────────────────────────────

String _monthName(int month) {
  const months = [
    'January', 'February', 'March', 'April', 'May', 'June',
    'July', 'August', 'September', 'October', 'November', 'December',
  ];
  return months[month - 1];
}

/// Returns true if two dates are on different calendar days.
bool isDifferentDay(DateTime dateA, DateTime dateB) {
  return dateA.year != dateB.year ||
      dateA.month != dateB.month ||
      dateA.day != dateB.day;
}
