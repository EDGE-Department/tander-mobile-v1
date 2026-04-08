import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:tander_flutter_v3/core/theme/app_colors.dart';
import 'package:tander_flutter_v3/core/theme/app_curves.dart';
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

const LinearGradient _parchmentGradient = LinearGradient(
  begin: Alignment(-0.15, -1.0),
  end: Alignment(0.15, 1.0),
  colors: [
    Color(0xFFFEF7EE),
    Color(0xFFFEFAF4),
    Color(0xFFFFF8EF),
    Color(0xFFFDF4E8),
  ],
  stops: [0.0, 0.35, 0.65, 1.0],
);

const LinearGradient _mobileAuthGradient = LinearGradient(
  begin: Alignment(-1, -1),
  end: Alignment(1, 1),
  colors: [
    Color(0xFFF07040),
    Color(0xFFE86035),
    Color(0xFF2EC878),
    Color(0xFF20BF68),
  ],
  stops: [0.0, 0.30, 0.70, 1.0],
);

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

  // Bottom color of _mobileAuthGradient — used to paint the system nav bar
  // so it blends seamlessly with the gradient background.
  static const Color _navBarColor = Color(0xFF20BF68);

  @override
  void initState() {
    super.initState();
    _onlineCount = SimulatedOnlineCount();
    SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
      systemNavigationBarColor: _navBarColor,
      systemNavigationBarDividerColor: Colors.transparent,
      systemNavigationBarContrastEnforced: false,
    ));
  }

  @override
  void dispose() {
    SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
      systemNavigationBarColor: Colors.transparent,
      systemNavigationBarContrastEnforced: false,
    ));
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
    final isPhone = _method == IdentifierMethod.phone;
    final email = isPhone ? null : _emailController.text.trim();
    final phone = isPhone ? _phoneController.text.trim() : null;
    final resetResult = await repository.requestPasswordReset(
      email: email,
      phone: phone,
    );

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
    final isPhone = _method == IdentifierMethod.phone;
    context.push(
      AppRoutes.otpVerification,
      extra: {
        'email': isPhone ? '' : _emailController.text.trim(),
        'phone': isPhone ? _phoneController.text.trim() : '',
        'type': 'PASSWORD_RESET',
      },
    );
  }

  void _navigateToLogin() => context.go(AppRoutes.login);

  // ── Build ──────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.sizeOf(context).width;
    final isWideLayout = screenWidth >= 1024;
    final isTabletPortraitLayout = screenWidth >= 768 && screenWidth < 1024;

    if (isWideLayout) return _buildWideLayout(context);
    if (isTabletPortraitLayout) return _buildTabletPortraitLayout();
    return _buildPhoneLayout();
  }

  Widget _buildWideLayout(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          Row(
            children: [
              Expanded(
                flex: 60,
                child: DesktopHeroPanel(onlineCount: _onlineCount),
              ),
              Expanded(
                flex: 40,
                child: _ForgotLandscapeRightPanel(
                  child: ForgotPasswordFormCard(
                    isWide: true,
                    isCodeSent: _isCodeSent,
                    formContent: _buildFormContent(),
                    successContent: _buildSuccessContent(),
                  ),
                ),
              ),
            ],
          ),
          Positioned(
            left: MediaQuery.sizeOf(context).width * 0.6 - 64,
            top: 0,
            bottom: 0,
            width: 128,
            child: const IgnorePointer(
              child: CustomPaint(painter: _WaveSeamPainter()),
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
      backgroundColor: Colors.transparent,
      body: Stack(
        children: [
          const Positioned.fill(
            child: IgnorePointer(
              child: DecoratedBox(
                decoration: BoxDecoration(gradient: _mobileAuthGradient),
              ),
            ),
          ),
          SingleChildScrollView(
            child: ConstrainedBox(
              constraints: BoxConstraints(minHeight: screenHeight),
              child: Column(
                children: [
                  ForgotPasswordMobileHeader(
                    headerHeight: headerHeight,
                    onlineCount: _onlineCount,
                  ),
                  Transform.translate(
                        offset: const Offset(0, -headerOverlap),
                        child: _ForgotMobileParchmentSheet(
                          child: Padding(
                            padding: const EdgeInsets.only(bottom: 32),
                            child: ForgotPasswordFormCard(
                              isWide: false,
                              isCodeSent: _isCodeSent,
                              formContent: _buildFormContent(),
                              successContent: _buildSuccessContent(),
                            ),
                          ),
                        ),
                      )
                      .animate()
                      .fadeIn(
                      duration: 700.ms,
                      delay: 100.ms,
                      curve: AppCurves.premiumEase,
                    )
                    .slideY(begin: 0.08, curve: AppCurves.premiumEase),
              ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTabletPortraitLayout() {
    return Scaffold(
      backgroundColor: AppColors.card,
      body: DecoratedBox(
        decoration: const BoxDecoration(gradient: _parchmentGradient),
        child: Stack(
          children: [
            const Positioned.fill(
              child: IgnorePointer(
                child: Opacity(
                  opacity: 0.05,
                  child: CustomPaint(painter: _ParchmentDotGridPainter()),
                ),
              ),
            ),
            SafeArea(
              child: Align(
                alignment: Alignment.topCenter,
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(32, 40, 32, 36),
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 940),
                    child: Column(
                      children: [
                        Stack(
                          clipBehavior: Clip.none,
                          children: [
                            Padding(
                              padding: const EdgeInsets.only(bottom: 96),
                              child: TabletPortraitHeroPanel(
                                onlineCount: _onlineCount,
                              ),
                            ),
                            Positioned(
                              left: 40,
                              right: 40,
                              bottom: 0,
                              child: Center(
                                child: ConstrainedBox(
                                  constraints: const BoxConstraints(
                                    maxWidth: 720,
                                  ),
                                  child: ForgotPasswordFormCard(
                                    isWide: true,
                                    isCodeSent: _isCodeSent,
                                    formContent: _buildFormContent(),
                                    successContent: _buildSuccessContent(),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
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

class _ForgotMobileParchmentSheet extends StatelessWidget {
  const _ForgotMobileParchmentSheet({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Colors.white.withValues(alpha: 0.14),
            Colors.white.withValues(alpha: 0.08),
            Colors.white.withValues(alpha: 0.04),
          ],
        ),
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(36),
          topRight: Radius.circular(36),
        ),
        border: Border.all(color: Colors.white.withValues(alpha: 0.12)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x26000000),
            blurRadius: 28,
            offset: Offset(0, -8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: 12),
          const _SheetHandle(),
          const SizedBox(height: 4),
          child,
        ],
      ),
    );
  }
}

class _ForgotLandscapeRightPanel extends StatelessWidget {
  const _ForgotLandscapeRightPanel({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: const BoxDecoration(gradient: _parchmentGradient),
      child: Stack(
        children: [
          const Positioned.fill(child: IgnorePointer(child: _LandscapeDecor())),
          SafeArea(
            left: false,
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(40),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 480),
                  child: child,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _LandscapeDecor extends StatelessWidget {
  const _LandscapeDecor();

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        const Positioned.fill(
          child: Opacity(
            opacity: 0.45,
            child: CustomPaint(painter: _ParchmentDotGridPainter(spacing: 24)),
          ),
        ),
        Positioned.fill(
          child: Center(
            child: Container(
              width: 420,
              height: 420,
              decoration: const BoxDecoration(
                gradient: RadialGradient(
                  colors: [
                    Color(0x1AE67E22),
                    Color(0x0AE67E22),
                    Colors.transparent,
                  ],
                  stops: [0.0, 0.45, 0.85],
                ),
              ),
            ),
          ),
        ),
        Positioned(
          left: 0,
          top: 0,
          bottom: 0,
          width: 80,
          child: Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.centerLeft,
                end: Alignment.centerRight,
                colors: [Color(0x0FE67E22), Colors.transparent],
              ),
            ),
          ),
        ),
        Positioned(
          top: 0,
          right: 0,
          child: Container(
            width: 280,
            height: 280,
            decoration: const BoxDecoration(
              gradient: RadialGradient(
                center: Alignment.topRight,
                radius: 0.95,
                colors: [Color(0x0FE6A03C), Colors.transparent],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _SheetHandle extends StatelessWidget {
  const _SheetHandle();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        width: 48,
        height: 4,
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFFFF7849), Color(0xFF0D9488)],
          ),
          borderRadius: BorderRadius.circular(999),
        ),
      ),
    );
  }
}

class _ParchmentDotGridPainter extends CustomPainter {
  const _ParchmentDotGridPainter({this.spacing = 26});

  final double spacing;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0x14B46414)
      ..style = PaintingStyle.fill;

    for (double x = 0; x <= size.width; x += spacing) {
      for (double y = 0; y <= size.height; y += spacing) {
        canvas.drawCircle(Offset(x, y), 0.8, paint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant _ParchmentDotGridPainter oldDelegate) {
    return oldDelegate.spacing != spacing;
  }
}

class _WaveSeamPainter extends CustomPainter {
  const _WaveSeamPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final path = Path()
      ..moveTo(size.width * 0.53, 0)
      ..cubicTo(
        size.width * 0.66,
        size.height * 0.078,
        size.width * 0.80,
        size.height * 0.143,
        size.width * 0.59,
        size.height * 0.266,
      )
      ..cubicTo(
        size.width * 0.44,
        size.height * 0.39,
        size.width * 0.71,
        size.height * 0.456,
        size.width * 0.56,
        size.height * 0.576,
      )
      ..cubicTo(
        size.width * 0.44,
        size.height * 0.696,
        size.width * 0.67,
        size.height * 0.75,
        size.width * 0.53,
        size.height * 0.876,
      )
      ..cubicTo(
        size.width * 0.44,
        size.height * 0.96,
        size.width * 0.56,
        size.height * 0.983,
        size.width * 0.53,
        size.height,
      );

    final paint = Paint()
      ..color = const Color(0x38E6A03C)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
