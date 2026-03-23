import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import 'package:tander_flutter_v3/core/theme/app_colors.dart';
import 'package:tander_flutter_v3/core/theme/app_radius.dart';
import 'package:tander_flutter_v3/core/theme/app_shadows.dart';
import 'package:tander_flutter_v3/core/theme/app_spacing.dart';
import 'package:tander_flutter_v3/core/theme/app_typography.dart';
import 'package:tander_flutter_v3/features/auth/presentation/providers/auth_providers.dart';
import 'package:tander_flutter_v3/shared/constants/routes.dart';
import 'package:tander_flutter_v3/shared/widgets/tander_button.dart';
import 'package:tander_flutter_v3/shared/widgets/tander_text_field.dart';
import 'package:tander_flutter_v3/shared/widgets/tander_toast.dart';

/// Forgot password screen — collects user email and sends a reset code.
///
/// Matches the web's mobile layout: warm gradient background, icon hero,
/// heading, form card with email field, success state with navigation to OTP.
class ForgotPasswordScreen extends ConsumerStatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  ConsumerState<ForgotPasswordScreen> createState() =>
      _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends ConsumerState<ForgotPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _emailFocusNode = FocusNode();

  bool _isLoading = false;
  bool _isCodeSent = false;

  @override
  void dispose() {
    _emailController.dispose();
    _emailFocusNode.dispose();
    super.dispose();
  }

  // -- Validation -----------------------------------------------------------

  String? _validateEmail(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Please enter your email address';
    }
    final emailPattern = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');
    if (!emailPattern.hasMatch(value.trim())) {
      return 'Enter a valid email address (name@email.com)';
    }
    return null;
  }

  // -- Actions --------------------------------------------------------------

  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    final repository = ref.read(authRepositoryProvider);
    final email = _emailController.text.trim();
    final resetResult = await repository.requestPasswordReset(email: email);

    if (!mounted) return;

    resetResult.when(
      success: (_) {
        setState(() {
          _isLoading = false;
          _isCodeSent = true;
        });
      },
      failure: (exception) {
        setState(() => _isLoading = false);
        TanderToastOverlay.show(
          context,
          TanderToastData(
            message: exception.userMessage,
            variant: TanderToastVariant.error,
          ),
        );
      },
    );
  }

  void _navigateToOtp() {
    context.push(
      AppRoutes.otpVerification,
      extra: {
        'email': _emailController.text.trim(),
        'type': 'PASSWORD_RESET',
      },
    );
  }

  // -- Build ----------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: DecoratedBox(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [AppColors.primaryLight, AppColors.secondaryLight],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              _buildBackButton(),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.lg,
                    vertical: AppSpacing.xl,
                  ),
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 420),
                    child:
                        _isCodeSent ? _buildSuccessState() : _buildFormContent(),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // -- Back button ----------------------------------------------------------

  Widget _buildBackButton() {
    return Align(
      alignment: Alignment.centerLeft,
      child: Padding(
        padding: const EdgeInsets.only(
          left: AppSpacing.sm,
          top: AppSpacing.xs,
        ),
        child: IconButton(
          onPressed: () => context.pop(),
          icon: const Icon(Icons.arrow_back_rounded),
          iconSize: 24,
          color: AppColors.textStrong,
          tooltip: 'Go back',
          constraints: const BoxConstraints(
            minWidth: AppSpacing.touchComfortable,
            minHeight: AppSpacing.touchComfortable,
          ),
        ),
      ),
    );
  }

  // -- Form content ---------------------------------------------------------

  Widget _buildFormContent() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        _buildIconHero(),
        const SizedBox(height: AppSpacing.lg),
        _buildHeading(),
        const SizedBox(height: AppSpacing.xl),
        _buildFormCard(),
      ],
    );
  }

  /// Icon hero: w-14 h-14 rounded-[18px] gradient, glow shadow
  Widget _buildIconHero() {
    return Container(
      width: 72,
      height: 72,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment(-0.7, -1),
          end: Alignment(0.7, 1),
          colors: [AppColors.primary, Color(0xFFD06A18)],
        ),
        borderRadius: AppRadius.borderXl,
        boxShadow: AppShadows.warmMd,
      ),
      child: const Icon(
        PhosphorIconsFill.envelope,
        size: 36,
        color: AppColors.textInverse,
      ),
    );
  }

  Widget _buildHeading() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          'Forgot your password?',
          style: AppTypography.h1,
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: AppSpacing.xs),
        Text(
          "Enter your email and we'll send you a code",
          style: AppTypography.body.copyWith(color: AppColors.textMuted),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildFormCard() {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: AppRadius.borderXl,
        boxShadow: AppShadows.warmLg,
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TanderTextField(
                label: 'Email address',
                hint: 'name@email.com',
                controller: _emailController,
                focusNode: _emailFocusNode,
                keyboardType: TextInputType.emailAddress,
                textInputAction: TextInputAction.done,
                prefixIcon: Icons.email_outlined,
                validator: _validateEmail,
              ),
              const SizedBox(height: AppSpacing.lg),
              TanderButton(
                label: 'Send Reset Code',
                onPressed: _isLoading ? null : _submitForm,
                isLoading: _isLoading,
                icon: Icons.arrow_forward_rounded,
                iconPosition: IconPosition.trailing,
              ),
              const SizedBox(height: AppSpacing.md),
              _buildSecurityNote(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSecurityNote() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Icon(
          Icons.shield_outlined,
          size: 14,
          color: AppColors.secondary,
        ),
        const SizedBox(width: AppSpacing.xxs),
        Text(
          "We'll send a secure 6-digit code",
          style: AppTypography.caption.copyWith(color: AppColors.textMuted),
        ),
      ],
    );
  }

  // -- Success state --------------------------------------------------------

  Widget _buildSuccessState() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        _buildSuccessIcon(),
        const SizedBox(height: AppSpacing.lg),
        Text(
          'Code Sent!',
          style: AppTypography.h1,
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: AppSpacing.xs),
        Text(
          'We sent a 6-digit verification code to',
          style: AppTypography.body.copyWith(color: AppColors.textMuted),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: AppSpacing.xxs),
        Text(
          _emailController.text.trim(),
          style: AppTypography.body.copyWith(
            color: AppColors.textStrong,
            fontWeight: FontWeight.w700,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: AppSpacing.xl),
        TanderButton(
          label: 'Enter Verification Code',
          onPressed: _navigateToOtp,
          icon: Icons.arrow_forward_rounded,
          iconPosition: IconPosition.trailing,
        ),
        const SizedBox(height: AppSpacing.md),
        TanderButton(
          label: 'Back to Login',
          onPressed: () => context.go(AppRoutes.login),
          variant: TanderButtonVariant.ghost,
          icon: Icons.arrow_back_rounded,
        ),
      ],
    );
  }

  Widget _buildSuccessIcon() {
    return Container(
      width: 80,
      height: 80,
      decoration: const BoxDecoration(
        color: AppColors.successLight,
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: Color(0x3322C55E),
            blurRadius: 24,
            offset: Offset(0, 8),
          ),
        ],
      ),
      child: const Icon(
        Icons.check_circle_rounded,
        size: 40,
        color: AppColors.success,
      ),
    );
  }
}
