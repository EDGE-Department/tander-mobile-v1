import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tander_flutter_v3/features/auth/presentation/widgets/verify/verify_tips_card.dart';

void main() {
  testWidgets('VerifyTipsCard expands to reveal tips on tap', (tester) async {
    await tester.pumpWidget(const MaterialApp(home: Scaffold(body: VerifyTipsCard())));
    expect(find.text('Find good lighting'), findsNothing);
    await tester.tap(find.text('Tips for a clear photo'));
    await tester.pumpAndSettle();
    expect(find.text('Find good lighting'), findsOneWidget);
  });
}
