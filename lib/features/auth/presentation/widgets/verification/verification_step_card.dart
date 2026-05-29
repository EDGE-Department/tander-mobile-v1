// lib/features/auth/presentation/widgets/verification/verification_step_card.dart
import 'package:flutter/material.dart';

class VerificationStepCard extends StatelessWidget {
  final String title;
  final String description;
  final IconData icon;
  final int stepNumber;
  final bool isSmallPhone;

  const VerificationStepCard({
    super.key,
    required this.title,
    required this.description,
    required this.icon,
    required this.stepNumber,
    this.isSmallPhone = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: EdgeInsets.all(isSmallPhone ? 12 : 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFF5BBFB3).withValues(alpha: 0.1), // Cool teal
              shape: BoxShape.circle,
            ),
            child: Icon(
              icon,
              color: const Color(0xFF5BBFB3),
              size: isSmallPhone ? 24 : 32,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: isSmallPhone ? 16 : 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  description,
                  style: TextStyle(
                    fontSize: isSmallPhone ? 13 : 14,
                    color: Colors.black54,
                    height: 1.3,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
