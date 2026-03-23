/// Main discover screen — pixel-perfect port of tander-web discover-page.tsx.
///
/// PHONE: single column, full-screen card stack with tab switcher.
/// TABLET (shortestSide > 600): two columns side-by-side (future).
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:tander_flutter_v3/core/theme/app_colors.dart';
import 'package:tander_flutter_v3/core/theme/app_curves.dart';
import 'package:tander_flutter_v3/core/theme/app_radius.dart';
import 'package:tander_flutter_v3/core/theme/app_spacing.dart';
import 'package:tander_flutter_v3/core/theme/app_typography.dart';
import 'package:tander_flutter_v3/features/discover/presentation/notifiers/discover_notifier.dart';
import 'package:tander_flutter_v3/features/discover/presentation/states/discover_state.dart';
import 'package:tander_flutter_v3/features/discover/presentation/widgets/discover_action_buttons.dart';
import 'package:tander_flutter_v3/features/discover/presentation/widgets/discover_filters_sheet.dart';
import 'package:tander_flutter_v3/features/discover/presentation/widgets/swipe_card.dart';
import 'package:tander_flutter_v3/shared/constants/routes.dart';
import 'package:tander_flutter_v3/shared/widgets/empty_state.dart';
import 'package:tander_flutter_v3/shared/widgets/skeleton_card.dart';

enum _DiscoverTab { discover, community }

class DiscoverScreen extends ConsumerStatefulWidget {
  const DiscoverScreen({super.key});

  @override
  ConsumerState<DiscoverScreen> createState() => _DiscoverScreenState();
}

class _DiscoverScreenState extends ConsumerState<DiscoverScreen> {
  _DiscoverTab _activeTab = _DiscoverTab.discover;
  double _dragProgress = 0;

  void _openFiltersSheet() {
    final notifier = ref.read(discoverNotifierProvider.notifier);
    DiscoverFiltersSheet.show(
      context: context,
      activeFilters: notifier.activeFilters,
      onApply: notifier.applyFilters,
    );
  }

  void _navigateToProfile(String userId) {
    context.push(AppRoutes.discoverProfile(userId));
  }

