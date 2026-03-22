/// Sub-widgets for the community post detail screen.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:tander_flutter_v3/core/contracts/models/community_models.dart';
import 'package:tander_flutter_v3/core/theme/app_colors.dart';
import 'package:tander_flutter_v3/core/theme/app_spacing.dart';
import 'package:tander_flutter_v3/core/theme/app_typography.dart';
import 'package:tander_flutter_v3/features/community/presentation/notifiers/community_post_notifier.dart';
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
        border: Border(
          bottom: BorderSide(color: AppColors.border, width: 0.5),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _PostAuthorRow(post: post),
          if (post.content.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.sm),
            Text(post.content, style: AppTypography.body),
          ],
          if (post.mediaUrls.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.sm),
            _InlinePhotoGrid(urls: post.mediaUrls),
          ],
          const SizedBox(height: AppSpacing.sm),
          _PostActions(
            post: post,
            onToggleReaction: onToggleReaction,
          ),
        ],
      ),
    );
  }
}

class _PostAuthorRow extends StatelessWidget {
  const _PostAuthorRow({required this.post});

  final CommunityPostItem post;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        TanderAvatar(
          imageUrl: post.author.photoUrl,
          displayName: post.author.displayName,
          size: TanderAvatarSize.md,
        ),
        const SizedBox(width: AppSpacing.sm),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(post.author.displayName, style: AppTypography.label),
            Text(
              formatRelativeTime(post.createdAt),
              style: AppTypography.caption,
            ),
          ],
        ),
      ],
    );
  }
}

class _PostActions extends StatelessWidget {
  const _PostActions({
    required this.post,
    required this.onToggleReaction,
  });

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
                color:
                    post.hasReacted ? AppColors.danger : AppColors.textMuted,
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
        border: Border(
          bottom: BorderSide(color: AppColors.border, width: 0.5),
        ),
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
  const CommentTile({required this.comment, super.key});

  final CommunityCommentItem comment;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.sm,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TanderAvatar(
            imageUrl: comment.authorPhotoUrl,
            displayName: comment.authorUsername,
            size: TanderAvatarSize.sm,
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      comment.authorUsername,
                      style: AppTypography.label.copyWith(fontSize: 13),
                    ),
                    const SizedBox(width: AppSpacing.xs),
                    Text(
                      formatRelativeTime(comment.createdAt),
                      style: AppTypography.caption,
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.xxs),
                Container(
                  padding: const EdgeInsets.only(left: AppSpacing.sm),
                  decoration: const BoxDecoration(
                    border: Border(
                      left: BorderSide(color: AppColors.border, width: 2),
                    ),
                  ),
                  child: Text(comment.body, style: AppTypography.body),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── Comment input ──────────────────────────────────────────────────────

class PostCommentInput extends ConsumerStatefulWidget {
  const PostCommentInput({
    required this.postId,
    required this.isSending,
    super.key,
  });

  final int postId;
  final bool isSending;

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
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _controller,
              maxLines: 3,
              minLines: 1,
              textInputAction: TextInputAction.send,
              onSubmitted: (_) => _handleSend(),
              decoration: InputDecoration(
                hintText: 'Write a comment...',
                hintStyle: AppTypography.body.copyWith(color: AppColors.textMuted),
                border: borderDecoration,
                enabledBorder: borderDecoration,
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
                ),
                filled: true,
                fillColor: AppColors.subtle,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.md, vertical: AppSpacing.sm,
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
                            colors: [AppColors.secondary, Color(0xFF0A7068)])
                        : null,
                    color: canSend ? null : AppColors.subtle,
                  ),
                  child: Icon(Icons.send_rounded, size: 20,
                    color: canSend ? AppColors.textInverse : AppColors.textMuted),
                ),
              );
            },
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
