import 'package:flutter/material.dart';
import 'package:tander_flutter_v3/app/widgets/nav_geometry.dart';

/// White "rail" hump that slides to the active column.
///
/// Layout/translate only (`AnimatedPositioned`) — never wrap this in a
/// per-frame filter (`BackdropFilter`/`saveLayer`/`ImageFiltered`). The
/// 2026-06-29 Adreno 610 blank-render bug was that class of issue, and the
/// bar already composites a blur elsewhere.
class NavRailIndicator extends StatelessWidget {
  const NavRailIndicator({
    required this.activeIndex,
    required this.columnCount,
    required this.barWidth,
    required this.railWidth,
    required this.railHeight,
    required this.reduceMotion,
    this.color = Colors.white,
    super.key,
  });

  final int activeIndex;
  final int columnCount;
  final double barWidth;
  final double railWidth;
  final double railHeight;
  final bool reduceMotion;

  /// Tint applied to the rail (via `BlendMode.srcIn`) so the hump is the exact
  /// same colour as the capsule surface — guaranteeing a seamless merge.
  final Color color;

  @override
  Widget build(BuildContext context) {
    final left = railLeftForIndex(
      index: activeIndex,
      columnCount: columnCount,
      barWidth: barWidth,
      railWidth: railWidth,
    );
    return AnimatedPositioned(
      duration: reduceMotion ? Duration.zero : const Duration(milliseconds: 320),
      curve: Curves.easeOutCubic,
      left: left,
      top: 0,
      width: railWidth,
      height: railHeight,
      child: Image.asset(
        'assets/icons/nav/nav_rail.png',
        width: railWidth,
        height: railHeight,
        fit: BoxFit.fill,
        // White filter: recolour the hump to the capsule surface colour while
        // preserving its alpha shape, so the two whites merge with no seam.
        color: color,
        colorBlendMode: BlendMode.srcIn,
        excludeFromSemantics: true,
      ),
    );
  }
}
