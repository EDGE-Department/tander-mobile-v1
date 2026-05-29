/// Reusable presentation-only widgets for the profile screens.
///
/// Each widget is a single-responsibility, stateless building block:
/// [ActionCard], [MetricTile], [CompletionTip], [InterestChip],
/// [SectionCard], [FactRow], and [EmptyPrompt].
///
/// For [PhotoGrid], see `profile_photo_grid.dart`.
library;

import 'package:flutter/material.dart';

import 'package:tander_flutter_v3/core/theme/app_colors.dart';
import 'package:tander_flutter_v3/core/theme/app_radius.dart';
import 'package:tander_flutter_v3/core/theme/app_shadows.dart';
import 'package:tander_flutter_v3/core/theme/app_spacing.dart';
import 'package:tander_flutter_v3/core/theme/app_typography.dart';

// ── Tone type ────────────────────────────────────────────────────────────

/// Accent color palette used across metric tiles, fact rows, and chips.
enum ProfileTone { primary, secondary, warm }

/// Resolves the background color for [tone].
Color toneBackground(ProfileTone tone) => switch (tone) {
  ProfileTone.primary => AppColors.primaryLight,
  ProfileTone.secondary => AppColors.secondaryLight,
  ProfileTone.warm => const Color(0xFFFFF4E8),
};

/// Resolves the foreground (text/icon) color for [tone].
Color toneForeground(ProfileTone tone) => switch (tone) {
  ProfileTone.primary => AppColors.primaryAccessible,
  ProfileTone.secondary => AppColors.secondary,
  ProfileTone.warm => const Color(0xFF956021),
};

// ── Action card ──────────────────────────────────────────────────────────

