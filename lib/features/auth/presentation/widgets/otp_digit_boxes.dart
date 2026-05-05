import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:tander_flutter_v3/core/theme/app_colors.dart';
import 'package:tander_flutter_v3/core/theme/app_radius.dart';
import 'package:tander_flutter_v3/core/theme/app_spacing.dart';

/// Number of OTP digits expected.
const int otpLength = 6;

/// Callback signature when the full OTP is ready for submission.
typedef OtpSubmitCallback = void Function(String otp);

/// A row of [otpLength] digit cells driven by a single hidden [TextField].
///
/// Why one input instead of six:
/// On iOS Safari/WebKit and on iOS Flutter, six per-digit fields cause the
/// software keyboard to flicker (dismiss/re-present) every time focus jumps
/// to the next box. With a single underlying field the keyboard stays put
/// across the whole entry, eliminating the jitter on every iPhone version.
/// We also opt into [AutofillHints.oneTimeCode] so iOS can paste a code
/// straight from the SMS notification.
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

  /// Whether the cells should display in error state.
  final bool hasError;

  /// Whether the input accepts characters.
  final bool isEnabled;

  /// Notifies the parent whenever the filled-digit count changes.
  final ValueChanged<int>? onDigitCountChanged;

  @override
  State<OtpDigitBoxes> createState() => OtpDigitBoxesState();
}

class OtpDigitBoxesState extends State<OtpDigitBoxes> {
  final TextEditingController _controller = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  int _lastReportedCount = 0;

  /// External API — the screen reads this when the user taps "Verify".
  String get otpValue => _controller.text;

  /// External API — used by the OTP screen on resend / error.
  void clearAll() {
    _controller.clear();
    _focusNode.requestFocus();
    if (_lastReportedCount != 0) {
      _lastReportedCount = 0;
      widget.onDigitCountChanged?.call(0);
    }
  }

  @override
  void initState() {
    super.initState();
    _controller.addListener(_onTextChanged);
  }

  void _onTextChanged() {
    final length = _controller.text.length;
    if (length != _lastReportedCount) {
      _lastReportedCount = length;
      widget.onDigitCountChanged?.call(length);
    }
    if (length == otpLength) {
      // Defer so the visual cell paint completes before the parent runs
      // verification (which may show a spinner / disable the field).
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) widget.onComplete(_controller.text);
      });
    }
  }

  @override
  void dispose() {
    _controller.removeListener(_onTextChanged);
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Cell sizing: 32px outer padding × 2 = 64px subtracted from screen width.
    final screenWidth = MediaQuery.sizeOf(context).width;
    final availableWidth = screenWidth - 64;
    const spacing = AppSpacing.xs;
    const totalSpacing = spacing * (otpLength - 1);
    final boxWidth = ((availableWidth - totalSpacing) / otpLength).clamp(36.0, 48.0);
    final boxHeight = (boxWidth * 1.15).clamp(44.0, 56.0);

    return AnimatedBuilder(
      animation: widget.shakeAnimation,
      builder: (context, child) => Transform.translate(
        offset: Offset(widget.shakeAnimation.value, 0),
        child: child,
      ),
      child: SizedBox(
        height: boxHeight,
        child: Stack(
          alignment: Alignment.center,
          children: [
            // Visual cells. Repaint on text and focus changes so the active
            // cell ring can move with the caret.
            Positioned.fill(
              child: AnimatedBuilder(
                animation: Listenable.merge([_controller, _focusNode]),
                builder: (context, _) => Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  mainAxisSize: MainAxisSize.min,
                  children: List.generate(
                    otpLength,
                    (i) => _buildCell(i, boxWidth, boxHeight),
                  ),
                ),
              ),
            ),
            // The single TextField sits on top, transparent, capturing every
            // tap on the row. One focusable element ⇒ keyboard stays put.
            Positioned.fill(
              child: TextField(
                controller: _controller,
                focusNode: _focusNode,
                enabled: widget.isEnabled,
                keyboardType: TextInputType.number,
                textInputAction: TextInputAction.done,
                autocorrect: false,
                enableSuggestions: false,
                autofillHints: const [AutofillHints.oneTimeCode],
                maxLength: otpLength,
                inputFormatters: [
                  FilteringTextInputFormatter.digitsOnly,
                  LengthLimitingTextInputFormatter(otpLength),
                ],
                showCursor: false,
                cursorWidth: 0,
                cursorColor: Colors.transparent,
                // Transparent text + transparent selection so the user only
                // sees the visual cells underneath.
                style: const TextStyle(color: Colors.transparent, fontSize: 1),
                selectionControls: _NoToolbarSelectionControls(),
                decoration: const InputDecoration(
                  border: InputBorder.none,
                  enabledBorder: InputBorder.none,
                  focusedBorder: InputBorder.none,
                  disabledBorder: InputBorder.none,
                  counterText: '',
                  contentPadding: EdgeInsets.zero,
                  isCollapsed: true,
                  filled: false,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCell(int index, double boxWidth, double boxHeight) {
    final value = _controller.text;
    final filled = index < value.length;
    final digit = filled ? value[index] : '';
    final isActive = _focusNode.hasFocus && index == value.length;

    Color borderColor;
    if (widget.hasError) {
      borderColor = AppColors.danger;
    } else if (isActive) {
      borderColor = AppColors.primary;
    } else if (filled) {
      borderColor = AppColors.primary;
    } else {
      borderColor = AppColors.border;
    }

    Color fillColor;
    if (widget.hasError) {
      fillColor = AppColors.dangerLight;
    } else if (filled) {
      fillColor = AppColors.primaryLight;
    } else {
      fillColor = AppColors.card;
    }

    return Padding(
      padding: EdgeInsets.only(left: index == 0 ? 0 : AppSpacing.xs),
      child: Container(
        width: boxWidth,
        height: boxHeight,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: fillColor,
          borderRadius: AppRadius.borderMd,
          border: Border.all(color: borderColor, width: isActive ? 2 : 1.5),
        ),
        child: Text(
          digit,
          style: TextStyle(
            fontSize: boxWidth * 0.5,
            fontWeight: FontWeight.w700,
            color: AppColors.textStrong,
          ),
        ),
      ),
    );
  }
}

/// Suppresses the Cut/Copy/Paste toolbar on the hidden field — the field has
/// no visible text, so the toolbar would just be confusing. Paste still works
/// via the keyboard suggestion bar (iOS) and via long-press on the cells (the
/// hidden field absorbs the gesture).
class _NoToolbarSelectionControls extends MaterialTextSelectionControls {
  @override
  Widget buildToolbar(
    BuildContext context,
    Rect globalEditableRegion,
    double textLineHeight,
    Offset selectionMidpoint,
    List<TextSelectionPoint> endpoints,
    TextSelectionDelegate delegate,
    ValueListenable<ClipboardStatus>? clipboardStatus,
    Offset? lastSecondaryTapDownPosition,
  ) {
    return const SizedBox.shrink();
  }
}
