import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:tander_flutter_v3/core/providers/core_providers.dart';
import 'package:tander_flutter_v3/core/theme/app_colors.dart';
import 'package:tander_flutter_v3/core/theme/app_spacing.dart';
import 'package:tander_flutter_v3/core/theme/app_typography.dart';
import 'package:tander_flutter_v3/features/auth/presentation/providers/auth_providers.dart';
import 'package:tander_flutter_v3/features/auth/presentation/widgets/auth_scene_decorations.dart';
import 'package:tander_flutter_v3/features/auth/shared/utils/first_name_extractor.dart';
import 'package:tander_flutter_v3/shared/constants/routes.dart';
import 'package:tander_flutter_v3/shared/widgets/tander_button.dart';

/// Terminal post-onboarding celebration screen.
///
/// Shown once, after the user finishes the notification-permission step
/// (or skips it). A `has_seen_welcome_screen` flag in [LocalStorage]
/// keeps the screen from showing again on subsequent logins.
///
/// Not gated by the onboarding redirect — this is a non-gating
/// authenticated route reachable only via explicit `context.go`.
class WelcomeScreen extends ConsumerWidget {
  const WelcomeScreen({super.key});

  static const String _hasSeenWelcomeKey = 'has_seen_welcome_screen';

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final session = ref.watch(sessionManagerProvider).session;
    final reduceMotion = MediaQuery.disableAnimationsOf(context);

    final displayName = extractFirstName(session?.username);

    return Scaffold(
      backgroundColor: const Color(0xFF20BF68),
      body: AuthStepScaffoldBody(
        parchment: AuthStepParchment(
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: () {
                final column = Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const SizedBox(height: AppSpacing.xl),
                    _CelebrationIcon(),
                    const SizedBox(height: AppSpacing.lg),
                    Text(
                      'Welcome to Tander,',
                      style: AppTypography.h2.copyWith(
                        color: AppColors.textStrong,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      '$displayName!',
                      style: AppTypography.h1.copyWith(
                        color: AppColors.primary,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.md,
                      ),
                      child: Text(
                        'Your account is verified and ready. Start exploring and connect with your community.',
                        style: AppTypography.body.copyWith(
                          color: AppColors.textMuted,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xl),
                    TanderButton(
                      label: 'Start Exploring',
                      icon: Icons.arrow_forward_rounded,
                      iconPosition: IconPosition.trailing,
                      onPressed: () => _onContinue(context, ref),
                    ),
                    const SizedBox(height: AppSpacing.md),
                  ],
                );
                if (reduceMotion) return column;
                return column
                    .animate()
                    .fadeIn(duration: 600.ms, delay: 100.ms)
                    .scale(
                      begin: const Offset(0.98, 0.98),
                      end: const Offset(1.0, 1.0),
                      duration: 700.ms,
                      delay: 100.ms,
                      curve: Curves.easeOutCubic,
                    );
              }(),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _onContinue(BuildContext context, WidgetRef ref) async {
    final localStorage = ref.read(localStorageProvider);
    await localStorage.saveBool(_hasSeenWelcomeKey, value: true);
    if (context.mounted) {
      context.go(AppRoutes.discover);
    }
  }
}

class _CelebrationIcon extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        width: 112,
        height: 112,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: const LinearGradient(
            begin: Alignment(-0.7, -1),
            end: Alignment(0.7, 1),
            colors: [AppColors.primary, AppColors.primaryHover],
          ),
          boxShadow: [
            BoxShadow(
              color: AppColors.primary.withValues(alpha: 0.35),
              blurRadius: 32,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: const Icon(
          Icons.verified_rounded,
          size: 64,
          color: AppColors.textInverse,
        ),
      ),
    );
  }
}