/// Row button with leading icon, label, and trailing chevron.
class ActionCard extends StatelessWidget {
  const ActionCard({
    required this.icon,
    required this.label,
    required this.onTap,
    super.key,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.card,
      borderRadius: AppRadius.borderLg,
      child: InkWell(
        onTap: onTap,
        borderRadius: AppRadius.borderLg,
        child: Container(
          constraints: const BoxConstraints(minHeight: AppSpacing.touchMinimum),
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md,
            vertical: AppSpacing.sm,
          ),
          decoration: BoxDecoration(
            border: Border.all(color: AppColors.border),
            borderRadius: AppRadius.borderLg,
          ),
          child: Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: AppColors.subtle,
                  borderRadius: AppRadius.borderMd,
                ),
                alignment: Alignment.center,
                child: Icon(icon, size: 18, color: AppColors.textStrong),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Text(
                  label,
                  style: AppTypography.label,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const Icon(
                Icons.chevron_right,
                size: 16,
                color: AppColors.textMuted,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Metric tile ──────────────────────────────────────────────────────────

/// Compact card displaying a numeric [value] with a [label] underneath.
class MetricTile extends StatelessWidget {
  const MetricTile({
    required this.label,
    required this.value,
    this.tone = ProfileTone.primary,
    super.key,
  });

  final String label;
  final String value;
  final ProfileTone tone;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.sm),
      decoration: BoxDecoration(
        color: toneBackground(tone),
        borderRadius: AppRadius.borderLg,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label.toUpperCase(),
            style: AppTypography.caption.copyWith(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              letterSpacing: 1.4,
              color: AppColors.textMuted,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: AppSpacing.xxs),
          Text(
            value,
            style: AppTypography.h2.copyWith(color: toneForeground(tone)),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}

// ── Completion tip ───────────────────────────────────────────────────────

/// Checklist-style card for a profile improvement suggestion.
class CompletionTip extends StatelessWidget {
  const CompletionTip({
    required this.label,
    required this.actionLabel,
    required this.boost,
    required this.onTap,
    super.key,
  });

  final String label;
  final String actionLabel;
  final String boost;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.subtle,
      borderRadius: AppRadius.borderLg,
      child: InkWell(
        onTap: onTap,
        borderRadius: AppRadius.borderLg,
        child: Container(
          constraints: const BoxConstraints(minHeight: AppSpacing.touchMinimum),
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.sm,
            vertical: AppSpacing.sm,
          ),
          decoration: BoxDecoration(
            border: Border.all(color: AppColors.border),
            borderRadius: AppRadius.borderLg,
          ),
          child: Row(
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: AppColors.primary,
                  borderRadius: AppRadius.borderSm,
                  boxShadow: AppShadows.warmXs,
                ),
                alignment: Alignment.center,
                child: Text(
                  boost,
                  style: AppTypography.caption.copyWith(
                    fontSize: 11,
                    fontWeight: FontWeight.w900,
                    color: AppColors.textInverse,
                  ),
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Text(
                  label,
                  style: AppTypography.label,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: AppSpacing.xs),
              Text(
                actionLabel,
                style: AppTypography.label.copyWith(color: AppColors.primary),
              ),
              const SizedBox(width: AppSpacing.xxs),
              const Icon(
                Icons.chevron_right,
                size: 12,
                color: AppColors.primary,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Interest chip ────────────────────────────────────────────────────────

/// Colored pill for a single interest tag.
class InterestChip extends StatelessWidget {
  const InterestChip({required this.label, required this.tone, super.key});

  final String label;
  final ProfileTone tone;

  @override
  Widget build(BuildContext context) {
    // Web: `px-5 py-3 text-[15px] font-bold border-2 rounded-2xl`
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      decoration: BoxDecoration(
        color: toneBackground(tone),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: toneForeground(tone).withValues(alpha: 0.20),
          width: 2,
        ),
        boxShadow: AppShadows.warmXs,
      ),
      child: Text(
        label,
        style: AppTypography.label.copyWith(
          fontSize: 15,
          fontWeight: FontWeight.w700,
          color: toneForeground(tone),
        ),
      ),
    );
  }
}

// ── Section card ─────────────────────────────────────────────────────────

/// Card container with an accent bar, title, and optional action button.
class SectionCard extends StatelessWidget {
  const SectionCard({
    required this.title,
    required this.child,
    this.actionLabel,
    this.onAction,
    super.key,
  });

  final String title;
  final Widget child;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: AppRadius.borderLg,
        border: Border.all(color: AppColors.border),
        boxShadow: AppShadows.warmXs,
      ),
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Container(
                width: 4,
                height: 16,
                decoration: BoxDecoration(
                  color: AppColors.primary,
                  borderRadius: AppRadius.borderFull,
                ),
              ),
              const SizedBox(width: AppSpacing.xs),
              Expanded(child: Text(title, style: AppTypography.h3)),
              if (actionLabel != null && onAction != null)
                GestureDetector(
                  onTap: onAction,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        actionLabel!,
                        style: AppTypography.label.copyWith(
                          color: AppColors.primary,
                        ),
                      ),
                      const SizedBox(width: 2),
                      const Icon(
                        Icons.chevron_right,
                        size: 14,
                        color: AppColors.primary,
                      ),
                    ],
                  ),
                ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          child,
        ],
      ),
    );
  }
}

// ── Fact row ─────────────────────────────────────────────────────────────

/// Single row showing an icon, label, and value — used in snapshot/details.
class FactRow extends StatelessWidget {
  const FactRow({
    required this.icon,
    required this.label,
    required this.value,
    this.tone = ProfileTone.primary,
    super.key,
  });

  final IconData icon;
  final String label;
  final String value;
  final ProfileTone tone;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
      child: Row(
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: toneBackground(tone),
              borderRadius: AppRadius.borderMd,
            ),
            alignment: Alignment.center,
            child: Icon(icon, size: 16, color: toneForeground(tone)),
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Text(
              label,
              style: AppTypography.bodySm.copyWith(color: AppColors.textMuted),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          Flexible(
            child: Text(
              value,
              style: AppTypography.label,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.end,
            ),
          ),
        ],
      ),
    );
  }
}

// ── Empty prompt ─────────────────────────────────────────────────────────

/// Placeholder shown when a section has no content yet.
class EmptyPrompt extends StatelessWidget {
  const EmptyPrompt({
    required this.text,
    required this.actionLabel,
    required this.onAction,
    super.key,
  });

  final String text;
  final String actionLabel;
  final VoidCallback onAction;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.subtle,
        borderRadius: AppRadius.borderLg,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            text,
            style: AppTypography.bodySm.copyWith(color: AppColors.textMuted),
          ),
          const SizedBox(height: AppSpacing.md),
          GestureDetector(
            onTap: onAction,
            child: Container(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.md,
                vertical: AppSpacing.xs,
              ),
              decoration: BoxDecoration(
                color: AppColors.primaryLight,
                borderRadius: AppRadius.borderFull,
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    actionLabel,
                    style: AppTypography.label.copyWith(
                      color: AppColors.primaryAccessible,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.xxs),
                  const Icon(
                    Icons.chevron_right,
                    size: 14,
                    color: AppColors.primaryAccessible,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
