/// Elder-friendly animated toggle switch matching the Tander design language.
///
/// A 48 x 28 track with a 22 px thumb that slides with a spring animation.
/// Reused across notification, privacy, security, and discovery screens.
library;

import 'package:flutter/material.dart';

import 'package:tander_flutter_v3/core/theme/app_colors.dart';
import 'package:tander_flutter_v3/core/theme/app_curves.dart';

/// Warm-styled toggle switch.
class WarmSwitch extends StatelessWidget {
  const WarmSwitch({
    required this.isEnabled,
    required this.onToggle,
    super.key,
  });

  /// Whether the switch is currently in the ON position.
  final bool isEnabled;

  /// Called when the user taps the switch.
  final VoidCallback onToggle;

  static const double _trackWidth = 48;
  static const double _trackHeight = 28;
  static const double _thumbSize = 22;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onToggle,
      child: AnimatedContainer(
        duration: AppDurations.fast,
        curve: AppCurves.premiumEase,
        width: _trackWidth,
        height: _trackHeight,
        decoration: BoxDecoration(
          color: isEnabled ? AppColors.primary : AppColors.border,
          borderRadius: BorderRadius.circular(_trackHeight / 2),
        ),
        child: AnimatedAlign(
          duration: AppDurations.fast,
          curve: AppCurves.spring,
          alignment:
              isEnabled ? Alignment.centerRight : Alignment.centerLeft,
          child: Container(
            width: _thumbSize,
            height: _thumbSize,
            margin: const EdgeInsets.all(3),
            decoration: const BoxDecoration(
              color: AppColors.card,
              shape: BoxShape.circle,
            ),
          ),
        ),
      ),
    );
  }
}
