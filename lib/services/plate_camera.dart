import 'dart:collection';
import 'dart:io';

import 'package:camera/camera.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';

import 'plate_parser.dart';
import 'report_photos.dart';

/// Streams frames from the back camera through on-device ML Kit OCR and
/// reports plate candidates found in each processed frame. The last few
/// frames with a plate in them are kept for report photos.
class PlateCamera {
  PlateCamera({this.frameInterval = const Duration(milliseconds: 300)});

  final Duration frameInterval;
  final _recognizer = TextRecognizer(script: TextRecognitionScript.latin);
  static const _keptFrames = 8;
  final _recent = Queue<CapturedFrame>();

  CameraController? _controller;
  CameraDescription? _camera;
  ValueChanged<List<String>>? _onCandidates;
  bool _busy = false;
  DateTime _lastFrame = DateTime.fromMillisecondsSinceEpoch(0);

  CameraController? get controller => _controller;

  bool get isRunning => _controller?.value.isInitialized ?? false;

  /// Recent frames in which [plate] was read, oldest first.
  List<CapturedFrame> framesWith(String plate) => [
    for (final frame in _recent)
      if (frame.plates.contains(plate)) frame,
  ];

  /// Throws [CameraException] (e.g. code `CameraAccessDenied`) on failure.
  Future<void> start(ValueChanged<List<String>> onCandidates) async {
    _onCandidates = onCandidates;
    if (_controller != null) return;

    _camera ??= await _backCamera();
    final controller = CameraController(
      _camera!,
      ResolutionPreset.high,
      enableAudio: false,
      imageFormatGroup: Platform.isAndroid
          ? ImageFormatGroup.nv21
          : ImageFormatGroup.bgra8888,
    );
    _controller = controller;
    try {
      await controller.initialize();
      await controller.startImageStream(_onFrame);
    } on Object {
      // stop() may have already released this controller mid-initialize.
      if (identical(_controller, controller)) {
        _controller = null;
        await controller.dispose();
      }
      rethrow;
    }
  }

  /// Releases the camera; [start] can be called again later.
  Future<void> stop() async {
    final controller = _controller;
    _controller = null;
    _recent.clear();
    if (controller == null) return;
    if (controller.value.isStreamingImages) {
      await controller.stopImageStream();
    }
    await controller.dispose();
  }

  Future<void> dispose() async {
    await stop();
    await _recognizer.close();
  }

  Future<CameraDescription> _backCamera() async {
    final cameras = await availableCameras();
    if (cameras.isEmpty) {
      throw CameraException('NoCamera', 'לא נמצאה מצלמה במכשיר');
    }
    return cameras.firstWhere(
      (c) => c.lensDirection == CameraLensDirection.back,
      orElse: () => cameras.first,
    );
  }

  Future<void> _onFrame(CameraImage image) async {
    final now = DateTime.now();
    if (_busy || now.difference(_lastFrame) < frameInterval) return;
    _busy = true;
    _lastFrame = now;
    try {
      final rotation = _rotation();
      if (rotation == null) return;
      final input = _toInputImage(image, rotation);
      if (input == null) return;
      final text = await _recognizer.processImage(input);
      final lines = [
        for (final block in text.blocks)
          for (final line in block.lines) line.text,
      ];
      final plates = PlateParser.extract(lines);
      if (_controller == null) return;
      if (plates.isNotEmpty) _keep(image, rotation, plates);
      _onCandidates?.call(plates);
    } on Object catch (e) {
      debugPrint('PlateCamera: frame failed: $e');
    } finally {
      _busy = false;
    }
  }

  static const _orientations = {
    DeviceOrientation.portraitUp: 0,
    DeviceOrientation.landscapeLeft: 90,
    DeviceOrientation.portraitDown: 180,
    DeviceOrientation.landscapeRight: 270,
  };

  void _keep(
    CameraImage image,
    InputImageRotation rotation,
    List<String> plates,
  ) {
    final plane = image.planes.first;
    _recent.addLast(
      CapturedFrame(
        bytes: plane.bytes,
        width: image.width,
        height: image.height,
        bytesPerRow: plane.bytesPerRow,
        format: Platform.isAndroid ? FrameFormat.nv21 : FrameFormat.bgra8888,
        rotation: rotation.rawValue,
        plates: plates,
      ),
    );
    if (_recent.length > _keptFrames) _recent.removeFirst();
  }

  // The rotation and conversion follow the google_mlkit_commons documentation.
  InputImageRotation? _rotation() {
    final camera = _camera;
    final controller = _controller;
    if (camera == null || controller == null) return null;

    final sensorOrientation = camera.sensorOrientation;
    if (Platform.isIOS) {
      return InputImageRotationValue.fromRawValue(sensorOrientation);
    }
    final compensation = _orientations[controller.value.deviceOrientation];
    if (compensation == null) return null;
    return InputImageRotationValue.fromRawValue(
      camera.lensDirection == CameraLensDirection.front
          ? (sensorOrientation + compensation) % 360
          : (sensorOrientation - compensation + 360) % 360,
    );
  }

  InputImage? _toInputImage(CameraImage image, InputImageRotation rotation) {
    final format = InputImageFormatValue.fromRawValue(image.format.raw as int);
    if (format == null ||
        (Platform.isAndroid && format != InputImageFormat.nv21) ||
        (Platform.isIOS && format != InputImageFormat.bgra8888)) {
      return null;
    }
    if (image.planes.length != 1) return null;
    final plane = image.planes.first;

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
}
