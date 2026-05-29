import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:tander_flutter_v3/features/auth/presentation/widgets/auth_scene_decorations.dart';
import 'package:tander_flutter_v3/features/auth/presentation/widgets/verification/primary_action_button.dart';
import 'package:tander_flutter_v3/shared/constants/routes.dart';
import 'package:tander_flutter_v3/shared/utils/launch_support_email.dart';

enum VerificationResultState {
  success,
  duplicateIdDetected,
  faceMismatch,
  ageRequirementNotMet,
  fraudDetected,
  rateLimited,
  idBlocked,
  idInCooldown,
}

class VerificationResultScreen extends StatefulWidget {
  final VerificationResultState state;
  final Duration? cooldownDuration;
  // Pass-through nuance fields used only by the duplicateIdDetected switch arm.
  // emailHint is the masked email surfaced by the backend duplicate-ID response;
  // existingAccountState is the literal backend enum ('PROFILE_INCOMPLETE' /
  // 'PROFILE_COMPLETE') used to swap copy and the primary-button label.
  final String? emailHint;
  final String? existingAccountState;

  const VerificationResultScreen({
    super.key,
    required this.state,
    this.cooldownDuration,
    this.emailHint,
    this.existingAccountState,
  });

  @override
  State<VerificationResultScreen> createState() =>
      _VerificationResultScreenState();
}

