/// Desktop-only layout widgets for the discover screen.
///
/// Contains the warm gradient vertical divider separating the two panels,
/// the compact filter button, and the compact new-post button used in
/// desktop panel headers.
library;

import 'package:flutter/material.dart';

import 'package:tander_flutter_v3/core/theme/app_colors.dart';
import 'package:tander_flutter_v3/core/theme/app_radius.dart';
import 'package:tander_flutter_v3/core/theme/app_spacing.dart';
import 'package:tander_flutter_v3/core/theme/app_typography.dart';

/// Warm gradient vertical divider separating the two desktop panels.
/// Matches web: 2px wide, gradient from border -> orange -> teal -> border.
class DiscoverVerticalDivider extends StatelessWidget {
  const DiscoverVerticalDivider({super.key});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 2,
      child: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              AppColors.border,
              Color(0x38E67E22), // orange 22%
              Color(0x290F9D94), // teal 16%
              AppColors.border,
            ],
            stops: [0.0, 0.3, 0.7, 1.0],
          ),
        ),
      ),
    );
  }
}

/// Desktop filter button — compact (44x44), rounded-md border container.
/// Used inside [DiscoverPanelHeader] on the discover panel.
class DesktopFilterButton extends StatelessWidget {
  const DesktopFilterButton({required this.onTap, super.key});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: 'Open filters',
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          width: AppSpacing.touchMinimum,
          height: AppSpacing.touchMinimum,
          decoration: BoxDecoration(
            color: AppColors.card,
            borderRadius: BorderRadius.circular(AppRadius.md),
            border: Border.all(color: AppColors.border),
          ),
          alignment: Alignment.center,
          child: const Icon(
            Icons.tune,
            size: 18,
            color: AppColors.textMuted,
          ),
        ),
      ),
    );
  }
}

/// Desktop new-post button — orange gradient, rounded-md, white text.
/// Used inside [DiscoverPanelHeader] on the community panel.
class DesktopNewPostButton extends StatelessWidget {
  const DesktopNewPostButton({required this.onTap, super.key});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: 'Create a new post',
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          height: 40,
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFFF07020), Color(0xFFE67E22)],
            ),
            borderRadius: BorderRadius.circular(AppRadius.md),
            boxShadow: const [
              BoxShadow(
                color: Color(0x14000000),
                blurRadius: 4,
                offset: Offset(0, 1),
              ),
            ],
          ),
          alignment: Alignment.center,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.add,
                size: 16,
                color: AppColors.textInverse,
              ),
              const SizedBox(width: AppSpacing.xxs),
              Text(
                'New post',
                style: AppTypography.label.copyWith(
                  color: AppColors.textInverse,
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
