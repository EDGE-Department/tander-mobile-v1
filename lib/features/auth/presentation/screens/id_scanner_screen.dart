import 'dart:async';
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import '../../../../core/providers/core_providers.dart';
import '../../../../core/theme/app_colors.dart';
import '../providers/auth_providers.dart';
import '../../../../core/utils/device_utils.dart';
import '../../../../shared/constants/routes.dart';
import '../../data/id_ocr_service.dart';
import '../../data/models/liveness_metadata.dart';
import '../../data/registration_constants.dart';
import '../notifiers/auth_notifier.dart';
import 'id_verification_result_screen.dart';
import '../widgets/scanner/document_scan_view.dart';
import '../widgets/scanner/id_preview_view.dart';
import '../widgets/scanner/liveness_tutorial_content.dart';
import '../widgets/scanner/liveness_view.dart';

/// Scan phase for the ID scanner flow.
enum _ScanPhase {
  tutorial,
  liveness,
  selfieToIdTransition,
  documentScan,
  preview,
  complete
}

/// Pre-registration ID scanner screen.
///
/// Phase 1: Liveness check (front camera, face detection, 2s hold).
/// Phase 2: ID document scan (back camera, OCR extracts DOB, age check).
/// Phase 3: Preview captured ID + verification badges.
/// On continue: backend verification -> full-screen result -> next action.
class IdScannerScreen extends ConsumerStatefulWidget {
  final int? minimumAge;

  const IdScannerScreen({super.key, this.minimumAge});

  @override
  ConsumerState<IdScannerScreen> createState() => _IdScannerScreenState();
}

class _IdScannerScreenState extends ConsumerState<IdScannerScreen> {
  _ScanPhase _phase = _ScanPhase.tutorial;
  String? _feedbackMessage;
  Timer? _feedbackTimer;
  Timer? _transitionTimer;
  bool _isNavigating = false;
  bool _isVerifying = false;
  bool _verifyComplete = false;
  int? _resolvedMinimumAge;

  String? _capturedIdPath;
  OcrResult? _ocrResult;
  String? _selfiePath;
  LivenessMetadata? _livenessMetadata;

  bool _isPhone = true;

  int get _minimumAge =>
      _resolvedMinimumAge ??
      widget.minimumAge ??
      RegistrationConstants.minimumAge;

