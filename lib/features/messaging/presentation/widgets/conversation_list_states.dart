import 'package:flutter/material.dart';

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
              style: AppTypography.h3.copyWith(
                fontWeight: FontWeight.w800,
              ),
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
  const ConversationsErrorView({
    super.key,
    required this.errorMessage,
    required this.onRetry,
  });

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
            Text(
              'Could not load conversations.',
              style: AppTypography.label.copyWith(
                color: AppColors.danger,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              errorMessage,
              textAlign: TextAlign.center,
              style: AppTypography.bodySm.copyWith(
                color: AppColors.textMuted,
              ),
            ),
            const SizedBox(height: 16),
            TextButton(
              onPressed: onRetry,
              child: const Text('Retry'),
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
          padding:
              const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
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

/// Shown on desktop when no conversation is selected.
/// Includes the icon circle, heading, subtitle, and three tip cards
/// matching the web `WelcomePlaceholder` exactly.
class MessagesWelcomePlaceholder extends StatelessWidget {
  const MessagesWelcomePlaceholder({super.key});

  static const _tips = [
    _WelcomeTip(
      icon: Icons.email,
      text: 'Tap a name from the list to open the chat',
    ),
    _WelcomeTip(
      icon: Icons.search,
      text: 'Use the search bar to find someone quickly',
    ),
    _WelcomeTip(
      icon: Icons.lock,
      text:
          'Your messages are private \u2014 only you and the recipient can read them',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xFFF6EFE4),
      child: Center(
        child: Padding(
          padding:
              const EdgeInsets.symmetric(horizontal: 32, vertical: 40),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Icon circle
              Container(
                width: 72,
                height: 72,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: const LinearGradient(
                    begin: Alignment(-0.5, -0.5),
                    end: Alignment(0.5, 0.5),
                    colors: [Color(0xFFFFF8EE), Color(0xFFFFF0DE)],
                  ),
                  border: Border.all(
                    color: _orange.withValues(alpha: 0.09),
                    width: 1.5,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: _orange.withValues(alpha: 0.07),
                      blurRadius: 28,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.chat_bubble_outline,
                  size: 32,
                  color: _orange,
                ),
              ),
              const SizedBox(height: 20),
              // Heading
              Text(
                'Choose a conversation',
                style: AppTypography.h3.copyWith(
                  fontWeight: FontWeight.w800,
                  fontSize: 20,
                  color: const Color(0xFF1F2937),
                  letterSpacing: -0.03 * 20,
                  height: 1.2,
                ),
              ),
              const SizedBox(height: 8),
              // Subtitle
              ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 300),
                child: Text(
                  'Select someone from the list to start chatting.',
                  textAlign: TextAlign.center,
                  style: AppTypography.bodySm.copyWith(
                    color: const Color(0xFF7C7165),
                    height: 1.7,
                  ),
                ),
              ),
              const SizedBox(height: 28),
              // Tip cards
              ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 340),
                child: Column(
                  children: [
                    for (final tip in _tips) ...[
                      _WelcomeTipCard(tip: tip),
                      if (tip != _tips.last)
                        const SizedBox(height: 8),
                    ],
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

/// Data holder for a welcome tip row.
class _WelcomeTip {
  const _WelcomeTip({required this.icon, required this.text});

  final IconData icon;
  final String text;
}

/// A single tip card in the welcome placeholder.
class _WelcomeTipCard extends StatelessWidget {
  const _WelcomeTipCard({required this.tip});

  final _WelcomeTip tip;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        borderRadius: AppRadius.borderMd,
        color: Colors.white.withValues(alpha: 0.60),
        border: Border.all(
          color: const Color(0xFFDCD2C4).withValues(alpha: 0.60),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 1),
            child: Icon(tip.icon, size: 16, color: _orange),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              tip.text,
              style: AppTypography.bodySm.copyWith(
                fontSize: 13,
                color: const Color(0xFF5C5044),
                height: 1.5,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
