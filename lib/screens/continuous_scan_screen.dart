import 'dart:async';
import 'dart:collection';

import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter/services.dart';
import 'package:wakelock_plus/wakelock_plus.dart';

import '../app_services.dart';
import '../models/vehicle_result.dart';
import '../services/report_photos.dart';
import '../services/plate_parser.dart';
import '../util/format.dart';
import '../widgets/camera_view.dart';
import '../widgets/plate_result_tile.dart';
import '../widgets/status_style.dart';
import 'plate_camera_host.dart';
import 'result_screen.dart';

class _Detection {
  _Detection(this.plate, this.seenAt, this.frames);

  final String plate;
  final DateTime seenAt;

  /// The frames this plate was read in, held in memory until they are saved
  /// (the plate raised an alert or the user opened it) or released.
  List<CapturedFrame>? frames;
  Future<List<String>>? _photos;

  /// Dropped from the list: its photos are gone and must not be written.
  bool evicted = false;
  VehicleResult? result;

  /// Writes the held frames to disk once and returns the paths of the saved
  /// photos. Empty when the frames were released or the detection evicted.
  Future<List<String>> savePhotos(ReportPhotos photos) {
    if (evicted) return Future.value(const []);
    final held = frames;
    frames = null;
    return _photos ??= held == null || held.isEmpty
        ? Future.value(const [])
        : photos.save(plate, held);
  }
}

/// Keeps the camera running, looks up every confirmed plate, and alerts on
/// off-road or inactive vehicles.
class ContinuousScanScreen extends StatefulWidget {
  const ContinuousScanScreen({super.key, required this.services});

  final AppServices services;

  @override
  State<ContinuousScanScreen> createState() => _ContinuousScanScreenState();
}

