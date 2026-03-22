import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:permission_handler/permission_handler.dart';

import 'package:tander_flutter_v3/core/theme/app_colors.dart';
import 'package:tander_flutter_v3/core/theme/app_radius.dart';
import 'package:tander_flutter_v3/core/theme/app_shadows.dart';
import 'package:tander_flutter_v3/core/theme/app_spacing.dart';
import 'package:tander_flutter_v3/core/theme/app_typography.dart';
import 'package:tander_flutter_v3/core/utils/app_logger.dart';
import 'package:tander_flutter_v3/features/auth/presentation/notifiers/auth_notifier.dart';
import 'package:tander_flutter_v3/features/auth/presentation/widgets/onboarding_chrome.dart';
import 'package:tander_flutter_v3/shared/constants/routes.dart';
import 'package:tander_flutter_v3/shared/widgets/tander_button.dart';

// ---------------------------------------------------------------------------
// Benefit items displayed in the feature list.
// ---------------------------------------------------------------------------

class _NotificationBenefit {
  const _NotificationBenefit({
    required this.icon,
    required this.label,
  });

  final IconData icon;
  final String label;
}

const List<_NotificationBenefit> _benefits = [
  _NotificationBenefit(
    icon: Icons.favorite_rounded,
    label: 'Know when you get a new match',
  ),
  _NotificationBenefit(
    icon: Icons.chat_bubble_rounded,
    label: 'Never miss a message',
  ),
  _NotificationBenefit(
    icon: Icons.self_improvement_rounded,
    label: 'Get reminded about your Tandy wellness sessions',
  ),
];

// ---------------------------------------------------------------------------
// Screen
// ---------------------------------------------------------------------------

/// Onboarding step 3 of 3 — requests notification permission via
/// [permission_handler]. Both "Enable" and "Maybe Later" navigate to
/// [AppRoutes.home] after refreshing the auth session.
class NotificationPermissionScreen extends ConsumerStatefulWidget {
  const NotificationPermissionScreen({super.key});

  @override
  ConsumerState<NotificationPermissionScreen> createState() =>
      _NotificationPermissionScreenState();
}

class _NotificationPermissionScreenState
    extends ConsumerState<NotificationPermissionScreen> {
  bool _isEnabling = false;

  // ── Actions ─────────────────────────────────────────────────────────

  Future<void> _enableNotifications() async {
    setState(() => _isEnabling = true);

    try {
      final status = await Permission.notification.request();

      AppLogger.info(
        'Notification permission result: ${status.name}',
        operation: 'NotificationPermissionScreen._enableNotifications',
      );
    } on Exception catch (error, stackTrace) {
      AppLogger.error(
        'Notification permission request failed',
        operation: 'NotificationPermissionScreen._enableNotifications',
        error: error,
        stackTrace: stackTrace,
      );
    } finally {
      await _navigateToHome();
    }
  }

  Future<void> _skipNotifications() async {
    await _navigateToHome();
  }

  Future<void> _navigateToHome() async {
    await ref.read(authNotifierProvider.notifier).refreshSession();
    if (mounted) {
      setState(() => _isEnabling = false);
      context.go(AppRoutes.home);
    }
  }

  // ── Build ──────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: DecoratedBox(
        decoration: onboardingGradientBackground,
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.lg,
              vertical: AppSpacing.xl,
            ),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 420),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const OnboardingStepBadge(currentStep: 3),
                    const SizedBox(height: AppSpacing.xxl),
                    _buildBellIcon(),
                    const SizedBox(height: AppSpacing.lg),
                    _buildHeading(),
                    const SizedBox(height: AppSpacing.lg),
                    _buildBenefitsList(),
                    const SizedBox(height: AppSpacing.xl),
                    _buildEnableButton(),
                    const SizedBox(height: AppSpacing.sm),
                    _buildSkipButton(),
                    const SizedBox(height: AppSpacing.md),
                    _buildFooterNote(),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBellIcon() {
    return Center(
      child: Container(
        width: 80,
        height: 80,
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            begin: Alignment(-0.7, -1),
            end: Alignment(0.7, 1),
            colors: [AppColors.primary, AppColors.primaryHover],
          ),
          borderRadius: AppRadius.borderXl,
          boxShadow: [
            BoxShadow(
              color: AppColors.primary.withValues(alpha: 0.35),
              blurRadius: 32,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: const Icon(
          Icons.notifications_rounded,
          size: 42,
          color: AppColors.textInverse,
        ),
      ),
    );
  }

  Widget _buildHeading() {
    return Column(
      children: [
        Text(
          'Stay Connected',
          style: AppTypography.h1,
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: AppSpacing.xs),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
          child: Text(
            'Enable notifications to know when someone likes you, '
            'sends a message, or wants to connect.',
            style: AppTypography.body.copyWith(color: AppColors.textMuted),
            textAlign: TextAlign.center,
          ),
        ),
      ],
    );
  }

  Widget _buildBenefitsList() {
    return Column(
      children: _benefits.map((benefit) {
        return Padding(
          padding: const EdgeInsets.only(bottom: AppSpacing.sm),
          child: _BenefitCard(benefit: benefit),
        );
      }).toList(),
    );
  }

  Widget _buildEnableButton() {
    return TanderButton(
      label: 'Enable Notifications',
      onPressed: _isEnabling ? null : _enableNotifications,
      isLoading: _isEnabling,
      icon: Icons.notifications_active_rounded,
      iconPosition: IconPosition.trailing,
    );
  }

  Widget _buildSkipButton() {
    return Center(
      child: GestureDetector(
        onTap: _isEnabling ? null : _skipNotifications,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
          child: Text(
            'Maybe Later',
            style: AppTypography.bodySm.copyWith(
              color: AppColors.textMuted,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFooterNote() {
    return Text(
      'You can change notification preferences at any time in Settings.',
      style: AppTypography.caption,
      textAlign: TextAlign.center,
    );
  }
}

// ---------------------------------------------------------------------------
// Benefit card widget
// ---------------------------------------------------------------------------

class _BenefitCard extends StatelessWidget {
  const _BenefitCard({required this.benefit});

  final _NotificationBenefit benefit;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: AppRadius.borderMd,
        border: Border.all(color: AppColors.border),
        boxShadow: AppShadows.warmXs,
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                begin: Alignment(-0.7, -1),
                end: Alignment(0.7, 1),
                colors: [AppColors.primary, AppColors.primaryHover],
              ),
              borderRadius: AppRadius.borderMd,
            ),
            child: Icon(
              benefit.icon,
              size: 22,
              color: AppColors.textInverse,
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Text(
              benefit.label,
              style: AppTypography.body.copyWith(
                fontWeight: FontWeight.w600,
                color: AppColors.textStrong,
              ),
            ),
          ),
          const Icon(
            Icons.check_circle_rounded,
            size: 22,
            color: AppColors.success,
          ),
        ],
      ),
    );
  }
}
