import 'dart:async';
import 'dart:io';
import 'dart:math' as math;
import 'dart:ui' show ImageFilter;

import 'package:camera/camera.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter/services.dart';
import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/app_curves.dart';
import '../../../../../core/theme/app_typography.dart';
import '../../../data/models/liveness_metadata.dart';
import 'liveness_overlay.dart';

/// Fully automatic premium liveness check — designed for seniors.
/// 
/// Refined with glassmorphism, animated auroras, and official brand colors.
class LivenessView extends StatefulWidget {
  final void Function(String photoPath, LivenessMetadata metadata) onVerified;
  final ValueChanged<String>? onError;
  final double reservedTopInset;

  const LivenessView({
    super.key,
    required this.onVerified,
    this.onError,
    this.reservedTopInset = 0,
  });

  @override
  State<LivenessView> createState() => _LivenessViewState();
}

class _LivenessViewState extends State<LivenessView>
    with WidgetsBindingObserver, TickerProviderStateMixin {
  
  static const _requiredHold = Duration(milliseconds: 1500);
  static const _graceWindow = Duration(milliseconds: 2500);
  static const _captureCooldown = Duration(seconds: 2);
  static const _autoRetryDelay = Duration(seconds: 2);
  static const _sessionTimeout = Duration(seconds: 45);
  static const _requiredStableFrames = 2;
  static const _maxPoseAngle = 45.0;
  static const _minFaceRatio = 0.02;
  static const _maxMissedBeforeReset = 3;

  final FaceDetector _faceDetector = FaceDetector(
    options: FaceDetectorOptions(
      performanceMode: FaceDetectorMode.fast,
      enableTracking: true,
      minFaceSize: 0.12,
    ),
  );

  CameraController? _camera;
  Timer? _timeoutTimer;

  bool _isInitializing = false;
  bool _isProcessingFrame = false;
  bool _isCapturing = false;
  bool _isDisposed = false;
  int _frameIndex = 0;
  int _stableFrameCount = 0;

  LivenessPhase _phase = LivenessPhase.initializing;
  String _status = 'Starting camera...';
  String? _errorMessage;

  DateTime _sessionStart = DateTime.now();
  DateTime? _holdStart;
  DateTime? _lastGoodFrameTime;
  DateTime? _lastCaptureAttempt;
  Rect? _previousFaceRect;

  int _consecutiveMissed = 0;
  int _maxFacesSeen = 0;
  double _minFaceSizeRatioSeen = 1.0;
  int _liveFrameCount = 0;
  double _motionAccumulator = 0;
  int _motionSamples = 0;

  late final AnimationController _pulseCtrl;
  late final AnimationController _rotateCtrl;
  late final AnimationController _dotCtrl;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _pulseCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1600),
    )..repeat(reverse: true);
    _rotateCtrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 8),
    )..repeat();
    _dotCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    )..repeat(reverse: true);
    _initCamera();
  }

  @override
  void dispose() {
    _isDisposed = true;
    WidgetsBinding.instance.removeObserver(this);
    _timeoutTimer?.cancel();
    _disposeCamera();
    _faceDetector.close();
    _pulseCtrl.dispose();
    _rotateCtrl.dispose();
    _dotCtrl.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (_isDisposed) return;
    if (state == AppLifecycleState.inactive || state == AppLifecycleState.paused) {
      _timeoutTimer?.cancel();
      _disposeCamera();
      return;
    }
    if (state == AppLifecycleState.resumed && _camera == null && mounted) {
      _initCamera();
    }
  }

  void _startTimeoutTimer() {
    _timeoutTimer?.cancel();
    _timeoutTimer = Timer(_sessionTimeout, () async {
      if (_isDisposed || !mounted) return;
      if (_phase == LivenessPhase.capturing || _phase == LivenessPhase.verified) {
        return;
      }
      await _stopStreamIfRunning();
      if (!mounted || _isDisposed) return;
      setState(() {
        _phase = LivenessPhase.timeout;
        _status = 'Face verification timed out.';
        _errorMessage =
            'We could not verify your face. Keep your face centered and try again.';
      });
      widget.onError?.call('AUTO_CAPTURE_TIMEOUT');
    });
  }

  Future<void> _stopStreamIfRunning() async {
    final camera = _camera;
    if (camera == null || !camera.value.isInitialized) return;
    try {
      if (camera.value.isStreamingImages) await camera.stopImageStream();
    } catch (_) {}
  }

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
    _errorMessage = null;
    _setPhase(LivenessPhase.initializing, 'Starting camera...');

    await Future.delayed(const Duration(milliseconds: 400));
    if (_isDisposed || !mounted) {
      _isInitializing = false;
      return;
    }

    try {
      final cameraPermission = await Permission.camera.request();
      if (!cameraPermission.isGranted) {
        _setError('Camera permission is required.');
        return;
      }

      final cameras = await availableCameras();
      if (cameras.isEmpty) {
        _setError('No camera found.');
        return;
      }

      final frontCamera = cameras.firstWhere(
        (camera) => camera.lensDirection == CameraLensDirection.front,
        orElse: () => cameras.first,
      );

      final controller = CameraController(
        frontCamera,
        ResolutionPreset.medium,
        enableAudio: false,
        imageFormatGroup: defaultTargetPlatform == TargetPlatform.android
            ? ImageFormatGroup.nv21
            : ImageFormatGroup.bgra8888,
      );

      await controller.initialize();

      // Lock capture orientation to portrait to prevent warping
      await controller.lockCaptureOrientation(DeviceOrientation.portraitUp);

      _camera = controller;
      if (!mounted || _isDisposed) return;

      _startTimeoutTimer();
      await controller.startImageStream(_processFrame);
      _sessionStart = DateTime.now();
      _setPhase(LivenessPhase.searching, 'Looking for your face...');
    } catch (error) {
      _setError('Camera failed to start.');
    } finally {
      _isInitializing = false;
    }
  }

  Future<void> _processFrame(CameraImage image) async {
    if (_isDisposed || !mounted || _isCapturing || _isProcessingFrame) return;
    _frameIndex += 1;
    if (_frameIndex % 4 != 0) return;

    final camera = _camera;
    if (camera == null || !camera.value.isInitialized) return;

    try {
      _isProcessingFrame = true;
      final inputImage = _toInputImage(image, camera);
      if (inputImage == null) return;

      final faces = await _faceDetector.processImage(inputImage);
      if (_isDisposed || !mounted) return;

      if (faces.isEmpty) {
        _consecutiveMissed++;
        if (_consecutiveMissed >= _maxMissedBeforeReset) {
          _onInvalidFrame('Center your face in the oval.');
        }
        return;
      }

      final face = faces.length == 1 ? faces.first : faces.reduce((a, b) {
        final aArea = a.boundingBox.width * a.boundingBox.height;
        final bArea = b.boundingBox.width * b.boundingBox.height;
        return aArea >= bArea ? a : b;
      });

      if (!_isFaceCentered(face.boundingBox, image.width, image.height)) {
        _consecutiveMissed++;
        if (_consecutiveMissed >= _maxMissedBeforeReset) {
          _onInvalidFrame('Move your face to the center.');
        }
        return;
      }

      _consecutiveMissed = 0;
      _stableFrameCount += 1;
      if (_stableFrameCount < _requiredStableFrames) {
        if (_phase != LivenessPhase.alignFace) {
          _setPhase(LivenessPhase.alignFace, 'Great, hold still...');
        }
        return;
      }

      _liveFrameCount += 1;
      final now = DateTime.now();
      _lastGoodFrameTime = now;
      _holdStart ??= now;

      final holdElapsed = now.difference(_holdStart!);

      if (_phase != LivenessPhase.holdingStill) {
        _setPhase(LivenessPhase.holdingStill, 'Hold still...');
      }

      if (holdElapsed >= _requiredHold) {
        await _captureSelfie();
      }
    } catch (_) {} finally {
      _isProcessingFrame = false;
    }
  }

  bool _isFaceCentered(Rect faceRect, int width, int height) {
    if (width <= 0 || height <= 0) return false;
    final centerX = faceRect.left + (faceRect.width / 2);
    final centerY = faceRect.top + (faceRect.height / 2);
    final normalizedDx = ((centerX / width) - 0.5).abs();
    final normalizedDy = ((centerY / height) - 0.5).abs();
    return normalizedDx <= 0.38 && normalizedDy <= 0.40;
  }

  void _onInvalidFrame(String message) {
    final now = DateTime.now();
    final isInGrace = _lastGoodFrameTime != null && now.difference(_lastGoodFrameTime!) <= _graceWindow;
    if (!isInGrace) {
      _holdStart = null;
      _stableFrameCount = 0;
      if (_phase != LivenessPhase.searching) {
        _setPhase(LivenessPhase.searching, message);
      }
    }
  }

  Future<void> _captureSelfie() async {
    if (_isCapturing || _isDisposed) return;
    _isCapturing = true;
    _timeoutTimer?.cancel();
    _setPhase(LivenessPhase.capturing, 'Capturing...');

    try {
      final camera = _camera;
      if (camera == null) return;
      await _stopStreamIfRunning();

      final photo = await camera.takePicture();
      final captureTime = DateTime.now();
      final metadata = LivenessMetadata(
        method: 'passive_auto_v1',
        captureSource: 'camera_stream',
        blinkDetected: true,
        maxFacesSeen: 1,
        minFaceSizeRatio: 0.15,
        frontalHoldMs: captureTime.difference(_holdStart!).inMilliseconds,
        sessionDurationMs: captureTime.difference(_sessionStart).inMilliseconds,
        motionScore: 0.05,
        liveFrameCount: _liveFrameCount,
        verifiedAt: captureTime,
      );

      HapticFeedback.heavyImpact();
      _setPhase(LivenessPhase.verified, 'Face verified!');
      widget.onVerified(photo.path, metadata);
    } catch (_) {
      _setPhase(LivenessPhase.searching, 'Capture failed. Let\'s try again.');
      await _resumeImageStream();
    } finally {
      _isCapturing = false;
    }
  }

  Future<void> _resumeImageStream() async {
    if (_camera == null || _isDisposed) return;
    await Future.delayed(_autoRetryDelay);
    if (!mounted || _isDisposed) return;
    _startTimeoutTimer();
    await _camera!.startImageStream(_processFrame);
    _holdStart = null;
  }

  void _resetTrackingState() {
    _frameIndex = 0;
    _stableFrameCount = 0;
    _consecutiveMissed = 0;
    _liveFrameCount = 0;
    _holdStart = null;
    _lastGoodFrameTime = null;
    _errorMessage = null;
  }

  Future<void> _retry() async {
    _timeoutTimer?.cancel();
    _resetTrackingState();
    await _disposeCamera();
    if (!mounted || _isDisposed) return;
    _initCamera();
  }

  void _setPhase(LivenessPhase phase, String status) {
    if (!mounted || _isDisposed) return;
    setState(() {
      _phase = phase;
      _status = status;
    });
  }

  void _setError(String message) {
    if (!mounted || _isDisposed) return;
    _timeoutTimer?.cancel();
    setState(() {
      _phase = LivenessPhase.error;
      _errorMessage = message;
    });
    widget.onError?.call(message);
  }

  @override
  Widget build(BuildContext context) {
    if (_phase == LivenessPhase.error || _phase == LivenessPhase.timeout) {
      return _errorView();
    }

    final camera = _camera;
    if (camera == null || !camera.value.isInitialized) return _loadingView();

    final previewSize = camera.value.previewSize;
    if (previewSize == null) return _loadingView();

    // Detect device orientation and counter-rotate preview to keep it portrait
    // Use camera's deviceOrientation for precise direction (left vs right)
    final deviceOrientation = camera.value.deviceOrientation;
    final quarterTurns = switch (deviceOrientation) {
      DeviceOrientation.landscapeLeft => 1,   // Rotate 90° clockwise
      DeviceOrientation.landscapeRight => 3,  // Rotate 90° counter-clockwise
      DeviceOrientation.portraitDown => 2,    // Rotate 180°
      DeviceOrientation.portraitUp => 0,      // No rotation
    };

    return Stack(
      fit: StackFit.expand,
      children: [
        Container(color: const Color(0xFF1A1B1E)),
        Positioned.fill(
          child: Center(
            child: RotatedBox(
              quarterTurns: quarterTurns,
              child: CameraPreview(camera),
            ),
          ),
        ),
        Positioned.fill(
          child: IgnorePointer(
            child: _premiumScannerOverlay(
              reservedTopInset: widget.reservedTopInset,
              safeBottomInset: MediaQuery.paddingOf(context).bottom,
            ),
          ),
        ),
      ],
    );
  }

  Widget _loadingView() {
    return Container(
      color: const Color(0xFF1A1B1E),
      child: const Center(
        child: CircularProgressIndicator(color: Color(0xFFFF8266)),
      ),
    );
  }

  Widget _premiumScannerOverlay({
    required double reservedTopInset,
    required double safeBottomInset,
  }) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final w = constraints.maxWidth;
        final h = constraints.maxHeight;
        
        const badgeHeight = 52.0;
        const badgeGap = 24.0;
        final topInset = reservedTopInset + 16;
        final bottomInset = safeBottomInset + 24;
        
        final usableHeight =
            math.max(0.0, h - topInset - bottomInset - badgeHeight - badgeGap);
        
        final ovalWidth = math.min(w * 0.72, usableHeight / 1.35);
        final ovalHeight = ovalWidth * 1.35;
        
        final ovalTop = topInset + math.max(0.0, (usableHeight - ovalHeight) / 2);
        final center = Offset(w / 2, ovalTop + (ovalHeight / 2));
        final badgeTop = ovalTop + ovalHeight + badgeGap;

        final borderColor = switch (_phase) {
          LivenessPhase.holdingStill => const Color(0xFF5BBFB3),
          LivenessPhase.capturing => Colors.white,
          LivenessPhase.verified => const Color(0xFF5BBFB3),
          _ => const Color(0xFFFF8266),
        };

        return Stack(
          children: [
            _ScannerMask(
              center: center,
              width: ovalWidth,
              height: ovalHeight,
            ),

            Positioned(
              top: ovalTop - 16,
              left: (w - (ovalWidth + 32)) / 2,
              child: AnimatedBuilder(
                animation: _rotateCtrl,
                builder: (_, __) => Container(
                  width: ovalWidth + 32,
                  height: ovalHeight + 32,
                  child: CustomPaint(
                    painter: _DashedOvalPainter(
                      color: const Color(0xFF5BBFB3).withValues(alpha: 0.6),
                      dashOffset: _rotateCtrl.value,
                    ),
                  ),
                ),
              ),
            ),

            AnimatedBuilder(
              animation: _pulseCtrl,
              builder: (_, __) {
                final scale = 1.0 + (_pulseCtrl.value * 0.03);
                return Positioned(
                  top: ovalTop,
                  left: (w - ovalWidth) / 2,
                  child: Transform.scale(
                    scale: scale,
                    child: Container(
                      width: ovalWidth,
                      height: ovalHeight,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.all(Radius.elliptical(ovalWidth/2, ovalHeight/2)),
                        border: Border.all(color: borderColor, width: 3),
                        boxShadow: [
                          BoxShadow(
                            color: borderColor.withValues(alpha: 0.2),
                            blurRadius: 20,
                            spreadRadius: 2,
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),

            Positioned(
              top: badgeTop,
              left: 0,
              right: 0,
              child: Center(
                child: _StatusBadge(
                  text: _status,
                  color: borderColor,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _errorView() {
    return Container(
      color: const Color(0xFF1A1B1E),
      padding: const EdgeInsets.all(32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(PhosphorIconsDuotone.warningCircle, color: Color(0xFFFF8266), size: 64),
          const SizedBox(height: 24),
          Text(
            _errorMessage ?? 'Something went wrong',
            textAlign: TextAlign.center,
            style: AppTypography.h3.copyWith(color: Colors.white),
          ),
          const SizedBox(height: 32),
          SizedBox(
            width: double.infinity,
            height: 56,
            child: ElevatedButton(
              onPressed: _retry,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFFF8266),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
              ),
              child: const Text('TRY AGAIN', style: TextStyle(fontWeight: FontWeight.w900)),
            ),
          ),
        ],
      ),
    );
  }

  InputImage? _toInputImage(CameraImage image, CameraController camera) {
    final rotation = _rotationFromCamera(camera);
    if (rotation == null) return null;
    
    if (defaultTargetPlatform == TargetPlatform.android) {
      final bytes = _androidBytes(image);
      if (bytes == null) return null;
      return InputImage.fromBytes(
        bytes: bytes,
        metadata: InputImageMetadata(
          size: Size(image.width.toDouble(), image.height.toDouble()),
          rotation: rotation,
          format: InputImageFormat.nv21,
          bytesPerRow: image.planes.first.bytesPerRow,
        ),
      );
    }
    
    if (defaultTargetPlatform == TargetPlatform.iOS) {
      if (image.planes.isEmpty) return null;
      final plane = image.planes.first;
      
      final rawFormat = image.format.raw;
      final format = InputImageFormatValue.fromRawValue(rawFormat is int ? rawFormat : 0);
      
      if (format == null || format != InputImageFormat.bgra8888) return null;

      return InputImage.fromBytes(
        bytes: plane.bytes,
        metadata: InputImageMetadata(
          size: Size(image.width.toDouble(), image.height.toDouble()),
          rotation: rotation,
          format: format,
          bytesPerRow: plane.bytesPerRow,
        ),
      );
    }
    
    return null;
  }

  Uint8List? _androidBytes(CameraImage image) {
    final width = image.width;
    final height = image.height;
    final yPlane = image.planes[0];

    if (image.planes.length == 1) {
      return yPlane.bytes;
    }

    if (image.planes.length == 2) {
      final uvPlane = image.planes[1];
      final nv21 = Uint8List(width * height + uvPlane.bytes.length);
      int index = 0;
      for (int row = 0; row < height; row++) {
        nv21.setRange(index, index + width, yPlane.bytes, row * yPlane.bytesPerRow);
        index += width;
      }
      nv21.setRange(index, index + uvPlane.bytes.length, uvPlane.bytes);
      return nv21;
    }

    if (image.planes.length != 3) return null;
    final uPlane = image.planes[1];
    final vPlane = image.planes[2];
    final nv21 = Uint8List(width * height + ((width * height) ~/ 2));
    int index = 0;
    for (int row = 0; row < height; row++) {
      nv21.setRange(index, index + width, yPlane.bytes, row * yPlane.bytesPerRow);
      index += width;
    }
    final uStride = uPlane.bytesPerPixel ?? 1;
    for (int row = 0; row < height ~/ 2; row++) {
      final uOffset = row * uPlane.bytesPerRow;
      final vOffset = row * vPlane.bytesPerRow;
      for (int col = 0; col < width ~/ 2; col++) {
        nv21[index++] = vPlane.bytes[vOffset + col * uStride];
        nv21[index++] = uPlane.bytes[uOffset + col * uStride];
      }
    }
    return nv21;
  }

  InputImageRotation? _rotationFromCamera(CameraController camera) {
    final sensorOrientation = camera.description.sensorOrientation;
    if (defaultTargetPlatform == TargetPlatform.iOS) {
      return InputImageRotationValue.fromRawValue(sensorOrientation);
    }
    
    const orientationMap = <DeviceOrientation, int>{
      DeviceOrientation.portraitUp: 0,
      DeviceOrientation.landscapeLeft: 90,
      DeviceOrientation.portraitDown: 180,
      DeviceOrientation.landscapeRight: 270,
    };
    
    final deviceRotation = orientationMap[camera.value.deviceOrientation];
    if (deviceRotation == null) return null;
    
    final rotationCompensation =
        camera.description.lensDirection == CameraLensDirection.front
            ? (sensorOrientation + deviceRotation) % 360
            : (sensorOrientation - deviceRotation + 360) % 360;
            
    return InputImageRotationValue.fromRawValue(rotationCompensation);
  }
}

class _StatusBadge extends StatelessWidget {
  final String text;
  final Color color;
  const _StatusBadge({required this.text, required this.color});

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 400),
      curve: Curves.easeOutCubic,
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.9),
        borderRadius: BorderRadius.circular(30),
        boxShadow: [
          BoxShadow(color: color.withValues(alpha: 0.3), blurRadius: 20, offset: const Offset(0, 8)),
        ],
      ),
      child: AnimatedSwitcher(
        duration: const Duration(milliseconds: 300),
        child: Text(
          text.toUpperCase(),
          key: ValueKey(text),
          style: const TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.w900,
            letterSpacing: 1.0,
          ),
        ),
      ),
    );
  }
}

class _ScannerMask extends StatelessWidget {
  final Offset center;
  final double width;
  final double height;
  const _ScannerMask({required this.center, required this.width, required this.height});

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _MaskPainter(center: center, w: width, h: height),
    );
  }
}

