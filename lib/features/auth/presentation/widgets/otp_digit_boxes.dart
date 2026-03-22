import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:tander_flutter_v3/core/theme/app_colors.dart';
import 'package:tander_flutter_v3/core/theme/app_radius.dart';
import 'package:tander_flutter_v3/core/theme/app_spacing.dart';
import 'package:tander_flutter_v3/core/theme/app_typography.dart';

/// Number of OTP digits expected.
const int otpLength = 6;

/// Callback signature when the full OTP is ready for submission.
typedef OtpSubmitCallback = void Function(String otp);

/// A row of [otpLength] individual digit input boxes that auto-advance
/// on input and auto-submit when all digits are filled.
///
/// Supports paste, backspace navigation, and a shake animation driven
/// by the parent via [shakeAnimation].
class OtpDigitBoxes extends StatefulWidget {
  const OtpDigitBoxes({
    required this.onComplete,
    required this.shakeAnimation,
    required this.hasError,
    this.isEnabled = true,
    this.onDigitCountChanged,
    super.key,
  });

  /// Called when all [otpLength] digits have been entered.
  final OtpSubmitCallback onComplete;

  /// Shake offset animation driven by the parent controller.
  final Animation<double> shakeAnimation;

  /// Whether the boxes should display in error state.
  final bool hasError;

  /// Whether the text fields accept input.
  final bool isEnabled;

  /// Notifies the parent whenever the filled-digit count changes.
  final ValueChanged<int>? onDigitCountChanged;

  @override
  State<OtpDigitBoxes> createState() => OtpDigitBoxesState();
}

class OtpDigitBoxesState extends State<OtpDigitBoxes> {
  final List<TextEditingController> _controllers =
      List.generate(otpLength, (_) => TextEditingController());
  final List<FocusNode> _focusNodes =
      List.generate(otpLength, (_) => FocusNode());

  int get filledCount =>
      _controllers.where((controller) => controller.text.isNotEmpty).length;

  String get otpValue => _controllers.map((c) => c.text).join();

  /// Clears all digit boxes and focuses the first one.
  void clearAll() {
    for (final controller in _controllers) {
      controller.clear();
    }
    _focusNodes.first.requestFocus();
    widget.onDigitCountChanged?.call(0);
  }

  /// Requests focus on the first digit box.
  void focusFirst() {
    _focusNodes.first.requestFocus();
  }

  @override
  void dispose() {
    for (final controller in _controllers) {
      controller.dispose();
    }
    for (final focusNode in _focusNodes) {
      focusNode.dispose();
    }
    super.dispose();
  }

  // -- Handlers -------------------------------------------------------------

  void _handleChanged(int index, String value) {
    final cleaned = value.replaceAll(RegExp(r'\D'), '');
    if (cleaned.isEmpty) {
      _controllers[index].clear();
      widget.onDigitCountChanged?.call(filledCount);
      return;
    }

    // Multiple digits means a paste event.
    if (cleaned.length > 1) {
      _pasteDigits(cleaned);
      return;
    }

    _controllers[index].text = cleaned;
    _controllers[index].selection =
        TextSelection.collapsed(offset: cleaned.length);
    widget.onDigitCountChanged?.call(filledCount);

    if (index < otpLength - 1) {
      _focusNodes[index + 1].requestFocus();
    }

    if (filledCount == otpLength) {
      widget.onComplete(otpValue);
    }
  }

  void _handleKeyEvent(int index, KeyEvent event) {
    if (event is! KeyDownEvent) return;

    if (event.logicalKey == LogicalKeyboardKey.backspace &&
        _controllers[index].text.isEmpty &&
        index > 0) {
      _focusNodes[index - 1].requestFocus();
      _controllers[index - 1].clear();
      widget.onDigitCountChanged?.call(filledCount);
    }
  }

  void _pasteDigits(String pasted) {
    final cleaned = pasted.replaceAll(RegExp(r'\D'), '');
    for (var i = 0; i < otpLength; i++) {
      _controllers[i].text = i < cleaned.length ? cleaned[i] : '';
    }
    final focusIndex = cleaned.length.clamp(0, otpLength - 1);
    _focusNodes[focusIndex].requestFocus();
    widget.onDigitCountChanged?.call(filledCount);

    if (cleaned.length >= otpLength) {
      widget.onComplete(otpValue);
    }
  }

  // -- Build ----------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: widget.shakeAnimation,
      builder: (context, child) {
        return Transform.translate(
          offset: Offset(widget.shakeAnimation.value, 0),
          child: child,
        );
      },
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: List.generate(otpLength, _buildBox),
      ),
    );
  }

  Widget _buildBox(int index) {
    final isFilled = _controllers[index].text.isNotEmpty;

    return Padding(
      padding: EdgeInsets.only(left: index == 0 ? 0 : AppSpacing.xs),
      child: SizedBox(
        width: 48,
        height: 56,
        child: KeyboardListener(
          focusNode: FocusNode(),
          onKeyEvent: (event) => _handleKeyEvent(index, event),
          child: TextField(
            controller: _controllers[index],
            focusNode: _focusNodes[index],
            textAlign: TextAlign.center,
            keyboardType: TextInputType.number,
            maxLength: 2,
            enabled: widget.isEnabled,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            style: AppTypography.h2.copyWith(
              fontWeight: FontWeight.w700,
              color: AppColors.textStrong,
            ),
            decoration: InputDecoration(
              counterText: '',
              filled: true,
              fillColor: widget.hasError
                  ? AppColors.dangerLight
                  : isFilled
                      ? AppColors.primaryLight
                      : AppColors.card,
              contentPadding: EdgeInsets.zero,
              border: _borderStyle(
                widget.hasError ? AppColors.danger : AppColors.border,
              ),
              enabledBorder: _borderStyle(
                widget.hasError
                    ? AppColors.danger
                    : isFilled
                        ? AppColors.primary
                        : AppColors.border,
              ),
              focusedBorder: _borderStyle(AppColors.primary, width: 2),
              disabledBorder: _borderStyle(AppColors.borderLight),
            ),
            onChanged: (value) => _handleChanged(index, value),
          ),
        ),
      ),
    );
  }

  OutlineInputBorder _borderStyle(Color color, {double width = 1.5}) {
    return OutlineInputBorder(
      borderRadius: AppRadius.borderMd,
      borderSide: BorderSide(color: color, width: width),
    );
  }
}
