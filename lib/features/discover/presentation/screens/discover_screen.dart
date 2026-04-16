/// Main discover screen — pixel-perfect port of tander-web discover-page.tsx.
///
/// MOBILE (width < 1024): single column, tab switcher (Discover | Community).
/// DESKTOP (width >= 1024): two panels side-by-side, both always visible.
///   Left: Discover panel (45%, max 520px).
///   Right: Community panel (flex-1, scrollable).
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:tander_flutter_v3/core/theme/app_colors.dart';
import 'package:tander_flutter_v3/core/theme/app_spacing.dart';
import 'package:tander_flutter_v3/features/community/presentation/widgets/create_post_sheet.dart';
import 'package:tander_flutter_v3/features/discover/presentation/notifiers/discover_notifier.dart';
import 'package:tander_flutter_v3/features/discover/presentation/states/discover_state.dart';
import 'package:tander_flutter_v3/features/discover/presentation/widgets/community_feed_panel.dart';
import 'package:tander_flutter_v3/features/discover/presentation/widgets/discover_action_buttons.dart';
import 'package:tander_flutter_v3/features/discover/presentation/widgets/discover_desktop_parts.dart';
import 'package:tander_flutter_v3/features/discover/presentation/widgets/discover_empty_state.dart';
import 'package:tander_flutter_v3/features/discover/presentation/widgets/discover_filters_sheet.dart';
import 'package:tander_flutter_v3/features/discover/presentation/widgets/discover_mobile_header.dart';
import 'package:tander_flutter_v3/features/discover/presentation/widgets/discover_panel_header.dart';
import 'package:tander_flutter_v3/features/discover/presentation/widgets/swipe_card.dart';
import 'package:tander_flutter_v3/shared/widgets/empty_state.dart';
import 'package:tander_flutter_v3/shared/widgets/profile_view_modal.dart';
import 'package:tander_flutter_v3/shared/widgets/skeleton_card.dart';

/// Breakpoint matching the web `lg:` prefix (1024px).
const double _desktopBreakpoint = 1024;

class DiscoverScreen extends ConsumerStatefulWidget {
  const DiscoverScreen({super.key});

  @override
  ConsumerState<DiscoverScreen> createState() => _DiscoverScreenState();
}

class _DiscoverScreenState extends ConsumerState<DiscoverScreen> {
  DiscoverTab _activeTab = DiscoverTab.discover;
  double _dragProgress = 0;

  // ── Actions ─────────────────────────────────────────────────────────

  void _openFiltersSheet() {
    final notifier = ref.read(discoverNotifierProvider.notifier);
    DiscoverFiltersSheet.show(
      context: context,
      activeFilters: notifier.activeFilters,
      onApply: notifier.applyFilters,
    );
  }

  void _openCreatePostSheet() {
    CreatePostSheet.show(
      context: context,
      ref: ref,
      onPostCreated: () {},
    );
  }

  void _openProfileModal(String userId) {
    showProfileViewModal(context, userId: userId);
  }

  // ── Build ───────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.sizeOf(context).width;
    final isDesktop = screenWidth >= _desktopBreakpoint;
    final discoverState = ref.watch(discoverNotifierProvider);

