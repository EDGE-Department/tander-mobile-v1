import 'package:flutter/material.dart';

import 'package:tander_flutter_v3/core/theme/app_colors.dart';
import 'package:tander_flutter_v3/core/theme/app_radius.dart';
import 'package:tander_flutter_v3/core/theme/app_spacing.dart';
import 'package:tander_flutter_v3/core/theme/app_typography.dart';

/// Warm gradient background used by all three onboarding screens.
const BoxDecoration onboardingGradientBackground = BoxDecoration(
  gradient: LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [AppColors.primaryLight, AppColors.secondaryLight],
  ),
);

/// Pill badge showing "Step N of 3".
class OnboardingStepBadge extends StatelessWidget {
  const OnboardingStepBadge({required this.currentStep, super.key});

  final int currentStep;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.sm,
          vertical: AppSpacing.xxs,
        ),
        decoration: BoxDecoration(
          color: AppColors.primary.withValues(alpha: 0.12),
          borderRadius: AppRadius.borderFull,
        ),
        child: Text(
          'Step $currentStep of 3',
          style: AppTypography.label.copyWith(
            color: AppColors.primary,
            fontSize: 13,
          ),
        ),
      ),
    );
  }
}

/// Prominent error banner with light-red background.
class OnboardingErrorBanner extends StatelessWidget {
  const OnboardingErrorBanner({required this.message, super.key});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.sm),
      decoration: BoxDecoration(
        color: AppColors.dangerLight,
        borderRadius: AppRadius.borderSm,
        border: Border.all(color: AppColors.danger.withValues(alpha: 0.2)),
      ),
      child: Text(
        message,
        style: AppTypography.bodySm.copyWith(
          color: AppColors.danger,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
