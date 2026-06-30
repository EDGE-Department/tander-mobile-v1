import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tander_flutter_v3/app/widgets/bottom_nav_bar.dart';
import 'package:tander_flutter_v3/app/widgets/nav_rail_indicator.dart';

Widget _harness({required int activeIndex, int Function(String)? badgeFor}) {
  return MaterialApp(
    home: Scaffold(
      bottomNavigationBar: BottomNavBarView(
        activeIndex: activeIndex,
        reduceMotion: true,
        badgeFor: badgeFor ?? (_) => 0,
        onTap: (_) {},
      ),
    ),
  );
}

bool _isNavCell(Widget w) =>
    w.key is ValueKey && '${(w.key as ValueKey).value}'.startsWith('nav-cell');

void main() {
  testWidgets('renders 5 tab cells and exactly one rail', (tester) async {
    await tester.pumpWidget(_harness(activeIndex: 2));
    await tester.pumpAndSettle();

    expect(find.byWidgetPredicate(_isNavCell), findsNWidgets(5));
    expect(find.byType(NavRailIndicator), findsOneWidget);
  });

  testWidgets('passes the active index through to the rail', (tester) async {
    await tester.pumpWidget(_harness(activeIndex: 3));
    await tester.pumpAndSettle();

    final indicator = tester.widget<NavRailIndicator>(
      find.byType(NavRailIndicator),
    );
    expect(indicator.activeIndex, 3);
  });

  testWidgets('shows a badge only on tabs with unread counts', (tester) async {
    await tester.pumpWidget(
      _harness(activeIndex: 2, badgeFor: (id) => id == 'messages' ? 4 : 0),
    );
    await tester.pumpAndSettle();

    expect(find.text('4'), findsOneWidget);
  });
}