    return Scaffold(
      backgroundColor: AppColors.canvas,
      body: SafeArea(
        child: isDesktop
            ? _buildDesktopLayout(discoverState)
            : _buildMobileLayout(discoverState),
      ),
    );
  }

  // ── Desktop: two panels side-by-side ────────────────────────────────

  Widget _buildDesktopLayout(DiscoverState discoverState) {
    final remainingCount = _remainingCount(discoverState);

    return Row(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Left panel: Discover (45%, max 520px)
        ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 520),
          child: SizedBox(
            width: MediaQuery.sizeOf(context).width * 0.45,
            child: Column(
              children: [
                DiscoverPanelHeader(
                  icon: const Icon(
                    Icons.explore,
                    size: 18,
                    color: AppColors.textInverse,
                  ),
                  iconGradient: const LinearGradient(
                    colors: [Color(0xFFF07020), Color(0xFFE67E22)],
                  ),
                  title: 'Discover',
                  subtitle: remainingCount > 0
                      ? '$remainingCount people nearby'
                      : 'Find your someone special',
                  action: DesktopFilterButton(onTap: _openFiltersSheet),
                ),
                Expanded(child: _buildDiscoverContent(discoverState)),
              ],
            ),
          ),
        ),
        const DiscoverVerticalDivider(),
        // Right panel: Community (flex-1, scrollable)
        Expanded(
          child: Column(
            children: [
              DiscoverPanelHeader(
                icon: const Icon(
                  Icons.groups,
                  size: 18,
                  color: AppColors.textInverse,
                ),
                iconGradient: const LinearGradient(
                  colors: [Color(0xFF0A7068), Color(0xFF0F9D94)],
                ),
                title: 'Community',
                subtitle: 'Stories from your neighbors',
                action: DesktopNewPostButton(onTap: _openCreatePostSheet),
              ),
              const Expanded(child: CommunityFeedPanel()),
            ],
          ),
        ),
      ],
    );
  }

  // ── Mobile: tab switcher, single column ─────────────────────────────

  Widget _buildMobileLayout(DiscoverState discoverState) {
    return Column(
      children: [
        DiscoverMobileHeader(
          activeTab: _activeTab,
          remainingCount: _remainingCount(discoverState),
          onOpenFilters: _openFiltersSheet,
          onCreatePost: _openCreatePostSheet,
        ),
        DiscoverTabSwitcher(
          activeTab: _activeTab,
          onTabChanged: (tab) => setState(() => _activeTab = tab),
        ),
        Expanded(
          child: _activeTab == DiscoverTab.discover
              ? _buildDiscoverContent(discoverState)
              : const CommunityFeedPanel(),
        ),
      ],
    );
  }

  // ── Discover content (shared between layouts) ───────────────────────

  Widget _buildDiscoverContent(DiscoverState discoverState) {
    return switch (discoverState) {
      DiscoverLoading() => _buildSkeletonLoader(),
      DiscoverError(:final exception) =>
        _buildErrorState(exception.userMessage),
      DiscoverEmpty() => DiscoverEmptyState(onOpenFilters: _openFiltersSheet),
      DiscoverLoaded() => _buildCardStack(discoverState),
    };
  }

  Widget _buildSkeletonLoader() {
    return const Padding(
      padding: EdgeInsets.symmetric(
        horizontal: AppSpacing.lg,
        vertical: AppSpacing.md,
      ),
      child: Column(
        children: [
          Expanded(child: SkeletonCard(variant: SkeletonVariant.fullCard)),
          SizedBox(height: AppSpacing.lg),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              SkeletonCard(
                variant: SkeletonVariant.circle,
                width: 60,
                height: 60,
              ),
              SizedBox(width: AppSpacing.lg),
              SkeletonCard(
                variant: SkeletonVariant.circle,
                width: 76,
                height: 76,
              ),
              SizedBox(width: AppSpacing.lg),
              SkeletonCard(
                variant: SkeletonVariant.circle,
                width: 60,
                height: 60,
              ),
            ],
          ),
        ],
      ),
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

  Widget _buildCardStack(DiscoverLoaded loadedState) {
    final visibleStack = loadedState.visibleStack;
    if (visibleStack.isEmpty) {
      return DiscoverEmptyState(onOpenFilters: _openFiltersSheet);
    }

    final absProgress = _dragProgress.abs();
    final notifier = ref.read(discoverNotifierProvider.notifier);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
      child: Column(
        children: [
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
              child: Stack(
                clipBehavior: Clip.none,
                children: [
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
                          _openProfileModal(visibleStack.first.userId),
                    ),
                  ),
                ],
              ),
            ),
          ),
          DiscoverActionButtons(
            candidate: visibleStack.first,
            onPass: notifier.passCurrentProfile,
            onLike: notifier.likeCurrentProfile,
            onViewProfile: () =>
                _openProfileModal(visibleStack.first.userId),
          ),
          DiscoverProgressDots(
            totalCount: loadedState.profiles.length,
            currentIndex: loadedState.currentIndex,
          ),
        ],
      ),
    );
  }

  // ── Helpers ─────────────────────────────────────────────────────────

  int _remainingCount(DiscoverState discoverState) {
    return discoverState is DiscoverLoaded
        ? discoverState.remainingCount
        : 0;
  }
}
