import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tander_flutter_v3/features/auth/presentation/widgets/verify/verify_steps_card.dart';

void main() {
  testWidgets('VerifyStepsCard shows headline and both steps, no chevrons', (tester) async {
    await tester.pumpWidget(const MaterialApp(
      home: Scaffold(body: VerifyStepsCard()),
    ));
    expect(find.text("Let's verify your identity"), findsOneWidget);
    expect(find.text('Scan your ID'), findsOneWidget);
    expect(find.text('Get approved'), findsOneWidget);
    expect(find.byIcon(Icons.chevron_right), findsNothing);
  });
}
