/// Connection screen with segmented tab bar (Requests / Sent / Friends).
///
/// Matches the web connection-page.tsx:
/// - Animated pill indicator with gradient + spring physics
/// - Stats pills in header (pending count, friends count)
/// - Staggered card entrance animations (45 ms delay, 220 ms duration)
/// - Pull-to-refresh on each tab
/// - Per-tab empty states
library;

import 'package:flutter/material.dart' hide ConnectionState;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:tander_flutter_v3/core/contracts/models/connection_models.dart';
import 'package:tander_flutter_v3/core/theme/app_colors.dart';
import 'package:tander_flutter_v3/core/theme/app_curves.dart';
import 'package:tander_flutter_v3/core/theme/app_spacing.dart';
import 'package:tander_flutter_v3/core/theme/app_typography.dart';
import 'package:tander_flutter_v3/features/connection/presentation/notifiers/connection_notifier.dart';
import 'package:tander_flutter_v3/features/connection/presentation/states/connection_state.dart';
import 'package:tander_flutter_v3/features/connection/presentation/widgets/connection_card.dart';
import 'package:tander_flutter_v3/features/connection/presentation/widgets/connection_card_variants.dart';
import 'package:tander_flutter_v3/features/connection/presentation/widgets/connection_header.dart';
import 'package:tander_flutter_v3/shared/constants/routes.dart';
import 'package:tander_flutter_v3/shared/widgets/empty_state.dart';
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
          onRefresh: _refreshAll,
        ),
      ConnectionTab.sent => _SentPanel(
          connections: loadedState.sentRequests.items,
          onRefresh: _refreshAll,
        ),
      ConnectionTab.connected => _FriendsPanel(
          connections: loadedState.connectedFriends.items,
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
    required this.onRefresh,
  });

  final List<ConnectionSummary> connections;
  final Future<void> Function() onRefresh;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (connections.isEmpty) {
      return const Center(
        child: EmptyState(
          title: 'No requests yet',
          description:
              'When someone wants to connect with you, their invitation '
              'will appear here. Love finds its own timing.',
          icon: Icons.favorite_outline,
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: onRefresh,
      color: AppColors.primary,
      child: ListView.separated(
        padding: const EdgeInsets.all(AppSpacing.lg),
        itemCount: connections.length,
        separatorBuilder: (_, _) => const SizedBox(height: AppSpacing.sm),
        itemBuilder: (context, index) {
          final connection = connections[index];
          return _StaggeredEntrance(
            index: index,
            child: RequestCard(
              connection: connection,
              isLoading: _isMutating(ref, connection.connectionId),
              onAccept: () => ref
                  .read(connectionNotifierProvider.notifier)
                  .acceptRequest(connection.connectionId),
              onDecline: () => ref
                  .read(connectionNotifierProvider.notifier)
                  .declineRequest(connection.connectionId),
              onViewProfile: () => context
                  .push(AppRoutes.userProfile(connection.otherUserId)),
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
    required this.onRefresh,
  });

  final List<ConnectionSummary> connections;
  final Future<void> Function() onRefresh;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (connections.isEmpty) {
      return Center(
        child: EmptyState(
          title: 'No sent requests',
          description:
              "You haven't reached out to anyone yet. "
              'Explore Discover to find someone to connect with.',
          icon: Icons.send_outlined,
          actionLabel: 'Go to Discover',
          onAction: () => context.go(AppRoutes.discover),
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: onRefresh,
      color: AppColors.primary,
      child: GridView.builder(
        padding: const EdgeInsets.all(AppSpacing.lg),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          mainAxisSpacing: AppSpacing.sm,
          crossAxisSpacing: AppSpacing.sm,
          childAspectRatio: 0.72,
        ),
        itemCount: connections.length,
        itemBuilder: (context, index) {
          final connection = connections[index];
          return _StaggeredEntrance(
            index: index,
            delayMilliseconds: 60,
            child: SentCard(
              connection: connection,
              isLoading: _isMutating(ref, connection.connectionId),
              onCancel: () => ref
                  .read(connectionNotifierProvider.notifier)
                  .cancelRequest(connection.connectionId),
              onViewProfile: () => context
                  .push(AppRoutes.userProfile(connection.otherUserId)),
            ),
          );
        },
      ),
    );
  }
}

// ── Friends Panel ───────────────────────────────────────────────────

class _FriendsPanel extends ConsumerWidget {
  const _FriendsPanel({
    required this.connections,
    required this.onRefresh,
  });

  final List<ConnectionSummary> connections;
  final Future<void> Function() onRefresh;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (connections.isEmpty) {
      return Center(
        child: EmptyState(
          title: 'No friends yet',
          description:
              'Accept requests or explore Discover to start building '
              'your circle.',
          icon: Icons.people_outline,
          actionLabel: 'Explore Discover',
          onAction: () => context.go(AppRoutes.discover),
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: onRefresh,
      color: AppColors.primary,
      child: ListView.separated(
        padding: const EdgeInsets.all(AppSpacing.lg),
        itemCount: connections.length,
        separatorBuilder: (_, _) => const SizedBox(height: AppSpacing.sm),
        itemBuilder: (context, index) {
          final connection = connections[index];
          return _StaggeredEntrance(
            index: index,
            delayMilliseconds: 50,
            child: FriendRow(
              connection: connection,
              isLoading: _isMutating(ref, connection.connectionId),
              onMessage: () {
                if (connection.conversationId != null) {
                  context.push(
                    AppRoutes.messageThread(connection.conversationId!),
                  );
                }
              },
              onRemove: () => ref
                  .read(connectionNotifierProvider.notifier)
                  .removeConnection(connection.connectionId),
              onViewProfile: () => context
                  .push(AppRoutes.userProfile(connection.otherUserId)),
            ),
          );
        },
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

// ── Staggered Entrance Animation ────────────────────────────────────

class _StaggeredEntrance extends StatefulWidget {
  const _StaggeredEntrance({
    required this.index,
    required this.child,
    this.delayMilliseconds = 45,
  });

  final int index;
  final Widget child;
  final int delayMilliseconds;

  @override
  State<_StaggeredEntrance> createState() => _StaggeredEntranceState();
}

class _StaggeredEntranceState extends State<_StaggeredEntrance>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _opacity;
  late final Animation<Offset> _slide;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 220),
    );

    _opacity = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _controller, curve: AppCurves.premiumEase),
    );
    _slide = Tween<Offset>(
      begin: const Offset(0, 0.06),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(parent: _controller, curve: AppCurves.premiumEase),
    );

    Future<void>.delayed(
      Duration(milliseconds: widget.index * widget.delayMilliseconds),
      () {
        if (mounted) _controller.forward();
      },
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _opacity,
      child: SlideTransition(
        position: _slide,
        child: widget.child,
      ),
    );
  }
}

// ── Shared UI ───────────────────────────────────────────────────────

class _LoadingSkeleton extends StatelessWidget {
  const _LoadingSkeleton();

  @override
  Widget build(BuildContext context) {
    return Padding(
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
