import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import 'package:tander_flutter_v3/core/theme/app_colors.dart';
import 'package:tander_flutter_v3/core/theme/app_curves.dart';
import 'package:tander_flutter_v3/core/theme/app_typography.dart';
import 'package:tander_flutter_v3/features/auth/presentation/widgets/agreement_checkboxes.dart';
import 'package:tander_flutter_v3/features/auth/presentation/widgets/login_form_inputs.dart';
import 'package:tander_flutter_v3/features/auth/presentation/widgets/login_submit_button.dart';
import 'package:tander_flutter_v3/shared/widgets/data_privacy_sheet.dart';
import 'package:tander_flutter_v3/shared/widgets/terms_conditions_sheet.dart';

/// Web: border-white/20 = rgba(255,255,255,0.20).
const Color _cardBorderColor = Color(0x33FFFFFF);

enum LoginFormCardLayout { mobile, tablet, desktop }

/// Shared white login card mirrored from the web surface.
///
/// This widget is intentionally limited to the inner card only. Outer shells
/// such as the mobile parchment sheet or the landscape right-panel background
/// are owned by the screen-level layouts.
class LoginFormCard extends StatefulWidget {
  const LoginFormCard({
    required this.formKey,
    required this.emailController,
    required this.passwordController,
    required this.emailFocusNode,
    required this.passwordFocusNode,
    required this.isPasswordVisible,
    required this.isLoading,
    required this.errorMessage,
    required this.onTogglePassword,
    required this.onSubmit,
    required this.onForgotPassword,
    required this.onRegister,
    this.layout = LoginFormCardLayout.mobile,
    super.key,
  });

  final GlobalKey<FormState> formKey;
  final TextEditingController emailController;
  final TextEditingController passwordController;
  final FocusNode emailFocusNode;
  final FocusNode passwordFocusNode;
  final bool isPasswordVisible;
  final bool isLoading;
  final String? errorMessage;
  final VoidCallback onTogglePassword;
  final VoidCallback onSubmit;
  final VoidCallback onForgotPassword;
  final VoidCallback onRegister;
  final LoginFormCardLayout layout;

  @override
  State<LoginFormCard> createState() => _LoginFormCardState();
}

class _LoginFormCardState extends State<LoginFormCard> {
  bool _agreedToTerms = false;
  bool _agreedToPrivacy = false;
  bool _agreementError = false;

  void _handleSubmit() {
    if (!_agreedToTerms || !_agreedToPrivacy) {
      setState(() => _agreementError = true);
      return;
    }
    widget.onSubmit();
  }

