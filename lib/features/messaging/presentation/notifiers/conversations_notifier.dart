import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:tander_flutter_v3/core/utils/app_logger.dart';
import 'package:tander_flutter_v3/features/messaging/domain/repositories/messaging_repository.dart';
import 'package:tander_flutter_v3/features/messaging/presentation/providers/messaging_providers.dart';
import 'package:tander_flutter_v3/features/messaging/presentation/states/conversations_state.dart';

/// Refresh interval for the conversation list.
const Duration _refreshInterval = Duration(seconds: 3);

// ─── Provider ──────────────────────────────────────────────────────────

final conversationsNotifierProvider =
    NotifierProvider<ConversationsNotifier, ConversationsState>(
      ConversationsNotifier.new,
    );

// ─── Notifier ──────────────────────────────────────────────────────────

/// Manages the conversations list, search, filtering, and periodic refresh.
final class ConversationsNotifier extends Notifier<ConversationsState> {
  late final MessagingRepository _repository;
  late final String _currentUserId;
  Timer? _refreshTimer;

  static const String _tag = 'ConversationsNotifier';

  @override
  ConversationsState build() {
    _repository = ref.read(messagingRepositoryProvider);
    _currentUserId = ref.read(currentUserIdProvider);

    ref.onDispose(_stopRefreshTimer);

    // Auto-fetch on first access.
    Future.microtask(loadConversations);

    return const ConversationsLoading();
  }

  // -----------------------------------------------------------------------
  // Load / refresh
  // -----------------------------------------------------------------------

  /// Loads conversations from the API, replacing any existing state.
  Future<void> loadConversations() async {
    final fetchResult = await _repository.fetchConversations(
      currentUserId: _currentUserId,
    );

    fetchResult.when(
      success: (conversations) {
        final currentState = state;
        final searchQuery = currentState is ConversationsLoaded
            ? currentState.searchQuery
            : '';
        final filterTab = currentState is ConversationsLoaded
            ? currentState.filterTab
            : ConversationFilterTab.all;

        state = ConversationsLoaded(
          conversations: conversations,
          searchQuery: searchQuery,
          filterTab: filterTab,
        );

        _startRefreshTimer();

        AppLogger.debug(
          'Loaded ${conversations.length} conversations',
          operation: _tag,
        );
      },
      failure: (exception) {
        // Only show error if we have no cached data.
        if (state is! ConversationsLoaded) {
          state = ConversationsError(exception: exception);
        }
        AppLogger.error(
          'Failed to load conversations',
          operation: _tag,
          error: exception,
        );
      },
    );
  }

  /// Triggers a silent background refresh without resetting state.
  Future<void> refreshSilently() async {
    final fetchResult = await _repository.fetchConversations(
      currentUserId: _currentUserId,
    );

    fetchResult.when(
      success: (conversations) {
        final currentState = state;
        if (currentState is ConversationsLoaded) {
          state = currentState.copyWith(conversations: conversations);
        } else {
          state = ConversationsLoaded(conversations: conversations);
        }
      },
      failure: (_) {
        // Swallow on silent refresh -- keep existing data visible.
      },
    );
  }

  // -----------------------------------------------------------------------
  // Search & filter
  // -----------------------------------------------------------------------

  /// Updates the search query.
  void setSearchQuery(String query) {
    final currentState = state;
    if (currentState is ConversationsLoaded) {
      state = currentState.copyWith(searchQuery: query);
    }
  }

  /// Updates the active filter tab.
  void setFilterTab(ConversationFilterTab tab) {
    final currentState = state;
    if (currentState is ConversationsLoaded) {
      state = currentState.copyWith(filterTab: tab);
    }
  }

  // -----------------------------------------------------------------------
  // Timer management
  // -----------------------------------------------------------------------

  void _startRefreshTimer() {
    _stopRefreshTimer();
    _refreshTimer = Timer.periodic(_refreshInterval, (_) {
      refreshSilently();
    });
  }

  void _stopRefreshTimer() {
    _refreshTimer?.cancel();
    _refreshTimer = null;
  }
}
