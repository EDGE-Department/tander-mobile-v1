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
  Future<Result<CommunityPostItem>> fetchPost({required int postId});

  /// Creates a new post with text content and optional photo paths.
  Future<Result<CommunityPostItem>> createPost({
    required String content,
    List<String> photoPaths,
  });

  /// Fetches comments for a post, optionally paging with [cursor].
  Future<Result<CommentsPage>> fetchComments({
    required int postId,
    String? cursor,
  });

  /// Creates a comment on a post.
  Future<Result<CommunityCommentItem>> createComment({
    required int postId,
    required String content,
  });

  /// Toggles a reaction (like/unlike) on a post.
  Future<Result<void>> toggleReaction({required int postId});
}
