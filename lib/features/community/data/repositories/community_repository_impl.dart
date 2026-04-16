/// Coordinates [CommunityRemoteDatasource] to fulfil the
/// [CommunityRepository] contract.
///
/// Every public method catches all exceptions and wraps them in
/// [Failure] so callers never see raw throws.
library;

import 'package:tander_flutter_v3/core/contracts/community_contracts.dart';
import 'package:tander_flutter_v3/core/contracts/models/community_models.dart';
import 'package:tander_flutter_v3/core/errors/app_exception.dart';
import 'package:tander_flutter_v3/core/mappers/community_mapper.dart';
import 'package:tander_flutter_v3/core/utils/app_logger.dart';
import 'package:tander_flutter_v3/core/utils/result.dart';
import 'package:tander_flutter_v3/features/community/data/datasources/community_remote_datasource.dart';
import 'package:tander_flutter_v3/features/community/domain/repositories/community_repository.dart';

final class CommunityRepositoryImpl implements CommunityRepository {
  const CommunityRepositoryImpl({
    required CommunityRemoteDatasource remoteDatasource,
  }) : _remoteDatasource = remoteDatasource;

  final CommunityRemoteDatasource _remoteDatasource;

  static const String _tag = 'CommunityRepositoryImpl';

  // -----------------------------------------------------------------------
  // Feed
  // -----------------------------------------------------------------------

  @override
  Future<Result<CommunityFeedPage>> fetchFeed({String? cursor}) {
    return _runSafe('fetchFeed', () async {
      final response = await _remoteDatasource.fetchFeed(cursor: cursor);
      final body = _requireResponseBody(response.data, 'fetch feed');
      return CommunityMapper.mapFeedResponse(
        FeedResponseDto.fromJson(body),
      );
    });
  }

  // -----------------------------------------------------------------------
  // Single Post
  // -----------------------------------------------------------------------

  @override
  Future<Result<CommunityPostItem>> fetchPost({required int postId}) {
    return _runSafe('fetchPost', () async {
      final response = await _remoteDatasource.fetchPost(postId: postId);
      final body = _requireResponseBody(response.data, 'fetch post');
      return CommunityMapper.mapPostDto(
        CommunityPostDto.fromJson(body),
      );
    });
  }

  // -----------------------------------------------------------------------
  // Create Post
  // -----------------------------------------------------------------------

  @override
  Future<Result<CommunityPostItem>> createPost({
    required String content,
    List<String> photoPaths = const [],
  }) {
    return _runSafe('createPost', () async {
      final response = await _remoteDatasource.createPost(
        content: content,
        photoPaths: photoPaths,
      );
      final body = _requireResponseBody(response.data, 'create post');
      return CommunityMapper.mapPostDto(
        CommunityPostDto.fromJson(body),
      );
    });
  }

  // -----------------------------------------------------------------------
  // Update Post
  // -----------------------------------------------------------------------

  @override
  Future<Result<CommunityPostItem>> updatePost({
    required int postId,
    required String content,
  }) {
    return _runSafe('updatePost', () async {
      final response = await _remoteDatasource.updatePost(
        postId: postId,
        content: content,
      );
      final body = _requireResponseBody(response.data, 'update post');
      return CommunityMapper.mapPostDto(
        CommunityPostDto.fromJson(body),
      );
    });
  }

  // -----------------------------------------------------------------------
  // Delete Post
  // -----------------------------------------------------------------------

  @override
  Future<Result<void>> deletePost({required int postId}) {
    return _runSafe('deletePost', () async {
      await _remoteDatasource.deletePost(postId: postId);
    });
  }

  // -----------------------------------------------------------------------
  // Comments
  // -----------------------------------------------------------------------

  @override
  Future<Result<CommentsPage>> fetchComments({
    required int postId,
    String? cursor,
  }) {
    return _runSafe('fetchComments', () async {
      final response = await _remoteDatasource.fetchComments(
        postId: postId,
        cursor: cursor,
      );
      final body = _requireResponseBody(response.data, 'fetch comments');
      return CommunityMapper.mapCommentsResponse(
        CommentsResponseDto.fromJson(body),
      );
    });
  }

  @override
  Future<Result<CommunityCommentItem>> createComment({
    required int postId,
    required String content,
    int? parentCommentId,
  }) {
    return _runSafe('createComment', () async {
      final response = await _remoteDatasource.createComment(
        postId: postId,
        content: content,
        parentCommentId: parentCommentId,
      );
      final body = _requireResponseBody(response.data, 'create comment');
      return CommunityMapper.mapCommentDto(
        CommunityCommentDto.fromJson(body),
      );
    });
  }

  @override
  Future<Result<CommentsPage>> fetchReplies({
    required int commentId,
    String? cursor,
  }) {
    return _runSafe('fetchReplies', () async {
      final response = await _remoteDatasource.fetchReplies(
        commentId: commentId,
        cursor: cursor,
      );
      final body = _requireResponseBody(response.data, 'fetch replies');
      return CommunityMapper.mapCommentsResponse(
        CommentsResponseDto.fromJson(body),
      );
    });
  }

  @override
  Future<Result<void>> deleteComment({required int commentId}) {
    return _runSafe('deleteComment', () async {
      await _remoteDatasource.deleteComment(commentId: commentId);
    });
  }

  // -----------------------------------------------------------------------
  // Reactions
  // -----------------------------------------------------------------------

  @override
  Future<Result<void>> toggleReaction({required int postId}) {
    return _runSafe('toggleReaction', () async {
      await _remoteDatasource.toggleReaction(postId: postId);
    });
  }

  // -----------------------------------------------------------------------
  // Private helpers
  // -----------------------------------------------------------------------

  Future<Result<TValue>> _runSafe<TValue>(
    String operationName,
    Future<TValue> Function() action,
  ) async {
    try {
      final value = await action();
      return Success(value);
    } on AppException catch (exception) {
      return Failure(exception);
    } on Object catch (error, stackTrace) {
      AppLogger.error(
        '$operationName failed',
        operation: _tag,
        error: error,
        stackTrace: stackTrace,
      );
      return Failure(
        UnknownException(
          message: '$operationName failed: $error',
          stackTrace: stackTrace,
        ),
      );
    }
  }

  Map<String, Object?> _requireResponseBody(
    Map<String, Object?>? body,
    String endpointLabel,
  ) {
    if (body == null) {
      throw FormatException(
        'Empty response body from $endpointLabel endpoint',
      );
    }
    return body;
  }
}