class _ContinuousScanScreenState extends State<ContinuousScanScreen>
    with WidgetsBindingObserver, PlateCameraHost<ContinuousScanScreen> {
  static const _recheckAfter = Duration(minutes: 10);
  static const _maxInFlight = 2;
  static const _maxDetections = 50;

  /// Only this many of the newest detections keep their frames in memory, at
  /// most [_framesPerDetection] each. A frame is a full NV21 or BGRA camera
  /// frame (about 1.4 MB at 720p, 3.1 MB at 1080p), so the worst case is
  /// 6 x 3 = 18 frames (about 25 MB at 720p, 56 MB at 1080p), less when
  /// detections share frames. An older detection that alerts or is opened
  /// has no photos.
  static const _heldDetections = 6;
  static const _framesPerDetection = 3;

  final _voter = PlateVoter();
  final _detections = <_Detection>[];
  final _lastQueued = <String, DateTime>{};
  final _pending = Queue<_Detection>();
  int _inFlight = 0;
  bool _paused = false;
  _Detection? _alert;
  Timer? _alertTimer;

  /// Alerts that arrived while a result screen was open; shown on return.
  final _held = <_Detection>[];

  @override
  bool get wantsCamera => !_paused;

  @override
  void initState() {
    super.initState();
    unawaited(WakelockPlus.enable());
  }

  @override
  void dispose() {
    unawaited(WakelockPlus.disable());
    _alertTimer?.cancel();
    for (final detection in _detections) {
      _discardPhotos(detection);
    }
    super.dispose();
  }

  @override
  void onCameraCandidates(List<String> candidates) {
    if (!mounted) return;
    final now = DateTime.now();
    for (final plate in _voter.add(candidates)) {
      final last = _lastQueued[plate];
      if (last != null && now.difference(last) < _recheckAfter) continue;
      _lastQueued[plate] = now;
      final detection = _Detection(plate, now, _thin(camera.framesWith(plate)));
      setState(() {
        _detections.insert(0, detection);
        for (var i = _heldDetections; i < _detections.length; i++) {
          _detections[i].frames = null;
        }
        if (_detections.length > _maxDetections) {
          final old = _detections.removeLast();
          // It must not be looked up, alerted or saved after it is gone.
          _pending.remove(old);
          _discardPhotos(old);
        }
      });
      _pending.add(detection);
    }
    _pump();
  }

  /// Up to [_framesPerDetection] of [frames]: first, middle and last.
  static List<CapturedFrame> _thin(List<CapturedFrame> frames) {
    if (frames.length <= _framesPerDetection) return frames;
    return [frames.first, frames[frames.length ~/ 2], frames.last];
  }

  void _discardPhotos(_Detection detection) {
    detection
      ..evicted = true
      ..frames = null;
    unawaited(detection._photos?.then(widget.services.photos.delete));
  }

  void _pump() {
    while (_inFlight < _maxInFlight && _pending.isNotEmpty) {
      final detection = _pending.removeFirst();
      _inFlight++;
      unawaited(
        widget.services.lookup
            .lookup(detection.plate)
            .then((result) => _onResult(detection, result))
            .whenComplete(() {
              _inFlight--;
              if (mounted) _pump();
            }),
      );
    }
  }

  void _onResult(_Detection detection, VehicleResult result) {
    if (!mounted) return;
    // A failed lookup says nothing about the car, so let it be checked again.
    if (result.status == PlateStatus.error) _lastQueued.remove(detection.plate);
    setState(() => detection.result = result);
    if (!result.status.isAlert) return;
    // History and photos keep alerts and plates the user opens, not a log of
    // every passing car.
    unawaited(widget.services.history.add(result));
    unawaited(detection.savePhotos(widget.services.photos));
    // Don't beep over another car's result screen; show it on return.
    if (_paused) {
      _held.add(detection);
    } else {
      unawaited(_raiseAlert(detection));
    }
  }

  static const _alertChannel = MethodChannel('plate_scan/alert');

  /// Android beeps natively; elsewhere this is a best-effort system sound.
  Future<void> _beep() async {
    try {
      await _alertChannel.invokeMethod<bool>('beep');
    } on MissingPluginException {
      await SystemSound.play(SystemSoundType.alert);
    } on PlatformException catch (e) {
      debugPrint('Alert beep failed: $e');
    }
  }

  Future<void> _raiseAlert(_Detection detection) async {
    _alertTimer?.cancel();
    setState(() => _alert = detection);
    _alertTimer = Timer(const Duration(seconds: 8), () {
      if (mounted) setState(() => _alert = null);
    });
    unawaited(_beep());
    unawaited(
      SemanticsService.sendAnnouncement(
        View.of(context),
        'התרעה: ${formatPlate(detection.plate)}, ${detection.result!.status.label}',
        TextDirection.rtl,
        assertiveness: Assertiveness.assertive,
      ),
    );
    for (var i = 0; i < 3; i++) {
      await HapticFeedback.heavyImpact();
      await Future<void>.delayed(const Duration(milliseconds: 250));
    }
  }

  Future<void> _open(_Detection detection) async {
    if (_paused) return;
    _paused = true;
    await camera.stop();
    final photos = await detection.savePhotos(widget.services.photos);
    if (!mounted) return;
    final result = detection.result;
    if (result != null && result.status != PlateStatus.error) {
      unawaited(widget.services.history.add(result));
    }
    // The scanner is covered, so the screen need not stay awake for it.
    unawaited(WakelockPlus.disable());
    await Navigator.push(
      context,
      MaterialPageRoute<void>(
        builder: (_) => ResultScreen(
          services: widget.services,
          plate: detection.plate,
          // Errors are worth retrying, so look those up again.
          initial: detection.result?.status == PlateStatus.error
              ? null
              : detection.result,
          photos: photos,
          seenAt: detection.seenAt,
        ),
      ),
    );
    if (!mounted) return;
    unawaited(WakelockPlus.enable());
    _paused = false;
    _voter.reset();
    unawaited(startCamera());
    final held = _held.where((d) => d != detection).toList();
    _held.clear();
    if (held.isNotEmpty) unawaited(_raiseAlert(held.last));
  }

  @override
  Widget build(BuildContext context) {
    final alert = _alert;
    return Scaffold(
      appBar: AppBar(
        title: const Text('סריקה רציפה'),
        actions: [
          Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Text('${_detections.length} לוחיות'),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          Material(
            color: Colors.amber.shade700,
            child: const Padding(
              padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              child: Row(
                children: [
                  Icon(Icons.no_crash, color: Colors.black),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'לשימוש נוסע בלבד. אין להפעיל בזמן נהיגה.',
                      style: TextStyle(color: Colors.black),
                    ),
                  ),
                ],
              ),
            ),
          ),
          Expanded(
            flex: 3,
            child: Stack(
              fit: StackFit.expand,
              children: [
                if (cameraError != null)
                  buildCameraError()
                else
                  CameraView(camera.controller),
                if (alert != null)
                  Positioned(
                    top: 8,
                    left: 8,
                    right: 8,
                    child: _AlertBanner(alert, onTap: () => _open(alert)),
                  ),
              ],
            ),
          ),
          Expanded(
            flex: 2,
            child: _detections.isEmpty
                ? const Center(
                    child: Padding(
                      padding: EdgeInsets.all(24),
                      child: Text(
                        'כוון את המצלמה לרכבים. לוחיות שיזוהו יופיעו כאן.',
                        textAlign: TextAlign.center,
                      ),
                    ),
                  )
                : ListView.separated(
                    itemCount: _detections.length,
                    separatorBuilder: (_, _) => const Divider(height: 1),
                    itemBuilder: (context, i) {
                      final d = _detections[i];
                      return PlateResultTile(
                        plate: d.plate,
                        status: d.result?.status,
                        summary: d.result?.info?.summary,
                        time: formatTime(d.seenAt),
                        partial: d.result?.partial ?? false,
                        onTap: () => _open(d),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}

class _AlertBanner extends StatelessWidget {
  const _AlertBanner(this.detection, {required this.onTap});

  final _Detection detection;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final status = detection.result!.status;
    return Material(
      color: status.color,
      elevation: 6,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              Icon(status.icon, color: Colors.white, size: 36),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${formatPlate(detection.plate)}: ${status.label}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const Text(
                      'הקש לפרטים ולדיווח',
                      style: TextStyle(color: Colors.white),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
