import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:tander_flutter_v3/core/theme/app_colors.dart';
import 'package:tander_flutter_v3/core/theme/app_radius.dart';
import 'package:tander_flutter_v3/core/theme/app_spacing.dart';
import 'package:tander_flutter_v3/core/theme/app_typography.dart';
import 'package:tander_flutter_v3/features/messaging/presentation/notifiers/conversations_notifier.dart';
import 'package:tander_flutter_v3/features/messaging/presentation/states/conversations_state.dart';
import 'package:tander_flutter_v3/features/messaging/presentation/widgets/conversation_list_states.dart';
import 'package:tander_flutter_v3/features/messaging/presentation/widgets/conversation_row.dart';

const Color _orange = AppColors.primary;

/// Complete sidebar content: header + scrollable conversation list.
class MessagesSidebarContent extends ConsumerWidget {
  const MessagesSidebarContent({
    super.key,
    required this.activeConversationId,
    required this.onSelectConversation,
  });

  final String? activeConversationId;
  final ValueChanged<String> onSelectConversation;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final conversationsState = ref.watch(conversationsNotifierProvider);
    final unreadCount = switch (conversationsState) {
      ConversationsLoaded(:final conversations) => conversations
          .where((conv) => conv.unreadCount > 0 && !conv.isMuted)
          .length,
      _ => 0,
    };

    return Column(
      children: [
        _MessagesHeader(unreadCount: unreadCount),
        Expanded(
          child: Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Color(0xB8FFFCF7), Color(0x85FFF7EF)],
              ),
            ),
            child: switch (conversationsState) {
              ConversationsLoading() => const ConversationsListSkeleton(),
              ConversationsError(:final exception) => ConversationsErrorView(
                  errorMessage: exception.userMessage,
                  onRetry: () => ref
                      .read(conversationsNotifierProvider.notifier)
                      .loadConversations(),
                ),
              ConversationsLoaded() => _ConversationListView(
                  activeConversationId: activeConversationId,
                  onSelectConversation: onSelectConversation,
                ),
            },
          ),
        ),
      ],
    );
  }
}

class _MessagesHeader extends ConsumerWidget {
  const _MessagesHeader({required this.unreadCount});

  final int unreadCount;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final conversationsState = ref.watch(conversationsNotifierProvider);
    final activeTab = conversationsState is ConversationsLoaded
        ? conversationsState.filterTab
        : ConversationFilterTab.all;

    return Container(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 14),
      decoration: const BoxDecoration(
        color: Color(0xFAFFFDF9),
        border: Border(bottom: BorderSide(color: Color(0xCCEDE8DE))),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _TitleRow(unreadCount: unreadCount),
          const SizedBox(height: AppSpacing.sm),
          _SearchBar(
            onChanged: (query) => ref
                .read(conversationsNotifierProvider.notifier)
                .setSearchQuery(query),
          ),
          const SizedBox(height: AppSpacing.sm),
          _FilterTabs(
            activeTab: activeTab,
            unreadCount: unreadCount,
            onTabChanged: (tab) => ref
                .read(conversationsNotifierProvider.notifier)
                .setFilterTab(tab),
          ),
        ],
      ),
    );
  }
}

class _TitleRow extends StatelessWidget {
  const _TitleRow({required this.unreadCount});

  final int unreadCount;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 7,
                    height: 7,
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [_orange, Color(0xFFF7B23C)],
                      ),
                    ),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    'MESSAGES',
                    style: AppTypography.caption.copyWith(
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFF904C18),
                      letterSpacing: 0.08 * 10.5,
                      fontSize: 10.5,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 2),
              Text(
                'Your Chats',
                style: AppTypography.h2.copyWith(
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                  color: const Color(0xFF1F2937),
                  letterSpacing: -0.04 * 22,
                  height: 1.1,
                ),
              ),
            ],
          ),
        ),
        if (unreadCount > 0)
          Container(
            constraints: const BoxConstraints(minWidth: 22),
            height: 22,
            padding: const EdgeInsets.symmetric(horizontal: 6),
            decoration: BoxDecoration(
              borderRadius: AppRadius.borderFull,
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [_orange, Color(0xFFD06A18)],
              ),
            ),
            alignment: Alignment.center,
            child: Text(
              unreadCount > 99 ? '99+' : '$unreadCount',
              style: AppTypography.caption.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.w800,
                fontSize: 12,
              ),
            ),
          ),
      ],
    );
  }
}

