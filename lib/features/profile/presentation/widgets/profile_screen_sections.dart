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

/// Web: flex items-center gap-4
/// Edit Profile: flex-1 h-14 rounded-[24px] bg-primary text-white
/// Settings/Help: w-14 h-14 rounded-[24px] border-2 bg-white icon-only
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
    return Row(
      children: [
        // Web: flex-1 h-14 rounded-[24px] bg-primary, font-black
        Expanded(
          child: GestureDetector(
            onTap: onEdit,
            child: Container(
              height: 56,
              decoration: BoxDecoration(
                color: AppColors.primary,
                borderRadius: BorderRadius.circular(24),
                boxShadow: const [
                  BoxShadow(
                    color: Color(0x80E67E22),
                    blurRadius: 24,
                    offset: Offset(0, 12),
                    spreadRadius: -8,
                  ),
                ],
              ),
              alignment: Alignment.center,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.edit, size: 20, color: Colors.white),
                  const SizedBox(width: 12),
                  Text(
                    'Edit Profile',
                    style: AppTypography.body.copyWith(
                      fontWeight: FontWeight.w900,
                      color: Colors.white,
                      fontSize: 16,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(width: 16),
        // Web: w-14 h-14 rounded-[24px] border-2 border-border bg-white
        _IconAction(icon: Icons.settings, onTap: onSettings),
        const SizedBox(width: 16),
        _IconAction(icon: Icons.help_outline, onTap: onHelp),
      ],
    );
  }
}

class _IconAction extends StatelessWidget {
  const _IconAction({required this.icon, required this.onTap});
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 56,
        height: 56,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: AppColors.border, width: 2),
        ),
        alignment: Alignment.center,
        child: Icon(icon, size: 24, color: AppColors.textBody),
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

