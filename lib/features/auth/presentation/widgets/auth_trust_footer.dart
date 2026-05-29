import 'package:flutter/material.dart';

/// Small lock-icon + reassurance text used near the bottom of registration
/// screens to signal data safety. Built for 60+ users who look for explicit
/// trust cues before submitting personal information.
///
/// Matches the existing footer in `ready_to_verify_screen.dart` so the
/// reassurance reads identically across the flow.
class AuthTrustFooter extends StatelessWidget {
  const AuthTrustFooter({
    this.message = 'Your data is securely encrypted and never shared.',
    super.key,
  });

  final String message;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(Icons.lock_outline, size: 16, color: Colors.grey[600]),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            message,
            style: TextStyle(fontSize: 14, color: Colors.grey[600], height: 1.3),
          ),
        ),
      ],
    );
  }
}
