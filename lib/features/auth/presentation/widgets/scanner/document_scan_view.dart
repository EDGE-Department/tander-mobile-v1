import 'dart:async';
import 'dart:io';
import 'dart:math' as math;

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter/services.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import '../../../../../core/theme/app_colors.dart';
import '../../../data/id_ocr_service.dart';

enum _DocScanPhase {
  initializing,
  positioning,
  capturing,
  processing,
  retrying,
  timeout,
  error,
}

/// Fully automatic ID scanner -- no buttons, no countdowns.
///
/// Camera opens, user positions ID, auto-captures after brief delay.
/// If OCR fails, auto-retries. Super simple for elderly users.
class DocumentScanView extends StatefulWidget {
  final int minimumAge;
  final void Function(String photoPath, OcrResult ocrResult) onScanned;
  final ValueChanged<String> onError;

  const DocumentScanView({
    super.key,
    required this.minimumAge,
    required this.onScanned,
    required this.onError,
  });

  @override
  State<DocumentScanView> createState() => _DocumentScanViewState();
}

class _DocumentScanViewState extends State<DocumentScanView>
    with WidgetsBindingObserver, SingleTickerProviderStateMixin {
  // After brightness check confirms card is in frame, wait this long before capture.
  static const _captureHoldDuration = Duration(milliseconds: 1200);
  // After a failed OCR, wait this long before resuming stream analysis.
  static const _retryDelay = Duration(seconds: 6);
  // Max number of takePicture() calls before timing out.
  static const _maxAttempts = 8;
  // How many consecutive "bright" frames needed before we schedule capture.
  static const _requiredBrightFrames = 12;

  final _ocrService = IdOcrService();

  CameraController? _camera;
  Timer? _captureTimer;

  _DocScanPhase _phase = _DocScanPhase.initializing;
  String _status = 'Starting camera...';
  String? _error;
  int _attempt = 0;

  late final AnimationController _scanCtrl;

  bool _isInitializing = false;
  bool _isCapturing = false;
  bool _isDisposed = false;

  // Stream-based alignment state (avoids repeated takePicture() shutter sounds).
  int _streamFrameIndex = 0;
  int _brightFrameCount = 0;
  bool _captureScheduled = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _scanCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2200),
    )..repeat();
    _initCamera();
  }

  @override
  void dispose() {
    _isDisposed = true;
    WidgetsBinding.instance.removeObserver(this);
    _captureTimer?.cancel();
    _disposeCamera();
    _scanCtrl.dispose();
    _ocrService.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (_isDisposed) return;

    if (state == AppLifecycleState.inactive ||
        state == AppLifecycleState.paused) {
      _captureTimer?.cancel();
      _disposeCamera();
      return;
    }

    if (state == AppLifecycleState.resumed && _camera == null && mounted) {
      _initCamera();
    }
  }

  Future<void> _disposeCamera() async {
    final camera = _camera;
    _camera = null;
    if (camera == null) return;

    try {
      if (camera.value.isStreamingImages) {
        await camera.stopImageStream();
      }
    } catch (_) {}

    try {
      await camera.dispose();
    } catch (_) {}
  }

  Future<void> _initCamera() async {
    if (_isInitializing || _isDisposed) return;

    _isInitializing = true;
    _captureTimer?.cancel();
    _attempt = 0;
    _error = null;
    _streamFrameIndex = 0;
    _brightFrameCount = 0;
    _captureScheduled = false;
    _setPhase(_DocScanPhase.initializing, 'Starting camera...');

    try {
      final permission = await Permission.camera.request();
      if (!permission.isGranted) {
        _setError('Camera permission is required to scan your ID.');
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

      _setPhase(_DocScanPhase.positioning, 'Place your ID inside the frame.');

      // Use image stream to detect when ID is in frame -- no shutter sound.
      await controller.startImageStream(_analyzeAlignmentFrame);
    } catch (_) {
      _setError('Could not start camera. Please try again.');
    } finally {
      _isInitializing = false;
    }
  }

  /// Analyzes camera stream frames to detect when an ID card is likely in frame.
  /// Fires takePicture() only once alignment is confirmed -- avoids repeated
  /// shutter sounds on iOS that occur with blind timer-based capture.
  void _analyzeAlignmentFrame(CameraImage image) {
    if (_isDisposed || !mounted || _isCapturing || _captureScheduled) return;

    _streamFrameIndex++;
    // Sample every 6th frame (~5fps at 30fps stream) to save CPU.
    if (_streamFrameIndex % 6 != 0) return;

    // Sample brightness from the Y (luma) plane center region.
    final yPlane = image.planes.first.bytes;
    if (yPlane.isEmpty) return;

    final sampleCount = 60;
    final step = math.max(1, yPlane.length ~/ sampleCount);
    int sum = 0;
    for (int i = 0; i < sampleCount; i++) {
      final index = i * step;
      if (index < yPlane.length) sum += yPlane[index];
    }
    final avgBrightness = sum / sampleCount;

    // Brightness 40-240: card present with adequate lighting (not dark room /
    // not blown-out overexposure). Accumulate consecutive good frames.
    if (avgBrightness >= 40 && avgBrightness <= 240) {
      _brightFrameCount++;
      if (_brightFrameCount >= _requiredBrightFrames) {
        _captureScheduled = true;
        _brightFrameCount = 0;
        // Brief hold so the user sees "Hold still" before the shutter fires.
        _captureTimer?.cancel();
        _captureTimer = Timer(_captureHoldDuration, () {
          if (!_isDisposed && mounted) _captureAndAnalyze();
        });
        _setPhase(_DocScanPhase.capturing, 'Hold still...');
      } else if (_brightFrameCount == _requiredBrightFrames ~/ 2) {
        _setPhase(_DocScanPhase.positioning, 'Looking good -- hold still...');
      }
    } else {
      // Frame too dark or overexposed -- reset counter.
      if (_brightFrameCount > 0) {
        _brightFrameCount = 0;
        _setPhase(_DocScanPhase.positioning, 'Place your ID inside the frame.');
      }
    }
  }

  Future<void> _stopStreamIfRunning() async {
    final camera = _camera;
    if (camera == null || !camera.value.isInitialized) return;
    try {
      if (camera.value.isStreamingImages) {
        await camera.stopImageStream();
      }
    } catch (_) {}
  }

  Future<void> _resumeStreamAnalysis() async {
    if (_isDisposed) return;
    _captureScheduled = false;
    _brightFrameCount = 0;
    _streamFrameIndex = 0;

    await Future.delayed(_retryDelay);
    if (_isDisposed || !mounted) return;

    final camera = _camera;
    if (camera == null || !camera.value.isInitialized) return;
    try {
      if (!camera.value.isStreamingImages) {
        await camera.startImageStream(_analyzeAlignmentFrame);
      }
    } catch (_) {}
    _setPhase(_DocScanPhase.retrying, 'Adjusting -- hold your ID steady.');
  }

  Future<void> _captureAndAnalyze() async {
    final camera = _camera;
    if (_isDisposed ||
        !mounted ||
        _isCapturing ||
        camera == null ||
        !camera.value.isInitialized) {
      _captureScheduled = false;
      return;
    }

    if (_attempt >= _maxAttempts) {
      _captureTimer?.cancel();
      _setPhase(
        _DocScanPhase.timeout,
        'Could not read your ID. Please try with better lighting.',
      );
      widget.onError('AUTO_CAPTURE_TIMEOUT');
      return;
    }

    _attempt += 1;
    _isCapturing = true;

    try {
      // Stop stream before taking picture -- prevents concurrent stream/capture
      // and avoids extra shutter triggers on iOS.
      await _stopStreamIfRunning();

      _setPhase(_DocScanPhase.capturing, 'Taking photo...');
      final xFile = await camera.takePicture();

      if (!mounted || _isDisposed) return;

      _setPhase(_DocScanPhase.processing, 'Reading your ID...');
      final ocrResult =
          await _ocrService.extractDobFromId(xFile.path, widget.minimumAge);

      if (!mounted || _isDisposed) return;

      if (ocrResult.success && ocrResult.meetsAgeRequirement) {
        HapticFeedback.heavyImpact();
        _announce('ID scanned successfully.');
        _captureTimer?.cancel();
        widget.onScanned(xFile.path, ocrResult);
        return;
      }

      // Delete failed capture to avoid orphaning files.
      await _safeDelete(xFile.path);

      if (ocrResult.success && !ocrResult.meetsAgeRequirement) {
        _captureTimer?.cancel();
        widget.onError(
            'Age requirement not met. Must be ${widget.minimumAge}+.');
        return;
      }

      // Resume stream-based alignment detection after a delay.
      _setPhase(_DocScanPhase.retrying,
          'Couldn\'t read the ID clearly. Repositioning...');
      unawaited(_resumeStreamAnalysis());
    } catch (_) {
      _setPhase(_DocScanPhase.retrying, 'Let\'s try again. Hold your ID steady.');
      unawaited(_resumeStreamAnalysis());
    } finally {
      _isCapturing = false;
    }
  }

  Future<void> _safeDelete(String path) async {
    try {
      final file = File(path);
      if (await file.exists()) {
        await file.delete();
      }
    } catch (_) {}
  }

  void _setPhase(_DocScanPhase phase, String status) {
    if (!mounted || _isDisposed) return;
    setState(() {
      _phase = phase;
      _status = status;
      if (phase != _DocScanPhase.error) {
        _error = null;
      }
    });
  }

  void _setError(String message) {
    if (!mounted || _isDisposed) return;
    _captureTimer?.cancel();
    setState(() {
      _phase = _DocScanPhase.error;
      _error = message;
      _status = message;
    });
    widget.onError(message);
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
    _captureTimer?.cancel();
    _captureScheduled = false;
    _brightFrameCount = 0;
    await _disposeCamera();
    if (!mounted || _isDisposed) return;
    _initCamera();
  }

  @override
  Widget build(BuildContext context) {
    if (_phase == _DocScanPhase.error || _phase == _DocScanPhase.timeout) {
      return _errorView();
    }

    final camera = _camera;
    if (camera == null || !camera.value.isInitialized) {
      return _loadingView();
    }

    final previewSize = camera.value.previewSize;
    if (previewSize == null) return _loadingView();

    return Stack(
      fit: StackFit.expand,
      children: [
        Container(color: const Color(0xFF4B4C4F)),
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
        Positioned.fill(child: IgnorePointer(child: _frameGuide())),
        _statusCard(),
      ],
    );
  }

  Widget _loadingView() {
    return Container(
      color: const Color(0xFF4B4C4F),
      alignment: Alignment.center,
      child: const Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: 42,
            height: 42,
            child: CircularProgressIndicator(
              color: AppColors.primary,
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

  Widget _frameGuide() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isTablet =
            math.min(constraints.maxWidth, constraints.maxHeight) >= 600;
        final frameWidth = math.min(
          constraints.maxWidth * 0.86,
          isTablet ? 520.0 : 360.0,
        );
        final frameHeight = frameWidth / 1.58;
        const cornerSize = 40.0;
        const cornerStroke = 4.0;
        const cornerRadius = 24.0;

        final isScanning = _phase == _DocScanPhase.positioning ||
            _phase == _DocScanPhase.retrying;
        final isCapturing = _phase == _DocScanPhase.capturing ||
            _phase == _DocScanPhase.processing;

        final cornerColor = isCapturing
            ? AppColors.secondary
            : AppColors.primary;

        final frameRect = Rect.fromCenter(
          center: Offset(constraints.maxWidth / 2, constraints.maxHeight / 2),
          width: frameWidth,
          height: frameHeight,
        );

        return AnimatedBuilder(
          animation: _scanCtrl,
          builder: (context, child) {
            final scanY = frameRect.top +
                frameRect.height * CurvedAnimation(
                  parent: _scanCtrl,
                  curve: Curves.easeInOut,
                ).value;

            return Stack(
              children: [
                // Dark overlay with rectangular cutout
                Positioned.fill(
                  child: CustomPaint(
                    painter: _RectCutoutPainter(
                      frameRect: frameRect,
                      borderRadius: cornerRadius,
                    ),
                  ),
                ),
                // Animated scan line (only when scanning)
                if (isScanning)
                  Positioned(
                    top: scanY - 1,
                    left: frameRect.left + 12,
                    right: constraints.maxWidth - frameRect.right + 12,
                    child: Container(
                      height: 2,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(999),
                        gradient: LinearGradient(
                          colors: [
                            Colors.transparent,
                            AppColors.primary.withValues(alpha: 0.8),
                            Colors.transparent,
                          ],
                        ),
                      ),
                    ),
                  ),
                // Animated corner brackets
                Positioned(
                  left: frameRect.left,
                  top: frameRect.top,
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 400),
                    child: _corner(
                      topLeft: true,
                      size: cornerSize,
                      stroke: cornerStroke,
                      radius: cornerRadius,
                      color: cornerColor,
                    ),
                  ),
                ),
                Positioned(
                  right: constraints.maxWidth - frameRect.right,
                  top: frameRect.top,
                  child: _corner(
                    topRight: true,
                    size: cornerSize,
                    stroke: cornerStroke,
                    radius: cornerRadius,
                    color: cornerColor,
                  ),
                ),
                Positioned(
                  left: frameRect.left,
                  bottom: constraints.maxHeight - frameRect.bottom,
                  child: _corner(
                    bottomLeft: true,
                    size: cornerSize,
                    stroke: cornerStroke,
                    radius: cornerRadius,
                    color: cornerColor,
                  ),
                ),
                Positioned(
                  right: constraints.maxWidth - frameRect.right,
                  bottom: constraints.maxHeight - frameRect.bottom,
                  child: _corner(
                    bottomRight: true,
                    size: cornerSize,
                    stroke: cornerStroke,
                    radius: cornerRadius,
                    color: cornerColor,
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Widget _corner({
    bool topLeft = false,
    bool topRight = false,
    bool bottomLeft = false,
    bool bottomRight = false,
    required double size,
    required double stroke,
    required double radius,
    required Color color,
  }) {
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(
        painter: _CornerPainter(
          topLeft: topLeft,
          topRight: topRight,
          bottomLeft: bottomLeft,
          bottomRight: bottomRight,
          stroke: stroke,
          radius: radius,
          color: color,
        ),
      ),
    );
  }

  Widget _statusCard() {
    final badgeText = switch (_phase) {
      _DocScanPhase.positioning => 'Align your ID within the frame',
      _DocScanPhase.capturing => 'Hold still...',
      _DocScanPhase.processing => 'Reading your ID...',
      _DocScanPhase.retrying => 'Adjusting position...',
      _ => 'Place your ID here',
    };

    final badgeColor = switch (_phase) {
      _DocScanPhase.capturing || _DocScanPhase.processing => AppColors.secondary,
      _ => AppColors.primary,
    };

    return Positioned(
      bottom: 80,
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
          child: AnimatedContainer(
            key: ValueKey(badgeColor),
            duration: const Duration(milliseconds: 350),
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
                if (_phase == _DocScanPhase.processing) ...[
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
                  badgeText,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
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

class _RectCutoutPainter extends CustomPainter {
  final Rect frameRect;
  final double borderRadius;

  const _RectCutoutPainter({
    required this.frameRect,
    required this.borderRadius,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFF4B4C4F)
      ..style = PaintingStyle.fill;

    final path = Path()
      ..addRect(Rect.fromLTWH(0, 0, size.width, size.height))
      ..addRRect(
        RRect.fromRectAndRadius(
          frameRect,
          Radius.circular(borderRadius),
        ),
      );
    path.fillType = PathFillType.evenOdd;
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(_RectCutoutPainter old) =>
      old.frameRect != frameRect || old.borderRadius != borderRadius;
}

class _CornerPainter extends CustomPainter {
  final bool topLeft;
  final bool topRight;
  final bool bottomLeft;
  final bool bottomRight;
  final double stroke;
  final double radius;
  final Color color;

  const _CornerPainter({
    this.topLeft = false,
    this.topRight = false,
    this.bottomLeft = false,
    this.bottomRight = false,
    required this.stroke,
    required this.radius,
    required this.color,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke
      ..strokeCap = StrokeCap.round;

    final path = Path();
    if (topLeft) {
      path.moveTo(0, size.height);
      path.lineTo(0, radius);
      path.arcToPoint(
        Offset(radius, 0),
        radius: Radius.circular(radius),
      );
      path.lineTo(size.width, 0);
    } else if (topRight) {
      path.moveTo(0, 0);
      path.lineTo(size.width - radius, 0);
      path.arcToPoint(
        Offset(size.width, radius),
        radius: Radius.circular(radius),
      );
      path.lineTo(size.width, size.height);
    } else if (bottomLeft) {
      path.moveTo(0, 0);
      path.lineTo(0, size.height - radius);
      path.arcToPoint(
        Offset(radius, size.height),
        radius: Radius.circular(radius),
        clockwise: false,
      );
      path.lineTo(size.width, size.height);
    } else if (bottomRight) {
      path.moveTo(0, size.height);
      path.lineTo(size.width - radius, size.height);
      path.arcToPoint(
        Offset(size.width, size.height - radius),
        radius: Radius.circular(radius),
        clockwise: false,
      );
      path.lineTo(size.width, 0);
    }
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(_CornerPainter old) => false;
}
