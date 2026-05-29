import 'package:flutter/material.dart';

import 'package:tander_flutter_v3/core/theme/app_colors.dart';
import 'package:tander_flutter_v3/core/theme/app_radius.dart';
import 'package:tander_flutter_v3/core/theme/app_spacing.dart';
import 'package:tander_flutter_v3/core/theme/app_typography.dart';
import 'package:tander_flutter_v3/shared/widgets/tander_button.dart';

/// Modal confirmation dialog with primary or danger action.
///
/// Returns `true` when the user taps confirm, `false` on cancel,
/// and `null` if dismissed via backdrop tap or system back.
///
/// Use the static [show] helper for convenience:
/// ```dart
/// final didConfirm = await TanderConfirmDialog.show(
///   context: context,
///   title: 'Delete account?',
///   message: 'This cannot be undone.',
///   confirmLabel: 'Delete',
///   isDanger: true,
/// );
/// ```
class TanderConfirmDialog extends StatelessWidget {
  const TanderConfirmDialog({
    required this.title,
    required this.message,
    required this.confirmLabel,
    this.cancelLabel = 'Cancel',
    this.isDanger = false,
    this.onConfirm,
    this.onCancel,
    super.key,
  });

  /// Bold heading displayed at the top of the dialog.
  final String title;

  /// Descriptive body text explaining the action.
  final String message;

  /// Label for the primary action button.
  final String confirmLabel;

  /// Label for the cancel button (defaults to "Cancel").
  final String cancelLabel;

  /// When `true`, the confirm button uses the danger variant.
  final bool isDanger;

  /// Called when the user presses confirm. If null, the dialog
  /// pops with `true`.
  final VoidCallback? onConfirm;

  /// Called when the user presses cancel. If null, the dialog
  /// pops with `false`.
  final VoidCallback? onCancel;

  /// Present the dialog modally and return the user's choice.
  static Future<bool?> show({
    required BuildContext context,
    required String title,
    required String message,
    required String confirmLabel,
    String cancelLabel = 'Cancel',
    bool isDanger = false,
  }) {
    return showDialog<bool>(
      context: context,
      barrierColor: AppColors.overlay,
      builder: (dialogContext) => TanderConfirmDialog(
        title: title,
        message: message,
        confirmLabel: confirmLabel,
        cancelLabel: cancelLabel,
        isDanger: isDanger,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: AppColors.card,
      shape: RoundedRectangleBorder(borderRadius: AppRadius.borderXl),
      insetPadding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(title, style: AppTypography.h3),
            const SizedBox(height: AppSpacing.xs),
            Text(
              message,
              style: AppTypography.body.copyWith(color: AppColors.textMuted),
            ),
            const SizedBox(height: AppSpacing.lg),
            _ActionButtons(
              confirmLabel: confirmLabel,
              cancelLabel: cancelLabel,
              isDanger: isDanger,
              onConfirm: onConfirm,
              onCancel: onCancel,
            ),
          ],
        ),
      ),
    );
  }
}

/// Row of cancel + confirm buttons at the bottom of the dialog.
class _ActionButtons extends StatelessWidget {
  const _ActionButtons({
    required this.confirmLabel,
    required this.cancelLabel,
    required this.isDanger,
    this.onConfirm,
    this.onCancel,
  });

  final String confirmLabel;
  final String cancelLabel;
  final bool isDanger;
  final VoidCallback? onConfirm;
  final VoidCallback? onCancel;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: TanderButton(
            label: cancelLabel,
            variant: TanderButtonVariant.ghost,
            size: TanderButtonSize.compact,
            onPressed: onCancel ?? () => Navigator.of(context).pop(false),
          ),
        ),
        const SizedBox(width: AppSpacing.sm),
        Expanded(
          child: TanderButton(
            label: confirmLabel,
            variant: isDanger
                ? TanderButtonVariant.danger
                : TanderButtonVariant.primary,
            size: TanderButtonSize.compact,
            onPressed: onConfirm ?? () => Navigator.of(context).pop(true),
          ),
        ),
      ],
    );
  }
}
