import 'package:flutter/material.dart';

import 'package:tander_flutter_v3/features/tandy/presentation/widgets/tandy_constants.dart';

/// Warm, elder-friendly pill shown above assistant message bubbles
/// when Tandy detects an emotion in the conversation.
class EmotionIndicatorWidget extends StatelessWidget {
  const EmotionIndicatorWidget({required this.emotion, super.key});

  final String emotion;

  @override
  Widget build(BuildContext context) {
    final emotionStyle =
        kEmotionStyles[emotion.toLowerCase()] ?? kFallbackEmotionStyle;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(9999),
        gradient: LinearGradient(
          colors: <Color>[
            emotionStyle.backgroundFrom,
            emotionStyle.backgroundTo,
          ],
        ),
        border: Border.all(color: emotionStyle.borderColor),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Text(emotionStyle.emoji, style: const TextStyle(fontSize: 16)),
          const SizedBox(width: 6),
          Text(
            emotionStyle.label,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: emotionStyle.textColor,
            ),
          ),
        ],
      ),
    );
  }
}
