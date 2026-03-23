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
// Notification features — matches web NOTIFICATION_FEATURES
// ---------------------------------------------------------------------------

class _NotificationFeature {
  const _NotificationFeature({
    required this.icon,
    required this.label,
    required this.description,
  });

  final IconData icon;
  final String label;
  final String description;
}

const List<_NotificationFeature> _notificationFeatures = [
  _NotificationFeature(
    icon: Icons.chat_bubble_outline,
    label: 'New messages',
    description: 'Know the moment someone sends you a message',
  ),
  _NotificationFeature(
    icon: Icons.people,
    label: 'Connection requests',
    description: 'Be notified when someone wants to connect with you',
  ),
  _NotificationFeature(
    icon: Icons.favorite,
    label: 'Community activity',
    description: 'Reactions and comments on your posts',
  ),
];

// ---------------------------------------------------------------------------
// Screen
// ---------------------------------------------------------------------------

/// Onboarding step 3 of 3 — requests notification permission.
///
/// Matches the web notification-permission-page.tsx mobile layout:
/// bell icon with ripple, heading, feature list with gradient icon containers,
/// enable/skip buttons, and footer settings note.
///
/// Both "Enable" and "Maybe Later" navigate to [AppRoutes.home] after
/// refreshing the auth session.
class NotificationPermissionScreen extends ConsumerStatefulWidget {
  const NotificationPermissionScreen({super.key});

  @override
  ConsumerState<NotificationPermissionScreen> createState() =>
      _NotificationPermissionScreenState();
}

class _NotificationPermissionScreenState
    extends ConsumerState<NotificationPermissionScreen> {
  bool _isEnabling = false;

  // -- Actions --------------------------------------------------------------

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

  // -- Build ----------------------------------------------------------------

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
                    _buildFeatureList(),
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

  /// Bell icon: 80x80 rounded-3xl gradient, glow shadow — matches web
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
          Icons.notifications_outlined,
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
            'Never miss a message or new connection request',
            style: AppTypography.body.copyWith(color: AppColors.textMuted),
            textAlign: TextAlign.center,
          ),
        ),
      ],
    );
  }

  /// Feature list: cards with gradient icon, label, description — matches web
  Widget _buildFeatureList() {
    return Column(
      children: _notificationFeatures.map((feature) {
        return Padding(
          padding: const EdgeInsets.only(bottom: AppSpacing.sm),
          child: _FeatureCard(feature: feature),
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
// Feature card — matches web's feature list items with gradient icon
// ---------------------------------------------------------------------------

class _FeatureCard extends StatelessWidget {
  const _FeatureCard({required this.feature});

  final _NotificationFeature feature;

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
          // Gradient icon container: w-11 h-11 (44px) rounded-xl
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
              feature.icon,
              size: 22,
              color: AppColors.textInverse,
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  feature.label,
                  style: AppTypography.body.copyWith(
                    fontWeight: FontWeight.w600,
                    color: AppColors.textStrong,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  feature.description,
                  style: AppTypography.caption.copyWith(
                    color: AppColors.textMuted,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
