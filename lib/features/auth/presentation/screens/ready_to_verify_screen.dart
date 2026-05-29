import 'package:flutter/material.dart';
import 'package:tander_flutter_v3/core/theme/app_colors.dart';
import 'package:tander_flutter_v3/features/auth/presentation/screens/id_scanner_screen.dart';
import 'package:tander_flutter_v3/features/auth/presentation/widgets/auth_scene_decorations.dart';
import 'package:tander_flutter_v3/features/auth/presentation/widgets/verification/primary_action_button.dart';
import 'package:tander_flutter_v3/features/auth/presentation/widgets/verification/verification_step_card.dart';

/// Ready-to-verify step (unnumbered) — explains the ID-scan flow before
/// launching the camera. Uses the canonical auth step scaffold so it matches
/// the rest of the registration cycle.
class ReadyToVerifyScreen extends StatelessWidget {
  const ReadyToVerifyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final isSmall = MediaQuery.sizeOf(context).height < 700;

    return Scaffold(
      backgroundColor: const Color(0xFF20BF68),
      body: AuthStepScaffoldBody(
        header: const AuthStepHeader(currentStep: null),
        parchment: AuthStepParchment(
          scrollable: false,
          contentPadding: EdgeInsets.fromLTRB(
            isSmall ? 16 : 24,
            8,
            isSmall ? 16 : 24,
            16,
          ),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 600),
              child: Column(
                children: [
                  Expanded(
                    child: SingleChildScrollView(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildHeader(isSmall: isSmall),
                          SizedBox(height: isSmall ? 24 : 32),
                          _buildSteps(isSmall: isSmall),
                          SizedBox(height: isSmall ? 8 : 12),
                          _buildPhotoTips(isSmall: isSmall),
                        ],
                      ),
                    ),
                  ),
                  _buildBottomBar(context, isSmall: isSmall),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader({required bool isSmall}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(
          Icons.verified_user_rounded,
          size: isSmall ? 48 : 64,
          color: const Color(0xFF5BBFB3),
        ),
        SizedBox(height: isSmall ? 16 : 24),
        Text(
          'Let\'s verify\nyour identity',
          style: TextStyle(
            fontSize: isSmall ? 28 : 36,
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
            fontSize: isSmall ? 15 : 16,
            color: Colors.black54,
            height: 1.4,
          ),
        ),
        SizedBox(height: isSmall ? 8 : 10),
        Text(
          'This step is required to finish setting up your account.',
          style: TextStyle(
            fontSize: isSmall ? 15 : 16,
            fontWeight: FontWeight.w600,
            color: AppColors.textBody,
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
          title: 'Get approved',
          description: 'Fast and secure verification process.',
          icon: Icons.check_circle_outline,
          isSmallPhone: isSmall,
        ),
      ],
    );
  }

  Widget _buildPhotoTips({required bool isSmall}) {
    const tips = [
      'Find good lighting',
      'Lay your ID flat on a dark surface',
      'Avoid glare and shadows',
    ];

    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(isSmall ? 14 : 18),
      decoration: BoxDecoration(
        color: const Color(0xFF5BBFB3).withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.lightbulb_outline,
                size: 20,
                color: Color(0xFF3E9B90),
              ),
              const SizedBox(width: 8),
              Text(
                'Tips for a clear photo',
                style: TextStyle(
                  fontSize: isSmall ? 15 : 16,
                  fontWeight: FontWeight.w700,
                  color: Colors.black87,
                ),
              ),
            ],
          ),
          SizedBox(height: isSmall ? 8 : 10),
          for (final tip in tips)
            Padding(
              padding: EdgeInsets.only(bottom: isSmall ? 6 : 8),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Padding(
                    padding: EdgeInsets.only(top: 2),
                    child: Icon(
                      Icons.check_rounded,
                      size: 18,
                      color: Color(0xFF3E9B90),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      tip,
                      style: const TextStyle(
                        fontSize: 15,
                        color: AppColors.textBody,
                        height: 1.4,
                      ),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildBottomBar(BuildContext context, {required bool isSmall}) {
    return SafeArea(
      top: false,
      child: Padding(
        padding: EdgeInsets.only(top: isSmall ? 8 : 12),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Row(
              children: [
                Icon(
                  Icons.lock_outline,
                  size: 20,
                  color: AppColors.textMuted,
                ),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Your data is securely encrypted and never shared.',
                    style: TextStyle(
                      fontSize: 16,
                      height: 1.4,
                      color: AppColors.textMuted,
                    ),
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
                  MaterialPageRoute(builder: (_) => const IdScannerScreen()),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
