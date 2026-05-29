import 'package:flutter/material.dart';

import 'package:tander_flutter_v3/core/theme/app_colors.dart';
import 'package:tander_flutter_v3/core/theme/app_curves.dart';
import 'package:tander_flutter_v3/core/theme/app_spacing.dart';
import 'package:tander_flutter_v3/core/theme/app_typography.dart';

/// Success state shown after OTP verification completes.
///
/// Displays a green checkmark icon, "Verified!" heading, and a
/// contextual redirect message while the parent navigates the user.
class OtpVerifiedState extends StatelessWidget {
  const OtpVerifiedState({required this.isRegistration, super.key});

  /// When `true`, shows "Taking you to set up your profile..." instead
  /// of the default "Redirecting you to sign in..." message.
  final bool isRegistration;

  @override
  Widget build(BuildContext context) {
    return AnimatedOpacity(
      opacity: 1.0,
      duration: AppDurations.entrance,
      curve: AppCurves.premiumEase,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildIcon(),
          const SizedBox(height: AppSpacing.lg),
          Text(
            'Verified!',
            style: AppTypography.h1,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            isRegistration
                ? 'Taking you to set up your profile...'
                : 'Redirecting you to sign in...',
            style: AppTypography.body.copyWith(color: AppColors.textMuted),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AppSpacing.xl),
          const SizedBox(
            width: 24,
            height: 24,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildIcon() {
    return Container(
      width: 80,
      height: 80,
      decoration: const BoxDecoration(
        color: AppColors.successLight,
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: Color(0x3322C55E),
            blurRadius: 24,
            offset: Offset(0, 8),
          ),
        ],
      ),
      child: const Icon(
        Icons.verified_rounded,
        size: 40,
        color: AppColors.success,
      ),
    );
  }
}
