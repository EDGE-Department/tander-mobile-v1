/// Connection screen with segmented tab bar (Requests / Sent / Friends).
///
/// Matches web connection-page.tsx:
/// - Animated pill indicator with gradient + spring physics
/// - Stats pills in header (pending count, friends count)
/// - Staggered card entrance animations (45 ms delay, 220 ms duration)
/// - Pull-to-refresh on each tab
/// - Per-tab empty states with layered concentric circles
/// - Section label with count + gradient divider line
library;

import 'package:flutter/material.dart' hide ConnectionState;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:tander_flutter_v3/core/contracts/models/connection_models.dart';
import 'package:tander_flutter_v3/shared/widgets/profile_view_content.dart';
import 'package:tander_flutter_v3/shared/widgets/profile_view_modal.dart';
import 'package:tander_flutter_v3/core/theme/app_colors.dart';
import 'package:tander_flutter_v3/core/theme/app_curves.dart';
import 'package:tander_flutter_v3/core/theme/app_spacing.dart';
import 'package:tander_flutter_v3/core/theme/app_typography.dart';
import 'package:tander_flutter_v3/features/connection/presentation/notifiers/connection_notifier.dart';
import 'package:tander_flutter_v3/features/connection/presentation/states/connection_state.dart';
import 'package:tander_flutter_v3/features/connection/presentation/widgets/connection_card.dart';
import 'package:tander_flutter_v3/features/connection/presentation/widgets/connection_card_variants.dart';
import 'package:tander_flutter_v3/features/connection/presentation/widgets/connection_friends_panel.dart';
import 'package:tander_flutter_v3/features/connection/presentation/widgets/connection_header.dart';
import 'package:tander_flutter_v3/features/connection/presentation/widgets/connection_shared_ui.dart';
import 'package:tander_flutter_v3/shared/constants/routes.dart';
import 'package:tander_flutter_v3/shared/widgets/skeleton_card.dart';

// ── Screen ──────────────────────────────────────────────────────────

class ConnectionScreen extends ConsumerStatefulWidget {
  const ConnectionScreen({super.key});

  @override
  ConsumerState<ConnectionScreen> createState() => _ConnectionScreenState();
}

class _ConnectionScreenState extends ConsumerState<ConnectionScreen> {
  ConnectionTab _activeTab = ConnectionTab.incoming;

  @override
  Widget build(BuildContext context) {
    final connectionState = ref.watch(connectionNotifierProvider);

    return Scaffold(
      backgroundColor: AppColors.canvas,
      body: SafeArea(
        child: Column(
          children: [
            ConnectionHeader(
              activeTab: _activeTab,
              connectionState: connectionState,
              onTabChanged: (tab) => setState(() => _activeTab = tab),
            ),
            const ConnectionHeaderDivider(),
            Expanded(child: _buildTabPanel(connectionState)),
          ],
        ),
      ),
    );
  }

  Widget _buildTabPanel(ConnectionState connectionState) {
    return AnimatedSwitcher(
      duration: AppDurations.fast,
      switchInCurve: AppCurves.premiumEase,
      child: KeyedSubtree(
        key: ValueKey(_activeTab),
        child: switch (connectionState) {
          ConnectionLoading() => const _LoadingSkeleton(),
          ConnectionError(:final exception) =>
            _ErrorPanel(message: exception.userMessage),
          ConnectionLoaded() => _buildLoadedPanel(connectionState),
        },
      ),
    );
  }

  Widget _buildLoadedPanel(ConnectionLoaded loadedState) {
    return switch (_activeTab) {
      ConnectionTab.incoming => _IncomingPanel(
          connections: loadedState.incomingRequests.items,
          totalCount: loadedState.incomingRequests.totalCount,
          onRefresh: _refreshAll,
        ),
      ConnectionTab.sent => _SentPanel(
          connections: loadedState.sentRequests.items,
          totalCount: loadedState.sentRequests.totalCount,
          onRefresh: _refreshAll,
        ),
      ConnectionTab.connected => ConnectionFriendsPanel(
          connections: loadedState.connectedFriends.items,
          totalCount: loadedState.connectedFriends.totalCount,
          onRefresh: _refreshAll,
        ),
    };
  }

  Future<void> _refreshAll() async {
    await ref.read(connectionNotifierProvider.notifier).loadAll();
  }
}

// ── Incoming Panel ──────────────────────────────────────────────────

class _IncomingPanel extends ConsumerWidget {
  const _IncomingPanel({
    required this.connections,
    required this.totalCount,
    required this.onRefresh,
  });

