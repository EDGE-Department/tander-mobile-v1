import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import '../../../../core/theme/app_colors.dart';
import '../../data/registration_method.dart';

/// Animated segmented control for Phone | Email registration.
///
/// Orange slider animates between the two options. 56px height,
/// elder-friendly touch targets.
class MethodSelector extends StatelessWidget {
  final RegistrationMethod selected;
  final ValueChanged<RegistrationMethod> onChanged;
  final bool enabled;

  const MethodSelector({
    super.key,
    required this.selected,
    required this.onChanged,
    this.enabled = true,
  });

  @override
  Widget build(BuildContext context) {
    final isPhone = selected == RegistrationMethod.phone;

    return Container(
      height: 56,
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: const Color(0xFFF3F4F6),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE5E7EB), width: 1),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final tabWidth = constraints.maxWidth / 2;
          return Stack(
            children: [
              // Animated slider
              AnimatedAlign(
                duration: const Duration(milliseconds: 250),
                curve: Curves.easeInOut,
                alignment:
                    isPhone ? Alignment.centerLeft : Alignment.centerRight,
                child: Container(
                  width: tabWidth,
                  height: 48,
                  decoration: BoxDecoration(
                    color: enabled ? AppColors.primary : const Color(0xFF9CA3AF),
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: (enabled
                                ? AppColors.primary
                                : const Color(0xFF9CA3AF))
                            .withValues(alpha: 0.3),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                ),
              ),
              // Tabs
              Row(
                children: [
                  _Tab(
                    icon: PhosphorIconsRegular.phone,
                    label: 'Phone',
                    isSelected: isPhone,
                    onTap: enabled
                        ? () {
                            if (!isPhone) {
                              HapticFeedback.selectionClick();
                              onChanged(RegistrationMethod.phone);
                            }
                          }
                        : null,
                  ),
                  _Tab(
                    icon: PhosphorIconsRegular.envelope,
                    label: 'Email',
                    isSelected: !isPhone,
                    onTap: enabled
                        ? () {
                            if (isPhone) {
                              HapticFeedback.selectionClick();
                              onChanged(RegistrationMethod.email);
                            }
                          }
                        : null,
                  ),
                ],
              ),
            ],
          );
        },
      ),
    );
  }
}

class _Tab extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isSelected;
  final VoidCallback? onTap;

  const _Tab({
    required this.icon,
    required this.label,
    required this.isSelected,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final color = isSelected ? Colors.white : const Color(0xFF6B7280);

    return Expanded(
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: SizedBox(
          height: 48,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 20, color: color),
              const SizedBox(width: 8),
              Text(
                label,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: color,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