  @override
  Widget build(BuildContext context) {
    final isDesktop = widget.layout == LoginFormCardLayout.desktop;
    final borderRadius = BorderRadius.circular(32);
    final padding = EdgeInsets.symmetric(
      horizontal: isDesktop ? 40 : 24,
      vertical: 32,
    );

    return ClipRRect(
      borderRadius: borderRadius,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Orange accent bar at top
          Container(
            height: 6,
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFFF07040), Color(0xFFE86035)],
              ),
            ),
          ),
          // White card content
          Container(
            decoration: const BoxDecoration(color: Color(0xFFFFFBF8)),
            child: Padding(
              padding: padding,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                mainAxisSize: MainAxisSize.min,
                children: [
                  _HeadingBlock(layout: widget.layout)
                      .animate()
                      .fadeIn(
                        duration: 550.ms,
                        delay: 510.ms,
                        curve: AppCurves.premiumEase,
                      )
                      .slideY(begin: 0.08, curve: AppCurves.premiumEase),
                  const SizedBox(height: 24),
                  AnimatedSize(
                    duration: AppDurations.base,
                    curve: AppCurves.premiumEase,
                    child: widget.errorMessage != null
                        ? Padding(
                            padding: const EdgeInsets.only(bottom: 16),
                            child: _ApiErrorBanner(
                              key: ValueKey(widget.errorMessage),
                              message: widget.errorMessage!,
                            ),
                          )
                        : const SizedBox.shrink(),
                  ),
                  _buildForm()
                      .animate()
                      .fadeIn(
                        duration: 550.ms,
                        delay: 600.ms,
                        curve: AppCurves.premiumEase,
                      )
                      .slideY(begin: 0.06, curve: AppCurves.premiumEase),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildForm() {
    return Form(
      key: widget.formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          LoginTextField(
            label: 'Email or phone number',
            hint: 'Enter your contact info',
            controller: widget.emailController,
            focusNode: widget.emailFocusNode,
            prefixIcon: Icons.mail_outline,
            keyboardType: TextInputType.text,
            textInputAction: TextInputAction.next,
            validator: _validateIdentifier,
          ),
          const SizedBox(height: 20),
          LoginPasswordField(
            controller: widget.passwordController,
            focusNode: widget.passwordFocusNode,
            isPasswordVisible: widget.isPasswordVisible,
            onToggleVisibility: widget.onTogglePassword,
            onForgotPassword: widget.onForgotPassword,
            textInputAction: TextInputAction.done,
          ),
          const SizedBox(height: 20),
          AgreementCheckboxes(
            agreedToTerms: _agreedToTerms,
            agreedToPrivacy: _agreedToPrivacy,
            onTermsChanged: (value) => setState(() {
              _agreedToTerms = value;
              _agreementError = false;
            }),
            onPrivacyChanged: (value) => setState(() {
              _agreedToPrivacy = value;
              _agreementError = false;
            }),
            onTermsTapped: () => TermsConditionsSheet.show(context),
            onPrivacyTapped: () => DataPrivacySheet.show(context),
          ),
          AnimatedSize(
            duration: const Duration(milliseconds: 200),
            curve: AppCurves.premiumEase,
            child: _agreementError
                ? Padding(
                    padding: const EdgeInsets.only(top: 6, left: 8),
                    child: Text(
                      'Please agree to both Terms and Privacy Policy',
                      style: AppTypography.caption.copyWith(
                        color: AppColors.danger,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  )
                : const SizedBox.shrink(),
          ),
          const SizedBox(height: 20),
          const SizedBox(height: 8),
          LoginSubmitButton(
            isLoading: widget.isLoading,
            onPressed: _handleSubmit,
          ),
          // Web: trust badges right after button, then register link
          const _PrivacyNotice(),
          const SizedBox(height: 20),
          _CreateAccountPrompt(onTap: widget.onRegister),
        ],
      ),
    );
  }

  static String? _validateIdentifier(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Please enter your email or phone number';
    }
    return null;
  }
}

class _HeadingBlock extends StatelessWidget {
  const _HeadingBlock({required this.layout});

  final LoginFormCardLayout layout;

  @override
  Widget build(BuildContext context) {
    final isDesktop = layout == LoginFormCardLayout.desktop;
    return Text(
      'Sign in',
      textAlign: isDesktop ? TextAlign.left : TextAlign.center,
      style: AppTypography.displayLg.copyWith(
        fontSize: isDesktop ? 30 : 28,
        fontWeight: FontWeight.w900,
        height: 1.1,
        letterSpacing: -0.5,
      ),
    );
  }
}

class _ApiErrorBanner extends StatefulWidget {
  const _ApiErrorBanner({required this.message, super.key});

  final String message;

  @override
  State<_ApiErrorBanner> createState() => _ApiErrorBannerState();
}

class _ApiErrorBannerState extends State<_ApiErrorBanner>
    with SingleTickerProviderStateMixin {
  late final AnimationController _entranceController;
  late final Animation<double> _opacity;
  late final Animation<Offset> _slide;

  @override
  void initState() {
    super.initState();
    _entranceController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 250),
    );
    _opacity = CurvedAnimation(
      parent: _entranceController,
      curve: AppCurves.premiumEase,
    );
    _slide = Tween<Offset>(begin: const Offset(0, -8), end: Offset.zero)
        .animate(
          CurvedAnimation(
            parent: _entranceController,
            curve: AppCurves.premiumEase,
          ),
        );
    _entranceController.forward();
  }

  @override
  void dispose() {
    _entranceController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedSize(
      duration: AppDurations.base,
      curve: AppCurves.premiumEase,
      child: AnimatedBuilder(
        animation: _entranceController,
        builder: (_, child) => Opacity(
          opacity: _opacity.value,
          child: Transform.translate(offset: _slide.value, child: child),
        ),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: AppColors.dangerLight,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.danger.withValues(alpha: 0.20)),
          ),
          child: Text(
            widget.message,
            style: AppTypography.bodySm.copyWith(
              fontWeight: FontWeight.w500,
              color: AppColors.danger,
            ),
          ),
        ),
      ),
    );
  }
}

/// Web: trust badges — "ID Verified" + "Secure" with teal icons.
class _PrivacyNotice extends StatelessWidget {
  const _PrivacyNotice();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16),
      decoration: BoxDecoration(
        border: Border(top: BorderSide(color: Colors.grey.shade200)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.check_circle, size: 22, color: AppColors.secondary),
          const SizedBox(width: 10),
          Text(
            'ID VERIFIED',
            style: AppTypography.caption.copyWith(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              letterSpacing: 1.5,
              color: AppColors.textMuted,
            ),
          ),
          const SizedBox(width: 32),
          const Icon(Icons.verified_user, size: 22, color: AppColors.secondary),
          const SizedBox(width: 10),
          Text(
            'SECURE',
            style: AppTypography.caption.copyWith(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              letterSpacing: 1.5,
              color: AppColors.textMuted,
            ),
          ),
        ],
      ),
    );
  }
}

class _CreateAccountPrompt extends StatelessWidget {
  const _CreateAccountPrompt({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    // Web: text-center, text-[16px] font-bold text-gray-500
    return GestureDetector(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: RichText(
          textAlign: TextAlign.center,
          text: TextSpan(
            style: AppTypography.body.copyWith(
              fontWeight: FontWeight.w700,
              color: AppColors.textMuted,
            ),
            children: [
              const TextSpan(text: 'New to Tander? '),
              TextSpan(
                text: 'Join our community',
                style: AppTypography.body.copyWith(
                  fontWeight: FontWeight.w700,
                  color: AppColors.primary,
                  decoration: TextDecoration.underline,
                  decorationThickness: 2,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
