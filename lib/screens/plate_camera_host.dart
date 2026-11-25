import 'dart:async';

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';

import '../services/plate_camera.dart';
import '../widgets/camera_error_view.dart';

/// Camera hosting shared by the scan screens: owns the [PlateCamera], starts
/// it, releases it when the app goes to the background, and shows the error
/// state. The State must list WidgetsBindingObserver before this mixin.
mixin PlateCameraHost<T extends StatefulWidget>
    on State<T>, WidgetsBindingObserver {
  final camera = PlateCamera();
  String? _cameraError;
  bool _permissionDenied = false;
  bool _wasInBackground = false;

  /// Whether the screen needs the camera right now. It decides whether coming
  /// back to the foreground restarts it.
  bool get wantsCamera;

  /// Plate candidates read from one processed frame.
  void onCameraCandidates(List<String> candidates);

  String? get cameraError => _cameraError;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    unawaited(startCamera());
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    unawaited(camera.dispose());
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    switch (state) {
      case AppLifecycleState.inactive:
        // The camera permission dialog also makes the app inactive, so only
        // release a camera that has finished initializing.
        if (camera.isRunning) _release();
      case AppLifecycleState.paused || AppLifecycleState.hidden:
        // Release unconditionally: stop() waits for a start that is still
        // initializing, so the camera cannot keep running in the background.
        _wasInBackground = true;
        _release();
      case AppLifecycleState.resumed:
        // After a denial the permission dialog only makes the app inactive;
        // retrying then would ask again in a loop. A real trip to the
        // background (e.g. to the settings) is worth a retry.
        final retry = _cameraError == null || _wasInBackground;
        _wasInBackground = false;
        if (retry && wantsCamera) unawaited(startCamera());
      case AppLifecycleState.detached:
        break;
    }
  }

  void _release() {
    unawaited(
      camera.stop().then((_) {
        if (mounted) setState(() {});
      }),
    );
  }

  /// Starts the camera and maps any failure to the error state.
  Future<void> startCamera() async {
    try {
      await camera.start(onCameraCandidates);
      if (mounted) setState(() => _cameraError = null);
    } on CameraException catch (e) {
      _fail(
        e.code.startsWith('CameraAccess'),
        e.code == 'NoCamera' ? e.description : null,
        e,
      );
    } on Object catch (e) {
      _fail(false, null, e);
    }
  }

  void _fail(bool permissionDenied, String? description, Object error) {
    debugPrint('PlateCameraHost: camera failed: $error');
    if (!mounted) return;
    setState(() {
      _permissionDenied = permissionDenied;
      _cameraError = permissionDenied
          ? 'אין הרשאה למצלמה. אפשר אותה בהגדרות המכשיר.'
          : description ?? 'המצלמה לא הופעלה. נסה שוב.';
    });
  }

  /// The error state; only call when [cameraError] is not null.
  Widget buildCameraError() {
    return CameraErrorView(
      message: _cameraError ?? '',
      onRetry: () {
        setState(() => _cameraError = null);
        unawaited(startCamera());
      },
      onOpenSettings: _permissionDenied
          ? () => unawaited(Geolocator.openAppSettings())
          : null,
    );
  }
}
