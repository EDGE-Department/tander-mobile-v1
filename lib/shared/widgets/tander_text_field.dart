import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:tander_flutter_v3/core/theme/app_colors.dart';
import 'package:tander_flutter_v3/core/theme/app_radius.dart';
import 'package:tander_flutter_v3/core/theme/app_spacing.dart';
import 'package:tander_flutter_v3/core/theme/app_typography.dart';

/// Elder-friendly text field matching the Tander web INPUT token system.
///
/// Renders an optional [label] above the field, with built-in support for
/// [errorText], [helperText], prefix/suffix icons, and obscured input.
///
/// Uses [minHeight] of 56 px for WCAG-compliant touch targets. Font size
/// defaults to 16 px ([AppTypography.body]) to prevent iOS auto-zoom.
class TanderTextField extends StatelessWidget {
  const TanderTextField({
    this.label,
    this.hint,
    this.errorText,
    this.helperText,
    this.controller,
    this.obscureText = false,
    this.keyboardType,
    this.prefixIcon,
    this.suffixIcon,
    this.maxLines = 1,
    this.maxLength,
    this.onChanged,
    this.validator,
    this.textInputAction,
    this.autofocus = false,
    this.enabled = true,
    this.focusNode,
    this.inputFormatters,
    super.key,
  });

  final String? label;
  final String? hint;
  final String? errorText;
  final String? helperText;
  final TextEditingController? controller;
  final bool obscureText;
  final TextInputType? keyboardType;
  final IconData? prefixIcon;
  final IconData? suffixIcon;
  final int maxLines;
  final int? maxLength;
  final ValueChanged<String>? onChanged;
  final FormFieldValidator<String>? validator;
  final TextInputAction? textInputAction;
  final bool autofocus;
  final bool enabled;
  final FocusNode? focusNode;
  final List<TextInputFormatter>? inputFormatters;

  bool get _hasError => errorText != null && errorText!.isNotEmpty;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (label != null) ...[
          Text(label!, style: AppTypography.label),
          const SizedBox(height: AppSpacing.xs),
        ],
        _buildInputField(),
        if (_hasError) ...[
          const SizedBox(height: AppSpacing.xxs),
          _buildErrorText(),
        ] else if (helperText != null) ...[
          const SizedBox(height: AppSpacing.xxs),
          _buildHelperText(),
        ],
      ],
    );
  }

  Widget _buildInputField() {
    return TextFormField(
      controller: controller,
      obscureText: obscureText,
      keyboardType: keyboardType,
      maxLines: maxLines,
      maxLength: maxLength,
      onChanged: onChanged,
      validator: validator,
      textInputAction: textInputAction,
      autofocus: autofocus,
      enabled: enabled,
      focusNode: focusNode,
      inputFormatters: inputFormatters,
      style: AppTypography.body.copyWith(
        color: enabled ? AppColors.textStrong : AppColors.textDisabled,
      ),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: AppTypography.body.copyWith(color: AppColors.textMuted),
        filled: true,
        fillColor: enabled ? AppColors.card : AppColors.subtle,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.sm,
        ),
        constraints: const BoxConstraints(
          minHeight: AppSpacing.touchComfortable,
        ),
        prefixIcon: _buildPrefixIcon(),
        suffixIcon: _buildSuffixIcon(),
        counterText: '',
        border: _buildBorder(AppColors.border),
        enabledBorder: _buildBorder(AppColors.border),
        focusedBorder: _buildBorder(AppColors.primary, width: 1.5),
        errorBorder: _buildBorder(AppColors.danger),
        focusedErrorBorder: _buildBorder(AppColors.danger, width: 1.5),
        disabledBorder: _buildBorder(AppColors.borderLight),
        errorStyle: const TextStyle(fontSize: 0, height: 0),
      ),
    );
  }

  OutlineInputBorder _buildBorder(Color color, {double width = 1.0}) {
    return OutlineInputBorder(
      borderRadius: AppRadius.borderSm,
      borderSide: BorderSide(color: color, width: width),
    );
  }

  Widget? _buildPrefixIcon() {
    if (prefixIcon == null) return null;
    return Padding(
      padding: const EdgeInsets.only(left: AppSpacing.sm, right: AppSpacing.xs),
      child: Icon(prefixIcon, size: 20, color: AppColors.textMuted),
    );
  }

  Widget? _buildSuffixIcon() {
    if (suffixIcon == null) return null;
    return Padding(
      padding: const EdgeInsets.only(right: AppSpacing.sm, left: AppSpacing.xs),
      child: Icon(suffixIcon, size: 20, color: AppColors.textMuted),
    );
  }

  Widget _buildErrorText() {
    return Text(
      errorText!,
      style: AppTypography.caption.copyWith(color: AppColors.danger),
    );
  }

  Widget _buildHelperText() {
    return Text(
      helperText!,
      style: AppTypography.caption,
    );
  }
}
