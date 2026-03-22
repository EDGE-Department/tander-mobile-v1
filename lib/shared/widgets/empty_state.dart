import 'package:flutter/material.dart';

import 'package:tander_flutter_v3/core/theme/app_colors.dart';
import 'package:tander_flutter_v3/core/theme/app_spacing.dart';
import 'package:tander_flutter_v3/core/theme/app_typography.dart';
import 'package:tander_flutter_v3/shared/widgets/tander_button.dart';

/// Full-width empty-state placeholder with icon, title, and optional CTA.
///
/// Renders a centered column suitable for screens that have no content yet
/// (empty inbox, no connections, etc.). The icon sits inside a 72 x 72
/// warm-gradient circle that matches the Tander brand palette.
class EmptyState extends StatelessWidget {
  const EmptyState({
    required this.title,
    this.description,
    this.icon,
    this.actionLabel,
    this.onAction,
    super.key,
  });

  /// Heading displayed beneath the icon circle.
  final String title;

  /// Optional body text rendered below the title.
  final String? description;

  /// Icon drawn inside the gradient circle. Defaults to [Icons.inbox_outlined].
  final IconData? icon;

  /// Label for the optional call-to-action button.
  final String? actionLabel;

  /// Callback fired when the CTA button is tapped.
  final VoidCallback? onAction;

  // ── Visual constants ─────────────────────────────────────────────

  static const double _circleSize = 72;
  static const double _iconSize = 32;
  static const Color _gradientStart = Color(0xFFFFF8EE);
  static const Color _gradientEnd = Color(0xFFFFF0DE);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildIconCircle(),
          const SizedBox(height: AppSpacing.lg),
          _buildTitle(),
          if (description != null) ...[
            const SizedBox(height: AppSpacing.xs),
            _buildDescription(),
          ],
          if (actionLabel != null) ...[
            const SizedBox(height: AppSpacing.lg),
            _buildActionButton(),
          ],
        ],
      ),
    );
  }

  Widget _buildIconCircle() {
    return Container(
      width: _circleSize,
      height: _circleSize,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [_gradientStart, _gradientEnd],
        ),
        border: Border.all(color: AppColors.borderLight),
      ),
      child: Center(
        child: Icon(
          icon ?? Icons.inbox_outlined,
          size: _iconSize,
          color: AppColors.primary,
        ),
      ),
    );
  }

  Widget _buildTitle() {
    return Text(
      title,
      style: AppTypography.h3,
      textAlign: TextAlign.center,
    );
  }

  Widget _buildDescription() {
    return Text(
      description!,
      style: AppTypography.body.copyWith(color: AppColors.textMuted),
      textAlign: TextAlign.center,
    );
  }

  Widget _buildActionButton() {
    return TanderButton(
      label: actionLabel!,
      onPressed: onAction,
      size: TanderButtonSize.compact,
    );
  }
}
