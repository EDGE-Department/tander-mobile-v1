/// Section widgets for the profile screen loaded state (part 1).
///
/// Contains: [ProfileActionRow], [ProfileMetricRow],
/// [ProfileCompletionSection]. Data holders and builder functions are
/// in `profile_section_builders.dart`, re-exported from here.
library;

import 'package:flutter/material.dart';

import 'package:tander_flutter_v3/core/theme/app_colors.dart';
import 'package:tander_flutter_v3/core/theme/app_radius.dart';
import 'package:tander_flutter_v3/core/theme/app_shadows.dart';
import 'package:tander_flutter_v3/core/theme/app_spacing.dart';
import 'package:tander_flutter_v3/core/theme/app_typography.dart';
import 'package:tander_flutter_v3/features/profile/presentation/widgets/profile_helpers.dart';
import 'package:tander_flutter_v3/features/profile/presentation/widgets/profile_page_components.dart';
import 'package:tander_flutter_v3/features/profile/presentation/widgets/profile_section_builders.dart';

// Re-export so callers can import everything from one file.
export 'package:tander_flutter_v3/features/profile/presentation/widgets/profile_content_sections.dart';
export 'package:tander_flutter_v3/features/profile/presentation/widgets/profile_section_builders.dart';

// ── Action row ─────────────────────────────────────────────────────────

class ProfileActionRow extends StatelessWidget {
  const ProfileActionRow({
    required this.onEdit,
    required this.onPhotos,
    required this.onSettings,
    required this.onHelp,
    super.key,
  });

  final VoidCallback onEdit;
  final VoidCallback onPhotos;
  final VoidCallback onSettings;
  final VoidCallback onHelp;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          _PrimaryAction(label: 'Edit profile', onTap: onEdit),
          const SizedBox(width: AppSpacing.xs),
          _SecondaryAction(
            icon: Icons.photo_library,
            label: 'Photos',
            onTap: onPhotos,
          ),
          const SizedBox(width: AppSpacing.xs),
          _SecondaryAction(
            icon: Icons.settings,
            label: 'Settings',
            onTap: onSettings,
          ),
          const SizedBox(width: AppSpacing.xs),
          _SecondaryAction(
            icon: Icons.help_outline,
            label: 'Help',
            onTap: onHelp,
          ),
        ],
      ),
    );
  }
}

class _PrimaryAction extends StatelessWidget {
  const _PrimaryAction({required this.label, required this.onTap});
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        constraints:
            const BoxConstraints(minHeight: AppSpacing.touchMinimum),
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.lg,
          vertical: AppSpacing.sm,
        ),
        decoration: BoxDecoration(
          color: AppColors.primary,
          borderRadius: AppRadius.borderMd,
          boxShadow: AppShadows.warmSm,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.edit,
              size: 16,
              color: AppColors.textInverse,
            ),
            const SizedBox(width: AppSpacing.xs),
            Text(
              label,
              style: AppTypography.label.copyWith(
                color: AppColors.textInverse,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SecondaryAction extends StatelessWidget {
  const _SecondaryAction({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        constraints:
            const BoxConstraints(minHeight: AppSpacing.touchMinimum),
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.sm,
        ),
        decoration: BoxDecoration(
          color: AppColors.card,
          borderRadius: AppRadius.borderMd,
          border: Border.all(color: AppColors.border),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 15, color: AppColors.textBody),
            const SizedBox(width: AppSpacing.xxs),
            Text(label, style: AppTypography.label),
          ],
        ),
      ),
    );
  }
}

// ── Metric row ─────────────────────────────────────────────────────────

class ProfileMetricRow extends StatelessWidget {
  const ProfileMetricRow({
    required this.completionPercent,
    required this.photoCount,
    required this.interestCount,
    super.key,
  });

  final int completionPercent;
  final int photoCount;
  final int interestCount;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: MetricTile(
            label: 'Strength',
            value: '$completionPercent%',
            tone: ProfileTone.primary,
          ),
        ),
        const SizedBox(width: 6),
        Expanded(
          child: MetricTile(
            label: 'Photos',
            value: '$photoCount/$maxPhotos',
            tone: ProfileTone.secondary,
          ),
        ),
        const SizedBox(width: 6),
        Expanded(
          child: MetricTile(
            label: 'Interests',
            value: '$interestCount',
            tone: ProfileTone.warm,
          ),
        ),
      ],
    );
  }
}

// ── Completion section ─────────────────────────────────────────────────

class ProfileCompletionSection extends StatelessWidget {
  const ProfileCompletionSection({
    required this.completionPercent,
    required this.tips,
    super.key,
  });

  final int completionPercent;
  final List<CompletionTipData> tips;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: AppRadius.borderLg,
        border: Border.all(color: AppColors.border),
        boxShadow: AppShadows.warmXs,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Profile strength', style: AppTypography.h3),
              Text(
                '$completionPercent%',
                style: AppTypography.label.copyWith(
                  color: AppColors.primary,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.xs),
          ClipRRect(
            borderRadius: AppRadius.borderFull,
            child: SizedBox(
              height: 6,
              child: Stack(
                children: [
                  Container(color: AppColors.subtle),
                  FractionallySizedBox(
                    widthFactor: completionPercent / 100,
                    child: Container(
                      decoration: const BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            AppColors.primary,
                            AppColors.secondary,
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          for (int index = 0; index < tips.length; index++) ...[
            if (index > 0) const SizedBox(height: AppSpacing.xs),
            CompletionTip(
              label: tips[index].label,
              actionLabel: tips[index].actionLabel,
              boost: tips[index].boost,
              onTap: tips[index].onTap,
            ),
          ],
        ],
      ),
    );
  }
}

