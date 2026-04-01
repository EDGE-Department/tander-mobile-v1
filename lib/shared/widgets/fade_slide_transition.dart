import 'package:flutter/material.dart';

/// Reusable fade + slide-up entrance transition.
///
/// Driven by a parent [AnimationController]. The [interval] controls
/// when within the parent's timeline this transition occurs.
class FadeSlideTransition extends StatelessWidget {
  final Animation<double> animation;
  final Interval interval;
  final double slideY;
  final Widget child;

  const FadeSlideTransition({
    super.key,
    required this.animation,
    this.interval = const Interval(0.0, 1.0, curve: Curves.easeOut),
    this.slideY = 20,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: animation,
      builder: (context, child) {
        final value = interval.transform(animation.value);
        return Opacity(
          opacity: value,
          child: Transform.translate(
            offset: Offset(0, slideY * (1 - value)),
            child: child,
          ),
        );
      },
      child: child,
    );
  }
}
