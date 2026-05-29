/// Warm bokeh drift widget — a softly blurred circle that follows a
/// Lissajous pattern to create a gentle floating atmosphere.
library;

import 'dart:math' as math;

import 'dart:ui';

import 'package:flutter/material.dart';

import 'package:tander_flutter_v3/core/theme/app_colors.dart';

class FloatingOrb extends StatefulWidget {
  const FloatingOrb({
    this.color,
    this.size = 120,
    this.blurSigma = 28,
    this.driftAmplitudeX = 30,
    this.driftAmplitudeY = 20,
    this.frequencyX = 0.7,
    this.frequencyY = 1.1,
    this.phaseOffset = 0.0,
    this.cycleDuration = const Duration(seconds: 8),
    super.key,
  });

  /// Orb fill color. Defaults to warm orange at 14 % opacity.
  final Color? color;

  /// Diameter of the orb in logical pixels.
  final double size;

  /// Gaussian blur sigma applied to the orb.
  final double blurSigma;

  /// Horizontal drift amplitude in logical pixels.
  final double driftAmplitudeX;

  /// Vertical drift amplitude in logical pixels.
  final double driftAmplitudeY;

  /// Lissajous horizontal frequency multiplier.
  final double frequencyX;

  /// Lissajous vertical frequency multiplier.
  final double frequencyY;

  /// Phase offset (radians) for staggering multiple orbs.
  final double phaseOffset;

  /// Duration of one full Lissajous cycle.
  final Duration cycleDuration;

  @override
  State<FloatingOrb> createState() => _FloatingOrbState();
}

class _FloatingOrbState extends State<FloatingOrb>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: widget.cycleDuration,
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final orbColor = widget.color ?? AppColors.primary.withValues(alpha: 0.14);

    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        final double progressRadians =
            _controller.value * 2 * math.pi + widget.phaseOffset;

        final double offsetX =
            math.sin(progressRadians * widget.frequencyX) *
            widget.driftAmplitudeX;
        final double offsetY =
            math.sin(progressRadians * widget.frequencyY) *
            widget.driftAmplitudeY;

        return Transform.translate(
          offset: Offset(offsetX, offsetY),
          child: child,
        );
      },
      child: ImageFiltered(
        imageFilter: ImageFilter.blur(
          sigmaX: widget.blurSigma,
          sigmaY: widget.blurSigma,
          tileMode: TileMode.decal,
        ),
        child: Container(
          width: widget.size,
          height: widget.size,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: RadialGradient(
              colors: [orbColor, orbColor.withValues(alpha: 0.0)],
              stops: const [0.0, 0.68],
            ),
          ),
        ),
      ),
    );
  }
}
