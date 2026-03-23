/// Extracted form sections for the security settings screen.
///
/// Contains [PasswordSection], [TwoFactorSection], [DataActionCard],
/// and [DangerDeleteCard] to keep the parent screen under 400 lines.
library;

import 'package:flutter/material.dart';

import 'package:tander_flutter_v3/core/theme/app_colors.dart';
import 'package:tander_flutter_v3/core/theme/app_radius.dart';
import 'package:tander_flutter_v3/core/theme/app_spacing.dart';
import 'package:tander_flutter_v3/core/theme/app_typography.dart';
import 'package:tander_flutter_v3/shared/widgets/tander_button.dart';
import 'package:tander_flutter_v3/shared/widgets/tander_text_field.dart';
import 'package:tander_flutter_v3/shared/widgets/warm_switch.dart';

// ── Password section ────────────────────────────────────────────────────

/// Expandable password change section with old/new/confirm fields.
class PasswordSection extends StatelessWidget {
  const PasswordSection({
    required this.showForm,
    required this.onToggleForm,
    required this.formKey,
    required this.currentPasswordController,
    required this.newPasswordController,
    required this.confirmPasswordController,
    required this.isChangingPassword,
    required this.onSubmit,
    super.key,
  });

  final bool showForm;
  final VoidCallback onToggleForm;
  final GlobalKey<FormState> formKey;
  final TextEditingController currentPasswordController;
  final TextEditingController newPasswordController;
  final TextEditingController confirmPasswordController;
  final bool isChangingPassword;
  final VoidCallback onSubmit;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: AppRadius.borderLg,
        border: Border.all(color: AppColors.border),
      ),
      child: Column(children: [
        _PasswordHeader(showForm: showForm, onToggle: onToggleForm),
        if (showForm) ...[
          const Divider(height: 1, color: AppColors.border),
          Padding(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Form(
              key: formKey,
              child: Column(children: [
                TanderTextField(
                  label: 'Current password',
                  controller: currentPasswordController,
                  obscureText: true,
                  validator: _requiredValidator,
                ),
                const SizedBox(height: AppSpacing.sm),
                TanderTextField(
                  label: 'New password',
                  controller: newPasswordController,
                  obscureText: true,
                  validator: _passwordValidator,
                ),
                const SizedBox(height: AppSpacing.sm),
                TanderTextField(
                  label: 'Confirm new password',
                  controller: confirmPasswordController,
                  obscureText: true,
                  validator: (value) =>
                      _confirmValidator(value, newPasswordController.text),
                ),
                const SizedBox(height: AppSpacing.md),
                SizedBox(
                  width: double.infinity,
                  child: TanderButton(
                    label: 'Change password',
                    isLoading: isChangingPassword,
                    onPressed: onSubmit,
                  ),
                ),
              ]),
            ),
          ),
        ],
      ]),
    );
  }

  static String? _requiredValidator(String? value) {
    if (value == null || value.trim().isEmpty) return 'Required';
    return null;
  }

  static String? _passwordValidator(String? value) {
    if (value == null || value.trim().isEmpty) return 'Required';
    if (value.length < 8) return 'Must be at least 8 characters';
    return null;
  }

  static String? _confirmValidator(String? value, String newPassword) {
    if (value == null || value.trim().isEmpty) return 'Required';
    if (value != newPassword) return 'Passwords do not match';
    return null;
  }
}

class _PasswordHeader extends StatelessWidget {
  const _PasswordHeader({required this.showForm, required this.onToggle});
  final bool showForm;
  final VoidCallback onToggle;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onToggle,
      behavior: HitTestBehavior.opaque,
      child: Container(
        constraints: const BoxConstraints(minHeight: AppSpacing.touchComfortable),
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.sm),
        child: Row(children: [
          Container(
            width: 40, height: 40,
            decoration: BoxDecoration(color: AppColors.secondary, borderRadius: AppRadius.borderMd),
            alignment: Alignment.center,
            child: const Icon(Icons.key, size: 20, color: AppColors.textInverse),
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('Change password', style: AppTypography.label),
            Text('Update your account password', style: AppTypography.bodySm.copyWith(color: AppColors.textMuted)),
          ])),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm, vertical: AppSpacing.xxs),
            decoration: BoxDecoration(color: AppColors.subtle, borderRadius: AppRadius.borderFull),
            child: Text(showForm ? 'Cancel' : 'Update', style: AppTypography.caption.copyWith(fontWeight: FontWeight.w600)),
          ),
        ]),
      ),
    );
  }
}

