import 'dart:async';
import 'dart:io';

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter/services.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import '../../../../../core/theme/app_colors.dart';
import '../../../data/id_ocr_service.dart';
import 'auto_track_overlay_painter.dart';
import 'id_rectangle_detector.dart';

/// Auto-detecting ID scanner with CamScanner-style visual feedback.
///
/// Uses ML Kit text recognition to detect ID cards in real-time.
/// Shows a guide frame that turns blue when ID text is detected,
/// green when stable, then auto-captures. No manual alignment needed —
/// the user just points their camera roughly at their ID.
class DocumentScanView extends StatefulWidget {
  final int minimumAge;
  final void Function(String photoPath, OcrResult ocrResult) onScanned;
  final ValueChanged<String> onError;
  final double reservedTopInset;

  const DocumentScanView({
    super.key,
    required this.minimumAge,
    required this.onScanned,
    required this.onError,
    this.reservedTopInset = 0,
  });

  @override
  State<DocumentScanView> createState() => _DocumentScanViewState();
}

class _DocumentScanViewState extends State<DocumentScanView>
    with WidgetsBindingObserver, SingleTickerProviderStateMixin {
  // ---------------------------------------------------------------------------
  // Constants
  // ---------------------------------------------------------------------------

  static const _retryDelay = Duration(seconds: 5);
  static const _maxAttempts = 10;

  /// Consecutive detections needed to confirm ID is present.
  static const _detectionsToConfirm = 3;

  /// Consecutive confirmations needed to start countdown.
  static const _confirmationsToStartCountdown = 2;

  /// Frames to tolerate without detection before resetting.
  static const _missesToReset = 4;

  /// Countdown duration in seconds before capture.
  static const _countdownDuration = 3;

  /// CamScanner blue.
  static const _scannerBlue = Color(0xFF2979FF);
  static const _stableGreen = Color(0xFF00C853);

  // ---------------------------------------------------------------------------
  // State
  // ---------------------------------------------------------------------------

  final _ocrService = IdOcrService();
  final _detector = IdRectangleDetector();

  CameraController? _camera;
  Timer? _timeoutTimer;
  Timer? _countdownTimer;

  ScanPhase _phase = ScanPhase.initializing;
  DetectionState _detection = DetectionState.searching;
  String _status = 'Starting camera...';
  String? _error;
  int _attempt = 0;
  double _confidence = 0.0;

  late final AnimationController _pulseCtrl;

  bool _isInitializing = false;
  bool _isCapturing = false;
  bool _isDisposed = false;
  bool _isDetecting = false;

  int _streamFrameIndex = 0;
  int _consecutiveDetections = 0;
  int _consecutiveConfirmations = 0;
  int _consecutiveMisses = 0;
  int _countdownSeconds = 0;
  bool _isCountingDown = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _pulseCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);
    _initCamera();
  }

  @override
  void dispose() {
    _isDisposed = true;
    WidgetsBinding.instance.removeObserver(this);
    _timeoutTimer?.cancel();
    _countdownTimer?.cancel();
    _disposeCamera();
    _pulseCtrl.dispose();
    _ocrService.dispose();
    _detector.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (_isDisposed) return;
    if (state == AppLifecycleState.inactive ||
        state == AppLifecycleState.paused) {
      _timeoutTimer?.cancel();
      _cancelCountdown();
      _disposeCamera();
      return;
    }
    if (state == AppLifecycleState.resumed && _camera == null && mounted) {
      _initCamera();
    }
  }

  // ---------------------------------------------------------------------------
  // Camera lifecycle
  // ---------------------------------------------------------------------------

  Future<void> _disposeCamera() async {
    final camera = _camera;
    _camera = null;
    if (camera == null) return;
    try {
      if (camera.value.isStreamingImages) await camera.stopImageStream();
    } catch (_) {}
    try {
      await camera.dispose();
    } catch (_) {}
  }

  Future<void> _initCamera() async {
    if (_isInitializing || _isDisposed) return;
    _isInitializing = true;
    _resetState();
    _setPhase(ScanPhase.initializing, 'Starting camera...');

    try {
      final permission = await Permission.camera.request();
      if (!permission.isGranted) {
        if ((permission.isPermanentlyDenied || permission.isRestricted) &&
            mounted) {
          await _showSettingsDialog();
        } else {
          _setError('Camera permission is required to scan your ID.');
        }
        return;
      }

      final cameras = await availableCameras();
      if (cameras.isEmpty) {
        _setError('No camera found on this device.');
        return;
      }

      final backCamera = cameras.firstWhere(
        (c) => c.lensDirection == CameraLensDirection.back,
        orElse: () => cameras.first,
      );

      final controller = CameraController(
        backCamera,
        ResolutionPreset.high,
        enableAudio: false,
        imageFormatGroup: ImageFormatGroup.yuv420,
      );

      await controller.initialize();
      try {
        await controller.setFlashMode(FlashMode.off);
      } catch (_) {}
      try {
        await controller.setFocusMode(FocusMode.auto);
      } catch (_) {}
      _camera = controller;

      if (!mounted || _isDisposed) return;

      _setPhase(ScanPhase.scanning, 'Place your ID inside the frame');
      _detection = DetectionState.searching;

      // 45-second timeout.
      _timeoutTimer?.cancel();
      _timeoutTimer = Timer(const Duration(seconds: 45), () {
        if (!_isDisposed && mounted && _phase == ScanPhase.scanning) {
          _setPhase(
            ScanPhase.timeout,
            'Could not find your ID. Please try with better lighting.',
          );
          widget.onError('AUTO_CAPTURE_TIMEOUT');
        }
      });

      await controller.startImageStream(_onCameraFrame);
    } catch (_) {
      _setError('Could not start camera. Please try again.');
    } finally {
      _isInitializing = false;
    }
  }

  // ---------------------------------------------------------------------------
  // Frame analysis — ML Kit text detection
  // ---------------------------------------------------------------------------

  void _onCameraFrame(CameraImage image) {
    if (_isDisposed || !mounted || _isCapturing) return;
    if (_phase != ScanPhase.scanning) return;
    if (_isDetecting) return;

    _streamFrameIndex++;
    // Process every 5th frame (~6fps). Faster detection = quicker capture.
    if (_streamFrameIndex % 5 != 0) return;

    // Skip brightness gate — let detection handle quality naturally.
    // The "Move to a brighter area" spam was blocking legitimate scans.

    final camera = _camera;
    if (camera == null) return;

    _isDetecting = true;
    _detector.detectAsync(image, camera).then(_onDetectionResult).catchError((_) {
      _isDetecting = false;
    });
  }

  void _onDetectionResult(IdDetectionResult result) {
    _isDetecting = false;
    if (_isDisposed || !mounted || _isCapturing) return;
    if (_phase != ScanPhase.scanning) return;

    if (!result.detected) {
      _onMiss();
      return;
    }

    // Reset miss counter on any detection.
    _consecutiveMisses = 0;
    _confidence = result.confidence;
    _consecutiveDetections++;

    // If already counting down, just keep going (ID still detected)
    if (_isCountingDown) {
      return;
    }

    if (_consecutiveDetections >= _detectionsToConfirm) {
      _consecutiveConfirmations++;

      if (_consecutiveConfirmations >= _confirmationsToStartCountdown) {
        // ID confirmed stable — start countdown
        _startCountdown();
      } else {
        _setDetection(DetectionState.confirming, 'Hold steady...');
      }
    } else {
      _setDetection(DetectionState.detected, 'ID detected...');
    }
  }

  void _startCountdown() {
    if (_isCountingDown || _isCapturing) return;

    _isCountingDown = true;
    _countdownSeconds = _countdownDuration;
    HapticFeedback.lightImpact();
    _setDetection(DetectionState.countingDown, 'Hold still... $_countdownSeconds');

    _countdownTimer?.cancel();
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_isDisposed || !mounted || !_isCountingDown) {
        timer.cancel();
        return;
      }

      _countdownSeconds--;
      HapticFeedback.selectionClick();

      if (_countdownSeconds <= 0) {
        timer.cancel();
        _isCountingDown = false;
        _setDetection(DetectionState.stable, 'Capturing...');
        _doCapture();
      } else {
        _setDetection(DetectionState.countingDown, 'Hold still... $_countdownSeconds');
      }
    });
  }

  void _cancelCountdown() {
    _countdownTimer?.cancel();
    _isCountingDown = false;
    _countdownSeconds = 0;
  }

  void _onMiss() {
    _consecutiveMisses++;

    // Don't reset immediately — tolerate a few missed frames.
    if (_consecutiveMisses >= _missesToReset) {
      // Cancel any active countdown
      if (_isCountingDown) {
        _cancelCountdown();
        HapticFeedback.lightImpact();
      }

      if (_detection != DetectionState.searching) {
        _consecutiveDetections = 0;
        _consecutiveConfirmations = 0;
        _confidence = 0.0;
        _setDetection(
          DetectionState.searching,
          'Place your ID inside the frame',
        );
      }
    }
  }

  void _setDetection(DetectionState state, String status) {
    if (!mounted || _isDisposed) return;
    setState(() {
      _detection = state;
      _status = status;
    });
  }

  // ---------------------------------------------------------------------------
  // Capture
  // ---------------------------------------------------------------------------

  void _doCapture() {
    if (_isCapturing) return;
    HapticFeedback.mediumImpact();

    // Stop detection and capture on next microtask (lets UI paint green first).
    Future.microtask(() {
      if (!_isDisposed && mounted) _captureAndAnalyze();
    });
  }

  Future<void> _stopStreamIfRunning() async {
    final camera = _camera;
    if (camera == null || !camera.value.isInitialized) return;
    try {
      if (camera.value.isStreamingImages) await camera.stopImageStream();
    } catch (_) {}
  }

  Future<void> _captureAndAnalyze() async {
    final camera = _camera;
    if (_isDisposed ||
        !mounted ||
        _isCapturing ||
        camera == null ||
        !camera.value.isInitialized) {
      return;
    }

    if (_attempt >= _maxAttempts) {
      _timeoutTimer?.cancel();
      _setPhase(
        ScanPhase.timeout,
        'Could not read your ID. Please try with better lighting.',
      );
      widget.onError('AUTO_CAPTURE_TIMEOUT');
      return;
    }

    _attempt++;
    _isCapturing = true;

    try {
      await _stopStreamIfRunning();

      _setPhase(ScanPhase.capturing, 'Taking photo...');
      final xFile = await camera.takePicture();

      if (!mounted || _isDisposed) return;

      _setPhase(ScanPhase.processing, 'Reading your ID...');
      final ocrResult =
          await _ocrService.extractDobFromId(xFile.path, widget.minimumAge);

      if (!mounted || _isDisposed) return;

      if (ocrResult.success && ocrResult.meetsAgeRequirement) {
        HapticFeedback.heavyImpact();
        _announce('ID scanned successfully.');
        _timeoutTimer?.cancel();
        widget.onScanned(xFile.path, ocrResult);
        return;
      }

      if (ocrResult.success && !ocrResult.meetsAgeRequirement) {
        await _safeDelete(xFile.path);
        _timeoutTimer?.cancel();
        widget.onError(
            'Age requirement not met. Must be ${widget.minimumAge}+.');
        return;
      }

      // OCR failed or partial — still send to backend (Azure is more accurate).
      // Don't delete the photo or retry with "Repositioning..." — just submit.
      HapticFeedback.heavyImpact();
      _announce('ID captured. Sending for verification...');
      _timeoutTimer?.cancel();
      widget.onScanned(xFile.path, ocrResult);
      return;
    } catch (_) {
      _setPhase(ScanPhase.retrying, 'Let\'s try again.');
      unawaited(_resumeDetection());
    } finally {
      _isCapturing = false;
    }
  }

  Future<void> _resumeDetection() async {
    _resetState();
    await Future.delayed(_retryDelay);
    if (_isDisposed || !mounted) return;

    final camera = _camera;
    if (camera == null || !camera.value.isInitialized) return;
    try {
      if (!camera.value.isStreamingImages) {
        await camera.startImageStream(_onCameraFrame);
      }
    } catch (_) {}
    _setPhase(ScanPhase.scanning, 'Place your ID inside the frame');
    _detection = DetectionState.searching;
  }

  // ---------------------------------------------------------------------------
  // Helpers
  // ---------------------------------------------------------------------------

  void _resetState() {
    _isDetecting = false;
    _consecutiveDetections = 0;
    _consecutiveConfirmations = 0;
    _consecutiveMisses = 0;
    _confidence = 0.0;
    _streamFrameIndex = 0;
    _attempt = 0;
    _error = null;
    _cancelCountdown();
  }

  Future<void> _safeDelete(String path) async {
    try {
      final file = File(path);
      if (await file.exists()) await file.delete();
    } catch (_) {}
  }

  void _setPhase(ScanPhase phase, String status) {
    if (!mounted || _isDisposed) return;
    setState(() {
      _phase = phase;
      _status = status;
      if (phase != ScanPhase.error) _error = null;
    });
  }

  void _setError(String message) {
    if (!mounted || _isDisposed) return;
    _timeoutTimer?.cancel();
    setState(() {
      _phase = ScanPhase.error;
      _error = message;
      _status = message;
    });
    widget.onError(message);
  }

  Future<void> _showSettingsDialog() async {
    if (!mounted) return;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Camera Access Required'),
        content: const Text(
          'Camera permission was denied. To scan your ID, please enable camera access in your device Settings.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Open Settings'),
          ),
        ],
      ),
    );
    if (confirmed == true) await openAppSettings();
  }

  void _announce(String message) {
    if (!mounted || _isDisposed) return;
    try {
      SemanticsService.sendAnnouncement(
        View.of(context),
        message,
        TextDirection.ltr,
      );
    } catch (_) {}
  }

  Future<void> _retry() async {
    _timeoutTimer?.cancel();
    _resetState();
    await _disposeCamera();
    if (!mounted || _isDisposed) return;
    _initCamera();
  }

  // ---------------------------------------------------------------------------
  // Build
  // ---------------------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    if (_phase == ScanPhase.error || _phase == ScanPhase.timeout) {
      return _errorView();
    }

    final camera = _camera;
    if (camera == null || !camera.value.isInitialized) {
      return _loadingView();
    }

    final previewSize = camera.value.previewSize;
    if (previewSize == null) return _loadingView();

    final mediaPadding = MediaQuery.paddingOf(context);

    return Stack(
      fit: StackFit.expand,
      children: [
        Container(color: const Color(0xFF1A1A1A)),
        // Camera preview.
        Positioned.fill(
          child: FittedBox(
            fit: BoxFit.cover,
            child: SizedBox(
              width: previewSize.height,
              height: previewSize.width,
              child: CameraPreview(camera),
            ),
          ),
        ),
        // Overlay with guide frame.
        Positioned.fill(
          child: IgnorePointer(
            child: AnimatedBuilder(
              animation: _pulseCtrl,
              builder: (context, child) {
                return CustomPaint(
                  painter: AutoTrackOverlayPainter(
                    detectionState: _detection,
                    scanPhase: _phase,
                    pulseValue: _pulseCtrl.value,
                    screenSize: MediaQuery.sizeOf(context),
                    confidenceLevel: _confidence,
                    reservedTopInset: widget.reservedTopInset,
                    reservedBottomInset: mediaPadding.bottom + 96,
                    countdownSeconds: _countdownSeconds,
                  ),
                );
              },
            ),
          ),
        ),
        // Status badge.
        _statusBadge(),
      ],
    );
  }

  Widget _loadingView() {
    return Container(
      color: const Color(0xFF1A1A1A),
      alignment: Alignment.center,
      child: const Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: 42,
            height: 42,
            child: CircularProgressIndicator(
              color: Color(0xFF2979FF),
              strokeWidth: 3,
            ),
          ),
          SizedBox(height: 16),
          Text(
            'Starting ID scanner...',
            style: TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _statusBadge() {
    final Color badgeColor;
    switch (_phase) {
      case ScanPhase.processing:
        badgeColor = _scannerBlue;
      case ScanPhase.capturing:
        badgeColor = _stableGreen;
      case ScanPhase.retrying:
        badgeColor = Colors.orange;
      default:
        switch (_detection) {
          case DetectionState.searching:
            badgeColor = Colors.white.withValues(alpha: 0.15);
          case DetectionState.detected:
            badgeColor = _scannerBlue.withValues(alpha: 0.8);
          case DetectionState.confirming:
            badgeColor = _scannerBlue;
          case DetectionState.countingDown:
            badgeColor = const Color(0xFF4CAF50);
          case DetectionState.stable:
            badgeColor = _stableGreen;
        }
    }

    return Positioned(
      bottom: MediaQuery.paddingOf(context).bottom + 24,
      left: 0,
      right: 0,
      child: Center(
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 300),
          transitionBuilder: (child, animation) => FadeTransition(
            opacity: animation,
            child: SlideTransition(
              position: Tween<Offset>(
                begin: const Offset(0, 0.5),
                end: Offset.zero,
              ).animate(animation),
              child: child,
            ),
          ),
          child: Container(
            key: ValueKey('$_phase-$_detection'),
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 13),
            decoration: BoxDecoration(
              color: badgeColor,
              borderRadius: BorderRadius.circular(999),
              boxShadow: [
                BoxShadow(
                  color: badgeColor.withValues(alpha: 0.4),
                  blurRadius: 20,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (_phase == ScanPhase.processing) ...[
                  const SizedBox(
                    width: 14,
                    height: 14,
                    child: CircularProgressIndicator(
                      color: Colors.white,
                      strokeWidth: 2,
                    ),
                  ),
                  const SizedBox(width: 8),
                ],
                Text(
                  _status,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _errorView() {
    final message = _error ?? _status;
    return Container(
      color: const Color(0xFFF8F9FA),
      child: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 88,
                height: 88,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  color: Color(0xFFFFECE8),
                ),
                child: Icon(
                  PhosphorIconsDuotone.warningCircle,
                  color: AppColors.primary,
                  size: 44,
                ),
              ),
              const SizedBox(height: 24),
              const Text(
                'Could not scan your ID',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Color(0xFF141A28),
                  fontSize: 26,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                message,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Color(0xFF747E93),
                  fontSize: 16,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _retry,
                  style: ElevatedButton.styleFrom(
                    minimumSize: const Size.fromHeight(56),
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    elevation: 4,
                    shadowColor: AppColors.primary.withValues(alpha: 0.3),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30),
                    ),
                  ),
                  child: const Text(
                    'Try Again',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
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
