/// Staggered fade + slide entrance wrapper for list items.
///
/// Wraps a child with [flutter_animate] fadeIn + slideY, using the
/// provided [index] to compute a staggered delay (index * 40 ms).
library;

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

/// Delay per item in a staggered list entrance.
const Duration _staggerDelay = Duration(milliseconds: 40);

/// Duration of the fade + slide animation.
const Duration _animationDuration = Duration(milliseconds: 220);

/// Vertical offset in logical pixels for the slide-up entrance.
const double _slideOffset = 16;

class StaggerEntrance extends StatelessWidget {
  const StaggerEntrance({required this.index, required this.child, super.key});

  /// Position in the list — determines the stagger delay.
  final int index;

  /// The widget to animate in.
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return child
        .animate(delay: _staggerDelay * index)
        .fadeIn(duration: _animationDuration, curve: Curves.easeOut)
        .slideY(
          begin: _slideOffset / 100,
          end: 0,
          duration: _animationDuration,
          curve: Curves.easeOut,
        );
  }
}
