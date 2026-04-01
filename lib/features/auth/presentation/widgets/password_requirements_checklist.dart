import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import '../../../../core/theme/app_colors.dart';

/// Animated checklist showing password strength requirements.
class PasswordRequirementsChecklist extends StatelessWidget {
  final String password;
  final String? confirmPassword;

  const PasswordRequirementsChecklist({
    super.key,
    required this.password,
    this.confirmPassword,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _RequirementRow(
          met: password.length >= 8,
          label: 'At least 8 characters',
        ),
        _RequirementRow(
          met: RegExp(r'[A-Z]').hasMatch(password),
          label: 'Contains an uppercase letter',
        ),
        _RequirementRow(
          met: RegExp(r'[0-9]').hasMatch(password),
          label: 'Contains a number',
        ),
        if (confirmPassword != null && confirmPassword!.isNotEmpty)
          _RequirementRow(
            met: password == confirmPassword && password.isNotEmpty,
            label: 'Passwords match',
          ),
      ],
    );
  }
}

class _RequirementRow extends StatelessWidget {
  final bool met;
  final String label;

  const _RequirementRow({required this.met, required this.label});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        children: [
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 200),
            child: met
                ? Icon(
                    PhosphorIconsRegular.checkCircle,
                    key: const ValueKey<bool>(true),
                    color: AppColors.secondary,
                    size: 18,
                  )
                : const Icon(
                    PhosphorIconsRegular.circle,
                    key: ValueKey<bool>(false),
                    color: Color(0xFF9CA3AF),
                    size: 18,
                  ),
          ),
          const SizedBox(width: 8),
          Text(
            label,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w400,
              color: met ? AppColors.secondaryHover : const Color(0xFF6B7280),
            ),
          ),
        ],
      ),
    );
  }
}
