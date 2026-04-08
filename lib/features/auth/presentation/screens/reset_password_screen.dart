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
    return Scaffold(
      backgroundColor: AppColors.card,
      body: DecoratedBox(
        decoration: const BoxDecoration(gradient: _parchmentGradient),
        child: SafeArea(
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
                              constraints: const BoxConstraints(maxWidth: 720),
                              child: _buildFormCard(isWide: true),
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
      ),
    );
  }

  // ── Phone portrait ─────────────────────────────────────────────────

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
                  _ResetPasswordMobileHeader(
                    headerHeight: headerHeight,
                    onlineCount: _onlineCount,
                  ),
                  Transform.translate(
                        offset: const Offset(0, -headerOverlap),
                        child: _MobileParchmentSheet(
                          child: Padding(
                            padding: const EdgeInsets.only(bottom: 32),
                            child: _buildFormCard(isWide: false),
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
