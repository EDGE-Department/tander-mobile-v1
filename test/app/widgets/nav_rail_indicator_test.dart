import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tander_flutter_v3/app/widgets/nav_geometry.dart';
import 'package:tander_flutter_v3/app/widgets/nav_rail_indicator.dart';

void main() {
  testWidgets('rail is positioned at the geometry helper offset', (
    tester,
  ) async {
    const barWidth = 360.0, railWidth = 100.8, railHeight = 28.0;
    await tester.pumpWidget(
      const MaterialApp(
        home: SizedBox(
          width: barWidth,
          height: 80,
          child: Stack(
            children: [
              NavRailIndicator(
                activeIndex: 2,
                columnCount: 5,
                barWidth: barWidth,
                railWidth: railWidth,
                railHeight: railHeight,
                reduceMotion: true,
              ),
            ],
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    final positioned = tester.widget<AnimatedPositioned>(
      find.byType(AnimatedPositioned),
    );
    final expected = railLeftForIndex(
      index: 2,
      columnCount: 5,
      barWidth: barWidth,
      railWidth: railWidth,
    );
    expect(positioned.left, closeTo(expected, 0.001));
    expect(positioned.width, closeTo(railWidth, 0.001));
  });
}
