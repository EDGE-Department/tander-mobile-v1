import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:tander_flutter_v3/core/theme/app_curves.dart';
import 'package:tander_flutter_v3/core/theme/app_typography.dart';
import 'package:tander_flutter_v3/features/auth/presentation/notifiers/auth_notifier.dart';
import 'package:tander_flutter_v3/features/auth/presentation/widgets/auth_scene_decorations.dart';
import 'package:tander_flutter_v3/features/auth/presentation/widgets/login_background.dart';
import 'package:tander_flutter_v3/features/auth/presentation/widgets/login_desktop_hero.dart';
import 'package:tander_flutter_v3/features/auth/presentation/widgets/registration_step_dots.dart';
import 'package:tander_flutter_v3/features/auth/presentation/widgets/sign_up_form_card.dart';
import 'package:tander_flutter_v3/shared/constants/routes.dart';

/// Registration screen — Step 1 of 4 (Account Setup).
///
/// Matches login screen layout exactly:
///   - **Phone portrait**: gradient bg + header (constellation) + parchment sheet
///   - **Tablet portrait (768–1023)**: 42/58 split brand panel + form panel
///   - **Landscape/tablet (≥1024)**: 60/40 split DesktopHeroPanel + form panel
class SignUpScreen extends ConsumerStatefulWidget {
  const SignUpScreen({super.key});

  @override
  ConsumerState<SignUpScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends ConsumerState<SignUpScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _entrance;
  late final SimulatedOnlineCount _onlineCount;
  bool _isNavigating = false;

