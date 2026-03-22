import 'package:flutter/material.dart';

import 'package:tander_flutter_v3/core/theme/app_colors.dart';
import 'package:tander_flutter_v3/core/theme/app_curves.dart';
import 'package:tander_flutter_v3/core/theme/app_spacing.dart';
import 'package:tander_flutter_v3/core/theme/app_typography.dart';

/// Elder-friendly checkbox with the Tander warm design language.
///
/// A 24 x 24 px checkbox that transitions from a white bordered box
/// to a filled primary-orange box with a white checkmark.
/// An optional [label] renders to the right.
class WarmCheckbox extends StatelessWidget {
  const WarmCheckbox({
    required this.value,
    required this.onChanged,
    this.label,
    super.key,
  });

  /// Whether the checkbox is currently checked.
  final bool value;

  /// Called when the user taps the checkbox or its label.
  final ValueChanged<bool> onChanged;

  /// Optional text label rendered to the right of the box.
  final String? label;

  // ── Visual constants ─────────────────────────────────────────────

  static const double _boxSize = 24;
  static const double _borderRadius = 6;
  static const double _checkmarkSize = 16;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => onChanged(!value),
      behavior: HitTestBehavior.opaque,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildCheckbox(),
          if (label != null) ...[
            const SizedBox(width: AppSpacing.xs),
            Flexible(child: _buildLabel()),
          ],
        ],
      ),
    );
  }

  Widget _buildCheckbox() {
    return AnimatedContainer(
      duration: AppDurations.fast,
      curve: AppCurves.premiumEase,
      width: _boxSize,
      height: _boxSize,
      decoration: BoxDecoration(
        color: value ? AppColors.primary : AppColors.card,
        borderRadius: BorderRadius.circular(_borderRadius),
        border: value ? null : Border.all(color: AppColors.border),
      ),
      child: value
          ? const Center(
              child: Icon(
                Icons.check_rounded,
                size: _checkmarkSize,
                color: AppColors.textInverse,
              ),
            )
          : null,
    );
  }

  Widget _buildLabel() {
    return Text(
      label!,
      style: AppTypography.body,
    );
  }
}
