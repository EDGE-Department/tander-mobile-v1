/// Sealed state hierarchy for the community feed UI.
///
/// Using a sealed class guarantees exhaustive `switch` -- the compiler
/// will error if a new subclass is added without updating every consumer.
library;

import 'package:tander_flutter_v3/core/contracts/models/community_models.dart';
import 'package:tander_flutter_v3/core/errors/app_exception.dart';

sealed class CommunityFeedState {
  const CommunityFeedState();
}

/// Initial loading -- feed is being fetched for the first time.
final class CommunityFeedLoading extends CommunityFeedState {
  const CommunityFeedLoading();
}

/// Feed loaded successfully.
final class CommunityFeedLoaded extends CommunityFeedState {
  const CommunityFeedLoaded({
    required this.posts,
    required this.hasMore,
    this.nextCursor,
    this.isLoadingMore = false,
  });

  /// All posts loaded so far (accumulated across pages).
  final List<CommunityPostItem> posts;

  /// Cursor for the next page.
  final String? nextCursor;

  /// Whether more pages exist on the server.
  final bool hasMore;

  /// True while a loadMore request is in flight.
  final bool isLoadingMore;

  CommunityFeedLoaded copyWith({
    List<CommunityPostItem>? posts,
    String? nextCursor,
    bool? hasMore,
    bool? isLoadingMore,
  }) {
    return CommunityFeedLoaded(
      posts: posts ?? this.posts,
      nextCursor: nextCursor ?? this.nextCursor,
      hasMore: hasMore ?? this.hasMore,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
    );
  }
}

/// Feed fetch failed with a typed exception.
final class CommunityFeedError extends CommunityFeedState {
  const CommunityFeedError({required this.exception});

  final AppException exception;
}
