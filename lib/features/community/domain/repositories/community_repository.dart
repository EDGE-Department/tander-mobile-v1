/// Contract for all community operations.
///
/// Implementations live in the data layer and may use Dio or
/// any other infrastructure concern. The domain and presentation layers
/// only know this interface.
library;

import 'package:tander_flutter_v3/core/contracts/models/community_models.dart';
import 'package:tander_flutter_v3/core/utils/result.dart';

abstract interface class CommunityRepository {
  /// Fetches the community feed, optionally paging with [cursor].
  Future<Result<CommunityFeedPage>> fetchFeed({String? cursor});

  /// Fetches a single community post by [postId].
  Future<Result<CommunityPostItem>> fetchPost({required String postId});

  /// Creates a new post with text content and optional photo paths.
  Future<Result<CommunityPostItem>> createPost({
    required String content,
    List<String> photoPaths,
  });

  /// Updates an existing post's content.
  Future<Result<CommunityPostItem>> updatePost({
    required String postId,
    required String content,
  });

  /// Deletes a post by ID.
  Future<Result<void>> deletePost({required String postId});

  /// Fetches comments for a post, optionally paging with [cursor].
  Future<Result<CommentsPage>> fetchComments({
    required String postId,
    String? cursor,
  });

  /// Creates a comment on a post. Pass [parentCommentId] for threaded replies.
  Future<Result<CommunityCommentItem>> createComment({
    required String postId,
    required String content,
    String? parentCommentId,
  });

  /// Fetches replies to a specific comment.
  Future<Result<CommentsPage>> fetchReplies({
    required String commentId,
    String? cursor,
  });

  /// Deletes a comment by ID.
  Future<Result<void>> deleteComment({required String commentId});

  /// Toggles a reaction (like/unlike) on a post.
  Future<Result<void>> toggleReaction({required String postId});
}
