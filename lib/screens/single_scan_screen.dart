import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter/services.dart';

import '../app_services.dart';
import '../services/plate_parser.dart';
import '../widgets/camera_view.dart';
import '../widgets/plate_badge.dart';
import '../widgets/plate_number_field.dart';
import 'plate_camera_host.dart';
import 'result_screen.dart';

/// Point-and-shoot: scans until one plate is confirmed, then lets the user
/// correct it before checking. While scanning, the user can also accept or
/// reject the current best reading instead of waiting for confirmation.
class SingleScanScreen extends StatefulWidget {
  const SingleScanScreen({super.key, required this.services});

  final AppServices services;

  @override
  State<SingleScanScreen> createState() => _SingleScanScreenState();
}

class _SingleScanScreenState extends State<SingleScanScreen>
    with WidgetsBindingObserver, PlateCameraHost<SingleScanScreen> {
  final _voter = PlateVoter();
  final _plateController = TextEditingController();
  String? _confirmed;
  DateTime? _seenAt;
  Future<List<String>>? _photos;
  bool _photosHandedOff = false;
  String? _reading;
  final _rejected = <String>{};
  String? _plateError;

  @override
  bool get wantsCamera => _confirmed == null;

  @override
  void dispose() {
    _plateController.dispose();
    if (!_photosHandedOff) _discardPhotos();
    super.dispose();
  }

  @override
  void onCameraCandidates(List<String> candidates) {
    if (!mounted || _confirmed != null) return;
    final confirmed = _voter.add(
      candidates.where((p) => !_rejected.contains(p)),
    );
    if (confirmed.isEmpty) {
      // Keep showing the last reading after the plate leaves the frame, so
      // the user can still accept it.
      final leader = _voter.leader;
      if (leader != null && leader != _reading) {
        if (_reading == null) {
          _announce(
            'זוהה מספר אפשרי ${_spoken(leader)}. אשר אותו או המשך לכוון.',
          );
        }
        setState(() => _reading = leader);
      }
      return;
    }
    unawaited(HapticFeedback.mediumImpact());
    final plate = confirmed.first;
    _announce('זוהה מספר ${_spoken(plate)}. ודא שהוא נכון ולחץ בדוק.');
    _freeze(plate);
    setState(() => _plateController.text = plate);
  }

  String _spoken(String plate) => plate.split('').join(' ');

  void _announce(String message) => SemanticsService.sendAnnouncement(
    View.of(context),
    message,
    TextDirection.rtl,
  );

  /// Stops scanning on [plate] and saves the frames it was read in.
  void _freeze(String plate) {
    // Grab the frames before stop() releases them.
    _photos = widget.services.photos.save(plate, camera.framesWith(plate));
    _seenAt = DateTime.now();
    setState(() => _confirmed = plate);
    unawaited(camera.stop());
  }

  /// The user says the reading is right: check it straight away.
  void _acceptReading(String plate) {
    unawaited(HapticFeedback.mediumImpact());
    _freeze(plate);
    _plateController.text = plate;
    unawaited(_check());
  }

  /// The user says [plate] is a misread: ignore it until they leave.
  void _reject(String plate) {
    _rejected.add(plate);
    _voter.reset();
    setState(() => _reading = null);
  }

  void _discardPhotos() {
    final photos = _photos;
    if (photos != null) unawaited(photos.then(widget.services.photos.delete));
    _photos = null;
  }

  /// The confirmed number is wrong: ignore it and scan again.
  void _rescan() {
    if (_confirmed case final plate?) _rejected.add(plate);
    _discardPhotos();
    _voter.reset();
    setState(() {
      _confirmed = null;
      _reading = null;
    });
    unawaited(startCamera());
  }

  Future<void> _check() async {
    if (_photosHandedOff) return;
    final error = plateNumberError(_plateController.text);
    if (error != null) {
      setState(() => _plateError = error);
      return;
    }
    final plate = normalizePlate(_plateController.text);
    _photosHandedOff = true;
    // Encoding normally finishes while the user confirms the number.
    final photos = await _photos ?? const <String>[];
    if (!mounted) {
      unawaited(widget.services.photos.delete(photos));
      return;
    }
    unawaited(
      Navigator.pushReplacement(
        context,
        MaterialPageRoute<void>(
          builder: (_) => ResultScreen(
            services: widget.services,
            plate: plate,
            photos: photos,
            ownsPhotos: true,
            seenAt: _seenAt,
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final reading = _reading;
    final confirmed = _confirmed;
    return Scaffold(
      appBar: AppBar(title: const Text('כוון וצלם')),
      body: Stack(
        fit: StackFit.expand,
        children: [
          if (cameraError != null)
            buildCameraError()
          else if (confirmed != null)
            // The camera is off: show the frame the plate was read in, so
            // the number can be compared with it.
            _FrozenFrame(_photos)
          else ...[
            CameraView(camera.controller),
            const PlateFrame(),
            const Positioned(
              top: 16,
              left: 16,
              right: 16,
              child: _Hint('כוון את המצלמה ללוחית הרישוי'),
            ),
          ],
          if (confirmed != null)
            Align(
              alignment: Alignment.bottomCenter,
              child: _ConfirmCard(
                controller: _plateController,
                errorText: _plateError,
                onChanged: () {
                  if (_plateError != null) setState(() => _plateError = null);
                },
                onCheck: _check,
                onRescan: _rescan,
              ),
            )
          else if (reading != null && cameraError == null)
            Align(
              alignment: Alignment.bottomCenter,
              child: _ReadingCard(
                reading,
                onAccept: () => _acceptReading(reading),
                onReject: () => _reject(reading),
              ),
            ),
        ],
      ),
    );
  }
}

class _FrozenFrame extends StatelessWidget {
  const _FrozenFrame(this.photos);

  final Future<List<String>>? photos;

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: Colors.black,
      child: FutureBuilder<List<String>>(
        future: photos,
        builder: (context, snapshot) {
          final path = snapshot.data?.lastOrNull;
          if (path == null) return const SizedBox.expand();
          return Image.file(
            File(path),
            fit: BoxFit.cover,
            width: double.infinity,
            height: double.infinity,
            semanticLabel: 'התמונה שבה זוהה המספר',
          );
        },
      ),
    );
  }
}

/// The best reading so far, before it is confirmed.
class _ReadingCard extends StatelessWidget {
  const _ReadingCard(
    this.plate, {
    required this.onAccept,
    required this.onReject,
  });

  final String plate;
  final VoidCallback onAccept;
  final VoidCallback onReject;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Card(
        margin: const EdgeInsets.all(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text('מזהה מספר. האם זה המספר שעל הרכב?'),
              const SizedBox(height: 8),
              Center(child: PlateBadge(plate, fontSize: 28)),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: FilledButton.icon(
                      onPressed: onAccept,
                      icon: const Icon(Icons.check),
                      label: const Text('זה המספר'),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: onReject,
                      icon: const Icon(Icons.close),
                      label: const Text('לא המספר'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Hint extends StatelessWidget {
  const _Hint(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: Colors.black54,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Text(
            text,
            style: const TextStyle(color: Colors.white, fontSize: 16),
          ),
        ),
      ),
    );
  }
}

class _ConfirmCard extends StatelessWidget {
  const _ConfirmCard({
    required this.controller,
    required this.errorText,
    required this.onChanged,
    required this.onCheck,
    required this.onRescan,
  });

  final TextEditingController controller;
  final String? errorText;
  final VoidCallback onChanged;
  final VoidCallback onCheck;
  final VoidCallback onRescan;

  @override
  Widget build(BuildContext context) {
    // Scrolls so large text plus the keyboard cannot overflow.
    return SafeArea(
      child: Card(
        margin: const EdgeInsets.all(16),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text('זוהה מספר. ודא שהוא נכון:'),
              const SizedBox(height: 8),
              PlateNumberField(
                controller: controller,
                style: Theme.of(context).textTheme.headlineMedium,
                errorText: errorText,
                onChanged: (_) => onChanged(),
                onSubmitted: (_) => onCheck(),
              ),
              const SizedBox(height: 12),
              FilledButton.icon(
                onPressed: onCheck,
                icon: const Icon(Icons.search),
                label: const Text('בדוק'),
              ),
              TextButton.icon(
                onPressed: onRescan,
                icon: const Icon(Icons.refresh),
                label: const Text('זה לא המספר, סרוק שוב'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
