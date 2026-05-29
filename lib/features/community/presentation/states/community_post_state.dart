/// Sealed state hierarchy for the community post detail + comments UI.
library;

import 'package:tander_flutter_v3/core/contracts/models/community_models.dart';
import 'package:tander_flutter_v3/core/errors/app_exception.dart';

sealed class CommunityPostState {
  const CommunityPostState();
}

/// Loading the post and initial comments.
final class CommunityPostLoading extends CommunityPostState {
  const CommunityPostLoading();
}

/// Post and comments loaded successfully.
final class CommunityPostLoaded extends CommunityPostState {
  const CommunityPostLoaded({
    required this.post,
    required this.comments,
    required this.hasMoreComments,
    this.nextCommentsCursor,
    this.isLoadingMoreComments = false,
    this.isSendingComment = false,
    this.replyTarget,
    this.expandedReplies = const {},
  });

  final CommunityPostItem post;
  final List<CommunityCommentItem> comments;
  final String? nextCommentsCursor;
  final bool hasMoreComments;
  final bool isLoadingMoreComments;
  final bool isSendingComment;

  /// Comment being replied to (null = top-level comment).
  final CommunityCommentItem? replyTarget;

  /// Loaded replies keyed by parent comment ID.
  final Map<String, List<CommunityCommentItem>> expandedReplies;

  CommunityPostLoaded copyWith({
    CommunityPostItem? post,
    List<CommunityCommentItem>? comments,
    String? nextCommentsCursor,
    bool? hasMoreComments,
    bool? isLoadingMoreComments,
    bool? isSendingComment,
    CommunityCommentItem? replyTarget,
    bool clearReplyTarget = false,
    Map<String, List<CommunityCommentItem>>? expandedReplies,
  }) {
    return CommunityPostLoaded(
      post: post ?? this.post,
      comments: comments ?? this.comments,
      nextCommentsCursor: nextCommentsCursor ?? this.nextCommentsCursor,
      hasMoreComments: hasMoreComments ?? this.hasMoreComments,
      isLoadingMoreComments:
          isLoadingMoreComments ?? this.isLoadingMoreComments,
      isSendingComment: isSendingComment ?? this.isSendingComment,
      replyTarget: clearReplyTarget ? null : (replyTarget ?? this.replyTarget),
      expandedReplies: expandedReplies ?? this.expandedReplies,
    );
  }
}

/// Post fetch failed with a typed exception.
final class CommunityPostError extends CommunityPostState {
  const CommunityPostError({required this.exception});

  final AppException exception;
}
