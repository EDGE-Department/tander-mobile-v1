import 'dart:async';
import 'dart:io';

import 'package:cunning_document_scanner/cunning_document_scanner.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:tander_flutter_v3/core/errors/app_exception.dart';
import 'package:tander_flutter_v3/core/theme/app_colors.dart';
import 'package:tander_flutter_v3/features/auth/data/id_ocr_service.dart';
import 'package:tander_flutter_v3/features/auth/presentation/notifiers/auth_notifier.dart';
import 'package:tander_flutter_v3/features/auth/presentation/screens/verification_result_screen.dart';
import 'package:tander_flutter_v3/features/auth/presentation/widgets/auth_error_display.dart';
import 'package:tander_flutter_v3/features/auth/presentation/widgets/auth_scene_decorations.dart';
import 'package:tander_flutter_v3/shared/constants/routes.dart';
import 'package:tander_flutter_v3/shared/utils/launch_support_email.dart';
import 'package:tander_flutter_v3/shared/widgets/tander_toast.dart';

class IdScannerScreen extends ConsumerStatefulWidget {
  const IdScannerScreen({super.key});

  @override
  ConsumerState<IdScannerScreen> createState() => _IdScannerScreenState();
}

class _IdScannerScreenState extends ConsumerState<IdScannerScreen> {
  bool _isScanning = false;
  bool _isSubmitting = false;
  String? _error;
  NetworkException? _offlineError;
  String? _scannedIdPath;
  // When true, the current error is something a fresh scan or resubmit will
  // never fix (e.g. duplicate ID, age-not-met, expired ID). We hide the
  // "Retry" button in that case and only offer Cancel + Go to Login.
  bool _errorIsTerminal = false;

  // Safety-net timers for the submitting state. The submit dialog used to
  // own these; now they live inline with the parchment view.
  Timer? _submitTimeoutTimer;
  Timer? _cancelAffordanceTimer;
  bool _showCancelAffordance = false;
  int _consecutiveNonNetworkFailures = 0;

  @override
  void dispose() {
    _submitTimeoutTimer?.cancel();
    _cancelAffordanceTimer?.cancel();
    super.dispose();
  }

