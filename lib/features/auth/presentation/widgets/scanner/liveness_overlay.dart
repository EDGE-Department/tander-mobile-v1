/// Phases for passive auto-capture liveness flow.
enum LivenessPhase {
  /// Initial camera setup.
  initializing,

  /// Searching for a single valid face.
  searching,

  /// Face detected, user should align.
  alignFace,

  /// Face is aligned and hold is in progress.
  holdingStill,

  /// Taking final selfie capture.
  capturing,

  /// Verification successful.
  verified,

  /// Session timed out.
  timeout,

  /// Error state.
  error,
}
