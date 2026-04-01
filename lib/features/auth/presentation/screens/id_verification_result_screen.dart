import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import '../../../../core/theme/app_colors.dart';
import '../widgets/auth_status_screen.dart';

enum IdVerificationResultType {
  success,
  ageRejected,
  fraudRejected,
  retakePhoto,
  error,
}

enum IdVerificationResultAction {
  continueRegistration,
  retryScan,
  exitFlow,
}

/// Full-screen ID verification result page.
class IdVerificationResultScreen extends StatelessWidget {
  final IdVerificationResultType resultType;
  final int minimumAge;
  final String? message;
  final int? extractedAge;
  final String? retakeGuidance;

  const IdVerificationResultScreen({
    super.key,
    required this.resultType,
    this.minimumAge = 60,
    this.message,
    this.extractedAge,
    this.retakeGuidance,
  });

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      child: AuthStatusScreen(
        icon: _statusIcon(),
        title: _title,
        message: message ?? _defaultMessage,
        detail: _detail(),
        actions: _actions(context),
      ),
    );
  }

  Widget _statusIcon() {
    final (IconData icon, Color color) = switch (resultType) {
      IdVerificationResultType.success =>
        (PhosphorIconsDuotone.checkCircle, AppColors.success),
      IdVerificationResultType.ageRejected =>
        (PhosphorIconsDuotone.warningCircle, AppColors.warning),
      IdVerificationResultType.fraudRejected =>
        (PhosphorIconsDuotone.shieldWarning, AppColors.danger),
      IdVerificationResultType.retakePhoto =>
        (PhosphorIconsDuotone.camera, AppColors.primary),
      IdVerificationResultType.error =>
        (PhosphorIconsDuotone.warning, AppColors.danger),
    };

    return Container(
      width: 88,
      height: 88,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: color.withValues(alpha: 0.12),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.20),
            blurRadius: 24,
            spreadRadius: 2,
          ),
        ],
      ),
      child: Center(
        child: PhosphorIcon(icon, size: 44, color: color),
      ),
    );
  }

  String get _title => switch (resultType) {
        IdVerificationResultType.success => 'Identity Verified',
        IdVerificationResultType.ageRejected => 'Age Requirement Not Met',
        IdVerificationResultType.fraudRejected => 'Verification Failed',
        IdVerificationResultType.retakePhoto => 'Better Photo Needed',
        IdVerificationResultType.error => 'Verification Failed',
      };

  String get _defaultMessage => switch (resultType) {
        IdVerificationResultType.success =>
          'Your liveness check passed. Continue to create your account.',
        IdVerificationResultType.ageRejected =>
          'You must be $minimumAge or older to join Tander. If your ID was '
              'scanned incorrectly, please try again with better lighting.',
        IdVerificationResultType.fraudRejected =>
          'We could not verify this document. This may be due to image '
              'quality or document issues. Please try again with your '
              'original ID.',
        IdVerificationResultType.retakePhoto =>
          'The photo quality was not sufficient for verification. '
              'Please take a clearer photo.',
        IdVerificationResultType.error =>
          'We couldn\'t verify your identity. Please try again with a clear photo.',
      };

  Widget? _detail() {
    if (resultType == IdVerificationResultType.ageRejected &&
        extractedAge != null) {
      return _detailBox(
        'Your ID indicates you are $extractedAge years old. '
        'Tander requires members to be at least $minimumAge.',
      );
    }

    if (resultType == IdVerificationResultType.fraudRejected) {
      return _detailBox(
        'Use your original physical ID, ensure clear lighting, '
        'and keep all text fully visible.',
      );
    }

    if (resultType == IdVerificationResultType.retakePhoto &&
        retakeGuidance != null &&
        retakeGuidance!.isNotEmpty) {
      return _detailBox(retakeGuidance!);
    }

    return null;
  }

  Widget _detailBox(String text) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFF0F1F5),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        text,
        textAlign: TextAlign.center,
        style: const TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w500,
          color: Color(0xFF4A5568),
          height: 1.4,
        ),
      ),
    );
  }

  List<AuthStatusAction> _actions(BuildContext context) {
    if (resultType == IdVerificationResultType.success) {
      return [
        AuthStatusAction(
          label: 'Continue',
          style: AuthStatusActionStyle.primary,
          backgroundColor: AppColors.primary,
          onPressed: () => Navigator.of(context).pop(
            IdVerificationResultAction.continueRegistration,
          ),
        ),
      ];
    }

    return [
      AuthStatusAction(
        label: 'Try Again',
        style: AuthStatusActionStyle.primary,
        backgroundColor: AppColors.primary,
        onPressed: () =>
            Navigator.of(context).pop(IdVerificationResultAction.retryScan),
      ),
      AuthStatusAction(
        label: 'Exit',
        style: AuthStatusActionStyle.text,
        onPressed: () =>
            Navigator.of(context).pop(IdVerificationResultAction.exitFlow),
      ),
    ];
  }
}
