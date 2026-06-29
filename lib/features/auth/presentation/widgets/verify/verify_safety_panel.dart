import 'package:flutter/material.dart';
import 'package:tander_flutter_v3/features/auth/presentation/widgets/verify/verify_safety_content.dart';

/// Right pane shown in the tablet-landscape two-pane layout (width >= 1024).
/// Wraps [VerifySafetyContent] in a scrollable padded container.
class VerifySafetyPanel extends StatelessWidget {
  const VerifySafetyPanel({super.key});

  @override
  Widget build(BuildContext context) {
    return const SingleChildScrollView(
      padding: EdgeInsets.all(40),
      child: VerifySafetyContent(),
    );
  }
}
