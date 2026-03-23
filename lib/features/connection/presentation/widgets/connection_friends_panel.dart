/// Friends panel with search for the Connection screen.
/// Extracted to keep connection_screen.dart under 400 lines.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:tander_flutter_v3/core/contracts/models/connection_models.dart';
import 'package:tander_flutter_v3/core/theme/app_colors.dart';
import 'package:tander_flutter_v3/core/theme/app_spacing.dart';
import 'package:tander_flutter_v3/core/theme/app_typography.dart';
import 'package:tander_flutter_v3/features/connection/presentation/notifiers/connection_notifier.dart';
import 'package:tander_flutter_v3/features/connection/presentation/widgets/connection_card_variants.dart';
import 'package:tander_flutter_v3/shared/constants/routes.dart';
import 'package:tander_flutter_v3/shared/widgets/empty_state.dart';

/// Friends tab content with search input and pull-to-refresh.
///
/// Web: search input (rounded-2xl border bg-card), filtered friend rows,
/// "No friends matching" empty text when search has no results.
class ConnectionFriendsPanel extends ConsumerStatefulWidget {
  const ConnectionFriendsPanel({
    required this.connections,
    required this.onRefresh,
    super.key,
  });

  final List<ConnectionSummary> connections;
  final Future<void> Function() onRefresh;

  @override
  ConsumerState<ConnectionFriendsPanel> createState() =>
      _ConnectionFriendsPanelState();
}

class _ConnectionFriendsPanelState
    extends ConsumerState<ConnectionFriendsPanel> {
  String _searchQuery = '';

  List<ConnectionSummary> get _filteredConnections {
    if (_searchQuery.isEmpty) return widget.connections;
    final query = _searchQuery.toLowerCase();
    return widget.connections
        .where((connection) =>
            connection.otherUsername.toLowerCase().contains(query) ||
            (connection.otherCity?.toLowerCase().contains(query) ?? false))
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.connections.isEmpty) {
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

    final filteredItems = _filteredConnections;

    return RefreshIndicator(
      onRefresh: widget.onRefresh,
      color: AppColors.primary,
      child: CustomScrollView(
        slivers: [
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.lg,
              AppSpacing.lg,
              AppSpacing.lg,
              0,
            ),
            sliver: SliverToBoxAdapter(child: _buildSearchBar()),
          ),
          if (filteredItems.isEmpty)
            SliverFillRemaining(
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 40),
                  child: Text(
                    'No friends matching "$_searchQuery"',
                    style: AppTypography.bodySm.copyWith(
                      color: AppColors.textMuted,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
            )
          else
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.lg,
                AppSpacing.sm,
                AppSpacing.lg,
                AppSpacing.lg,
              ),
              sliver: SliverList.separated(
                itemCount: filteredItems.length,
                separatorBuilder: (_, _) =>
                    const SizedBox(height: AppSpacing.sm),
                itemBuilder: (context, index) {
                  final connection = filteredItems[index];
                  return FriendRow(
                    connection: connection,
                    isLoading: _isMutating(ref, connection.connectionId),
                    onMessage: () {
                      if (connection.conversationId != null) {
                        context.push(
                          AppRoutes.messageThread(
                            connection.conversationId!,
                          ),
                        );
                      }
                    },
                    onRemove: () => ref
                        .read(connectionNotifierProvider.notifier)
                        .removeConnection(connection.connectionId),
                    onViewProfile: () => context
                        .push(AppRoutes.userProfile(connection.otherUserId)),
                  );
                },
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.xs),
      child: TextField(
        onChanged: (value) => setState(() => _searchQuery = value),
        decoration: InputDecoration(
          hintText: 'Search friends\u2026',
          hintStyle: AppTypography.bodySm.copyWith(
            color: AppColors.textMuted,
          ),
          prefixIcon: const Icon(
            Icons.search,
            size: 18,
            color: AppColors.textMuted,
          ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: const BorderSide(color: AppColors.border),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: const BorderSide(color: AppColors.border),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: const BorderSide(
              color: AppColors.secondary,
              width: 2,
            ),
          ),
          filled: true,
          fillColor: AppColors.card,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 10,
          ),
          isDense: true,
        ),
        style: AppTypography.bodySm.copyWith(color: AppColors.textStrong),
      ),
    );
  }
}

bool _isMutating(WidgetRef ref, String connectionId) {
  return ref.watch(connectionNotifierProvider.notifier)
          .mutatingConnectionId ==
      connectionId;
}
