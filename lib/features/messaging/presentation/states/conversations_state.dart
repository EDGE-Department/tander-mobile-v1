import 'package:tander_flutter_v3/core/contracts/models/messaging_models.dart';
import 'package:tander_flutter_v3/core/errors/app_exception.dart';

/// Sealed state hierarchy for the conversations list UI.
///
/// Using a sealed class guarantees exhaustive `switch` -- the compiler
/// will error if a new subclass is added without updating every consumer.
sealed class ConversationsState {
  const ConversationsState();
}

/// Initial loading -- conversations are being fetched for the first time.
final class ConversationsLoading extends ConversationsState {
  const ConversationsLoading();
}

/// Conversations loaded successfully.
final class ConversationsLoaded extends ConversationsState {
  const ConversationsLoaded({
    required this.conversations,
    this.searchQuery = '',
    this.filterTab = ConversationFilterTab.all,
  });

  /// All conversations returned from the API (already sorted by recency).
  final List<ConversationItem> conversations;

  /// Active search query for filtering by participant name.
  final String searchQuery;

  /// Active filter tab.
  final ConversationFilterTab filterTab;

  /// Conversations matching current search and filter criteria.
  List<ConversationItem> get filteredConversations {
    final tabFiltered = switch (filterTab) {
      ConversationFilterTab.all => conversations,
      ConversationFilterTab.unread =>
        conversations
            .where((conv) => conv.unreadCount > 0 && !conv.isMuted)
            .toList(),
    };

    if (searchQuery.trim().isEmpty) return tabFiltered;

    final lowerQuery = searchQuery.toLowerCase();
    return tabFiltered
        .where(
          (conv) =>
              conv.participant.username.toLowerCase().contains(lowerQuery),
        )
        .toList();
  }

  /// Number of conversations with unread messages (excluding muted).
  int get unreadCount => conversations
      .where((conv) => conv.unreadCount > 0 && !conv.isMuted)
      .length;

  ConversationsLoaded copyWith({
    List<ConversationItem>? conversations,
    String? searchQuery,
    ConversationFilterTab? filterTab,
  }) {
    return ConversationsLoaded(
      conversations: conversations ?? this.conversations,
      searchQuery: searchQuery ?? this.searchQuery,
      filterTab: filterTab ?? this.filterTab,
    );
  }
}

/// Conversation fetch failed with a typed exception.
final class ConversationsError extends ConversationsState {
  const ConversationsError({required this.exception});

  final AppException exception;
}

/// Filter tabs for the conversations list.
enum ConversationFilterTab { all, unread }
