import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tander_flutter_v3/features/auth/presentation/widgets/verify/verify_bottom_bar.dart';

void main() {
  testWidgets('VerifyBottomBar fires onStart', (tester) async {
    var started = false;
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(body: VerifyBottomBar(onStart: () => started = true)),
    ));
    expect(find.text('Start Verification'), findsOneWidget);
    await tester.tap(find.text('Start Verification'));
    expect(started, isTrue);
  });
}
