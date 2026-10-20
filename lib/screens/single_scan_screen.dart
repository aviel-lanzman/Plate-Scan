import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../app_services.dart';
import '../services/plate_camera.dart';
import '../services/plate_parser.dart';
import '../widgets/camera_view.dart';
import 'result_screen.dart';

/// Point-and-shoot: scans until one plate is confirmed, then lets the user
/// correct it before checking.
class SingleScanScreen extends StatefulWidget {
  const SingleScanScreen({super.key, required this.services});

  final AppServices services;

  @override
  State<SingleScanScreen> createState() => _SingleScanScreenState();
}

class _SingleScanScreenState extends State<SingleScanScreen>
    with WidgetsBindingObserver {
  final _camera = PlateCamera();
  final _voter = PlateVoter();
  final _plateController = TextEditingController();
  String? _confirmed;
  String? _reading;
  String? _error;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _start();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _camera.dispose();
    _plateController.dispose();
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
        _confirmed == null) {
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
    if (!mounted || _confirmed != null) return;
    final confirmed = _voter.add(candidates);
    if (confirmed.isEmpty) {
      setState(() => _reading = candidates.firstOrNull ?? _reading);
      return;
    }
    HapticFeedback.mediumImpact();
    setState(() {
      _confirmed = confirmed.first;
      _plateController.text = confirmed.first;
    });
    _camera.stop();
  }

  void _rescan() {
    _voter.reset();
    setState(() {
      _confirmed = null;
      _reading = null;
    });
    _start();
  }

  void _check() {
    final plate = normalizePlate(_plateController.text);
    if (!isValidPlate(plate)) return;
    Navigator.pushReplacement(
      context,
      MaterialPageRoute<void>(
        builder: (_) => ResultScreen(services: widget.services, plate: plate),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final reading = _reading;
    return Scaffold(
      appBar: AppBar(title: const Text('כוון וצלם')),
      body: Stack(
        fit: StackFit.expand,
        children: [
          if (_error case final error?)
            Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Text(error, textAlign: TextAlign.center),
              ),
            )
          else ...[
            CameraView(_camera.controller),
            const PlateFrame(),
            Positioned(
              top: 16,
              left: 16,
              right: 16,
              child: _Hint(
                reading == null
                    ? 'כוון את המצלמה ללוחית הרישוי'
                    : 'מזהה: ${formatPlate(reading)}',
              ),
            ),
          ],
          if (_confirmed != null)
            Align(
              alignment: Alignment.bottomCenter,
              child: _ConfirmCard(
                controller: _plateController,
                onCheck: _check,
                onRescan: _rescan,
              ),
            ),
        ],
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
    required this.onCheck,
    required this.onRescan,
  });

  final TextEditingController controller;
  final VoidCallback onCheck;
  final VoidCallback onRescan;

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
              const Text('זוהה מספר. ודא שהוא נכון:'),
              const SizedBox(height: 8),
              TextField(
                controller: controller,
                keyboardType: TextInputType.number,
                textDirection: TextDirection.ltr,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.headlineMedium,
                inputFormatters: [
                  FilteringTextInputFormatter.digitsOnly,
                  LengthLimitingTextInputFormatter(8),
                ],
                decoration: const InputDecoration(border: OutlineInputBorder()),
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
                label: const Text('סרוק שוב'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
