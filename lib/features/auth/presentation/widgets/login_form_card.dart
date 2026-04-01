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

const Color _cardBorderColor = Color(0x1AE6A032);

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
    final borderRadius = BorderRadius.circular(isDesktop ? 32 : 28);
    final padding = EdgeInsets.fromLTRB(
      isDesktop ? 40 : 32,
      isDesktop ? 36 : 32,
      isDesktop ? 40 : 32,
      isDesktop ? 36 : 32,
    );

    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFFFFFFFF), Color(0xFFFFFCF8)],
        ),
        borderRadius: borderRadius,
        border: Border.all(color: _cardBorderColor),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0A000000),
            blurRadius: 2,
            offset: Offset(0, 1),
          ),
          BoxShadow(
            color: Color(0x0FB46414),
            blurRadius: 12,
            offset: Offset(0, 4),
          ),
          BoxShadow(
            color: Color(0x1AC85A12),
            blurRadius: 48,
            offset: Offset(0, 16),
          ),
          BoxShadow(
            color: Color(0x0F000000),
            blurRadius: 80,
            offset: Offset(0, 32),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: borderRadius,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              height: 2.5,
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xFFFF7849), Color(0xFF0D9488)],
                ),
              ),
            ),
            Padding(
              padding: padding,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                mainAxisSize: MainAxisSize.min,
                children: [
                  const _HeadingBlock()
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
          ],
        ),
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
            hint: 'name@email.com or 09XXXXXXXXX',
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
          Container(
            decoration: BoxDecoration(
              color: const Color(0xFFF7F4F0),
              borderRadius: BorderRadius.circular(12),
            ),
            padding: const EdgeInsets.all(12),
            child: AgreementCheckboxes(
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
          LoginSubmitButton(
            isLoading: widget.isLoading,
            onPressed: _handleSubmit,
          ),
          const SizedBox(height: 12),
          const _PrivacyNotice(),
          const SizedBox(height: 18),
          Divider(height: 1, color: AppColors.primary.withValues(alpha: 0.12)),
          const SizedBox(height: 16),
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
  const _HeadingBlock();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          'Welcome back',
          style: AppTypography.displayLg.copyWith(
            fontSize: 32,
            fontWeight: FontWeight.w800,
            height: 1.08,
            letterSpacing: -0.32,
          ),
        ),
      ],
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

class _PrivacyNotice extends StatelessWidget {
  const _PrivacyNotice();

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Icon(Icons.verified_user, size: 12, color: AppColors.secondary),
        const SizedBox(width: 6),
        Flexible(
          child: Text(
            'Your privacy and safety are our top priority',
            style: AppTypography.caption.copyWith(
              fontSize: 11,
              color: AppColors.textMuted,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
          ),
        ),
      ],
    );
  }
}

class _CreateAccountPrompt extends StatelessWidget {
  const _CreateAccountPrompt({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: const BoxDecoration(
                  color: AppColors.primaryLight,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.person_add_alt_1_rounded,
                  size: 16,
                  color: AppColors.primary,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: RichText(
                  text: TextSpan(
                    style: AppTypography.bodySm.copyWith(
                      color: AppColors.textMuted,
                      height: 1.35,
                    ),
                    children: [
                      const TextSpan(text: 'New to Tander? '),
                      TextSpan(
                        text: 'Create an account',
                        style: AppTypography.bodySm.copyWith(
                          color: AppColors.primary,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const TextSpan(text: ' to get started'),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 8),
              const Icon(
                Icons.arrow_forward_rounded,
                size: 18,
                color: AppColors.primaryAccessible,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
