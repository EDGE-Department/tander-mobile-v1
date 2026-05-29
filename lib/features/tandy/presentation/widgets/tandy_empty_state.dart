import 'package:flutter/material.dart';

import 'package:tander_flutter_v3/features/tandy/presentation/widgets/tandy_mood_checkin.dart';
import 'package:tander_flutter_v3/features/tandy/presentation/widgets/tandy_quick_actions.dart';
import 'package:tander_flutter_v3/features/tandy/presentation/widgets/tandy_welcome_card.dart';

/// Empty state shown when the conversation has no messages.
///
/// Includes a welcome card, avatar, mood check-in, quick actions,
/// and a features grid.
class TandyEmptyState extends StatelessWidget {
  const TandyEmptyState({
    required this.greeting,
    this.onMoodSelect,
    this.onBreathingTap,
    this.onMeditationTap,
    this.onChatTap,
    this.onWellnessTap,
    super.key,
  });

  final String greeting;
  final void Function(String chatMessage)? onMoodSelect;
  final VoidCallback? onBreathingTap;
  final VoidCallback? onMeditationTap;
  final VoidCallback? onChatTap;
  final VoidCallback? onWellnessTap;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: <Widget>[
        ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 480),
          child: const TandyWelcomeCard(),
        ),
        const SizedBox(height: 24),
        ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 440),
          child: Column(
            children: <Widget>[
              Text(
                greeting,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 20,
                  color: Color(0xFF1F2937),
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'How are you feeling today?',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 15,
                  color: Color(0xFF7B7068),
                  height: 1.5,
                ),
              ),
              if (onMoodSelect != null) ...<Widget>[
                const SizedBox(height: 20),
                TandyMoodCheckin(onMoodSelect: onMoodSelect!),
              ],
              if (onBreathingTap != null &&
                  onMeditationTap != null) ...<Widget>[
                const SizedBox(height: 20),
                TandyQuickActions(
                  onBreathingTap: onBreathingTap!,
                  onMeditationTap: onMeditationTap!,
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}