class _SearchBar extends StatelessWidget {
  const _SearchBar({required this.onChanged});

  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 44,
      child: TextField(
        onChanged: onChanged,
        style: AppTypography.bodySm.copyWith(
          color: const Color(0xFF374151),
          fontSize: 14,
        ),
        decoration: InputDecoration(
          hintText: 'Search by name\u2026',
          hintStyle: AppTypography.bodySm.copyWith(color: AppColors.textMuted),
          prefixIcon: const Icon(
            Icons.search,
            size: 15,
            color: Color(0xFFA89C8E),
          ),
          filled: true,
          fillColor: Colors.white.withValues(alpha: 0.70),
          contentPadding: const EdgeInsets.symmetric(vertical: 12),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(color: Color(0xCCE8E2D8)),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(color: Color(0xCCE8E2D8)),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: BorderSide(color: _orange.withValues(alpha: 0.31)),
          ),
        ),
      ),
    );
  }
}

class _FilterTabs extends StatelessWidget {
  const _FilterTabs({
    required this.activeTab,
    required this.unreadCount,
    required this.onTabChanged,
  });

  final ConversationFilterTab activeTab;
  final int unreadCount;
  final ValueChanged<ConversationFilterTab> onTabChanged;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _TabChip(
          label: 'All',
          isActive: activeTab == ConversationFilterTab.all,
          onTap: () => onTabChanged(ConversationFilterTab.all),
        ),
        const SizedBox(width: 6),
        _TabChip(
          label: 'Unread',
          isActive: activeTab == ConversationFilterTab.unread,
          badgeCount: unreadCount,
          onTap: () => onTabChanged(ConversationFilterTab.unread),
        ),
      ],
    );
  }
}

class _TabChip extends StatelessWidget {
  const _TabChip({
    required this.label,
    required this.isActive,
    required this.onTap,
    this.badgeCount = 0,
  });

  final String label;
  final bool isActive;
  final VoidCallback onTap;
  final int badgeCount;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isActive ? _orange : Colors.white.withValues(alpha: 0.60),
          borderRadius: AppRadius.borderFull,
          border: isActive
              ? null
              : Border.all(color: const Color(0xE0DCD2C4), width: 1.5),
          boxShadow: isActive
              ? [
                  BoxShadow(
                    color: _orange.withValues(alpha: 0.30),
                    blurRadius: 16,
                    offset: const Offset(0, 6),
                  ),
                ]
              : null,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              label,
              style: AppTypography.label.copyWith(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: isActive ? Colors.white : const Color(0xFF7C6E60),
              ),
            ),
            if (badgeCount > 0) ...[
              const SizedBox(width: 6),
              Container(
                constraints: const BoxConstraints(minWidth: 18),
                height: 18,
                padding: const EdgeInsets.symmetric(horizontal: 4),
                decoration: BoxDecoration(
                  borderRadius: AppRadius.borderFull,
                  color: isActive
                      ? Colors.white.withValues(alpha: 0.28)
                      : _orange.withValues(alpha: 0.13),
                ),
                alignment: Alignment.center,
                child: Text(
                  badgeCount > 99 ? '99+' : '$badgeCount',
                  style: AppTypography.caption.copyWith(
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    color: isActive ? Colors.white : _orange,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _ConversationListView extends ConsumerWidget {
  const _ConversationListView({
    required this.activeConversationId,
    required this.onSelectConversation,
  });

  final String? activeConversationId;
  final ValueChanged<String> onSelectConversation;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final conversationsState = ref.watch(conversationsNotifierProvider);
    if (conversationsState is! ConversationsLoaded) {
      return const SizedBox.shrink();
    }

    final filtered = conversationsState.filteredConversations;
    final allConversations = conversationsState.conversations;

    if (allConversations.isEmpty) return const ConversationsEmptyState();

    if (conversationsState.filterTab == ConversationFilterTab.unread &&
        filtered.isEmpty) {
      return const ConversationsAllCaughtUp();
    }

    if (filtered.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Text(
            'No conversations match your search.',
            style: AppTypography.bodySm.copyWith(color: AppColors.textMuted),
          ),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(10, 12, 10, 24),
      itemCount: filtered.length,
      itemBuilder: (context, index) => ConversationRow(
        conversation: filtered[index],
        isActive: activeConversationId == filtered[index].conversationId,
        onTap: () => onSelectConversation(filtered[index].conversationId),
        entranceDelay: Duration(milliseconds: index * 40),
      ),
    );
  }
}

