/// Pulsing glow effect widget — a repeating scale + opacity animation
/// that creates a warm "breathing" glow aura around its child.
library;

import 'package:flutter/material.dart';

import 'package:tander_flutter_v3/core/theme/app_colors.dart';

class BreathingGlow extends StatefulWidget {
  const BreathingGlow({
    required this.child,
    this.glowColor,
    this.glowRadius = 24,
    this.minScale = 0.95,
    this.maxScale = 1.05,
    this.duration = const Duration(milliseconds: 2400),
    super.key,
  });

  /// Widget rendered at the center of the glow.
  final Widget child;

  /// Glow color. Defaults to [AppColors.primary] at 30 % opacity.
  final Color? glowColor;

  /// Blur radius of the glow shadow.
  final double glowRadius;

  /// Minimum scale at the trough of the pulse.
  final double minScale;

  /// Maximum scale at the peak of the pulse.
  final double maxScale;

  /// Full cycle duration (down + up).
  final Duration duration;

  @override
  State<BreathingGlow> createState() => _BreathingGlowState();
}

class _BreathingGlowState extends State<BreathingGlow>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _scaleAnimation;
  late final Animation<double> _opacityAnimation;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(vsync: this, duration: widget.duration)
      ..repeat(reverse: true);

    _scaleAnimation = Tween<double>(
      begin: widget.minScale,
      end: widget.maxScale,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));

    _opacityAnimation = Tween<double>(
      begin: 0.4,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final glowColor =
        widget.glowColor ?? AppColors.primary.withValues(alpha: 0.30);

    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Transform.scale(
          scale: _scaleAnimation.value,
          child: Container(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: glowColor.withValues(
                    alpha: (glowColor.a * _opacityAnimation.value).clamp(
                      0.0,
                      1.0,
                    ),
                  ),
                  blurRadius: widget.glowRadius,
                  spreadRadius: widget.glowRadius * 0.25,
                ),
              ],
            ),
            child: child,
          ),
        );
      },
      child: widget.child,
    );
  }
}
