import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:tander_flutter_v3/core/theme/app_radius.dart';
import 'package:tander_flutter_v3/core/theme/app_shadows.dart';

/// Default frosted-glass background: rgba(255, 252, 248, 0.78).
const Color _defaultGlassBackground = Color(0xC8FFFCF8);

/// Default glass border: rgba(255, 255, 255, 0.84).
const Color _defaultGlassBorder = Color(0xD6FFFFFF);

/// Frosted-glass container with backdrop blur, warm shadow, and subtle border.
///
/// Wraps [child] in a clipped, blurred surface inspired by iOS vibrancy.
/// Ideal for overlays, floating panels, and elevated content areas.
///
/// ```dart
/// GlassCard(
///   child: Padding(
///     padding: EdgeInsets.all(16),
///     child: Text('Hello from behind the frost'),
///   ),
/// )
/// ```
class GlassCard extends StatelessWidget {
  const GlassCard({
    super.key,
    required this.child,
    this.borderRadius,
    this.padding,
    this.blurSigma = 32.0,
    this.backgroundColor,
    this.borderColor,
  });

  /// Content rendered inside the glass surface.
  final Widget child;

  /// Corner radius. Defaults to [AppRadius.xl] (24 px).
  final BorderRadius? borderRadius;

  /// Inner padding applied to [child]. `null` means no padding.
  final EdgeInsetsGeometry? padding;

  /// Gaussian blur strength for the backdrop filter.
  final double blurSigma;

  /// Glass tint color. Defaults to warm off-white at 78 % opacity.
  final Color? backgroundColor;

  /// Border color. Defaults to white at 84 % opacity.
  final Color? borderColor;

  @override
  Widget build(BuildContext context) {
    final BorderRadius resolvedRadius = borderRadius ?? AppRadius.borderXl;
    final Color resolvedBackground = backgroundColor ?? _defaultGlassBackground;
    final Color resolvedBorder = borderColor ?? _defaultGlassBorder;

    return ClipRRect(
      borderRadius: resolvedRadius,
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: blurSigma, sigmaY: blurSigma),
        child: Container(
          decoration: BoxDecoration(
            color: resolvedBackground,
            borderRadius: resolvedRadius,
            border: Border.all(color: resolvedBorder),
            boxShadow: AppShadows.warmMd,
          ),
          padding: padding,
          child: child,
        ),
      ),
    );
  }
}
