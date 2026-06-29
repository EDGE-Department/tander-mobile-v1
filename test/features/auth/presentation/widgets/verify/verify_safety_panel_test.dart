import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tander_flutter_v3/features/auth/presentation/widgets/verify/verify_safety_panel.dart';

void main() {
  testWidgets('VerifySafetyPanel renders trust points', (tester) async {
    await tester.pumpWidget(const MaterialApp(home: Scaffold(body: VerifySafetyPanel())));
    expect(find.text('Simple steps for your safety'), findsOneWidget);
    expect(find.text('Secure'), findsOneWidget);
    expect(find.text('Trusted'), findsOneWidget);
    expect(find.text('Community Safe'), findsOneWidget);
  });
}
