# Liveness Screen Implementation Details

## Files Created
- `lib/features/auth/presentation/states/liveness_state.dart` (and generated `.freezed.dart`)
- `lib/features/auth/presentation/notifiers/liveness_notifier.dart`
- `lib/features/auth/presentation/screens/liveness_screen.dart`
- `lib/features/auth/presentation/widgets/liveness/camera_preview_widget.dart`
- `lib/features/auth/presentation/widgets/liveness/face_overlay_widget.dart`
- `lib/features/auth/presentation/widgets/liveness/liveness_instructions.dart`

## Platform Changes
- Lowered iOS `platform :ios` to `'12.0'` in `ios/Podfile`.
- Lowered Android `minSdk` to `21` in `android/app/build.gradle.kts`.

## Responsive Layouts & Orientation (iPad Landscape)
- Used `LayoutBuilder` in `FaceOverlayWidget` to compute `screenWidth` and scale the oval dynamically (70% of screen width).
- Used `FittedBox` with `BoxFit.cover` in `CameraPreviewWidget` to guarantee the camera preview fills the screen regardless of device aspect ratio.
- Implemented orientation locking *after* camera initializes based on the user's current orientation (`MediaQuery.orientationOf(context)`). If they start in portrait, it locks to portrait; if they start in landscape (e.g. tablet), it locks to landscape. This ensures the app doesn't unexpectedly rotate and break the UI layout or camera preview. On exit, `DeviceUtils.configureOrientations(context)` restores the allowed orientations.

## Performance on Old Devices
- **Throttling**: Framerate processing is throttled using a timer (`_lastFrameTime` check) to skip frames, targeting roughly 10 FPS for ML kit processing.
- **ML Kit Configuration**: `FaceDetectorMode.fast` is enabled and contours/landmarks are disabled to minimize processing overhead.
- **Memory Management**: Camera controller and ML Kit instances are immediately disposed in the notifier when the screen is destroyed. 
- **Lifecycle Management**: The detection pipeline pauses when the app goes to the background and resumes upon returning to avoid processing while inactive.

## Aesthetic touches
- The UI features a premium dark theme. 
- A warm orange border (`#E86035`) is shown during detection. 
- Once the face is centered and eyes are open, the border transitions smoothly to a cool teal (`#5BBFB3`) and a circular progress indicator surrounds the oval to provide "stability" feedback. 
- Auto-capture kicks in when the 1.5s stability threshold is met.
