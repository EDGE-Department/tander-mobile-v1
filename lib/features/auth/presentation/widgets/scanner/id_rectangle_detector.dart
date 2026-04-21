import 'dart:math' as math;
import 'dart:typed_data';

import 'package:camera/camera.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';

/// Result of text-based ID detection on a camera frame.
class IdDetectionResult {
  /// Whether text resembling an ID card was found.
  final bool detected;

  /// Confidence score 0.0-1.0.
  final double confidence;

  /// Number of text blocks found.
  final int textBlockCount;

  /// Total character count.
  final int charCount;

  const IdDetectionResult({
    required this.detected,
    required this.confidence,
    this.textBlockCount = 0,
    this.charCount = 0,
  });

  static const notFound = IdDetectionResult(
    detected: false,
    confidence: 0.0,
  );
}

/// Text-based ID card detector using Google ML Kit.
///
/// Runs ML Kit text recognition on camera frames to detect whether an ID
/// card is present. Does NOT return exact bounding boxes (which are too
/// unstable for smooth tracking). Instead returns a detection confidence
/// that the scanner UI uses to animate a guide frame.
class IdRectangleDetector {
  final TextRecognizer _recognizer = TextRecognizer();
  bool _isProcessing = false;

  /// Minimum text blocks to consider it might be an ID.
  static const _minTextBlocks = 1;

  /// Minimum characters for confident detection.
  static const _minCharsForDetection = 5;

  /// Keywords that indicate a Philippine government ID.
  static const _idKeywords = [
    'republic', 'philippines', 'pilipinas', 'name', 'pangalan',
    'date', 'birth', 'kapanganakan', 'address', 'tirahan',
    'sex', 'kasarian', 'nationality', 'valid', 'expiry',
    'id', 'number', 'issued', 'signature', 'driver',
    'license', 'senior', 'citizen', 'sss', 'umid',
    'passport', 'postal', 'voter', 'philhealth', 'pagibig',
    'philsys', 'national', 'osca', 'pwd',
  ];

  void dispose() => _recognizer.close();

  /// Detect whether an ID card is in the camera frame.
  ///
  /// Tries all image orientations and returns the best result.
  Future<IdDetectionResult> detectAsync(
    CameraImage image,
    CameraController camera,
  ) async {
    if (_isProcessing) return IdDetectionResult.notFound;
    _isProcessing = true;

    try {
      IdDetectionResult bestResult = IdDetectionResult.notFound;

      // Try all orientations and keep best result
      for (final rotation in InputImageRotation.values) {
        final result = await _tryDetectWithRotation(image, camera, rotation);
        if (result.confidence > bestResult.confidence) {
          bestResult = result;
        }
      }

      return bestResult;
    } catch (_) {
      return IdDetectionResult.notFound;
    } finally {
      _isProcessing = false;
    }
  }

  Future<IdDetectionResult> _tryDetectWithRotation(
    CameraImage image,
    CameraController camera,
    InputImageRotation rotation,
  ) async {
    final inputImage = _toInputImageWithRotation(image, camera, rotation);
    if (inputImage == null) return IdDetectionResult.notFound;

    final recognized = await _recognizer.processImage(inputImage);
    if (recognized.blocks.isEmpty) return IdDetectionResult.notFound;

    final blockCount = recognized.blocks.length;
    final fullText = recognized.blocks.map((b) => b.text).join(' ');
    final charCount = fullText.length;

    if (blockCount < _minTextBlocks || charCount < _minCharsForDetection) {
      return IdDetectionResult.notFound;
    }

    final lowerText = fullText.toLowerCase();
    int keywordMatches = 0;
    for (final kw in _idKeywords) {
      if (lowerText.contains(kw)) keywordMatches++;
    }

    final densityScore = (blockCount / 6.0).clamp(0.0, 1.0);
    final charScore = (charCount / 60.0).clamp(0.0, 1.0);
    final keywordScore = (keywordMatches / 4.0).clamp(0.0, 1.0);

    final confidence =
        keywordScore * 0.50 + densityScore * 0.25 + charScore * 0.25;

    final isDetected = confidence >= 0.15 || keywordMatches >= 1;

    return IdDetectionResult(
      detected: isDetected,
      confidence: confidence,
      textBlockCount: blockCount,
      charCount: charCount,
    );
  }

  /// Quick brightness check.
  bool hasSufficientBrightness(CameraImage image) {
    final yPlane = image.planes.first.bytes;
    if (yPlane.isEmpty) return false;
    const sampleCount = 60;
    final step = math.max(1, yPlane.length ~/ sampleCount);
    int sum = 0;
    for (int i = 0; i < sampleCount; i++) {
      final index = i * step;
      if (index < yPlane.length) sum += yPlane[index];
    }
    final avg = sum / sampleCount;
    return avg >= 35 && avg <= 245;
  }

  // ---------------------------------------------------------------------------
  // CameraImage → InputImage
  // ---------------------------------------------------------------------------

