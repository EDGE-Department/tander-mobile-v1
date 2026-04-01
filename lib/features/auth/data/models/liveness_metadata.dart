/// Metadata from client-side liveness verification.
class LivenessMetadata {
  /// Verification method used (e.g. 'passive_auto_v1').
  final String method;

  /// Capture source type (e.g. 'camera_stream').
  final String captureSource;

  /// Legacy compatibility flag for older backend checks.
  final bool? blinkDetected;

  /// Maximum faces seen during liveness (should be 1).
  final int maxFacesSeen;

  /// Minimum face ratio observed (face area / frame area).
  final double minFaceSizeRatio;

  /// Stable frontal hold duration in milliseconds.
  final int frontalHoldMs;

  /// Total time from first capture to verification completion (ms).
  final int sessionDurationMs;

  /// Motion score computed from micro face movement between frames.
  final double motionScore;

  /// Number of live frames used for evidence.
  final int liveFrameCount;

  /// Optional two-selfie compatibility field.
  final double? smileDelta;

  /// Optional two-selfie compatibility field.
  final bool? smileDetectionSupported;

  /// Timestamp of successful verification.
  final DateTime verifiedAt;

  const LivenessMetadata({
    this.method = 'passive_auto_v1',
    this.captureSource = 'camera_stream',
    this.blinkDetected,
    required this.maxFacesSeen,
    required this.minFaceSizeRatio,
    required this.frontalHoldMs,
    required this.sessionDurationMs,
    required this.motionScore,
    required this.liveFrameCount,
    this.smileDelta,
    this.smileDetectionSupported,
    required this.verifiedAt,
  });

  Map<String, dynamic> toJson() => {
        'method': method,
        'captureSource': captureSource,
        'blinkDetected': blinkDetected,
        'maxFacesSeen': maxFacesSeen,
        'minFaceSizeRatio': minFaceSizeRatio,
        'frontalHoldMs': frontalHoldMs,
        'sessionDurationMs': sessionDurationMs,
        'motionScore': motionScore,
        'liveFrameCount': liveFrameCount,
        if (smileDelta != null) 'smileDelta': smileDelta,
        if (smileDetectionSupported != null)
          'smileDetectionSupported': smileDetectionSupported,
        'verifiedAt': verifiedAt.toIso8601String(),
      };
}
