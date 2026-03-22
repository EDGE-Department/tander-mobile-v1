/// Converts community DTOs into domain models.
///
/// Pure static methods with no side effects -- safe to call from any layer.
library;

import 'package:tander_flutter_v3/core/contracts/community_contracts.dart';
import 'package:tander_flutter_v3/core/contracts/models/community_models.dart';

abstract final class CommunityMapper {
  /// Maps [PostAuthorDto] to [PostAuthor].
  static PostAuthor mapAuthorDto(PostAuthorDto dto) {
    return PostAuthor(
      userId: dto.userId.toString(),
      displayName: (dto.displayName?.isNotEmpty ?? false)
          ? dto.displayName!
          : 'Tander User',
      photoUrl: dto.photoUrl,
    );
  }

  /// Maps [CommunityPostDto] to [CommunityPostItem].
  static CommunityPostItem mapPostDto(CommunityPostDto dto) {
    return CommunityPostItem(
      postId: dto.id.toString(),
      author: mapAuthorDto(dto.author),
      content: dto.content ?? '',
      mediaUrls: List<String>.unmodifiable(dto.photos),
      reactionCount: dto.reactionCount,
      commentCount: dto.commentCount,
      hasReacted: dto.hasReacted,
      createdAt: DateTime.tryParse(dto.createdAt) ?? DateTime.now(),
    );
  }

  /// Maps [CommunityCommentDto] to [CommunityCommentItem].
  static CommunityCommentItem mapCommentDto(CommunityCommentDto dto) {
    return CommunityCommentItem(
      commentId: dto.id.toString(),
      postId: dto.postId.toString(),
      authorUsername: (dto.author.displayName?.isNotEmpty ?? false)
          ? dto.author.displayName!
          : 'Tander User',
      authorPhotoUrl: dto.author.photoUrl,
      body: dto.content,
      createdAt: DateTime.tryParse(dto.createdAt) ?? DateTime.now(),
    );
  }

  /// Maps [FeedResponseDto] to [CommunityFeedPage].
  static CommunityFeedPage mapFeedResponse(FeedResponseDto dto) {
    return CommunityFeedPage(
      posts: dto.posts.map(mapPostDto).toList(),
      nextCursor: dto.nextCursor,
      hasMore: dto.hasMore,
    );
  }

  /// Maps [CommentsResponseDto] to [CommentsPage].
  static CommentsPage mapCommentsResponse(CommentsResponseDto dto) {
    return CommentsPage(
      comments: dto.comments.map(mapCommentDto).toList(),
      nextCursor: dto.nextCursor,
      hasMore: dto.hasMore,
    );
  }
}
