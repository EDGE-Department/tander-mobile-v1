import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import 'package:tander_flutter_v3/core/theme/app_curves.dart';

/// Fade-and-slide entrance wrapper for screen-level transitions.
///
/// Wraps [child] with a combined fade-in + subtle upward slide
/// that fires once when the widget first mounts. Uses the Tander
/// [AppCurves.premiumEase] curve for a polished deceleration feel.
///
/// Usage:
/// ```dart
/// PageTransition(child: MyScreenContent());
/// ```
class PageTransition extends StatelessWidget {
  const PageTransition({required this.child, super.key});

  /// The screen content to animate in.
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return child
        .animate()
        .fadeIn(duration: AppDurations.entrance, curve: AppCurves.premiumEase)
        .slideY(
          begin: 0.02,
          end: 0,
          duration: AppDurations.entrance,
          curve: AppCurves.premiumEase,
        );
  }
}