// ── Two-factor section ──────────────────────────────────────────────────

/// Two-factor authentication toggle with optional setup instructions.
class TwoFactorSection extends StatelessWidget {
  const TwoFactorSection({
    required this.isEnabled,
    required this.onToggle,
    super.key,
  });

  final bool isEnabled;
  final VoidCallback onToggle;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: AppRadius.borderLg,
        border: Border.all(color: AppColors.border),
      ),
      child: Column(children: [
        GestureDetector(
          onTap: onToggle,
          behavior: HitTestBehavior.opaque,
          child: Container(
            constraints: const BoxConstraints(minHeight: AppSpacing.touchComfortable),
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.sm),
            child: Row(children: [
              Container(
                width: 40, height: 40,
                decoration: BoxDecoration(color: AppColors.secondary, borderRadius: AppRadius.borderMd),
                alignment: Alignment.center,
                child: const Icon(Icons.phone_android, size: 20, color: AppColors.textInverse),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('Authenticator app', style: AppTypography.label),
                Text('Add an extra layer of security', style: AppTypography.bodySm.copyWith(color: AppColors.textMuted)),
              ])),
              WarmSwitch(isEnabled: isEnabled, onToggle: onToggle),
            ]),
          ),
        ),
        if (isEnabled) ...[
          const Divider(height: 1, color: AppColors.border),
          Padding(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(
                'Use an authenticator app like Google Authenticator or Authy to generate one-time codes.',
                style: AppTypography.bodySm.copyWith(color: AppColors.textMuted),
              ),
              const SizedBox(height: AppSpacing.sm),
              Text('Set up authenticator', style: AppTypography.label.copyWith(color: AppColors.primary)),
            ]),
          ),
        ],
      ]),
    );
  }
}

// ── Data action card ────────────────────────────────────────────────────

/// Card for data export or similar non-destructive account actions.
class DataActionCard extends StatelessWidget {
  const DataActionCard({
    required this.icon,
    required this.label,
    required this.description,
    required this.onTap,
    super.key,
  });

  final IconData icon;
  final String label;
  final String description;
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
          constraints: const BoxConstraints(minHeight: AppSpacing.touchComfortable),
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.sm),
          decoration: BoxDecoration(border: Border.all(color: AppColors.border), borderRadius: AppRadius.borderLg),
          child: Row(children: [
            Container(
              width: 40, height: 40,
              decoration: BoxDecoration(color: AppColors.infoLight, borderRadius: AppRadius.borderMd),
              alignment: Alignment.center,
              child: Icon(icon, size: 20, color: AppColors.info),
            ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(label, style: AppTypography.label),
              Text(description, style: AppTypography.bodySm.copyWith(color: AppColors.textMuted)),
            ])),
            const Icon(Icons.chevron_right, size: 16, color: AppColors.textMuted),
          ]),
        ),
      ),
    );
  }
}

// ── Danger card ─────────────────────────────────────────────────────────

/// Red-bordered card for destructive account actions (delete).
class DangerDeleteCard extends StatelessWidget {
  const DangerDeleteCard({required this.onTap, super.key});
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
          constraints: const BoxConstraints(minHeight: AppSpacing.touchComfortable),
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.sm),
          decoration: BoxDecoration(
            border: Border.all(color: AppColors.danger.withValues(alpha: 0.3)),
            borderRadius: AppRadius.borderLg,
          ),
          child: Row(children: [
            Container(
              width: 40, height: 40,
              decoration: BoxDecoration(color: AppColors.danger, borderRadius: AppRadius.borderMd),
              alignment: Alignment.center,
              child: const Icon(Icons.delete_outline, size: 20, color: AppColors.textInverse),
            ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('Delete account', style: AppTypography.label.copyWith(color: AppColors.danger)),
              Text('Permanently remove your account and data', style: AppTypography.bodySm.copyWith(color: AppColors.textMuted)),
            ])),
            const Icon(Icons.warning_amber, size: 18, color: AppColors.danger),
          ]),
        ),
      ),
    );
  }
}
