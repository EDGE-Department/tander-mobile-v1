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
}) {
  final columnWidth = barWidth / columnCount;
  final centerX = columnWidth * (index + 0.5);
  final rawLeft = centerX - railWidth / 2;
  final maxLeft = (barWidth - railWidth).clamp(0.0, double.infinity);
  return rawLeft.clamp(0.0, maxLeft);
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
