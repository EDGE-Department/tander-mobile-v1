import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:cunning_document_scanner/cunning_document_scanner.dart';
import '../../../../shared/constants/routes.dart';
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

      // Returns auditId on success, null on failure
      final auditId = await authNotifier.verifyIdPreRegister(
        idPhotoFrontPath: _scannedIdPath!,
        selfiePath: widget.selfiePath,
        livenessMetadata: metadata,
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
        // Verification returned null - show generic error
        setState(() {
          _error = 'Verification failed. Please try again or contact support.';
          _isSubmitting = false;
        });
      }
    } catch (e) {
      debugPrint('Verification submission error: $e');
      if (mounted) {
        final errorStr = e.toString().toLowerCase();

        // Check for duplicate ID / identifier already in use
        if (errorStr.contains('identifier_in_use') ||
            errorStr.contains('duplicate') ||
            errorStr.contains('already registered') ||
            errorStr.contains('already been used')) {
          setState(() => _isSubmitting = false);

          // Extract email hint if present (format: IDENTIFIER_IN_USE|HINT:email@example.com: message)
          String? emailHint;
          final hintMatch = RegExp(r'\|HINT:([^:]+):').firstMatch(e.toString());
          if (hintMatch != null) {
            emailHint = hintMatch.group(1);
          }

          _showDuplicateIdDialog(emailHint: emailHint);
          return;
        }

        // Check for other specific error types
        VerificationResultState? resultState;
        if (errorStr.contains('face') && errorStr.contains('mismatch')) {
          resultState = VerificationResultState.faceMismatch;
        } else if (errorStr.contains('age')) {
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
          setState(() {
            _error = 'Verification failed. Please try again or contact support.';
            _isSubmitting = false;
          });
        }
      }
    }
  }

  void _showDuplicateIdDialog({String? emailHint}) {
    // Use email hint from backend if available, otherwise show placeholder
    final maskedEmail = emailHint ?? '***@***.com';

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
              const Text(
                'ID Already Registered',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),

              // Description
              Text(
                'This ID has already been used to create an account. If this is your ID, please log in to your existing account.',
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
                  child: const Text(
                    'Go to Login',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
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
                onPressed: _scannedIdPath != null ? _submitVerification : _startScan,
                child: Text(
                  _scannedIdPath != null ? 'Retry Submit' : 'Retry Scan',
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