  InputImage? _toInputImage(CameraImage image, CameraController camera) {
    final rotation = _rotationFromCamera(camera);
    if (rotation == null) return null;

    if (defaultTargetPlatform == TargetPlatform.android) {
      final bytes = _androidBytes(image);
      if (bytes == null) return null;
      final bytesPerRow = image.planes.isNotEmpty
          ? image.planes.first.bytesPerRow
          : image.width;

      return InputImage.fromBytes(
        bytes: bytes,
        metadata: InputImageMetadata(
          size: Size(image.width.toDouble(), image.height.toDouble()),
          rotation: rotation,
          format: InputImageFormat.nv21,
          bytesPerRow: bytesPerRow,
        ),
      );
    }

    final rawFormat = image.format.raw;
    final format =
        InputImageFormatValue.fromRawValue(rawFormat is int ? rawFormat : 0);
    if (format == null || image.planes.isEmpty) return null;

    return InputImage.fromBytes(
      bytes: image.planes.first.bytes,
      metadata: InputImageMetadata(
        size: Size(image.width.toDouble(), image.height.toDouble()),
        rotation: rotation,
        format: format,
        bytesPerRow: image.planes.first.bytesPerRow,
      ),
    );
  }

  InputImage? _toInputImageWithRotation(
    CameraImage image,
    CameraController camera,
    InputImageRotation rotation,
  ) {
    if (defaultTargetPlatform == TargetPlatform.android) {
      final bytes = _androidBytes(image);
      if (bytes == null) return null;
      final bytesPerRow = image.planes.isNotEmpty
          ? image.planes.first.bytesPerRow
          : image.width;

      return InputImage.fromBytes(
        bytes: bytes,
        metadata: InputImageMetadata(
          size: Size(image.width.toDouble(), image.height.toDouble()),
          rotation: rotation,
          format: InputImageFormat.nv21,
          bytesPerRow: bytesPerRow,
        ),
      );
    }

    final rawFormat = image.format.raw;
    final format =
        InputImageFormatValue.fromRawValue(rawFormat is int ? rawFormat : 0);
    if (format == null || image.planes.isEmpty) return null;

    return InputImage.fromBytes(
      bytes: image.planes.first.bytes,
      metadata: InputImageMetadata(
        size: Size(image.width.toDouble(), image.height.toDouble()),
        rotation: rotation,
        format: format,
        bytesPerRow: image.planes.first.bytesPerRow,
      ),
    );
  }

  Uint8List? _androidBytes(CameraImage image) {
    final rawFormat = image.format.raw;
    final format =
        InputImageFormatValue.fromRawValue(rawFormat is int ? rawFormat : 0);
    if (format == InputImageFormat.nv21 && image.planes.isNotEmpty) {
      return image.planes.first.bytes;
    }

    if (image.planes.length != 3) return null;
    final width = image.width;
    final height = image.height;
    final yPlane = image.planes[0];
    final uPlane = image.planes[1];
    final vPlane = image.planes[2];

    final nv21 = Uint8List(width * height + ((width * height) ~/ 2));
    int index = 0;

    for (int row = 0; row < height; row++) {
      final rowOffset = row * yPlane.bytesPerRow;
      nv21.setRange(index, index + width, yPlane.bytes, rowOffset);
      index += width;
    }

    final uPixelStride = uPlane.bytesPerPixel ?? 1;
    final vPixelStride = vPlane.bytesPerPixel ?? 1;
    for (int row = 0; row < height ~/ 2; row++) {
      final uRowOffset = row * uPlane.bytesPerRow;
      final vRowOffset = row * vPlane.bytesPerRow;
      for (int col = 0; col < width ~/ 2; col++) {
        nv21[index++] = vPlane.bytes[vRowOffset + (col * vPixelStride)];
        nv21[index++] = uPlane.bytes[uRowOffset + (col * uPixelStride)];
      }
    }

    return nv21;
  }

  InputImageRotation? _rotationFromCamera(CameraController camera) {
    final sensorOrientation = camera.description.sensorOrientation;
    if (defaultTargetPlatform == TargetPlatform.iOS) {
      return InputImageRotationValue.fromRawValue(sensorOrientation);
    }

    final deviceOrientation = camera.value.deviceOrientation;
    final orientationMap = <DeviceOrientation, int>{
      DeviceOrientation.portraitUp: 0,
      DeviceOrientation.landscapeLeft: 90,
      DeviceOrientation.portraitDown: 180,
      DeviceOrientation.landscapeRight: 270,
    };

    int? rotationCompensation = orientationMap[deviceOrientation];
    if (rotationCompensation == null) return null;

    if (camera.description.lensDirection == CameraLensDirection.front) {
      rotationCompensation = (sensorOrientation + rotationCompensation) % 360;
    } else {
      rotationCompensation = (sensorOrientation - rotationCompensation + 360) % 360;
    }

    return InputImageRotationValue.fromRawValue(rotationCompensation);
  }
}
