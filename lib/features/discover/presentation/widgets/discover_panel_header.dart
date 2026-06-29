/// Panel header shared between Discover and Community panels on desktop.
///
/// Matches the web PanelHeader component exactly:
/// - 40x40 rounded-xl gradient icon container
/// - Title (h2) + subtitle (caption muted)
/// - Right-aligned action widget (filter button or new-post button)
/// - Sticky, blurred background, bottom border at 40% opacity
library;

import 'package:flutter/material.dart';

import 'package:tander_flutter_v3/core/theme/app_colors.dart';
import 'package:tander_flutter_v3/core/theme/app_spacing.dart';
import 'package:tander_flutter_v3/core/theme/app_typography.dart';

class DiscoverPanelHeader extends StatelessWidget {
  const DiscoverPanelHeader({
    required this.icon,
    required this.iconGradient,
    required this.title,
    required this.subtitle,
    required this.action,
    super.key,
  });

  /// Icon widget rendered inside the gradient box (typically a white Icon).
  final Widget icon;

  /// Gradient applied to the 40x40 icon container.
  final LinearGradient iconGradient;

  /// Panel title rendered as h2 bold, e.g. "Discover" or "Community".
  final String title;

  /// Subtitle rendered as caption muted, e.g. "Connect with fellow seniors who share your interests.".
  final String subtitle;

  /// Action widget on the right (filter button, new-post button, etc.).
  final Widget action;

  static const double _iconBoxSize = 40;
  static const double _iconBoxRadius = 12;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.lg,
        vertical: AppSpacing.md,
      ),
      decoration: BoxDecoration(
        color: AppColors.canvas.withValues(alpha: 0.88),
        border: const Border(
          bottom: BorderSide(
            color: Color(0x66E5E1DC), // border at ~40% opacity
          ),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: _iconBoxSize,
            height: _iconBoxSize,
            decoration: BoxDecoration(
              gradient: iconGradient,
              borderRadius: BorderRadius.circular(_iconBoxRadius),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x14000000),
                  blurRadius: 4,
                  offset: Offset(0, 1),
                ),
              ],
            ),
            alignment: Alignment.center,
            child: icon,
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  title,
                  style: AppTypography.h3.copyWith(
                    fontSize: 17.6, // ~1.1rem
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: AppTypography.caption.copyWith(
                    color: AppColors.textMuted,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          action,
        ],
      ),
    );
  }
}
