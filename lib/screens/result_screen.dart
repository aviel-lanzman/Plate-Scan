import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';

import '../app_services.dart';
import '../models/vehicle_result.dart';
import '../services/plate_parser.dart';
import '../services/report_service.dart';
import '../widgets/photo_viewer.dart';
import '../widgets/plate_badge.dart';
import '../widgets/plate_number_field.dart';
import '../widgets/result/report_card.dart';
import '../widgets/result/status_card.dart';
import '../widgets/result/stolen_card.dart';
import '../widgets/result/vehicle_card.dart';
import 'report_guide_screen.dart';
import 'stolen_check_screen.dart';

class ResultScreen extends StatefulWidget {
  const ResultScreen({
    super.key,
    required this.services,
    required this.plate,
    this.initial,
    this.photos = const [],
    this.ownsPhotos = false,
    this.seenAt,
  });

  final AppServices services;

  /// Digits only. The user can correct it on this screen; the photos and
  /// [seenAt] still apply then, since it is the same car.
  final String plate;

  /// An existing result (from history or continuous mode) to show instead of
  /// looking the plate up again.
  final VehicleResult? initial;

  /// Photos taken while scanning, to attach to a report.
  final List<String> photos;

  /// Whether to delete [photos] when this screen closes, because no earlier
  /// screen will.
  final bool ownsPhotos;

  /// When the camera read the plate; null for typed plates and history.
  final DateTime? seenAt;

  @override
  State<ResultScreen> createState() => _ResultScreenState();
}

class _ResultScreenState extends State<ResultScreen> {
  late String _plate = widget.plate;
  VehicleResult? _result;
  bool _sharing = false;
  late final _photos = [...widget.photos];

  /// Tells a lookup that finished late that the plate was edited meanwhile.
  int _lookupId = 0;

  @override
  void dispose() {
    if (widget.ownsPhotos) unawaited(widget.services.photos.delete(_photos));
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    _result = widget.initial;
    if (_result == null) unawaited(_lookup());
  }

  Future<void> _lookup({bool refresh = false}) async {
    final id = ++_lookupId;
    final previous = _result;
    setState(() => _result = null);
    var result = await widget.services.lookup.lookup(_plate, refresh: refresh);
    if (previous?.stolenCheck case final stolen?) {
      result = result.withStolenCheck(stolen);
    }
    if (!mounted || id != _lookupId) return;
    setState(() => _result = result);
    if (result.status != PlateStatus.error) {
      await widget.services.history.add(result);
    }
  }

  Future<void> _checkStolen() async {
    final outcome = await Navigator.push<StolenCheckOutcome>(
      context,
      MaterialPageRoute(builder: (_) => StolenCheckScreen(plate: _plate)),
    );
    final result = _result;
    if (outcome == null || result == null || !mounted) return;
    final updated = result.withStolenCheck(outcome);
    setState(() => _result = updated);
    await widget.services.history.add(updated);
  }

