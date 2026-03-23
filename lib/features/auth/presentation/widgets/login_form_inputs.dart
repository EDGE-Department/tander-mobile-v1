import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import 'package:tander_flutter_v3/core/theme/app_colors.dart';
import 'package:tander_flutter_v3/core/theme/app_curves.dart';
import 'package:tander_flutter_v3/core/theme/app_spacing.dart';
import 'package:tander_flutter_v3/core/theme/app_typography.dart';

// ── Constants ────────────────────────────────────────────────────────

/// Field background matching web's `#F9F5F0`.
const Color _fieldBackground = Color(0xFFF9F5F0);

/// Field border color matching web's `rgba(230,126,34,0.20)`.
const Color _fieldBorderColor = Color(0x33E67E22);

/// Field border color on focus matching web's primary.
const Color _fieldFocusBorderColor = AppColors.primary;

// ── Styled login text field ─────────────────────────────────────────

/// Warm-styled text field matching the web login form inputs.
///
/// Features: rounded-16 border, `#F9F5F0` fill, duotone prefix icon
/// tinted primary at 65%, 2px orange border, 56px min height.
class LoginTextField extends StatelessWidget {
  const LoginTextField({
    required this.label,
    required this.hint,
    required this.controller,
    required this.focusNode,
    required this.prefixIcon,
    this.keyboardType,
    this.textInputAction,
    this.validator,
    super.key,
  });

  final String label;
  final String hint;
  final TextEditingController controller;
  final FocusNode focusNode;
  final IconData prefixIcon;
  final TextInputType? keyboardType;
  final TextInputAction? textInputAction;
  final FormFieldValidator<String>? validator;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          label,
          style: AppTypography.bodySm.copyWith(
            fontWeight: FontWeight.w600,
            color: AppColors.textBody,
            fontSize: 15,
          ),
        ),
        const SizedBox(height: 6),
        TextFormField(
          controller: controller,
          focusNode: focusNode,
          keyboardType: keyboardType,
          textInputAction: textInputAction,
          autocorrect: false,
          enableSuggestions: false,
          validator: validator,
          style: AppTypography.body.copyWith(color: AppColors.textStrong),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: AppTypography.body.copyWith(color: AppColors.textMuted),
            filled: true,
            fillColor: _fieldBackground,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.md,
              vertical: AppSpacing.md,
            ),
            constraints: const BoxConstraints(minHeight: 56),
            prefixIcon: Padding(
              padding: const EdgeInsets.only(left: 16, right: 8),
              child: Icon(
                prefixIcon,
                size: 18,
                color: AppColors.primary.withValues(alpha: 0.65),
              ),
            ),
            prefixIconConstraints: const BoxConstraints(minWidth: 42),
            border: _buildBorder(_fieldBorderColor),
            enabledBorder: _buildBorder(_fieldBorderColor),
            focusedBorder: _buildBorder(_fieldFocusBorderColor, width: 2),
            errorBorder: _buildBorder(AppColors.danger),
            focusedErrorBorder: _buildBorder(AppColors.danger, width: 2),
            errorStyle: AppTypography.caption.copyWith(
              color: AppColors.danger,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ],
    );
  }
}

// ── Password field ──────────────────────────────────────────────────

/// Password input with visibility toggle and "Forgot password?" link.
///
/// Matches the web's password row: label + link on same line, duotone
/// lock prefix, eye/eye-slash suffix toggle, same warm field styling.
class LoginPasswordField extends StatelessWidget {
  const LoginPasswordField({
    required this.controller,
    required this.focusNode,
    required this.isPasswordVisible,
    required this.onToggleVisibility,
    required this.onForgotPassword,
    this.textInputAction,
    super.key,
  });

