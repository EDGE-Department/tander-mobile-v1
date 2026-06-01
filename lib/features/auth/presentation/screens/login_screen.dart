import 'dart:math' as math;
import 'dart:ui' show ImageFilter;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:tander_flutter_v3/core/auth/session_manager.dart';
import 'package:tander_flutter_v3/core/theme/app_curves.dart';
import 'package:tander_flutter_v3/core/theme/app_typography.dart';
import 'package:tander_flutter_v3/core/utils/device_utils.dart';
import 'package:tander_flutter_v3/features/auth/presentation/notifiers/auth_notifier.dart';
import 'package:tander_flutter_v3/features/auth/presentation/states/auth_state.dart';
import 'package:tander_flutter_v3/features/auth/presentation/widgets/account_suspended_dialog.dart';
import 'package:tander_flutter_v3/features/auth/presentation/widgets/login_background.dart';
import 'package:tander_flutter_v3/features/auth/presentation/widgets/login_connection_showcase.dart';
import 'package:tander_flutter_v3/features/auth/presentation/widgets/login_desktop_hero.dart';
import 'package:tander_flutter_v3/features/auth/presentation/widgets/login_form_card.dart';
import 'package:tander_flutter_v3/features/splash/presentation/widgets/splash_painters.dart';
import 'package:tander_flutter_v3/shared/constants/routes.dart';