  @override
  Widget build(BuildContext context) {
    final discoverState = ref.watch(discoverNotifierProvider);

    return Scaffold(
      backgroundColor: AppColors.canvas,
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(discoverState),
            _buildTabSwitcher(),
            Expanded(
              child: _activeTab == _DiscoverTab.discover
                  ? _buildDiscoverContent(discoverState)
                  : _buildCommunityPlaceholder(),
            ),
          ],
        ),
      ),
    );
  }

  // ── Header ──────────────────────────────────────────────────────────

  Widget _buildHeader(DiscoverState discoverState) {
    final int remainingCount =
        discoverState is DiscoverLoaded ? discoverState.remainingCount : 0;

    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.lg, AppSpacing.lg, AppSpacing.lg, AppSpacing.sm,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(children: [
                  Text(
                    _activeTab == _DiscoverTab.discover
                        ? 'Discover' : 'Community',
                    style: AppTypography.h1,
                  ),
                  if (_activeTab == _DiscoverTab.discover &&
                      remainingCount > 0) ...[
                    const SizedBox(width: 10),
                    DiscoverRemainingBadge(count: remainingCount),
                  ],
                ]),
                const SizedBox(height: 2),
                Text(
                  _activeTab == _DiscoverTab.discover
                      ? 'Find your someone special'
                      : 'Stories from your neighbors',
                  style: AppTypography.bodySm.copyWith(
                    color: AppColors.textMuted, fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          if (_activeTab == _DiscoverTab.discover) _buildFilterButton(),
        ],
      ),
    );
  }

  Widget _buildFilterButton() {
    return Semantics(
      button: true,
      label: 'Open filters',
      child: GestureDetector(
        onTap: _openFiltersSheet,
        child: Container(
          width: AppSpacing.touchComfortable,
          height: AppSpacing.touchComfortable,
          decoration: BoxDecoration(
            color: AppColors.card,
            borderRadius: AppRadius.borderLg,
            border: Border.all(color: AppColors.border),
            boxShadow: const [
              BoxShadow(
                color: Color(0x0A000000), blurRadius: 4, offset: Offset(0, 2),
              ),
            ],
          ),
          alignment: Alignment.center,
          child: const Icon(
            Icons.tune,
            size: 20, color: AppColors.textMuted,
          ),
        ),
      ),
    );
  }

  // ── Tab switcher ────────────────────────────────────────────────────

  Widget _buildTabSwitcher() {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.lg, vertical: AppSpacing.xs,
      ),
      child: Container(
        height: 48,
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          color: AppColors.subtle,
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: AppColors.border),
        ),
        child: Row(children: [
          _tabButton(
            isSelected: _activeTab == _DiscoverTab.discover,
            activeIcon: Icons.favorite,
            inactiveIcon: Icons.favorite,
            label: 'Discover',
            onTap: () => setState(() => _activeTab = _DiscoverTab.discover),
          ),
          const SizedBox(width: 6),
          _tabButton(
            isSelected: _activeTab == _DiscoverTab.community,
            activeIcon: Icons.groups,
            inactiveIcon: Icons.groups,
            label: 'Community',
            onTap: () => setState(() => _activeTab = _DiscoverTab.community),
          ),
        ]),
      ),
    );
  }

  Widget _tabButton({
    required bool isSelected,
    required IconData activeIcon,
    required IconData inactiveIcon,
    required String label,
    required VoidCallback onTap,
  }) {
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
                    colors: [Color(0xFFF07020), Color(0xFFE67E22)])
                : null,
            boxShadow: isSelected
                ? const [BoxShadow(
                    color: Color(0x61E67E22), blurRadius: 14,
                    offset: Offset(0, 3))]
                : null,
          ),
          alignment: Alignment.center,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(isSelected ? activeIcon : inactiveIcon, size: 16,
                color: isSelected ? AppColors.textInverse : AppColors.textMuted),
              const SizedBox(width: 8),
              Text(label, style: AppTypography.label.copyWith(
                color: isSelected ? AppColors.textInverse : AppColors.textMuted,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600,
                fontSize: 15,
              )),
            ],
          ),
        ),
      ),
    );
  }

  // ── Discover content ────────────────────────────────────────────────

  Widget _buildDiscoverContent(DiscoverState discoverState) {
    return switch (discoverState) {
      DiscoverLoading() => _buildSkeletonLoader(),
      DiscoverError(:final exception) =>
        _buildErrorState(exception.userMessage),
      DiscoverEmpty() => _buildEmptyState(),
      DiscoverLoaded() => _buildCardStack(discoverState),
    };
  }

  Widget _buildSkeletonLoader() {
    return const Padding(
      padding: EdgeInsets.symmetric(
        horizontal: AppSpacing.lg, vertical: AppSpacing.md,
      ),
      child: Column(children: [
        Expanded(child: SkeletonCard(variant: SkeletonVariant.fullCard)),
        SizedBox(height: AppSpacing.lg),
        Row(mainAxisAlignment: MainAxisAlignment.center, children: [
          SkeletonCard(variant: SkeletonVariant.circle, width: 60, height: 60),
          SizedBox(width: AppSpacing.lg),
          SkeletonCard(variant: SkeletonVariant.circle, width: 76, height: 76),
          SizedBox(width: AppSpacing.lg),
          SkeletonCard(variant: SkeletonVariant.circle, width: 60, height: 60),
        ]),
      ]),
    );
  }

  Widget _buildErrorState(String message) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: EmptyState(
          icon: Icons.error_outline,
          title: "Couldn't load profiles",
          description: message,
          actionLabel: 'Try again',
          onAction: () =>
              ref.read(discoverNotifierProvider.notifier).loadProfiles(),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: EmptyState(
          icon: Icons.favorite,
          title: "You've seen everyone!",
          description:
              'New people join every day. We will let you know when '
              'someone new is nearby.',
          actionLabel: 'Adjust filters',
          onAction: _openFiltersSheet,
        ),
      ),
    );
  }

  Widget _buildCardStack(DiscoverLoaded loadedState) {
    final visibleStack = loadedState.visibleStack;
    if (visibleStack.isEmpty) return _buildEmptyState();

    final absProgress = _dragProgress.abs();
    final notifier = ref.read(discoverNotifierProvider.notifier);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
      child: Column(children: [
        Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
            child: Stack(clipBehavior: Clip.none, children: [
              if (visibleStack.length > 2)
                DiscoverGhostCard(
                  scale: 0.91 + absProgress * 0.05,
                  translateY: 20 - absProgress * 20,
                  opacity: 0.70,
                ),
              if (visibleStack.length > 1)
                DiscoverGhostCard(
                  scale: 0.95 + absProgress * 0.05,
                  translateY: 12 - absProgress * 12,
                  opacity: 0.85,
                ),
              Positioned.fill(
                child: SwipeCard(
                  key: ValueKey(visibleStack.first.userId),
                  candidate: visibleStack.first,
                  onLikeComplete: notifier.likeCurrentProfile,
                  onPassComplete: notifier.passCurrentProfile,
                  onDragProgress: (progress) =>
                      setState(() => _dragProgress = progress),
                  onViewProfile: () =>
                      _navigateToProfile(visibleStack.first.userId),
                ),
              ),
            ]),
          ),
        ),
        DiscoverActionButtons(
          candidate: visibleStack.first,
          onPass: notifier.passCurrentProfile,
          onLike: notifier.likeCurrentProfile,
          onViewProfile: () =>
              _navigateToProfile(visibleStack.first.userId),
        ),
        DiscoverProgressDots(
          totalCount: loadedState.profiles.length,
          currentIndex: loadedState.currentIndex,
        ),
      ]),
    );
  }

  Widget _buildCommunityPlaceholder() {
    return const Center(
      child: EmptyState(
        icon: Icons.groups,
        title: 'Coming Soon',
        description:
            'Community stories from your neighbors are on the way. '
            'Stay tuned!',
      ),
    );
  }
}
