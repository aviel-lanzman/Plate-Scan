import 'dart:async';
import 'dart:collection';

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter/services.dart';
import 'package:wakelock_plus/wakelock_plus.dart';

import '../app_services.dart';
import '../models/vehicle_result.dart';
import '../services/plate_camera.dart';
import '../services/plate_parser.dart';
import '../util/format.dart';
import '../widgets/camera_view.dart';
import '../widgets/plate_result_tile.dart';
import '../widgets/status_style.dart';
import 'result_screen.dart';

class _Detection {
  _Detection(this.plate, this.seenAt, this.photos);

  final String plate;
  final DateTime seenAt;

  /// Paths of the saved frames this plate was read in.
  final Future<List<String>> photos;
  VehicleResult? result;
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
    with WidgetsBindingObserver {
  static const _recheckAfter = Duration(minutes: 10);
  static const _maxInFlight = 2;
  static const _maxDetections = 50;

  final _camera = PlateCamera();
  final _voter = PlateVoter();
  final _detections = <_Detection>[];
  final _lastQueued = <String, DateTime>{};
  final _pending = Queue<_Detection>();
  int _inFlight = 0;
  bool _paused = false;
  _Detection? _alert;
  Timer? _alertTimer;
  String? _error;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    WakelockPlus.enable();
    _start();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    WakelockPlus.disable();
    _alertTimer?.cancel();
    _camera.dispose();
    for (final detection in _detections) {
      _discardPhotos(detection);
    }
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // The camera permission dialog also makes the app inactive, so only
    // release a camera that has finished initializing.
    if (state == AppLifecycleState.inactive && _camera.isRunning) {
      _camera.stop().then((_) {
        if (mounted) setState(() {});
      });
    } else if (state == AppLifecycleState.resumed &&
        _camera.controller == null &&
        !_paused) {
      _start();
    }
  }

  Future<void> _start() async {
    try {
      await _camera.start(_onCandidates);
      if (mounted) setState(() => _error = null);
    } on CameraException catch (e) {
      if (!mounted) return;
      setState(
        () => _error = e.code == 'CameraAccessDenied'
            ? 'אין הרשאה למצלמה. אפשר אותה בהגדרות המכשיר.'
            : 'שגיאת מצלמה: ${e.description ?? e.code}',
      );
    }
  }

  void _onCandidates(List<String> candidates) {
    if (!mounted) return;
    final now = DateTime.now();
    for (final plate in _voter.add(candidates)) {
      final last = _lastQueued[plate];
      if (last != null && now.difference(last) < _recheckAfter) continue;
      _lastQueued[plate] = now;
      final detection = _Detection(
        plate,
        now,
        widget.services.photos.save(plate, _camera.framesWith(plate)),
      );
      setState(() {
        _detections.insert(0, detection);
        if (_detections.length > _maxDetections) {
          _discardPhotos(_detections.removeLast());
        }
      });
      _pending.add(detection);
    }
    _pump();
  }

  void _discardPhotos(_Detection detection) =>
      detection.photos.then(widget.services.photos.delete);

  void _pump() {
    while (_inFlight < _maxInFlight && _pending.isNotEmpty) {
      final detection = _pending.removeFirst();
      _inFlight++;
      widget.services.lookup
          .lookup(detection.plate)
          .then((result) => _onResult(detection, result))
          .whenComplete(() {
            _inFlight--;
            if (mounted) _pump();
          });
    }
  }

  void _onResult(_Detection detection, VehicleResult result) {
    if (!mounted) return;
    setState(() => detection.result = result);
    // History keeps alerts and plates the user opens, not a log of every
    // passing car.
    if (result.status.isAlert) widget.services.history.add(result);
    if (result.status.isAlert) _raiseAlert(detection);
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
    _beep();
    SemanticsService.sendAnnouncement(
      View.of(context),
      'התרעה: ${formatPlate(detection.plate)}, ${detection.result!.status.label}',
      TextDirection.rtl,
      assertiveness: Assertiveness.assertive,
    );
    for (var i = 0; i < 3; i++) {
      await HapticFeedback.heavyImpact();
      await Future<void>.delayed(const Duration(milliseconds: 250));
    }
  }

  Future<void> _open(_Detection detection) async {
    if (_paused) return;
    _paused = true;
    await _camera.stop();
    final photos = await detection.photos;
    if (!mounted) return;
    final result = detection.result;
    if (result != null && result.status != PlateStatus.error) {
      widget.services.history.add(result);
    }
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
    _paused = false;
    _voter.reset();
    if (mounted) _start();
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
                if (_error case final error?)
                  Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Text(error, textAlign: TextAlign.center),
                    ),
                  )
                else
                  CameraView(_camera.controller),
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
