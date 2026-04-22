import 'package:flutter/material.dart';
import '../widgets/verification/responsive_layout.dart';
import '../widgets/verification/primary_action_button.dart';
import '../widgets/verification/verification_step_card.dart';
import 'liveness_screen.dart';

class ReadyToVerifyScreen extends StatelessWidget {
  const ReadyToVerifyScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      body: SafeArea(
        child: ResponsiveLayout(
          mobileSmall: (context, constraints) => _buildMobile(context, isSmall: true),
          mobileNormal: (context, constraints) => _buildMobile(context, isSmall: false),
          tabletPortrait: (context, constraints) => _buildTabletPortrait(context),
          tabletLandscape: (context, constraints) => _buildTabletLandscape(context),
        ),
      ),
    );
  }

  Widget _buildMobile(BuildContext context, {required bool isSmall}) {
    return Column(
      children: [
        Expanded(
          child: SingleChildScrollView(
            padding: EdgeInsets.all(isSmall ? 16.0 : 24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(height: isSmall ? 10 : 20),
                _buildHeader(isSmall: isSmall),
                SizedBox(height: isSmall ? 24 : 40),
                _buildSteps(isSmall: isSmall),
              ],
            ),
          ),
        ),
        _buildBottomBar(context, isSmall: isSmall),
      ],
    );
  }

  Widget _buildTabletPortrait(BuildContext context) {
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 600),
        child: _buildMobile(context, isSmall: false),
      ),
    );
  }

  Widget _buildTabletLandscape(BuildContext context) {
    return Row(
      children: [
        Expanded(
          flex: 1,
          child: Container(
            color: const Color(0xFF5BBFB3).withOpacity(0.05),
            padding: const EdgeInsets.all(40.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildHeader(isSmall: false, isLandscape: true),
              ],
            ),
          ),
        ),
        Expanded(
          flex: 1,
          child: Padding(
            padding: const EdgeInsets.all(40.0),
            child: Column(
              children: [
                Expanded(
                  child: SingleChildScrollView(
                    child: _buildSteps(isSmall: false),
                  ),
                ),
                _buildBottomBar(context, isSmall: false, isLandscape: true),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildHeader({required bool isSmall, bool isLandscape = false}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(
          Icons.verified_user_rounded,
          size: isSmall ? 48 : (isLandscape ? 80 : 64),
          color: const Color(0xFF5BBFB3),
        ),
        SizedBox(height: isSmall ? 16 : 24),
        Text(
          'Let\'s verify\nyour identity',
          style: TextStyle(
            fontSize: isSmall ? 28 : (isLandscape ? 40 : 36),
            fontWeight: FontWeight.w900,
            height: 1.1,
            letterSpacing: -0.5,
            color: Colors.black87,
          ),
        ),
        SizedBox(height: isSmall ? 12 : 16),
        Text(
          'To keep our community safe, we need to make sure you\'re really you.',
          style: TextStyle(
            fontSize: isSmall ? 15 : (isLandscape ? 18 : 16),
            color: Colors.black54,
            height: 1.4,
          ),
        ),
      ],
    );
  }

  Widget _buildSteps({required bool isSmall}) {
    return Column(
      children: [
        VerificationStepCard(
          stepNumber: 1,
          title: 'Scan your ID',
          description: 'Take a clear photo of your government-issued ID card.',
          icon: Icons.badge_outlined,
          isSmallPhone: isSmall,
        ),
        VerificationStepCard(
          stepNumber: 2,
          title: 'Take a selfie',
          description: 'Hold steady while we make sure it\'s you in real life.',
          icon: Icons.face_retouching_natural,
          isSmallPhone: isSmall,
        ),
        VerificationStepCard(
          stepNumber: 3,
          title: 'Get approved',
          description: 'Fast and secure verification process.',
          icon: Icons.check_circle_outline,
          isSmallPhone: isSmall,
        ),
      ],
    );
  }

  Widget _buildBottomBar(BuildContext context, {required bool isSmall, bool isLandscape = false}) {
    return Container(
      padding: EdgeInsets.all(isSmall ? 16 : (isLandscape ? 0 : 24)),
      decoration: isLandscape
          ? null
          : BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  offset: const Offset(0, -4),
                  blurRadius: 16,
                ),
              ],
            ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                Icon(Icons.lock_outline, size: 16, color: Colors.grey[600]),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Your data is securely encrypted and never shared.',
                    style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            PrimaryActionButton(
              label: 'Start Verification',
              icon: Icons.camera_alt_outlined,
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const LivenessScreen()),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
