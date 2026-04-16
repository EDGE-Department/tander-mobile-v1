/// Manages the community feed state: initial load, pull-to-refresh,
/// and cursor-based infinite scroll pagination.
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:tander_flutter_v3/core/utils/app_logger.dart';
import 'package:tander_flutter_v3/features/community/domain/repositories/community_repository.dart';
import 'package:tander_flutter_v3/features/community/presentation/providers/community_providers.dart';
import 'package:tander_flutter_v3/features/community/presentation/states/community_state.dart';

// ─── Provider ──────────────────────────────────────────────────────────

final communityFeedNotifierProvider =
    NotifierProvider<CommunityFeedNotifier, CommunityFeedState>(
  CommunityFeedNotifier.new,
);

// ─── Notifier ──────────────────────────────────────────────────────────

final class CommunityFeedNotifier extends Notifier<CommunityFeedState> {
  late final CommunityRepository _repository;

  static const String _tag = 'CommunityFeedNotifier';

  @override
  CommunityFeedState build() {
    _repository = ref.read(communityRepositoryProvider);

    // Auto-fetch on first access.
    Future.microtask(loadFeed);

    return const CommunityFeedLoading();
  }

  // -----------------------------------------------------------------------
  // Initial load / refresh
  // -----------------------------------------------------------------------

  /// Loads the first page of the community feed, replacing any existing state.
  Future<void> loadFeed() async {
    final fetchResult = await _repository.fetchFeed();

    fetchResult.when(
      success: (feedPage) {
        state = CommunityFeedLoaded(
          posts: feedPage.posts,
          nextCursor: feedPage.nextCursor,
          hasMore: feedPage.hasMore,
        );
        AppLogger.debug(
          'Loaded ${feedPage.posts.length} posts',
          operation: _tag,
        );
      },
      failure: (exception) {
        if (state is! CommunityFeedLoaded) {
          state = CommunityFeedError(exception: exception);
        }
        AppLogger.error(
          'Failed to load community feed',
          operation: _tag,
          error: exception,
        );
      },
    );
  }

  /// Pull-to-refresh: reloads from the beginning.
  Future<void> refreshFeed() async {
    await loadFeed();
  }

  // -----------------------------------------------------------------------
  // Infinite scroll — load next page
  // -----------------------------------------------------------------------

  /// Loads the next page of posts. No-op if already loading or no more pages.
  Future<void> loadMore() async {
    final currentState = state;
    if (currentState is! CommunityFeedLoaded) return;
    if (currentState.isLoadingMore || !currentState.hasMore) return;

    state = currentState.copyWith(isLoadingMore: true);

    final fetchResult = await _repository.fetchFeed(
      cursor: currentState.nextCursor,
    );

    fetchResult.when(
      success: (feedPage) {
        state = CommunityFeedLoaded(
          posts: [...currentState.posts, ...feedPage.posts],
          nextCursor: feedPage.nextCursor,
          hasMore: feedPage.hasMore,
        );
      },
      failure: (exception) {
        // Keep existing posts visible, just stop the loading indicator.
        state = currentState.copyWith(isLoadingMore: false);
        AppLogger.error(
          'Failed to load more posts',
          operation: _tag,
          error: exception,
        );
      },
    );
  }

  // -----------------------------------------------------------------------
  // Optimistic reaction toggle
  // -----------------------------------------------------------------------

  /// Optimistically toggles the reaction on a post in the feed.
  Future<void> toggleReaction({required String postId}) async {
    final currentState = state;
    if (currentState is! CommunityFeedLoaded) return;

    // Optimistic update.
    final updatedPosts = currentState.posts.map((post) {
      if (post.postId != postId) return post;
      return post.copyWith(
        hasReacted: !post.hasReacted,
        reactionCount: post.hasReacted
            ? post.reactionCount - 1
            : post.reactionCount + 1,
      );
    }).toList();

    state = currentState.copyWith(posts: updatedPosts);

    // Fire-and-forget server call; revert on failure.
    final parsedId = int.tryParse(postId);
    if (parsedId == null) return;

    final toggleResult = await _repository.toggleReaction(postId: parsedId);

    if (toggleResult.isFailure) {
      // Revert optimistic update.
      state = currentState;
      AppLogger.error(
        'Failed to toggle reaction',
        operation: _tag,
        error: toggleResult.exceptionOrNull,
      );
    }
  }

  /// Updates a post's content and refreshes it in the feed.
  Future<bool> updatePost({
    required String postId,
    required String content,
  }) async {
    final parsedId = int.tryParse(postId);
    if (parsedId == null) return false;

    final result = await _repository.updatePost(
      postId: parsedId,
      content: content,
    );

    if (result.isSuccess) {
      final currentState = state;
      if (currentState is CommunityFeedLoaded) {
        final updatedPosts = currentState.posts.map((post) {
          if (post.postId != postId) return post;
          return post.copyWith(content: content);
        }).toList();
        state = currentState.copyWith(posts: updatedPosts);
      }
      return true;
    }

    AppLogger.error(
      'Failed to update post',
      operation: _tag,
      error: result.exceptionOrNull,
    );
    return false;
  }

  /// Deletes a post and removes it from the feed optimistically.
  Future<bool> deletePost({required String postId}) async {
    final currentState = state;
    if (currentState is! CommunityFeedLoaded) return false;

    // Optimistic removal.
    final updatedPosts =
        currentState.posts.where((post) => post.postId != postId).toList();
    state = currentState.copyWith(posts: updatedPosts);

    final parsedId = int.tryParse(postId);
    if (parsedId == null) return false;

    final result = await _repository.deletePost(postId: parsedId);

    if (result.isFailure) {
      // Revert optimistic removal.
      state = currentState;
      AppLogger.error(
        'Failed to delete post',
        operation: _tag,
        error: result.exceptionOrNull,
      );
      return false;
    }
    return true;
  }
}
