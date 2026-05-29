/// Embeddable community feed panel for the discover desktop layout.
///
/// Wraps the existing community feed state and renders the same
/// post list used by [CommunityScreen], minus the standalone scaffold.
/// Includes pull-to-refresh, infinite scroll, daily prompt, and
/// create-post sheet integration.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tander_flutter_v3/core/contracts/models/community_models.dart';
import 'package:tander_flutter_v3/core/providers/core_providers.dart';
import 'package:tander_flutter_v3/core/theme/app_colors.dart';
import 'package:tander_flutter_v3/core/theme/app_spacing.dart';
import 'package:tander_flutter_v3/core/theme/app_typography.dart';
import 'package:tander_flutter_v3/features/community/presentation/notifiers/community_feed_notifier.dart';
import 'package:tander_flutter_v3/features/community/presentation/screens/community_post_screen.dart';
import 'package:tander_flutter_v3/features/community/presentation/states/community_state.dart';
import 'package:tander_flutter_v3/features/community/presentation/widgets/create_post_sheet.dart';
import 'package:tander_flutter_v3/features/community/presentation/widgets/daily_prompt_card.dart';
import 'package:tander_flutter_v3/features/community/presentation/widgets/post_card.dart';
import 'package:tander_flutter_v3/shared/widgets/empty_state.dart';
import 'package:tander_flutter_v3/shared/widgets/profile_view_modal.dart';
import 'package:tander_flutter_v3/shared/widgets/skeleton_card.dart';
import 'package:tander_flutter_v3/shared/widgets/web_error_state.dart';

class CommunityFeedPanel extends ConsumerStatefulWidget {
  const CommunityFeedPanel({super.key});

  @override
  ConsumerState<CommunityFeedPanel> createState() => _CommunityFeedPanelState();
}

class _CommunityFeedPanelState extends ConsumerState<CommunityFeedPanel> {
  final ScrollController _scrollController = ScrollController();

  static const double _loadMoreThreshold = 200;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController
      ..removeListener(_onScroll)
      ..dispose();
    super.dispose();
  }

  void _onScroll() {
    if (!_scrollController.hasClients) return;
    final maxScroll = _scrollController.position.maxScrollExtent;
    final currentScroll = _scrollController.offset;
    if (maxScroll - currentScroll <= _loadMoreThreshold) {
      ref.read(communityFeedNotifierProvider.notifier).loadMore();
    }
  }

  void _openCreatePost() {
    CreatePostSheet.show(
      context: context,
      ref: ref,
      onPostCreated: () {
        ref.read(communityFeedNotifierProvider.notifier).refreshFeed();
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final feedState = ref.watch(communityFeedNotifierProvider);

    return switch (feedState) {
      CommunityFeedLoading() => const _PanelLoadingSkeleton(),
      CommunityFeedError() => CommunityFeedErrorState(
        onRetry: () {
          ref.read(communityFeedNotifierProvider.notifier).loadFeed();
        },
      ),
      CommunityFeedLoaded(:final posts, :final isLoadingMore) =>
        posts.isEmpty
            ? Center(
                child: EmptyState(
                  title: 'Start the conversation',
                  description: 'Your neighbors are waiting to hear from you.',
                  icon: Icons.forum_outlined,
                  actionLabel: 'Write the first post',
                  onAction: _openCreatePost,
                ),
              )
            : RefreshIndicator(
                color: AppColors.primary,
                onRefresh: () => ref
                    .read(communityFeedNotifierProvider.notifier)
                    .refreshFeed(),
                child: ListView.builder(
                  controller: _scrollController,
                  padding: const EdgeInsets.fromLTRB(
                    AppSpacing.md,
                    AppSpacing.md,
                    AppSpacing.md,
                    80,
                  ),
                  itemCount: posts.length + 2,
                  itemBuilder: (context, index) {
                    if (index == 0) {
                      return Padding(
                        padding: const EdgeInsets.only(bottom: AppSpacing.md),
                        child: DailyPromptCard(onWriteStory: _openCreatePost),
                      );
                    }
                    final postIndex = index - 1;
                    if (postIndex >= posts.length) {
                      if (isLoadingMore) {
                        return const Padding(
                          padding: EdgeInsets.all(AppSpacing.lg),
                          child: Center(
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: AppColors.primary,
                            ),
                          ),
                        );
                      }
                      return const SizedBox.shrink();
                    }
                    final post = posts[postIndex];
                    final currentUserId = ref
                        .read(sessionManagerLateProvider)
                        ?.session
                        ?.userId
                        .toString();
                    final isOwnPost = currentUserId == post.author.userId;
                    return Padding(
                      padding: const EdgeInsets.only(bottom: AppSpacing.lg),
                      child: PostCard(
                        post: post,
                        isOwnPost: isOwnPost,
                        onViewPost: () {
                          _showPostDetailModal(
                            context,
                            ref,
                            postId: post.postId,
                          );
                        },
                        onToggleReaction: () {
                          ref
                              .read(communityFeedNotifierProvider.notifier)
                              .toggleReaction(postId: post.postId);
                        },
                        onViewProfile: () => showProfileViewModal(
                          context,
                          userId: post.author.userId,
                        ),
                        onEditPost: isOwnPost
                            ? () => _showEditPostDialog(context, ref, post)
                            : null,
                        onDeletePost: isOwnPost
                            ? () => _showDeleteConfirmation(
                                context,
                                ref,
                                post.postId,
                              )
                            : null,
                      ),
                    );
                  },
                ),
              ),
    };
  }
}