  final TextEditingController controller;
  final FocusNode focusNode;
  final bool isPasswordVisible;
  final VoidCallback onToggleVisibility;
  final VoidCallback onForgotPassword;
  final TextInputAction? textInputAction;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        // Label row with "Forgot password?" link
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Password',
              style: AppTypography.bodySm.copyWith(
                fontWeight: FontWeight.w600,
                color: AppColors.textBody,
                fontSize: 15,
              ),
            ),
            GestureDetector(
              onTap: onForgotPassword,
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 2),
                child: Text(
                  'Forgot password?',
                  style: AppTypography.bodySm.copyWith(
                    fontWeight: FontWeight.w600,
                    color: AppColors.primaryAccessible,
                  ),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        TextFormField(
          controller: controller,
          focusNode: focusNode,
          obscureText: !isPasswordVisible,
          textInputAction: textInputAction,
          validator: _validatePassword,
          style: AppTypography.body.copyWith(color: AppColors.textStrong),
          decoration: InputDecoration(
            hintText: 'Enter your password',
            hintStyle: AppTypography.body.copyWith(color: AppColors.textMuted),
            filled: true,
            fillColor: _fieldBackground,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.md,
              vertical: AppSpacing.md,
            ),
            constraints: const BoxConstraints(minHeight: 56),
            prefixIcon: Padding(
              padding: const EdgeInsets.only(left: 16, right: 8),
              child: Icon(
                PhosphorIconsDuotone.lockSimple,
                size: 18,
                color: AppColors.primary.withValues(alpha: 0.65),
              ),
            ),
            prefixIconConstraints: const BoxConstraints(minWidth: 42),
            suffixIcon: GestureDetector(
              onTap: onToggleVisibility,
              child: Padding(
                padding: const EdgeInsets.only(right: 12),
                child: Icon(
                  isPasswordVisible
                      ? PhosphorIconsRegular.eyeSlash
                      : PhosphorIconsRegular.eye,
                  size: 20,
                  color: AppColors.primary.withValues(alpha: 0.65),
                ),
              ),
            ),
            suffixIconConstraints: const BoxConstraints(
              minWidth: AppSpacing.touchMinimum,
              minHeight: AppSpacing.touchMinimum,
            ),
            border: _buildBorder(_fieldBorderColor),
            enabledBorder: _buildBorder(_fieldBorderColor),
            focusedBorder: _buildBorder(_fieldFocusBorderColor, width: 2),
            errorBorder: _buildBorder(AppColors.danger),
            focusedErrorBorder: _buildBorder(AppColors.danger, width: 2),
            errorStyle: AppTypography.caption.copyWith(
              color: AppColors.danger,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ],
    );
  }

  String? _validatePassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'Please enter your password';
    }
    return null;
  }
}

// ── Remember me checkbox ────────────────────────────────────────────

/// Animated checkbox with spring checkmark matching the web's
/// remember-me toggle. Orange fill when checked, bordered when not.
class LoginRememberMeCheckbox extends StatelessWidget {
  const LoginRememberMeCheckbox({
    required this.isChecked,
    required this.onToggle,
    super.key,
  });

  final bool isChecked;
  final VoidCallback onToggle;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onToggle,
      behavior: HitTestBehavior.opaque,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4),
        child: Row(
          children: [
            AnimatedContainer(
              duration: AppDurations.fast,
              width: 20,
              height: 20,
              decoration: BoxDecoration(
                color: isChecked ? AppColors.primary : Colors.transparent,
                borderRadius: BorderRadius.circular(5),
                border: Border.all(
                  color: isChecked
                      ? AppColors.primary
                      : const Color(0x4DE67E22), // rgba(230,126,34,0.30)
                  width: 2,
                ),
              ),
              child: isChecked
                  ? const Center(
                      child: Icon(Icons.check, size: 14, color: Colors.white),
                    )
                  : null,
            ),
            const SizedBox(width: 12),
            Text(
              'Remember me on this device',
              style: AppTypography.body.copyWith(
                fontSize: 15,
                color: AppColors.textBody,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Shared border builder ───────────────────────────────────────────

OutlineInputBorder _buildBorder(Color color, {double width = 2}) {
  return OutlineInputBorder(
    borderRadius: BorderRadius.circular(16),
    borderSide: BorderSide(color: color, width: width),
  );
}
