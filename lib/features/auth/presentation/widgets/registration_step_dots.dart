import 'package:flutter/material.dart';

import 'package:tander_flutter_v3/core/theme/app_colors.dart';

/// Animated step progress dots for the registration flow.
///
/// Active step = orange pill (24x8px), completed = orange dot (8x8px),
/// future = gray dot (8x8px). AnimatedContainer with 300ms transitions.
class RegistrationStepDots extends StatelessWidget {
  final int currentStep;
  final int totalSteps;

  const RegistrationStepDots({
    super.key,
    required this.currentStep,
    required this.totalSteps,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(totalSteps, (index) {
        final stepNumber = index + 1;
        final isActive = stepNumber == currentStep;
        final isCompleted = stepNumber < currentStep;

        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 3),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeInOut,
            width: isActive ? 24 : 8,
            height: 8,
            decoration: BoxDecoration(
              color: isActive || isCompleted
                  ? AppColors.primary
                  : const Color(0xFFD1D5DB),
              borderRadius: BorderRadius.circular(4),
            ),
          ),
        );
      }),
    );
  }
}
