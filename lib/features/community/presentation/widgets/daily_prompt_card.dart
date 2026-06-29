/// Teal gradient daily prompt card shown at the top of the community feed.
///
/// Rotates through a set of daily prompts based on the day of the week.
library;

import 'package:flutter/material.dart';

import 'package:tander_flutter_v3/core/theme/app_colors.dart';
import 'package:tander_flutter_v3/core/theme/app_radius.dart';
import 'package:tander_flutter_v3/core/theme/app_spacing.dart';

// ── Prompt definitions ─────────────────────────────────────────────────

const List<_DailyPrompt> _dailyPrompts = [
  _DailyPrompt(
    question: 'What brought a smile to your face today?',
    icon: Icons.sentiment_satisfied_alt_rounded,
  ),
  _DailyPrompt(
    question: 'Share a memory that made you smile.',
    icon: Icons.home_rounded,
  ),
  _DailyPrompt(
    question: 'What is the best piece of advice you ever received?',
    icon: Icons.lightbulb_rounded,
  ),
  _DailyPrompt(
    question: 'What hobby would you love to share with a new friend?',
    icon: Icons.palette_rounded,
  ),
  _DailyPrompt(
    question:
        'What is your favorite Filipino dish — and who first made it for you?',
    icon: Icons.restaurant_rounded,
  ),
  _DailyPrompt(
    question: 'Describe your perfect afternoon.',
    icon: Icons.wb_sunny_rounded,
  ),
  _DailyPrompt(
    question: 'What song brings back a wonderful memory?',
    icon: Icons.music_note_rounded,
  ),
];

const List<String> _dayNames = [
  'Sunday',
  'Monday',
  'Tuesday',
  'Wednesday',
  'Thursday',
  'Friday',
  'Saturday',
];

const List<String> _quickStarters = [
  'Share a photo',
  'Tell a story',
  'Ask a question',
];

@immutable
class _DailyPrompt {
  const _DailyPrompt({required this.question, required this.icon});

  final String question;
  final IconData icon;
}

// ── Widget ─────────────────────────────────────────────────────────────

class DailyPromptCard extends StatelessWidget {
  const DailyPromptCard({required this.onWriteStory, super.key});

  final VoidCallback onWriteStory;

  @override
  Widget build(BuildContext context) {
    final todayIndex = DateTime.now().weekday % _dailyPrompts.length;
    final prompt = _dailyPrompts[todayIndex];
    final dayName = _dayNames[DateTime.now().weekday % 7];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _PromptCard(
          prompt: prompt,
          dayName: dayName,
          onWriteStory: onWriteStory,
        ),
        const SizedBox(height: AppSpacing.sm),
        _QuickStartChips(onTap: onWriteStory),
      ],
    );
  }
}

// ── Gradient card ──────────────────────────────────────────────────────

class _PromptCard extends StatelessWidget {
  const _PromptCard({
    required this.prompt,
    required this.dayName,
    required this.onWriteStory,
  });

  final _DailyPrompt prompt;
  final String dayName;
  final VoidCallback onWriteStory;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment(-0.6, -1),
          end: Alignment(0.6, 1),
          colors: [Color(0xFF0A7068), Color(0xFF0F9D94), Color(0xFF15C0B6)],
        ),
        borderRadius: BorderRadius.circular(AppRadius.xxl),
        boxShadow: const [
          BoxShadow(
            color: Color(0x470F9D94),
            blurRadius: 32,
            offset: Offset(0, 8),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Day badge row.
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.sm,
                    vertical: AppSpacing.xxs + 2,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.15),
                    borderRadius: AppRadius.borderFull,
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.20),
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        prompt.icon,
                        size: 14,
                        color: Colors.white.withValues(alpha: 0.80),
                      ),
                      const SizedBox(width: AppSpacing.xxs),
                      Text(
                        dayName.toUpperCase(),
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.90),
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 1.2,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Container(
                    height: 1,
                    color: Colors.white.withValues(alpha: 0.12),
                  ),
                ),
                const SizedBox(width: AppSpacing.xs),
                Icon(
                  Icons.auto_awesome_rounded,
                  size: 16,
                  color: Colors.white.withValues(alpha: 0.20),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.md),
            // Question text.
            Text(
              prompt.question,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 21,
                fontWeight: FontWeight.w700,
                height: 1.35,
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            // CTA button.
            GestureDetector(
              onTap: onWriteStory,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.lg,
                  vertical: AppSpacing.sm,
                ),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.22),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.35),
                    width: 1.5,
                  ),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.edit_rounded, size: 16, color: Colors.white),
                    SizedBox(width: AppSpacing.xs),
                    Text(
                      'Share your story',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Quick-start chips ──────────────────────────────────────────────────

class _QuickStartChips extends StatelessWidget {
  const _QuickStartChips({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: AppSpacing.xs,
      runSpacing: AppSpacing.xs,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        const Text(
          'or start with',
          style: TextStyle(
            fontSize: 12,
            color: AppColors.textMuted,
            fontWeight: FontWeight.w500,
          ),
        ),
        for (final label in _quickStarters)
          GestureDetector(
            onTap: onTap,
            child: Container(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.sm + 2,
                vertical: AppSpacing.xs,
              ),
              decoration: BoxDecoration(
                color: AppColors.card,
                borderRadius: AppRadius.borderFull,
                border: Border.all(color: AppColors.border),
              ),
              child: Text(
                label,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textMuted,
                ),
              ),
            ),
          ),
      ],
    );
  }
}
