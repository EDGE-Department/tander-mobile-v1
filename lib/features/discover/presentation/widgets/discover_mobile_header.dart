/// Mobile header + tab switcher for the discover screen.
///
/// Extracted from discover_screen.dart to keep the main screen under 400 lines.
/// Contains the animated tab switcher, header with title/subtitle/badge,
/// and action buttons (filter for discover, new-post for community).
library;

import 'package:flutter/material.dart';

import 'package:tander_flutter_v3/core/theme/app_colors.dart';
import 'package:tander_flutter_v3/core/theme/app_curves.dart';
import 'package:tander_flutter_v3/core/theme/app_radius.dart';
import 'package:tander_flutter_v3/core/theme/app_spacing.dart';
import 'package:tander_flutter_v3/core/theme/app_typography.dart';
import 'package:tander_flutter_v3/features/discover/presentation/widgets/discover_action_buttons.dart';

/// Two possible mobile tabs — mirrors the web DiscoverTab type.
enum DiscoverTab { discover, community }

/// Mobile header showing title, subtitle, remaining badge, and action button.
class DiscoverMobileHeader extends StatelessWidget {
  const DiscoverMobileHeader({
    required this.activeTab,
    required this.remainingCount,
    required this.onOpenFilters,
    required this.onCreatePost,
    super.key,
  });

  final DiscoverTab activeTab;
  final int remainingCount;
  final VoidCallback onOpenFilters;
  final VoidCallback onCreatePost;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.lg,
        AppSpacing.lg,
        AppSpacing.lg,
        AppSpacing.sm,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        activeTab == DiscoverTab.discover
                            ? 'Discover'
                            : 'Community',
                        style: AppTypography.h1,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (activeTab == DiscoverTab.discover &&
                        remainingCount > 0) ...[
                      const SizedBox(width: 10),
                      DiscoverRemainingBadge(count: remainingCount),
                    ],
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  activeTab == DiscoverTab.discover
                      ? 'Find your someone special'
                      : 'Stories from your neighbors',
                  style: AppTypography.bodySm.copyWith(
                    color: AppColors.textMuted,
                    fontWeight: FontWeight.w500,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          if (activeTab == DiscoverTab.discover)
            _MobileFilterButton(onTap: onOpenFilters)
          else
            _MobileNewPostButton(onTap: onCreatePost),
        ],
      ),
    );
  }
}

/// Mobile tab switcher with animated gradient pill.
class DiscoverTabSwitcher extends StatelessWidget {
  const DiscoverTabSwitcher({
    required this.activeTab,
    required this.onTabChanged,
    super.key,
  });

  final DiscoverTab activeTab;
  final ValueChanged<DiscoverTab> onTabChanged;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.lg,
        vertical: AppSpacing.xs,
      ),
      child: Container(
        height: 48,
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          color: AppColors.subtle,
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: AppColors.border),
        ),
        child: Row(
          children: [
            _TabButton(
              isSelected: activeTab == DiscoverTab.discover,
              icon: Icons.explore,
              label: 'Discover',
              onTap: () => onTabChanged(DiscoverTab.discover),
            ),
            const SizedBox(width: 6),
            _TabButton(
              isSelected: activeTab == DiscoverTab.community,
              icon: Icons.groups,
              label: 'Community',
              onTap: () => onTabChanged(DiscoverTab.community),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Private widgets ─────────────────────────────────────────────────────

class _TabButton extends StatelessWidget {
  const _TabButton({
    required this.isSelected,
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final bool isSelected;
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: AppDurations.base,
          curve: AppCurves.premiumEase,
          height: 40,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            gradient: isSelected
                ? const LinearGradient(
                    colors: [Color(0xFFF07020), Color(0xFFE67E22)],
                  )
                : null,
            boxShadow: isSelected
                ? const [
                    BoxShadow(
                      color: Color(0x61E67E22),
                      blurRadius: 14,
                      offset: Offset(0, 3),
                    ),
                  ]
                : null,
          ),
          alignment: Alignment.center,
          child: MediaQuery(
            data: MediaQuery.of(context).copyWith(
              textScaler: TextScaler.noScaling,
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  icon,
                  size: 16,
                  color: isSelected
                      ? AppColors.textInverse
                      : AppColors.textMuted,
                ),
                const SizedBox(width: 8),
                Flexible(
                  child: Text(
                    label,
                    style: AppTypography.label.copyWith(
                      color: isSelected
                          ? AppColors.textInverse
                          : AppColors.textMuted,
                      fontWeight:
                          isSelected ? FontWeight.w700 : FontWeight.w600,
                      fontSize: 15,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Mobile filter button — rounded-lg, border, shadow-sm.
class _MobileFilterButton extends StatelessWidget {
  const _MobileFilterButton({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: 'Open filters',
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          width: AppSpacing.touchComfortable,
          height: AppSpacing.touchComfortable,
          decoration: BoxDecoration(
            color: AppColors.card,
            borderRadius: AppRadius.borderLg,
            border: Border.all(color: AppColors.border),
            boxShadow: const [
              BoxShadow(
                color: Color(0x0A000000),
                blurRadius: 4,
                offset: Offset(0, 2),
              ),
            ],
          ),
          alignment: Alignment.center,
          child: const Icon(
            Icons.tune,
            size: 20,
            color: AppColors.textMuted,
          ),
        ),
      ),
    );
  }
}

/// Mobile new-post button — orange gradient, rounded-lg, shadow.
class _MobileNewPostButton extends StatelessWidget {
  const _MobileNewPostButton({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: 'Create a new post',
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          height: 44,
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFFF07020), Color(0xFFE67E22)],
            ),
            borderRadius: AppRadius.borderLg,
            boxShadow: const [
              BoxShadow(
                color: Color(0x52E67E22),
                blurRadius: 12,
                offset: Offset(0, 3),
              ),
            ],
          ),
          alignment: Alignment.center,
          child: MediaQuery(
            data: MediaQuery.of(context).copyWith(
              textScaler: TextScaler.noScaling,
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.add,
                  size: 18,
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
      ),
    );
  }
}