/// Opens a post detail + comments.
/// Mobile (<768): full-screen bottom sheet matching web.
/// Tablet/desktop: centered modal dialog.
void _showPostDetailModal(
  BuildContext context,
  WidgetRef ref, {
  required String postId,
}) {
  final screenWidth = MediaQuery.sizeOf(context).width;

  if (screenWidth >= 768) {
    // Desktop/tablet: dialog (no extra header — CommunityPostScreen has its own)
    showDialog<void>(
      context: context,
      barrierColor: Colors.black54,
      builder: (dialogContext) => Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 560, maxHeight: 700),
          child: Material(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
            clipBehavior: Clip.antiAlias,
            elevation: 8,
            surfaceTintColor: Colors.transparent,
            child: CommunityPostScreen(postId: postId),
          ),
        ),
      ),
    );
  } else {
    // Mobile: full-screen bottom sheet
    ref.read(modalVisibleProvider.notifier).state = true;
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => SizedBox(
        height: MediaQuery.sizeOf(context).height * 0.92,
        child: ClipRRect(
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          child: CommunityPostScreen(postId: postId),
        ),
      ),
    ).whenComplete(() {
      ref.read(modalVisibleProvider.notifier).state = false;
    });
  }
}

class _PanelLoadingSkeleton extends StatelessWidget {
  const _PanelLoadingSkeleton();

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Column(
        children: List.generate(
          3,
          (index) => const Padding(
            padding: EdgeInsets.only(bottom: AppSpacing.md),
            child: SkeletonCard(variant: SkeletonVariant.card),
          ),
        ),
      ),
    );
  }
}

// ── Edit / Delete helpers ──────────────────────────────────────────────

void _showEditPostDialog(
  BuildContext context,
  WidgetRef ref,
  CommunityPostItem post,
) {
  final screenWidth = MediaQuery.sizeOf(context).width;
  if (screenWidth >= 768) {
    _showEditPostAsDialog(context, ref, post);
  } else {
    _showEditPostAsSheet(context, ref, post);
  }
}

