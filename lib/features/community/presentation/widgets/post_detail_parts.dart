/// Sub-widgets for the community post detail screen.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:tander_flutter_v3/core/contracts/models/community_models.dart';
import 'package:tander_flutter_v3/core/theme/app_colors.dart';
import 'package:tander_flutter_v3/core/theme/app_spacing.dart';
import 'package:tander_flutter_v3/core/theme/app_typography.dart';
import 'package:tander_flutter_v3/features/community/presentation/notifiers/community_post_notifier.dart';
import 'package:tander_flutter_v3/shared/widgets/profile_view_modal.dart';
import 'package:tander_flutter_v3/shared/widgets/tander_avatar.dart';

// ── Post content ───────────────────────────────────────────────────────

class PostDetailContent extends StatelessWidget {
  const PostDetailContent({
    required this.post,
    required this.onToggleReaction,
    super.key,
  });

  final CommunityPostItem post;
  final VoidCallback onToggleReaction;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: const BoxDecoration(
        color: AppColors.card,
        border: Border(bottom: BorderSide(color: AppColors.border, width: 0.5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _PostAuthorRow(
            post: post,
            onTap: () =>
                showProfileViewModal(context, userId: post.author.userId),
          ),
          if (post.content.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.sm),
            Text(post.content, style: AppTypography.body),
          ],
          if (post.mediaUrls.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.sm),
            _InlinePhotoGrid(urls: post.mediaUrls),
          ],
          const SizedBox(height: AppSpacing.sm),
          _PostActions(post: post, onToggleReaction: onToggleReaction),
        ],
      ),
    );
  }
}

class _PostAuthorRow extends StatelessWidget {
  const _PostAuthorRow({required this.post, this.onTap});

