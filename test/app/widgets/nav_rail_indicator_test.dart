import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tander_flutter_v3/app/widgets/nav_rail_indicator.dart';

void main() {
  testWidgets('renders the rail image at the given size', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: Center(
            child: NavRailIndicator(
              activeIndex: 2,
              width: 100,
              height: 30,
              reduceMotion: true,
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    final img = tester.widget<Image>(find.byType(Image));
    expect(img.width, 100);
    expect(img.height, 30);
  });
}
