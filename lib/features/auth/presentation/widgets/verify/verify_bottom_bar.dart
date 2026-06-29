import 'package:flutter/material.dart';
import 'package:tander_flutter_v3/core/theme/app_colors.dart';
import 'package:tander_flutter_v3/features/auth/presentation/widgets/verification/primary_action_button.dart';

class VerifyBottomBar extends StatelessWidget {
  const VerifyBottomBar({required this.onStart, super.key});
  final VoidCallback onStart;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Row(children: [
              Icon(Icons.lock_outline, size: 18, color: AppColors.textMuted),
              SizedBox(width: 8),
              Expanded(child: Text('Your data is encrypted and never shared.',
                  style: TextStyle(fontSize: 14, height: 1.35, color: AppColors.textMuted))),
            ]),
            const SizedBox(height: 12),
            PrimaryActionButton(
              label: 'Start Verification',
              icon: Icons.camera_alt_outlined,
              onPressed: onStart,
            ),
          ],
        ),
      ),
    );
  }
}
