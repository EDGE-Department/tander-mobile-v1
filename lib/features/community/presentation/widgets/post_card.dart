/// Community post card — 1:1 replica of web's PostCard.
///
/// Avatar with gradient ring + online dot, author name + timestamp +
/// "NEIGHBOR" badge, share button + three-dot menu (edit/delete),
/// content text, photo carousel with counter + pagination dots,
/// and like/chat action bar with pill buttons.
library;

import 'package:flutter/material.dart';

import 'package:tander_flutter_v3/core/contracts/models/community_models.dart';
import 'package:tander_flutter_v3/core/theme/app_colors.dart';
import 'package:tander_flutter_v3/core/theme/app_spacing.dart';
import 'package:tander_flutter_v3/core/theme/app_typography.dart';

class PostCard extends StatelessWidget {
  const PostCard({
    required this.post,
    required this.onViewPost,
    required this.onToggleReaction,
    this.onViewProfile,
    this.onEditPost,
    this.onDeletePost,
    this.isOwnPost = false,
    super.key,
  });

  final CommunityPostItem post;
  final VoidCallback onViewPost;
  final VoidCallback onToggleReaction;
  final VoidCallback? onViewProfile;
  final VoidCallback? onEditPost;
  final VoidCallback? onDeletePost;
  final bool isOwnPost;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.card,
        // Web: rounded-[40px]
        borderRadius: BorderRadius.circular(40),
        border: Border.all(color: AppColors.border),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _AuthorHeader(
            author: post.author,
            createdAt: post.createdAt,
            isOwnPost: isOwnPost,
            onTap: onViewProfile,
            onEditPost: onEditPost,
            onDeletePost: onDeletePost,
          ),
          if (post.content.isNotEmpty)
            Padding(
              // Web: px-8 pb-6
              padding: const EdgeInsets.fromLTRB(32, 0, 32, 24),
              child: Text(
                post.content,
                // Web: text-[18px] leading-[1.65] font-medium text-text-strong
                style: AppTypography.bodyLg.copyWith(
                  fontWeight: FontWeight.w500,
                  height: 1.65,
                  color: AppColors.textStrong,
                ),
              ),
            ),
          if (post.mediaUrls.isNotEmpty)
            _PostPhotoCarousel(urls: post.mediaUrls),
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
    required this.isOwnPost,
    this.onTap,
    this.onEditPost,
    this.onDeletePost,
  });

  final PostAuthor author;
  final DateTime createdAt;
  final bool isOwnPost;
  final VoidCallback? onTap;
  final VoidCallback? onEditPost;
  final VoidCallback? onDeletePost;

  @override
  Widget build(BuildContext context) {
    return Padding(
      // Web: px-8 py-6
      padding: const EdgeInsets.fromLTRB(32, 24, 16, 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Avatar with gradient ring + online dot
          GestureDetector(
            onTap: onTap,
            child: _GradientAvatarRing(photoUrl: author.photoUrl),
          ),
          const SizedBox(width: 16),
          // Author info
          Expanded(
            child: GestureDetector(
              onTap: onTap,
              behavior: HitTestBehavior.opaque,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Web: font-black text-[16px] text-text-strong leading-tight tracking-tight
                  Text(
                    author.displayName,
                    style: AppTypography.body.copyWith(
                      fontSize: 16,
                      fontWeight: FontWeight.w900,
                      color: AppColors.textStrong,
                      height: 1.2,
                      letterSpacing: -0.3,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 6),
                  // Timestamp + dot + NEIGHBOR
                  Row(
                    children: [
                      // Web: text-[12px] text-text-muted font-bold uppercase tracking-[0.12em]
                      Flexible(
                        child: Text(
                          _formatPostTime(createdAt).toUpperCase(),
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.12 * 12,
                            color: AppColors.textMuted,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 8),
                      // Web: w-1.5 h-1.5 rounded-full bg-primary/20
                      Container(
                        width: 6,
                        height: 6,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: AppColors.primary.withValues(alpha: 0.20),
                        ),
                      ),
                      const SizedBox(width: 8),
                      // Web: text-[12px] text-primary font-black uppercase tracking-[0.12em]
                      const Text(
                        'NEIGHBOR',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 0.08 * 11,
                          color: AppColors.primary,
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          // Share button — Web: ShareNetwork 22px, w-11 h-11, rounded-2xl
          Material(
            color: Colors.transparent,
            borderRadius: BorderRadius.circular(16),
            child: InkWell(
              onTap: () {},
              borderRadius: BorderRadius.circular(16),
              child: const SizedBox(
                width: 44,
                height: 44,
                child: Icon(
                  Icons.share_outlined,
                  size: 22,
                  color: AppColors.textMuted,
                ),
              ),
            ),
          ),
          // Three-dot menu
          _PostMenu(
            isOwnPost: isOwnPost,
            onEditPost: onEditPost,
            onDeletePost: onDeletePost,
          ),
        ],
      ),
    );
  }
}

// ── Gradient avatar ring ──────────────────────────────────────────────

class _GradientAvatarRing extends StatelessWidget {
  const _GradientAvatarRing({this.photoUrl});

  final String? photoUrl;

  @override
  Widget build(BuildContext context) {
    // Web: avatar "lg" = 64px, gradient ring p-[3px], border-[3px] border-white
    return Stack(
      children: [
        Container(
          padding: const EdgeInsets.all(3),
          decoration: const BoxDecoration(
            shape: BoxShape.circle,
            gradient: LinearGradient(
              begin: Alignment.topRight,
              end: Alignment.bottomLeft,
              colors: [Color(0xFFF07020), Color(0xFFE67E22), Color(0xFF0F9D94)],
            ),
          ),
          child: Container(
            width: 58,
            height: 58,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white, width: 3),
              image: photoUrl != null
                  ? DecorationImage(
                      image: NetworkImage(photoUrl!),
                      fit: BoxFit.cover,
                    )
                  : null,
              color: photoUrl == null ? AppColors.subtle : null,
            ),
            child: photoUrl == null
                ? const Icon(Icons.person, color: AppColors.textMuted, size: 28)
                : null,
          ),
        ),
        // Web: online indicator — w-4 h-4 bg-green-500 border-[3px] border-white
        Positioned(
          bottom: 0,
          right: 0,
          child: Container(
            width: 16,
            height: 16,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: const Color(0xFF22C55E),
              border: Border.all(color: Colors.white, width: 3),
            ),
          ),
        ),
      ],
    );
  }
}

// ── Three-dot post menu ───────────────────────────────────────────────

class _PostMenu extends StatelessWidget {
  const _PostMenu({
    required this.isOwnPost,
    this.onEditPost,
    this.onDeletePost,
  });

  final bool isOwnPost;
  final VoidCallback? onEditPost;
  final VoidCallback? onDeletePost;

  @override
  Widget build(BuildContext context) {
    // Web: DotsThree 28px bold, w-11 h-11 (44px), rounded-2xl (16px)
    return SizedBox(
      width: 44,
      height: 44,
      child: IconButton(
        icon: const Icon(
          Icons.more_horiz,
          size: 28,
          color: AppColors.textMuted,
        ),
        padding: EdgeInsets.zero,
        onPressed: () => _showMenu(context),
      ),
    );
  }

  void _showMenu(BuildContext context) {
    final renderBox = context.findRenderObject()! as RenderBox;
    final overlay =
        Overlay.of(context).context.findRenderObject()! as RenderBox;
    final position = RelativeRect.fromRect(
      Rect.fromPoints(
        renderBox.localToGlobal(
          Offset(renderBox.size.width, renderBox.size.height),
          ancestor: overlay,
        ),
        renderBox.localToGlobal(
          Offset(renderBox.size.width, renderBox.size.height),
          ancestor: overlay,
        ),
      ),
      Offset.zero & overlay.size,
    );

    showMenu<String>(
      context: context,
      position: position,
      // Web: w-48 (192px), rounded-3xl (24px), border border-border, shadow-2xl
      constraints: const BoxConstraints(minWidth: 192, maxWidth: 192),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(24),
        side: const BorderSide(color: AppColors.border),
      ),
      elevation: 16,
      color: Colors.white,
      surfaceTintColor: Colors.transparent,
      items: [
        if (isOwnPost) ...[
          // Web: px-5 py-3 text-[14px] font-bold, gap-3
          _buildMenuItem(
            value: 'edit',
            icon: Icons.edit_outlined,
            label: 'Edit Post',
            iconColor: AppColors.textStrong,
            textColor: AppColors.textStrong,
          ),
          _buildMenuItem(
            value: 'delete',
            icon: Icons.delete_outline,
            label: 'Delete Post',
            iconColor: AppColors.danger,
            textColor: AppColors.danger,
          ),
        ] else
          _buildMenuItem(
            value: 'save',
            icon: Icons.favorite_border,
            label: 'Save Post',
            iconColor: AppColors.textStrong,
            textColor: AppColors.textStrong,
          ),
      ],
    ).then((value) {
      if (value == null) return;
      switch (value) {
        case 'edit':
          onEditPost?.call();
        case 'delete':
          onDeletePost?.call();
      }
    });
  }

  PopupMenuItem<String> _buildMenuItem({
    required String value,
    required IconData icon,
    required String label,
    required Color iconColor,
    required Color textColor,
  }) {
    return PopupMenuItem<String>(
      value: value,
      // Web: px-5 py-3 = 20px horizontal, 12px vertical
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      height: 48,
      child: Row(
        children: [
          Icon(icon, size: 20, color: iconColor),
          const SizedBox(width: 12),
          Text(
            label,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: textColor,
            ),
          ),
        ],
      ),
    );
  }
}