  void _resetSubmitTimers() {
    _submitTimeoutTimer?.cancel();
    _cancelAffordanceTimer?.cancel();
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _startScan();
    });
  }

  Future<void> _startScan() async {
    if (_isScanning) return;

    // Pre-check camera permission. If denied or restricted, show the
    // system dialog (for first-time deny) or custom Open-Settings dialog
    // (for permanent deny / restricted). Skip the document scanner call
    // when permission isn't granted, so the user gets actionable guidance
    // instead of a generic "Scan failed" error.
    final initialStatus = await Permission.camera.status;
    if (!initialStatus.isGranted) {
      final requestResult = await Permission.camera.request();
      if (!requestResult.isGranted) {
        if (!mounted) return;
        if (requestResult.isPermanentlyDenied || requestResult.isRestricted) {
          await _showCameraPermissionDialog();
        } else {
          // User denied non-permanently — treat as cancellation.
          if (Navigator.canPop(context)) {
            Navigator.pop(context);
          }
        }
        return;
      }
    }

    setState(() {
      _isScanning = true;
      _error = null;
      _errorIsTerminal = false;
      _consecutiveNonNetworkFailures = 0;
    });

    try {
      // cunning_document_scanner uses native scanners on both platforms:
      // - Android: Google ML Kit Document Scanner
      // - iOS: Apple VisionKit (VNDocumentCameraViewController)
      final List<String>? pictures = await CunningDocumentScanner.getPictures(
        noOfPages: 1,
        isGalleryImportAllowed: false,
      );

      if (pictures != null && pictures.isNotEmpty) {
        setState(() {
          _scannedIdPath = pictures.first;
          _isScanning = false;
        });

        // Auto-submit after successful scan
        await _submitVerification();
      } else {
        // User cancelled
        if (mounted && Navigator.canPop(context)) {
          Navigator.pop(context);
        }
      }
    } catch (e) {
      debugPrint('Document scan error: $e');
      if (mounted) {
        final errorStr = e.toString().toLowerCase();
        if (errorStr.contains('cancelled') || errorStr.contains('canceled')) {
          if (Navigator.canPop(context)) {
            Navigator.pop(context);
          }
        } else {
          setState(() {
            _error = 'Scan failed. Please try again.';
            _isScanning = false;
          });
        }
      }
    }
  }

  Future<void> _submitVerification() async {
    if (_scannedIdPath == null) return;

    setState(() {
      _isSubmitting = true;
      _error = null;
      _errorIsTerminal = false;
      _offlineError = null;
      _showCancelAffordance = false;
    });

    _submitTimeoutTimer?.cancel();
    _cancelAffordanceTimer?.cancel();

    // Safety net: if backend hangs > 30s, surface a transient error and let
    // the user retry. The Dio request itself isn't aborted (no CancelToken
    // in scope); we just stop showing the spinner so the user has a way
    // forward.
    _submitTimeoutTimer = Timer(const Duration(seconds: 30), () {
      if (!mounted || !_isSubmitting) return;
      setState(() {
        _isSubmitting = false;
        _error = 'This is taking longer than expected. Please try again.';
        _errorIsTerminal = false;
      });
    });

    // After 4s of waiting, expose a Cancel button so the user has agency.
    // Kept short because a 60+ user can read a longer wait as "stuck".
    // Tap-cancel just pops the screen back (orphans the in-flight request
    // — same behavior as the prior dialog's cancel button).
    _cancelAffordanceTimer = Timer(const Duration(seconds: 4), () {
      if (!mounted || !_isSubmitting) return;
      setState(() => _showCancelAffordance = true);
    });

    try {
      final authNotifier = ref.read(authNotifierProvider.notifier);

      // Run on-device OCR over the captured ID before upload so the
      // backend can persist real PII (firstName, lastName, dob, etc.)
      // for profile-setup pre-fill instead of falling back to its stub.
      // We send whatever we extracted even on partial success — partial
      // names are still better than the backend's hardcoded fallback.
      // Total failure is non-fatal: uploading without OCR data still
      // creates the verification record, the user just types more.
      Map<String, dynamic>? ocrPayload;
      final ocrService = IdOcrService();
      try {
        final ocr = await ocrService.extractDobFromId(_scannedIdPath!, 60);
        // Always send if we got SOMETHING — DOB or any name. Backend's
        // parseOcrJson handles missing fields gracefully (returns null
        // for whatever is absent).
        final candidate = ocr.toFrontendOcrData();
        final hasAnything =
            candidate['firstName'] != null ||
            candidate['lastName'] != null ||
            candidate['middleName'] != null ||
            candidate['dob'] != null ||
            candidate['documentNumber'] != null;
        if (hasAnything) {
          ocrPayload = candidate;
          debugPrint('[OCR] sending prefill data: ${candidate.keys}');
        } else {
          debugPrint(
            '[OCR] no extractable data: success=${ocr.success}, '
            'qualityScore=${ocr.qualityScore}, '
            'rawTextLength=${ocr.rawTextLength}, '
            'error=${ocr.errorMessage}',
          );
        }
      } catch (e) {
        debugPrint('[OCR] threw: $e');
      } finally {
        ocrService.dispose();
      }

      // Returns auditId on success, null on failure
      final auditId = await authNotifier.verifyIdPreRegister(
        idPhotoFrontPath: _scannedIdPath!,
        frontendOcrData: ocrPayload,
      );

      if (!mounted) return;

      if (auditId != null && auditId.isNotEmpty) {
        // SUCCESS! AuditId is saved to secure storage by the repository.
        // Show success screen, then redirect to sign-up to complete registration.
        _resetSubmitTimers();
        unawaited(
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(
              builder: (_) => const VerificationResultScreen(
                state: VerificationResultState.success,
              ),
            ),
          ),
        );
      } else {
        // Verification returned null without throwing — should not happen
        // for the current notifier contract, but keep a defensive fallback.
        _resetSubmitTimers();
        setState(() {
          _error =
              "We couldn't verify your ID this time. Make sure your ID is clear and fully visible, then try again.";
          _isSubmitting = false;
          _consecutiveNonNetworkFailures++;
        });
      }
    } catch (e) {
      // Error policy: terminal outcomes (duplicate, face-mismatch, age, fraud,
      // blocked, cooldown, rate-limited) push to VerificationResultScreen.
      // Transient outcomes (network, OCR fail, generic) stay inline via _buildErrorView.
      //
      // 401 unauthorized must be handled BEFORE any string-matching of
      // backend error codes — otherwise an expired session falls into
      // duplicate-ID / age / fraud misclassification paths.
      if (e is DioException && e.response?.statusCode == 401) {
        if (mounted) {
          _resetSubmitTimers();
          setState(() => _isSubmitting = false);
          TanderToastOverlay.show(
            context,
            const TanderToastData(
              message: 'Session expired. Please sign in again.',
              variant: TanderToastVariant.error,
            ),
          );
          await Future.delayed(const Duration(milliseconds: 500));
          if (mounted) context.go(AppRoutes.login);
        }
        return;
      }
      // Offline / connection failure — show sticky retry banner instead of
      // falling into the OCR/backend-code parsing path. See
      // network_exception_handler.dart for the catch-order policy.
      if (e is NetworkException) {
        if (mounted) {
          _resetSubmitTimers();
          setState(() {
            _isSubmitting = false;
            _offlineError = e;
          });
        }
        return;
      }
      debugPrint('Verification submission error: $e');
      if (mounted) {
        final raw = e.toString();
        final errorStr = raw.toLowerCase();

        // Stable code embedded by repository: CODE:id-low-quality:, etc.
        String? backendCode;
        final codeMatch = RegExp(r'CODE:([a-z0-9-]+):').firstMatch(raw);
        if (codeMatch != null) backendCode = codeMatch.group(1);

        // Check for duplicate ID / identifier already in use. Match on stable
        // code first (id-duplicate from v3k+), then fall back to legacy text
        // patterns including the new "already exists for this person" copy.
        final isDuplicate =
            backendCode == 'id-duplicate' ||
            errorStr.contains('identifier_in_use') ||
            errorStr.contains('duplicate') ||
            errorStr.contains('already registered') ||
            errorStr.contains('already been used') ||
            errorStr.contains('already exists for this person') ||
            errorStr.contains("haven't finished your profile");
        if (isDuplicate) {
          _resetSubmitTimers();
          setState(() => _isSubmitting = false);

          String? emailHint;
          final hintMatch = RegExp(r'\|HINT:([^|:]+)').firstMatch(raw);
          if (hintMatch != null) emailHint = hintMatch.group(1);
          String? existingState;
          final stateMatch = RegExp(r'\|STATE:([A-Z_]+)').firstMatch(raw);
          if (stateMatch != null) existingState = stateMatch.group(1);

          unawaited(
            Navigator.of(context).pushReplacement(
              MaterialPageRoute(
                builder: (_) => VerificationResultScreen(
                  state: VerificationResultState.duplicateIdDetected,
                  emailHint: emailHint,
                  existingAccountState: existingState,
                ),
              ),
            ),
          );
          return;
        }

        // Check for other specific error types
        VerificationResultState? resultState;
        if (errorStr.contains('face') && errorStr.contains('mismatch')) {
          resultState = VerificationResultState.faceMismatch;
        } else if (backendCode == 'id-age-not-met' ||
            // Word-boundary match so the fallback doesn't fire on 'image'
            // (im-AGE) — a blurry/quality error must not masquerade as an
            // age rejection. Stable backendCode is the primary signal.
            RegExp(r'\bage\b').hasMatch(errorStr)) {
          resultState = VerificationResultState.ageRequirementNotMet;
        } else if (errorStr.contains('fraud')) {
          resultState = VerificationResultState.fraudDetected;
        } else if (errorStr.contains('blocked')) {
          resultState = VerificationResultState.idBlocked;
        }

        if (resultState != null) {
          _resetSubmitTimers();
          unawaited(
            Navigator.of(context).pushReplacement(
              MaterialPageRoute(
                builder: (_) => VerificationResultScreen(state: resultState!),
              ),
            ),
          );
        } else {
          // Inline error path. Mark the error terminal (no Retry Submit) for
          // categories where retrying the same scan won't help — the user
          // must take a new photo or contact support.
          final terminalCodes = {
            'id-age-not-met',
            'id-expired',
            'id-duplicate',
          };
          final isTerminal =
              backendCode != null && terminalCodes.contains(backendCode);
          _resetSubmitTimers();
          setState(() {
            _error = _humanizeError(e);
            _errorIsTerminal = isTerminal;
            _isSubmitting = false;
            _consecutiveNonNetworkFailures++;
          });
        }
      }
    }
  }

  Future<void> _showCameraPermissionDialog() async {
    final shouldOpenSettings = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Camera permission needed'),
        content: const Text(
          'Tander needs camera access to scan your ID. Open Settings to enable it.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text('Open Settings'),
          ),
        ],
      ),
    );

    if (!mounted) return;

    if (shouldOpenSettings == true) {
      await openAppSettings();
      // User must come back and tap "Retry Scan" — no auto-retry on resume.
      // Surface an actionable error so the screen isn't stuck on the
      // "Starting Document Scanner..." spinner forever.
      if (!mounted) return;
      setState(() {
        _error =
            'Camera permission is required. Tap Retry after enabling it in Settings.';
        _errorIsTerminal = false;
      });
    } else if (Navigator.canPop(context)) {
      Navigator.pop(context);
    }
  }

  /// Strips wrapper prefixes ("Exception:", "FormatException:",
  /// "verifyIdPreRegister failed:") that get layered on as the error
  /// bubbles up through Result → notifier → screen, so the user sees
  /// just the server's human message ("Tander is for seniors 60 years
  /// and older. Your age: 22.") instead of a stack-of-prefixes blob.
  String _humanizeError(Object e) {
    String s = e.toString().trim();
    // Peel off known wrapper prefixes in priority order. Loop until stable.
    final prefixes = [
      RegExp(r'^Exception:\s*'),
      RegExp(r'^verifyIdPreRegister failed:\s*'),
      RegExp(r'^FormatException:\s*'),
    ];
    bool changed = true;
    while (changed) {
      changed = false;
      for (final p in prefixes) {
        final next = s.replaceFirst(p, '').trim();
        if (next != s) {
          s = next;
          changed = true;
        }
      }
    }
    s = s.replaceAll(RegExp(r'CODE:[a-z0-9-]+:\s*'), '').trim();
    if (s.isEmpty) {
      return "We couldn't verify your ID this time. Make sure your ID is clear and fully visible, then try again.";
    }
    return s;
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      // Block system back-press while a verification submit is in flight —
      // popping orphans the Dio request and would land the user in an
      // ambiguous state. The 4s-delayed Cancel button in _buildSubmittingView
      // is the sanctioned escape hatch.
      canPop: !_isSubmitting,
      child: Scaffold(
        backgroundColor: Colors.black,
        body: AuthStepScaffoldBody(
          parchment: AuthStepParchment(
            child: _isSubmitting
                ? _buildSubmittingView()
                : _offlineError != null
                ? _buildOfflineRetryView()
                : _error != null
                ? _buildErrorView()
                : _buildLoadingView(),
          ),
        ),
      ),
    );
  }

  Widget _buildLoadingView() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const CircularProgressIndicator(color: Color(0xFFE86035)),
        const SizedBox(height: 24),
        const Text(
          'Starting Document Scanner...',
          style: TextStyle(color: Colors.black54, fontSize: 16),
        ),
        const SizedBox(height: 8),
        Text(
          Platform.isIOS ? 'Apple VisionKit' : 'ML-powered edge detection',
          style: const TextStyle(color: Colors.black45, fontSize: 14),
        ),
      ],
    );
  }

  Widget _buildSubmittingView() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(
          width: 100,
          height: 100,
          decoration: BoxDecoration(
            color: const Color(0xFF5BBFB3).withValues(alpha: 0.2),
            shape: BoxShape.circle,
          ),
          child: const Center(
            child: CircularProgressIndicator(
              color: Color(0xFF5BBFB3),
              strokeWidth: 4,
            ),
          ),
        ),
        const SizedBox(height: 32),
        // liveRegion so screen readers announce the transition into the
        // verifying state (and out of it, into error/success). Wrap only the
        // primary status line — a single live region per view avoids
        // double-announcing.
        Semantics(
          liveRegion: true,
          child: const Text(
            'Verifying your identity...',
            style: TextStyle(
              color: Colors.black87,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        const SizedBox(height: 12),
        const Text(
          'This may take a moment',
          style: TextStyle(color: Colors.black54, fontSize: 15),
        ),
        const SizedBox(height: 16),
        // Privacy reassurance repeated at the submit point (the only other
        // place it appears is the screen one step back). Must stay consistent
        // with the actual retention policy: encrypted, identity-only,
        // permanently deleted within 30 days, never shared. No biometric /
        // face-recognition claims.
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 24),
          child: Text(
            "Your ID is encrypted and only used to confirm it's really you. We delete the photo within 30 days and never share it.",
            style: TextStyle(color: Colors.black54, fontSize: 14),
            textAlign: TextAlign.center,
          ),
        ),
        if (_showCancelAffordance) ...[
          const SizedBox(height: 24),
          TextButton(
            onPressed: () {
              _resetSubmitTimers();
              if (Navigator.canPop(context)) {
                Navigator.pop(context);
              }
            },
            child: const Text(
              'Cancel',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: AppColors.textMuted,
              ),
            ),
          ),
        ],
      ],
    );
  }

  void _retryOffline() {
    setState(() => _offlineError = null);
    _submitVerification();
  }

  Widget _buildOfflineRetryView() {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          AuthErrorDisplay.banner(
            message: _offlineError!.userMessage,
            autoDismiss: false,
            onRetry: _retryOffline,
            onDismiss: () => setState(() => _offlineError = null),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorView() {
    // Terminal errors (duplicate, age-not-met, expired) can't be fixed by
    // retrying the same scan — offer "Go to Login" / "Take New Photo"
    // instead. Non-terminal errors (network, transient OCR) keep the
    // retry-submit / retry-scan path.
    final primaryLabel = _errorIsTerminal
        ? 'Go to Login'
        : (_scannedIdPath != null ? 'Retry Submit' : 'Retry Scan');
    final VoidCallback primaryOnPressed = _errorIsTerminal
        ? () => context.go(AppRoutes.login)
        : (_scannedIdPath != null ? _submitVerification : _startScan);

    return Padding(
      padding: const EdgeInsets.all(32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error_outline, color: Color(0xFFE86035), size: 64),
          const SizedBox(height: 24),
          // liveRegion so screen readers announce the transition into the
          // error state (verifying -> error). One live region per view.
          Semantics(
            liveRegion: true,
            child: Text(
              _error!,
              style: const TextStyle(color: Colors.black87, fontSize: 16),
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(height: 32),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.grey[800],
                  minimumSize: const Size(120, 50),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                onPressed: () => Navigator.pop(context),
                child: const Text(
                  'Cancel',
                  style: TextStyle(color: Colors.white),
                ),
              ),
              const SizedBox(width: 16),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFE86035),
                  minimumSize: const Size(120, 50),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                onPressed: primaryOnPressed,
                child: Text(
                  primaryLabel,
                  style: const TextStyle(color: Colors.white),
                ),
              ),
            ],
          ),
          if (_consecutiveNonNetworkFailures >= 3) ...[
            const SizedBox(height: 20),
            TextButton.icon(
              onPressed: () => launchSupportEmail(
                context,
                subject: 'ID Scanner verification issue',
              ),
              icon: const Icon(Icons.mail_outline_rounded),
              label: const Text('Contact Support'),
              style: TextButton.styleFrom(
                foregroundColor: const Color(0xFFE86035),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
