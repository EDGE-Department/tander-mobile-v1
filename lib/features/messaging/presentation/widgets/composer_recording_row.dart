import 'package:flutter/material.dart';

import 'package:tander_flutter_v3/core/theme/app_colors.dart';
import 'package:tander_flutter_v3/core/theme/app_typography.dart';

const Color _orange = AppColors.primary;

/// Recording mode UI for the message composer.
///
/// Shows cancel button, waveform animation, timer, and send button.
class ComposerRecordingRow extends StatelessWidget {
  const ComposerRecordingRow({
    super.key,
    required this.recordingSeconds,
    required this.onCancel,
    required this.onSend,
  });

  final int recordingSeconds;
  final VoidCallback onCancel;
  final VoidCallback onSend;

  @override
  Widget build(BuildContext context) {
    final minutes = recordingSeconds ~/ 60;
    final seconds = recordingSeconds % 60;
    final timeLabel = '$minutes:${seconds.toString().padLeft(2, '0')}';

    return Row(
      children: [
        // Cancel
        GestureDetector(
          onTap: onCancel,
          child: Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              color: AppColors.danger.withValues(alpha: 0.08),
            ),
            child: const Icon(Icons.close, size: 16, color: AppColors.danger),
          ),
        ),
        const SizedBox(width: 12),
        // Recording dot
        Container(
          width: 8,
          height: 8,
          decoration: const BoxDecoration(
            shape: BoxShape.circle,
            color: AppColors.danger,
          ),
        ),
        const SizedBox(width: 8),
        // Mini waveform
        Row(
          children: List.generate(10, (index) {
            const heights = [6, 12, 8, 14, 10, 6, 11, 7, 13, 9];
            return Container(
              width: 2.5,
              height: heights[index].toDouble(),
              margin: const EdgeInsets.symmetric(horizontal: 1),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(2),
                color: AppColors.danger.withValues(alpha: 0.6),
              ),
            );
          }),
        ),
        const SizedBox(width: 8),
        Text(
          timeLabel,
          style: AppTypography.label.copyWith(
            fontSize: 15,
            fontWeight: FontWeight.w700,
            color: const Color(0xFF18110A),
          ),
        ),
        const Spacer(),
        // Send
        GestureDetector(
          onTap: onSend,
          child: Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              gradient: const LinearGradient(
                colors: [AppColors.success, Color(0xFF16A34A)],
              ),
              boxShadow: [
                BoxShadow(
                  color: AppColors.success.withValues(alpha: 0.30),
                  blurRadius: 20,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: const Center(
              child: Icon(Icons.send, size: 18, color: Colors.white),
            ),
          ),
        ),
      ],
    );
  }
}

/// Reusable circular action button for the composer.
class ComposerActionButton extends StatelessWidget {
  const ComposerActionButton({
    super.key,
    required this.onTap,
    required this.icon,
    this.gradient,
    this.color,
  });

  final VoidCallback onTap;
  final Widget icon;
  final Gradient? gradient;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          gradient: gradient,
          color: gradient == null ? color : null,
          boxShadow: gradient != null
              ? [
                  BoxShadow(
                    color: _orange.withValues(alpha: 0.30),
                    blurRadius: 20,
                    offset: const Offset(0, 6),
                  ),
                ]
              : null,
        ),
        child: Center(child: icon),
      ),
    );
  }
}
