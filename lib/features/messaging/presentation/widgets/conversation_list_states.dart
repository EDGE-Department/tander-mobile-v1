import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import 'package:tander_flutter_v3/core/theme/app_colors.dart';
import 'package:tander_flutter_v3/core/theme/app_radius.dart';
import 'package:tander_flutter_v3/core/theme/app_spacing.dart';
import 'package:tander_flutter_v3/core/theme/app_typography.dart';

const Color _orange = AppColors.primary;
const Color _teal = AppColors.secondary;

/// Shown when the conversation list is completely empty.
class ConversationsEmptyState extends StatelessWidget {
  const ConversationsEmptyState({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 48),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  colors: [
                    _orange.withValues(alpha: 0.09),
                    _teal.withValues(alpha: 0.07),
                  ],
                ),
                border: Border.all(color: _orange.withValues(alpha: 0.13), width: 1.5),
              ),
              child: const Icon(PhosphorIconsDuotone.chatTeardropDots, size: 28, color: _orange),
            ),
            const SizedBox(height: 16),
            Text('No messages yet', style: AppTypography.h3.copyWith(fontWeight: FontWeight.w800)),
            const SizedBox(height: 6),
            Text(
              'When you connect with someone,\nyour chats appear here.',
              textAlign: TextAlign.center,
              style: AppTypography.bodySm.copyWith(color: const Color(0xFF7C7165), height: 1.6),
            ),
          ],
        ),
      ),
    );
  }
}

/// Shown when the "Unread" filter has no results.
class ConversationsAllCaughtUp extends StatelessWidget {
  const ConversationsAllCaughtUp({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 40),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('All caught up!', style: AppTypography.label.copyWith(fontSize: 15, fontWeight: FontWeight.w700)),
            const SizedBox(height: 6),
            Text('No unread conversations.', style: AppTypography.bodySm.copyWith(color: const Color(0xFF7C7165))),
          ],
        ),
      ),
    );
  }
}

/// Shown when the conversation list fetch fails.
class ConversationsErrorView extends StatelessWidget {
  const ConversationsErrorView({super.key, required this.errorMessage, required this.onRetry});

  final String errorMessage;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Could not load conversations.', style: AppTypography.label.copyWith(color: AppColors.danger)),
            const SizedBox(height: 6),
            Text(errorMessage, textAlign: TextAlign.center, style: AppTypography.bodySm.copyWith(color: AppColors.textMuted)),
            const SizedBox(height: 16),
            TextButton(onPressed: onRetry, child: const Text('Retry')),
          ],
        ),
      ),
    );
  }
}

/// Shimmer skeleton list while conversations are loading.
class ConversationsListSkeleton extends StatelessWidget {
  const ConversationsListSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(10, 8, 10, 0),
      itemCount: 6,
      itemBuilder: (_, index) => Padding(
        padding: const EdgeInsets.only(bottom: 2),
        child: Container(
          height: 72,
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          child: Row(
            children: [
              Container(
                width: 48, height: 48,
                decoration: const BoxDecoration(shape: BoxShape.circle, color: AppColors.borderLight),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(height: 14, width: double.infinity, decoration: BoxDecoration(borderRadius: AppRadius.borderSm, color: AppColors.borderLight)),
                    const SizedBox(height: 9),
                    Container(height: 12, width: 120, decoration: BoxDecoration(borderRadius: AppRadius.borderSm, color: AppColors.borderLight)),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
