import 'package:flutter/material.dart';

import 'package:tander_flutter_v3/core/theme/app_colors.dart';
import 'package:tander_flutter_v3/core/theme/app_typography.dart';

class WebErrorState extends StatelessWidget {
  const WebErrorState({
    required this.iconContainer,
    required this.icon,
    required this.title,
    required this.description,
    required this.button,
    this.topPadding = 0,
    super.key,
  });

  final BoxDecoration iconContainer;
  final Widget icon;
  final String title;
  final String description;
  final Widget button;
  final double topPadding;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: EdgeInsets.fromLTRB(24, topPadding, 24, 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: iconContainer,
              alignment: Alignment.center,
              child: icon,
            ),
            const SizedBox(height: 24),
            Text(
              title,
              textAlign: TextAlign.center,
              style: AppTypography.h2.copyWith(
                fontSize: 22,
                fontWeight: FontWeight.w700,
                height: 1.2,
                color: AppColors.textStrong,
              ),
            ),
            const SizedBox(height: 8),
            ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 280),
              child: Text(
                description,
                textAlign: TextAlign.center,
                style: AppTypography.body.copyWith(
                  fontSize: 16,
                  height: 1.55,
                  color: AppColors.textMuted,
                ),
              ),
            ),
            const SizedBox(height: 32),
            Align(alignment: Alignment.center, child: button),
          ],
        ),
      ),
    );
  }
}

class DiscoverProfilesErrorState extends StatelessWidget {
  const DiscoverProfilesErrorState({
    required this.onRetry,
    this.topPadding = 0,
    super.key,
  });

  final VoidCallback onRetry;
  final double topPadding;

  @override
  Widget build(BuildContext context) {
    return WebErrorState(
      topPadding: topPadding,
      iconContainer: BoxDecoration(
        color: AppColors.danger.withValues(alpha: 0.10),
        shape: BoxShape.circle,
      ),
      icon: const Icon(Icons.close_rounded, size: 36, color: AppColors.danger),
      title: "Couldn't load profiles",
      description: 'Something went wrong. Check your connection and try again.',
      button: _GradientErrorButton(
        onTap: onRetry,
        label: 'Try again',
        icon: Icons.refresh_rounded,
      ),
    );
  }
}

class CommunityFeedErrorState extends StatelessWidget {
  const CommunityFeedErrorState({
    required this.onRetry,
    this.topPadding = 0,
    super.key,
  });

  final VoidCallback onRetry;
  final double topPadding;

  @override
  Widget build(BuildContext context) {
    return WebErrorState(
      topPadding: topPadding,
      iconContainer: BoxDecoration(
        color: AppColors.danger.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(28),
        boxShadow: const [
          BoxShadow(
            color: Color(0x12000000),
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),
      icon: const Icon(
        Icons.refresh_rounded,
        size: 36,
        color: AppColors.danger,
      ),
      title: 'Something went wrong',
      description: "We couldn't load the community feed. Please try again.",
      button: _SolidErrorButton(onTap: onRetry, label: 'TRY AGAIN'),
    );
  }
}

class _GradientErrorButton extends StatelessWidget {
  const _GradientErrorButton({
    required this.onTap,
    required this.label,
    required this.icon,
  });

  final VoidCallback onTap;
  final String label;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return UnconstrainedBox(
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(18),
          onTap: onTap,
          child: Ink(
            height: 56,
            padding: const EdgeInsets.symmetric(horizontal: 28),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(18),
              gradient: const LinearGradient(
                colors: [Color(0xFFF07020), Color(0xFFE67E22)],
              ),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x33E67E22),
                  blurRadius: 16,
                  offset: Offset(0, 6),
                ),
              ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(icon, size: 20, color: AppColors.textInverse),
                const SizedBox(width: 8),
                Text(
                  label,
                  style: AppTypography.body.copyWith(
                    color: AppColors.textInverse,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _SolidErrorButton extends StatelessWidget {
  const _SolidErrorButton({required this.onTap, required this.label});

  final VoidCallback onTap;
  final String label;

  @override
  Widget build(BuildContext context) {
    return UnconstrainedBox(
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(18),
          onTap: onTap,
          child: Ink(
            height: 48,
            padding: const EdgeInsets.symmetric(horizontal: 32),
            decoration: BoxDecoration(
              color: AppColors.textStrong,
              borderRadius: BorderRadius.circular(18),
            ),
            child: Center(
              child: Text(
                label,
                style: AppTypography.label.copyWith(
                  color: AppColors.textInverse,
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1.4,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
