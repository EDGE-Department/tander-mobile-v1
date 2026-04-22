import 'dart:async';
import 'dart:io';
import 'dart:math';
import 'dart:typed_data';
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';
import 'package:permission_handler/permission_handler.dart';
import '../states/liveness_state.dart';

class LivenessNotifier extends StateNotifier<LivenessState> {
  LivenessNotifier() : super(const LivenessState.initial());

  CameraController? _cameraController;
  FaceDetector? _faceDetector;
  bool _isProcessing = false;
  Timer? _stabilityTimer;
  int _stableFrames = 0;
  static const int _requiredStableFrames = 8; // Roughly 0.8 seconds at 10 FPS - faster capture
  DateTime? _lastFrameTime;
  
  // Throttle frame processing for older devices
  int _minFrameIntervalMs = 100; // 10 FPS target for mid-range

  // Convert YUV420 camera image to NV21 format for ML Kit
  Uint8List _convertYUV420toNV21(CameraImage image) {
    final int width = image.width;
    final int height = image.height;
    final int ySize = width * height;
    final int uvSize = width * height ~/ 2;

    final Uint8List nv21 = Uint8List(ySize + uvSize);

    // Copy Y plane
    final yPlane = image.planes[0];
    final yBuffer = yPlane.bytes;
    int yIndex = 0;
    final int yRowStride = yPlane.bytesPerRow;
    for (int y = 0; y < height; y++) {
      for (int x = 0; x < width; x++) {
        nv21[yIndex++] = yBuffer[y * yRowStride + x];
      }
    }

    // Interleave V and U planes into NV21 format (VU order)
    final uPlane = image.planes[1];
    final vPlane = image.planes[2];
    final uBuffer = uPlane.bytes;
    final vBuffer = vPlane.bytes;
    final int uvRowStride = uPlane.bytesPerRow;

    int uvIndex = ySize;
    final int uvWidth = width ~/ 2;
    final int uvHeight = height ~/ 2;

    for (int y = 0; y < uvHeight; y++) {
      for (int x = 0; x < uvWidth; x++) {
        // UV planes are typically interleaved or have pixel stride of 2
        final int uvOffset = y * uvRowStride + x * 2;
        if (uvOffset < vBuffer.length) {
          nv21[uvIndex++] = vBuffer[uvOffset]; // V first (NV21)
        } else {
          nv21[uvIndex++] = 128;
        }
        if (uvOffset < uBuffer.length) {
          nv21[uvIndex++] = uBuffer[uvOffset]; // then U
        } else {
          nv21[uvIndex++] = 128;
        }
      }
    }

    return nv21;
  }

  Future<void> initializeCamera(Orientation currentOrientation) async {
    // Clean up any existing camera first
    await _cleanupCamera();

    state = const LivenessState.initializing();

    // Request camera permission
    try {
      final status = await Permission.camera.request();
      if (!status.isGranted) {
        state = LivenessState.error(
          message: status.isPermanentlyDenied
              ? 'Camera permission denied. Enable in Settings.'
              : 'Camera permission required.',
        );
        return;
      }
    } catch (e) {
      state = const LivenessState.error(message: 'Permission check failed');
      return;
    }

    // Get cameras with retry
    List<CameraDescription> cameras = [];
    for (int attempt = 0; attempt < 3; attempt++) {
      try {
        cameras = await availableCameras();
        if (cameras.isNotEmpty) break;
        await Future.delayed(const Duration(milliseconds: 500));
      } catch (e) {
        if (attempt == 2) {
          state = const LivenessState.error(message: 'Cannot access camera');
          return;
        }
        await Future.delayed(const Duration(milliseconds: 500));
      }
    }

    if (cameras.isEmpty) {
      state = const LivenessState.error(message: 'No camera found');
      return;
    }

    final frontCamera = cameras.firstWhere(
      (c) => c.lensDirection == CameraLensDirection.front,
      orElse: () => cameras.first,
    );

    // Initialize camera with retry
    for (int attempt = 0; attempt < 2; attempt++) {
      try {
        _cameraController = CameraController(
          frontCamera,
          ResolutionPreset.medium,
          enableAudio: false,
          imageFormatGroup: Platform.isIOS ? ImageFormatGroup.bgra8888 : ImageFormatGroup.yuv420,
        );

        await _cameraController!.initialize();
        break;
      } catch (e) {
        await _cameraController?.dispose();
        _cameraController = null;

        if (attempt == 1) {
          state = LivenessState.error(message: 'Camera init failed: ${e.toString().split('.').last}');
          return;
        }
        await Future.delayed(const Duration(milliseconds: 800));
      }
    }

    if (_cameraController == null || !_cameraController!.value.isInitialized) {
      state = const LivenessState.error(message: 'Camera not ready');
      return;
    }

    // Allow all orientations - don't lock

    _faceDetector = FaceDetector(
      options: FaceDetectorOptions(
        enableContours: false,
        enableClassification: true,
        enableLandmarks: false,
        enableTracking: false,
        performanceMode: FaceDetectorMode.fast,
      ),
    );

    state = LivenessState.ready(
      cameraController: _cameraController!,
      instruction: 'Position your face in the oval',
    );

    _startImageStream();
  }

  Future<void> _cleanupCamera() async {
    try {
      if (_cameraController != null) {
        if (_cameraController!.value.isStreamingImages) {
          await _cameraController!.stopImageStream();
        }
        await _cameraController!.dispose();
        _cameraController = null;
      }
    } catch (_) {}
  }

