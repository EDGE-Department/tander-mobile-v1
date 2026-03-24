/// Embeddable community feed panel for the discover desktop layout.
///
/// Wraps the existing community feed state and renders the same
/// post list used by [CommunityScreen], minus the standalone scaffold.
/// Includes pull-to-refresh, infinite scroll, daily prompt, and
/// create-post sheet integration.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:tander_flutter_v3/core/theme/app_colors.dart';
import 'package:tander_flutter_v3/core/theme/app_spacing.dart';
import 'package:tander_flutter_v3/features/community/presentation/notifiers/community_feed_notifier.dart';
import 'package:tander_flutter_v3/features/community/presentation/states/community_state.dart';
import 'package:tander_flutter_v3/features/community/presentation/widgets/create_post_sheet.dart';
import 'package:tander_flutter_v3/features/community/presentation/widgets/daily_prompt_card.dart';
import 'package:tander_flutter_v3/features/community/presentation/widgets/post_card.dart';
import 'package:tander_flutter_v3/features/community/presentation/screens/community_post_screen.dart';
import 'package:tander_flutter_v3/shared/constants/routes.dart';
import 'package:tander_flutter_v3/shared/widgets/empty_state.dart';
import 'package:tander_flutter_v3/shared/widgets/skeleton_card.dart';

class CommunityFeedPanel extends ConsumerStatefulWidget {
  const CommunityFeedPanel({super.key});

  @override
  ConsumerState<CommunityFeedPanel> createState() =>
      _CommunityFeedPanelState();
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
                    80,
                  ),
                  itemCount: posts.length + 2,
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
                      ),
                    );
                  },
                ),
              ),
    };
  }
}

/// Opens a post detail + comments as a centered modal dialog.
void _showPostDetailModal(
  BuildContext context,
  WidgetRef ref, {
  required String postId,
}) {
  final numericId = int.tryParse(postId) ?? 0;
  showDialog<void>(
    context: context,
    barrierColor: Colors.black54,
    builder: (dialogContext) => Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 560, maxHeight: 700),
        child: Material(
          color: AppColors.card,
          borderRadius: BorderRadius.circular(24),
          clipBehavior: Clip.antiAlias,
          elevation: 8,
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(8, 8, 8, 0),
                child: Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.of(dialogContext).pop(),
                    ),
                    const Text('Post', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                  ],
                ),
              ),
              const Divider(height: 1),
              Expanded(
                child: CommunityPostScreen(postId: numericId),
              ),
            ],
          ),
        ),
      ),
    ),
  );
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
