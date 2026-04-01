import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import '../../../../core/theme/app_colors.dart';

/// Blocking dialog when user tries to register without agreeing to
/// Terms & Conditions and Data Privacy Policy.
class AgreementRequiredDialog extends StatelessWidget {
  final VoidCallback onViewTerms;
  final VoidCallback onViewPrivacy;
  final VoidCallback onDecline;
  final VoidCallback onAgree;

  const AgreementRequiredDialog({
    super.key,
    required this.onViewTerms,
    required this.onViewPrivacy,
    required this.onDecline,
    required this.onAgree,
  });

  @override
  Widget build(BuildContext context) {
    final screen = MediaQuery.sizeOf(context);
    final isLandscape = screen.width > screen.height;
    final isTablet = screen.shortestSide >= 600;

    final dialogPadding = isLandscape ? 24.0 : (isTablet ? 32.0 : 20.0);
    final verticalInset = isLandscape ? 40.0 : (isTablet ? 100.0 : 80.0);
    final spacing = isLandscape ? 10.0 : (isTablet ? 18.0 : 14.0);
    final iconSize = isLandscape ? 48.0 : 64.0;

    return Dialog(
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      insetPadding: EdgeInsets.symmetric(
        horizontal: 24,
        vertical: verticalInset,
      ),
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: isTablet ? 600 : 500,
          maxHeight: screen.height * 0.75,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Flexible(
              child: SingleChildScrollView(
                padding: EdgeInsets.all(dialogPadding),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: iconSize,
                      height: iconSize,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: LinearGradient(
                          colors: [
                            AppColors.secondary,
                            AppColors.secondaryHover,
                          ],
                        ),
                      ),
                      child: PhosphorIcon(
                        PhosphorIconsDuotone.shield,
                        size: iconSize * 0.5,
                        color: Colors.white,
                      ),
                    ),
                    SizedBox(height: spacing),
                    Text(
                      'Agreement Required',
                      style: TextStyle(
                        fontSize: isLandscape ? 20 : 22,
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFF111827),
                      ),
                      textAlign: TextAlign.center,
                    ),
                    SizedBox(height: spacing * 0.6),
                    Text(
                      'To continue using Tander, you must agree to our '
                      'Terms & Conditions and Data Privacy Policy.',
                      style: TextStyle(
                        fontSize: isLandscape ? 14 : 16,
                        fontWeight: FontWeight.w400,
                        color: const Color(0xFF4B5563),
                        height: isLandscape ? 1.3 : 1.4,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    SizedBox(height: spacing * 0.8),
                    _DocumentLink(
                      label: 'Terms & Conditions',
                      color: AppColors.secondaryHover,
                      onTap: onViewTerms,
                      isCompact: isLandscape,
                    ),
                    SizedBox(height: isLandscape ? 6 : 8),
                    _DocumentLink(
                      label: 'Data Privacy Policy',
                      color: AppColors.primaryHover,
                      onTap: onViewPrivacy,
                      isCompact: isLandscape,
                    ),
                    SizedBox(height: spacing * 0.8),
                    Row(
                      children: [
                        Expanded(
                          child: ConstrainedBox(
                            constraints: const BoxConstraints(minHeight: 48),
                            child: OutlinedButton(
                              onPressed: onDecline,
                              style: OutlinedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(
                                  vertical: 12,
                                  horizontal: 8,
                                ),
                                side: const BorderSide(
                                  color: Color(0xFFD1D5DB),
                                  width: 1.5,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(100),
                                ),
                              ),
                              child: const FittedBox(
                                fit: BoxFit.scaleDown,
                                child: Text(
                                  'Decline',
                                  style: TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w600,
                                    color: Color(0xFF4B5563),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          flex: 2,
                          child: _AgreeButton(onPressed: onAgree),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            Padding(
              padding: EdgeInsets.fromLTRB(
                dialogPadding,
                spacing * 0.5,
                dialogPadding,
                dialogPadding,
              ),
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  PhosphorIcon(PhosphorIconsDuotone.info,
                      size: 14, color: Color(0xFF6B7280)),
                  SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      'You cannot access the app without agreeing to both policies.',
                      style: TextStyle(
                        fontSize: 14,
                        color: Color(0xFF6B7280),
                        height: 1.3,
                      ),
                      textAlign: TextAlign.center,
                      maxLines: 2,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DocumentLink extends StatelessWidget {
  final String label;
  final Color color;
  final VoidCallback onTap;
  final bool isCompact;

  const _DocumentLink({
    required this.label,
    required this.color,
    required this.onTap,
    this.isCompact = false,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: TextButton(
        onPressed: onTap,
        style: TextButton.styleFrom(
          backgroundColor: color.withValues(alpha: 0.1),
          padding: EdgeInsets.symmetric(vertical: isCompact ? 10 : 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: isCompact ? 14 : 16,
            fontWeight: FontWeight.w600,
            color: color,
          ),
        ),
      ),
    );
  }
}

class _AgreeButton extends StatelessWidget {
  final VoidCallback onPressed;
  const _AgreeButton({required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return ConstrainedBox(
      constraints: const BoxConstraints(minHeight: 48),
      child: DecoratedBox(
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFFFF7849), Color(0xFFFF5C35)],
          ),
          borderRadius: BorderRadius.circular(100),
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onPressed,
            borderRadius: BorderRadius.circular(100),
            child: const Padding(
              padding: EdgeInsets.symmetric(vertical: 12, horizontal: 12),
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(PhosphorIconsBold.check,
                        size: 18, color: Colors.white),
                    SizedBox(width: 6),
                    Text(
                      'I Agree to Both',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