void _showEditPostAsSheet(
  BuildContext context,
  WidgetRef ref,
  CommunityPostItem post,
) {
  final controller = TextEditingController(text: post.content);
  ref.read(modalVisibleProvider.notifier).state = true;
  showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.white,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
    ),
    builder: (sheetContext) => Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(sheetContext).viewInsets.bottom,
      ),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(8, 12, 16, 8),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.close, size: 24),
                    onPressed: () => Navigator.of(sheetContext).pop(),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    'Edit post',
                    style: AppTypography.body.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const Spacer(),
                  FilledButton(
                    onPressed: () async {
                      final newContent = controller.text.trim();
                      if (newContent.isEmpty) return;
                      Navigator.of(sheetContext).pop();
                      await ref
                          .read(communityFeedNotifierProvider.notifier)
                          .updatePost(postId: post.postId, content: newContent);
                    },
                    style: FilledButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 10,
                      ),
                    ),
                    child: const Text('Save'),
                  ),
                ],
              ),
            ),
            const Divider(height: 1, color: AppColors.border),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 20,
                    backgroundImage: post.author.photoUrl != null
                        ? NetworkImage(post.author.photoUrl!)
                        : null,
                    backgroundColor: AppColors.subtle,
                    child: post.author.photoUrl == null
                        ? const Icon(Icons.person, size: 20)
                        : null,
                  ),
                  const SizedBox(width: 12),
                  Text(
                    post.author.displayName.toUpperCase(),
                    style: AppTypography.label.copyWith(
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 4),
              child: TextField(
                controller: controller,
                maxLines: 5,
                maxLength: 2000,
                autofocus: true,
                decoration: InputDecoration(
                  hintText: 'Update your post...',
                  hintStyle: const TextStyle(color: AppColors.textDisabled),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: const BorderSide(color: AppColors.border),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: const BorderSide(
                      color: AppColors.primary,
                      width: 2,
                    ),
                  ),
                  contentPadding: const EdgeInsets.all(16),
                ),
              ),
            ),
            if (post.mediaUrls.isNotEmpty)
              SizedBox(
                height: 88,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  itemCount: post.mediaUrls.length,
                  separatorBuilder: (_, _) => const SizedBox(width: 8),
                  itemBuilder: (_, index) => ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Image.network(
                      post.mediaUrls[index],
                      width: 80,
                      height: 80,
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
              ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 8),
              child: Row(
                children: [
                  const Icon(
                    Icons.photo_outlined,
                    size: 20,
                    color: AppColors.primary,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    'Photos (${post.mediaUrls.length}/4)',
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: AppColors.primary,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    ),
  ).whenComplete(() {
    ref.read(modalVisibleProvider.notifier).state = false;
  });
}

void _showEditPostAsDialog(
  BuildContext context,
  WidgetRef ref,
  CommunityPostItem post,
) {
  final controller = TextEditingController(text: post.content);
  showDialog<void>(
    context: context,
    builder: (dialogContext) => AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      surfaceTintColor: Colors.transparent,
      backgroundColor: Colors.white,
      title: Text('Edit Post', style: AppTypography.h3),
      content: TextField(
        controller: controller,
        maxLines: 6,
        maxLength: 2000,
        decoration: InputDecoration(
          hintText: 'Update your post...',
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: const BorderSide(color: AppColors.border),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: const BorderSide(color: AppColors.primary, width: 2),
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(dialogContext).pop(),
          child: const Text(
            'Cancel',
            style: TextStyle(color: AppColors.textMuted),
          ),
        ),
        FilledButton(
          onPressed: () async {
            final newContent = controller.text.trim();
            if (newContent.isEmpty) return;
            Navigator.of(dialogContext).pop();
            await ref
                .read(communityFeedNotifierProvider.notifier)
                .updatePost(postId: post.postId, content: newContent);
          },
          style: FilledButton.styleFrom(
            backgroundColor: AppColors.primary,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          child: const Text('Save'),
        ),
      ],
    ),
  );
}

void _showDeleteConfirmation(
  BuildContext context,
  WidgetRef ref,
  String postId,
) {
  showDialog<void>(
    context: context,
    builder: (dialogContext) => AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      surfaceTintColor: Colors.transparent,
      backgroundColor: Colors.white,
      title: Text('Delete Post', style: AppTypography.h3),
      content: const Text(
        'Are you sure you want to delete this post? This action cannot be undone.',
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(dialogContext).pop(),
          child: const Text(
            'Cancel',
            style: TextStyle(color: AppColors.textMuted),
          ),
        ),
        FilledButton(
          onPressed: () async {
            Navigator.of(dialogContext).pop();
            await ref
                .read(communityFeedNotifierProvider.notifier)
                .deletePost(postId: postId);
          },
          style: FilledButton.styleFrom(
            backgroundColor: AppColors.danger,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          child: const Text('Delete'),
        ),
      ],
    ),
  );
}
