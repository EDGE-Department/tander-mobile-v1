import 'package:camera/camera.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'liveness_state.freezed.dart';

@freezed
sealed class LivenessState with _$LivenessState {
  const factory LivenessState.initial() = _Initial;
  const factory LivenessState.initializing() = _Initializing;
  const factory LivenessState.ready({
    required CameraController cameraController,
    @Default(false) bool isFaceDetected,
    @Default(false) bool isFaceCentered,
    @Default(0.0) double stabilityScore,
    @Default(false) bool isCapturing,
    String? instruction,
  }) = _Ready;
  const factory LivenessState.success({required String imagePath}) = _Success;
  const factory LivenessState.error({required String message}) = _Error;
}
