import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import 'package:tander_flutter_v3/core/contracts/models/tandy_models.dart';
import 'package:tander_flutter_v3/core/theme/app_colors.dart';
import 'package:tander_flutter_v3/features/tandy/presentation/widgets/tandy_bubbles.dart';
import 'package:tander_flutter_v3/features/tandy/presentation/widgets/tandy_constants.dart';

/// Scrollable message list with date separators, grouped bubbles,
/// typing indicator, and structured block rendering.
class TandyMessageThread extends StatelessWidget {
  const TandyMessageThread({
    required this.messages,
    required this.isSending,
    required this.scrollController,
    super.key,
  });

  final List<TandyMessage> messages;
  final bool isSending;
  final ScrollController scrollController;

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      controller: scrollController,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      itemCount: messages.length + (isSending ? 1 : 0),
      itemBuilder: (_, index) {
        if (index == messages.length) return const _TypingBubble();

        final message = messages[index];
        final previousMessage = index > 0 ? messages[index - 1] : null;
        final nextMessage = index < messages.length - 1
            ? messages[index + 1]
            : null;

        final showDate =
            previousMessage == null ||
            !_isSameDay(previousMessage.sentAt, message.sentAt);
        final isGroupStart = previousMessage?.role != message.role;
        final isGroupEnd = nextMessage?.role != message.role;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            if (showDate) _DateSeparator(date: message.sentAt),
            MessageBubble(
              message: message,
              isGroupStart: isGroupStart,
              isGroupEnd: isGroupEnd,
            ),
          ],
        );
      },
    );
  }

  bool _isSameDay(DateTime left, DateTime right) {
    return left.year == right.year &&
        left.month == right.month &&
        left.day == right.day;
  }
}

// ── Date Separator ──────────────────────────────────────────────────

class _DateSeparator extends StatelessWidget {
  const _DateSeparator({required this.date});

  final DateTime date;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Row(
        children: <Widget>[
          const Expanded(child: Divider(color: AppColors.borderLight)),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
              decoration: BoxDecoration(
                color: Colors.white.withAlpha(200),
                borderRadius: BorderRadius.circular(999),
                border: Border.all(color: AppColors.borderLight),
              ),
              child: Text(
                _formatDateLabel(date),
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFFA09080),
                ),
              ),
            ),
          ),
          const Expanded(child: Divider(color: AppColors.borderLight)),
        ],
      ),
    );
  }

  String _formatDateLabel(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final dateOnly = DateTime(date.year, date.month, date.day);
    final yesterday = today.subtract(const Duration(days: 1));

    if (dateOnly == today) return 'Today';
    if (dateOnly == yesterday) return 'Yesterday';
    return DateFormat.yMMMd().format(date);
  }
}

// ── Typing Bubble ───────────────────────────────────────────────────

class _TypingBubble extends StatelessWidget {
  const _TypingBubble();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 20),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: <Widget>[
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: const LinearGradient(
                colors: <Color>[Color(0xFFFFF8EF), Color(0xFFFFECD8)],
              ),
              border: Border.all(color: kTandyOrange.withAlpha(56), width: 1.5),
            ),
            child: Center(
              child: Image.asset(
                'assets/icons/tandy_icon.png',
                width: 18,
                height: 18,
                fit: BoxFit.contain,
              ),
            ),
          ),
          const SizedBox(width: 10),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: <Color>[Color(0xFAEFFBF9), Color(0xF5FFFFFF)],
              ),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(6),
                topRight: Radius.circular(20),
                bottomRight: Radius.circular(20),
                bottomLeft: Radius.circular(6),
              ),
              border: Border.all(color: kTandyTeal.withAlpha(46), width: 1.5),
            ),
            child: const _TypingDots(),
          ),
        ],
      ),
    );
  }
}

class _TypingDots extends StatefulWidget {
  const _TypingDots();

  @override
  State<_TypingDots> createState() => _TypingDotsState();
}

class _TypingDotsState extends State<_TypingDots>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (_, _) {
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: List.generate(3, (index) {
            final delay = index * 0.2;
            final animationValue = ((_controller.value - delay) % 1.0).clamp(
              0.0,
              1.0,
            );
            final scale = 1.0 + 0.3 * _bounceCurve(animationValue);
            final opacity = 0.25 + 0.55 * _bounceCurve(animationValue);

            return Padding(
              padding: EdgeInsets.only(right: index < 2 ? 5 : 0),
              child: Transform.scale(
                scale: scale,
                child: Container(
                  width: 7,
                  height: 7,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: kTandyTeal.withValues(alpha: opacity),
                  ),
                ),
              ),
            );
          }),
        );
      },
    );
  }

  double _bounceCurve(double value) {
    if (value < 0.5) return value * 2;
    return (1.0 - value) * 2;
  }
}
