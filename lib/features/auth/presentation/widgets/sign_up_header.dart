import 'package:flutter/material.dart';

import '../../../../shared/widgets/fade_slide_transition.dart';
import '../../data/registration_constants.dart';

/// SignUp screen header with logo, title, identity verified badge, and subtitle.
class SignUpHeader extends StatelessWidget {
  final AnimationController entrance;
  final bool compact;
  final bool showStepIndicator;

  const SignUpHeader({
    super.key,
    required this.entrance,
    this.compact = false,
    this.showStepIndicator = true,
  });

  @override
  Widget build(BuildContext context) {
    final ts = MediaQuery.textScalerOf(context);
    final scale = ts.scale(1.0);
    final isHighScale = scale > 1.3;

    final logoSize = compact ? 64.0 : (isHighScale ? 56.0 : 80.0);
    final titleSize = isHighScale ? 26.0 : 32.0;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (showStepIndicator) ...[
          FadeSlideTransition(
            animation: entrance,
            interval: const Interval(0.02, 0.22, curve: Curves.easeOut),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(999),
                border:
                    Border.all(color: Colors.white.withValues(alpha: 0.18)),
              ),
              child: Text(
                'Step 1 of ${RegistrationConstants.stepLabels.length}  •  ${RegistrationConstants.stepLabels[0]} Setup',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: Colors.white.withValues(alpha: 0.95),
                ),
              ),
            ),
          ),
          const SizedBox(height: 10),
        ],
        // Logo
        FadeSlideTransition(
          animation: entrance,
          interval: const Interval(0.05, 0.25, curve: Curves.easeOut),
          child: Container(
            width: logoSize,
            height: logoSize,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.3),
                width: 3,
              ),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFFE67E22).withValues(alpha: 0.3),
                  blurRadius: 24,
                  spreadRadius: 4,
                ),
              ],
            ),
            child: Image.asset(
              'assets/icons/tander_icon.png',
              width: logoSize,
              height: logoSize,
              fit: BoxFit.contain,
            ),
          ),
        ),
        const SizedBox(height: 16),
        FadeSlideTransition(
          animation: entrance,
          interval: const Interval(0.15, 0.40, curve: Curves.easeOut),
          child: Text(
            'Create Account',
            style: TextStyle(
              fontSize: titleSize,
              fontWeight: FontWeight.w700,
              color: Colors.white,
              letterSpacing: 0.5,
            ),
            textAlign: TextAlign.center,
          ),
        ),
        const SizedBox(height: 12),
        FadeSlideTransition(
          animation: entrance,
          interval: const Interval(0.20, 0.45, curve: Curves.easeOut),
          child: const _IdentityVerifiedBadge(),
        ),
        const SizedBox(height: 12),
        FadeSlideTransition(
          animation: entrance,
          interval: const Interval(0.25, 0.50, curve: Curves.easeOut),
          child: Text(
            'Set up your secure login credentials\nto start your account safely',
            style: TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w500,
              color: Colors.white.withValues(alpha: 0.9),
              height: 1.4,
            ),
            textAlign: TextAlign.center,
          ),
        ),
      ],
    );
  }
}

/// Identity verified badge shown after passing ID scanner gate.
class _IdentityVerifiedBadge extends StatelessWidget {
  static const _greenColor = Color(0xFF10B981);

  const _IdentityVerifiedBadge();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
      decoration: BoxDecoration(
        color: _greenColor.withValues(alpha: 0.18),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: _greenColor.withValues(alpha: 0.5),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: _greenColor.withValues(alpha: 0.15),
            blurRadius: 12,
            spreadRadius: 1,
          ),
        ],
      ),
      child: const Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.verified_user_rounded, color: _greenColor, size: 18),
          SizedBox(width: 8),
          Text(
            'Identity Verified',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: _greenColor,
              letterSpacing: 0.3,
            ),
          ),
          SizedBox(width: 6),
          Icon(Icons.check_circle_rounded, color: _greenColor, size: 16),
        ],
      ),
    );
  }
}
