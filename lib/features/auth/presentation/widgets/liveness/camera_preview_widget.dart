import 'package:camera/camera.dart';
import 'package:flutter/material.dart';

class CameraPreviewWidget extends StatelessWidget {
  final CameraController controller;

  const CameraPreviewWidget({
    super.key,
    required this.controller,
  });

  @override
  Widget build(BuildContext context) {
    if (!controller.value.isInitialized) {
      return const SizedBox.shrink();
    }

    final orientation = MediaQuery.orientationOf(context);
    final previewSize = controller.value.previewSize;

    final double previewWidth;
    final double previewHeight;

    if (orientation == Orientation.portrait) {
      previewWidth = previewSize?.height ?? 1;
      previewHeight = previewSize?.width ?? 1;
    } else {
      previewWidth = previewSize?.width ?? 1;
      previewHeight = previewSize?.height ?? 1;
    }

    return SizedBox.expand(
      child: FittedBox(
        fit: BoxFit.cover,
        child: SizedBox(
          width: previewWidth,
          height: previewHeight,
          child: CameraPreview(controller),
        ),
      ),
    );
  }
}
