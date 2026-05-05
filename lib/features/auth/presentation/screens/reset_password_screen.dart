import 'dart:ui' show ImageFilter;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:tander_flutter_v3/core/theme/app_colors.dart';
import 'package:tander_flutter_v3/core/theme/app_spacing.dart';
import 'package:tander_flutter_v3/core/theme/app_typography.dart';
import 'package:tander_flutter_v3/features/auth/presentation/providers/auth_providers.dart';
import 'package:tander_flutter_v3/features/auth/presentation/widgets/auth_scene_decorations.dart';
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

/// Reset password screen — user sets a new password after OTP verification.
///
/// Layout mirrors the login screen pattern:
///   - **Landscape tablet** (≥1024): DesktopHeroPanel left + parchment form right
///   - **Portrait tablet** (768–1024): side-by-side brand panel + parchment form
///   - **Phone portrait**: gradient header + overlapping frosted form sheet
///
/// Expects route extras: `{'email': String, 'phone': String, 'resetToken': String}`.
class ResetPasswordScreen extends ConsumerStatefulWidget {
  const ResetPasswordScreen({super.key});

  @override
  ConsumerState<ResetPasswordScreen> createState() =>
      _ResetPasswordScreenState();
}

class _ResetPasswordScreenState extends ConsumerState<ResetPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _passwordController = TextEditingController();
  final _confirmController = TextEditingController();
  final _passwordFocusNode = FocusNode();
  final _confirmFocusNode = FocusNode();
  late final SimulatedOnlineCount _onlineCount;

  String _email = '';
  String _phone = '';
  String _resetToken = '';
  bool _isLoading = false;
  bool _isSuccess = false;

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
  void didChangeDependencies() {
    super.didChangeDependencies();
    final extras = GoRouterState.of(context).extra;
    if (extras is Map<String, String>) {
      _email = extras['email'] ?? '';
      _phone = extras['phone'] ?? '';
      _resetToken = extras['resetToken'] ?? '';
    }
  }

  @override
  void dispose() {
    SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
      systemNavigationBarColor: Colors.transparent,
      systemNavigationBarContrastEnforced: false,
    ));
    _passwordController.dispose();
    _confirmController.dispose();
    _passwordFocusNode.dispose();
    _confirmFocusNode.dispose();
    _onlineCount.dispose();
    super.dispose();
  }

  // ── Validation ─────────────────────────────────────────────────────

  String? _validatePassword(String? value) {
    if (value == null || value.isEmpty) return 'Please enter a new password';
    if (value.length < 8) return 'At least 8 characters required';
    if (!RegExp(r'[A-Z]').hasMatch(value)) {
      return 'Include at least one uppercase letter (A–Z)';
    }
    if (!RegExp(r'[0-9]').hasMatch(value)) {
      return 'Include at least one number (0–9)';
    }
    return null;
  }

  String? _validateConfirm(String? value) {
    if (value == null || value.isEmpty) return 'Please confirm your password';
    if (value != _passwordController.text) return 'Passwords do not match';
    return null;
  }

  // ── Actions ────────────────────────────────────────────────────────

  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    final repository = ref.read(authRepositoryProvider);
    final resetResult = await repository.resetPassword(
      email: _email.isNotEmpty ? _email : null,
      phone: _phone.isNotEmpty ? _phone : null,
      resetToken: _resetToken,
      newPassword: _passwordController.text,
    );

    if (!mounted) return;

    resetResult.when(
      success: (_) {
        setState(() {
          _isLoading = false;
          _isSuccess = true;
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

  // ── Landscape tablet (≥1024) ───────────────────────────────────────

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
                child: DecoratedBox(
                  decoration: const BoxDecoration(gradient: _parchmentGradient),
                  child: SafeArea(
                    left: false,
                    child: Center(
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.all(40),
                        child: ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: 480),
                          child: _buildFormCard(isWide: true),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ── Portrait tablet (768–1024) ─────────────────────────────────────

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
                child: _ResetTabletBrandPanel(onlineCount: _onlineCount),
              ),
              Expanded(
                child: _ResetTabletFormPanel(
                  child: _buildFormCard(isWide: true),
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
              child: CustomPaint(painter: _ResetWaveSeamPainter()),
            ),
          ),
        ],
      ),
    );
  }

  // ── Phone portrait ─────────────────────────────────────────────────

  Widget _buildPhoneLayout() {
    final screenHeight = MediaQuery.sizeOf(context).height;
    final headerHeight = resolveHeaderHeight(screenHeight);
    final bottomPadding = MediaQuery.of(context).viewPadding.bottom;

    return Scaffold(
      backgroundColor: _navBarColor,
      resizeToAvoidBottomInset: true,
      body: Stack(
        children: [
          Positioned.fill(
            child: IgnorePointer(
              child: DecoratedBox(
                decoration: const BoxDecoration(gradient: authGradient),
              ),
            ),
          ),
          Column(
            children: [
              _buildMobileHeader(headerHeight),
              Expanded(
                child: Padding(
                  padding: EdgeInsets.only(bottom: bottomPadding + 8),
                  child: _buildWhiteSheet(),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMobileHeader(double headerHeight) {
    final screenWidth = MediaQuery.sizeOf(context).width;
    final ghostFontSize = (screenWidth * 0.24).clamp(72.0, 96.0);
    final wordmarkSize = (screenWidth * 0.14).clamp(48.0, 60.0);

    return SizedBox(
      height: headerHeight + headerOverlap,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          // Ghost "Tander" wordmark
          Positioned.fill(
            child: IgnorePointer(
              child: Center(
                child: Transform.translate(
                  offset: Offset(0, ghostFontSize * 0.15),
                  child: Text(
                    'Tander',
                    style: AppTypography.brandWordmark(
                      fontSize: ghostFontSize,
                      color: Colors.white.withValues(alpha: 0.09),
                      letterSpacing: -0.03 * ghostFontSize,
                    ).copyWith(height: 1),
                  ),
                ),
              ),
            ),
          ),
          SafeArea(
            bottom: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 2, 16, 0),
              child: Column(
                children: [
                  _buildNavRow(),
                  const Spacer(),
                  // Logo
                  ClipOval(
                    child: Image.asset(
                      'assets/icons/tander_icon.png',
                      width: 48,
                      height: 48,
                      semanticLabel: 'Tander logo',
                    ),
                  ),
                  // White "Tander" wordmark with shadow
                  Text(
                    'Tander',
                    style: AppTypography.brandWordmark(
                      fontSize: wordmarkSize,
                      color: Colors.white,
                      letterSpacing: -0.03 * wordmarkSize,
                    ).copyWith(
                      height: 0.95,
                      shadows: const [
                        Shadow(
                          offset: Offset(0, 4),
                          blurRadius: 24,
                          color: Color(0x38000000),
                        ),
                        Shadow(
                          blurRadius: 50,
                          color: Color(0x47FFA050),
                        ),
                      ],
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

  Widget _buildNavRow() {
    return Row(
      children: [
        Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () => context.pop(),
            customBorder: const CircleBorder(),
            child: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withValues(alpha: 0.18),
                border: Border.all(
                  color: Colors.white.withValues(alpha: 0.3),
                ),
              ),
              child: const Icon(
                Icons.arrow_back_rounded,
                color: Colors.white,
                size: 20,
              ),
            ),
          ),
        ),
        const Spacer(),
        // Online count badge
        ValueListenableBuilder<int>(
          valueListenable: _onlineCount,
          builder: (_, count, __) =>
              OnlineCountBadge(count: count, useSeniorsLabel: true),
        ),
      ],
    );
  }

  Widget _buildWhiteSheet() {
    final borderRadius = BorderRadius.circular(32);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Container(
        decoration: BoxDecoration(
          color: const Color(0xFFFFFBF8),
          borderRadius: borderRadius,
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Orange accent bar at top
            Container(
              height: 6,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFFF07040), Color(0xFFE86035)],
                ),
                borderRadius: BorderRadius.only(
                  topLeft: borderRadius.topLeft,
                  topRight: borderRadius.topRight,
                ),
              ),
            ),
            // Scrollable form content
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(24, 24, 24, 24),
                child: _isSuccess ? _buildSuccessContent() : _buildFormContent(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Form card ──────────────────────────────────────────────────────

  Widget _buildFormCard({required bool isWide}) {
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFFFFFFFF), Color(0xFFFFFCF8)],
        ),
        borderRadius: BorderRadius.circular(isWide ? 32 : 28),
        border: Border.all(color: const Color(0x1AE6A032)),
        boxShadow: const [
          BoxShadow(color: Color(0x0A000000), blurRadius: 2, offset: Offset(0, 1)),
          BoxShadow(color: Color(0x0FB46414), blurRadius: 12, offset: Offset(0, 4)),
          BoxShadow(color: Color(0x1AC85A12), blurRadius: 48, offset: Offset(0, 16)),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(isWide ? 32 : 28),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: [
            // Accent bar
            Container(
              height: 2.5,
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xFFFF7849), Color(0xFF0D9488)],
                ),
              ),
            ),
            Padding(
              padding: EdgeInsets.fromLTRB(
                isWide ? 40 : 32,
                isWide ? 36 : 32,
                isWide ? 40 : 32,
                isWide ? 32 : 32,
              ),
              child: _isSuccess ? _buildSuccessContent() : _buildFormContent(),
            ),
          ],
        ),
      ),
    );
  }

  // ── Form content ───────────────────────────────────────────────────

  Widget _buildFormContent() {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.lock_reset_rounded, size: 48, color: AppColors.primary),
          const SizedBox(height: AppSpacing.md),
          Text(
            'Set New Password',
            style: AppTypography.displayLg.copyWith(
              fontWeight: FontWeight.w800,
              height: 1.05,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            'Create a strong password for your account.',
            style: AppTypography.body.copyWith(
              fontSize: 15,
              color: AppColors.textMuted,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AppSpacing.lg),
          TanderTextField(
            label: 'New Password',
            hint: '8+ characters with uppercase & number',
            controller: _passwordController,
            focusNode: _passwordFocusNode,
            obscureText: true,
            textInputAction: TextInputAction.next,
            prefixIcon: Icons.lock_outline,
            validator: _validatePassword,
          ),
          const SizedBox(height: AppSpacing.md),
          TanderTextField(
            label: 'Confirm Password',
            hint: 'Re-enter your password',
            controller: _confirmController,
            focusNode: _confirmFocusNode,
            obscureText: true,
            textInputAction: TextInputAction.done,
            prefixIcon: Icons.lock_outline,
            validator: _validateConfirm,
          ),
          const SizedBox(height: AppSpacing.sm),
          _buildPasswordRequirements(),
          const SizedBox(height: AppSpacing.lg),
          TanderButton(
            label: 'Reset Password',
            onPressed: _isLoading ? null : _submitForm,
            isLoading: _isLoading,
            icon: Icons.check,
            iconPosition: IconPosition.trailing,
          ),
        ],
      ),
    );
  }

  Widget _buildPasswordRequirements() {
    final password = _passwordController.text;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _requirementRow('At least 8 characters', password.length >= 8),
        _requirementRow(
          'One uppercase letter (A–Z)',
          RegExp(r'[A-Z]').hasMatch(password),
        ),
        _requirementRow(
          'One number (0–9)',
          RegExp(r'[0-9]').hasMatch(password),
        ),
      ],
    );
  }

  Widget _requirementRow(String label, bool isMet) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        children: [
          Icon(
            isMet ? Icons.check_circle : Icons.circle_outlined,
            size: 16,
            color: isMet ? AppColors.success : AppColors.textMuted,
          ),
          const SizedBox(width: 8),
          Text(
            label,
            style: AppTypography.caption.copyWith(
              fontSize: 12,
              color: isMet ? AppColors.success : AppColors.textMuted,
            ),
          ),
        ],
      ),
    );
  }

  // ── Success content ────────────────────────────────────────────────

  Widget _buildSuccessContent() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 96,
          height: 96,
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment(-0.5, -1),
              end: Alignment(0.5, 1),
              colors: [Color(0xFF2E8B57), Color(0xFF38A169)],
            ),
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: Color(0x732E8B57),
                blurRadius: 40,
                offset: Offset(0, 12),
              ),
            ],
          ),
          child: const Center(
            child: Icon(Icons.check_circle, size: 46, color: Colors.white),
          ),
        ),
        const SizedBox(height: AppSpacing.lg),
        Text(
          'Password Reset!',
          style: AppTypography.displayLg.copyWith(
            fontWeight: FontWeight.w800,
            height: 1.05,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: AppSpacing.xs),
        Text(
          'Your password has been updated successfully.\nYou can now sign in with your new password.',
          style: AppTypography.body.copyWith(
            fontSize: 15,
            color: AppColors.textMuted,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: AppSpacing.xl),
        TanderButton(
          label: 'Sign In Now',
          onPressed: _navigateToLogin,
          icon: Icons.arrow_forward,
          iconPosition: IconPosition.trailing,
        ),
      ],
    );
  }
}

