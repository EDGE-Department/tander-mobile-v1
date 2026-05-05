/// Friends (connected) panel with search for the Connection screen.
///
/// Extracted from connection_screen.dart to keep each file under 400 lines.
/// Matches web ConnectedPanel: search input, filtered friend rows,
/// section label with count, staggered entrance animations.
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
import 'package:tander_flutter_v3/features/connection/presentation/widgets/connection_shared_ui.dart';
import 'package:tander_flutter_v3/shared/constants/routes.dart';
import 'package:tander_flutter_v3/shared/widgets/profile_view_content.dart';
import 'package:tander_flutter_v3/shared/widgets/profile_view_modal.dart';
import 'package:tander_flutter_v3/shared/widgets/tander_confirm_dialog.dart';

/// Friends tab content with search input and pull-to-refresh.
///
/// Web: search input (rounded-2xl border bg-card), filtered friend rows,
/// section label "{N} friends" with gradient divider,
/// "No friends matching" empty text when search has no results.
class ConnectionFriendsPanel extends ConsumerStatefulWidget {
  const ConnectionFriendsPanel({
    required this.connections,
    required this.totalCount,
    required this.onRefresh,
    super.key,
  });

  final List<ConnectionSummary> connections;
  final int totalCount;
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
        .where(
          (connection) =>
              connection.otherUsername.toLowerCase().contains(query) ||
              (connection.otherCity?.toLowerCase().contains(query) ?? false),
        )
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.connections.isEmpty) {
      return RefreshableTabEmptyState(
        icon: Icons.people,
        title: 'No friends yet',
        description:
            'Accept requests or explore Discover to start building '
            'your circle.',
        actionLabel: 'Explore Discover',
        onAction: () => context.go(AppRoutes.discover),
        onRefresh: widget.onRefresh,
      );
    }

    final filteredItems = _filteredConnections;

    // Use ListView instead of CustomScrollView to avoid layout issues
    // with AnimatedSwitcher's Stack on mobile.
    return RefreshIndicator(
      onRefresh: widget.onRefresh,
      color: AppColors.primary,
      child: ListView.separated(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(AppSpacing.lg),
        itemCount: filteredItems.length + 2, // search bar + label + items
        separatorBuilder: (_, index) =>
            SizedBox(height: index == 0 ? AppSpacing.md : AppSpacing.sm),
        itemBuilder: (context, index) {
          if (index == 0) return _buildSearchBar();
          if (index == 1) {
            if (filteredItems.isEmpty) {
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 40),
                child: Text(
                  'No friends matching "$_searchQuery"',
                  style: AppTypography.bodySm.copyWith(
                    color: AppColors.textMuted,
                  ),
                  textAlign: TextAlign.center,
                ),
              );
            }
            return SectionLabel(count: filteredItems.length, noun: 'friend');
          }
          final friendIndex = index - 2;
          final connection = filteredItems[friendIndex];
          return StaggeredEntrance(
            index: friendIndex,
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
              onRemove: () async {
                final confirmed = await TanderConfirmDialog.show(
                  context: context,
                  title: 'Remove friend?',
                  message:
                      'Are you sure you want to remove '
                      '${connection.otherUsername} from your friends? '
                      'This action cannot be undone.',
                  confirmLabel: 'Remove',
                  isDanger: true,
                );
                if (confirmed == true && context.mounted) {
                  await ref
                      .read(connectionNotifierProvider.notifier)
                      .removeConnection(connection.connectionId);
                }
              },
              onViewProfile: () => showProfileViewModal(
                context,
                userId: connection.otherUserId,
                relationship: ProfileRelationship.connected,
              ),
            ),
          );
        },
      ),
    );
  }

  /// Web: rounded-2xl border bg-card, MagnifyingGlass 15px left,
  /// focus ring secondary/20, text-sm
  Widget _buildSearchBar() {
    return TextField(
      onChanged: (value) => setState(() => _searchQuery = value),
      decoration: InputDecoration(
        hintText: 'Search friends\u2026',
        hintStyle: AppTypography.bodySm.copyWith(color: AppColors.textMuted),
        prefixIcon: const Icon(
          Icons.search,
          size: 15,
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
          borderSide: const BorderSide(color: AppColors.secondary, width: 2),
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
    );
  }
}

bool _isMutating(WidgetRef ref, String connectionId) {
  return ref.watch(connectionNotifierProvider.notifier).mutatingConnectionId ==
      connectionId;
}