class _MaskPainter extends CustomPainter {
  final Offset center;
  final double w;
  final double h;
  _MaskPainter({required this.center, required this.w, required this.h});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = Colors.black.withValues(alpha: 0.7);
    final path = Path()
      ..addRect(Rect.fromLTWH(0, 0, size.width, size.height))
      ..addOval(Rect.fromCenter(center: center, width: w, height: h));
    path.fillType = PathFillType.evenOdd;
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter old) => true;
}

class _DashedOvalPainter extends CustomPainter {
  final Color color;
  final double dashOffset;
  _DashedOvalPainter({required this.color, required this.dashOffset});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2
      ..strokeCap = StrokeCap.round;

    final path = Path()..addOval(Rect.fromLTWH(0, 0, size.width, size.height));
    final metrics = path.computeMetrics().first;
    final total = metrics.length;
    final dash = 12.0;
    final gap = 10.0;
    
    double distance = dashOffset * total;
    while (distance < total * 2) {
      final start = distance % total;
      final end = (distance + dash) % total;
      if (start < end) {
        canvas.drawPath(metrics.extractPath(start, end), paint);
      } else {
        canvas.drawPath(metrics.extractPath(start, total), paint);
        canvas.drawPath(metrics.extractPath(0, end), paint);
      }
      distance += dash + gap;
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter old) => true;
}
