import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tander_flutter_v3/features/auth/presentation/widgets/verify/verify_hero.dart';

void main() {
  testWidgets('VerifyHero shows logo + wordmark and fires onBack', (tester) async {
    var backTapped = false;
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(body: VerifyHero(onBack: () => backTapped = true)),
    ));
    expect(find.text('Tander'), findsOneWidget);
    expect(find.bySemanticsLabel('Tander logo'), findsOneWidget);
    expect(find.byIcon(Icons.arrow_back_rounded), findsOneWidget);
    await tester.tap(find.byIcon(Icons.arrow_back_rounded));
    expect(backTapped, isTrue);
  });
}