  final CommunityPostItem post;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Row(
        children: [
          TanderAvatar(
            imageUrl: post.author.photoUrl,
            displayName: post.author.displayName,
            size: TanderAvatarSize.md,
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  post.author.displayName,
                  style: AppTypography.label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  formatRelativeTime(post.createdAt),
                  style: AppTypography.caption,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _PostActions extends StatelessWidget {
  const _PostActions({required this.post, required this.onToggleReaction});

  final CommunityPostItem post;
  final VoidCallback onToggleReaction;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        GestureDetector(
          onTap: onToggleReaction,
          child: Row(
            children: [
              Icon(
                post.hasReacted ? Icons.favorite : Icons.favorite_border,
                size: 20,
                color: post.hasReacted ? AppColors.danger : AppColors.textMuted,
              ),
              const SizedBox(width: AppSpacing.xxs + 2),
              Text(
                '${post.reactionCount}',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: post.hasReacted
                      ? AppColors.danger
                      : AppColors.textMuted,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: AppSpacing.lg),
        Row(
          children: [
            const Icon(
              Icons.chat_bubble_outline_rounded,
              size: 18,
              color: AppColors.textMuted,
            ),
            const SizedBox(width: AppSpacing.xxs + 2),
            Text(
              '${post.commentCount}',
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: AppColors.textMuted,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _InlinePhotoGrid extends StatelessWidget {
  const _InlinePhotoGrid({required this.urls});

  final List<String> urls;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: GridView.count(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        crossAxisCount: urls.length == 1 ? 1 : 2,
        crossAxisSpacing: 4,
        mainAxisSpacing: 4,
        children: urls.take(4).map((url) {
          return Image.network(
            url,
            fit: BoxFit.cover,
            errorBuilder: (_, _, _) => Container(
              color: AppColors.subtle,
              child: const Icon(
                Icons.broken_image_outlined,
                color: AppColors.textMuted,
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}

// ── Comments ───────────────────────────────────────────────────────────

class CommentsHeader extends StatelessWidget {
  const CommentsHeader({required this.commentCount, super.key});

  final int commentCount;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.sm,
      ),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: AppColors.border, width: 0.5)),
      ),
      child: Text(
        '$commentCount ${commentCount == 1 ? 'comment' : 'comments'}'
            .toUpperCase(),
        style: AppTypography.caption.copyWith(
          fontWeight: FontWeight.w600,
          letterSpacing: 1.2,
        ),
      ),
    );
  }
}

class CommentTile extends StatelessWidget {
  const CommentTile({
    required this.comment,
    required this.depth,
    required this.onReply,
    this.expandedReplies = const [],
    this.onExpandReplies,
    this.parentAuthor,
    this.isExpanded = false,
    this.onToggleExpand,
    this.currentUserId,
    this.onDelete,
    super.key,
  });

  final CommunityCommentItem comment;
  final int depth;
  final ValueChanged<CommunityCommentItem> onReply;
  final List<CommunityCommentItem> expandedReplies;
  final VoidCallback? onExpandReplies;
  final String? parentAuthor;
  final bool isExpanded;
  final VoidCallback? onToggleExpand;
  final String? currentUserId;
  final VoidCallback? onDelete;

  static const int _maxVisualDepth = 3;
  static const List<Color> _threadColors = [
    AppColors.primary,
    AppColors.secondary,
    Color(0xFFB47A1E),
    Color(0xFF9D6EC1),
  ];

  @override
  Widget build(BuildContext context) {
    final visualDepth = depth.clamp(0, _maxVisualDepth);
    final isReply = depth > 0;
    final threadColor = _threadColors[visualDepth % _threadColors.length];

    return Stack(
      children: [
        // Thread line — vertical connector
        if (isReply)
          Positioned(
            left: AppSpacing.md + (visualDepth - 1) * 28.0 + 12,
            top: 0,
            bottom: 0,
            child: Container(
              width: 2,
              decoration: BoxDecoration(
                color: threadColor.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(1),
              ),
            ),
          ),

        Padding(
          padding: EdgeInsets.only(left: visualDepth * 28.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.md,
                  vertical: 6,
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    TanderAvatar(
                      imageUrl: comment.authorPhotoUrl,
                      displayName: comment.authorUsername,
                      size: isReply ? TanderAvatarSize.xs : TanderAvatarSize.sm,
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Reply context label
                          if (isReply && parentAuthor != null)
                            Padding(
                              padding: const EdgeInsets.only(bottom: 2),
                              child: Row(
                                children: [
                                  Icon(
                                    Icons.reply,
                                    size: 10,
                                    color: threadColor.withValues(alpha: 0.6),
                                  ),
                                  const SizedBox(width: 3),
                                  Flexible(
                                    child: Text.rich(
                                      TextSpan(
                                        style: AppTypography.caption.copyWith(
                                          color: AppColors.textMuted,
                                        ),
                                        children: [
                                          const TextSpan(text: 'replying to '),
                                          TextSpan(
                                            text: parentAuthor,
                                            style: const TextStyle(
                                              fontWeight: FontWeight.w600,
                                              color: AppColors.textBody,
                                            ),
                                          ),
                                        ],
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ],
                              ),
                            ),

                          // Comment bubble
                          Container(
                            padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
                            decoration: BoxDecoration(
                              color: isReply
                                  ? threadColor.withValues(alpha: 0.04)
                                  : AppColors.subtle,
                              borderRadius: const BorderRadius.only(
                                topLeft: Radius.circular(4),
                                topRight: Radius.circular(16),
                                bottomLeft: Radius.circular(16),
                                bottomRight: Radius.circular(16),
                              ),
                              border: isReply
                                  ? Border(
                                      left: BorderSide(
                                        color: threadColor.withValues(
                                          alpha: 0.3,
                                        ),
                                        width: 2,
                                      ),
                                    )
                                  : null,
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Flexible(
                                      child: Text(
                                        comment.authorUsername,
                                        style: AppTypography.label.copyWith(
                                          fontSize: isReply ? 12 : 13,
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                    const SizedBox(width: 6),
                                    Text(
                                      formatRelativeTime(comment.createdAt),
                                      style: AppTypography.caption,
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  comment.body,
                                  style: AppTypography.body.copyWith(
                                    fontSize: isReply ? 14 : 15,
                                  ),
                                ),
                              ],
                            ),
                          ),

                          // Reply + expand actions
                          Padding(
                            padding: const EdgeInsets.only(top: 4, left: 4),
                            child: Row(
                              children: [
                                GestureDetector(
                                  behavior: HitTestBehavior.opaque,
                                  onTap: () => onReply(comment),
                                  child: Padding(
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 6,
                                      horizontal: 2,
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        const Icon(
                                          Icons.reply,
                                          size: 13,
                                          color: AppColors.textMuted,
                                        ),
                                        const SizedBox(width: 4),
                                        Text(
                                          'Reply',
                                          style: AppTypography.caption.copyWith(
                                            fontSize: 13,
                                            fontWeight: FontWeight.w600,
                                            color: AppColors.textMuted,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                                if (currentUserId != null &&
                                    comment.authorUserId == currentUserId) ...[
                                  const SizedBox(width: 12),
                                  GestureDetector(
                                    behavior: HitTestBehavior.opaque,
                                    onTap: onDelete,
                                    child: Padding(
                                      padding: const EdgeInsets.symmetric(
                                        vertical: 6,
                                        horizontal: 2,
                                      ),
                                      child: Text(
                                        'Delete',
                                        style: AppTypography.caption.copyWith(
                                          fontSize: 13,
                                          fontWeight: FontWeight.w600,
                                          color: AppColors.textMuted,
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                                if (comment.replyCount > 0) ...[
                                  const SizedBox(width: 12),
                                  GestureDetector(
                                    behavior: HitTestBehavior.opaque,
                                    onTap: onExpandReplies ?? onToggleExpand,
                                    child: Padding(
                                      padding: const EdgeInsets.symmetric(
                                        vertical: 6,
                                        horizontal: 2,
                                      ),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Icon(
                                            isExpanded ||
                                                    expandedReplies.isNotEmpty
                                                ? Icons.expand_less
                                                : Icons.expand_more,
                                            size: 14,
                                            color:
                                                isExpanded ||
                                                    expandedReplies.isNotEmpty
                                                ? AppColors.textMuted
                                                : AppColors.primary,
                                          ),
                                          const SizedBox(width: 3),
                                          Text(
                                            isExpanded ||
                                                    expandedReplies.isNotEmpty
                                                ? 'Hide replies'
                                                : '${comment.replyCount} ${comment.replyCount == 1 ? 'reply' : 'replies'}',
                                            style: AppTypography.caption
                                                .copyWith(
                                                  fontSize: 13,
                                                  fontWeight: FontWeight.w700,
                                                  color:
                                                      isExpanded ||
                                                          expandedReplies
                                                              .isNotEmpty
                                                      ? AppColors.textMuted
                                                      : AppColors.primary,
                                                ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              // Nested replies
              for (final reply in expandedReplies)
                CommentTile(
                  comment: reply,
                  depth: depth + 1,
                  onReply: onReply,
                  parentAuthor: comment.authorUsername,
                  currentUserId: currentUserId,
                  onDelete: onDelete,
                ),
            ],
          ),
        ),
      ],
    );
  }
}

// ── Comment input ──────────────────────────────────────────────────────

class PostCommentInput extends ConsumerStatefulWidget {
  const PostCommentInput({
    required this.postId,
    required this.isSending,
    this.replyTarget,
    this.onClearReply,
    super.key,
  });

  final String postId;
  final bool isSending;
  final CommunityCommentItem? replyTarget;
  final VoidCallback? onClearReply;

  @override
  ConsumerState<PostCommentInput> createState() => _PostCommentInputState();
}

class _PostCommentInputState extends ConsumerState<PostCommentInput> {
  final TextEditingController _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _handleSend() {
    final trimmed = _controller.text.trim();
    if (trimmed.isEmpty || widget.isSending) return;

    ref
        .read(communityPostNotifierProvider(widget.postId).notifier)
        .sendComment(content: trimmed);

    _controller.clear();
  }

  @override
  Widget build(BuildContext context) {
    final borderDecoration = OutlineInputBorder(
      borderRadius: BorderRadius.circular(16),
      borderSide: const BorderSide(color: AppColors.border),
    );

    return Container(
      padding: const EdgeInsets.all(AppSpacing.sm),
      decoration: const BoxDecoration(
        color: AppColors.card,
        border: Border(top: BorderSide(color: AppColors.border, width: 0.5)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Reply target indicator
          if (widget.replyTarget != null)
            Container(
              padding: const EdgeInsets.fromLTRB(12, 6, 8, 6),
              margin: const EdgeInsets.only(bottom: AppSpacing.xs),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.06),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                children: [
                  const Icon(Icons.reply, size: 14, color: AppColors.primary),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      'Replying to ${widget.replyTarget!.authorUsername}',
                      style: AppTypography.caption.copyWith(
                        fontWeight: FontWeight.w600,
                        color: AppColors.primary,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  GestureDetector(
                    onTap: widget.onClearReply,
                    child: const Padding(
                      padding: EdgeInsets.all(4),
                      child: Icon(
                        Icons.close,
                        size: 14,
                        color: AppColors.textMuted,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _controller,
                  maxLines: 3,
                  minLines: 1,
                  textInputAction: TextInputAction.send,
                  onSubmitted: (_) => _handleSend(),
                  decoration: InputDecoration(
                    hintText: widget.replyTarget != null
                        ? 'Reply to ${widget.replyTarget!.authorUsername}...'
                        : 'Write a comment...',
                    hintStyle: AppTypography.body.copyWith(
                      color: AppColors.textMuted,
                    ),
                    border: borderDecoration,
                    enabledBorder: borderDecoration,
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: const BorderSide(
                        color: AppColors.primary,
                        width: 1.5,
                      ),
                    ),
                    filled: true,
                    fillColor: AppColors.subtle,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.md,
                      vertical: AppSpacing.sm,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              ValueListenableBuilder<TextEditingValue>(
                valueListenable: _controller,
                builder: (context, textValue, _) {
                  final bool canSend =
                      textValue.text.trim().isNotEmpty && !widget.isSending;
                  return GestureDetector(
                    onTap: canSend ? _handleSend : null,
                    child: Container(
                      width: AppSpacing.touchComfortable,
                      height: AppSpacing.touchComfortable,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: canSend
                            ? const LinearGradient(
                                colors: [
                                  AppColors.secondary,
                                  Color(0xFF0A7068),
                                ],
                              )
                            : null,
                        color: canSend ? null : AppColors.subtle,
                      ),
                      child: Icon(
                        Icons.send_rounded,
                        size: 20,
                        color: canSend
                            ? AppColors.textInverse
                            : AppColors.textMuted,
                      ),
                    ),
                  );
                },
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ── Helpers ────────────────────────────────────────────────────────────

String formatRelativeTime(DateTime dateTime) {
  final difference = DateTime.now().difference(dateTime);

  if (difference.inMinutes < 1) return 'just now';
  if (difference.inMinutes < 60) return '${difference.inMinutes}m ago';
  if (difference.inHours < 24) return '${difference.inHours}h ago';
  if (difference.inDays < 7) return '${difference.inDays}d ago';

  return '${dateTime.month}/${dateTime.day}';
}