// ── Mobile header ────────────────────────────────────────────────────

class _ResetPasswordMobileHeader extends StatelessWidget {
  const _ResetPasswordMobileHeader({
    required this.headerHeight,
    required this.onlineCount,
  });

  final double headerHeight;
  final SimulatedOnlineCount onlineCount;

  @override
  Widget build(BuildContext context) {
    final horizontalOverscan = MediaQuery.sizeOf(context).width * 0.10;

    return SizedBox(
      height: headerHeight + headerOverlap,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Positioned(
            left: -horizontalOverscan,
            right: -horizontalOverscan,
            top: 0,
            bottom: 0,
            child: const IgnorePointer(child: _MobileHeaderScene()),
          ),
          Positioned.fill(
            child: SafeArea(
              bottom: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(24, 2, 24, 8),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    Flexible(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.end,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Image.asset(
                            'assets/icons/tander_icon.png',
                            width: 32,
                            height: 32,
                            semanticLabel: 'Tander logo',
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Tander',
                            style: AppTypography.brandWordmark(
                              fontSize: 21,
                              color: Colors.white,
                              letterSpacing: -0.3,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Reset Password',
                      style: AppTypography.h1.copyWith(
                        fontSize: 27,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                        letterSpacing: -0.5,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 8),
                    ValueListenableBuilder<int>(
                      valueListenable: onlineCount,
                      builder: (_, count, _) =>
                          OnlineCountBadge(count: count, useSeniorsLabel: true),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Mobile header scene (constellation + grain + ghost text) ─────────

class _MobileHeaderScene extends StatelessWidget {
  const _MobileHeaderScene();

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(30),
      child: Stack(
        fit: StackFit.expand,
        children: [
          Positioned.fill(
            child: IgnorePointer(
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final fontSize =
                      (constraints.maxWidth * 0.34).clamp(116.0, 176.0);
                  return Center(
                    child: Transform.translate(
                      offset: Offset(0, fontSize * 0.08),
                      child: Text(
                        '60+',
                        style: TextStyle(
                          fontWeight: FontWeight.w900,
                          fontSize: fontSize,
                          color: Colors.white.withValues(alpha: 0.05),
                          height: 1,
                          letterSpacing: -0.05 * fontSize,
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Mobile frosted parchment sheet ──────────────────────────────────

class _MobileParchmentSheet extends StatelessWidget {
  const _MobileParchmentSheet({required this.child});

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
          Center(
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
          ),
          const SizedBox(height: 4),
          child,
        ],
      ),
    );
  }
}

// ── Tablet portrait brand panel (left 42%) ────────────────────────────────

class _ResetTabletBrandPanel extends StatelessWidget {
  const _ResetTabletBrandPanel({required this.onlineCount});

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
          const Positioned.fill(
            child: IgnorePointer(
              child: LoginHeaderBackground(
                headerHeight: double.infinity,
                showSocialOrbs: false,
              ),
            ),
          ),
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
          Positioned(
            top: 0,
            right: 0,
            child: SafeArea(
              child: Padding(
                padding: const EdgeInsets.only(top: 20, right: 20),
                child: ValueListenableBuilder<int>(
                  valueListenable: onlineCount,
                  builder: (context, count, child) => OnlineCountBadge(count: count),
                ),
              ),
            ),
          ),
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
                      fontSize: 9,
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

// ── Tablet portrait form panel (right 58%) ────────────────────────────────

class _ResetTabletFormPanel extends StatelessWidget {
  const _ResetTabletFormPanel({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: const BoxDecoration(gradient: _parchmentGradient),
      child: Stack(
        children: [
          const Positioned.fill(
            child: IgnorePointer(child: _ResetLandscapeDecor()),
          ),
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

// ── Parchment decorations ─────────────────────────────────────────────────

class _ResetLandscapeDecor extends StatelessWidget {
  const _ResetLandscapeDecor();

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        const Positioned.fill(
          child: Opacity(
            opacity: 0.45,
            child: CustomPaint(painter: _ResetDotGridPainter()),
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

class _ResetDotGridPainter extends CustomPainter {
  const _ResetDotGridPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0x14B46414)
      ..style = PaintingStyle.fill;
    const spacing = 24.0;
    for (double x = 0; x <= size.width; x += spacing) {
      for (double y = 0; y <= size.height; y += spacing) {
        canvas.drawCircle(Offset(x, y), 0.8, paint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// ── Wave seam between brand panel and form panel ──────────────────────────

class _ResetWaveSeamPainter extends CustomPainter {
  const _ResetWaveSeamPainter();

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
        size.width * 0.55,
        size.height * 0.578,
      )
      ..cubicTo(
        size.width * 0.40,
        size.height * 0.70,
        size.width * 0.68,
        size.height * 0.78,
        size.width * 0.52,
        size.height * 0.90,
      )
      ..cubicTo(
        size.width * 0.40,
        size.height * 0.97,
        size.width * 0.48,
        size.height,
        size.width * 0.50,
        size.height,
      );

    final paint = Paint()
      ..color = Colors.white.withValues(alpha: 0.18)
      ..strokeWidth = 1.2
      ..style = PaintingStyle.stroke
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2.5);

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
