import 'package:flutter/material.dart';
import 'dart:async';
import 'package:go_router/go_router.dart';
import '../../../../shared/constants/routes.dart';
import '../widgets/verification/responsive_layout.dart';
import '../widgets/verification/primary_action_button.dart';

enum VerificationResultState {
  success,
  duplicateIdDetected,
  faceMismatch,
  ageRequirementNotMet,
  fraudDetected,
  rateLimited,
  livenessCheckFailed,
  livenessWeakEvidence,
  idBlocked,
  idInCooldown,
}

class VerificationResultScreen extends StatefulWidget {
  final VerificationResultState state;
  final Duration? cooldownDuration;

  const VerificationResultScreen({
    Key? key,
    required this.state,
    this.cooldownDuration,
  }) : super(key: key);

  @override
  State<VerificationResultScreen> createState() => _VerificationResultScreenState();
}

class _VerificationResultScreenState extends State<VerificationResultScreen> with SingleTickerProviderStateMixin {
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

    if (widget.state == VerificationResultState.rateLimited || widget.state == VerificationResultState.idInCooldown) {
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
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      body: SafeArea(
        child: ResponsiveLayout(
          mobileSmall: (context, constraints) => _buildContent(isSmall: true, isLandscape: false),
          mobileNormal: (context, constraints) => _buildContent(isSmall: false, isLandscape: false),
          tabletPortrait: (context, constraints) => Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 600),
              child: _buildContent(isSmall: false, isLandscape: false),
            ),
          ),
          tabletLandscape: (context, constraints) => _buildContent(isSmall: false, isLandscape: true),
        ),
      ),
    );
  }

  Widget _buildContent({required bool isSmall, required bool isLandscape}) {
    final uiData = _getUIData(widget.state);
    
    final content = Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        ScaleTransition(
          scale: _scaleAnimation,
          child: Container(
            padding: EdgeInsets.all(isSmall ? 24 : 32),
            decoration: BoxDecoration(
              color: uiData.color.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              uiData.icon,
              size: isSmall ? 64 : (isLandscape ? 100 : 80),
              color: uiData.color,
            ),
          ),
        ),
        SizedBox(height: isSmall ? 24 : 40),
        Text(
          uiData.title,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: isSmall ? 24 : (isLandscape ? 36 : 30),
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
              fontSize: isSmall ? 15 : (isLandscape ? 18 : 16),
              color: Colors.black54,
              height: 1.4,
            ),
          ),
        ),
        if (_remainingTime.inSeconds > 0) ...[
          const SizedBox(height: 24),
          _buildTimerWidget(isSmall),
        ],
      ],
    );

    if (isLandscape) {
      return Row(
        children: [
          Expanded(
            flex: 1,
            child: Padding(
              padding: const EdgeInsets.all(40.0),
              child: content,
            ),
          ),
          Expanded(
            flex: 1,
            child: Padding(
              padding: const EdgeInsets.all(60.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _buildActions(uiData, isSmall: false),
                ],
              ),
            ),
          ),
        ],
      );
    }

    return Padding(
      padding: EdgeInsets.all(isSmall ? 16.0 : 24.0),
      child: Column(
        children: [
          Expanded(
            child: Center(
              child: SingleChildScrollView(
                child: content,
              ),
            ),
          ),
          _buildActions(uiData, isSmall: isSmall),
        ],
      ),
    );
  }

  Widget _buildTimerWidget(bool isSmall) {
    String minutes = (_remainingTime.inSeconds ~/ 60).toString().padLeft(2, '0');
    String seconds = (_remainingTime.inSeconds % 60).toString().padLeft(2, '0');
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFFE86035).withOpacity(0.1),
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
    return Column(
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
    );
  }

  void _handlePrimaryAction() {
    switch (widget.state) {
      case VerificationResultState.success:
        // ID verified! Go to sign-up to complete registration with contact/password
        context.go(AppRoutes.signUp);
        break;
      case VerificationResultState.faceMismatch:
      case VerificationResultState.livenessCheckFailed:
      case VerificationResultState.livenessWeakEvidence:
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
      case VerificationResultState.ageRequirementNotMet:
        Navigator.of(context).popUntil((route) => route.isFirst);
        break;
      case VerificationResultState.faceMismatch:
      case VerificationResultState.livenessCheckFailed:
        // TODO: Navigate to support/contact screen
        Navigator.of(context).popUntil((route) => route.isFirst);
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
          description: 'Thank you for keeping our community safe. You now have full access to all features.',
          icon: Icons.verified_rounded,
          color: teal,
          primaryButtonText: 'Continue',
        );
      case VerificationResultState.duplicateIdDetected:
        return _ResultUIData(
          title: 'ID Already Registered',
          description: 'This ID has already been used to verify an account. For security, each ID can only be used once.',
          icon: Icons.file_copy_outlined,
          color: orange,
          primaryButtonText: 'Contact Support',
          secondaryButtonText: 'Back to Login',
        );
      case VerificationResultState.faceMismatch:
        return _ResultUIData(
          title: 'Face Doesn\'t Match',
          description: 'We couldn\'t match your selfie with the photo on your ID. Make sure you\'re in a well-lit area and looking directly at the camera.',
          icon: Icons.face_retouching_off,
          color: orange,
          primaryButtonText: 'Try Again',
          secondaryButtonText: 'Contact Support',
        );
      case VerificationResultState.ageRequirementNotMet:
        return _ResultUIData(
          title: 'Age Requirement',
          description: 'We\'re sorry, but you must be at least 60 years old to join this community.',
          icon: Icons.cake_outlined,
          color: grey,
          primaryButtonText: 'Learn More',
          secondaryButtonText: 'Back to Start',
        );
      case VerificationResultState.fraudDetected:
        return _ResultUIData(
          title: 'Verification Unsuccessful',
          description: 'We couldn\'t verify your identity automatically. Please reach out to our team for a manual review.',
          icon: Icons.gpp_bad_outlined,
          color: orange,
          primaryButtonText: 'Contact Support',
        );
      case VerificationResultState.rateLimited:
        return _ResultUIData(
          title: 'Too Many Attempts',
          description: 'You\'ve reached the maximum number of verification attempts. Please wait a moment before trying again.',
          icon: Icons.hourglass_bottom_rounded,
          color: orange,
          primaryButtonText: 'Try Again',
        );
      case VerificationResultState.livenessCheckFailed:
        return _ResultUIData(
          title: 'Liveness Check Failed',
          description: 'We couldn\'t verify that there is a live person holding the device. Please hold steady and try again.',
          icon: Icons.person_off_outlined,
          color: orange,
          primaryButtonText: 'Try Again',
          secondaryButtonText: 'Cancel',
        );
      case VerificationResultState.livenessWeakEvidence:
        return _ResultUIData(
          title: 'Better Lighting Needed',
          description: 'The image was too blurry or dark. Find a well-lit spot and keep the device steady.',
          icon: Icons.light_mode_outlined,
          color: orange,
          primaryButtonText: 'Try Again',
        );
      case VerificationResultState.idBlocked:
        return _ResultUIData(
          title: 'ID Cannot Be Used',
          description: 'This ID has been restricted from our platform. If you think this is a mistake, please contact support.',
          icon: Icons.block_outlined,
          color: grey,
          primaryButtonText: 'Contact Support',
        );
      case VerificationResultState.idInCooldown:
        return _ResultUIData(
          title: 'Please Wait',
          description: 'This ID was recently used in a failed attempt. Please wait before trying again.',
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
