import 'package:flutter_test/flutter_test.dart';
import 'package:tander_flutter_v3/app/widgets/nav_geometry.dart';

void main() {
  group('railLeftForIndex', () {
    const barWidth = 360.0; // 5 columns => 72 each
    const railWidth = 1.4 * 72.0; // 100.8

    test('centers the rail on a middle column', () {
      final left = railLeftForIndex(
        index: 2,
        columnCount: 5,
        barWidth: barWidth,
        railWidth: railWidth,
      );
      // column 2 center = 72 * 2.5 = 180; left = 180 - 50.4 = 129.6
      expect(left, closeTo(129.6, 0.001));
    });

    test('clamps the first column so the rail never goes negative', () {
      final left = railLeftForIndex(
        index: 0,
        columnCount: 5,
        barWidth: barWidth,
        railWidth: railWidth,
      );
      // raw = 36 - 50.4 = -14.4 -> clamped to 0
      expect(left, 0.0);
    });

    test('clamps the last column to the right edge', () {
      final left = railLeftForIndex(
        index: 4,
        columnCount: 5,
        barWidth: barWidth,
        railWidth: railWidth,
      );
      // raw = 324 - 50.4 = 273.6; max = 360 - 100.8 = 259.2 -> clamped
      expect(left, closeTo(259.2, 0.001));
    });
  });

  group('activeIndexForLocation', () {
    const routes = [
      '/discover',
      '/connections',
      '/messages',
      '/tandy',
      '/profile',
    ];

    test('matches an exact route', () {
      expect(activeIndexForLocation('/messages', routes), 2);
    });
    test('matches a sub-route by prefix', () {
      expect(activeIndexForLocation('/tandy/cooking', routes), 3);
    });
    test('falls back to 0 for an unknown location', () {
      expect(activeIndexForLocation('/settings', routes), 0);
    });
  });
}
