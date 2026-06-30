import 'package:flutter/material.dart';

import 'package:tander_flutter_v3/core/theme/app_colors.dart';
import 'package:tander_flutter_v3/core/theme/app_radius.dart';
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
                border: Border.all(
                  color: _orange.withValues(alpha: 0.13),
                  width: 1.5,
                ),
              ),
              child: const Icon(
                Icons.chat_bubble_outline,
                size: 28,
                color: _orange,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'No messages yet',
              style: AppTypography.h3.copyWith(fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 6),
            Text(
              'When you connect with someone,\nyour chats appear here.',
              textAlign: TextAlign.center,
              style: AppTypography.bodySm.copyWith(
                color: const Color(0xFF7C7165),
                height: 1.6,
              ),
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
            Text(
              'All caught up!',
              style: AppTypography.label.copyWith(
                fontSize: 15,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'No unread conversations.',
              style: AppTypography.bodySm.copyWith(
                color: const Color(0xFF7C7165),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Shown when the conversation list fetch fails.
class ConversationsErrorView extends StatelessWidget {
  const ConversationsErrorView({super.key, required this.onRetry});

  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 40),
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
                    _orange.withValues(alpha: 0.12),
                    AppColors.danger.withValues(alpha: 0.08),
                  ],
                ),
                border: Border.all(
                  color: _orange.withValues(alpha: 0.18),
                  width: 1.5,
                ),
              ),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  const Icon(
                    Icons.error_outline_rounded,
                    size: 28,
                    color: _orange,
                  ),
                  Positioned(
                    top: 10,
                    right: 10,
                    child: Container(
                      width: 18,
                      height: 18,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: _orange.withValues(alpha: 0.16),
                      ),
                      child: const Icon(
                        Icons.refresh_rounded,
                        size: 10,
                        color: _orange,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Could not load conversations.',
              style: AppTypography.label.copyWith(
                color: AppColors.danger,
                fontSize: 15,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 6),
            SizedBox(
              width: 220,
              child: Text(
                'Check your connection and try again.',
                textAlign: TextAlign.center,
                style: AppTypography.bodySm.copyWith(
                  color: AppColors.textMuted,
                  height: 1.55,
                ),
              ),
            ),
            const SizedBox(height: 18),
            SizedBox(
              height: 40,
              child: FilledButton(
                onPressed: onRetry,
                style: FilledButton.styleFrom(
                  backgroundColor: _orange,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 18),
                  shape: const StadiumBorder(),
                  textStyle: AppTypography.label.copyWith(
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.9,
                  ),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.refresh_rounded, size: 14),
                    SizedBox(width: 8),
                    Text('TRY AGAIN'),
                  ],
                ),
              ),
            ),
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
                width: 48,
                height: 48,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.borderLight,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      height: 14,
                      width: double.infinity,
                      decoration: BoxDecoration(
                        borderRadius: AppRadius.borderSm,
                        color: AppColors.borderLight,
                      ),
                    ),
                    const SizedBox(height: 9),
                    Container(
                      height: 12,
                      width: 120,
                      decoration: BoxDecoration(
                        borderRadius: AppRadius.borderSm,
                        color: AppColors.borderLight,
                      ),
                    ),
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

// ---- Welcome placeholder (desktop: no conversation selected) -------------

/// Shown on desktop/landscape when no conversation is selected.
class MessagesWelcomePlaceholder extends StatelessWidget {
  const MessagesWelcomePlaceholder({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 40),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const _BubblesIllustration(),
            const SizedBox(height: 24),
            Text(
              'Start a conversation',
              style: AppTypography.h3.copyWith(
                fontWeight: FontWeight.w800,
                fontSize: 20,
                color: const Color(0xFF1F2937),
                letterSpacing: -0.03 * 20,
                height: 1.2,
              ),
            ),
            const SizedBox(height: 8),
            ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 280),
              child: Text(
                'Select a chat to start messaging\nor send a new message.',
                textAlign: TextAlign.center,
                style: AppTypography.bodySm.copyWith(
                  color: const Color(0xFF7C7165),
                  height: 1.65,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Two overlapping speech bubbles — orange (front-left) + teal (back-right).
class _BubblesIllustration extends StatelessWidget {
  const _BubblesIllustration();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 96,
      height: 80,
      child: Stack(
        children: [
          // Teal bubble — back, shifted right and up
          Positioned(
            right: 0,
            top: 0,
            child: Transform.rotate(
              angle: 0.18,
              child: Container(
                width: 58,
                height: 58,
                decoration: BoxDecoration(
                  color: _teal,
                  borderRadius: BorderRadius.only(
                    topLeft: const Radius.circular(18),
                    topRight: const Radius.circular(18),
                    bottomRight: const Radius.circular(4),
                    bottomLeft: const Radius.circular(18),
                  ),
                ),
              ),
            ),
          ),
          // Orange bubble — front, shifted left and down
          Positioned(
            left: 0,
            bottom: 0,
            child: Transform.rotate(
              angle: -0.12,
              child: Container(
                width: 62,
                height: 62,
                decoration: BoxDecoration(
                  color: _orange,
                  borderRadius: BorderRadius.only(
                    topLeft: const Radius.circular(18),
                    topRight: const Radius.circular(18),
                    bottomRight: const Radius.circular(18),
                    bottomLeft: const Radius.circular(4),
                  ),
                ),
                child: const Center(
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _Dot(),
                      SizedBox(width: 5),
                      _Dot(),
                      SizedBox(width: 5),
                      _Dot(),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Dot extends StatelessWidget {
  const _Dot();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 6,
      height: 6,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: Colors.white.withValues(alpha: 0.9),
      ),
    );
  }
}
