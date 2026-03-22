/// Security settings screen with password change, 2FA, and account actions.
///
/// Section widgets live in `security_form_sections.dart` to stay under
/// the 400-line budget.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import 'package:tander_flutter_v3/core/theme/app_colors.dart';
import 'package:tander_flutter_v3/core/theme/app_spacing.dart';
import 'package:tander_flutter_v3/core/theme/app_typography.dart';
import 'package:tander_flutter_v3/features/profile/presentation/widgets/security_form_sections.dart';
import 'package:tander_flutter_v3/shared/widgets/section_label.dart';
import 'package:tander_flutter_v3/shared/widgets/tander_confirm_dialog.dart';
import 'package:tander_flutter_v3/shared/widgets/tander_toast.dart';

/// Security settings screen.
class SettingsSecurityScreen extends ConsumerStatefulWidget {
  const SettingsSecurityScreen({super.key});

  @override
  ConsumerState<SettingsSecurityScreen> createState() =>
      _SettingsSecurityScreenState();
}

class _SettingsSecurityScreenState
    extends ConsumerState<SettingsSecurityScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _currentPasswordController;
  late final TextEditingController _newPasswordController;
  late final TextEditingController _confirmPasswordController;

  bool _isTwoFactorEnabled = false;
  bool _isChangingPassword = false;
  bool _showPasswordForm = false;

  @override
  void initState() {
    super.initState();
    _currentPasswordController = TextEditingController();
    _newPasswordController = TextEditingController();
    _confirmPasswordController = TextEditingController();
  }

  @override
  void dispose() {
    _currentPasswordController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  void _toggleTwoFactor() {
    setState(() => _isTwoFactorEnabled = !_isTwoFactorEnabled);
    TanderToastOverlay.show(
      context,
      TanderToastData(
        message: _isTwoFactorEnabled
            ? 'Two-factor authentication enabled.'
            : 'Two-factor authentication disabled.',
        variant: TanderToastVariant.success,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  Future<void> _handleChangePassword() async {
    if (!_formKey.currentState!.validate()) return;
    if (_isChangingPassword) return;

    setState(() => _isChangingPassword = true);
    await Future<void>.delayed(const Duration(seconds: 1));
    if (!mounted) return;

    setState(() {
      _isChangingPassword = false;
      _showPasswordForm = false;
    });
    _currentPasswordController.clear();
    _newPasswordController.clear();
    _confirmPasswordController.clear();

    TanderToastOverlay.show(
      context,
      const TanderToastData(
        message: 'Password changed successfully.',
        variant: TanderToastVariant.success,
      ),
    );
  }

  Future<void> _handleExportData() async {
    TanderToastOverlay.show(
      context,
      const TanderToastData(
        message: 'Your data export will be emailed to you shortly.',
        variant: TanderToastVariant.info,
      ),
    );
  }

  Future<void> _handleDeleteAccount() async {
    final didConfirm = await TanderConfirmDialog.show(
      context: context,
      title: 'Delete account?',
      message: 'This action is permanent. All your data will be deleted.',
      confirmLabel: 'Delete forever',
      isDanger: true,
    );
    if (didConfirm != true) return;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.canvas,
      appBar: AppBar(
        backgroundColor: AppColors.card,
        surfaceTintColor: Colors.transparent,
        leading: IconButton(
          icon: const Icon(PhosphorIconsBold.arrowLeft, size: 22),
          onPressed: () => context.pop(),
          tooltip: 'Back to settings',
        ),
        title: Text('Security', style: AppTypography.h3),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SectionLabel(label: 'Password'),
            const SizedBox(height: AppSpacing.sm),
            PasswordSection(
              showForm: _showPasswordForm,
              onToggleForm: () =>
                  setState(() => _showPasswordForm = !_showPasswordForm),
              formKey: _formKey,
              currentPasswordController: _currentPasswordController,
              newPasswordController: _newPasswordController,
              confirmPasswordController: _confirmPasswordController,
              isChangingPassword: _isChangingPassword,
              onSubmit: _handleChangePassword,
            ),
            const SizedBox(height: AppSpacing.lg),
            const SectionLabel(label: 'Two-factor authentication'),
            const SizedBox(height: AppSpacing.sm),
            TwoFactorSection(
              isEnabled: _isTwoFactorEnabled,
              onToggle: _toggleTwoFactor,
            ),
            const SizedBox(height: AppSpacing.lg),
            const SectionLabel(label: 'Data'),
            const SizedBox(height: AppSpacing.sm),
            DataActionCard(
              icon: PhosphorIconsFill.export,
              label: 'Export my data',
              description: 'Download a copy of your personal data',
              onTap: _handleExportData,
            ),
            const SizedBox(height: AppSpacing.lg),
            const SectionLabel(label: 'Danger zone'),
            const SizedBox(height: AppSpacing.sm),
            DangerDeleteCard(onTap: _handleDeleteAccount),
            const SizedBox(height: AppSpacing.xxs),
            Text(
              'Account deletion is permanent and cannot be undone.',
              style: AppTypography.caption.copyWith(color: AppColors.textMuted),
            ),
            const SizedBox(height: AppSpacing.xxl),
          ],
        ),
      ),
    );
  }
}
