import 'dart:async';
import 'dart:math';
import 'dart:typed_data';
import 'package:camera/camera.dart';
import 'package:opencv_dart/opencv_dart.dart' as cv;

class DetectedEdge {
  final Point<double> topLeft;
  final Point<double> topRight;
  final Point<double> bottomLeft;
  final Point<double> bottomRight;
  final double confidence;

  DetectedEdge({
    required this.topLeft,
    required this.topRight,
    required this.bottomLeft,
    required this.bottomRight,
    this.confidence = 0.0,
  });
}

class DocumentEdgeDetector {
  bool _isProcessing = false;
  int _frameCount = 0;
  final int _throttleFrames;

  DocumentEdgeDetector({int throttleFrames = 2}) : _throttleFrames = throttleFrames;

  final double _smoothing = 0.25;
  DetectedEdge? _smoothedEdge;
  int _noDetectionFrames = 0;

  Future<DetectedEdge?> processImage(CameraImage image) async {
    _frameCount++;
    if (_isProcessing || _frameCount % _throttleFrames != 0) {
      return _smoothedEdge;
    }

    _isProcessing = true;
    try {
      final result = await _detectDocument(image);

      if (result == null) {
        _noDetectionFrames++;
        if (_noDetectionFrames > 6) {
          _smoothedEdge = null;
        }
        return _smoothedEdge;
      }

      _noDetectionFrames = 0;

      if (_smoothedEdge == null) {
        _smoothedEdge = result;
      } else {
        _smoothedEdge = DetectedEdge(
          topLeft: _lerp(_smoothedEdge!.topLeft, result.topLeft, _smoothing),
          topRight: _lerp(_smoothedEdge!.topRight, result.topRight, _smoothing),
          bottomLeft: _lerp(_smoothedEdge!.bottomLeft, result.bottomLeft, _smoothing),
          bottomRight: _lerp(_smoothedEdge!.bottomRight, result.bottomRight, _smoothing),
          confidence: result.confidence,
        );
      }
      return _smoothedEdge;
    } catch (e) {
      return _smoothedEdge;
    } finally {
      _isProcessing = false;
    }
  }

  Future<DetectedEdge?> _detectDocument(CameraImage image) async {
    final int origWidth = image.width;
    final int origHeight = image.height;

    final Uint8List yPlane = image.planes[0].bytes;
    final int rowStride = image.planes[0].bytesPerRow;

    final Uint8List grayData = Uint8List(origWidth * origHeight);
    for (int y = 0; y < origHeight; y++) {
      for (int x = 0; x < origWidth; x++) {
        grayData[y * origWidth + x] = yPlane[y * rowStride + x];
      }
    }

    final gray = cv.Mat.fromList(origHeight, origWidth, cv.MatType.CV_8UC1, grayData);

    // Use higher resolution for better detection
    final double scale = 600.0 / max(origWidth, origHeight);
    final int newWidth = (origWidth * scale).round();
    final int newHeight = (origHeight * scale).round();
    final resized = cv.resize(gray, (newWidth, newHeight));
    gray.dispose();

    // Apply CLAHE for contrast enhancement (helps with varying lighting)
    final clahe = cv.createCLAHE(clipLimit: 2.0, tileGridSize: (8, 8));
    final enhanced = clahe.apply(resized);
    resized.dispose();

    // Try multiple detection approaches
    DetectedEdge? result;

    // Method 1: Enhanced + Gaussian blur + Canny
    result = _detectMethod1(enhanced, scale, origWidth, origHeight);
    if (result != null) {
      enhanced.dispose();
      return result;
    }

    // Method 2: Enhanced + bilateral + adaptive threshold
    result = _detectMethod2(enhanced, scale, origWidth, origHeight);
    if (result != null) {
      enhanced.dispose();
      return result;
    }

    // Method 3: Otsu thresholding
    result = _detectMethod3(enhanced, scale, origWidth, origHeight);
    enhanced.dispose();

    return result;
  }

  DetectedEdge? _detectMethod1(cv.Mat enhanced, double scale, int origWidth, int origHeight) {
    final blurred = cv.gaussianBlur(enhanced, (5, 5), 0);
    final edges = cv.canny(blurred, 30, 90);
    blurred.dispose();

    final kernel = cv.getStructuringElement(cv.MORPH_RECT, (3, 3));
    final dilated = cv.dilate(edges, kernel);
    edges.dispose();
    kernel.dispose();

    final result = _findBestQuad(dilated, scale, origWidth, origHeight);
    dilated.dispose();
    return result;
  }

  DetectedEdge? _detectMethod2(cv.Mat enhanced, double scale, int origWidth, int origHeight) {
    final blurred = cv.bilateralFilter(enhanced, 9, 75, 75);
    final thresh = cv.adaptiveThreshold(
      blurred, 255, cv.ADAPTIVE_THRESH_GAUSSIAN_C, cv.THRESH_BINARY, 15, 5,
    );
    blurred.dispose();

    final kernel = cv.getStructuringElement(cv.MORPH_RECT, (5, 5));
    final morphed = cv.morphologyEx(thresh, cv.MORPH_CLOSE, kernel);
    thresh.dispose();

    final edges = cv.canny(morphed, 50, 150);
    morphed.dispose();

    final dilated = cv.dilate(edges, kernel);
    edges.dispose();
    kernel.dispose();

    final result = _findBestQuad(dilated, scale, origWidth, origHeight);
    dilated.dispose();
    return result;
  }

