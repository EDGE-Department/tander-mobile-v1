import 'dart:ui' show ImageFilter;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:tander_flutter_v3/core/theme/app_colors.dart';
import 'package:tander_flutter_v3/core/theme/app_spacing.dart';
import 'package:tander_flutter_v3/core/theme/app_typography.dart';
import 'package:tander_flutter_v3/features/auth/presentation/providers/auth_providers.dart';
import 'package:tander_flutter_v3/features/auth/presentation/widgets/forgot_password_components.dart';
import 'package:tander_flutter_v3/features/auth/presentation/widgets/forgot_password_panels.dart';
import 'package:tander_flutter_v3/features/auth/presentation/widgets/login_background.dart';
import 'package:tander_flutter_v3/features/auth/presentation/widgets/login_connection_showcase.dart';
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
    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        systemNavigationBarColor: _navBarColor,
        systemNavigationBarDividerColor: Colors.transparent,
        systemNavigationBarContrastEnforced: false,
      ),
    );
  }

  @override
  void dispose() {
    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        systemNavigationBarColor: Colors.transparent,
        systemNavigationBarContrastEnforced: false,
      ),
    );
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
    final bottomPadding = MediaQuery.of(context).viewPadding.bottom;

    return Scaffold(
      backgroundColor: Colors.transparent,
      resizeToAvoidBottomInset: true,
      body: Stack(
        children: [
          const Positioned.fill(
            child: IgnorePointer(
              child: DecoratedBox(
                decoration: BoxDecoration(gradient: _mobileAuthGradient),
              ),
            ),
          ),
          Column(
            children: [
              ForgotPasswordMobileHeader(
                headerHeight: headerHeight,
                onlineCount: _onlineCount,
              ),
              Expanded(
                child: Padding(
                  padding: EdgeInsets.only(bottom: bottomPadding + 8),
                  child: Transform.translate(
                    offset: const Offset(0, -12),
                    child: _buildScrollableFormCard(),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildScrollableFormCard() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(32),
        child: Container(
          decoration: const BoxDecoration(color: Color(0xFFFFFBF8)),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
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
              // Scrollable form content
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(24, 24, 24, 16),
                  child: _isCodeSent
                      ? _buildSuccessContent()
                      : _buildScrollableFormContent(),
                ),
              ),
              // Sticky button at bottom
              if (!_isCodeSent)
                Padding(
                  padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
                  child: _SubmitButton(
                    isLoading: _isLoading,
                    onPressed: _submitForm,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildScrollableFormContent() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            BackToSignInPill(onPressed: _navigateToLogin),
            const ForgotPasswordBrandHeader(),
          ],
        ),
        const SizedBox(height: AppSpacing.md),
        const Center(child: StepIconHero()),
        const SizedBox(height: AppSpacing.md),
        const Center(child: StepIndicator()),
        const SizedBox(height: AppSpacing.lg),
        _buildHeadingBlock(),
        const SizedBox(height: AppSpacing.lg),
        _buildIdentifierFormWithoutButton(),
        const SizedBox(height: AppSpacing.md),
        RememberPasswordFooter(onSignIn: _navigateToLogin),
      ],
    );
  }

  Widget _buildIdentifierFormWithoutButton() {
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
          const SizedBox(height: AppSpacing.sm),
          const SecurityNote(),
        ],
      ),
    );
  }

  Widget _buildTabletPortraitLayout() {
    final screenWidth = MediaQuery.sizeOf(context).width;
    final leftPanelWidth = screenWidth * 0.42;

    return Scaffold(
      body: Stack(
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              SizedBox(
                width: leftPanelWidth,
                child: _ForgotTabletBrandPanel(onlineCount: _onlineCount),
              ),
              Expanded(
                child: _ForgotTabletFormPanel(
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
            left: leftPanelWidth - 64,
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

  // ── Form content (Step 1) ──────────────────────────────────────────

  Widget _buildFormContent() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            BackToSignInPill(onPressed: _navigateToLogin),
            const ForgotPasswordBrandHeader(),
          ],
        ),
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
            fontSize: 13,
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
          _emailController.text.trim().isNotEmpty
              ? _emailController.text.trim()
              : _phoneController.text.trim(),
          style: AppTypography.body.copyWith(
            color: AppColors.textStrong,
            fontWeight: FontWeight.w700,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: AppSpacing.xl),
        _SuccessButton(
          label: 'ENTER CODE',
          onPressed: _navigateToOtp,
          isPrimary: true,
        ),
        const SizedBox(height: AppSpacing.md),
        _SuccessButton(
          label: 'BACK TO SIGN IN',
          onPressed: _navigateToLogin,
          isPrimary: false,
        ),
      ],
    );
  }
}

