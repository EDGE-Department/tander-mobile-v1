import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../shared/constants/routes.dart';
import '../../../../shared/widgets/fade_slide_transition.dart';
import '../notifiers/auth_notifier.dart';
import '../widgets/registration_step_dots.dart';
import '../widgets/sign_up_form_card.dart';
import '../widgets/sign_up_header.dart';

/// Registration screen — Step 1 of 4 (Account Setup).
///
/// Portrait: 30/70 split — gradient top with logo/title, white bottom sheet
/// with drag handle, step dots, and form card.
/// Landscape (tablet): side-by-side header + form card.
class SignUpScreen extends ConsumerStatefulWidget {
  const SignUpScreen({super.key});

  @override
  ConsumerState<SignUpScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends ConsumerState<SignUpScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _entrance;
  bool _isNavigating = false;

  @override
  void initState() {
    super.initState();
    _entrance = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    )..forward();
  }

  @override
  void dispose() {
    _entrance.dispose();
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

    final screen = MediaQuery.sizeOf(context);
    final isLandscape = screen.width > screen.height;
    final isTablet = screen.shortestSide >= 600;

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _onBack();
      },
      child: Scaffold(
        body: Stack(
          children: [
            // Gradient background
            Container(
              width: screen.width,
              height: screen.height,
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Color(0xFF1A0800),
                    Color(0xFF2D1810),
                    Color(0xFF0D3D38),
                  ],
                  stops: [0.0, 0.45, 1.0],
                  begin: Alignment.topLeft,
                  end: Alignment(0.3, 1.0),
                ),
              ),
            ),
            // Floating orbs
            Positioned(
              left: screen.width * -0.15,
              top: screen.height * -0.08,
              child: Container(
                width: isTablet ? 300 : 220,
                height: isTablet ? 300 : 220,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withValues(alpha: 0.08),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.1),
                  ),
                ),
              ),
            ),
            Positioned(
              left: screen.width * 0.75,
              top: screen.height * 0.35,
              child: Container(
                width: isTablet ? 200 : 150,
                height: isTablet ? 200 : 150,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withValues(alpha: 0.08),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.1),
                  ),
                ),
              ),
            ),
            // Content
            SafeArea(
              child: isLandscape && isTablet ? _landscape() : _portrait(),
            ),
          ],
        ),
      ),
    );
  }

  // --- Portrait Layout (30/70 split) ---

  Widget _portrait() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Expanded(
          flex: 3,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
            child: Column(
              children: [
                _buildNavRow(),
                Expanded(
                  child: Center(
                    child: Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: SignUpHeader(
                        entrance: _entrance,
                        compact: true,
                        showStepIndicator: false,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        Expanded(
          flex: 7,
          child: _buildBottomSheet(),
        ),
      ],
    );
  }

  Widget _buildNavRow() {
    return Row(
      children: [
        _backButton(),
        const Spacer(),
        _buildStepPill(),
        const Spacer(),
        const SizedBox(width: 48),
      ],
    );
  }

  Widget _backButton() {
    return FadeSlideTransition(
      animation: _entrance,
      interval: const Interval(0.0, 0.25, curve: Curves.easeOut),
      slideY: 10,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: _onBack,
          customBorder: const CircleBorder(),
          child: Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white.withValues(alpha: 0.18),
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.3),
                width: 1,
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
    );
  }

  Widget _buildStepPill() {
    return FadeSlideTransition(
      animation: _entrance,
      interval: const Interval(0.05, 0.30, curve: Curves.easeOut),
      slideY: 8,
      child: Container(
        padding: const EdgeInsets.all(1.2),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFFFF7849), Color(0xFF0D9488)],
          ),
          borderRadius: BorderRadius.circular(999),
        ),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
          decoration: BoxDecoration(
            color: Colors.black.withValues(alpha: 0.22),
            borderRadius: BorderRadius.circular(999),
          ),
          child: Text(
            'Step 1 of 4  \u2022  Account Setup',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: Colors.white.withValues(alpha: 0.95),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBottomSheet() {
    return FadeSlideTransition(
      animation: _entrance,
      interval: const Interval(0.20, 0.55, curve: Curves.easeOut),
      slideY: 60,
      child: Container(
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
        child: ClipRRect(
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(36),
            topRight: Radius.circular(36),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Padding(
                padding: const EdgeInsets.only(top: 12, bottom: 4),
                child: Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFFFF7849), Color(0xFF0D9488)],
                      ),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
              ),
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                child: FadeSlideTransition(
                  animation: _entrance,
                  interval:
                      const Interval(0.25, 0.50, curve: Curves.easeOut),
                  slideY: 0,
                  child: const RegistrationStepDots(
                    currentStep: 1,
                    totalSteps: 4,
                  ),
                ),
              ),
              Expanded(
                child: SingleChildScrollView(
                  keyboardDismissBehavior:
                      ScrollViewKeyboardDismissBehavior.onDrag,
                  padding: const EdgeInsets.fromLTRB(24, 12, 24, 40),
                  child: SignUpFormCard(
                    entrance: _entrance,
                    onSignIn: _onSignIn,
                    isBottomSheet: true,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // --- Landscape Layout (tablets only) ---

  Widget _landscape() {
    return Row(
      children: [
        Expanded(
          flex: 2,
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              children: [
                Align(
                  alignment: Alignment.centerLeft,
                  child: _backButton(),
                ),
                const SizedBox(height: 40),
                SignUpHeader(entrance: _entrance, compact: true),
              ],
            ),
          ),
        ),
        Container(
          width: 1,
          margin: const EdgeInsets.symmetric(vertical: 40),
          color: Colors.white.withValues(alpha: 0.25),
        ),
        Expanded(
          flex: 3,
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(32),
            child: SignUpFormCard(
              entrance: _entrance,
              onSignIn: _onSignIn,
            ),
          ),
        ),
      ],
    );
  }
}
