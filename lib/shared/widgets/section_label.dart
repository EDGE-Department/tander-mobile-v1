/// Reusable uppercase section label for settings and form screens.
library;

import 'package:flutter/material.dart';

import 'package:tander_flutter_v3/core/theme/app_colors.dart';
import 'package:tander_flutter_v3/core/theme/app_spacing.dart';
import 'package:tander_flutter_v3/core/theme/app_typography.dart';

/// Uppercase tracking section heading used in settings and edit screens.
class SectionLabel extends StatelessWidget {
  const SectionLabel({required this.label, super.key});

  /// Text to display (will be uppercased automatically).
  final String label;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: AppSpacing.xxs),
      child: Text(
        label.toUpperCase(),
        style: AppTypography.caption.copyWith(
          fontWeight: FontWeight.w700,
          letterSpacing: 1.4,
          color: AppColors.textMuted,
        ),
      ),
    );
  }
}