// ── Photo carousel ────────────────────────────────────────────────────

class _PostPhotoCarousel extends StatefulWidget {
  const _PostPhotoCarousel({required this.urls});

  final List<String> urls;

  @override
  State<_PostPhotoCarousel> createState() => _PostPhotoCarouselState();
}

class _PostPhotoCarouselState extends State<_PostPhotoCarousel> {
  int _currentPage = 0;
  late final PageController _pageController;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final hasMultiple = widget.urls.length > 1;

    return Stack(
      children: [
        // Web: aspect-[4/5] bg-gray-50
        AspectRatio(
          aspectRatio: 4 / 5,
          child: Container(
            color: AppColors.subtle,
            child: PageView.builder(
              controller: _pageController,
              itemCount: widget.urls.length,
              onPageChanged: (index) => setState(() => _currentPage = index),
              itemBuilder: (_, index) {
                return Image.network(
                  widget.urls[index],
                  fit: BoxFit.cover,
                  loadingBuilder: (_, child, progress) {
                    if (progress == null) return child;
                    return const Center(
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: AppColors.primary,
                      ),
                    );
                  },
                  errorBuilder: (_, error, _) {
                    debugPrint('Image load failed: $error');
                    return Container(
                      color: AppColors.subtle,
                      child: const Icon(
                        Icons.broken_image_outlined,
                        color: AppColors.textMuted,
                        size: 40,
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ),

        // Web: counter badge — top-6 right-6, bg-black/50, backdrop-blur, rounded-2xl
        if (hasMultiple)
          Positioned(
            top: 24,
            right: 24,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.50),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.white.withValues(alpha: 0.20)),
              ),
              child: Text(
                '${_currentPage + 1} / ${widget.urls.length}',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 1.5,
                ),
              ),
            ),
          ),

        // Web: pagination dots — bottom-8, gap-2.5
        if (hasMultiple)
          Positioned(
            left: 0,
            right: 0,
            bottom: 32,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(widget.urls.length, (index) {
                final isActive = index == _currentPage;
                return AnimatedContainer(
                  duration: const Duration(milliseconds: 700),
                  margin: const EdgeInsets.symmetric(horizontal: 5),
                  // Web: active w-10 (40px), inactive w-1.5 (6px), h-1.5 (6px)
                  width: isActive ? 40 : 6,
                  height: 6,
                  decoration: BoxDecoration(
                    color: isActive
                        ? Colors.white
                        : Colors.white.withValues(alpha: 0.40),
                    borderRadius: BorderRadius.circular(3),
                  ),
                );
              }),
            ),
          ),
      ],
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
      // Web: px-6 py-5 border-t border-border/40 gap-3
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
      decoration: BoxDecoration(
        border: Border(
          top: BorderSide(color: AppColors.border.withValues(alpha: 0.40)),
        ),
      ),
      child: Row(
        children: [
          // Like button — Web: flex-[1.2] h-16 rounded-[24px]
          Expanded(
            flex: 6,
            child: _LikeButton(
              reactionCount: reactionCount,
              hasReacted: hasReacted,
              onTap: onToggleReaction,
            ),
          ),
          const SizedBox(width: 12),
          // Chat button — Web: flex-1 h-16 rounded-[24px]
          Expanded(
            flex: 5,
            child: _ChatButton(
              commentCount: commentCount,
              onTap: onViewComments,
            ),
          ),
        ],
      ),
    );
  }
}

