import 'package:flutter/material.dart';

import 'package:tander_flutter_v3/core/theme/app_curves.dart';
import 'package:tander_flutter_v3/core/theme/app_radius.dart';

/// Shape variant for [SkeletonCard] shimmer placeholders.
enum SkeletonVariant {
  /// Single line of text — 100 % width, 16 px tall, radius 8.
  text,

  /// Title-width block — 60 % width, 24 px tall, radius 10.
  title,

  /// Circular avatar — uses [width] as diameter (default 48).
  circle,

  /// Rounded card — 100 % width, 200 px tall, radius 16.
  card,

  /// Full-bleed card — 100 % width, 320 px tall, radius 16.
  fullCard,
}

/// Shimmer-pulsing loading placeholder that adapts to [SkeletonVariant].
///
/// Renders a rounded rectangle (or circle) whose opacity oscillates
/// between 0.3 and 0.7 over 1.6 s, simulating a skeleton screen.
class SkeletonCard extends StatefulWidget {
  const SkeletonCard({
    this.variant = SkeletonVariant.card,
    this.width,
    this.height,
    super.key,
  });

  /// Visual shape preset.
  final SkeletonVariant variant;

  /// Explicit width override. Falls back to variant defaults.
  final double? width;

  /// Explicit height override. Falls back to variant defaults.
  final double? height;

  @override
  State<SkeletonCard> createState() => _SkeletonCardState();
}

class _SkeletonCardState extends State<SkeletonCard>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulseController;
  late final Animation<double> _opacityAnimation;

  // ── Shimmer gradient colors ────────────────────────────────────
  static const Color _shimmerLight = Color(0xFFEDE8E0);
  static const Color _shimmerDark = Color(0xFFE5DFDA);
  static const double _opacityMin = 0.3;
  static const double _opacityMax = 0.7;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: AppDurations.shimmer,
    )..repeat(reverse: true);

    _opacityAnimation = Tween<double>(
      begin: _opacityMin,
      end: _opacityMax,
    ).animate(
      CurvedAnimation(
        parent: _pulseController,
        curve: Curves.easeInOut,
      ),
    );
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final resolvedWidth = _resolveWidth();
    final resolvedHeight = _resolveHeight();
    final resolvedRadius = _resolveRadius();

    return AnimatedBuilder(
      animation: _opacityAnimation,
      builder: (context, child) {
        return Opacity(
          opacity: _opacityAnimation.value,
          child: child,
        );
      },
      child: Container(
        width: resolvedWidth,
        height: resolvedHeight,
        decoration: BoxDecoration(
          borderRadius: widget.variant == SkeletonVariant.circle
              ? null
              : BorderRadius.circular(resolvedRadius),
          shape: widget.variant == SkeletonVariant.circle
              ? BoxShape.circle
              : BoxShape.rectangle,
          gradient: const LinearGradient(
            begin: Alignment(-0.7, -1),
            end: Alignment(0.7, 1),
            colors: [_shimmerLight, _shimmerDark],
          ),
        ),
      ),
    );
  }

  double? _resolveWidth() {
    if (widget.width != null) return widget.width;
    return switch (widget.variant) {
      SkeletonVariant.text => double.infinity,
      SkeletonVariant.title => null,
      SkeletonVariant.circle => 48,
      SkeletonVariant.card => double.infinity,
      SkeletonVariant.fullCard => double.infinity,
    };
  }

  double _resolveHeight() {
    if (widget.height != null) return widget.height!;
    return switch (widget.variant) {
      SkeletonVariant.text => 16,
      SkeletonVariant.title => 24,
      SkeletonVariant.circle => 48,
      SkeletonVariant.card => 200,
      SkeletonVariant.fullCard => 320,
    };
  }

  double _resolveRadius() {
    return switch (widget.variant) {
      SkeletonVariant.text => AppRadius.sm,
      SkeletonVariant.title => 10,
      SkeletonVariant.circle => AppRadius.full,
      SkeletonVariant.card => AppRadius.lg,
      SkeletonVariant.fullCard => AppRadius.lg,
    };
  }
}
