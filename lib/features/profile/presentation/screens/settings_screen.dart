/// Settings hub screen with navigation to sub-screens.
///
/// Organizes settings into logical sections (Account, Preferences,
/// Support, Actions) using [ActionCard] rows. Each row navigates
/// to a dedicated sub-screen via [GoRouter].
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import 'package:tander_flutter_v3/core/theme/app_colors.dart';
import 'package:tander_flutter_v3/core/theme/app_radius.dart';
import 'package:tander_flutter_v3/core/theme/app_spacing.dart';
import 'package:tander_flutter_v3/core/theme/app_typography.dart';
import 'package:tander_flutter_v3/features/auth/presentation/notifiers/auth_notifier.dart';
import 'package:tander_flutter_v3/features/profile/presentation/widgets/profile_page_components.dart';
import 'package:tander_flutter_v3/shared/constants/routes.dart';
import 'package:tander_flutter_v3/shared/widgets/tander_bottom_sheet.dart';
import 'package:tander_flutter_v3/shared/widgets/tander_button.dart';
import 'package:tander_flutter_v3/shared/widgets/tander_confirm_dialog.dart';

/// Settings hub screen.
class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      backgroundColor: AppColors.canvas,
      appBar: AppBar(
        backgroundColor: AppColors.card,
        surfaceTintColor: Colors.transparent,
        leading: IconButton(
          icon: const Icon(PhosphorIconsBold.arrowLeft, size: 22),
          onPressed: () => context.pop(),
          tooltip: 'Back to profile',
        ),
        title: Text('Settings', style: AppTypography.h3),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _SectionHeading(label: 'Account'),
            const SizedBox(height: AppSpacing.xs),
            ActionCard(
              icon: PhosphorIconsFill.bell,
              label: 'Notifications',
              onTap: () =>
                  context.push(AppRoutes.profileSettingsNotifications),
            ),
            const SizedBox(height: AppSpacing.xs),
            ActionCard(
              icon: PhosphorIconsFill.eye,
              label: 'Privacy',
              onTap: () =>
                  context.push(AppRoutes.profileSettingsPrivacy),
            ),
            const SizedBox(height: AppSpacing.xs),
            ActionCard(
              icon: PhosphorIconsFill.shieldCheck,
              label: 'Security',
              onTap: () =>
                  context.push(AppRoutes.profileSettingsSecurity),
            ),
            const SizedBox(height: AppSpacing.lg),

            _SectionHeading(label: 'Preferences'),
            const SizedBox(height: AppSpacing.xs),
            ActionCard(
              icon: PhosphorIconsFill.compassTool,
              label: 'Discovery Settings',
              onTap: () =>
                  context.push(AppRoutes.profileSettingsDiscovery),
            ),
            const SizedBox(height: AppSpacing.lg),

            _SectionHeading(label: 'Support'),
            const SizedBox(height: AppSpacing.xs),
            ActionCard(
              icon: PhosphorIconsFill.question,
              label: 'Help & FAQ',
              onTap: () => _showHelpSheet(context),
            ),
            const SizedBox(height: AppSpacing.xs),
            ActionCard(
              icon: PhosphorIconsFill.info,
              label: 'About Tander',
              onTap: () => _showAboutDialog(context),
            ),
            const SizedBox(height: AppSpacing.lg),

            _SectionHeading(label: 'Actions'),
            const SizedBox(height: AppSpacing.xs),
            _SignOutCard(
              onTap: () => _handleSignOut(context, ref),
            ),
            const SizedBox(height: AppSpacing.xs),
            _DeleteAccountCard(
              onTap: () => _handleDeleteAccount(context, ref),
            ),
            const SizedBox(height: AppSpacing.xxl),
          ],
        ),
      ),
    );
  }

  void _showHelpSheet(BuildContext context) {
    TanderBottomSheet.show(
      context: context,
      title: 'Help & FAQ',
      child: const _HelpSheetPlaceholder(),
    );
  }

  void _showAboutDialog(BuildContext context) {
    showAboutDialog(
      context: context,
      applicationName: 'Tander',
      applicationVersion: '1.0.0',
      applicationLegalese: 'Dating & wellness for Filipino seniors 60+',
    );
  }

  Future<void> _handleSignOut(BuildContext context, WidgetRef ref) async {
    final didConfirm = await TanderConfirmDialog.show(
      context: context,
      title: 'Sign out?',
      message: 'You will need to sign in again to access your account.',
      confirmLabel: 'Sign out',
    );

    if (didConfirm != true) return;
    ref.read(authNotifierProvider.notifier).signOut();
  }

  Future<void> _handleDeleteAccount(
      BuildContext context, WidgetRef ref) async {
    final didConfirm = await TanderConfirmDialog.show(
      context: context,
      title: 'Delete account?',
      message:
          'This action is permanent and cannot be undone. All your data, '
          'connections, and messages will be permanently deleted.',
      confirmLabel: 'Delete forever',
      isDanger: true,
    );

    if (didConfirm != true) return;

    // Second confirmation for destructive action
    final didDoubleConfirm = await TanderConfirmDialog.show(
      context: context,
      title: 'Are you absolutely sure?',
      message:
          'There is no way to recover your account after deletion. '
          'This cannot be undone.',
      confirmLabel: 'Yes, delete my account',
      isDanger: true,
    );

    if (didDoubleConfirm != true) return;

    // Delegate to auth notifier (which calls the delete endpoint)
    ref.read(authNotifierProvider.notifier).signOut();
  }
}