  @override
  void initState() {
    super.initState();
    _entrance = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    )..forward();
    _onlineCount = SimulatedOnlineCount();
  }

  @override
  void dispose() {
    _entrance.dispose();
    _onlineCount.dispose();
    super.dispose();
  }

  void _onBack() {
    if (_isNavigating) return;
    _isNavigating = true;
    HapticFeedback.lightImpact();
    // From the Create Account screen, the back button takes the user
    // straight to the login screen — they came here intending to sign up
    // and changing their mind almost always means "actually I have an
    // account, log me in" rather than re-running ID verification.
    context.go(AppRoutes.login);
  }

  void _onSignIn() {
    if (_isNavigating) return;
    _isNavigating = true;
    HapticFeedback.lightImpact();
    context.go(AppRoutes.login);
  }

  @override
  Widget build(BuildContext context) {
    if (_isNavigating) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _isNavigating = false;
      });
    }

    final screenSize = MediaQuery.sizeOf(context);
    final isWideLayout = screenSize.width >= 1024;
    final isTabletPortrait =
        screenSize.width >= 768 && screenSize.width < 1024;

    if (isWideLayout) return _buildLandscapeLayout(context);
    if (isTabletPortrait) return _buildTabletPortraitLayout(context);
    return _buildPhoneLayout(context, screenSize.height);
  }

  // ── Phone portrait ──────────────────────────────────────────────────

  Widget _buildPhoneLayout(BuildContext context, double screenHeight) {
    final headerHeight = resolveHeaderHeight(screenHeight);

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _onBack();
      },
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: Stack(
          children: [
            const Positioned.fill(
              child: IgnorePointer(
                child: DecoratedBox(
                  decoration: BoxDecoration(gradient: authGradient),
                ),
              ),
            ),
            SingleChildScrollView(
              child: Column(
                children: [
                  _SignUpHeaderSection(
                    headerHeight: headerHeight,
                    onlineCount: _onlineCount,
                    onBack: _onBack,
                  ),
                  Transform.translate(
                        offset: const Offset(0, -20),
                        child: _SignUpSheet(
                          child: Padding(
                            padding: const EdgeInsets.only(bottom: 32),
                            child: SignUpFormCard(
                              entrance: _entrance,
                              onSignIn: _onSignIn,
                              isBottomSheet: true,
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
          ],
        ),
      ),
    );
  }

  // ── Tablet portrait (42/58 split) ──────────────────────────────────

  Widget _buildTabletPortraitLayout(BuildContext context) {
    final screenWidth = MediaQuery.sizeOf(context).width;
    final leftPanelWidth = screenWidth * 0.42;

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _onBack();
      },
      child: Scaffold(
        body: Stack(
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                SizedBox(
                  width: leftPanelWidth,
                  child: _SignUpBrandPanel(
                    onlineCount: _onlineCount,
                    onBack: _onBack,
                  ),
                ),
                Expanded(
                  child: AuthParchmentFormPanel(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        const Center(
                          child: RegistrationStepDots(
                            currentStep: 1,
                            totalSteps: 4,
                          ),
                        ),
                        const SizedBox(height: 16),
                        SignUpFormCard(entrance: _entrance, onSignIn: _onSignIn)
                            .animate()
                            .fadeIn(
                              duration: 650.ms,
                              delay: 120.ms,
                              curve: AppCurves.premiumEase,
                            )
                            .slideX(
                              begin: 0.04,
                              curve: AppCurves.premiumEase,
                            ),
                      ],
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
                child: CustomPaint(painter: WaveSeamPainter()),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Landscape / wide tablet (60/40 split) ──────────────────────────

  Widget _buildLandscapeLayout(BuildContext context) {
    final screenWidth = MediaQuery.sizeOf(context).width;

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _onBack();
      },
      child: Scaffold(
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
                  child: AuthParchmentFormPanel(
                    maxWidth: 480,
                    padding: const EdgeInsets.all(40),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        const Center(
                          child: RegistrationStepDots(
                            currentStep: 1,
                            totalSteps: 4,
                          ),
                        ),
                        const SizedBox(height: 16),
                        SignUpFormCard(entrance: _entrance, onSignIn: _onSignIn)
                            .animate()
                            .fadeIn(
                              duration: 650.ms,
                              delay: 120.ms,
                              curve: AppCurves.premiumEase,
                            )
                            .slideY(
                              begin: 0.08,
                              curve: AppCurves.premiumEase,
                            ),
                      ],
                    ),
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
                child: CustomPaint(painter: WaveSeamPainter()),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Simple parchment sheet (matches login) ─────────────────────────────────

class _SignUpSheet extends StatelessWidget {
  const _SignUpSheet({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: child,
    );
  }
}

// ── Phone header section (matches login's _HeaderSection exactly) ────────────

class _SignUpHeaderSection extends StatelessWidget {
  const _SignUpHeaderSection({
    required this.headerHeight,
    required this.onlineCount,
    required this.onBack,
  });

  final double headerHeight;
  final SimulatedOnlineCount onlineCount;
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.sizeOf(context).width;
    final wordmarkSize = (screenWidth * 0.17).clamp(56.0, 72.0);

    return SizedBox(
      height: headerHeight + headerOverlap,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          // Ghost wordmark background (moved down closer to white Tander)
          Positioned.fill(
            child: IgnorePointer(
              child: Center(
                child: Transform.translate(
                  offset: Offset(0, (screenWidth * 0.26).clamp(82.0, 108.0) * 0.25),
                  child: Text(
                    'Tander',
                    style: AppTypography.brandWordmark(
                      fontSize: (screenWidth * 0.26).clamp(82.0, 108.0),
                      color: Colors.white.withValues(alpha: 0.09),
                      letterSpacing: -0.03 * (screenWidth * 0.26).clamp(82.0, 108.0),
                    ).copyWith(height: 1),
                  ),
                ),
              ),
            ),
          ),

          // Online badge — top-right
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
                  builder: (_, count, __) =>
                      OnlineCountBadge(count: count, useSeniorsLabel: false),
                ),
              ),
            ),
          ),

          // Back button — top-left
          Positioned(
            top: 0,
            left: 0,
            child: SafeArea(
              bottom: false,
              right: false,
              child: Padding(
                padding: const EdgeInsets.only(left: 16, top: 8),
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: onBack,
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
              ),
            ),
          ),

          // Brand content — logo and wordmark (matching login)
          Positioned.fill(
            child: SafeArea(
              bottom: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(24, 8, 24, 16),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.start,
                  children: [
                    // Logo
                    ClipOval(
                      child: Image.asset(
                        'assets/icons/tander_icon.png',
                        width: 60,
                        height: 60,
                        semanticLabel: 'Tander logo',
                      ),
                    ),

                    // Wordmark
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
          ),
        ],
      ),
    );
  }
}

// ── Tablet portrait brand panel (matches login's brand panel) ────────

class _SignUpBrandPanel extends StatelessWidget {
  const _SignUpBrandPanel({
    required this.onlineCount,
    required this.onBack,
  });

  final SimulatedOnlineCount onlineCount;
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    final panelWidth = MediaQuery.sizeOf(context).width * 0.42;
    final ghostSize = (panelWidth * 0.60).clamp(140.0, 220.0);

    return Container(
      decoration: const BoxDecoration(gradient: authGradient),
      child: Stack(
        children: [
          const Positioned.fill(
            child: IgnorePointer(
              child: Opacity(
                opacity: 0.9,
                child: CustomPaint(painter: AuthConstellationPainter()),
              ),
            ),
          ),
          const Positioned.fill(
            child: IgnorePointer(
              child: Opacity(
                opacity: 0.05,
                child: CustomPaint(painter: AuthGrainPainter()),
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
          SafeArea(
            right: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(24, 20, 24, 32),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: onBack,
                      customBorder: const CircleBorder(),
                      child: Container(
                        width: 44,
                        height: 44,
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
                          size: 22,
                        ),
                      ),
                    ),
                  ),
                  const Spacer(),
                  Text(
                    'CREATE YOUR ACCOUNT',
                    style: TextStyle(
                      fontSize: 9,
                      fontWeight: FontWeight.w700,
                      color: Colors.white.withValues(alpha: 0.65),
                      letterSpacing: 2.8,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Image.asset(
                    'assets/icons/tander_icon.png',
                    width: 56,
                    height: 56,
                    semanticLabel: 'Tander logo',
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Step 1 of 4\nAccount Setup',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Colors.white.withValues(alpha: 0.85),
                      height: 1.3,
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