/// Web like button:
/// Active: bg-danger text-white shadow-danger/20
/// Inactive: bg-gray-50 border-2 border-transparent text-text-strong
class _LikeButton extends StatelessWidget {
  const _LikeButton({
    required this.reactionCount,
    required this.hasReacted,
    required this.onTap,
  });

  final int reactionCount;
  final bool hasReacted;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: hasReacted ? AppColors.danger : AppColors.subtle,
      borderRadius: BorderRadius.circular(24),
      elevation: hasReacted ? 2 : 0,
      shadowColor: hasReacted
          ? AppColors.danger.withValues(alpha: 0.20)
          : Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(24),
        child: Container(
          height: 64,
          alignment: Alignment.center,
          decoration: hasReacted
              ? null
              : BoxDecoration(
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: Colors.transparent, width: 2),
                ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                hasReacted ? Icons.favorite : Icons.favorite_border,
                size: 28,
                color: hasReacted ? Colors.white : AppColors.textStrong,
              ),
              const SizedBox(width: AppSpacing.sm),
              Text(
                reactionCount > 0 ? '$reactionCount' : 'LIKE',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 2.0,
                  color: hasReacted ? Colors.white : AppColors.textStrong,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Web chat button: bg-gray-50 text-text-strong hover:bg-secondary/10 hover:text-secondary
class _ChatButton extends StatelessWidget {
  const _ChatButton({required this.commentCount, required this.onTap});

  final int commentCount;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.subtle,
      borderRadius: BorderRadius.circular(24),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(24),
        child: Container(
          height: 64,
          alignment: Alignment.center,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.chat_bubble_outline_rounded,
                size: 28,
                color: AppColors.textStrong,
              ),
              const SizedBox(width: AppSpacing.sm),
              Text(
                commentCount > 0 ? '$commentCount' : 'CHAT',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 2.0,
                  color: AppColors.textStrong,
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
