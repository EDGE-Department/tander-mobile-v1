import 'dart:math' as math;

import 'package:flutter/material.dart';

/// The white "rail" dome. Renders the rail-anim image and plays a fluid wave
/// dip whenever the active column changes. Horizontal placement is handled by
/// the parent grid (an `AnimatedAlign` over the 5 equal columns).
///
/// Layout/translate only — never wrap in a per-frame filter
/// (`BackdropFilter`/`saveLayer`/`ImageFiltered`). The 2026-06-29 Adreno 610
/// blank-render bug was that class of issue.
class NavRailIndicator extends StatefulWidget {
  const NavRailIndicator({
    required this.activeIndex,
    required this.width,
    required this.height,
    required this.reduceMotion,
    this.color = Colors.white,
    super.key,
  });

  final int activeIndex;
  final double width;
  final double height;
  final bool reduceMotion;

  /// Tint applied to the dome (via `BlendMode.srcIn`) so it is the exact same
  /// colour as the capsule surface — a seamless white-on-white merge.
  final Color color;

  @override
  State<NavRailIndicator> createState() => _NavRailIndicatorState();
}


class _NavRailIndicatorState extends State<NavRailIndicator>
    with SingleTickerProviderStateMixin {
  static const Duration _kWave = Duration(milliseconds: 380);
  static const double _kDipAmount = 16.0;

  late final AnimationController _dip;

  @override
  void initState() {
    super.initState();
    _dip = AnimationController(vsync: this, duration: _kWave);
  }

  @override
  void didUpdateWidget(NavRailIndicator oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.activeIndex != widget.activeIndex && !widget.reduceMotion) {
      _dip.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _dip.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _dip,
      builder: (context, child) {
        // Half-sine: rests at 0, dips down at mid-travel, returns to 0.
        final dipY = math.sin(_dip.value * math.pi) * _kDipAmount;
        return Transform.translate(offset: Offset(0, dipY), child: child);
      },
      child: Image.asset(
        'assets/icons/nav/nav_rail.png',
        width: widget.width,
        height: widget.height,
        fit: BoxFit.fill,
        color: const Color(0xEEFFFFFF),
        colorBlendMode: BlendMode.srcIn,
        excludeFromSemantics: true,
      ),
    );
  }
}
