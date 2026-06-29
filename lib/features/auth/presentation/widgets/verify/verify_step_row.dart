import 'package:flutter/material.dart';
import 'package:tander_flutter_v3/core/theme/app_colors.dart';

class VerifyStepRow extends StatelessWidget {
  const VerifyStepRow({
    required this.icon, required this.title, required this.description, super.key,
  });
  final IconData icon;
  final String title;
  final String description;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 40, height: 40,
            decoration: BoxDecoration(
              color: const Color(0xFF5BBFB3).withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(11),
            ),
            child: Icon(icon, size: 22, color: const Color(0xFF0F6E56)),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(
                    fontSize: 16, fontWeight: FontWeight.w600, color: Colors.black87)),
                const SizedBox(height: 2),
                Text(description, style: const TextStyle(
                    fontSize: 13, height: 1.3, color: AppColors.textMuted)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