class _VerificationResultScreenState extends State<VerificationResultScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _animController;
  late Animation<double> _scaleAnimation;
  Timer? _timer;
  Duration _remainingTime = Duration.zero;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _scaleAnimation = CurvedAnimation(
      parent: _animController,
      curve: Curves.elasticOut,
    );
    _animController.forward();

    if (widget.state == VerificationResultState.rateLimited ||
        widget.state == VerificationResultState.idInCooldown) {
      _remainingTime = widget.cooldownDuration ?? const Duration(minutes: 5);
      _startTimer();
    }
  }

  void _startTimer() {
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_remainingTime.inSeconds > 0) {
        setState(() {
          _remainingTime = _remainingTime - const Duration(seconds: 1);
        });
      } else {
        timer.cancel();
      }
    });
  }

  @override
  void dispose() {
    _animController.dispose();
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isSmall = MediaQuery.sizeOf(context).height < 700;
    return Scaffold(
      backgroundColor: const Color(0xFF20BF68),
      // Terminal screen (success or failure) — no step header, just the
      // gradient backdrop + parchment, matching the absence-of-step idiom.
      body: AuthStepScaffoldBody(
        parchment: AuthStepParchment(
          scrollable: false,
          contentPadding: EdgeInsets.fromLTRB(
            isSmall ? 16 : 24,
            8,
            isSmall ? 16 : 24,
            16,
          ),
          child: _buildContent(isSmall: isSmall),
        ),
      ),
    );
  }

  Widget _buildContent({required bool isSmall}) {
    final uiData = _getUIData(widget.state);

    // Respect reduce-motion: skip the elastic bounce and show the icon at
    // full scale immediately (same idiom as StepBadgeEntry / _triggerErrorShake).
    final reduceMotion = MediaQuery.disableAnimationsOf(context);

    final iconBadge = Container(
      padding: EdgeInsets.all(isSmall ? 24 : 32),
      decoration: BoxDecoration(
        color: uiData.color.withValues(alpha: 0.1),
        shape: BoxShape.circle,
      ),
      child: Icon(
        uiData.icon,
        size: isSmall ? 64 : 80,
        color: uiData.color,
      ),
    );

    final content = Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        reduceMotion
            ? iconBadge
            : ScaleTransition(scale: _scaleAnimation, child: iconBadge),
        SizedBox(height: isSmall ? 24 : 40),
        Text(
          uiData.title,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: isSmall ? 24 : 30,
            fontWeight: FontWeight.w900,
            letterSpacing: -0.5,
            color: Colors.black87,
          ),
        ),
        SizedBox(height: isSmall ? 12 : 16),
        Padding(
          padding: EdgeInsets.symmetric(horizontal: isSmall ? 16.0 : 32.0),
          child: Text(
            uiData.description,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: isSmall ? 15 : 16,
              color: Colors.black54,
              height: 1.4,
            ),
          ),
        ),
        if (widget.state == VerificationResultState.duplicateIdDetected &&
            widget.emailHint != null) ...[
          const SizedBox(height: 16),
          _buildEmailHintChip(widget.emailHint!),
        ],
        if (_remainingTime.inSeconds > 0) ...[
          const SizedBox(height: 24),
          _buildTimerWidget(isSmall),
        ],
      ],
    );

    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 600),
        child: Column(
          children: [
            Expanded(
              child: Center(child: SingleChildScrollView(child: content)),
            ),
            _buildActions(uiData, isSmall: isSmall),
          ],
        ),
      ),
    );
  }

  Widget _buildEmailHintChip(String maskedEmail) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFFFEF7EE),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.email_outlined, size: 18, color: Colors.grey[600]),
          const SizedBox(width: 8),
          Text(
            maskedEmail,
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[700],
              fontFamily: 'monospace',
              letterSpacing: 0.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTimerWidget(bool isSmall) {
    final String minutes = (_remainingTime.inSeconds ~/ 60).toString().padLeft(
      2,
      '0',
    );
    final String seconds = (_remainingTime.inSeconds % 60).toString().padLeft(
      2,
      '0',
    );

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFFE86035).withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(30),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.timer_outlined, color: Color(0xFFE86035)),
          const SizedBox(width: 8),
          Text(
            '$minutes:$seconds',
            style: TextStyle(
              fontSize: isSmall ? 20 : 24,
              fontWeight: FontWeight.bold,
              color: const Color(0xFFE86035),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActions(_ResultUIData uiData, {required bool isSmall}) {
    return SafeArea(
      top: false,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          PrimaryActionButton(
            label: uiData.primaryButtonText,
            color: uiData.color,
            onPressed: () => _handlePrimaryAction(),
          ),
          if (uiData.secondaryButtonText != null) ...[
            const SizedBox(height: 12),
            TextButton(
              onPressed: () => _handleSecondaryAction(),
              style: TextButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                minimumSize: const Size(double.infinity, 56),
              ),
              child: Text(
                uiData.secondaryButtonText!,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey[700],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  void _handlePrimaryAction() {
    switch (widget.state) {
      case VerificationResultState.success:
        // ID verified! Go to sign-up to complete registration with contact/password
        context.go(AppRoutes.signUp);
        break;
      case VerificationResultState.faceMismatch:
      case VerificationResultState.rateLimited:
      case VerificationResultState.idInCooldown:
        // Retry - go back to verification flow
        context.go(AppRoutes.readyToVerify);
        break;
      case VerificationResultState.duplicateIdDetected:
      case VerificationResultState.fraudDetected:
      case VerificationResultState.idBlocked:
      case VerificationResultState.ageRequirementNotMet:
        // Navigate back to login for blocked/fraud cases
        context.go(AppRoutes.login);
        break;
    }
  }

  void _handleSecondaryAction() {
    switch (widget.state) {
      case VerificationResultState.duplicateIdDetected:
        // Entry is pushReplacement from ID Scanner — no back-stack to popUntil.
        // Mirror the deleted modal's "Contact Support" affordance: surface the
        // support email then land on login.
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Contact us at support@tander.app'),
            backgroundColor: const Color(0xFF5BBFB3),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        );
        context.go(AppRoutes.login);
        break;
      case VerificationResultState.faceMismatch:
        launchSupportEmail(
          context,
          subject: 'ID verification issue',
        );
        break;
      default:
        Navigator.of(context).pop();
        break;
    }
  }

  _ResultUIData _getUIData(VerificationResultState state) {
    const teal = Color(0xFF5BBFB3);
    const orange = Color(0xFFE86035);
    const grey = Colors.blueGrey;

    switch (state) {
      case VerificationResultState.success:
        return _ResultUIData(
          title: 'You\'re Verified!',
          description:
              'Thank you for keeping our community safe. You now have full access to all features.',
          icon: Icons.verified_rounded,
          color: teal,
          primaryButtonText: 'Continue',
        );
      case VerificationResultState.duplicateIdDetected:
        final isIncompleteProfile =
            widget.existingAccountState == 'PROFILE_INCOMPLETE';
        return _ResultUIData(
          title: isIncompleteProfile
              ? 'Finish Your Registration'
              : 'ID Already Registered',
          description: isIncompleteProfile
              ? "You already have an account but haven't finished your profile yet. Log in to continue setting it up."
              : 'This ID has already been used to create an account. If this is your ID, please log in to your existing account.',
          icon: Icons.person_search_rounded,
          color: orange,
          primaryButtonText: isIncompleteProfile
              ? 'Log in to continue'
              : 'Go to Login',
          secondaryButtonText: 'Contact Support',
        );
      case VerificationResultState.faceMismatch:
        return _ResultUIData(
          title: 'Face Doesn\'t Match',
          description:
              'We couldn\'t match your selfie with the photo on your ID. Make sure you\'re in a well-lit area and looking directly at the camera.',
          icon: Icons.face_retouching_off,
          color: orange,
          primaryButtonText: 'Try Again',
          secondaryButtonText: 'Contact Support',
        );
      case VerificationResultState.ageRequirementNotMet:
        return _ResultUIData(
          title: 'Age Requirement',
          description:
              'We\'re sorry, but you must be at least 60 years old to join this community.',
          icon: Icons.cake_outlined,
          color: grey,
          // Both actions led to login; 'Learn More' was misleading (there is no
          // destination to learn more). Collapse to a single clear exit.
          primaryButtonText: 'Back to Sign In',
        );
      case VerificationResultState.fraudDetected:
        return _ResultUIData(
          title: 'Verification Unsuccessful',
          description:
              'We couldn\'t verify your identity automatically. Please reach out to our team for a manual review.',
          icon: Icons.gpp_bad_outlined,
          color: orange,
          primaryButtonText: 'Contact Support',
        );
      case VerificationResultState.rateLimited:
        return _ResultUIData(
          title: 'Too Many Attempts',
          description:
              'You\'ve reached the maximum number of verification attempts. Please wait a moment before trying again.',
          icon: Icons.hourglass_bottom_rounded,
          color: orange,
          primaryButtonText: 'Try Again',
        );
      case VerificationResultState.idBlocked:
        return _ResultUIData(
          title: 'ID Cannot Be Used',
          description:
              'This ID has been restricted from our platform. If you think this is a mistake, please contact support.',
          icon: Icons.block_outlined,
          color: grey,
          primaryButtonText: 'Contact Support',
        );
      case VerificationResultState.idInCooldown:
        return _ResultUIData(
          title: 'Please Wait',
          description:
              'This ID was recently used in a failed attempt. Please wait before trying again.',
          icon: Icons.timer_outlined,
          color: orange,
          primaryButtonText: 'Try Again',
        );
    }
  }
}

class _ResultUIData {
  final String title;
  final String description;
  final IconData icon;
  final Color color;
  final String primaryButtonText;
  final String? secondaryButtonText;

  _ResultUIData({
    required this.title,
    required this.description,
    required this.icon,
    required this.color,
    required this.primaryButtonText,
    this.secondaryButtonText,
  });
}