  @override
  void initState() {
    super.initState();
    // Force portrait on ALL devices (phones + tablets) during ID scanner
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
    ]);
    _phase = _ScanPhase.tutorial;
    _resolveMinimumAgeIfNeeded();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _isPhone = MediaQuery.sizeOf(context).shortestSide < 600;
    // Re-enforce portrait lock after dependencies resolve (catches tablets)
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
    ]);
  }

  /// Best-effort deletion of selfie + ID photos from device temp storage.
  Future<void> _cleanupPhotos() async {
    for (final path in [_selfiePath, _capturedIdPath]) {
      if (path != null && path.isNotEmpty) {
        try {
          final file = File(path);
          if (await file.exists()) await file.delete();
        } catch (_) {
          // Best-effort — don't block the flow on cleanup failure
        }
      }
    }
    _selfiePath = null;
    _capturedIdPath = null;
  }

  @override
  void dispose() {
    _feedbackTimer?.cancel();
    _transitionTimer?.cancel();
    _cleanupPhotos(); // Safety net: delete any lingering photos on exit
    // Restore: phones=portrait only, tablets=all orientations
    if (_isPhone) {
      SystemChrome.setPreferredOrientations([
        DeviceOrientation.portraitUp,
        DeviceOrientation.portraitDown,
      ]);
    } else {
      SystemChrome.setPreferredOrientations([
        DeviceOrientation.portraitUp,
        DeviceOrientation.portraitDown,
        DeviceOrientation.landscapeLeft,
        DeviceOrientation.landscapeRight,
      ]);
    }
    super.dispose();
  }

  void _showFeedback(String message) {
    _feedbackTimer?.cancel();
    setState(() => _feedbackMessage = message);
    _feedbackTimer = Timer(const Duration(seconds: 4), () {
      if (mounted) setState(() => _feedbackMessage = null);
    });
  }

  Future<void> _resolveMinimumAgeIfNeeded() async {
    if (widget.minimumAge != null) return;
    try {
      final age =
          await ref.read(authNotifierProvider.notifier).getMinimumAge();
      if (!mounted) return;
      setState(() => _resolvedMinimumAge = age);
    } catch (_) {
      // Keep fallback from RegistrationConstants.
    }
  }

  void _onLivenessVerified(String photoPath, LivenessMetadata metadata) {
    if (!mounted) return;
    _selfiePath = photoPath;
    _livenessMetadata = metadata;
    _transitionTimer?.cancel();
    setState(() {
      _phase = _ScanPhase.selfieToIdTransition;
      _feedbackMessage = null;
    });
    _transitionTimer = Timer(const Duration(milliseconds: 1200), () {
      if (!mounted) return;
      setState(() => _phase = _ScanPhase.documentScan);
    });
  }

  void _onLivenessError(String message) {
    if (!mounted) return;
    final normalized = message.trim().toUpperCase();
    if (normalized == 'AUTO_CAPTURE_TIMEOUT') {
      _showFeedback(
        'Let\'s try again. Keep your face centered and hold still.',
      );
      return;
    }
    _showFeedback(message);
  }

  void _onDocumentScanned(String photoPath, OcrResult ocrResult) {
    if (!mounted) return;
    _capturedIdPath = photoPath;
    _ocrResult = ocrResult;
    setState(() => _phase = _ScanPhase.preview);
  }

  Future<void> _verifyWithBackend() async {
    if (_isVerifying || _capturedIdPath == null || _ocrResult == null) return;
    if (_selfiePath == null || _selfiePath!.isEmpty) {
      _showFeedback('Please complete selfie verification first.');
      setState(() => _phase = _ScanPhase.liveness);
      return;
    }
    if (_livenessMetadata == null) {
      _showFeedback('Please complete face verification first.');
      setState(() => _phase = _ScanPhase.liveness);
      return;
    }
    setState(() {
      _isVerifying = true;
      _phase = _ScanPhase.complete;
    });

    try {
      final repository = ref.read(authRepositoryProvider);
      final verifyResult = await repository.verifyIdPreRegister(
        idPhotoFrontPath: _capturedIdPath!,
        selfiePath: _selfiePath,
        livenessMetadata: _livenessMetadata?.toJson(),
        frontendOcrData: _ocrResult!.toFrontendOcrData(),
      );

      if (!mounted) return;

      verifyResult.when(
        success: (auditId) async {
          if (auditId.isEmpty) {
            setState(() {
              _isVerifying = false;
              _phase = _ScanPhase.complete;
            });
            await _showResultScreen(
              IdVerificationResultType.error,
              message: 'ID verification returned empty result. Please try again.',
            );
            return;
          }

          await ref.read(secureStorageProvider).saveAuditId(auditId);
          await _cleanupPhotos();

          HapticFeedback.heavyImpact();
          setState(() {
            _isVerifying = false;
            _verifyComplete = true;
          });
        },
        failure: (exception) async {
          if (!mounted) return;
          final errorMsg = exception.userMessage;
          final errorCode = exception.code;

          // Check for specific backend error codes
          final isLivenessIssue = errorCode == 'LIVENESS_REQUIRED' ||
              errorCode == 'LIVENESS_CHECK_FAILED' ||
              errorCode == 'LIVENESS_WEAK_EVIDENCE' ||
              errorCode == 'INVALID_LIVENESS_METADATA' ||
              errorCode == 'FACE_MISMATCH';

          if (isLivenessIssue) {
            _cleanupPhotos();
            setState(() {
              _isVerifying = false;
              _verifyComplete = false;
              _phase = _ScanPhase.liveness;
              _ocrResult = null;
              _livenessMetadata = null;
            });
            _showFeedback(errorMsg);
            return;
          }

          if (errorCode == 'DUPLICATE_ID_DETECTED' ||
              errorCode == 'ID_IN_COOLDOWN' ||
              errorCode == 'ID_BLOCKED') {
            setState(() => _isVerifying = false);
            if (mounted) {
              _showDuplicateIdDialog(
                errorMsg,
                'This ID is already linked to an active account.',
              );
            }
            return;
          }

          if (errorCode == 'ACCOUNT_INCOMPLETE') {
            setState(() => _isVerifying = false);
            if (mounted) {
              _showDuplicateIdDialog(
                'You already have an account. Please sign in to complete your profile.',
                'Account found',
              );
            }
            return;
          }

          if (errorCode == 'AGE_REQUIREMENT_NOT_MET') {
            setState(() {
              _isVerifying = false;
              _phase = _ScanPhase.complete;
            });
            await _showResultScreen(
              IdVerificationResultType.ageRejected,
              message: errorMsg,
            );
            return;
          }

          if (errorCode == 'FRAUD_DETECTED') {
            setState(() {
              _isVerifying = false;
              _phase = _ScanPhase.complete;
            });
            await _showResultScreen(IdVerificationResultType.fraudRejected);
            return;
          }

          // Rate limit
          if (errorCode == 'RATE_LIMITED') {
            setState(() => _isVerifying = false);
            _showFeedback(errorMsg);
            return;
          }

          // Generic error — show actual backend message
          setState(() {
            _isVerifying = false;
            _phase = _ScanPhase.complete;
          });
          await _showResultScreen(
            IdVerificationResultType.error,
            message: errorMsg,
          );
        },
      );
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isVerifying = false;
        _phase = _ScanPhase.complete;
      });
      await _showResultScreen(
        IdVerificationResultType.error,
        message: 'Something went wrong. Please try again.',
      );
    }
  }

  Future<void> _handleDioError(DioException e) async {
    final responseData = e.response?.data;
    String? errorCode;
    String friendlyMsg = 'Something went wrong. Please try again.';

    if (responseData is Map<String, dynamic>) {
      errorCode = responseData['code'] as String?;
      final message = responseData['message'] as String?;
      if (message != null && message.isNotEmpty) {
        friendlyMsg = message;
      }
    }

    final statusCode = e.response?.statusCode;

    final isLivenessIssue = errorCode == 'LIVENESS_REQUIRED' ||
        errorCode == 'LIVENESS_CHECK_FAILED' ||
        errorCode == 'LIVENESS_WEAK_EVIDENCE' ||
        errorCode == 'INVALID_LIVENESS_METADATA' ||
        errorCode == 'INVALID_SELFIE_FILE_TYPE' ||
        errorCode == 'SELFIE_FILE_TOO_LARGE' ||
        errorCode == 'FACE_MISMATCH' ||
        errorCode == 'AUTO_CAPTURE_TIMEOUT';

    if (isLivenessIssue) {
      _cleanupPhotos(); // Delete photos before retry
      setState(() {
        _isVerifying = false;
        _verifyComplete = false;
        _phase = _ScanPhase.liveness;
        _ocrResult = null;
        _livenessMetadata = null;
      });
      _showFeedback(
        friendlyMsg.isNotEmpty
            ? friendlyMsg
            : 'Please verify your face again before scanning your ID.',
      );
      return;
    }

    if (errorCode == 'DUPLICATE_ID_DETECTED' ||
        errorCode == 'ID_IN_COOLDOWN' ||
        errorCode == 'ID_BLOCKED') {
      setState(() => _isVerifying = false);
      if (mounted) {
        _showDuplicateIdDialog(
          friendlyMsg,
          'This ID is already linked to an active account.',
        );
      }
      return;
    }

    if (errorCode == 'ACCOUNT_INCOMPLETE') {
      setState(() => _isVerifying = false);
      if (mounted) {
        _showDuplicateIdDialog(
          'You already have an account. Please sign in to complete your profile.',
          'Account found',
        );
      }
      return;
    }

    if (statusCode == 429) {
      setState(() => _isVerifying = false);
      if (mounted) context.go(AppRoutes.login);
      return;
    }

    setState(() {
      _isVerifying = false;
      _phase = _ScanPhase.complete;
    });

    if (errorCode == 'AGE_REQUIREMENT_NOT_MET') {
      await _showResultScreen(
        IdVerificationResultType.ageRejected,
        message: friendlyMsg,
      );
    } else if (errorCode == 'FRAUD_DETECTED') {
      await _showResultScreen(IdVerificationResultType.fraudRejected);
    } else {
      await _showResultScreen(
        IdVerificationResultType.error,
        message: friendlyMsg,
      );
    }
  }

  void _onScanError(String error) {
    if (!mounted) return;
    final isAgeRejection = error.contains('Age requirement');
    final isTimeout = error == 'AUTO_CAPTURE_TIMEOUT' ||
        error.toLowerCase().contains('timed out');
    unawaited(_showResultScreen(
      isAgeRejection
          ? IdVerificationResultType.ageRejected
          : (isTimeout
              ? IdVerificationResultType.retakePhoto
              : IdVerificationResultType.error),
      message: isTimeout
          ? 'We couldn\'t read your ID. Try with better lighting and a flat surface.'
          : error,
    ));
  }

  void _showDuplicateIdDialog(String message, String title) {
    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: const Color(0xFFFFF3E0),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.info_outline, color: Color(0xFFE65100), size: 22),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                title,
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
              ),
            ),
          ],
        ),
        content: Text(
          message,
          style: const TextStyle(fontSize: 15, color: Color(0xFF64748B), height: 1.4),
        ),
        actions: [
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () {
                Navigator.of(dialogContext).pop();
                context.go(AppRoutes.login);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFE86035),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: const Text('Go to Login', style: TextStyle(fontWeight: FontWeight.w600)),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _showResultScreen(
    IdVerificationResultType type, {
    String? message,
    String? retakeGuidance,
  }) async {
    final action =
        await Navigator.of(context).push<IdVerificationResultAction>(
      MaterialPageRoute(
        builder: (_) => IdVerificationResultScreen(
          resultType: type,
          minimumAge: _minimumAge,
          message: message,
          retakeGuidance: retakeGuidance,
        ),
      ),
    );

    if (!mounted || action == null) return;

    switch (action) {
      case IdVerificationResultAction.continueRegistration:
        _navigateToSignUp();
      case IdVerificationResultAction.retryScan:
        _retryDocumentScan();
      case IdVerificationResultAction.exitFlow:
        _goBack();
    }
  }

  void _navigateToSignUp() {
    if (_isNavigating) return;
    _isNavigating = true;
    HapticFeedback.mediumImpact();
    context.go(AppRoutes.signUp);
  }

  void _retryDocumentScan() {
    _transitionTimer?.cancel();
    setState(() {
      _phase = _ScanPhase.documentScan;
      _feedbackMessage = null;
      _capturedIdPath = null;
      _ocrResult = null;
      _verifyComplete = false;
    });
  }

  void _handleBackPressed() {
    HapticFeedback.lightImpact();

    if (_phase == _ScanPhase.selfieToIdTransition ||
        _phase == _ScanPhase.documentScan) {
      _transitionTimer?.cancel();
      setState(() {
        _phase = _ScanPhase.tutorial;
        _selfiePath = null;
        _livenessMetadata = null;
        _capturedIdPath = null;
        _ocrResult = null;
        _feedbackMessage = null;
      });
      return;
    }

    if (_phase == _ScanPhase.preview) {
      _retryDocumentScan();
      return;
    }

    if (_phase == _ScanPhase.liveness) {
      setState(() => _phase = _ScanPhase.tutorial);
      return;
    }

    _goBack();
  }

  void _goBack() {
    if (_isNavigating) return;
    _isNavigating = true;
    context.go(AppRoutes.login);
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _handleBackPressed();
      },
      child: Scaffold(
        backgroundColor: const Color(0xFF4B4C4F),
        body: Stack(
          fit: StackFit.expand,
          children: [
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 350),
              transitionBuilder: (child, animation) => FadeTransition(
                opacity: animation,
                child: child,
              ),
              child: KeyedSubtree(
                key: ValueKey(_phase),
                child: _cameraView(),
              ),
            ),
            if (_phase != _ScanPhase.preview &&
                _phase != _ScanPhase.complete &&
                _phase != _ScanPhase.tutorial)
              _header(),
            if (_feedbackMessage != null) _feedbackBadge(),
          ],
        ),
      ),
    );
  }

  Widget _cameraView() {
    return switch (_phase) {
      _ScanPhase.tutorial => LivenessTutorialContent(
          onStart: () {
            if (!mounted) return;
            setState(() => _phase = _ScanPhase.liveness);
          },
          onBack: _goBack,
        ),
      _ScanPhase.liveness => LivenessView(
          onVerified: _onLivenessVerified,
          onError: _onLivenessError,
        ),
      _ScanPhase.selfieToIdTransition => const _SelfieTransitionView(),
      _ScanPhase.documentScan => DocumentScanView(
          minimumAge: _minimumAge,
          onScanned: _onDocumentScanned,
          onError: _onScanError,
        ),
      _ScanPhase.preview => IdPreviewView(
          idPhotoPath: _capturedIdPath!,
          isVerifying: _isVerifying,
          onRetake: _retryDocumentScan,
          onContinue: _verifyWithBackend,
        ),
      _ScanPhase.complete => _completePlaceholder(),
    };
  }

  Widget _header() {
    final title = _phaseTitle();
    final subtitle = _phaseSubtitle();
    final hideBack =
        _phase == _ScanPhase.tutorial || _phase == _ScanPhase.complete;

    return Positioned(
      top: 0,
      left: 0,
      right: 0,
      child: Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(bottom: Radius.circular(32)),
          boxShadow: [
            BoxShadow(
              color: Color(0x0D000000),
              blurRadius: 20,
              offset: Offset(0, 4),
            ),
          ],
        ),
        child: SafeArea(
          bottom: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(24, 12, 24, 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (!hideBack) ...[
                      GestureDetector(
                        onTap: _handleBackPressed,
                        child: Container(
                          width: 40,
                          height: 40,
                          decoration: const BoxDecoration(
                            color: Color(0xFFF4F5F7),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            PhosphorIconsBold.arrowLeft,
                            color: Color(0xFF141A28),
                            size: 20,
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                    ],
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.only(top: 4),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              title,
                              style: const TextStyle(
                                color: Color(0xFF141A28),
                                fontSize: 22,
                                fontWeight: FontWeight.w700,
                                height: 1.2,
                              ),
                            ),
                            if (subtitle != null) ...[
                              const SizedBox(height: 6),
                              Text(
                                subtitle,
                                style: const TextStyle(
                                  color: Color(0xFF747E93),
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
                                  height: 1.4,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                _phaseIndicator(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _phaseTitle() => switch (_phase) {
        _ScanPhase.tutorial => 'Identity Verification',
        _ScanPhase.liveness => 'Face Verification',
        _ScanPhase.selfieToIdTransition => 'Face Verified',
        _ScanPhase.documentScan => 'Scan Your ID',
        _ScanPhase.preview => 'Review ID Photo',
        _ScanPhase.complete => 'Verifying Your Identity',
      };

  String? _phaseSubtitle() => switch (_phase) {
        _ScanPhase.tutorial =>
          'We will guide you through a quick selfie and ID check.',
        _ScanPhase.liveness =>
          'Just look at the camera. We\'ll do the rest automatically.',
        _ScanPhase.selfieToIdTransition =>
          'Great. Preparing the document scanner now.',
        _ScanPhase.documentScan =>
          'Place your ID inside the frame. We\'ll scan it automatically.',
        _ScanPhase.preview =>
          'Confirm details are clear before we submit for validation.',
        _ScanPhase.complete =>
          'Please wait while we complete final checks.',
      };

  Widget _phaseIndicator() {
    final livenessActive =
        _phase == _ScanPhase.liveness || _phase == _ScanPhase.tutorial;
    final livenessComplete = _phase.index > _ScanPhase.liveness.index;
    final docActive =
        _phase == _ScanPhase.documentScan || _phase == _ScanPhase.preview;
    final docComplete = _phase.index > _ScanPhase.preview.index;

    final progress = switch (_phase) {
      _ScanPhase.tutorial => 0.10,
      _ScanPhase.liveness => 0.35,
      _ScanPhase.selfieToIdTransition => 0.50,
      _ScanPhase.documentScan => 0.75,
      _ScanPhase.preview => 0.90,
      _ScanPhase.complete => 1.0,
    };

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TweenAnimationBuilder<double>(
          tween: Tween(begin: 0.0, end: progress),
          duration: const Duration(milliseconds: 600),
          curve: Curves.easeInOut,
          builder: (context, value, _) => ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: LinearProgressIndicator(
              minHeight: 6,
              value: value,
              backgroundColor: const Color(0xFFF4F5F7),
              valueColor:
                  const AlwaysStoppedAnimation<Color>(Color(0xFFFF8266)),
            ),
          ),
        ),
        const SizedBox(height: 24),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _stepDot('Selfie', PhosphorIconsDuotone.user,
                isActive: livenessActive, isDone: livenessComplete),
            AnimatedContainer(
              duration: const Duration(milliseconds: 400),
              curve: Curves.easeInOut,
              width: 32,
              height: 2,
              decoration: BoxDecoration(
                color: livenessComplete
                    ? const Color(0xFF5BBFB3)
                    : const Color(0xFFE2E6EE),
                borderRadius: BorderRadius.circular(999),
              ),
            ),
            _stepDot('ID Card', PhosphorIconsDuotone.creditCard,
                isActive: docActive, isDone: docComplete),
          ],
        ),
      ],
    );
  }

  Widget _stepDot(String label, IconData icon,
      {required bool isActive, required bool isDone}) {
    final Color bgColor;
    final Color textColor;
    final Border? border;
    final List<BoxShadow> shadows;

    if (isDone) {
      bgColor = const Color(0xFF5BBFB3);
      textColor = const Color(0xFF5BBFB3);
      border = null;
      shadows = const [];
    } else if (isActive) {
      bgColor = const Color(0xFFFF8266);
      textColor = const Color(0xFFFF8266);
      border = null;
      shadows = const [
        BoxShadow(
            color: Color(0x4DFF8266), blurRadius: 12, offset: Offset(0, 4)),
      ];
    } else {
      bgColor = Colors.white;
      textColor = const Color(0xFFA0A7B5);
      border = Border.all(color: const Color(0xFFE2E6EE), width: 2);
      shadows = const [];
    }

    final iconColor =
        (isDone || isActive) ? Colors.white : const Color(0xFFA0A7B5);

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        AnimatedScale(
          scale: isActive ? 1.08 : 1.0,
          duration: const Duration(milliseconds: 300),
          curve: Curves.elasticOut,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeInOut,
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: bgColor,
              border: border,
              boxShadow: shadows,
            ),
            child: isDone
                ? const Icon(PhosphorIconsBold.check,
                    color: Colors.white, size: 20)
                : Icon(icon, color: iconColor, size: 20),
          ),
        ),
        const SizedBox(height: 8),
        AnimatedDefaultTextStyle(
          duration: const Duration(milliseconds: 300),
          style: TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w800,
            letterSpacing: 1.0,
            color: textColor,
          ),
          child: Text(label.toUpperCase()),
        ),
      ],
    );
  }

  Widget _feedbackBadge() {
    final message = _feedbackMessage ?? '';
    final lower = message.toLowerCase();
    final isSuccess = lower.contains('verified') || lower.contains('success');
    final isError = lower.contains('failed') ||
        lower.contains('error') ||
        lower.contains('timed out') ||
        lower.contains('unable') ||
        lower.contains('required');
    final bgColor = isSuccess
        ? AppColors.success
        : (isError ? AppColors.danger : AppColors.primary);
    final icon = isSuccess
        ? PhosphorIconsDuotone.checkCircle
        : (isError
            ? PhosphorIconsDuotone.warningCircle
            : PhosphorIconsDuotone.info);

    return Positioned(
      bottom: 100,
      left: 24,
      right: 24,
      child: Center(
        child: TweenAnimationBuilder<double>(
          tween: Tween(begin: 0.0, end: 1.0),
          duration: const Duration(milliseconds: 350),
          curve: Curves.easeOutBack,
          builder: (context, value, child) => Transform.translate(
            offset: Offset(0, (1 - value) * 20),
            child: Opacity(opacity: value.clamp(0.0, 1.0), child: child),
          ),
          child: Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            decoration: BoxDecoration(
              color: bgColor.withValues(alpha: 0.92),
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: bgColor.withValues(alpha: 0.3),
                  blurRadius: 16,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                PhosphorIcon(icon, color: Colors.white, size: 20),
                const SizedBox(width: 8),
                Flexible(
                  child: Text(
                    message,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _completePlaceholder() {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 400),
      transitionBuilder: (child, animation) =>
          FadeTransition(opacity: animation, child: child),
      child: _verifyComplete
          ? _VerifiedView(
              key: const ValueKey('verified'),
              onContinue: () async {
                HapticFeedback.mediumImpact();
                await _showResultScreen(IdVerificationResultType.success);
              },
            )
          : const _AnalyzingView(key: ValueKey('analyzing')),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Analyzing Data screen
// ─────────────────────────────────────────────────────────────────────────────

class _AnalyzingView extends StatefulWidget {
  const _AnalyzingView({super.key});
  @override
  State<_AnalyzingView> createState() => _AnalyzingViewState();
}

class _AnalyzingViewState extends State<_AnalyzingView>
    with TickerProviderStateMixin {
  late final AnimationController _enterCtrl;
  late final AnimationController _pulseCtrl;
  late final Animation<double> _enterFade;
  late final Animation<Offset> _enterSlide;
  late final Animation<double> _pulse;

  @override
  void initState() {
    super.initState();
    _enterCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 600))
      ..forward();
    _pulseCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 1400))
      ..repeat(reverse: true);
    _enterFade = CurvedAnimation(parent: _enterCtrl, curve: Curves.easeOut);
    _enterSlide =
        Tween<Offset>(begin: const Offset(0, 0.3), end: Offset.zero).animate(
            CurvedAnimation(parent: _enterCtrl, curve: Curves.easeOutCubic));
    _pulse = Tween<double>(begin: 0.10, end: 0.30).animate(
        CurvedAnimation(parent: _pulseCtrl, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _enterCtrl.dispose();
    _pulseCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: const Color(0xFFF8F9FA),
      child: Center(
        child: FadeTransition(
          opacity: _enterFade,
          child: SlideTransition(
            position: _enterSlide,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                AnimatedBuilder(
                  animation: _pulse,
                  builder: (context, _) => Container(
                    width: 88,
                    height: 88,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: const Color(0xFF5BBFB3)
                          .withValues(alpha: _pulse.value * 0.15),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF5BBFB3)
                              .withValues(alpha: _pulse.value),
                          blurRadius: 30,
                          spreadRadius: 4,
                        ),
                      ],
                    ),
                    child: const Padding(
                      padding: EdgeInsets.all(22),
                      child: CircularProgressIndicator(
                          color: Color(0xFF5BBFB3), strokeWidth: 4),
                    ),
                  ),
                ),
                const SizedBox(height: 32),
                const Text('Analyzing Data',
                    style: TextStyle(
                        color: Color(0xFF141A28),
                        fontSize: 26,
                        fontWeight: FontWeight.w800)),
                const SizedBox(height: 10),
                const Text('Checking secure details...',
                    style: TextStyle(
                        color: Color(0xFF747E93), fontSize: 15, height: 1.5)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Verified! success card
// ─────────────────────────────────────────────────────────────────────────────

class _VerifiedView extends StatefulWidget {
  final VoidCallback onContinue;
  const _VerifiedView({super.key, required this.onContinue});
  @override
  State<_VerifiedView> createState() => _VerifiedViewState();
}

class _VerifiedViewState extends State<_VerifiedView>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _iconScale;
  late final Animation<double> _fade;
  late final Animation<Offset> _textSlide;
  late final Animation<Offset> _btnSlide;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 900))
      ..forward();
    _iconScale = CurvedAnimation(
        parent: _ctrl,
        curve: const Interval(0.0, 0.55, curve: Curves.elasticOut));
    _fade = CurvedAnimation(
        parent: _ctrl,
        curve: const Interval(0.0, 0.45, curve: Curves.easeOut));
    _textSlide =
        Tween<Offset>(begin: const Offset(0, 0.4), end: Offset.zero).animate(
            CurvedAnimation(
                parent: _ctrl,
                curve: const Interval(0.3, 0.7, curve: Curves.easeOutCubic)));
    _btnSlide =
        Tween<Offset>(begin: const Offset(0, 0.6), end: Offset.zero).animate(
            CurvedAnimation(
                parent: _ctrl,
                curve: const Interval(0.5, 0.9, curve: Curves.easeOutCubic)));
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bottomPadding = MediaQuery.paddingOf(context).bottom;
    return ColoredBox(
      color: const Color(0xFFF8F9FA),
      child: Stack(
        fit: StackFit.expand,
        children: [
          Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  ScaleTransition(
                    scale: _iconScale,
                    child: FadeTransition(
                      opacity: _fade,
                      child: Container(
                        width: 104,
                        height: 104,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.white,
                          border: Border.all(
                              color: const Color(0xFF5BBFB3), width: 3),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFF5BBFB3)
                                  .withValues(alpha: 0.22),
                              blurRadius: 36,
                              offset: const Offset(0, 10),
                            ),
                          ],
                        ),
                        child: const Icon(PhosphorIconsBold.checkCircle,
                            color: Color(0xFF5BBFB3), size: 58),
                      ),
                    ),
                  ),
                  const SizedBox(height: 32),
                  SlideTransition(
                    position: _textSlide,
                    child: FadeTransition(
                      opacity: _fade,
                      child: const Column(
                        children: [
                          Text('Verified!',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                  color: Color(0xFF141A28),
                                  fontSize: 32,
                                  fontWeight: FontWeight.w800,
                                  height: 1.1)),
                          SizedBox(height: 12),
                          Text('Identity validated successfully.',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                  color: Color(0xFF747E93),
                                  fontSize: 16,
                                  height: 1.5)),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          Positioned(
            bottom: bottomPadding + 32,
            left: 24,
            right: 24,
            child: SlideTransition(
              position: _btnSlide,
              child: FadeTransition(
                opacity: _fade,
                child: SizedBox(
                  height: 56,
                  child: ElevatedButton(
                    onPressed: widget.onContinue,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFFF8266),
                      foregroundColor: Colors.white,
                      elevation: 6,
                      shadowColor: const Color(0x4DFF8266),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(30)),
                    ),
                    child: const Text('Continue',
                        style: TextStyle(
                            fontSize: 18, fontWeight: FontWeight.w700)),
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

// ─────────────────────────────────────────────────────────────────────────────
// Selfie -> ID transition
// ─────────────────────────────────────────────────────────────────────────────

class _SelfieTransitionView extends StatefulWidget {
  const _SelfieTransitionView();
  @override
  State<_SelfieTransitionView> createState() => _SelfieTransitionViewState();
}

class _SelfieTransitionViewState extends State<_SelfieTransitionView>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _scale;
  late final Animation<double> _fade;
  late final Animation<Offset> _slideText;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 700))
      ..forward();
    _scale = CurvedAnimation(
        parent: _ctrl,
        curve: const Interval(0.0, 0.6, curve: Curves.elasticOut));
    _fade = CurvedAnimation(
        parent: _ctrl,
        curve: const Interval(0.0, 0.5, curve: Curves.easeOut));
    _slideText = Tween<Offset>(
            begin: const Offset(0, 0.4), end: Offset.zero)
        .animate(CurvedAnimation(
            parent: _ctrl,
            curve: const Interval(0.3, 0.8, curve: Curves.easeOutCubic)));
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xFFF8F9FA),
      child: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ScaleTransition(
                scale: _scale,
                child: FadeTransition(
                  opacity: _fade,
                  child: Container(
                    width: 96,
                    height: 96,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.white,
                      boxShadow: [
                        BoxShadow(
                          color:
                              const Color(0xFF5BBFB3).withValues(alpha: 0.25),
                          blurRadius: 30,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: const Icon(PhosphorIconsBold.checkCircle,
                        color: Color(0xFF5BBFB3), size: 52),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              SlideTransition(
                position: _slideText,
                child: FadeTransition(
                  opacity: _fade,
                  child: const Column(
                    children: [
                      Text('Perfect!',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                              color: Color(0xFF141A28),
                              fontSize: 28,
                              fontWeight: FontWeight.w700)),
                      SizedBox(height: 8),
                      Text('Preparing the document scanner.',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                              color: Color(0xFF747E93),
                              fontSize: 15,
                              height: 1.5)),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
