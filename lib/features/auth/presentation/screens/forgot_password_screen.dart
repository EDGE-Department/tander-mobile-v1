import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:tander_flutter_v3/core/theme/app_colors.dart';
import 'package:tander_flutter_v3/core/theme/app_spacing.dart';
import 'package:tander_flutter_v3/core/theme/app_typography.dart';
import 'package:tander_flutter_v3/features/auth/presentation/providers/auth_providers.dart';
import 'package:tander_flutter_v3/features/auth/presentation/widgets/forgot_password_components.dart';
import 'package:tander_flutter_v3/features/auth/presentation/widgets/forgot_password_panels.dart';
import 'package:tander_flutter_v3/features/auth/presentation/widgets/login_background.dart';
import 'package:tander_flutter_v3/features/auth/presentation/widgets/login_desktop_hero.dart';
import 'package:tander_flutter_v3/shared/constants/routes.dart';
import 'package:tander_flutter_v3/shared/widgets/tander_button.dart';
import 'package:tander_flutter_v3/shared/widgets/tander_text_field.dart';
import 'package:tander_flutter_v3/shared/widgets/tander_toast.dart';

/// Forgot password screen — 1:1 copy of the web's forgot-password-page.
///
/// Layout:
///   - **Landscape/tablet** (width >= 1024): split-panel with DesktopHeroPanel
///     on left (60%) and form card on warm parchment right panel (40%).
///   - **Phone portrait**: gradient header + overlapping white form panel.
///
/// Step 1 sends a verification code. On success, navigates to the OTP screen.
class ForgotPasswordScreen extends ConsumerStatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  ConsumerState<ForgotPasswordScreen> createState() =>
      _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends ConsumerState<ForgotPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _emailFocusNode = FocusNode();
  final _phoneFocusNode = FocusNode();
  late final SimulatedOnlineCount _onlineCount;

  IdentifierMethod _method = IdentifierMethod.email;
  bool _isLoading = false;
  bool _isCodeSent = false;

  @override
  void initState() {
    super.initState();
    _onlineCount = SimulatedOnlineCount();
  }

  @override
  void dispose() {
    _emailController.dispose();
    _phoneController.dispose();
    _emailFocusNode.dispose();
    _phoneFocusNode.dispose();
    _onlineCount.dispose();
    super.dispose();
  }

  // ── Validation ─────────────────────────────────────────────────────

  String? _validateEmail(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Please enter your email address';
    }
    if (!RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(value.trim())) {
      return 'Enter a valid email address (name@email.com)';
    }
    return null;
  }

  String? _validatePhone(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Please enter your phone number';
    }
    if (!RegExp(r'^09\d{9}$').hasMatch(value.trim())) {
      return 'Enter a valid PH number (09XXXXXXXXX)';
    }
    return null;
  }

  // ── Actions ────────────────────────────────────────────────────────

  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    final repository = ref.read(authRepositoryProvider);
    final email = _emailController.text.trim();
    final resetResult = await repository.requestPasswordReset(email: email);

    if (!mounted) return;

    resetResult.when(
      success: (_) => setState(() {
        _isLoading = false;
        _isCodeSent = true;
      }),
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

  void _navigateToLogin() => context.go(AppRoutes.login);

  // ── Build ──────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final isWideLayout = MediaQuery.sizeOf(context).width >= 1024;
    return isWideLayout ? _buildWideLayout() : _buildPhoneLayout();
  }

  Widget _buildWideLayout() {
    return Scaffold(
      body: Row(
        children: [
          Expanded(
            flex: 60,
            child: DesktopHeroPanel(onlineCount: _onlineCount),
          ),
          Expanded(
            flex: 40,
            child: Container(
              color: const Color(0xFFFEFAF4),
              child: SafeArea(
                left: false,
                child: Center(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.lg,
                      vertical: AppSpacing.xl,
                    ),
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 480),
                      child: ForgotPasswordFormCard(
                        isWide: true,
                        isCodeSent: _isCodeSent,
                        formContent: _buildFormContent(),
                        successContent: _buildSuccessContent(),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPhoneLayout() {
    final screenHeight = MediaQuery.sizeOf(context).height;
    final headerHeight = resolveHeaderHeight(screenHeight);

    return Scaffold(
      backgroundColor: AppColors.card,
      body: SingleChildScrollView(
        child: Column(
          children: [
            ForgotPasswordMobileHeader(
              headerHeight: headerHeight,
              onlineCount: _onlineCount,
            ),
            Transform.translate(
              offset: const Offset(0, -headerOverlap),
              child: ForgotPasswordFormCard(
                isWide: false,
                isCodeSent: _isCodeSent,
                formContent: _buildFormContent(),
                successContent: _buildSuccessContent(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Form content (Step 1) ──────────────────────────────────────────

  Widget _buildFormContent() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        BackToSignInPill(onPressed: _navigateToLogin),
        const SizedBox(height: 20),
        const ForgotPasswordBrandHeader(),
        const SizedBox(height: AppSpacing.md),
        const Center(child: StepIconHero()),
        const SizedBox(height: AppSpacing.md),
        const Center(child: StepIndicator()),
        const SizedBox(height: AppSpacing.lg),
        _buildHeadingBlock(),
        const SizedBox(height: AppSpacing.lg),
        _buildIdentifierForm(),
        const SizedBox(height: AppSpacing.lg),
        RememberPasswordFooter(onSignIn: _navigateToLogin),
      ],
    );
  }

  Widget _buildHeadingBlock() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          'Forgot your password?',
          style: AppTypography.displayLg.copyWith(
            fontWeight: FontWeight.w800,
            height: 1.05,
          ),
        ),
        const SizedBox(height: 10),
        Text(
          'Enter your email or phone number to receive a 6-digit code.',
          style: AppTypography.body.copyWith(
            fontSize: 15,
            color: AppColors.textMuted,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          'Ligtas at madali \u00B7 Safe and easy',
          style: AppTypography.caption.copyWith(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            fontStyle: FontStyle.italic,
            letterSpacing: 0.3,
            color: AppColors.primaryAccessible.withValues(alpha: 0.65),
          ),
        ),
      ],
    );
  }

  Widget _buildIdentifierForm() {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          MethodSelector(
            selectedMethod: _method,
            onMethodChanged: (method) => setState(() => _method = method),
          ),
          const SizedBox(height: AppSpacing.md),
          if (_method == IdentifierMethod.email)
            TanderTextField(
              label: 'Email address',
              hint: 'name@email.com',
              controller: _emailController,
              focusNode: _emailFocusNode,
              keyboardType: TextInputType.emailAddress,
              textInputAction: TextInputAction.done,
              prefixIcon: Icons.email_outlined,
              validator: _validateEmail,
            )
          else
            TanderTextField(
              label: 'Phone number',
              hint: '09XXXXXXXXX',
              controller: _phoneController,
              focusNode: _phoneFocusNode,
              keyboardType: TextInputType.phone,
              textInputAction: TextInputAction.done,
              prefixIcon: Icons.phone,
              validator: _validatePhone,
            ),
          const SizedBox(height: AppSpacing.md),
          TanderButton(
            label: 'Send Verification Code',
            onPressed: _isLoading ? null : _submitForm,
            isLoading: _isLoading,
            icon: Icons.arrow_forward,
            iconPosition: IconPosition.trailing,
          ),
          const SizedBox(height: AppSpacing.sm),
          const SecurityNote(),
        ],
      ),
    );
  }

  // ── Success content ────────────────────────────────────────────────

  Widget _buildSuccessContent() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const SuccessIconOrb(),
        const SizedBox(height: AppSpacing.lg),
        Text(
          'Code Sent!',
          style: AppTypography.displayLg.copyWith(
            fontWeight: FontWeight.w800,
            height: 1.05,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: AppSpacing.xs),
        Text(
          'We sent a 6-digit verification code to',
          style: AppTypography.body.copyWith(
            fontSize: 15,
            color: AppColors.textMuted,
          ),
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
          icon: Icons.arrow_forward,
          iconPosition: IconPosition.trailing,
        ),
        const SizedBox(height: AppSpacing.md),
        TanderButton(
          label: 'Back to Sign In',
          onPressed: _navigateToLogin,
          variant: TanderButtonVariant.ghost,
          icon: Icons.arrow_back,
        ),
      ],
    );
  }
}