  DetectedEdge? _detectMethod3(cv.Mat enhanced, double scale, int origWidth, int origHeight) {
    final blurred = cv.gaussianBlur(enhanced, (5, 5), 0);

    // Otsu's thresholding - automatically finds optimal threshold
    final thresh = cv.threshold(blurred, 0, 255, cv.THRESH_BINARY + cv.THRESH_OTSU);
    blurred.dispose();

    final kernel = cv.getStructuringElement(cv.MORPH_RECT, (7, 7));
    final morphed = cv.morphologyEx(thresh.$2, cv.MORPH_CLOSE, kernel);
    thresh.$2.dispose();

    final inverted = cv.bitwiseNOT(morphed);
    morphed.dispose();

    final result = _findBestQuad(inverted, scale, origWidth, origHeight);
    inverted.dispose();
    kernel.dispose();
    return result;
  }

  DetectedEdge? _findBestQuad(cv.Mat binary, double scale, int origWidth, int origHeight) {
    final result = cv.findContours(binary, cv.RETR_LIST, cv.CHAIN_APPROX_SIMPLE);
    final contours = result.$1;

    if (contours.isEmpty) return null;

    final imageArea = binary.rows * binary.cols;
    final minArea = imageArea * 0.08;
    final maxArea = imageArea * 0.90;

    // Score all valid quadrilaterals
    List<(DetectedEdge, double)> candidates = [];

    for (final contour in contours) {
      final area = cv.contourArea(contour);
      if (area < minArea || area > maxArea) continue;

      final peri = cv.arcLength(contour, true);

      for (final eps in [0.015, 0.02, 0.025, 0.03, 0.04, 0.05, 0.06, 0.08]) {
        final approx = cv.approxPolyDP(contour, eps * peri, true);

        if (approx.length == 4 && cv.isContourConvex(approx)) {
          final quad = _validateAndExtract(approx, scale, origWidth, origHeight, binary.cols, binary.rows);
          if (quad != null) {
            // Score based on area (prefer larger), aspect ratio closeness to 1.586
            final w = ((quad.topRight.x - quad.topLeft.x) + (quad.bottomRight.x - quad.bottomLeft.x)) / 2;
            final h = ((quad.bottomLeft.y - quad.topLeft.y) + (quad.bottomRight.y - quad.topRight.y)) / 2;
            final aspect = w / h;
            final aspectScore = 1.0 - (aspect - 1.586).abs() / 1.586;
            final areaScore = area / maxArea;
            final score = aspectScore * 0.6 + areaScore * 0.4;
            candidates.add((quad, score));
          }
        }
      }
    }

    if (candidates.isEmpty) return null;

    // Return highest scoring candidate
    candidates.sort((a, b) => b.$2.compareTo(a.$2));
    return candidates.first.$1;
  }

  DetectedEdge? _validateAndExtract(cv.VecPoint approx, double scale, int origWidth, int origHeight, int procWidth, int procHeight) {
    if (approx.length != 4) return null;

    final points = <Point<double>>[];
    for (int i = 0; i < 4; i++) {
      final p = approx[i];
      points.add(Point(p.x.toDouble(), p.y.toDouble()));
    }

    // Reject corners too close to image edges (5% margin)
    final marginX = procWidth * 0.04;
    final marginY = procHeight * 0.04;
    for (final p in points) {
      if (p.x < marginX || p.x > procWidth - marginX ||
          p.y < marginY || p.y > procHeight - marginY) {
        return null;
      }
    }

    // Sort corners by centroid
    double cx = 0, cy = 0;
    for (final p in points) {
      cx += p.x;
      cy += p.y;
    }
    cx /= 4;
    cy /= 4;

    Point<double>? topLeft, topRight, bottomLeft, bottomRight;
    for (final p in points) {
      if (p.x < cx && p.y < cy) topLeft = p;
      else if (p.x >= cx && p.y < cy) topRight = p;
      else if (p.x < cx && p.y >= cy) bottomLeft = p;
      else bottomRight = p;
    }

    if (topLeft == null || topRight == null || bottomLeft == null || bottomRight == null) {
      final sorted = List<Point<double>>.from(points);
      sorted.sort((a, b) => (a.x + a.y).compareTo(b.x + b.y));
      topLeft = sorted[0];
      bottomRight = sorted[3];
      sorted.sort((a, b) => (a.x - a.y).compareTo(b.x - b.y));
      bottomLeft = sorted[0];
      topRight = sorted[3];
    }

    // Scale to original coordinates
    topLeft = Point(topLeft.x / scale, topLeft.y / scale);
    topRight = Point(topRight.x / scale, topRight.y / scale);
    bottomLeft = Point(bottomLeft.x / scale, bottomLeft.y / scale);
    bottomRight = Point(bottomRight.x / scale, bottomRight.y / scale);

    // Validate dimensions
    final w = ((topRight.x - topLeft.x) + (bottomRight.x - bottomLeft.x)) / 2;
    final h = ((bottomLeft.y - topLeft.y) + (bottomRight.y - topRight.y)) / 2;

    if (w < 80 || h < 50) return null;

    final aspect = w / h;
    if (aspect < 1.2 || aspect > 2.3) return null;

    return DetectedEdge(
      topLeft: topLeft,
      topRight: topRight,
      bottomLeft: bottomLeft,
      bottomRight: bottomRight,
      confidence: 0.9,
    );
  }

  Point<double> _lerp(Point<double> a, Point<double> b, double t) {
    return Point(a.x + (b.x - a.x) * t, a.y + (b.y - a.y) * t);
  }

  void reset() {
    _smoothedEdge = null;
    _frameCount = 0;
    _noDetectionFrames = 0;
  }
}
