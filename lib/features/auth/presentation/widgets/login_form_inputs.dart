import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import 'package:tander_flutter_v3/core/theme/app_colors.dart';
import 'package:tander_flutter_v3/core/theme/app_curves.dart';
import 'package:tander_flutter_v3/core/theme/app_spacing.dart';
import 'package:tander_flutter_v3/core/theme/app_typography.dart';

// ── Constants ────────────────────────────────────────────────────────

/// Web: bg-gray-50/30 = rgba(249,250,251,0.30).
const Color _fieldBackground = Color(0x4DF9FAFB);

/// Web: border-gray-100 (#F3F4F6) with border-2.
const Color _fieldBorderColor = Color(0xFFF3F4F6);

/// Web: focus:border-[#E67E22].
const Color _fieldFocusBorderColor = AppColors.primary;

/// Web: rounded-2xl = 16px.
const double _fieldRadius = 16;

// ── Styled login text field ─────────────────────────────────────────

/// Warm-styled text field matching the web login form inputs.
///
/// Features: pill border, `#F7F2EC` fill, Phosphor duotone prefix icon
/// tinted primary at 50%, 1px orange border, 48px min height.
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
        Padding(
          padding: const EdgeInsets.only(left: 4),
          child: Text(
            label,
            style: AppTypography.bodySm.copyWith(
              fontWeight: FontWeight.w700,
              color: AppColors.textBody,
              fontSize: 15,
            ),
          ),
        ),
        const SizedBox(height: 12),
        AnimatedSize(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOut,
          alignment: Alignment.topCenter,
          child: TextFormField(
            controller: controller,
            focusNode: focusNode,
            keyboardType: keyboardType,
            textInputAction: textInputAction,
            autocorrect: false,
            enableSuggestions: false,
            autofillHints: const [AutofillHints.username, AutofillHints.email],
            validator: validator,
            style: AppTypography.body.copyWith(color: AppColors.textStrong),
            decoration: InputDecoration(
              hintText: hint,
              hintStyle: AppTypography.body.copyWith(
                color: AppColors.textDisabled,
              ),
              filled: true,
              fillColor: _fieldBackground,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 24,
                vertical: 16,
              ),
              // Web: h-14 = 56px
              constraints: const BoxConstraints(minHeight: 56),
              prefixIcon: Padding(
                padding: const EdgeInsets.only(left: 24, right: 12),
                child: Icon(
                  prefixIcon,
                  size: 24,
                  color: AppColors.textDisabled,
                ),
              ),
              prefixIconConstraints: const BoxConstraints(minWidth: 60),
              // Web: border-2 with rounded-2xl
              border: _buildBorder(_fieldBorderColor, width: 2),
              enabledBorder: _buildBorder(_fieldBorderColor, width: 2),
              focusedBorder: _buildBorder(_fieldFocusBorderColor, width: 2),
              errorBorder: _buildBorder(AppColors.danger, width: 2),
              focusedErrorBorder: _buildBorder(AppColors.danger, width: 2),
              errorStyle: AppTypography.caption.copyWith(
                color: AppColors.danger,
                fontWeight: FontWeight.w700,
              ),
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
        // Web: flex items-center justify-between mx-1
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Password',
                style: AppTypography.bodySm.copyWith(
                  fontWeight: FontWeight.w700,
                  color: AppColors.textBody,
                  fontSize: 15,
                ),
              ),
              GestureDetector(
                onTap: onForgotPassword,
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    vertical: 4,
                    horizontal: 8,
                  ),
                  child: Text(
                    'Forgot?',
                    style: AppTypography.bodySm.copyWith(
                      fontWeight: FontWeight.w900,
                      color: AppColors.primary,
                      fontSize: 14,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        AnimatedSize(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOut,
          alignment: Alignment.topCenter,
          child: TextFormField(
            controller: controller,
            focusNode: focusNode,
            obscureText: !isPasswordVisible,
            textInputAction: textInputAction,
            autofillHints: const [AutofillHints.password],
            validator: _validatePassword,
            style: AppTypography.body.copyWith(color: AppColors.textStrong),
            decoration: InputDecoration(
              // Web: placeholder="••••••••"
              hintText: '••••••••',
              hintStyle: AppTypography.body.copyWith(
                color: AppColors.textDisabled,
              ),
              filled: true,
              fillColor: _fieldBackground,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 24,
                vertical: 16,
              ),
              constraints: const BoxConstraints(minHeight: 56),
              prefixIcon: Padding(
                padding: const EdgeInsets.only(left: 24, right: 12),
                child: Icon(
                  PhosphorIconsDuotone.lockSimple,
                  size: 24,
                  color: AppColors.textDisabled,
                ),
              ),
              prefixIconConstraints: const BoxConstraints(minWidth: 60),
              suffixIcon: GestureDetector(
                onTap: onToggleVisibility,
                child: Padding(
                  padding: const EdgeInsets.only(right: 24),
                  child: Icon(
                    isPasswordVisible
                        ? PhosphorIconsRegular.eyeSlash
                        : PhosphorIconsRegular.eye,
                    size: 24,
                    color: AppColors.textDisabled,
                  ),
                ),
              ),
              suffixIconConstraints: const BoxConstraints(
                minWidth: AppSpacing.touchMinimum,
                minHeight: AppSpacing.touchMinimum,
              ),
              border: _buildBorder(_fieldBorderColor),
              enabledBorder: _buildBorder(_fieldBorderColor),
              focusedBorder: _buildBorder(_fieldFocusBorderColor),
              errorBorder: _buildBorder(AppColors.danger),
              focusedErrorBorder: _buildBorder(AppColors.danger),
              errorStyle: AppTypography.caption.copyWith(
                color: AppColors.danger,
                fontWeight: FontWeight.w700,
              ),
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
        // web: px-0.5
        padding: const EdgeInsets.symmetric(horizontal: 2),
        child: Row(
          children: [
            // web: w-[18px] h-[18px] rounded-[4px] border-[1.5px]
            AnimatedContainer(
              duration: AppDurations.fast,
              width: 18,
              height: 18,
              decoration: BoxDecoration(
                color: isChecked ? AppColors.primary : Colors.transparent,
                borderRadius: BorderRadius.circular(4),
                border: Border.all(
                  color: isChecked
                      ? AppColors.primary
                      : const Color(0x40B47832), // rgba(180,120,50,0.25)
                  width: 1.5,
                ),
              ),
              child: isChecked
                  ? const Center(
                      child: Icon(Icons.check, size: 12, color: Colors.white),
                    )
                  : null,
            ),
            const SizedBox(width: 10), // web: gap-2.5
            Flexible(
              child: Text(
                '',
                style: AppTypography.body.copyWith(
                  fontSize: 13.5, // web: text-[13.5px]
                  color: AppColors.textBody,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
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
    borderRadius: BorderRadius.circular(_fieldRadius),
    borderSide: BorderSide(color: color, width: width),
  );
}
