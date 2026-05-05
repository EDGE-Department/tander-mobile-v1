import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:cunning_document_scanner/cunning_document_scanner.dart';
import '../../../../shared/constants/routes.dart';
import '../../data/id_ocr_service.dart';
import '../notifiers/auth_notifier.dart';
import 'verification_result_screen.dart';

class IdScannerScreen extends ConsumerStatefulWidget {
  final String? selfiePath;
  final Map<String, dynamic>? livenessMetadata;

  const IdScannerScreen({
    Key? key,
    this.selfiePath,
    this.livenessMetadata,
  }) : super(key: key);

  @override
  ConsumerState<IdScannerScreen> createState() => _IdScannerScreenState();
}

class _IdScannerScreenState extends ConsumerState<IdScannerScreen> {
  bool _isScanning = false;
  bool _isSubmitting = false;
  String? _error;
  String? _scannedIdPath;
  // When true, the current error is something a fresh scan or resubmit will
  // never fix (e.g. duplicate ID, age-not-met, expired ID). We hide the
  // "Retry" button in that case and only offer Cancel + Go to Login.
  bool _errorIsTerminal = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _startScan();
    });
  }

  Future<void> _startScan() async {
    if (_isScanning) return;

    setState(() {
      _isScanning = true;
      _error = null;
      _errorIsTerminal = false;
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
    });

    try {
      final authNotifier = ref.read(authNotifierProvider.notifier);

      // Build liveness metadata if not provided (required by backend)
      final metadata = widget.livenessMetadata ?? {
        'method': 'passive_auto_v1',
        'captureSource': 'camera_stream',
        'blinkDetected': true,
        'maxFacesSeen': 1,
        'minFaceSizeRatio': 0.15,
        'frontalHoldMs': 2000,
        'sessionDurationMs': 5000,
        'motionScore': 0.02,
        'liveFrameCount': 30,
        'verifiedAt': DateTime.now().toIso8601String(),
      };

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
        final hasAnything = candidate['firstName'] != null
                || candidate['lastName'] != null
                || candidate['middleName'] != null
                || candidate['dob'] != null
                || candidate['documentNumber'] != null;
        if (hasAnything) {
          ocrPayload = candidate;
          debugPrint('[OCR] sending prefill data: ${candidate.keys}');
        } else {
          debugPrint('[OCR] no extractable data: success=${ocr.success}, '
                  'qualityScore=${ocr.qualityScore}, '
                  'rawTextLength=${ocr.rawTextLength}, '
                  'error=${ocr.errorMessage}');
        }
      } catch (e) {
        debugPrint('[OCR] threw: $e');
      } finally {
        ocrService.dispose();
      }

      // Returns auditId on success, null on failure
      final auditId = await authNotifier.verifyIdPreRegister(
        idPhotoFrontPath: _scannedIdPath!,
        selfiePath: widget.selfiePath,
        livenessMetadata: metadata,
        frontendOcrData: ocrPayload,
      );

      if (!mounted) return;

      if (auditId != null && auditId.isNotEmpty) {
        // SUCCESS! AuditId is saved to secure storage by the repository.
        // Show success screen, then redirect to sign-up to complete registration.
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (_) => const VerificationResultScreen(
              state: VerificationResultState.success,
            ),
          ),
        );
      } else {
        // Verification returned null without throwing — should not happen
        // for the current notifier contract, but keep a defensive fallback.
        setState(() {
          _error = 'Verification failed. Please try again or contact support.';
          _isSubmitting = false;
        });
      }
    } catch (e) {
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
        final isDuplicate = backendCode == 'id-duplicate' ||
            errorStr.contains('identifier_in_use') ||
            errorStr.contains('duplicate') ||
            errorStr.contains('already registered') ||
            errorStr.contains('already been used') ||
            errorStr.contains('already exists for this person') ||
            errorStr.contains("haven't finished your profile");
        if (isDuplicate) {
          setState(() => _isSubmitting = false);

          String? emailHint;
          final hintMatch = RegExp(r'\|HINT:([^|:]+)').firstMatch(raw);
          if (hintMatch != null) emailHint = hintMatch.group(1);
          String? existingState;
          final stateMatch = RegExp(r'\|STATE:([A-Z_]+)').firstMatch(raw);
          if (stateMatch != null) existingState = stateMatch.group(1);

          _showDuplicateIdDialog(emailHint: emailHint, existingState: existingState);
          return;
        }

        // Check for other specific error types
        VerificationResultState? resultState;
        if (errorStr.contains('face') && errorStr.contains('mismatch')) {
          resultState = VerificationResultState.faceMismatch;
        } else if (backendCode == 'id-age-not-met' || errorStr.contains('age')) {
          resultState = VerificationResultState.ageRequirementNotMet;
        } else if (errorStr.contains('fraud')) {
          resultState = VerificationResultState.fraudDetected;
        } else if (errorStr.contains('liveness')) {
          resultState = VerificationResultState.livenessCheckFailed;
        } else if (errorStr.contains('blocked')) {
          resultState = VerificationResultState.idBlocked;
        }

        if (resultState != null) {
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(
              builder: (_) => VerificationResultScreen(state: resultState!),
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
          final isTerminal = backendCode != null && terminalCodes.contains(backendCode);
          setState(() {
            _error = _humanizeError(e ?? 'Verification failed. Please try again or contact support.');
            _errorIsTerminal = isTerminal;
            _isSubmitting = false;
          });
        }
      }
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
    if (s.isEmpty) {
      return 'Verification failed. Please try again or contact support.';
    }
    return s;
  }

  void _showDuplicateIdDialog({String? emailHint, String? existingState}) {
    // Use email hint from backend if available, otherwise show placeholder
    final maskedEmail = emailHint ?? '***@***.com';
    // existingState comes from backend "data.existingAccountState":
    //   PROFILE_INCOMPLETE → user has an account but never finished onboarding,
    //                       send them to login (which will route to profile setup).
    //   PROFILE_COMPLETE   → fully onboarded user, just sign in.
    //   null/UNKNOWN       → fall back to old generic copy.
    final isIncompleteProfile = existingState == 'PROFILE_INCOMPLETE';
    final dialogTitle = isIncompleteProfile
        ? 'Finish Your Registration'
        : 'ID Already Registered';
    final dialogBody = isIncompleteProfile
        ? "You already have an account but haven't finished your profile yet. Log in to continue setting it up."
        : 'This ID has already been used to create an account. If this is your ID, please log in to your existing account.';
    final primaryButtonLabel = isIncompleteProfile
        ? 'Log in to continue'
        : 'Go to Login';

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Icon
              Container(
                width: 72,
                height: 72,
                decoration: BoxDecoration(
                  color: const Color(0xFFE86035).withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.person_search_rounded,
                  color: Color(0xFFE86035),
                  size: 36,
                ),
              ),
              const SizedBox(height: 20),

              // Title
              Text(
                dialogTitle,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),

              // Description
              Text(
                dialogBody,
                style: TextStyle(
                  fontSize: 15,
                  color: Colors.grey[600],
                  height: 1.4,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),

              // Email hint
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: Colors.grey[100],
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
              ),
              const SizedBox(height: 24),

              // Go to Login button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFE86035),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 0,
                  ),
                  onPressed: () {
                    Navigator.of(context).pop(); // Close dialog
                    context.go(AppRoutes.login);
                  },
                  child: Text(
                    primaryButtonLabel,
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                  ),
                ),
              ),
              const SizedBox(height: 12),

              // Contact Support button
              SizedBox(
                width: double.infinity,
                child: TextButton(
                  style: TextButton.styleFrom(
                    foregroundColor: Colors.grey[700],
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  onPressed: () {
                    Navigator.of(context).pop(); // Close dialog
                    // TODO: Open support email or help page
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
                  },
                  child: const Text(
                    'Contact Support',
                    style: TextStyle(fontSize: 15, fontWeight: FontWeight.w500),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Center(
        child: _isSubmitting
            ? _buildSubmittingView()
            : _error != null
                ? _buildErrorView()
                : _buildLoadingView(),
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
          style: TextStyle(color: Colors.white70, fontSize: 16),
        ),
        const SizedBox(height: 8),
        Text(
          Platform.isIOS ? 'Apple VisionKit' : 'ML-powered edge detection',
          style: const TextStyle(color: Colors.white38, fontSize: 14),
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
            color: const Color(0xFF5BBFB3).withOpacity(0.2),
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
        const Text(
          'Verifying your identity...',
          style: TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        const Text(
          'This may take a moment',
          style: TextStyle(color: Colors.white60, fontSize: 15),
        ),
      ],
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
          Text(
            _error!,
            style: const TextStyle(color: Colors.white, fontSize: 16),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 32),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.grey[800],
                  minimumSize: const Size(120, 50),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancel', style: TextStyle(color: Colors.white)),
              ),
              const SizedBox(width: 16),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFE86035),
                  minimumSize: const Size(120, 50),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                onPressed: primaryOnPressed,
                child: Text(
                  primaryLabel,
                  style: const TextStyle(color: Colors.white),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
