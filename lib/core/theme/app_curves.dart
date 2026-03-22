import 'package:flutter/animation.dart';

/// Centralized easing curves for the Tander design system.
///
/// These match the web application's CSS timing functions to ensure
/// consistent motion language across platforms.
abstract final class AppCurves {
  /// Premium deceleration curve — smooth, luxurious exit feel.
  /// CSS equivalent: cubic-bezier(0.22, 1.00, 0.36, 1.00)
  static const Curve premiumEase = Cubic(0.22, 1.00, 0.36, 1.00);

  /// Springy overshoot curve for playful micro-interactions.
  /// CSS equivalent: cubic-bezier(0.34, 1.56, 0.64, 1.00)
  static const Curve spring = Cubic(0.34, 1.56, 0.64, 1.00);
}

/// Centralized animation durations for the Tander design system.
abstract final class AppDurations {
  /// 150 ms — micro-interactions (checkbox, toggle).
  static const Duration fast = Duration(milliseconds: 150);

  /// 250 ms — standard transitions.
  static const Duration base = Duration(milliseconds: 250);

  /// 300 ms — page entrances, overlays.
  static const Duration entrance = Duration(milliseconds: 300);

  /// 400 ms — slow reveals, complex layouts.
  static const Duration slow = Duration(milliseconds: 400);

  /// 600 ms — hero animations, dramatic reveals.
  static const Duration slower = Duration(milliseconds: 600);

  /// 1600 ms — shimmer / skeleton pulse cycle.
  static const Duration shimmer = Duration(milliseconds: 1600);
}
