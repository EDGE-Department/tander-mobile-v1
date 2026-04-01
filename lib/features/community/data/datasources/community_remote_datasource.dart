/// All community-related HTTP calls, delegating to [DioClient].
///
/// Methods return raw [Response] objects so the repository layer
/// can map DTOs to domain models and wrap errors in [Result].
library;

import 'package:dio/dio.dart';

import 'package:tander_flutter_v3/core/network/dio_client.dart';
import 'package:tander_flutter_v3/core/utils/app_logger.dart';
import 'package:tander_flutter_v3/shared/constants/api_endpoints.dart';

final class CommunityRemoteDatasource {
  const CommunityRemoteDatasource({required DioClient dioClient})
      : _dioClient = dioClient;

  final DioClient _dioClient;

  static const String _tag = 'CommunityRemoteDatasource';

  // -----------------------------------------------------------------------
  // Feed
  // -----------------------------------------------------------------------

  /// Fetches the community feed, optionally paging with [cursor].
  Future<Response<Map<String, Object?>>> fetchFeed({String? cursor}) {
    AppLogger.debug(
      'Fetching community feed',
      operation: '$_tag.fetchFeed',
      context: cursor != null ? {'cursor': cursor} : null,
    );

    final Map<String, Object>? queryParameters =
        cursor != null ? {'cursor': cursor} : null;

    return _dioClient.get<Map<String, Object?>>(
      ApiEndpoints.communityFeed,
      queryParameters: queryParameters,
    );
  }

  // -----------------------------------------------------------------------
  // Single Post
  // -----------------------------------------------------------------------

  /// Fetches a single community post by [postId].
  Future<Response<Map<String, Object?>>> fetchPost({
    required int postId,
  }) {
    AppLogger.debug(
      'Fetching community post',
      operation: '$_tag.fetchPost',
      context: {'postId': postId},
    );

    return _dioClient.get<Map<String, Object?>>(
      ApiEndpoints.communityPost(postId),
    );
  }

  // -----------------------------------------------------------------------
  // Create Post
  // -----------------------------------------------------------------------

  /// Creates a new community post with text and optional photos.
  Future<Response<Map<String, Object?>>> createPost({
    required String content,
    List<String> photoPaths = const [],
  }) {
    AppLogger.debug(
      'Creating community post',
      operation: '$_tag.createPost',
      context: {'photoCount': photoPaths.length},
    );

    final formData = FormData.fromMap(<String, Object>{
      'content': content,
      for (int index = 0; index < photoPaths.length; index++)
        'photos': MultipartFile.fromFileSync(
          photoPaths[index],
          filename: 'photo_$index.jpg',
        ),
    });

    return _dioClient.post<Map<String, Object?>>(
      ApiEndpoints.createPost,
      data: formData,
    );
  }

  // -----------------------------------------------------------------------
  // Comments
  // -----------------------------------------------------------------------

  /// Fetches comments for a post, optionally paging with [cursor].
  Future<Response<Map<String, Object?>>> fetchComments({
    required int postId,
    String? cursor,
  }) {
    AppLogger.debug(
      'Fetching comments',
      operation: '$_tag.fetchComments',
      context: {'postId': postId},
    );

    final Map<String, Object>? queryParameters =
        cursor != null ? {'cursor': cursor} : null;

    return _dioClient.get<Map<String, Object?>>(
      ApiEndpoints.postComments(postId),
      queryParameters: queryParameters,
    );
  }

  /// Creates a comment on a post. Pass [parentCommentId] for threaded replies.
  Future<Response<Map<String, Object?>>> createComment({
    required int postId,
    required String content,
    int? parentCommentId,
  }) {
    AppLogger.debug(
      'Creating comment',
      operation: '$_tag.createComment',
      context: {'postId': postId, if (parentCommentId != null) 'parentCommentId': parentCommentId},
    );

    return _dioClient.post<Map<String, Object?>>(
      ApiEndpoints.postComments(postId),
      data: <String, Object>{
        'content': content,
        if (parentCommentId != null) 'parentCommentId': parentCommentId,
      },
    );
  }

  /// Fetches replies to a specific comment.
  Future<Response<Map<String, Object?>>> fetchReplies({
    required int commentId,
    String? cursor,
  }) {
    AppLogger.debug(
      'Fetching replies',
      operation: '$_tag.fetchReplies',
      context: {'commentId': commentId},
    );

    final Map<String, Object>? queryParameters =
        cursor != null ? {'cursor': cursor} : null;

    return _dioClient.get<Map<String, Object?>>(
      ApiEndpoints.commentReplies(commentId),
      queryParameters: queryParameters,
    );
  }

  /// Deletes a comment via DELETE /api/community/comments/{commentId}.
  Future<Response<Map<String, Object?>>> deleteComment({
    required int commentId,
  }) {
    AppLogger.debug(
      'Deleting comment',
      operation: '$_tag.deleteComment',
      context: {'commentId': commentId},
    );

    return _dioClient.delete<Map<String, Object?>>(
      '/api/community/comments/$commentId',
    );
  }

  // -----------------------------------------------------------------------
  // Reactions
  // -----------------------------------------------------------------------

  /// Toggles a reaction (like/unlike) on a post.
  Future<void> toggleReaction({required int postId}) async {
    AppLogger.debug(
      'Toggling reaction',
      operation: '$_tag.toggleReaction',
      context: {'postId': postId},
    );

    await _dioClient.post<Map<String, Object?>>(
      ApiEndpoints.postReactions(postId),
    );
  }
}
