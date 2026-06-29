import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import 'package:tander_flutter_v3/core/contracts/models/tandy_models.dart';
import 'package:tander_flutter_v3/features/tandy/presentation/notifiers/tandy_notifier.dart';
import 'package:tander_flutter_v3/features/tandy/presentation/widgets/chat/emotion_indicator.dart';
import 'package:tander_flutter_v3/features/tandy/presentation/widgets/chat/structured_block_renderer.dart';
import 'package:tander_flutter_v3/features/tandy/presentation/widgets/tandy_constants.dart';

/// Dispatches to user or Tandy bubble based on message role.
class MessageBubble extends StatelessWidget {
  const MessageBubble({
    required this.message,
    required this.isGroupStart,
    required this.isGroupEnd,
    super.key,
  });

  final TandyMessage message;
  final bool isGroupStart;
  final bool isGroupEnd;

  @override
  Widget build(BuildContext context) {
    final isTandy = message.role == TandyMessageRole.assistant;
    final topGap = isGroupStart ? 20.0 : 4.0;
    final time = DateFormat.jm().format(message.sentAt);

    if (!isTandy) {
      return UserBubble(
        message: message,
        isGroupStart: isGroupStart,
        isGroupEnd: isGroupEnd,
        topGap: topGap,
        time: time,
      );
    }

    return TandyBubble(
      message: message,
      isGroupStart: isGroupStart,
      isGroupEnd: isGroupEnd,
      topGap: topGap,
      time: time,
    );
  }
}

// ── User Bubble ─────────────────────────────────────────────────────

class UserBubble extends StatelessWidget {
  const UserBubble({
    required this.message,
    required this.isGroupStart,
    required this.isGroupEnd,
    required this.topGap,
    required this.time,
    super.key,
  });

  final TandyMessage message;
  final bool isGroupStart;
  final bool isGroupEnd;
  final double topGap;
  final String time;

  @override
  Widget build(BuildContext context) {
    final userRadius = BorderRadius.only(
      topLeft: const Radius.circular(20),
      topRight: Radius.circular(isGroupStart ? 6 : 20),
      bottomRight: Radius.circular(isGroupEnd ? 6 : 20),
      bottomLeft: const Radius.circular(20),
    );

    return Padding(
      padding: EdgeInsets.only(top: topGap),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: <Widget>[
          if (isGroupStart)
            const Padding(
              padding: EdgeInsets.only(right: 8, bottom: 5),
              child: Text(
                'You',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFFB8AFA6),
                ),
              ),
            ),
          Align(
            alignment: Alignment.centerRight,
            child: ConstrainedBox(
              constraints: BoxConstraints(
                maxWidth: MediaQuery.sizeOf(context).width * 0.72,
              ),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 18,
                  vertical: 13,
                ),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: <Color>[
                      Color(0xFFF7B23C),
                      Color(0xFFEE8B23),
                      Color(0xFFDB6F18),
                    ],
                  ),
                  borderRadius: userRadius,
                  boxShadow: const <BoxShadow>[
                    BoxShadow(
                      color: Color(0x42E67E22),
                      blurRadius: 20,
                      offset: Offset(0, 6),
                    ),
                  ],
                ),
                child: Text(
                  message.body,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 15,
                    height: 1.65,
                  ),
                ),
              ),
            ),
          ),
          if (isGroupEnd)
            Padding(
              padding: const EdgeInsets.only(right: 8, top: 4),
              child: Text(
                time,
                style: const TextStyle(fontSize: 13, color: Color(0xFFC0B8B0)),
              ),
            ),
        ],
      ),
    );
  }
}

// ── Tandy Bubble ────────────────────────────────────────────────────

class TandyBubble extends StatelessWidget {
  const TandyBubble({
    required this.message,
    required this.isGroupStart,
    required this.isGroupEnd,
    required this.topGap,
    required this.time,
    super.key,
  });

  final TandyMessage message;
  final bool isGroupStart;
  final bool isGroupEnd;
  final double topGap;
  final String time;

