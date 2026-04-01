import 'package:flutter/material.dart';

import 'package:tander_flutter_v3/core/theme/app_colors.dart';
import 'package:tander_flutter_v3/core/theme/app_spacing.dart';
import 'package:tander_flutter_v3/core/theme/app_typography.dart';

// ── Constants (shared across forgot-password files) ──────────────────

/// Parchment background color matching web's `#F9F5F0`.
const Color parchmentBg = Color(0xFFF9F5F0);

/// Subtle primary border matching web's `rgba(230,126,34,0.18)`.
const Color primaryBorderSubtle = Color(0x2EE67E22);

/// Divider color matching web's `rgba(230,126,34,0.14)`.
const Color dividerColor = Color(0x24E67E22);

/// Contact method for password recovery.
enum IdentifierMethod { email, phone }

// ── Back-to-sign-in pill ─────────────────────────────────────────────

/// Pill-shaped "Back to sign in" button matching the web's top pill.
class BackToSignInPill extends StatelessWidget {
  const BackToSignInPill({required this.onPressed, super.key});

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerLeft,
      child: GestureDetector(
        onTap: onPressed,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: parchmentBg,
            borderRadius: BorderRadius.circular(999),
            border: Border.all(color: primaryBorderSubtle),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.arrow_back,
                size: 15,
                color: AppColors.textMuted,
              ),
              const SizedBox(width: AppSpacing.xs),
              Text(
                'Back to sign in',
                style: AppTypography.bodySm.copyWith(
                  fontWeight: FontWeight.w600,
                  color: AppColors.textMuted,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Brand header row ─────────────────────────────────────────────────

/// Recovery badge row shown at the top-right of the forgot-password form.
class ForgotPasswordBrandHeader extends StatelessWidget {
  const ForgotPasswordBrandHeader({super.key});

  @override
  Widget build(BuildContext context) {
    return MediaQuery(
      data: MediaQuery.of(context).copyWith(textScaler: TextScaler.noScaling),
      child: Align(
        alignment: Alignment.centerRight,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: AppColors.primaryLight,
            borderRadius: BorderRadius.circular(999),
            border: Border.all(color: const Color(0x38E67E22)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.lock,
                size: 12,
                color: AppColors.primaryAccessible,
              ),
              const SizedBox(width: 6),
              Text(
                'Secure Recovery',
                style: AppTypography.caption.copyWith(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: AppColors.primaryAccessible,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Step icon hero ───────────────────────────────────────────────────

/// Orange envelope icon in gradient rounded box with glow shadow.
class StepIconHero extends StatelessWidget {
  const StepIconHero({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 56,
      height: 56,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment(-0.5, -1),
          end: Alignment(0.5, 1),
          colors: [Color(0xFFF07040), Color(0xFFE86035)],
        ),
        borderRadius: BorderRadius.circular(18),
        boxShadow: const [
          BoxShadow(
            color: Color(0x73F07040),
            blurRadius: 28,
            offset: Offset(0, 8),
          ),
          BoxShadow(
            color: Color(0x14000000),
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: const Center(
        child: Icon(Icons.email, size: 26, color: Colors.white),
      ),
    );
  }
}

// ── Step indicator ───────────────────────────────────────────────────

/// Three numbered circles connected by lines: IDENTIFY, VERIFY, SECURE.
class StepIndicator extends StatelessWidget {
  const StepIndicator({super.key});

  static const _labels = ['IDENTIFY', 'VERIFY', 'SECURE'];

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        for (int index = 0; index < 3; index++) ...[
          if (index > 0) _Connector(isActive: index == 0),
          _StepNode(number: index + 1, isActive: index == 0),
        ],
      ],
    );
  }
}

class _Connector extends StatelessWidget {
  const _Connector({required this.isActive});
  final bool isActive;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 32,
      height: 2,
      margin: const EdgeInsets.only(bottom: 20, left: 4, right: 4),
      decoration: BoxDecoration(
        color: isActive ? AppColors.primary : const Color(0x2EE67E22),
        borderRadius: BorderRadius.circular(999),
      ),
    );
  }
}

class _StepNode extends StatelessWidget {
  const _StepNode({required this.number, required this.isActive});
  final int number;
  final bool isActive;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 28,
          height: 28,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: isActive ? AppColors.primaryLight : parchmentBg,
            border: Border.all(
              color: isActive ? AppColors.primary : const Color(0x38E67E22),
              width: 2,
            ),
            boxShadow: isActive
                ? const [
                    BoxShadow(
                      color: Color(0x1FE67E22),
                      blurRadius: 4,
                      spreadRadius: 4,
                    ),
                  ]
                : null,
          ),
          child: Center(
            child: Text(
              '$number',
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w700,
                color: isActive ? AppColors.primary : AppColors.textDisabled,
              ),
            ),
          ),
        ),
        const SizedBox(height: 6),
        Text(
          StepIndicator._labels[number - 1],
          style: TextStyle(
            fontSize: 9,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.72,
            color: isActive ? AppColors.primary : AppColors.textDisabled,
          ),
        ),
      ],
    );
  }
}

// ── Method selector ──────────────────────────────────────────────────

/// Email / Phone Number tab switcher with pill-style toggle.
class MethodSelector extends StatelessWidget {
  const MethodSelector({
    required this.selectedMethod,
    required this.onMethodChanged,
    super.key,
  });

  final IdentifierMethod selectedMethod;
  final ValueChanged<IdentifierMethod> onMethodChanged;

  @override
  Widget build(BuildContext context) {
    return MediaQuery(
      data: MediaQuery.of(context).copyWith(textScaler: TextScaler.noScaling),
      child: Container(
        padding: const EdgeInsets.all(6),
        decoration: BoxDecoration(
          color: parchmentBg,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: primaryBorderSubtle, width: 1.5),
        ),
        child: Row(
          children: [
            _MethodTab(
              label: 'Email',
              icon: Icons.email_outlined,
              isActive: selectedMethod == IdentifierMethod.email,
              onTap: () => onMethodChanged(IdentifierMethod.email),
            ),
            const SizedBox(width: 4),
            _MethodTab(
              label: 'Phone Number',
              icon: Icons.phone,
              isActive: selectedMethod == IdentifierMethod.phone,
              onTap: () => onMethodChanged(IdentifierMethod.phone),
            ),
          ],
        ),
      ),
    );
  }
}

class _MethodTab extends StatelessWidget {
  const _MethodTab({
    required this.label,
    required this.icon,
    required this.isActive,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final bool isActive;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: isActive ? Colors.white : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
            boxShadow: isActive
                ? const [
                    BoxShadow(
                      color: Color(0x29E67E22),
                      blurRadius: 6,
                      offset: Offset(0, 1),
                    ),
                  ]
                : null,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 15,
                color: isActive
                    ? AppColors.primary.withValues(alpha: 0.80)
                    : AppColors.textMuted.withValues(alpha: 0.45),
              ),
              const SizedBox(width: 10),
              Text(
                label,
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: isActive ? AppColors.textStrong : AppColors.textMuted,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
