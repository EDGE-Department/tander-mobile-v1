import 'package:flutter/material.dart';

import 'package:tander_flutter_v3/features/tandy/presentation/widgets/tandy_constants.dart';
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
        // Welcome card
        ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 480),
          child: const TandyWelcomeCard(),
        ),
        const SizedBox(height: 20),

        // Avatar + greeting
        ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 440),
          child: Column(
            children: <Widget>[
              // Avatar
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: const LinearGradient(
                    begin: Alignment(-0.5, -0.5),
                    end: Alignment(0.5, 0.5),
                    colors: <Color>[Colors.white, Color(0xFFFFF6E8)],
                  ),
                  border: Border.all(
                    color: kTandyOrange.withAlpha(46),
                    width: 2,
                  ),
                  boxShadow: <BoxShadow>[
                    BoxShadow(
                      color: kTandyOrange.withAlpha(36),
                      blurRadius: 28,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.auto_awesome,
                  size: 36,
                  color: kTandyOrange,
                ),
              ),
              const SizedBox(height: 16),

              Text(
                greeting,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontWeight: FontWeight.w800,
                  fontSize: 22,
                  color: Color(0xFF1F2937),
                  letterSpacing: -0.6,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Tell Tandy how you are feeling, or try one of the activities below.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 14.5,
                  color: Color(0xFF7B7068),
                  height: 1.65,
                ),
              ),

              // Mood check-in
              if (onMoodSelect != null) ...<Widget>[
                const SizedBox(height: 20),
                TandyMoodCheckin(onMoodSelect: onMoodSelect!),
              ],

              // Quick actions
              if (onBreathingTap != null && onMeditationTap != null) ...<Widget>[
                const SizedBox(height: 16),
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