/// Web: -mt-10 = 40px overlap of form panel over brand zone.
const double _mobileSheetVisualOverlap = 40;

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

  @override
  void initState() {
    super.initState();
    _onlineCount = SimulatedOnlineCount();
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
  }

  @override
  void dispose() {
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    _emailController.dispose();
    _passwordController.dispose();
    _emailFocusNode.dispose();
    _passwordFocusNode.dispose();
    _scrollController.dispose();
    _onlineCount.dispose();
    super.dispose();
  }

  void _submitForm() {
    if (!_formKey.currentState!.validate()) return;

    ref
        .read(authNotifierProvider.notifier)
        .signIn(
          email: _emailController.text.trim(),
          password: _passwordController.text,
        );
  }

  void _togglePasswordVisibility() {
    setState(() => _isPasswordVisible = !_isPasswordVisible);
  }

  void _navigateToForgotPassword() {
    context.push(AppRoutes.forgotPassword);
  }

  void _navigateToRegister() {
    context.push(AppRoutes.readyToVerify);
  }

  void _listenToAuthState() {
    ref.listen<AuthState>(authNotifierProvider, (_, next) {
      switch (next) {
        case AuthAuthenticated():
          context.go(AppRoutes.home);
        case AuthOnboarding(:final phase):
          _navigateToOnboardingPhase(phase);
        case AuthError(:final exception):
          if (exception.code == 'account-suspended') {
            AccountSuspendedDialog.show(context, message: exception.message);
          } else {
            _scrollToTop();
          }
        case AuthInitial():
        case AuthLoading():
        case AuthUnauthenticated():
          break;
      }
    });
  }

  void _navigateToOnboardingPhase(RegistrationPhase phase) {
    final route = switch (phase) {
      RegistrationPhase.pendingProfileSetup => AppRoutes.profileSetup,
      RegistrationPhase.pendingPhotoSetup => AppRoutes.photoSetup,
      // pendingIdVerification is never emitted mid-onboarding in the current
      // flow (ID is verified pre-registration), so route it to home as a safe
      // default rather than back to profileSetup which would cause a loop.
      // Matches _onboardingRouteForPhase in app/router/app_router.dart.
      RegistrationPhase.pendingIdVerification => AppRoutes.home,
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

  @override
  Widget build(BuildContext context) {
    _listenToAuthState();

    final authState = ref.watch(authNotifierProvider);
    final isLoading = authState is AuthLoading;
    // Suppress the inline error banner when the suspended modal is taking
    // over — otherwise the user sees both at once.
    final errorMessage = authState is AuthError
        ? (authState.exception.code == 'account-suspended'
              ? null
              : authState.exception.userMessage)
        : null;

    final screenSize = MediaQuery.sizeOf(context);
    // Reduced header height to bring form closer to branding
    final headerHeight = screenSize.height * 0.22;

    final isLandscapeLayout = screenSize.width >= 1024;
    // Narrow tablets (shortestSide > 600dp, e.g. Galaxy Tab S9 FE at ~753dp
    // wide in portrait) sit just under the raw 768dp cutoff and would fall
    // through to the phone layout. Add DeviceUtils.isTablet so they get the
    // proper two-panel tablet login that fills the screen — consistent with
    // wider tablets and the app's shortestSide-based tablet detection.
    final isTabletPortraitLayout =
        !isLandscapeLayout &&
        (screenSize.width >= 768 || DeviceUtils.isTablet(context));
    final formCardLayout = isLandscapeLayout
        ? LoginFormCardLayout.desktop
        : isTabletPortraitLayout
        ? LoginFormCardLayout.tablet
        : LoginFormCardLayout.mobile;

    final formCard = LoginFormCard(
      formKey: _formKey,
      emailController: _emailController,
      passwordController: _passwordController,
      emailFocusNode: _emailFocusNode,
      passwordFocusNode: _passwordFocusNode,
      isPasswordVisible: _isPasswordVisible,
      isLoading: isLoading,
      errorMessage: errorMessage,
      onTogglePassword: _togglePasswordVisibility,
      onSubmit: _submitForm,
      onForgotPassword: _navigateToForgotPassword,
      onRegister: _navigateToRegister,
      layout: formCardLayout,
    );

    if (isLandscapeLayout) {
      return _LandscapeLoginLayout(
        scrollController: _scrollController,
        onlineCount: _onlineCount,
        formCard: formCard,
      );
    }

    if (isTabletPortraitLayout) {
      return _TabletPortraitLayout(
        scrollController: _scrollController,
        onlineCount: _onlineCount,
        formCard: formCard,
      );
    }

    return _PhonePortraitLayout(
      scrollController: _scrollController,
      headerHeight: headerHeight,
      onlineCount: _onlineCount,
      formCard: formCard,
    );
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties.add(
      DiagnosticsProperty<bool>('isPasswordVisible', _isPasswordVisible),
    );
  }
}

class _PhonePortraitLayout extends StatelessWidget {
  const _PhonePortraitLayout({
    required this.scrollController,
    required this.headerHeight,
    required this.onlineCount,
    required this.formCard,
  });

  final ScrollController scrollController;
  final double headerHeight;
  final SimulatedOnlineCount onlineCount;
  final Widget formCard;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Stack(
        // Expand so the gradient + content fill the full viewport. Without this
        // the only non-positioned child (the scroll view) shrink-wraps to its
        // content height, collapsing the Stack and leaving the dark window
        // background exposed as a black band below the form (seen on tall
        // tablets, e.g. Galaxy Tab S9 FE).
        fit: StackFit.expand,
        children: [
          const Positioned.fill(
            child: IgnorePointer(
              child: DecoratedBox(
                decoration: BoxDecoration(gradient: _mobileAuthGradient),
              ),
            ),
          ),
          SingleChildScrollView(
            controller: scrollController,
            child: Column(
              children: [
                _HeaderSection(
                  headerHeight: headerHeight,
                  onlineCount: onlineCount,
                ),
                Transform.translate(
                      offset: const Offset(0, -_mobileSheetVisualOverlap),
                      child: _MobileParchmentSheet(
                        child: Padding(
                          padding: const EdgeInsets.only(bottom: 32),
                          child: formCard,
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
        ],
      ),
    );
  }
}

class _MobileParchmentSheet extends StatelessWidget {
  const _MobileParchmentSheet({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: child,
    );
  }
}

class _TabletPortraitLayout extends StatelessWidget {
  const _TabletPortraitLayout({
    required this.scrollController,
    required this.onlineCount,
    required this.formCard,
  });

  final ScrollController scrollController;
  final SimulatedOnlineCount onlineCount;
  final Widget formCard;

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.sizeOf(context).width;
    final leftPanelWidth = screenWidth * 0.42;

    return Scaffold(
      body: Stack(
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Left 42% — gradient brand world
              SizedBox(
                width: leftPanelWidth,
                child: _TabletPortraitBrandPanel(onlineCount: onlineCount),
              ),
              // Right 58% — parchment form world
              Expanded(
                child: _TabletPortraitFormPanel(
                  scrollController: scrollController,
                  formCard: formCard,
                ),
              ),
            ],
          ),
          // Organic wave seam at the 42% boundary
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
}

class _TabletPortraitBrandPanel extends StatefulWidget {
  const _TabletPortraitBrandPanel({required this.onlineCount});

  final SimulatedOnlineCount onlineCount;

  @override
  State<_TabletPortraitBrandPanel> createState() =>
      _TabletPortraitBrandPanelState();
}

class _TabletPortraitBrandPanelState extends State<_TabletPortraitBrandPanel>
    with SingleTickerProviderStateMixin {
  late final AnimationController _constellationCtrl;

  @override
  void initState() {
    super.initState();
    _constellationCtrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 15),
    )..repeat();
  }

  @override
  void dispose() {
    _constellationCtrl.dispose();
    super.dispose();
  }

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
          // Aurora blobs
          Positioned.fill(
            child: IgnorePointer(
              child: Stack(
                children: [
                  Positioned(
                    top: -20,
                    left: -20,
                    width: panelWidth * 0.75,
                    height: 260,
                    child: Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(130),
                        gradient: const RadialGradient(
                          colors: [
                            Color(0x70FF8C46),
                            Color(0x38F06432),
                            Colors.transparent,
                          ],
                          stops: [0.0, 0.45, 0.70],
                        ),
                      ),
                    ),
                  ),
                  Positioned(
                    bottom: -20,
                    right: -20,
                    width: panelWidth * 0.65,
                    height: 220,
                    child: Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(110),
                        gradient: const RadialGradient(
                          colors: [
                            Color(0x472EC88C),
                            Color(0x240FA094),
                            Colors.transparent,
                          ],
                          stops: [0.0, 0.45, 0.70],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          // Constellation
          Positioned.fill(
            child: IgnorePointer(
              child: Opacity(
                opacity: 0.45,
                child: AnimatedBuilder(
                  animation: _constellationCtrl,
                  builder: (_, _) => CustomPaint(
                    painter: SplashConstellationPainter(
                      _constellationCtrl.value,
                    ),
                  ),
                ),
              ),
            ),
          ),
          // Grain
          const Positioned.fill(
            child: IgnorePointer(
              child: Opacity(
                opacity: 0.05,
                child: CustomPaint(painter: _MobileSceneGrainPainter()),
              ),
            ),
          ),
          // Design signature: vertical "Tander" chancery ghost at 7%
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
          // Online badge — top-right, SafeArea-aware
          Positioned(
            top: 0,
            right: 0,
            child: SafeArea(
              child: Padding(
                padding: const EdgeInsets.only(top: 20, right: 20),
                child: ValueListenableBuilder<int>(
                  valueListenable: widget.onlineCount,
                  builder: (_, count, _) => OnlineCountBadge(count: count),
                ),
              ),
            ),
          ),
          // Brand content — left-aligned, scrollable
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
                  const _MobileFilipinoValuesMarquee(),
                  const SizedBox(height: 20),
                  // ConnectionShowcase glass card
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

class _TabletPortraitFormPanel extends StatelessWidget {
  const _TabletPortraitFormPanel({
    required this.scrollController,
    required this.formCard,
  });

  final ScrollController scrollController;
  final Widget formCard;

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
                controller: scrollController,
                padding: const EdgeInsets.all(32),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 400),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      formCard
                          .animate()
                          .fadeIn(
                            duration: 650.ms,
                            delay: 120.ms,
                            curve: AppCurves.premiumEase,
                          )
                          .slideX(begin: 0.04, curve: AppCurves.premiumEase),
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
}

class _LandscapeLoginLayout extends StatelessWidget {
  const _LandscapeLoginLayout({
    required this.scrollController,
    required this.onlineCount,
    required this.formCard,
  });

  final ScrollController scrollController;
  final SimulatedOnlineCount onlineCount;
  final Widget formCard;

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.sizeOf(context).width;

    return Scaffold(
      body: Stack(
        children: [
          Row(
            children: [
              Expanded(
                flex: 60,
                child: DesktopHeroPanel(onlineCount: onlineCount),
              ),
              Expanded(
                flex: 40,
                child: _LandscapeRightPanel(
                  scrollController: scrollController,
                  formCard: formCard,
                ),
              ),
            ],
          ),
          Positioned(
            left: screenWidth * 0.6 - 64,
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
}

class _LandscapeRightPanel extends StatelessWidget {
  const _LandscapeRightPanel({
    required this.scrollController,
    required this.formCard,
  });

  final ScrollController scrollController;
  final Widget formCard;

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
                controller: scrollController,
                padding: const EdgeInsets.all(40),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 480),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      formCard
                          .animate()
                          .fadeIn(
                            duration: 650.ms,
                            delay: 120.ms,
                            curve: AppCurves.premiumEase,
                          )
                          .slideY(begin: 0.08, curve: AppCurves.premiumEase),
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

class _HeaderSection extends StatelessWidget {
  const _HeaderSection({required this.headerHeight, required this.onlineCount});

  final double headerHeight;
  final SimulatedOnlineCount onlineCount;

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.sizeOf(context).width;
    final wordmarkSize = (screenWidth * 0.17).clamp(56.0, 72.0);

    return SizedBox(
      height: headerHeight + headerOverlap,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          // DESIGN SIGNATURE — horizontal chancery wordmark ghosted at 9%, spans full width
          // web: fontSize: clamp(82px, 26vw, 108px), opacity: 0.09, translateY(-8%)
          Positioned.fill(
            child: IgnorePointer(
              child: Center(
                child: Transform.translate(
                  offset: Offset(
                    0,
                    -(screenWidth * 0.26).clamp(82.0, 108.0) * 0.08,
                  ),
                  child: Text(
                    'Tander',
                    style: AppTypography.brandWordmark(
                      fontSize: (screenWidth * 0.26).clamp(82.0, 108.0),
                      color: Colors.white.withValues(alpha: 0.09),
                      letterSpacing:
                          -0.03 * (screenWidth * 0.26).clamp(82.0, 108.0),
                    ).copyWith(height: 1),
                  ),
                ),
              ),
            ),
          ),

          // Online badge — absolute top-right
          Positioned(
            top: 0,
            right: 0,
            child: SafeArea(
              bottom: false,
              left: false,
              child: Padding(
                padding: const EdgeInsets.only(right: 20, top: 8),
                child: ValueListenableBuilder<int>(
                  valueListenable: onlineCount,
                  builder: (_, count, _) =>
                      OnlineCountBadge(count: count, useSeniorsLabel: false),
                ),
              ),
            ),
          ).animate().fadeIn(duration: 600.ms, delay: 100.ms),

          // Brand content — positioned near top
          Positioned.fill(
            child: SafeArea(
              bottom: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.start,
                  children: [
                    // Logo
                    ClipOval(
                          child: Image.asset(
                            'assets/icons/tander_icon.png',
                            width: 68,
                            height: 68,
                            semanticLabel: 'Tander logo',
                          ),
                        )
                        .animate()
                        .fadeIn(duration: 650.ms, delay: 100.ms)
                        .scale(
                          begin: const Offset(0.9, 0.9),
                          end: const Offset(1, 1),
                          curve: AppCurves.premiumEase,
                        ),
                    const SizedBox(height: 2),

                    // Wordmark (web: staggered entrance, but here unified for performance)
                    Text(
                          'Tander',
                          style:
                              AppTypography.brandWordmark(
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
                        )
                        .animate()
                        .fadeIn(duration: 600.ms, delay: 200.ms)
                        .moveY(begin: 8, end: 0, curve: AppCurves.premiumEase),
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

class _MobileFilipinoValuesMarquee extends StatefulWidget {
  const _MobileFilipinoValuesMarquee();

  @override
  State<_MobileFilipinoValuesMarquee> createState() =>
      _MobileFilipinoValuesMarqueeState();
}

class _MobileFilipinoValuesMarqueeState
    extends State<_MobileFilipinoValuesMarquee>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  static const _text =
      'PAGMAMAHAL \u00B7 TIWALA \u00B7 SAMA-SAMA \u00B7 TAHANAN '
      '\u00B7 KWENTUHAN \u00B7 MALASAKIT';

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 36),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    const style = TextStyle(
      color: Color(0x33FFFFFF), // white 20%
      fontSize: 8,
      fontWeight: FontWeight.w600,
      textBaseline: TextBaseline.alphabetic,
      letterSpacing: 0.24 * 8,
    );

    return SizedBox(
      height: 12,
      child: ClipRect(
        child: AnimatedBuilder(
          animation: _controller,
          builder: (_, _) {
            const contentWidth = 1200.0;
            final offset = -_controller.value * contentWidth;
            return Transform.translate(
              offset: Offset(offset, 0),
              child: const SizedBox(
                width: contentWidth * 2,
                child: Text(
                  '$_text     $_text     $_text     ',
                  style: style,
                  maxLines: 1,
                  overflow: TextOverflow.visible,
                  softWrap: false,
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

class _MobilePortraitHeaderScene extends StatefulWidget {
  const _MobilePortraitHeaderScene();

  @override
  State<_MobilePortraitHeaderScene> createState() =>
      _MobilePortraitHeaderSceneState();
}

class _MobilePortraitHeaderSceneState extends State<_MobilePortraitHeaderScene>
    with SingleTickerProviderStateMixin {
  late final AnimationController _constellationCtrl;

  @override
  void initState() {
    super.initState();
    _constellationCtrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 15),
    )..repeat();
  }

  @override
  void dispose() {
    _constellationCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final h = constraints.maxHeight;
        final w = constraints.maxWidth;

        return Stack(
          fit: StackFit.expand,
          children: [
            // Aurora blob — orange top-left (web: width 58%, height 72%, top -18%, left -10%)
            Positioned(
              top: -h * 0.18,
              left: -w * 0.10,
              child: Container(
                width: w * 0.58,
                height: h * 0.72,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      Color(0x47FF9656), // rgba(255,150,86,0.28)
                      Color(0x1FDC6937), // rgba(220,105,55,0.12)
                      Colors.transparent,
                    ],
                    stops: [0.0, 0.48, 0.74],
                  ),
                ),
              ),
            ),
            // Aurora blob — teal bottom-right (web: width 42%, height 58%, right -8%, bottom -4%)
            Positioned(
              bottom: -h * 0.04,
              right: -w * 0.08,
              child: Container(
                width: w * 0.42,
                height: h * 0.58,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      Color(0x2960D6BC), // rgba(96,214,188,0.16)
                      Color(0x0F1C927A), // rgba(28,146,122,0.06)
                      Colors.transparent,
                    ],
                    stops: [0.0, 0.44, 0.74],
                  ),
                ),
              ),
            ),

            // Film grain
            const Positioned.fill(
              child: Opacity(
                opacity: 0.05,
                child: CustomPaint(painter: _MobileSceneGrainPainter()),
              ),
            ),

            // Constellation — web's 19-node version at 45% opacity
            Positioned.fill(
              child: IgnorePointer(
                child: Opacity(
                  opacity: 0.45,
                  child: AnimatedBuilder(
                    animation: _constellationCtrl,
                    builder: (_, _) => CustomPaint(
                      painter: SplashConstellationPainter(
                        _constellationCtrl.value,
                      ),
                    ),
                  ),
                ),
              ),
            ),

            // "60+" watermark (web: opacity 0.05, translateY 8%)
            Positioned.fill(
              child: IgnorePointer(
                child: Center(
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      final fontSize = clampDouble(
                        constraints.maxWidth * 0.34,
                        116,
                        176,
                      );
                      return Transform.translate(
                        offset: Offset(0, fontSize * 0.08),
                        child: Text(
                          '60+',
                          style: TextStyle(
                            fontFamily: AppTypography.displayFontFamily,
                            fontWeight: FontWeight.w900,
                            fontSize: fontSize,
                            color: Colors.white.withValues(alpha: 0.05),
                            height: 1,
                            letterSpacing: -0.05 * fontSize,
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ),
            ),

            // Bottom vignette (web: opacity 0.42 -> 0.12 -> transparent)
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              height: h * 0.40,
              child: const DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.bottomCenter,
                    end: Alignment.topCenter,
                    colors: [
                      Color(0x6B120400), // rgba(18,4,0,0.42)
                      Color(0x1F0A0200), // rgba(10,2,0,0.12)
                      Colors.transparent,
                    ],
                    stops: [0.0, 0.55, 1.0],
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

class _MobileSceneGrainPainter extends CustomPainter {
  const _MobileSceneGrainPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = Colors.white;
    final random = math.Random(42);
    for (int index = 0; index < 520; index++) {
      canvas.drawCircle(
        Offset(
          random.nextDouble() * size.width,
          random.nextDouble() * size.height,
        ),
        0.2 + random.nextDouble() * 0.6,
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
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
        size.width * 0.72,
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

    canvas.drawPath(
      path,
      Paint()
        ..color = const Color(0x38E6A03C)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1
        ..strokeCap = StrokeCap.round,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