  @override
  Widget build(BuildContext context) {
    final tandyRadius = BorderRadius.only(
      topLeft: Radius.circular(isGroupStart ? 6 : 20),
      topRight: const Radius.circular(20),
      bottomRight: const Radius.circular(20),
      bottomLeft: Radius.circular(isGroupEnd ? 6 : 20),
    );

    final hasBlocks = message.structuredBlocks.isNotEmpty;

    return Padding(
      padding: EdgeInsets.only(top: topGap),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          if (message.detectedEmotion != null && isGroupStart)
            Padding(
              padding: const EdgeInsets.only(left: 50, bottom: 4),
              child: EmotionIndicatorWidget(emotion: message.detectedEmotion!),
            ),

          if (isGroupStart)
            const Padding(
              padding: EdgeInsets.only(left: 50, bottom: 5),
              child: Text(
                'Tandy',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF0B8078),
                ),
              ),
            ),

          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: <Widget>[
              SizedBox(
                width: 38,
                child: isGroupEnd
                    ? Container(
                        width: 38,
                        height: 38,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: const LinearGradient(
                            colors: <Color>[
                              Color(0xFFFFF8EF),
                              Color(0xFFFFECD8),
                            ],
                          ),
                          border: Border.all(
                            color: kTandyOrange.withAlpha(56),
                            width: 1.5,
                          ),
                        ),
                        child: Center(
                          child: Image.asset(
                            'assets/icons/tandy_icon.png',
                            width: 18,
                            height: 18,
                            fit: BoxFit.contain,
                          ),
                        ),
                      )
                    : null,
              ),
              const SizedBox(width: 10),

              Flexible(
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                    maxWidth:
                        MediaQuery.sizeOf(context).width *
                        (hasBlocks ? 0.88 : 0.74),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 17,
                          vertical: 12,
                        ),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: <Color>[
                              Color(0xFAEFFBF9),
                              Color(0xF5FFFFFF),
                            ],
                          ),
                          borderRadius: tandyRadius,
                          border: Border.all(
                            color: kTandyTeal.withAlpha(41),
                            width: 1.5,
                          ),
                          boxShadow: <BoxShadow>[
                            BoxShadow(
                              color: kTandyTeal.withAlpha(26),
                              blurRadius: 18,
                              offset: const Offset(0, 6),
                            ),
                          ],
                        ),
                        child: Text(
                          message.body,
                          style: const TextStyle(
                            color: Color(0xFF243140),
                            fontSize: 15,
                            height: 1.65,
                          ),
                        ),
                      ),

                      if (hasBlocks)
                        Padding(
                          padding: const EdgeInsets.only(top: 8),
                          child: Column(
                            children: message.structuredBlocks
                                .map(
                                  (block) => Padding(
                                    padding: const EdgeInsets.only(bottom: 8),
                                    child: StructuredBlockRenderer(
                                      block: block,
                                      isExpanded: message.isCardExpanded,
                                    ),
                                  ),
                                )
                                .toList(),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ],
          ),

          if (isGroupEnd)
            Padding(
              padding: const EdgeInsets.only(left: 50, top: 6),
              child: Row(
                children: <Widget>[
                  Text(
                    time,
                    style: const TextStyle(
                      fontSize: 13,
                      color: Color(0xFFC0B8B0),
                    ),
                  ),
                  const SizedBox(width: 10),
                  _RatingButtons(message: message),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

// ── Rating buttons (👍 / 👎) ────────────────────────────────────────

/// Thumbs up / down on a Tandy reply. Optimistic — see TandyNotifier.rateMessage.
class _RatingButtons extends ConsumerWidget {
  const _RatingButtons({required this.message});

  final TandyMessage message;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final rating = message.rating;
    final isUp = rating == 1;
    final isDown = rating == -1;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        _RatingButton(
          icon: '👍',
          isActive: isUp,
          activeBg: const Color(0x2810B981),
          activeBorder: const Color(0x7310B981),
          onTap: () => _send(ref, isUp ? 0 : 1),
          tooltip: isUp ? 'Remove thumbs up' : 'Mark Tandy reply as helpful',
        ),
        const SizedBox(width: 4),
        _RatingButton(
          icon: '👎',
          isActive: isDown,
          activeBg: const Color(0x24EF4444),
          activeBorder: const Color(0x73EF4444),
          onTap: () => _send(ref, isDown ? 0 : -1),
          tooltip: isDown
              ? 'Remove thumbs down'
              : 'Mark Tandy reply as unhelpful',
        ),
      ],
    );
  }

  void _send(WidgetRef ref, int rating) {
    unawaited(
      ref
          .read(tandyNotifierProvider.notifier)
          .rateMessage(messageId: message.messageId, rating: rating),
    );
  }
}

class _RatingButton extends StatelessWidget {
  const _RatingButton({
    required this.icon,
    required this.isActive,
    required this.activeBg,
    required this.activeBorder,
    required this.onTap,
    required this.tooltip,
  });

  final String icon;
  final bool isActive;
  final Color activeBg;
  final Color activeBorder;
  final VoidCallback onTap;
  final String tooltip;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      // 30x30 visual, but a >=44dp hit area for accessibility.
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(22),
        child: SizedBox(
          width: 44,
          height: 44,
          child: Center(
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 120),
              width: 30,
              height: 30,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: isActive ? activeBg : const Color(0x99FFFFFF),
                border: Border.all(
                  color: isActive ? activeBorder : kTandyTeal.withAlpha(46),
                ),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(icon, style: const TextStyle(fontSize: 14)),
            ),
          ),
        ),
      ),
    );
  }
}
