/// 404 screen with Tander branding and a "Go Home" button.
library;

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'package:tander_flutter_v3/core/theme/app_colors.dart';
import 'package:tander_flutter_v3/core/theme/app_spacing.dart';
import 'package:tander_flutter_v3/core/theme/app_typography.dart';
import 'package:tander_flutter_v3/shared/constants/routes.dart';
import 'package:tander_flutter_v3/shared/widgets/tander_button.dart';

class NotFoundScreen extends StatelessWidget {
  const NotFoundScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.canvas,
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Tander-branded 404 illustration.
                _NotFoundIllustration(),
                const SizedBox(height: AppSpacing.xl),
                Text(
                  'Page not found',
                  style: AppTypography.h1,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: AppSpacing.sm),
                Text(
                  'The page you are looking for does not exist '
                  'or has been moved.',
                  style: AppTypography.body.copyWith(
                    color: AppColors.textMuted,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: AppSpacing.xl),
                TanderButton(
                  label: 'Go Home',
                  onPressed: () => context.go(AppRoutes.home),
                  icon: Icons.home_rounded,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ── Illustration ───────────────────────────────────────────────────────

class _NotFoundIllustration extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 160,
      height: 160,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Outer warm ring.
          Container(
            width: 160,
            height: 160,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  AppColors.primary.withValues(alpha: 0.08),
                  AppColors.secondary.withValues(alpha: 0.06),
                ],
              ),
            ),
          ),
          // Inner ring.
          Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  AppColors.primary.withValues(alpha: 0.14),
                  AppColors.secondary.withValues(alpha: 0.10),
                ],
              ),
            ),
          ),
          // Center icon.
          Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  AppColors.primary.withValues(alpha: 0.22),
                  AppColors.secondary.withValues(alpha: 0.16),
                ],
              ),
            ),
            child: const Center(
              child: Text(
                '404',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                  color: AppColors.primary,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
