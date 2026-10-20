import 'package:camera/camera.dart';
import 'package:flutter/material.dart';

/// Full-bleed camera preview for a portrait screen.
class CameraView extends StatelessWidget {
  const CameraView(this.controller, {super.key});

  final CameraController? controller;

  @override
  Widget build(BuildContext context) {
    final controller = this.controller;
    if (controller == null || !controller.value.isInitialized) {
      return const ColoredBox(
        color: Colors.black,
        child: Center(child: CircularProgressIndicator()),
      );
    }
    // previewSize is reported in landscape, so swap it for portrait.
    final size = controller.value.previewSize!;
    return ClipRect(
      child: SizedBox.expand(
        child: FittedBox(
          fit: BoxFit.cover,
          child: SizedBox(
            width: size.height,
            height: size.width,
            child: CameraPreview(controller),
          ),
        ),
      ),
    );
  }
}

/// Plate-shaped aiming frame drawn over the preview.
class PlateFrame extends StatelessWidget {
  const PlateFrame({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: FractionallySizedBox(
        widthFactor: 0.85,
        child: AspectRatio(
          aspectRatio: 4.7, // Israeli plates are 520x110 mm.
          child: DecoratedBox(
            decoration: BoxDecoration(
              border: Border.all(color: Colors.white, width: 3),
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        ),
      ),
    );
  }
}
