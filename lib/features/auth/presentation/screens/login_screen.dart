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
import 'package:tander_flutter_v3/features/auth/presentation/notifiers/auth_notifier.dart';
import 'package:tander_flutter_v3/features/auth/presentation/states/auth_state.dart';
import 'package:tander_flutter_v3/features/auth/presentation/widgets/login_background.dart';
import 'package:tander_flutter_v3/features/auth/presentation/widgets/login_connection_showcase.dart';
import 'package:tander_flutter_v3/features/auth/presentation/widgets/login_desktop_hero.dart';
import 'package:tander_flutter_v3/features/auth/presentation/widgets/login_form_card.dart';
import 'package:tander_flutter_v3/shared/constants/routes.dart';

/// How far the parchment sheet visually overlaps the header (paint-only).
/// Smaller than [headerOverlap] so the online badge has clearance above the sheet.
const double _mobileSheetVisualOverlap = 8;

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
    context.push(AppRoutes.idScanner);
  }

  void _listenToAuthState() {
    ref.listen<AuthState>(authNotifierProvider, (_, next) {
      switch (next) {
        case AuthAuthenticated():
          context.go(AppRoutes.home);
        case AuthOnboarding(:final phase):
          _navigateToOnboardingPhase(phase);
        case AuthError():
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
      RegistrationPhase.pendingEmailVerification => AppRoutes.emailVerification,
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

  @override
  Widget build(BuildContext context) {
    _listenToAuthState();

    final authState = ref.watch(authNotifierProvider);
    final isLoading = authState is AuthLoading;
    final errorMessage = authState is AuthError
        ? authState.exception.userMessage
        : null;

    final screenSize = MediaQuery.sizeOf(context);
    final headerHeight = resolveHeaderHeight(screenSize.height);

    final isLandscapeLayout = screenSize.width >= 1024;
    final isTabletPortraitLayout =
        screenSize.width >= 768 && screenSize.width < 1024;
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

class _TabletPortraitBrandPanel extends StatelessWidget {
  const _TabletPortraitBrandPanel({required this.onlineCount});

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
          const Positioned.fill(
            child: IgnorePointer(
              child: Opacity(
                opacity: 0.9,
                child: CustomPaint(painter: _MobileConstellationPainter()),
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
                  valueListenable: onlineCount,
                  builder: (_, count, __) => OnlineCountBadge(count: count),
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
            child: const IgnorePointer(child: _MobilePortraitHeaderScene()),
          ),
          SafeArea(
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
                          width: 62,
                          height: 62,
                          semanticLabel: 'Tander logo',
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Tander',
                          style: AppTypography.brandWordmark(
                            fontSize: 40,
                            color: Colors.white,
                            letterSpacing: -0.8,
                          ),
                        ),
                      ],
                    ),
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
        ],
      ),
    );
  }
}

class _MobilePortraitHeaderScene extends StatelessWidget {
  const _MobilePortraitHeaderScene();

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(30),
      child: Stack(
        fit: StackFit.expand,
        children: [
          const Positioned.fill(
            child: Opacity(
              opacity: 0.05,
              child: CustomPaint(painter: _MobileSceneGrainPainter()),
            ),
          ),
          const Positioned.fill(
            child: IgnorePointer(
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                child: Opacity(
                  opacity: 0.9,
                  child: CustomPaint(painter: _MobileConstellationPainter()),
                ),
              ),
            ),
          ),
          Positioned.fill(
            child: IgnorePointer(
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final fontSize = clampDouble(
                    constraints.maxWidth * 0.34,
                    116,
                    176,
                  );
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

class _ConstellationNode {
  const _ConstellationNode(this.x, this.y, this.radius, this.color);

  final double x;
  final double y;
  final double radius;
  final Color color;
}

class _MobileConstellationPainter extends CustomPainter {
  const _MobileConstellationPainter();

  static const List<_ConstellationNode> _nodes = [
    _ConstellationNode(0.12, 0.34, 2.2, Color(0xE6FFA05A)),
    _ConstellationNode(0.25, 0.24, 1.7, Color(0xBFFFFFFF)),
    _ConstellationNode(0.23, 0.58, 1.6, Color(0x8CFFFFFF)),
    _ConstellationNode(0.39, 0.46, 2.1, Color(0xCCFFFFFF)),
    _ConstellationNode(0.50, 0.50, 4.4, Color(0xFFFFFFFF)),
    _ConstellationNode(0.61, 0.45, 2.1, Color(0xCCFFFFFF)),
    _ConstellationNode(0.76, 0.24, 1.7, Color(0xD996E6DF)),
    _ConstellationNode(0.85, 0.42, 2.3, Color(0xE678DCD7)),
    _ConstellationNode(0.78, 0.62, 1.8, Color(0x8CFFFFFF)),
    _ConstellationNode(0.50, 0.16, 1.7, Color(0xA6FFFFFF)),
    _ConstellationNode(0.05, 0.20, 1.4, Color(0xB3FFB464)),
    _ConstellationNode(0.95, 0.18, 1.4, Color(0xB396E6DF)),
  ];

  static const List<List<int>> _normalEdges = [
    [0, 1],
    [0, 3],
    [2, 3],
    [5, 6],
    [5, 7],
    [7, 8],
    [9, 4],
    [10, 0],
    [11, 6],
  ];

  static const List<List<int>> _bridgeEdges = [
    [3, 4],
    [4, 5],
  ];

  @override
  void paint(Canvas canvas, Size size) {
    final linePaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.10)
      ..strokeWidth = 0.75
      ..style = PaintingStyle.stroke;

    final bridgePaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.36)
      ..strokeWidth = 1.05
      ..style = PaintingStyle.stroke
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 1.2);

    for (final edge in _normalEdges) {
      final from = _resolve(size, _nodes[edge[0]]);
      final to = _resolve(size, _nodes[edge[1]]);
      canvas.drawLine(from, to, linePaint);
    }

    for (final edge in _bridgeEdges) {
      final from = _resolve(size, _nodes[edge[0]]);
      final to = _resolve(size, _nodes[edge[1]]);
      canvas.drawLine(from, to, bridgePaint);
    }

    final hubGlowPaint = Paint()
      ..color = const Color(0x66FFFFFF)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 12);
    final hubCenter = _resolve(size, _nodes[4]);
    canvas.drawCircle(hubCenter, 18, hubGlowPaint);

    for (final node in _nodes) {
      final offset = _resolve(size, node);
      final glowPaint = Paint()
        ..color = node.color.withValues(alpha: 0.28)
        ..maskFilter = MaskFilter.blur(
          BlurStyle.normal,
          node.radius >= 4 ? 8 : 3,
        );
      final fillPaint = Paint()..color = node.color;
      canvas.drawCircle(offset, node.radius * 2.2, glowPaint);
      canvas.drawCircle(offset, node.radius, fillPaint);
    }
  }

  static Offset _resolve(Size size, _ConstellationNode node) {
    const horizontalScale = 1.08;
    const verticalScale = 0.90;
    const horizontalInset = 0.08;
    const verticalInset = 0.10;

    final resolvedX = clampDouble(
      0.5 + (node.x - 0.5) * horizontalScale,
      horizontalInset,
      1 - horizontalInset,
    );
    final resolvedY = clampDouble(
      0.5 + (node.y - 0.5) * verticalScale,
      verticalInset,
      1 - verticalInset,
    );

    return Offset(size.width * resolvedX, size.height * resolvedY);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
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