// ── Tablet portrait brand panel (left 42%) ─────────────────────────────────

class _ForgotTabletBrandPanel extends StatelessWidget {
  const _ForgotTabletBrandPanel({required this.onlineCount});

  final SimulatedOnlineCount onlineCount;

  @override
  Widget build(BuildContext context) {
    final panelWidth = MediaQuery.sizeOf(context).width * 0.42;
    final wordmarkSize = (panelWidth * 0.18).clamp(56.0, 88.0);
    final ghostSize = (panelWidth * 0.60).clamp(140.0, 220.0);

    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment(-1, -1),
          end: Alignment(1, 1),
          colors: [
            Color(0xFFF07040),
            Color(0xFFE86035),
            Color(0xFF2EC878),
            Color(0xFF20BF68),
          ],
          stops: [0.0, 0.30, 0.70, 1.0],
        ),
      ),
      child: Stack(
        children: [
          // Full-height gradient background (reuses login's header background)
          const Positioned.fill(
            child: IgnorePointer(
              child: LoginHeaderBackground(
                headerHeight: double.infinity,
                showSocialOrbs: false,
              ),
            ),
          ),
          // Ghost wordmark
          Positioned.fill(
            child: IgnorePointer(
              child: Center(
                child: RotatedBox(
                  quarterTurns: 3,
                  child: Text(
                    'Tander',
                    style: AppTypography.brandWordmark(
                      fontSize: ghostSize,
                      color: Colors.white.withValues(alpha: 0.07),
                      letterSpacing: -0.02 * ghostSize,
                    ),
                  ),
                ),
              ),
            ),
          ),
          // Bottom vignette
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            height: 160,
            child: IgnorePointer(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.bottomCenter,
                    end: Alignment.topCenter,
                    colors: [
                      const Color(0xFF120400).withValues(alpha: 0.32),
                      Colors.transparent,
                    ],
                  ),
                ),
              ),
            ),
          ),
          // Online badge
          Positioned(
            top: 0,
            right: 0,
            child: SafeArea(
              child: Padding(
                padding: const EdgeInsets.only(top: 20, right: 20),
                child: ValueListenableBuilder<int>(
                  valueListenable: onlineCount,
                  builder: (_, count, _) => OnlineCountBadge(count: count),
                ),
              ),
            ),
          ),
          // Brand content
          SafeArea(
            right: false,
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(24, 64, 24, 32),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'MADE FOR FILIPINO SENIORS 60+',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: Colors.white.withValues(alpha: 0.65),
                      letterSpacing: 2.8,
                    ),
                  ),
                  const SizedBox(height: 12),
                  LoginLogoWordmarkRow(
                    alignment: MainAxisAlignment.start,
                    logoSize: wordmarkSize * 0.82,
                    wordmarkSize: wordmarkSize,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Connect with fellow seniors\nwho understand your world',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Colors.white.withValues(alpha: 0.85),
                      height: 1.3,
                    ),
                  ),
                  const SizedBox(height: 10),
                  const LoginFilipinoValuesMarquee(),
                  const SizedBox(height: 20),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(20),
                    child: BackdropFilter(
                      filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.10),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: Colors.white.withValues(alpha: 0.16),
                          ),
                        ),
                        child: const ConnectionShowcase(),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Tablet portrait form panel (right 58%) ─────────────────────────────────

class _ForgotTabletFormPanel extends StatelessWidget {
  const _ForgotTabletFormPanel({required this.child});

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

/// Orange gradient submit button with shimmer animation.
class _SubmitButton extends StatefulWidget {
  const _SubmitButton({required this.isLoading, required this.onPressed});

