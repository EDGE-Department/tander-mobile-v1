import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tander_flutter_v3/features/auth/presentation/screens/ready_to_verify_screen.dart';

void main() {
  testWidgets('renders single-column at 320x568 without overflow', (tester) async {
    tester.view.physicalSize = const Size(320, 568);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(const MaterialApp(home: ReadyToVerifyScreen()));
    expect(tester.takeException(), isNull);
    expect(find.text('Start Verification'), findsOneWidget);
    expect(find.byIcon(Icons.arrow_back_rounded), findsOneWidget);
  });

  testWidgets('renders tablet-portrait at 768x1024 without overflow', (tester) async {
    tester.view.physicalSize = const Size(768, 1024);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(const MaterialApp(home: ReadyToVerifyScreen()));
    expect(tester.takeException(), isNull);
    expect(find.text('Start Verification'), findsOneWidget);
  });
}
