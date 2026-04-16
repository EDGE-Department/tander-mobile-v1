import 'dart:async';
import 'dart:io';
import 'dart:math' as math;
import 'dart:ui' show ImageFilter, clampDouble;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../../../core/providers/core_providers.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_curves.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../splash/presentation/widgets/splash_painters.dart';
import '../providers/auth_providers.dart';
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
class IdScannerScreen extends ConsumerStatefulWidget {
  final int? minimumAge;

  const IdScannerScreen({super.key, this.minimumAge});

  @override
  ConsumerState<IdScannerScreen> createState() => _IdScannerScreenState();
}

class _IdScannerScreenState extends ConsumerState<IdScannerScreen> {
  final GlobalKey _headerKey = GlobalKey();
  double _headerHeight = 0;

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
    _phase = _ScanPhase.tutorial;
    _applySystemUiModeForPhase(_phase);
    _resolveMinimumAgeIfNeeded();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _isPhone = MediaQuery.sizeOf(context).shortestSide < 600;
    _updateOrientationForPhase(_phase);
    _scheduleHeaderMeasurement();
  }

  Future<void> _cleanupPhotos() async {
    for (final path in [_selfiePath, _capturedIdPath]) {
      if (path != null && path.isNotEmpty) {
        try {
          final file = File(path);
          if (await file.exists()) await file.delete();
        } catch (_) {}
      }
    }
    _selfiePath = null;
    _capturedIdPath = null;
  }

  @override
  void dispose() {
    _feedbackTimer?.cancel();
    _transitionTimer?.cancel();
    _cleanupPhotos();
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
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

  void _applySystemUiModeForPhase(_ScanPhase phase) {
    final immersive = phase == _ScanPhase.tutorial ||
        phase == _ScanPhase.liveness ||
        phase == _ScanPhase.selfieToIdTransition ||
        phase == _ScanPhase.documentScan;
    
    SystemChrome.setEnabledSystemUIMode(
      immersive ? SystemUiMode.immersiveSticky : SystemUiMode.edgeToEdge,
    );
  }

  void _scheduleHeaderMeasurement() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final box = _headerKey.currentContext?.findRenderObject() as RenderBox?;
      final nextHeight = box?.size.height ?? 0;
      if ((_headerHeight - nextHeight).abs() > 1) {
        setState(() => _headerHeight = nextHeight);
      }
    });
  }

  void _updateOrientationForPhase(_ScanPhase phase) {
    if (phase == _ScanPhase.liveness || phase == _ScanPhase.documentScan) {
      _lockPortrait();
    } else {
      _unlockOrientation();
    }
  }

  void _setPhase(_ScanPhase phase, {VoidCallback? mutate}) {
    if (!mounted) return;
    setState(() {
      mutate?.call();
      _phase = phase;
    });
    _applySystemUiModeForPhase(phase);
    _updateOrientationForPhase(phase);
    _scheduleHeaderMeasurement();
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
    } catch (_) {}
  }

  void _onLivenessVerified(String photoPath, LivenessMetadata metadata) {
    if (!mounted) return;
    _selfiePath = photoPath;
    _livenessMetadata = metadata;
    _transitionTimer?.cancel();
    
    _setPhase(
      _ScanPhase.selfieToIdTransition,
      mutate: () => _feedbackMessage = null,
    );
    
    _transitionTimer = Timer(const Duration(milliseconds: 1200), () {
      if (mounted) _setPhase(_ScanPhase.documentScan);
    });
  }

  void _onLivenessError(String message) {
    if (!mounted) return;
    final normalized = message.trim().toUpperCase();
    if (normalized == 'AUTO_CAPTURE_TIMEOUT') {
      // Parent no longer shows feedback for liveness timeout 
      // as LivenessView now owns its own retry UI.
      return;
    }
    _showFeedback(message);
  }

  void _onDocumentScanned(String photoPath, OcrResult ocrResult) {
    if (!mounted) return;
    _capturedIdPath = photoPath;
    _ocrResult = ocrResult;
    _setPhase(_ScanPhase.preview);
  }

  Future<void> _verifyWithBackend() async {
    if (_isVerifying || _capturedIdPath == null || _ocrResult == null) return;
    if (_selfiePath == null || _selfiePath!.isEmpty) {
      _showFeedback('Please complete selfie verification first.');
      _setPhase(_ScanPhase.liveness);
      return;
    }
    if (_livenessMetadata == null) {
      _showFeedback('Please complete face verification first.');
      _setPhase(_ScanPhase.liveness);
      return;
    }
    _setPhase(
      _ScanPhase.complete,
      mutate: () => _isVerifying = true,
    );

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
            _setPhase(
              _ScanPhase.complete,
              mutate: () => _isVerifying = false,
            );
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

          final isLivenessIssue = errorCode == 'LIVENESS_REQUIRED' ||
              errorCode == 'LIVENESS_CHECK_FAILED' ||
              errorCode == 'LIVENESS_WEAK_EVIDENCE' ||
              errorCode == 'INVALID_LIVENESS_METADATA' ||
              errorCode == 'FACE_MISMATCH';

          if (isLivenessIssue) {
            _cleanupPhotos();
            _setPhase(
              _ScanPhase.liveness,
              mutate: () {
                _isVerifying = false;
                _verifyComplete = false;
                _ocrResult = null;
                _livenessMetadata = null;
              },
            );
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
            _setPhase(
              _ScanPhase.complete,
              mutate: () => _isVerifying = false,
            );
            await _showResultScreen(
              IdVerificationResultType.ageRejected,
              message: errorMsg,
            );
            return;
          }

          if (errorCode == 'FRAUD_DETECTED') {
            _setPhase(
              _ScanPhase.complete,
              mutate: () => _isVerifying = false,
            );
            await _showResultScreen(IdVerificationResultType.fraudRejected);
            return;
          }

          if (errorCode == 'RATE_LIMITED') {
            setState(() => _isVerifying = false);
            _showFeedback(errorMsg);
            return;
          }

          _setPhase(
            _ScanPhase.complete,
            mutate: () => _isVerifying = false,
          );
          await _showResultScreen(
            IdVerificationResultType.error,
            message: errorMsg,
          );
        },
      );
    } catch (e) {
      if (!mounted) return;
      _setPhase(
        _ScanPhase.complete,
        mutate: () => _isVerifying = false,
      );
      await _showResultScreen(
        IdVerificationResultType.error,
        message: 'Something went wrong. Please try again.',
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
              decoration: const BoxDecoration(
                color: Color(0xFFFFF3E0),
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
    _setPhase(
      _ScanPhase.documentScan,
      mutate: () {
        _feedbackMessage = null;
        _capturedIdPath = null;
        _ocrResult = null;
        _verifyComplete = false;
      },
    );
  }

  void _handleBackPressed() {
    HapticFeedback.lightImpact();

    if (_phase == _ScanPhase.selfieToIdTransition ||
        _phase == _ScanPhase.documentScan) {
      _transitionTimer?.cancel();
      _setPhase(
        _ScanPhase.tutorial,
        mutate: () {
          _selfiePath = null;
          _livenessMetadata = null;
          _capturedIdPath = null;
          _ocrResult = null;
          _feedbackMessage = null;
        },
      );
      return;
    }

    if (_phase == _ScanPhase.preview) {
      _retryDocumentScan();
      return;
    }

    if (_phase == _ScanPhase.liveness) {
      _setPhase(_ScanPhase.tutorial);
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
        backgroundColor: const Color(0xFF1A1B1E),
        extendBody: true,
        extendBodyBehindAppBar: true,
        body: Stack(
          fit: StackFit.expand,
          children: [
            if (_phase != _ScanPhase.tutorial &&
                _phase != _ScanPhase.liveness &&
                _phase != _ScanPhase.documentScan)
              const Positioned.fill(
                child: IgnorePointer(
                  child: DecoratedBox(
                    decoration: BoxDecoration(
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
                  ),
                ),
              ),
            if (_phase != _ScanPhase.tutorial &&
                _phase != _ScanPhase.liveness &&
                _phase != _ScanPhase.documentScan)
              const Positioned.fill(
                child: IgnorePointer(child: _HeaderScene()),
              ),
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
                _phase != _ScanPhase.tutorial &&
                _phase != _ScanPhase.liveness)
              _header(),
            if (_feedbackMessage != null) _feedbackBadge(),
          ],
        ),
      ),
    );
  }


  static const _orientationChannel = MethodChannel('com.tander.app/orientation');

  Future<void> _lockPortrait() async {
    try {
      await _orientationChannel.invokeMethod('lockPortrait');
    } catch (_) {
      // Fallback to Flutter API
      SystemChrome.setPreferredOrientations([
        DeviceOrientation.portraitUp,
        DeviceOrientation.portraitDown,
      ]);
    }
  }

  Future<void> _unlockOrientation() async {
    if (_isPhone) {
      // Phones stay portrait-locked always
      SystemChrome.setPreferredOrientations([
        DeviceOrientation.portraitUp,
        DeviceOrientation.portraitDown,
      ]);
      return;
    }
    try {
      await _orientationChannel.invokeMethod('unlockOrientation');
    } catch (_) {
      SystemChrome.setPreferredOrientations([
        DeviceOrientation.portraitUp,
        DeviceOrientation.portraitDown,
        DeviceOrientation.landscapeLeft,
        DeviceOrientation.landscapeRight,
      ]);
    }
  }

  Widget _cameraView() {
    return switch (_phase) {
      _ScanPhase.tutorial => LivenessTutorialContent(
          onStart: () {
            if (!mounted) return;
            _setPhase(_ScanPhase.liveness);
          },
          onBack: _goBack,
        ),
      _ScanPhase.liveness => LivenessView(
          onVerified: _onLivenessVerified,
          onError: _onLivenessError,
          reservedTopInset: _headerHeight,
        ),
      _ScanPhase.selfieToIdTransition => const _SelfieTransitionView(),
      _ScanPhase.documentScan => DocumentScanView(
          minimumAge: _minimumAge,
          onScanned: _onDocumentScanned,
          onError: _onScanError,
          reservedTopInset: _headerHeight,
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
        key: _headerKey,
        decoration: BoxDecoration(
          color: const Color(0xF2FFFFFF),
          borderRadius: const BorderRadius.vertical(bottom: Radius.circular(32)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.08),
              blurRadius: 30,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: const BorderRadius.vertical(bottom: Radius.circular(32)),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  height: 6,
                  width: double.infinity,
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Color(0xFFE67E22), Color(0xFFF39C12), Color(0xFFE67E22)],
                    ),
                  ),
                ),
                SafeArea(
                  bottom: false,
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 16, 24, 20),
                    child: Column(
                      children: [
                        Row(
                          children: [
                            if (!hideBack) ...[
                              GestureDetector(
                                onTap: _handleBackPressed,
                                child: Container(
                                  width: 44,
                                  height: 44,
                                  decoration: BoxDecoration(
                                    color: Colors.black.withValues(alpha: 0.05),
                                    shape: BoxShape.circle,
                                    border: Border.all(color: Colors.black.withValues(alpha: 0.05)),
                                  ),
                                  child: const Icon(
                                    PhosphorIconsBold.arrowLeft,
                                    color: Color(0xFF141A28),
                                    size: 20,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 16),
                            ] else
                              const SizedBox(width: 8),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    title,
                                    style: AppTypography.displayLg.copyWith(
                                      fontSize: 22,
                                      fontWeight: FontWeight.w900,
                                      color: const Color(0xFF141A28),
                                      letterSpacing: -0.5,
                                    ),
                                  ),
                                  if (subtitle != null) ...[
                                    const SizedBox(height: 4),
                                    Text(
                                      subtitle,
                                      style: AppTypography.bodySm.copyWith(
                                        color: const Color(0xFF747E93),
                                        fontWeight: FontWeight.w600,
                                        height: 1.3,
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 20),
                        _phaseIndicator(),
                      ],
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

    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _stepDot('Selfie', PhosphorIconsDuotone.user,
                isActive: livenessActive, isDone: livenessComplete),
            const SizedBox(width: 12),
            Container(
              width: 40,
              height: 2,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(2),
                gradient: LinearGradient(
                  colors: [
                    livenessComplete ? const Color(0xFF5BBFB3) : const Color(0xFFE2E6EE),
                    docActive || docComplete ? const Color(0xFF5BBFB3) : const Color(0xFFE2E6EE),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 12),
            _stepDot('ID Card', PhosphorIconsDuotone.creditCard,
                isActive: docActive, isDone: docComplete),
          ],
        ),
      ],
    );
  }

  Widget _stepDot(String label, IconData icon,
      {required bool isActive, required bool isDone}) {
    final Color color;
    final Color iconColor;
    final List<BoxShadow> shadows;

    if (isDone) {
      color = const Color(0xFF5BBFB3);
      iconColor = Colors.white;
      shadows = [];
    } else if (isActive) {
      color = const Color(0xFFFF8266);
      iconColor = Colors.white;
      shadows = [
        BoxShadow(
          color: const Color(0xFFFF8266).withValues(alpha: 0.3),
          blurRadius: 12,
          offset: const Offset(0, 4),
        ),
      ];
    } else {
      color = Colors.white;
      iconColor = const Color(0xFFA0A7B5);
      shadows = [];
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        AnimatedContainer(
          duration: const Duration(milliseconds: 400),
          curve: AppCurves.premiumEase,
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: color,
            border: !isActive && !isDone
                ? Border.all(color: const Color(0xFFE2E6EE), width: 2)
                : null,
            boxShadow: shadows,
          ),
          child: Icon(
            isDone ? PhosphorIconsBold.check : icon,
            color: iconColor,
            size: 22,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          label.toUpperCase(),
          style: TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w900,
            letterSpacing: 1.2,
            color: isActive || isDone ? color : const Color(0xFFA0A7B5),
          ),
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
                      fontSize: 18,
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

// ── Background Scene ─────────────────────────────────────────────────────────

class _HeaderScene extends StatefulWidget {
  const _HeaderScene();

  @override
  State<_HeaderScene> createState() => _HeaderSceneState();
}

class _HeaderSceneState extends State<_HeaderScene>
    with TickerProviderStateMixin {
  late final AnimationController _constellationCtrl;
  late final AnimationController _driftCtrl;

  @override
  void initState() {
    super.initState();
    _constellationCtrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 15),
    )..repeat();
    _driftCtrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 20),
    )..repeat();
  }

  @override
  void dispose() {
    _constellationCtrl.dispose();
    _driftCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final h = constraints.maxHeight;
        final w = constraints.maxWidth;

        return AnimatedBuilder(
          animation: _driftCtrl,
          builder: (context, child) {
            final driftX = math.sin(_driftCtrl.value * math.pi * 2) * 15;
            final driftY = math.cos(_driftCtrl.value * math.pi * 2) * 10;

            return Stack(
              fit: StackFit.expand,
              children: [
                Positioned(
                  top: -h * 0.18 + driftY,
                  left: -w * 0.10 + driftX,
                  child: Container(
                    width: w * 0.65,
                    height: h * 0.80,
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: RadialGradient(
                        colors: [
                          Color(0x52FF9656),
                          Color(0x1FDC6937),
                          Colors.transparent,
                        ],
                        stops: [0.0, 0.5, 0.8],
                      ),
                    ),
                  ),
                ),
                Positioned(
                  bottom: -h * 0.05 - driftY,
                  right: -w * 0.10 - driftX,
                  child: Container(
                    width: w * 0.50,
                    height: h * 0.65,
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: RadialGradient(
                        colors: [
                          Color(0x3D60D6BC),
                          Color(0x0F1C927A),
                          Colors.transparent,
                        ],
                        stops: [0.0, 0.45, 0.75],
                      ),
                    ),
                  ),
                ),
                
                ...List.generate(3, (i) {
                  final seed = i * 133;
                  final tx = math.sin((_driftCtrl.value + seed) * math.pi * 2) * 20;
                  final ty = math.cos((_driftCtrl.value + seed * 0.7) * math.pi * 2) * 15;
                  final basePos = [
                    Offset(w * 0.2, h * 0.3),
                    Offset(w * 0.8, h * 0.25),
                    Offset(w * 0.7, h * 0.7),
                  ];
                  return Positioned(
                    left: basePos[i].dx + tx,
                    top: basePos[i].dy + ty,
                    child: Container(
                      width: 40 + (i * 10),
                      height: 40 + (i * 10),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.white.withValues(alpha: 0.03 + (i * 0.01)),
                        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
                      ),
                    ),
                  );
                }),

                const Positioned.fill(
                  child: Opacity(
                    opacity: 0.05,
                    child: CustomPaint(painter: _MobileSceneGrainPainter()),
                  ),
                ),
                Positioned.fill(
                  child: IgnorePointer(
                    child: Opacity(
                      opacity: 0.45,
                      child: AnimatedBuilder(
                        animation: _constellationCtrl,
                        builder: (_, _) => CustomPaint(
                          painter: SplashConstellationPainter(
                              _constellationCtrl.value),
                        ),
                      ),
                    ),
                  ),
                ),
                Positioned.fill(
                  child: IgnorePointer(
                    child: Center(
                      child: LayoutBuilder(
                        builder: (context, constraints) {
                          final fontSize = clampDouble(
                            constraints.maxWidth * 0.34,
                            116,
                            176,
                          );
                          return Transform.translate(
                            offset: Offset(0, fontSize * 0.08),
                            child: Text(
                              '60+',
                              style: TextStyle(
                                fontFamily: AppTypography.displayFontFamily,
                                fontWeight: FontWeight.w900,
                                fontSize: fontSize,
                                color: Colors.white.withValues(alpha: 0.05),
                                height: 1,
                                letterSpacing: -0.05 * fontSize,
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                ),
                Positioned(
                  left: 0,
                  right: 0,
                  bottom: 0,
                  height: h * 0.40,
                  child: const DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.bottomCenter,
                        end: Alignment.topCenter,
                        colors: [
                          Color(0x6B120400),
                          Color(0x1F0A0200),
                          Colors.transparent,
                        ],
                        stops: [0.0, 0.55, 1.0],
                      ),
                    ),
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }
}

class _MobileSceneGrainPainter extends CustomPainter {
  const _MobileSceneGrainPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = Colors.white;
    final random = math.Random(42);
    for (int index = 0; index < 520; index++) {
      canvas.drawCircle(
        Offset(random.nextDouble() * size.width, random.nextDouble() * size.height),
        0.2 + random.nextDouble() * 0.6,
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
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
                        color: Color(0xFF747E93), fontSize: 18, height: 1.5)),
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
                                  fontSize: 18,
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
// Rotate to portrait overlay
// ─────────────────────────────────────────────────────────────────────────────

class _RotateToPortraitOverlay extends StatelessWidget {
  const _RotateToPortraitOverlay({required this.phase});

  final _ScanPhase phase;

  @override
  Widget build(BuildContext context) {
    final label = phase == _ScanPhase.liveness
        ? 'Face Verification'
        : 'ID Scanning';

    return Scaffold(
      backgroundColor: const Color(0xFF1A1A2E),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(48),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                PhosphorIconsDuotone.deviceRotate,
                size: 72,
                color: Colors.white.withValues(alpha: 0.7),
              ),
              const SizedBox(height: 24),
              Text(
                'Please rotate to portrait',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                  color: Colors.white.withValues(alpha: 0.9),
                  letterSpacing: -0.3,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                '$label requires portrait orientation\nfor the best experience.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w500,
                  color: Colors.white.withValues(alpha: 0.55),
                  height: 1.5,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

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
                              fontSize: 18,
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