  void _say(String message) =>
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(message)));

  Future<void> _callPolice() => launchOrExplain(
    context,
    widget.services.report.callPolice,
    'לא ניתן לפתוח את החייגן. חייג 100 ידנית.',
  );

  Future<void> _openComplaint() => launchOrExplain(
    context,
    widget.services.report.openOnlineComplaint,
    'לא ניתן לפתוח את הדפדפן. היכנס ידנית לאתר המשטרה.',
  );

  /// Builds the report with the current location, then hands it to [send],
  /// which says whether it went through. Failures and a missing location are
  /// reported to the user.
  Future<void> _report(
    Future<bool> Function(VehicleResult result, Position? position) send,
  ) async {
    final result = _result;
    if (result == null || _sharing) return;
    setState(() => _sharing = true);
    try {
      final position = await widget.services.report.currentPosition();
      final sent = await send(result, position);
      if (sent && position == null && mounted) {
        _say('המיקום לא צורף לדיווח (שירותי המיקום כבויים או שאין הרשאה).');
      }
    } on Object {
      if (mounted) _say('הפעולה נכשלה. נסה שוב.');
    } finally {
      if (mounted) setState(() => _sharing = false);
    }
  }

  Future<void> _shareReport() => _report((result, position) async {
    // The OS may have cleared temporary files since the photos were taken.
    final photos = [
      for (final path in _photos)
        if (await File(path).exists()) path,
    ];
    final text = ReportService.buildReport(
      result,
      latitude: position?.latitude,
      longitude: position?.longitude,
      accuracyMeters: position?.accuracy,
      seenAt: widget.seenAt,
      photoCount: photos.length,
    );
    await widget.services.report.share(text, photos: photos);
    return true;
  });

  // SMS cannot carry the photos.
  Future<void> _smsPolice() => _report((result, position) async {
    final text = ReportService.buildReport(
      result,
      latitude: position?.latitude,
      longitude: position?.longitude,
      accuracyMeters: position?.accuracy,
      seenAt: widget.seenAt,
    );
    final ok = await widget.services.report.smsPolice(text);
    if (!ok && mounted) {
      _say('לא ניתן לפתוח את אפליקציית ההודעות. שלח SMS ל-052-2020100.');
    }
    return ok;
  });

  /// Corrects the plate in place and looks the new number up. The screen
  /// stays, so a scanner waiting underneath is not resumed, and the photos
  /// still belong to this screen.
  Future<void> _editPlate() async {
    final plate = await showDialog<String>(
      context: context,
      builder: (_) => _PlateEditDialog(initial: _plate),
    );
    if (plate == null || plate == _plate || !mounted) return;
    setState(() {
      _plate = plate;
      _result = null;
    });
    await _lookup();
  }

  void _removePhoto(String path) {
    setState(() => _photos.remove(path));
    if (widget.ownsPhotos) unawaited(widget.services.photos.delete([path]));
  }

  @override
  Widget build(BuildContext context) {
    final result = _result;
    return Scaffold(
      appBar: AppBar(
        title: const Text('תוצאת בדיקה'),
        actions: [
          IconButton(
            tooltip: 'תיקון מספר',
            icon: const Icon(Icons.edit),
            onPressed: _editPlate,
          ),
          IconButton(
            tooltip: 'בדוק שוב',
            icon: const Icon(Icons.refresh),
            onPressed: result == null
                ? null
                : () => unawaited(_lookup(refresh: true)),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Center(child: PlateBadge(_plate, fontSize: 36)),
          const SizedBox(height: 16),
          if (result == null)
            const Card(
              child: Padding(
                padding: EdgeInsets.all(24),
                child: Column(
                  children: [
                    CircularProgressIndicator(),
                    SizedBox(height: 12),
                    Text('בודק במאגרי משרד התחבורה...'),
                  ],
                ),
              ),
            )
          else ...[
            StatusCard(
              result,
              onRetry: () => unawaited(_lookup(refresh: true)),
            ),
            if (result.info case final info? when info.summary.isNotEmpty)
              VehicleCard(info),
            StolenCard(outcome: result.stolenCheck, onCheck: _checkStolen),
            ReportCard(
              urgent: result.needsReport,
              sharing: _sharing,
              photos: _photos,
              onCall: _callPolice,
              onShare: _shareReport,
              onSms: _smsPolice,
              onComplaint: _openComplaint,
              onGuide: () => unawaited(
                Navigator.push(
                  context,
                  MaterialPageRoute<void>(
                    builder: (_) =>
                        ReportGuideScreen(report: widget.services.report),
                  ),
                ),
              ),
              onViewPhoto: (path) => unawaited(showPhotoViewer(context, path)),
              onRemovePhoto: _removePhoto,
            ),
            const SizedBox(height: 8),
            // The data.gov.il licence requires naming the source.
            Text(
              'מקור המידע: משרד התחבורה והבטיחות בדרכים, באתר data.gov.il, '
              'כפי שהוא מתפרסם שם. אינו מהווה אישור רשמי.',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ],
      ),
    );
  }
}

/// Asks for a corrected number and stays open until it is a valid plate.
class _PlateEditDialog extends StatefulWidget {
  const _PlateEditDialog({required this.initial});

  final String initial;

  @override
  State<_PlateEditDialog> createState() => _PlateEditDialogState();
}

class _PlateEditDialogState extends State<_PlateEditDialog> {
  late final _controller = TextEditingController(text: widget.initial);
  String? _error;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _submit() {
    final error = plateNumberError(_controller.text);
    if (error != null) {
      setState(() => _error = error);
      return;
    }
    Navigator.pop(context, normalizePlate(_controller.text));
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('תיקון מספר'),
      content: PlateNumberField(
        controller: _controller,
        autofocus: true,
        errorText: _error,
        onChanged: (_) {
          if (_error != null) setState(() => _error = null);
        },
        onSubmitted: (_) => _submit(),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('ביטול'),
        ),
        FilledButton(onPressed: _submit, child: const Text('בדוק')),
      ],
    );
  }
}
