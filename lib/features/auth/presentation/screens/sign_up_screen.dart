import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:tander_flutter_v3/core/theme/app_colors.dart';
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

  Future<void> _onBack() async {
    if (_isNavigating) return;
    _isNavigating = true;
    HapticFeedback.lightImpact();

    int minimumAge = 60;
    try {
      minimumAge =
          await ref.read(authNotifierProvider.notifier).getMinimumAge();
    } catch (_) {
      // Fallback default.
    }

    if (!mounted) {
      _isNavigating = false;
      return;
    }
    context.go('${AppRoutes.idScanner}?minimumAge=$minimumAge');
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
                        offset: const Offset(0, -8),
                        child: _SignUpSheet(
                          child: Padding(
                            padding: const EdgeInsets.only(bottom: 32),
                            child: Column(
                              children: [
                                const Padding(
                                  padding: EdgeInsets.symmetric(
                                    horizontal: 24,
                                    vertical: 8,
                                  ),
                                  child: RegistrationStepDots(
                                    currentStep: 1,
                                    totalSteps: 4,
                                  ),
                                ),
                                Padding(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 24,
                                    vertical: 12,
                                  ),
                                  child: SignUpFormCard(
                                    entrance: _entrance,
                                    onSignIn: _onSignIn,
                                    isBottomSheet: true,
                                  ),
                                ),
                              ],
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

// ── Solid white bottom sheet ─────────────────────────────────────────

class _SignUpSheet extends StatelessWidget {
  const _SignUpSheet({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(36),
          topRight: Radius.circular(36),
        ),
        boxShadow: [
          BoxShadow(
            color: Color(0x1A000000),
            offset: Offset(0, -8),
            blurRadius: 24,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: 12),
          const AuthSheetHandle(),
          const SizedBox(height: 4),
          child,
        ],
      ),
    );
  }
}

// ── Phone header section (matches login's _HeaderSection) ────────────

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
            child: const IgnorePointer(child: AuthHeaderScene()),
          ),
          SafeArea(
            bottom: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 2, 16, 8),
              child: Column(
                children: [
                  _buildNavRow(context),
                  const Spacer(),
                  Image.asset(
                    'assets/icons/tander_icon.png',
                    width: 40,
                    height: 40,
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
                  const SizedBox(height: 8),
                  ValueListenableBuilder<int>(
                    valueListenable: onlineCount,
                    builder: (_, count, __) =>
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

  Widget _buildNavRow(BuildContext context) {
    return Row(
      children: [
        Material(
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
        const Spacer(),
        Container(
          padding: const EdgeInsets.all(1.2),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFFFF7849), Color(0xFF0D9488)],
            ),
            borderRadius: BorderRadius.circular(999),
          ),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.22),
              borderRadius: BorderRadius.circular(999),
            ),
            child: Text(
              'Step 1 of 4',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: Colors.white.withValues(alpha: 0.95),
              ),
            ),
          ),
        ),
        const Spacer(),
        const SizedBox(width: 40),
      ],
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
