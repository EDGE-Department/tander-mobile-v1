import 'package:flutter/material.dart';
import 'package:tander_flutter_v3/features/auth/presentation/widgets/verify/verify_step_row.dart';

class VerifyStepsCard extends StatelessWidget {
  const VerifyStepsCard({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: const [
          BoxShadow(color: Color(0x0F000000),
              blurRadius: 18, offset: Offset(0, 6)),
        ],
      ),
      padding: const EdgeInsets.all(18),
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text("Let's verify your identity",
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.w800,
                  height: 1.15, letterSpacing: -0.5, color: Colors.black87)),
          SizedBox(height: 6),
          Text('To keep our community safe, we make sure it’s really you.',
              style: TextStyle(fontSize: 15, height: 1.35, color: Colors.black54)),
          SizedBox(height: 10),
          VerifyStepRow(icon: Icons.badge_outlined, title: 'Scan your ID',
              description: 'Take a clear photo of your government-issued ID.'),
          VerifyStepRow(icon: Icons.check_circle_outline, title: 'Get approved',
              description: 'Fast and secure verification process.'),
        ],
      ),
    );
  }
}