  final bool isLoading;
  final VoidCallback onPressed;

  @override
  State<_SubmitButton> createState() => _SubmitButtonState();
}

class _SubmitButtonState extends State<_SubmitButton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _shimmerController;

  @override
  void initState() {
    super.initState();
    _shimmerController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 4000),
    )..repeat();
  }

  @override
  void dispose() {
    _shimmerController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isInteractive = !widget.isLoading;

    return Opacity(
      opacity: widget.isLoading ? 0.6 : 1.0,
      child: GestureDetector(
        onTap: isInteractive ? widget.onPressed : null,
        child: Container(
          height: 60,
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFFE67E22), Color(0xFFD35400)],
            ),
            borderRadius: BorderRadius.circular(20),
            boxShadow: const [
              BoxShadow(
                color: Color(0x59E67E22),
                blurRadius: 40,
                offset: Offset(0, 20),
                spreadRadius: -12,
              ),
            ],
          ),
          child: Stack(
            alignment: Alignment.center,
            children: [
              // Shimmer sweep
              Positioned.fill(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(20),
                  child: AnimatedBuilder(
                    animation: _shimmerController,
                    builder: (_, _) {
                      final translateX = (_shimmerController.value * 3.0 - 1.0);
                      return FractionallySizedBox(
                        widthFactor: 1.0,
                        child: Transform.translate(
                          offset: Offset(
                            translateX * MediaQuery.sizeOf(context).width,
                            0,
                          ),
                          child: Container(
                            decoration: const BoxDecoration(
                              gradient: LinearGradient(
                                colors: [
                                  Color(0x00FFFFFF),
                                  Color(0x38FFFFFF),
                                  Color(0x00FFFFFF),
                                ],
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ),
              widget.isLoading
                  ? Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              Colors.white,
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Text(
                          'SENDING...',
                          style: AppTypography.body.copyWith(
                            fontSize: 16,
                            color: Colors.white,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 0.12 * 16,
                            height: 1.0,
                          ),
                        ),
                      ],
                    )
                  : Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          'SEND VERIFICATION CODE',
                          style: AppTypography.body.copyWith(
                            fontSize: 14,
                            color: Colors.white,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 0.08 * 14,
                            height: 1.0,
                          ),
                        ),
                        const SizedBox(width: 12),
                        const Icon(
                          Icons.arrow_forward_rounded,
                          size: 22,
                          color: Colors.white,
                        ),
                      ],
                    ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Simple button for success state actions.
class _SuccessButton extends StatelessWidget {
  const _SuccessButton({
    required this.label,
    required this.onPressed,
    required this.isPrimary,
  });

  final String label;
  final VoidCallback onPressed;
  final bool isPrimary;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onPressed,
      child: Container(
        height: 56,
        decoration: BoxDecoration(
          gradient: isPrimary
              ? const LinearGradient(
                  colors: [Color(0xFFE67E22), Color(0xFFD35400)],
                )
              : null,
          color: isPrimary ? null : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
          border: isPrimary
              ? null
              : Border.all(
                  color: AppColors.textMuted.withValues(alpha: 0.3),
                  width: 1.5,
                ),
          boxShadow: isPrimary
              ? const [
                  BoxShadow(
                    color: Color(0x40E67E22),
                    blurRadius: 24,
                    offset: Offset(0, 12),
                    spreadRadius: -8,
                  ),
                ]
              : null,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (!isPrimary)
              const Icon(
                Icons.arrow_back_rounded,
                size: 20,
                color: AppColors.textMuted,
              ),
            if (!isPrimary) const SizedBox(width: 8),
            Text(
              label,
              style: AppTypography.body.copyWith(
                fontSize: 14,
                color: isPrimary ? Colors.white : AppColors.textMuted,
                fontWeight: FontWeight.w800,
                letterSpacing: 0.08 * 14,
              ),
            ),
            if (isPrimary) const SizedBox(width: 8),
            if (isPrimary)
              const Icon(
                Icons.arrow_forward_rounded,
                size: 20,
                color: Colors.white,
              ),
          ],
        ),
      ),
    );
  }
}
