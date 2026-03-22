/// Manages the state for a single community post detail page:
/// post content, comments list, sending new comments, and reactions.
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:tander_flutter_v3/core/utils/app_logger.dart';
import 'package:tander_flutter_v3/features/community/domain/repositories/community_repository.dart';
import 'package:tander_flutter_v3/features/community/presentation/providers/community_providers.dart';
import 'package:tander_flutter_v3/features/community/presentation/states/community_post_state.dart';

// ─── Provider family (keyed by postId) ──────────────────────────────

final communityPostNotifierProvider = NotifierProvider.family<
    CommunityPostNotifier, CommunityPostState, int>(
  CommunityPostNotifier.new,
);

// ─── Notifier ──────────────────────────────────────────────────────────

final class CommunityPostNotifier
    extends FamilyNotifier<CommunityPostState, int> {
  late final CommunityRepository _repository;

  static const String _tag = 'CommunityPostNotifier';

  @override
  CommunityPostState build(int arg) {
    _repository = ref.read(communityRepositoryProvider);

    Future.microtask(loadPost);

    return const CommunityPostLoading();
  }

  int get _postId => arg;

  // -----------------------------------------------------------------------
  // Initial load
  // -----------------------------------------------------------------------

  Future<void> loadPost() async {
    final postResult = await _repository.fetchPost(postId: _postId);
    final commentsResult = await _repository.fetchComments(postId: _postId);

    final post = postResult.valueOrNull;
    if (post == null) {
      final exception = postResult.exceptionOrNull;
      if (exception != null) {
        state = CommunityPostError(exception: exception);
      }
      return;
    }

    final commentsPage = commentsResult.valueOrNull;

    state = CommunityPostLoaded(
      post: post,
      comments: commentsPage?.comments ?? [],
      nextCommentsCursor: commentsPage?.nextCursor,
      hasMoreComments: commentsPage?.hasMore ?? false,
    );
  }

  // -----------------------------------------------------------------------
  // Load more comments
  // -----------------------------------------------------------------------

  Future<void> loadMoreComments() async {
    final currentState = state;
    if (currentState is! CommunityPostLoaded) return;
    if (currentState.isLoadingMoreComments ||
        !currentState.hasMoreComments) return;

    state = currentState.copyWith(isLoadingMoreComments: true);

    final commentsResult = await _repository.fetchComments(
      postId: _postId,
      cursor: currentState.nextCommentsCursor,
    );

    commentsResult.when(
      success: (commentsPage) {
        state = currentState.copyWith(
          comments: [
            ...currentState.comments,
            ...commentsPage.comments,
          ],
          nextCommentsCursor: commentsPage.nextCursor,
          hasMoreComments: commentsPage.hasMore,
          isLoadingMoreComments: false,
        );
      },
      failure: (_) {
        state = currentState.copyWith(isLoadingMoreComments: false);
      },
    );
  }

  // -----------------------------------------------------------------------
  // Send comment
  // -----------------------------------------------------------------------

  Future<void> sendComment({required String content}) async {
    final currentState = state;
    if (currentState is! CommunityPostLoaded) return;
    if (currentState.isSendingComment) return;

    state = currentState.copyWith(isSendingComment: true);

    final createResult = await _repository.createComment(
      postId: _postId,
      content: content,
    );

    createResult.when(
      success: (comment) {
        state = currentState.copyWith(
          comments: [...currentState.comments, comment],
          post: currentState.post.copyWith(
            commentCount: currentState.post.commentCount + 1,
          ),
          isSendingComment: false,
        );
      },
      failure: (exception) {
        state = currentState.copyWith(isSendingComment: false);
        AppLogger.error(
          'Failed to send comment',
          operation: _tag,
          error: exception,
        );
      },
    );
  }

  // -----------------------------------------------------------------------
  // Toggle reaction
  // -----------------------------------------------------------------------

  Future<void> toggleReaction() async {
    final currentState = state;
    if (currentState is! CommunityPostLoaded) return;

    final post = currentState.post;
    final updatedPost = post.copyWith(
      hasReacted: !post.hasReacted,
      reactionCount:
          post.hasReacted ? post.reactionCount - 1 : post.reactionCount + 1,
    );

    state = currentState.copyWith(post: updatedPost);

    final toggleResult = await _repository.toggleReaction(postId: _postId);

    if (toggleResult.isFailure) {
      state = currentState;
      AppLogger.error(
        'Failed to toggle reaction',
        operation: _tag,
        error: toggleResult.exceptionOrNull,
      );
    }
  }
}
