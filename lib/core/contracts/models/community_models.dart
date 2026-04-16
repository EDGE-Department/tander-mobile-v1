/// Community domain models -- consumed by the presentation layer.
///
/// These are immutable value objects with no serialization logic.
/// Mappers handle conversion from DTOs.
library;

import 'package:flutter/foundation.dart';

// ── Post Author ────────────────────────────────────────────────

@immutable
class PostAuthor {
  const PostAuthor({
    required this.userId,
    required this.displayName,
    this.photoUrl,
  });

  final String userId;
  final String displayName;
  final String? photoUrl;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PostAuthor &&
          runtimeType == other.runtimeType &&
          userId == other.userId;

  @override
  int get hashCode => userId.hashCode;

  @override
  String toString() => 'PostAuthor(userId: $userId, name: $displayName)';
}

// ── Community Post ─────────────────────────────────────────────

@immutable
class CommunityPostItem {
  const CommunityPostItem({
    required this.postId,
    required this.author,
    required this.content,
    required this.mediaUrls,
    required this.reactionCount,
    required this.commentCount,
    required this.hasReacted,
    required this.createdAt,
  });

  final String postId;
  final PostAuthor author;
  final String content;
  final List<String> mediaUrls;
  final int reactionCount;
  final int commentCount;
  final bool hasReacted;
  final DateTime createdAt;

  CommunityPostItem copyWith({
    String? content,
    int? reactionCount,
    int? commentCount,
    bool? hasReacted,
  }) {
    return CommunityPostItem(
      postId: postId,
      author: author,
      content: content ?? this.content,
      mediaUrls: mediaUrls,
      reactionCount: reactionCount ?? this.reactionCount,
      commentCount: commentCount ?? this.commentCount,
      hasReacted: hasReacted ?? this.hasReacted,
      createdAt: createdAt,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CommunityPostItem &&
          runtimeType == other.runtimeType &&
          postId == other.postId;

  @override
  int get hashCode => postId.hashCode;

  @override
  String toString() => 'CommunityPostItem(id: $postId)';
}

// ── Community Comment ──────────────────────────────────────────

@immutable
class CommunityCommentItem {
  const CommunityCommentItem({
    required this.commentId,
    required this.postId,
    required this.authorUserId,
    required this.authorUsername,
    required this.body,
    required this.createdAt,
    this.authorPhotoUrl,
    this.parentCommentId,
    this.replyCount = 0,
  });

  final String commentId;
  final String postId;
  final String authorUserId;
  final String authorUsername;
  final String? authorPhotoUrl;
  final String body;
  final String? parentCommentId;
  final int replyCount;
  final DateTime createdAt;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CommunityCommentItem &&
          runtimeType == other.runtimeType &&
          commentId == other.commentId;

  @override
  int get hashCode => commentId.hashCode;

  @override
  String toString() => 'CommunityCommentItem(id: $commentId)';
}

// ── Feed Page ──────────────────────────────────────────────────

@immutable
class CommunityFeedPage {
  const CommunityFeedPage({
    required this.posts,
    required this.hasMore,
    this.nextCursor,
  });

  final List<CommunityPostItem> posts;
  final String? nextCursor;
  final bool hasMore;

  static const CommunityFeedPage empty = CommunityFeedPage(
    posts: [],
    nextCursor: null,
    hasMore: false,
  );

  @override
  String toString() =>
      'CommunityFeedPage(posts: ${posts.length}, hasMore: $hasMore)';
}

// ── Comments Page ──────────────────────────────────────────────

@immutable
class CommentsPage {
  const CommentsPage({
    required this.comments,
    required this.hasMore,
    this.nextCursor,
  });

  final List<CommunityCommentItem> comments;
  final String? nextCursor;
  final bool hasMore;

  static const CommentsPage empty = CommentsPage(
    comments: [],
    nextCursor: null,
    hasMore: false,
  );
}