  void _startImageStream() {
    _cameraController?.startImageStream((image) {
      if (_isProcessing) return;
      
      final now = DateTime.now();
      if (_lastFrameTime != null && now.difference(_lastFrameTime!).inMilliseconds < _minFrameIntervalMs) {
        return; // Throttle frames
      }
      _lastFrameTime = now;
      
      _processImage(image);
    });
  }

  Future<void> _processImage(CameraImage image) async {
    _isProcessing = true;
    try {
      final readyState = state.mapOrNull(ready: (s) => s);
      if (readyState == null || readyState.isCapturing) return;

      final camera = _cameraController!.description;
      final sensorOrientation = camera.sensorOrientation;

      // Calculate rotation
      InputImageRotation imageRotation;
      if (Platform.isIOS) {
        imageRotation = InputImageRotationValue.fromRawValue(sensorOrientation) ?? InputImageRotation.rotation0deg;
      } else {
        // For Android front camera
        imageRotation = InputImageRotationValue.fromRawValue(sensorOrientation) ?? InputImageRotation.rotation270deg;
      }

      InputImage inputImage;

      if (Platform.isAndroid) {
        // Convert YUV420 to NV21 format for ML Kit
        final nv21Bytes = _convertYUV420toNV21(image);
        final inputImageData = InputImageMetadata(
          size: Size(image.width.toDouble(), image.height.toDouble()),
          rotation: imageRotation,
          format: InputImageFormat.nv21,
          bytesPerRow: image.width,
        );
        inputImage = InputImage.fromBytes(bytes: nv21Bytes, metadata: inputImageData);
      } else {
        // iOS uses BGRA8888
        final WriteBuffer allBytes = WriteBuffer();
        for (final Plane plane in image.planes) {
          allBytes.putUint8List(plane.bytes);
        }
        final inputImageData = InputImageMetadata(
          size: Size(image.width.toDouble(), image.height.toDouble()),
          rotation: imageRotation,
          format: InputImageFormat.bgra8888,
          bytesPerRow: image.planes[0].bytesPerRow,
        );
        inputImage = InputImage.fromBytes(bytes: allBytes.done().buffer.asUint8List(), metadata: inputImageData);
      }

      final faces = await _faceDetector!.processImage(inputImage);
      final Size imageSize = Size(image.width.toDouble(), image.height.toDouble());

      if (faces.isEmpty) {
        _resetStability();
        state = readyState.copyWith(
          isFaceDetected: false,
          isFaceCentered: false,
          instruction: 'No face detected',
          stabilityScore: 0.0,
        );
      } else {
        final face = faces.first;
        final bool isCentered = _checkIfFaceCentered(face.boundingBox, imageSize);
        // Less strict eye detection - 0.3 threshold (was 0.5), also accept if glasses block detection
        final leftEye = face.leftEyeOpenProbability ?? 1.0; // Default to open if not detected
        final rightEye = face.rightEyeOpenProbability ?? 1.0;
        final bool isOpenEyes = leftEye > 0.3 && rightEye > 0.3;

        // Just need face centered - eye check is optional now
        if (isCentered) {
          _stableFrames++;
          final score = min(1.0, _stableFrames.toDouble() / _requiredStableFrames.toDouble());

          if (_stableFrames >= _requiredStableFrames) {
            // First show 100% progress, then capture after a short delay
            state = readyState.copyWith(
              isFaceDetected: true,
              isFaceCentered: true,
              instruction: 'Perfect!',
              stabilityScore: 1.0,
            );
            // Small delay so user sees the completed bar
            await Future.delayed(const Duration(milliseconds: 400));
            await _captureImage();
          } else {
            state = readyState.copyWith(
              isFaceDetected: true,
              isFaceCentered: true,
              instruction: 'Hold still...',
              stabilityScore: score,
            );
          }
        } else {
          _resetStability();
          state = readyState.copyWith(
            isFaceDetected: true,
            isFaceCentered: false,
            instruction: isCentered ? 'Keep your eyes open' : 'Center your face',
            stabilityScore: 0.0,
          );
        }
      }
    } catch (e) {
      // Ignore errors during frame processing to prevent crashes
    } finally {
      _isProcessing = false;
    }
  }

  bool _checkIfFaceCentered(Rect boundingBox, Size imageSize) {
    // More lenient - face just needs to be 15% of image width (was 25%)
    final minFaceSize = imageSize.width * 0.15;
    if (boundingBox.width < minFaceSize || boundingBox.height < minFaceSize) {
      return false;
    }

    final center = boundingBox.center;
    final imageCenter = Offset(imageSize.width / 2, imageSize.height / 2);
    final distance = (center - imageCenter).distance;
    // More lenient - allow 35% offset from center (was 20%)
    return distance < imageSize.width * 0.35;
  }

  void _resetStability() {
    _stableFrames = 0;
  }

  Future<void> _captureImage() async {
    final readyState = state.mapOrNull(ready: (s) => s);
    if (readyState == null) return;

    state = readyState.copyWith(isCapturing: true, instruction: 'Capturing...');
    await _cameraController?.stopImageStream();
    
    try {
      final XFile file = await _cameraController!.takePicture();
      state = LivenessState.success(imagePath: file.path);
    } catch (e) {
      state = LivenessState.error(message: 'Failed to capture image');
    }
  }

  void pauseDetection() {
    _cameraController?.stopImageStream();
  }
  
  void resumeDetection() {
    if (_cameraController != null && !_cameraController!.value.isStreamingImages) {
      _startImageStream();
    }
  }

  @override
  void dispose() {
    _cleanupCamera();
    _faceDetector?.close();
    super.dispose();
  }
}

final livenessNotifierProvider = StateNotifierProvider<LivenessNotifier, LivenessState>((ref) {
  return LivenessNotifier();
});
