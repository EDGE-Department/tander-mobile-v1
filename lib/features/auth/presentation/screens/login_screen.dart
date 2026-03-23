import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:tander_flutter_v3/core/auth/session_manager.dart';
import 'package:tander_flutter_v3/core/theme/app_colors.dart';
import 'package:tander_flutter_v3/core/theme/app_curves.dart';
import 'package:tander_flutter_v3/core/theme/app_typography.dart';
import 'package:tander_flutter_v3/features/auth/presentation/notifiers/auth_notifier.dart';
import 'package:tander_flutter_v3/features/auth/presentation/states/auth_state.dart';
import 'package:tander_flutter_v3/features/auth/presentation/widgets/login_background.dart';
import 'package:tander_flutter_v3/features/auth/presentation/widgets/login_desktop_hero.dart';
import 'package:tander_flutter_v3/features/auth/presentation/widgets/login_form_card.dart';
import 'package:tander_flutter_v3/shared/constants/routes.dart';

/// Login screen matching the web's mobile layout pixel-for-pixel.
///
/// Structure: gradient header (dark warm -> teal) with logo, wordmark,
/// "Welcome Back" heading, online badge, then a white form panel that
/// overlaps the header by 24px with `rounded-t-[36px]`.
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
  final _scrollController = ScrollController();
  late final SimulatedOnlineCount _onlineCount;

  bool _isPasswordVisible = false;
  bool _rememberMe = false;

  @override
  void initState() {
    super.initState();
    _onlineCount = SimulatedOnlineCount();
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _emailFocusNode.dispose();
    _passwordFocusNode.dispose();
    _scrollController.dispose();
    _onlineCount.dispose();
    super.dispose();
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
    setState(() => _isPasswordVisible = !_isPasswordVisible);
  }

  void _toggleRememberMe() {
    setState(() => _rememberMe = !_rememberMe);
  }

  void _navigateToForgotPassword() {
    context.push(AppRoutes.forgotPassword);
  }

  // ── Auth state listener ─────────────────────────────────────────

  void _listenToAuthState() {
    ref.listen<AuthState>(authNotifierProvider, (_, next) {
      switch (next) {
        case AuthAuthenticated():
          context.go(AppRoutes.home);
        case AuthOnboarding(:final phase):
          _navigateToOnboardingPhase(phase);
        case AuthError():
          // Error is displayed inline via the form card banner.
          // Scroll to top so the user sees it.
          _scrollToTop();
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

  void _scrollToTop() {
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        0,
        duration: AppDurations.entrance,
        curve: AppCurves.premiumEase,
      );
    }
  }

  // ── Build ───────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    _listenToAuthState();

    final authState = ref.watch(authNotifierProvider);
    final isLoading = authState is AuthLoading;
    final errorMessage = authState is AuthError
        ? authState.exception.userMessage
        : null;

    final screenHeight = MediaQuery.sizeOf(context).height;
    final headerHeight = resolveHeaderHeight(screenHeight);

    // Detect tablet landscape: web shows split-panel at lg: (1024px+)
    final screenSize = MediaQuery.sizeOf(context);
    final isWideLayout = screenSize.shortestSide > 600 ||
        (screenSize.width > screenSize.height && screenSize.width > 900);

    final formCard = ValueListenableBuilder<int>(
      valueListenable: _onlineCount,
      builder: (_, count, _) => LoginFormCard(
        formKey: _formKey,
        emailController: _emailController,
        passwordController: _passwordController,
        emailFocusNode: _emailFocusNode,
        passwordFocusNode: _passwordFocusNode,
        isPasswordVisible: _isPasswordVisible,
        rememberMe: _rememberMe,
        isLoading: isLoading,
        errorMessage: errorMessage,
        onTogglePassword: _togglePasswordVisibility,
        onToggleRememberMe: _toggleRememberMe,
        onSubmit: _submitForm,
        onForgotPassword: _navigateToForgotPassword,
        onlineCount: count,
      ),
    );

    if (isWideLayout) {
      // ── TABLET/LANDSCAPE: split-panel (60% hero + 40% form) ──
      return Scaffold(
        body: Row(
          children: [
            // Left panel: gradient hero (60%)
            Expanded(
              flex: 60,
              child: DesktopHeroPanel(onlineCount: _onlineCount),
            ),
            // Right panel: form card on warm parchment (40%)
            Expanded(
              flex: 40,
              child: Container(
                color: const Color(0xFFFEFAF4), // warm parchment
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 440),
                    child: SingleChildScrollView(
                      controller: _scrollController,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 32,
                        vertical: 40,
                      ),
                      child: formCard,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      );
    }

    // ── PHONE PORTRAIT: stacked header + form ──
    return Scaffold(
      backgroundColor: AppColors.card,
      body: SingleChildScrollView(
        controller: _scrollController,
        child: Column(
          children: [
            _HeaderSection(
              headerHeight: headerHeight,
              onlineCount: _onlineCount,
            ),
            Transform.translate(
              offset: const Offset(0, -headerOverlap),
              child: formCard,
            ),
          ],
        ),
      ),
    );
  }

  @override
  void debugFillProperties(
    DiagnosticPropertiesBuilder properties,
  ) {
    super.debugFillProperties(properties);
    properties
      ..add(DiagnosticsProperty<bool>(
        'isPasswordVisible',
        _isPasswordVisible,
      ))
      ..add(DiagnosticsProperty<bool>('rememberMe', _rememberMe));
  }
}

// ── Header section ──────────────────────────────────────────────────

/// The gradient header containing logo, wordmark, "Welcome Back"
/// heading, subtext, Tagalog line, and online count badge.
///
/// Matches the web's `lg:hidden` mobile header block.
class _HeaderSection extends StatelessWidget {
  const _HeaderSection({
    required this.headerHeight,
    required this.onlineCount,
  });

  final double headerHeight;
  final SimulatedOnlineCount onlineCount;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: headerHeight + headerOverlap, // Extra space for overlap
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          LoginHeaderBackground(headerHeight: headerHeight + headerOverlap),

          // Content overlay
          Positioned.fill(
            child: SafeArea(
              bottom: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(24, 14, 24, 32),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    // Logo + wordmark
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Image.asset(
                          'assets/icons/tander_logo.png',
                          width: 32,
                          height: 32,
                          semanticLabel: 'Tander logo',
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Tander',
                          style: AppTypography.h2.copyWith(
                            fontSize: 20,
                            color: Colors.white,
                            letterSpacing: -0.3,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),

                    // "Welcome Back" heading
                    Text(
                      'Welcome Back',
                      style: AppTypography.h1.copyWith(
                        fontSize: 27,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                        letterSpacing: -0.5,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 6),

                    // Subheading
                    Text(
                      'Your community is waiting for you',
                      style: AppTypography.bodySm.copyWith(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        color: Colors.white.withValues(alpha: 0.75),
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 4),

                    // Tagalog line
                    Text(
                      'Nandito na kami \u00B7 We\u2019re here',
                      style: AppTypography.caption.copyWith(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        fontStyle: FontStyle.italic,
                        color: Colors.white.withValues(alpha: 0.45),
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 12),

                    // Online count badge
                    ValueListenableBuilder<int>(
                      valueListenable: onlineCount,
                      builder: (_, count, _) => OnlineCountBadge(count: count),
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
