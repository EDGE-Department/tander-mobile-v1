/// Community domain -- raw backend DTOs.
///
/// These match the Java CommunityPostDTO and CommunityCommentDTO classes.
library;

import 'package:json_annotation/json_annotation.dart';

part 'community_contracts.g.dart';

// ── Post Author ────────────────────────────────────────────────

@JsonSerializable()
class PostAuthorDto {
  const PostAuthorDto({
    required this.userId,
    this.displayName,
    this.photoUrl,
  });

  factory PostAuthorDto.fromJson(Map<String, Object?> json) =>
      _$PostAuthorDtoFromJson(json);

  final String userId;
  final String? displayName;
  final String? photoUrl;

  Map<String, Object?> toJson() => _$PostAuthorDtoToJson(this);
}

// ── Post ───────────────────────────────────────────────────────

@JsonSerializable()
class CommunityPostDto {
  const CommunityPostDto({
    required this.id,
    required this.author,
    required this.reactionCount,
    required this.commentCount,
    required this.hasReacted,
    required this.createdAt,
    this.content,
    this.photos = const [],
  });

  factory CommunityPostDto.fromJson(Map<String, Object?> json) =>
      _$CommunityPostDtoFromJson(json);

  final String id;
  final PostAuthorDto author;
  final String? content;
  final List<String> photos;
  final int reactionCount;
  final int commentCount;
  final bool hasReacted;
  final String createdAt;

  Map<String, Object?> toJson() => _$CommunityPostDtoToJson(this);
}

// ── Comment ────────────────────────────────────────────────────

@JsonSerializable()
class CommunityCommentDto {
  const CommunityCommentDto({
    required this.id,
    required this.postId,
    required this.author,
    required this.content,
    required this.createdAt,
    this.parentCommentId,
    this.replyCount = 0,
  });

  factory CommunityCommentDto.fromJson(Map<String, Object?> json) =>
      _$CommunityCommentDtoFromJson(json);

  final String id;
  final String postId;
  final PostAuthorDto author;
  final String content;
  final String? parentCommentId;
  final int replyCount;
  final String createdAt;

  Map<String, Object?> toJson() => _$CommunityCommentDtoToJson(this);
}

// ── Feed Response ──────────────────────────────────────────────

@JsonSerializable()
class FeedResponseDto {
  const FeedResponseDto({
    required this.posts,
    required this.hasMore,
    this.nextCursor,
  });

  factory FeedResponseDto.fromJson(Map<String, Object?> json) =>
      _$FeedResponseDtoFromJson(json);

  final List<CommunityPostDto> posts;
  final String? nextCursor;
  final bool hasMore;

  Map<String, Object?> toJson() => _$FeedResponseDtoToJson(this);
}

// ── Comments Response ──────────────────────────────────────────

@JsonSerializable()
class CommentsResponseDto {
  const CommentsResponseDto({
    required this.comments,
    required this.hasMore,
    this.nextCursor,
  });

  factory CommentsResponseDto.fromJson(Map<String, Object?> json) =>
      _$CommentsResponseDtoFromJson(json);

  final List<CommunityCommentDto> comments;
  final String? nextCursor;
  final bool hasMore;

  Map<String, Object?> toJson() => _$CommentsResponseDtoToJson(this);
}
