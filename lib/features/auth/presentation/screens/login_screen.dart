import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:tander_flutter_v3/core/auth/session_manager.dart';
import 'package:tander_flutter_v3/core/theme/app_colors.dart';
import 'package:tander_flutter_v3/core/theme/app_radius.dart';
import 'package:tander_flutter_v3/core/theme/app_shadows.dart';
import 'package:tander_flutter_v3/core/theme/app_spacing.dart';
import 'package:tander_flutter_v3/core/theme/app_typography.dart';
import 'package:tander_flutter_v3/features/auth/presentation/notifiers/auth_notifier.dart';
import 'package:tander_flutter_v3/features/auth/presentation/states/auth_state.dart';
import 'package:tander_flutter_v3/features/auth/presentation/widgets/login_background.dart';
import 'package:tander_flutter_v3/shared/constants/routes.dart';
import 'package:tander_flutter_v3/shared/widgets/tander_button.dart';
import 'package:tander_flutter_v3/shared/widgets/tander_text_field.dart';
import 'package:tander_flutter_v3/shared/widgets/tander_toast.dart';

// ── Constants ──────────────────────────────────────────────────────

const double _logoSize = 48;
const double _maxFormWidth = 420;
const int _minPasswordLength = 6;

/// Login screen — warm gradient background with decorative orbs and
/// a centered form card.
///
/// Carbon-copy of the web login page adapted for mobile. Uses
/// [ConsumerStatefulWidget] for [TextEditingController] lifecycle
/// management and auth state listening.
class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _emailFocusNode = FocusNode();
  final _passwordFocusNode = FocusNode();

  bool _isPasswordVisible = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _emailFocusNode.dispose();
    _passwordFocusNode.dispose();
    super.dispose();
  }

  // ── Validation ──────────────────────────────────────────────────

  String? _validateEmail(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Please enter your email address';
    }
    final emailPattern = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');
    if (!emailPattern.hasMatch(value.trim())) {
      return 'Please enter a valid email address';
    }
    return null;
  }

  String? _validatePassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'Please enter your password';
    }
    if (value.length < _minPasswordLength) {
      return 'Password must be at least $_minPasswordLength characters';
    }
    return null;
  }

  // ── Actions ─────────────────────────────────────────────────────

  void _submitForm() {
    if (!_formKey.currentState!.validate()) return;

    ref.read(authNotifierProvider.notifier).signIn(
          email: _emailController.text.trim(),
          password: _passwordController.text,
        );
  }

  void _togglePasswordVisibility() {
    setState(() {
      _isPasswordVisible = !_isPasswordVisible;
    });
  }

  // ── Build ───────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    _listenToAuthState();

    final authState = ref.watch(authNotifierProvider);
    final isLoading = authState is AuthLoading;

    return Scaffold(
      body: Stack(
        children: [
          const LoginGradientBackground(),
          const LoginDecorativeOrbs(),
          // Scrollable content
          SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.lg,
                  vertical: AppSpacing.xl,
                ),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: _maxFormWidth),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _buildBrandHeader(),
                      const SizedBox(height: AppSpacing.xl),
                      _buildFormCard(isLoading: isLoading),
                      const SizedBox(height: AppSpacing.lg),
                      _buildSignUpPrompt(),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Auth state listener ─────────────────────────────────────────

  void _listenToAuthState() {
    ref.listen<AuthState>(authNotifierProvider, (_, next) {
      switch (next) {
        case AuthAuthenticated():
          context.go(AppRoutes.home);
        case AuthOnboarding(:final phase):
          _navigateToOnboardingPhase(phase);
        case AuthError(:final exception):
          TanderToastOverlay.show(
            context,
            TanderToastData(
              message: exception.userMessage,
              variant: TanderToastVariant.error,
            ),
          );
        case AuthInitial():
        case AuthLoading():
        case AuthUnauthenticated():
          break;
      }
    });
  }

  void _navigateToOnboardingPhase(RegistrationPhase phase) {
    final route = switch (phase) {
      RegistrationPhase.pendingEmailVerification =>
        AppRoutes.emailVerification,
      RegistrationPhase.pendingProfileSetup => AppRoutes.profileSetup,
      RegistrationPhase.pendingPhotoSetup => AppRoutes.photoSetup,
      RegistrationPhase.pendingIdVerification => AppRoutes.profileSetup,
      RegistrationPhase.pendingNotificationPermission =>
        AppRoutes.notificationPermission,
      RegistrationPhase.complete => AppRoutes.home,
    };
    context.go(route);
  }

  // ── Brand header ────────────────────────────────────────────────

  Widget _buildBrandHeader() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Image.asset(
          'assets/icons/tander_logo.png',
          width: _logoSize,
          height: _logoSize,
          semanticLabel: 'Tander logo',
        ),
        const SizedBox(height: AppSpacing.sm),
        FittedBox(
          fit: BoxFit.scaleDown,
          child: Text('Tander', style: AppTypography.h1),
        ),
        const SizedBox(height: AppSpacing.xs),
        Text(
          'Welcome back',
          style: AppTypography.h2,
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: AppSpacing.xxs),
        Text(
          'Sign in to continue your journey',
          style: AppTypography.body.copyWith(color: AppColors.textMuted),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  // ── Form card ───────────────────────────────────────────────────

  Widget _buildFormCard({required bool isLoading}) {
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
              _buildEmailField(),
              const SizedBox(height: AppSpacing.md),
              _buildPasswordField(),
              const SizedBox(height: AppSpacing.xs),
              _buildForgotPasswordLink(),
              const SizedBox(height: AppSpacing.lg),
              _buildSignInButton(isLoading: isLoading),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmailField() {
    return TanderTextField(
      label: 'Email',
      hint: 'name@email.com',
      controller: _emailController,
      focusNode: _emailFocusNode,
      keyboardType: TextInputType.emailAddress,
      textInputAction: TextInputAction.next,
      prefixIcon: Icons.email_outlined,
      validator: _validateEmail,
    );
  }

  /// Password field with tappable visibility toggle.
  ///
  /// [TanderTextField.suffixIcon] renders a static icon without tap
  /// handling, so we build the password row using a [Stack] that
  /// layers a positioned [IconButton] over the field's suffix area.
  Widget _buildPasswordField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text('Password', style: AppTypography.label),
        const SizedBox(height: AppSpacing.xs),
        Stack(
          alignment: Alignment.centerRight,
          children: [
            TanderTextField(
              hint: 'Enter your password',
              controller: _passwordController,
              focusNode: _passwordFocusNode,
              obscureText: !_isPasswordVisible,
              textInputAction: TextInputAction.done,
              prefixIcon: Icons.lock_outline,
              validator: _validatePassword,
            ),
            Positioned(
              right: AppSpacing.xxs,
              child: SizedBox(
                width: AppSpacing.touchMinimum,
                height: AppSpacing.touchMinimum,
                child: IconButton(
                  onPressed: _togglePasswordVisibility,
                  icon: Icon(
                    _isPasswordVisible
                        ? Icons.visibility_off
                        : Icons.visibility,
                    size: 20,
                    color: AppColors.textMuted,
                  ),
                  tooltip: _isPasswordVisible
                      ? 'Hide password'
                      : 'Show password',
                  padding: EdgeInsets.zero,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildForgotPasswordLink() {
    return Align(
      alignment: Alignment.centerRight,
      child: GestureDetector(
        onTap: () => context.push(AppRoutes.forgotPassword),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: AppSpacing.xxs),
          child: Text(
            'Forgot password?',
            style: AppTypography.bodySm.copyWith(
              color: AppColors.primaryAccessible,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSignInButton({required bool isLoading}) {
    return TanderButton(
      label: 'Sign In',
      onPressed: isLoading ? null : _submitForm,
      isLoading: isLoading,
      icon: Icons.arrow_forward_rounded,
      iconPosition: IconPosition.trailing,
    );
  }

  // ── Sign-up prompt ──────────────────────────────────────────────

  Widget _buildSignUpPrompt() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Flexible(
          child: Text(
            "Don't have an account? ",
            style: AppTypography.bodySm.copyWith(
              color: AppColors.textMuted,
            ),
          ),
        ),
        GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: () {
            // Registration is download-only per web — a deep link or
            // store redirect could be wired here in the future.
          },
          child: Padding(
            padding: const EdgeInsets.symmetric(
              vertical: AppSpacing.xxs,
              horizontal: AppSpacing.xxs,
            ),
            child: Text(
              'Sign up',
              style: AppTypography.bodySm.copyWith(
                color: AppColors.primaryAccessible,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ),
      ],
    );
  }
}
