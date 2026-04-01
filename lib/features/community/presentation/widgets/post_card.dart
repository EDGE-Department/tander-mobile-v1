/// Community post card — author avatar+name, text, photo grid (1-4),
/// reaction/comment buttons.
library;

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import 'package:tander_flutter_v3/core/contracts/models/community_models.dart';
import 'package:tander_flutter_v3/core/theme/app_colors.dart';
import 'package:tander_flutter_v3/core/theme/app_radius.dart';
import 'package:tander_flutter_v3/core/theme/app_spacing.dart';
import 'package:tander_flutter_v3/core/theme/app_typography.dart';
import 'package:tander_flutter_v3/shared/widgets/tander_avatar.dart';

class PostCard extends StatelessWidget {
  const PostCard({
    required this.post,
    required this.onViewPost,
    required this.onToggleReaction,
    super.key,
  });

  final CommunityPostItem post;
  final VoidCallback onViewPost;
  final VoidCallback onToggleReaction;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(AppRadius.xl),
        border: Border.all(color: AppColors.border),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0FE67E22),
            blurRadius: 12,
            offset: Offset(0, 2),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _AuthorHeader(author: post.author, createdAt: post.createdAt),
          if (post.content.isNotEmpty)
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.lg,
                0,
                AppSpacing.lg,
                AppSpacing.sm,
              ),
              child: Text(
                post.content,
                style: AppTypography.body,
              ),
            ),
          if (post.mediaUrls.isNotEmpty)
            _PostPhotoGrid(urls: post.mediaUrls),
          _ActionBar(
            reactionCount: post.reactionCount,
            commentCount: post.commentCount,
            hasReacted: post.hasReacted,
            onToggleReaction: onToggleReaction,
            onViewComments: onViewPost,
          ),
        ],
      ),
    );
  }
}

// ── Author header ──────────────────────────────────────────────────────

class _AuthorHeader extends StatelessWidget {
  const _AuthorHeader({
    required this.author,
    required this.createdAt,
  });

  final PostAuthor author;
  final DateTime createdAt;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.lg,
        AppSpacing.md,
        AppSpacing.lg,
        AppSpacing.sm,
      ),
      child: Row(
        children: [
          TanderAvatar(
            imageUrl: author.photoUrl,
            displayName: author.displayName,
            size: TanderAvatarSize.md,
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  author.displayName,
                  style: AppTypography.label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  _formatPostTime(createdAt),
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

// ── Photo grid ─────────────────────────────────────────────────────────

class _PostPhotoGrid extends StatelessWidget {
  const _PostPhotoGrid({required this.urls});

  final List<String> urls;

  @override
  Widget build(BuildContext context) {
    final displayUrls = urls.length > 4 ? urls.sublist(0, 4) : urls;
    final int crossAxisCount = displayUrls.length == 1 ? 1 : 2;

    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.lg,
        0,
        AppSpacing.lg,
        AppSpacing.sm,
      ),
      child: ClipRRect(
        borderRadius: AppRadius.borderLg,
        child: GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: crossAxisCount,
            crossAxisSpacing: 4,
            mainAxisSpacing: 4,
          ),
          itemCount: displayUrls.length,
          itemBuilder: (context, index) {
            return Stack(
              fit: StackFit.expand,
              children: [
                Image.network(
                  displayUrls[index],
                  fit: BoxFit.cover,
                  loadingBuilder: (_, child, progress) {
                    if (progress == null) return child;
                    return Container(color: AppColors.subtle);
                  },
                  errorBuilder: (_, error, _) {
                    debugPrint('Image load failed: $error');
                    return Container(
                      color: AppColors.subtle,
                      child: const Icon(
                        Icons.broken_image_outlined,
                        color: AppColors.textMuted,
                      ),
                    );
                  },
                ),
                if (index == 3 && urls.length > 4)
                  Container(
                    color: Colors.black.withValues(alpha: 0.52),
                    alignment: Alignment.center,
                    child: Text(
                      '+${urls.length - 4}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
              ],
            );
          },
        ),
      ),
    );
  }
}

// ── Action bar ─────────────────────────────────────────────────────────

class _ActionBar extends StatelessWidget {
  const _ActionBar({
    required this.reactionCount,
    required this.commentCount,
    required this.hasReacted,
    required this.onToggleReaction,
    required this.onViewComments,
  });

  final int reactionCount;
  final int commentCount;
  final bool hasReacted;
  final VoidCallback onToggleReaction;
  final VoidCallback onViewComments;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: AppSpacing.xs,
      ),
      decoration: const BoxDecoration(
        border: Border(
          top: BorderSide(
            color: AppColors.border,
            width: 0.5,
          ),
        ),
      ),
      child: Row(
        children: [
          _ActionButton(
            icon: hasReacted ? Icons.favorite : Icons.favorite_border,
            label: reactionCount > 0 ? '$reactionCount' : 'Like',
            isActive: hasReacted,
            activeColor: AppColors.danger,
            onTap: onToggleReaction,
          ),
          _ActionButton(
            icon: Icons.chat_bubble_outline_rounded,
            label: commentCount > 0 ? '$commentCount' : 'Comment',
            isActive: false,
            activeColor: AppColors.secondary,
            onTap: onViewComments,
          ),
        ],
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  const _ActionButton({
    required this.icon,
    required this.label,
    required this.isActive,
    required this.activeColor,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final bool isActive;
  final Color activeColor;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final color = isActive ? activeColor : AppColors.textMuted;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: AppRadius.borderMd,
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.sm + 2,
            vertical: AppSpacing.xs + 2,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 20, color: color),
              const SizedBox(width: AppSpacing.xxs + 2),
              Text(
                label,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: color,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Time formatting ────────────────────────────────────────────────────

String _formatPostTime(DateTime dateTime) {
  final now = DateTime.now();
  final difference = now.difference(dateTime);

  if (difference.inMinutes < 1) return 'just now';
  if (difference.inMinutes < 60) return '${difference.inMinutes}m ago';
  if (difference.inHours < 24) return '${difference.inHours}h ago';
  if (difference.inDays < 7) return '${difference.inDays}d ago';

  return '${dateTime.month}/${dateTime.day}';
}
