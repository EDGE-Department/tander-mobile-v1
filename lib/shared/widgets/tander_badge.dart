import 'package:flutter/material.dart';
import 'package:tander_flutter_v3/core/theme/app_colors.dart';
import 'package:tander_flutter_v3/core/theme/app_radius.dart';
import 'package:tander_flutter_v3/core/theme/app_typography.dart';

/// Color variants for [TanderBadge].
///
/// Each variant maps to a background, text, and border color derived
/// from the Tander design system semantic palette.
enum TanderBadgeVariant {
  neutral,
  primary,
  secondary,
  success,
  warning,
  danger,
  info,
}

/// Pill-shaped badge with optional leading icon.
///
/// Used for status indicators, tags, and inline metadata labels.
///
/// ```dart
/// TanderBadge(label: 'Active', variant: TanderBadgeVariant.success)
/// TanderBadge(label: 'New', variant: TanderBadgeVariant.primary, icon: Icons.star)
/// ```
class TanderBadge extends StatelessWidget {
  const TanderBadge({
    super.key,
    required this.label,
    this.variant = TanderBadgeVariant.neutral,
    this.icon,
  });

  /// The text displayed inside the badge.
  final String label;

  /// Visual style variant controlling colors.
  final TanderBadgeVariant variant;

  /// Optional leading icon rendered at 14 px before the label.
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    final _BadgeColors colors = _resolveColors(variant);
    const double iconSize = 14;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: colors.background,
        borderRadius: BorderRadius.circular(AppRadius.full),
        border: Border.all(color: colors.border),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: iconSize, color: colors.foreground),
            const SizedBox(width: 4),
          ],
          Text(
            label,
            style: AppTypography.caption.copyWith(
              fontWeight: FontWeight.w700,
              color: colors.foreground,
            ),
          ),
        ],
      ),
    );
  }
}

/// Resolved color triplet for a badge variant.
class _BadgeColors {
  const _BadgeColors({
    required this.background,
    required this.foreground,
    required this.border,
  });

  final Color background;
  final Color foreground;
  final Color border;
}

/// Maps each [TanderBadgeVariant] to its background, foreground, and border.
_BadgeColors _resolveColors(TanderBadgeVariant variant) {
  return switch (variant) {
    TanderBadgeVariant.neutral => _BadgeColors(
        background: AppColors.subtle,
        foreground: AppColors.textStrong,
        border: AppColors.border.withValues(alpha: 0.20),
      ),
    TanderBadgeVariant.primary => _BadgeColors(
        background: AppColors.primaryLight,
        foreground: AppColors.primary,
        border: AppColors.primary.withValues(alpha: 0.20),
      ),
    TanderBadgeVariant.secondary => _BadgeColors(
        background: AppColors.secondaryLight,
        foreground: AppColors.secondary,
        border: AppColors.secondary.withValues(alpha: 0.20),
      ),
    TanderBadgeVariant.success => _BadgeColors(
        background: AppColors.successLight,
        foreground: AppColors.success,
        border: AppColors.success.withValues(alpha: 0.20),
      ),
    TanderBadgeVariant.warning => _BadgeColors(
        background: AppColors.warningLight,
        foreground: AppColors.warning,
        border: AppColors.warning.withValues(alpha: 0.20),
      ),
    TanderBadgeVariant.danger => _BadgeColors(
        background: AppColors.dangerLight,
        foreground: AppColors.danger,
        border: AppColors.danger.withValues(alpha: 0.20),
      ),
    TanderBadgeVariant.info => _BadgeColors(
        background: AppColors.infoLight,
        foreground: AppColors.info,
        border: AppColors.info.withValues(alpha: 0.20),
      ),
  };
}
