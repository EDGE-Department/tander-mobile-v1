/// Community feed screen — scrollable post feed with pull-to-refresh,
/// infinite scroll, daily prompt card, and create-post FAB.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:tander_flutter_v3/core/theme/app_colors.dart';
import 'package:tander_flutter_v3/core/theme/app_spacing.dart';
import 'package:tander_flutter_v3/core/theme/app_typography.dart';
import 'package:tander_flutter_v3/features/community/presentation/notifiers/community_feed_notifier.dart';
import 'package:tander_flutter_v3/features/community/presentation/states/community_state.dart';
import 'package:tander_flutter_v3/features/community/presentation/widgets/create_post_sheet.dart';
import 'package:tander_flutter_v3/features/community/presentation/widgets/daily_prompt_card.dart';
import 'package:tander_flutter_v3/features/community/presentation/widgets/post_card.dart';
import 'package:tander_flutter_v3/shared/constants/routes.dart';
import 'package:tander_flutter_v3/shared/widgets/empty_state.dart';
import 'package:tander_flutter_v3/shared/widgets/skeleton_card.dart';

class CommunityScreen extends ConsumerStatefulWidget {
  const CommunityScreen({super.key});

  @override
  ConsumerState<CommunityScreen> createState() => _CommunityScreenState();
}

class _CommunityScreenState extends ConsumerState<CommunityScreen> {
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
      onPostCreated: () {
        ref.read(communityFeedNotifierProvider.notifier).refreshFeed();
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final feedState = ref.watch(communityFeedNotifierProvider);

    return Scaffold(
      backgroundColor: AppColors.canvas,
      floatingActionButton: _CreatePostFab(onPressed: _openCreatePost),
      body: SafeArea(
        child: Column(
          children: [
            _CommunityHeader(onCreatePost: _openCreatePost),
            Expanded(
              child: _buildBody(feedState),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBody(CommunityFeedState feedState) {
    return switch (feedState) {
      CommunityFeedLoading() => const _LoadingSkeleton(),
      CommunityFeedError(:final exception) => Center(
          child: EmptyState(
            title: 'Failed to load posts',
            description: exception.userMessage,
            icon: Icons.warning_amber_rounded,
            actionLabel: 'Retry',
            onAction: () {
              ref.read(communityFeedNotifierProvider.notifier).loadFeed();
            },
          ),
        ),
      CommunityFeedLoaded(:final posts, :final isLoadingMore) =>
        posts.isEmpty
            ? Center(
                child: EmptyState(
                  title: 'Start the conversation',
                  description:
                      'Your neighbors are waiting to hear from you.',
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
                    100,
                  ),
                  itemCount: posts.length + 2, // prompt + posts + loader
                  itemBuilder: (context, index) {
                    if (index == 0) {
                      return Padding(
                        padding: const EdgeInsets.only(
                          bottom: AppSpacing.md,
                        ),
                        child: DailyPromptCard(
                          onWriteStory: _openCreatePost,
                        ),
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
                    return Padding(
                      padding: const EdgeInsets.only(
                        bottom: AppSpacing.md,
                      ),
                      child: PostCard(
                        post: post,
                        onViewPost: () {
                          context.push(
                            AppRoutes.communityPost(post.postId),
                          );
                        },
                        onToggleReaction: () {
                          ref
                              .read(
                                communityFeedNotifierProvider.notifier,
                              )
                              .toggleReaction(postId: post.postId);
                        },
                      ),
                    );
                  },
                ),
              ),
    };
  }
}

// ── Header ─────────────────────────────────────────────────────────────

class _CommunityHeader extends StatelessWidget {
  const _CommunityHeader({required this.onCreatePost});

  final VoidCallback onCreatePost;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.lg,
        AppSpacing.lg,
        AppSpacing.lg,
        AppSpacing.md,
      ),
      decoration: const BoxDecoration(
        border: Border(
          bottom: BorderSide(color: AppColors.border, width: 0.5),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 32,
                      height: 4,
                      decoration: BoxDecoration(
                        color: AppColors.secondary,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                    const SizedBox(width: AppSpacing.xs),
                    Container(
                      width: 16,
                      height: 4,
                      decoration: BoxDecoration(
                        color: AppColors.primary,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  'Community',
                  style: AppTypography.h1,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          _NewPostButton(onPressed: onCreatePost),
        ],
      ),
    );
  }
}

// ── New Post Button ────────────────────────────────────────────────────

class _NewPostButton extends StatelessWidget {
  const _NewPostButton({required this.onPressed});

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(16),
        child: Ink(
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFFF07020), Color(0xFFE67E22)],
            ),
            borderRadius: BorderRadius.circular(16),
          ),
          child: MediaQuery(
            data: MediaQuery.of(context).copyWith(
              textScaler: TextScaler.noScaling,
            ),
            child: const Padding(
              padding: EdgeInsets.symmetric(
                horizontal: AppSpacing.md,
                vertical: AppSpacing.sm,
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.add, color: AppColors.textInverse, size: 18),
                  SizedBox(width: AppSpacing.xxs),
                  Text(
                    'New post',
                    style: TextStyle(
                      color: AppColors.textInverse,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ── Create Post FAB ────────────────────────────────────────────────────

class _CreatePostFab extends StatelessWidget {
  const _CreatePostFab({required this.onPressed});

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return FloatingActionButton(
      onPressed: onPressed,
      backgroundColor: AppColors.primary,
      foregroundColor: AppColors.textInverse,
      elevation: 4,
      tooltip: 'Create a new post',
      child: const Icon(Icons.edit_rounded),
    );
  }
}

// ── Loading Skeleton ───────────────────────────────────────────────────

class _LoadingSkeleton extends StatelessWidget {
  const _LoadingSkeleton();

  @override
  Widget build(BuildContext context) {
    return Padding(
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
