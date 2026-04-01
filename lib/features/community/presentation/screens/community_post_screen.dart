/// Full community post detail screen — post content, comments list,
/// and comment input at the bottom.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:tander_flutter_v3/core/theme/app_colors.dart';
import 'package:tander_flutter_v3/core/theme/app_spacing.dart';
import 'package:tander_flutter_v3/core/theme/app_typography.dart';
import 'package:tander_flutter_v3/core/providers/core_providers.dart';
import 'package:tander_flutter_v3/features/community/presentation/notifiers/community_post_notifier.dart';
import 'package:tander_flutter_v3/features/community/presentation/states/community_post_state.dart';
import 'package:tander_flutter_v3/features/community/presentation/widgets/post_detail_parts.dart';
import 'package:tander_flutter_v3/shared/widgets/skeleton_card.dart';

class CommunityPostScreen extends ConsumerWidget {
  const CommunityPostScreen({required this.postId, super.key});

  final int postId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final postState = ref.watch(communityPostNotifierProvider(postId));

    return Scaffold(
      backgroundColor: AppColors.canvas,
      body: SafeArea(
        child: Column(
          children: [
            _PostHeader(onBack: () => context.pop()),
            Expanded(
              child: _buildBody(context, ref, postState),
            ),
            if (postState is CommunityPostLoaded)
              PostCommentInput(
                postId: postId,
                isSending: postState.isSendingComment,
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildBody(
    BuildContext context,
    WidgetRef ref,
    CommunityPostState postState,
  ) {
    return switch (postState) {
      CommunityPostLoading() => const _LoadingPlaceholder(),
      CommunityPostError(:final exception) => _ErrorPlaceholder(
          message: exception.userMessage,
        ),
      CommunityPostLoaded(
        :final post,
        :final comments,
        :final isLoadingMoreComments,
        :final replyTarget,
        :final expandedReplies,
        :final isSendingComment,
      ) =>
        Builder(builder: (context) {
        final currentUserId = ref.read(sessionManagerLateProvider)?.session?.userId.toString();
        return Column(
          children: [
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.only(bottom: AppSpacing.md),
                itemCount: comments.length + 2,
                itemBuilder: (context, index) {
                  if (index == 0) {
                    return PostDetailContent(
                      post: post,
                      onToggleReaction: () {
                        ref
                            .read(
                              communityPostNotifierProvider(postId).notifier,
                            )
                            .toggleReaction();
                      },
                    );
                  }

                  if (index == 1) {
                    return CommentsHeader(commentCount: comments.length);
                  }

                  final commentIndex = index - 2;

                  if (commentIndex >= comments.length) {
                    if (isLoadingMoreComments) {
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

                  final comment = comments[commentIndex];
                  return CommentTile(
                    comment: comment,
                    depth: 0,
                    onReply: (target) {
                      ref
                          .read(communityPostNotifierProvider(postId).notifier)
                          .setReplyTarget(target);
                    },
                    expandedReplies: expandedReplies[comment.commentId] ?? const [],
                    onExpandReplies: comment.replyCount > 0
                        ? () {
                            ref
                                .read(communityPostNotifierProvider(postId).notifier)
                                .loadReplies(commentId: comment.commentId);
                          }
                        : null,
                    currentUserId: currentUserId,
                    onDelete: () {
                      ref
                          .read(communityPostNotifierProvider(postId).notifier)
                          .deleteCommentById(commentId: comment.commentId);
                    },
                  );
                },
              ),
            ),
            PostCommentInput(
              postId: postId,
              isSending: isSendingComment,
              replyTarget: replyTarget,
              onClearReply: () {
                ref
                    .read(communityPostNotifierProvider(postId).notifier)
                    .clearReplyTarget();
              },
            ),
          ],
        );
        }),
    };
  }
}

// ── Header ─────────────────────────────────────────────────────────────

class _PostHeader extends StatelessWidget {
  const _PostHeader({required this.onBack});

  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: AppSpacing.sm,
      ),
      decoration: const BoxDecoration(
        color: AppColors.card,
        border: Border(
          bottom: BorderSide(color: AppColors.border, width: 0.5),
        ),
      ),
      child: Row(
        children: [
          IconButton(
            onPressed: onBack,
            icon: const Icon(Icons.arrow_back_rounded),
            color: AppColors.textMuted,
            tooltip: 'Back to community',
          ),
          const SizedBox(width: AppSpacing.xs),
          Text('Post', style: AppTypography.h3),
        ],
      ),
    );
  }
}

// ── Loading / Error states ─────────────────────────────────────────────

class _LoadingPlaceholder extends StatelessWidget {
  const _LoadingPlaceholder();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Padding(
        padding: EdgeInsets.all(AppSpacing.md),
        child: Column(
          children: [
            SkeletonCard(variant: SkeletonVariant.card),
            SizedBox(height: AppSpacing.md),
            SkeletonCard(variant: SkeletonVariant.card),
          ],
        ),
      ),
    );
  }
}

class _ErrorPlaceholder extends StatelessWidget {
  const _ErrorPlaceholder({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.warning_amber_rounded,
              color: AppColors.danger,
              size: 40,
            ),
            const SizedBox(height: AppSpacing.md),
            Text(
              message,
              style: AppTypography.body.copyWith(
                color: AppColors.textMuted,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
