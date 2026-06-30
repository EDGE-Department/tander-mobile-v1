/// Pure geometry helpers for the bottom nav bar's rail indicator.
///
/// These are deliberately Flutter-free so they can be unit-tested in isolation
/// and act as the single source of truth for the rail's guardrailed position.
library;

/// Left offset (in logical px, from the bar's left edge) for the rail
/// indicator so it is centered on [index]'s column, clamped to stay fully
/// inside the bar. This is the single source of truth for the guardrail.
double railLeftForIndex({
  required int index,
  required int columnCount,
  required double barWidth,
  required double railWidth,
  double margin = 0,
  List<double>? centerFractions,
}) {
  // Columns live inside a [margin]-inset content area, so the rail and the
  // icon row (which uses the same inset) always share column centres. When
  // [centerFractions] is given, columns sit at those fractions of the content
  // width instead of being evenly spaced.
  final contentWidth = barWidth - 2 * margin;
  final double centerX;
  if (centerFractions != null) {
    centerX = margin + centerFractions[index] * contentWidth;
  } else {
    centerX = margin + (contentWidth / columnCount) * (index + 0.5);
  }
  final rawLeft = centerX - railWidth / 2;
  final lo = margin;
  final hi = barWidth - railWidth - margin;
  return rawLeft.clamp(lo, hi < lo ? lo : hi);
}

/// Index of the active tab for a GoRouter [location], matching either an
/// exact route or a sub-route prefix. Falls back to 0.
int activeIndexForLocation(String location, List<String> routes) {
  for (var i = 0; i < routes.length; i++) {
    if (location == routes[i] || location.startsWith('${routes[i]}/')) {
      return i;
    }
  }
  return 0;
}
