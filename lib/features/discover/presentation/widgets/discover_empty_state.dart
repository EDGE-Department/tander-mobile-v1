/// Custom empty state for the discover card stack — pixel-perfect web port.
///
/// Shows a layered pulsing heart icon, "You've seen everyone!" heading,
/// body text, orange gradient "Adjust filters" button, and secondary
/// "View connections" + "Check messages" pill links.
library;

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'package:tander_flutter_v3/core/theme/app_colors.dart';
import 'package:tander_flutter_v3/core/theme/app_radius.dart';
import 'package:tander_flutter_v3/core/theme/app_spacing.dart';
import 'package:tander_flutter_v3/core/theme/app_typography.dart';
import 'package:tander_flutter_v3/shared/constants/routes.dart';

class DiscoverEmptyState extends StatelessWidget {
  const DiscoverEmptyState({required this.onOpenFilters, super.key});

  final VoidCallback onOpenFilters;

  static const double _outerSize = 112;
  static const double _middleInset = 12;
  static const double _innerInset = 24;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.lg,
          vertical: AppSpacing.xl,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildLayeredHeartIcon(),
            const SizedBox(height: AppSpacing.lg),
            Text(
              "You've seen everyone!",
              style: AppTypography.h2,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.xs),
            ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 280),
              child: const Text(
                'New people join every day. We\u2019ll let you know '
                'when someone new is nearby.',
                style: TextStyle(
                  fontSize: 16,
                  color: AppColors.textMuted,
                  height: 1.5,
                ),
                textAlign: TextAlign.center,
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            _buildAdjustFiltersButton(context),
            const SizedBox(height: AppSpacing.md),
            _buildSecondaryLinks(context),
          ],
        ),
      ),
    );
  }

  /// Three concentric circles with warm orange-teal gradient and a heart.
  Widget _buildLayeredHeartIcon() {
    return SizedBox(
      width: _outerSize,
      height: _outerSize,
      child: Stack(
        children: [
          // Outer pulsing ring
          const Positioned.fill(
            child: _PulsingCircle(
              gradient: LinearGradient(
                begin: Alignment(-0.3, -1),
                end: Alignment(0.3, 1),
                colors: [
                  Color(0x14E67E22), // orange 8%
                  Color(0x0F0F9D94), // teal 6%
                ],
              ),
            ),
          ),
          // Middle ring
          Positioned.fill(
            child: Padding(
              padding: const EdgeInsets.all(_middleInset),
              child: Container(
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    begin: Alignment(-0.3, -1),
                    end: Alignment(0.3, 1),
                    colors: [
                      Color(0x24E67E22), // orange 14%
                      Color(0x1A0F9D94), // teal 10%
                    ],
                  ),
                ),
              ),
            ),
          ),
          // Inner ring with heart
          Positioned.fill(
            child: Padding(
              padding: const EdgeInsets.all(_innerInset),
              child: Container(
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    begin: Alignment(-0.3, -1),
                    end: Alignment(0.3, 1),
                    colors: [
                      Color(0x38E67E22), // orange 22%
                      Color(0x290F9D94), // teal 16%
                    ],
                  ),
                ),
                alignment: Alignment.center,
                child: const Icon(
                  Icons.favorite,
                  size: 30,
                  color: AppColors.primary,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAdjustFiltersButton(BuildContext context) {
    return Semantics(
      button: true,
      label: 'Adjust filters',
      child: GestureDetector(
        onTap: onOpenFilters,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 14),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFFF07020), Color(0xFFE67E22)],
            ),
            borderRadius: AppRadius.borderXl,
            boxShadow: const [
              BoxShadow(
                color: Color(0x52E67E22),
                blurRadius: 16,
                offset: Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.tune, size: 18, color: AppColors.textInverse),
              const SizedBox(width: AppSpacing.xs),
              Text(
                'Adjust filters',
                style: AppTypography.label.copyWith(
                  color: AppColors.textInverse,
                  fontWeight: FontWeight.w600,
                  fontSize: 16,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSecondaryLinks(BuildContext context) {
    return Wrap(
      spacing: AppSpacing.xs,
      runSpacing: AppSpacing.xs,
      alignment: WrapAlignment.center,
      children: [
        _SecondaryPill(
          label: 'View connections',
          textColor: AppColors.secondary,
          borderColor: AppColors.secondary.withValues(alpha: 0.25),
          backgroundColor: AppColors.secondaryLight.withValues(alpha: 0.40),
          onTap: () => context.go(AppRoutes.connection),
        ),
        _SecondaryPill(
          label: 'Check messages',
          textColor: AppColors.textMuted,
          borderColor: AppColors.border,
          backgroundColor: AppColors.card,
          onTap: () => context.go(AppRoutes.messages),
        ),
      ],
    );
  }
}

/// Slow-pulsing circle for the empty state layered heart icon.
class _PulsingCircle extends StatefulWidget {
  const _PulsingCircle({required this.gradient});

  final LinearGradient gradient;

  @override
  State<_PulsingCircle> createState() => _PulsingCircleState();
}

class _PulsingCircleState extends State<_PulsingCircle>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Opacity(opacity: 0.6 + 0.4 * _controller.value, child: child);
      },
      child: Container(
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: widget.gradient,
        ),
      ),
    );
  }
}

/// Secondary pill link (matches web: rounded-full, border, text-sm semibold).
class _SecondaryPill extends StatelessWidget {
  const _SecondaryPill({
    required this.label,
    required this.textColor,
    required this.borderColor,
    required this.backgroundColor,
    required this.onTap,
  });

  final String label;
  final Color textColor;
  final Color borderColor;
  final Color backgroundColor;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: label,
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          constraints: const BoxConstraints(minHeight: 40),
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md,
            vertical: 10,
          ),
          decoration: BoxDecoration(
            color: backgroundColor,
            borderRadius: AppRadius.borderFull,
            border: Border.all(color: borderColor),
          ),
          child: Text(
            label,
            style: AppTypography.bodySm.copyWith(
              color: textColor,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ),
    );
  }
}