  final List<ConnectionSummary> connections;
  final int totalCount;
  final Future<void> Function() onRefresh;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (connections.isEmpty) {
      return const SingleChildScrollView(
        child: Center(
          child: TabEmptyState(
            icon: Icons.favorite,
            title: 'No requests yet',
            description:
                'When someone wants to connect with you, their invitation '
                'will appear here. Love finds its own timing.',
          ),
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: onRefresh,
      color: AppColors.primary,
      child: ListView.separated(
        padding: const EdgeInsets.all(AppSpacing.lg),
        itemCount: connections.length + 1,
        separatorBuilder: (_, _) => const SizedBox(height: AppSpacing.sm),
        itemBuilder: (context, index) {
          if (index == 0) {
            return SectionLabel(count: totalCount, noun: 'request');
          }
          final connection = connections[index - 1];
          return StaggeredEntrance(
            index: index - 1,
            child: RequestCard(
              connection: connection,
              isLoading: _isMutating(ref, connection.connectionId),
              onAccept: () => ref
                  .read(connectionNotifierProvider.notifier)
                  .acceptRequest(connection.connectionId),
              onDecline: () => ref
                  .read(connectionNotifierProvider.notifier)
                  .declineRequest(connection.connectionId),
              onViewProfile: () => showProfileViewModal(
                context,
                userId: connection.otherUserId,
                relationship: ProfileRelationship.none,
              ),
            ),
          );
        },
      ),
    );
  }
}

// ── Sent Panel ──────────────────────────────────────────────────────

class _SentPanel extends ConsumerWidget {
  const _SentPanel({
    required this.connections,
    required this.totalCount,
    required this.onRefresh,
  });

  final List<ConnectionSummary> connections;
  final int totalCount;
  final Future<void> Function() onRefresh;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (connections.isEmpty) {
      return SingleChildScrollView(
        child: Center(
          child: TabEmptyState(
            icon: Icons.send,
            title: 'No sent requests',
            description:
                "You haven't reached out to anyone yet. "
                'Explore Discover to find someone to connect with.',
            actionLabel: 'Go to Discover',
            onAction: () => context.go(AppRoutes.discover),
          ),
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: onRefresh,
      color: AppColors.primary,
      child: CustomScrollView(
        slivers: [
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.lg,
              AppSpacing.lg,
              AppSpacing.lg,
              AppSpacing.sm,
            ),
            sliver: SliverToBoxAdapter(
              child: SectionLabel(
                count: totalCount,
                noun: 'pending request',
              ),
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.lg,
              0,
              AppSpacing.lg,
              AppSpacing.lg,
            ),
            sliver: SliverGrid(
              delegate: SliverChildBuilderDelegate(
                (context, index) {
                  final connection = connections[index];
                  return StaggeredEntrance(
                    index: index,
                    delayMilliseconds: 60,
                    child: SentCard(
                      connection: connection,
                      isLoading: _isMutating(ref, connection.connectionId),
                      onCancel: () => ref
                          .read(connectionNotifierProvider.notifier)
                          .cancelRequest(connection.connectionId),
                      onViewProfile: () => showProfileViewModal(
                        context,
                        userId: connection.otherUserId,
                        relationship: ProfileRelationship.pendingOutgoing,
                      ),
                    ),
                  );
                },
                childCount: connections.length,
              ),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                mainAxisSpacing: AppSpacing.sm,
                crossAxisSpacing: AppSpacing.sm,
                childAspectRatio: 0.72,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Helpers ─────────────────────────────────────────────────────────

bool _isMutating(WidgetRef ref, String connectionId) {
  return ref.watch(connectionNotifierProvider.notifier)
          .mutatingConnectionId ==
      connectionId;
}

// ── Shared UI ───────────────────────────────────────────────────────

class _LoadingSkeleton extends StatelessWidget {
  const _LoadingSkeleton();

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        children: List.generate(
          3,
          (index) => const Padding(
            padding: EdgeInsets.only(bottom: AppSpacing.sm),
            child: SkeletonCard(variant: SkeletonVariant.card, height: 140),
          ),
        ),
      ),
    );
  }
}

class _ErrorPanel extends StatelessWidget {
  const _ErrorPanel({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Text(
          message,
          style: AppTypography.bodySm.copyWith(
            color: AppColors.danger,
            fontWeight: FontWeight.w500,
          ),
          textAlign: TextAlign.center,
        ),
      ),
    );
  }
}