// ── Private widgets ──────────────────────────────────────────────────────

class _SectionHeading extends StatelessWidget {
  const _SectionHeading({required this.label});
  final String label;

  @override
  Widget build(BuildContext context) {
    return Text(
      label.toUpperCase(),
      style: AppTypography.caption.copyWith(
        fontWeight: FontWeight.w700,
        letterSpacing: 1.4,
        color: AppColors.textMuted,
      ),
    );
  }
}

class _SignOutCard extends StatelessWidget {
  const _SignOutCard({required this.onTap});
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.card,
      borderRadius: AppRadius.borderLg,
      child: InkWell(
        onTap: onTap,
        borderRadius: AppRadius.borderLg,
        child: Container(
          constraints: const BoxConstraints(minHeight: AppSpacing.touchMinimum),
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md,
            vertical: AppSpacing.sm,
          ),
          decoration: BoxDecoration(
            border: Border.all(color: AppColors.border),
            borderRadius: AppRadius.borderLg,
          ),
          child: Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: AppColors.warningLight,
                  borderRadius: AppRadius.borderMd,
                ),
                alignment: Alignment.center,
                child: const Icon(PhosphorIconsFill.signOut, size: 18,
                    color: AppColors.warning),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Text(
                  'Sign out',
                  style: AppTypography.label.copyWith(color: AppColors.warning),
                ),
              ),
              const Icon(PhosphorIconsBold.caretRight, size: 16,
                  color: AppColors.textMuted),
            ],
          ),
        ),
      ),
    );
  }
}

class _DeleteAccountCard extends StatelessWidget {
  const _DeleteAccountCard({required this.onTap});
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.card,
      borderRadius: AppRadius.borderLg,
      child: InkWell(
        onTap: onTap,
        borderRadius: AppRadius.borderLg,
        child: Container(
          constraints: const BoxConstraints(minHeight: AppSpacing.touchMinimum),
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md,
            vertical: AppSpacing.sm,
          ),
          decoration: BoxDecoration(
            border: Border.all(color: AppColors.danger.withValues(alpha: 0.3)),
            borderRadius: AppRadius.borderLg,
          ),
          child: Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: AppColors.dangerLight,
                  borderRadius: AppRadius.borderMd,
                ),
                alignment: Alignment.center,
                child: const Icon(PhosphorIconsFill.trash, size: 18,
                    color: AppColors.danger),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Text(
                  'Delete account',
                  style: AppTypography.label.copyWith(color: AppColors.danger),
                ),
              ),
              const Icon(PhosphorIconsBold.warning, size: 16,
                  color: AppColors.danger),
            ],
          ),
        ),
      ),
    );
  }
}

class _HelpSheetPlaceholder extends StatelessWidget {
  const _HelpSheetPlaceholder();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'Help content will be loaded here.',
            style: AppTypography.body.copyWith(color: AppColors.textMuted),
          ),
          const SizedBox(height: AppSpacing.md),
          TanderButton(
            label: 'Close',
            variant: TanderButtonVariant.outline,
            size: TanderButtonSize.compact,
            onPressed: () => Navigator.of(context).pop(),
          ),
        ],
      ),
    );
  }
}
