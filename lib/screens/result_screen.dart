import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../app_services.dart';
import '../models/vehicle_result.dart';
import '../services/plate_parser.dart';
import '../services/report_service.dart';
import '../util/format.dart';
import '../widgets/plate_badge.dart';
import '../widgets/status_style.dart';
import 'stolen_check_screen.dart';

class ResultScreen extends StatefulWidget {
  const ResultScreen({
    super.key,
    required this.services,
    required this.plate,
    this.initial,
    this.photos = const [],
    this.seenAt,
  });

  final AppServices services;

  /// Digits only.
  final String plate;

  /// An existing result (from history or continuous mode) to show instead of
  /// looking the plate up again.
  final VehicleResult? initial;

  /// Photos taken while scanning, to attach to a report.
  final List<String> photos;

  /// When the camera read the plate; null for typed plates and history.
  final DateTime? seenAt;

  @override
  State<ResultScreen> createState() => _ResultScreenState();
}

class _ResultScreenState extends State<ResultScreen> {
  VehicleResult? _result;
  bool _sharing = false;
  late final _photos = [...widget.photos];

  @override
  void initState() {
    super.initState();
    _result = widget.initial;
    if (_result == null) _lookup();
  }

  Future<void> _lookup({bool refresh = false}) async {
    final previous = _result;
    setState(() => _result = null);
    var result = await widget.services.lookup.lookup(
      widget.plate,
      refresh: refresh,
    );
    if (previous?.stolenCheck case final stolen?) {
      result = result.withStolenCheck(stolen);
    }
    if (!mounted) return;
    setState(() => _result = result);
    if (result.status != PlateStatus.error) {
      await widget.services.history.add(result);
    }
  }

  Future<void> _checkStolen() async {
    final outcome = await Navigator.push<StolenCheckOutcome>(
      context,
      MaterialPageRoute(builder: (_) => StolenCheckScreen(plate: widget.plate)),
    );
    final result = _result;
    if (outcome == null || result == null || !mounted) return;
    final updated = result.withStolenCheck(outcome);
    setState(() => _result = updated);
    await widget.services.history.add(updated);
  }

  Future<void> _callPolice() async {
    final ok = await widget.services.report.callPolice();
    if (!ok && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('לא ניתן לפתוח את החייגן. חייג 100 ידנית.'),
        ),
      );
    }
  }

  Future<void> _shareReport() async {
    final result = _result;
    if (result == null) return;
    setState(() => _sharing = true);
    try {
      final position = await widget.services.report.currentPosition();
      // Temporary photos may have been purged since they were taken.
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
    } finally {
      if (mounted) setState(() => _sharing = false);
    }
  }

  Future<void> _editPlate() async {
    final plate = await showDialog<String>(
      context: context,
      builder: (_) => _PlateEditDialog(initial: widget.plate),
    );
    if (plate == null || !isValidPlate(plate) || !mounted) return;
    await Navigator.pushReplacement(
      context,
      MaterialPageRoute<void>(
        builder: (_) => ResultScreen(
          services: widget.services,
          plate: plate,
          // Same car, so the photos still apply after a typo fix.
          photos: _photos,
          seenAt: widget.seenAt,
        ),
      ),
    );
  }

  Future<void> _viewPhoto(String path) => showDialog<void>(
    context: context,
    builder: (context) => Dialog.fullscreen(
      backgroundColor: Colors.black,
      child: Stack(
        children: [
          Positioned.fill(
            child: InteractiveViewer(
              maxScale: 6,
              child: Image.file(File(path), fit: BoxFit.contain),
            ),
          ),
          SafeArea(
            child: IconButton(
              tooltip: 'סגור',
              color: Colors.white,
              icon: const Icon(Icons.close),
              onPressed: () => Navigator.pop(context),
            ),
          ),
        ],
      ),
    ),
  );

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
            onPressed: result == null ? null : () => _lookup(refresh: true),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Center(child: PlateBadge(widget.plate, fontSize: 36)),
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
            _StatusCard(result, onRetry: () => _lookup(refresh: true)),
            if (result.info case final info? when info.summary.isNotEmpty)
              _VehicleCard(info),
            _StolenCard(outcome: result.stolenCheck, onCheck: _checkStolen),
            _ReportCard(
              urgent: result.needsReport,
              sharing: _sharing,
              photos: _photos,
              onCall: _callPolice,
              onShare: _shareReport,
              onViewPhoto: _viewPhoto,
              onRemovePhoto: (path) => setState(() => _photos.remove(path)),
            ),
          ],
        ],
      ),
    );
  }
}

class _StatusCard extends StatelessWidget {
  const _StatusCard(this.result, {required this.onRetry});

  final VehicleResult result;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final status = result.status;
    final info = result.info;
    const white = TextStyle(color: Colors.white);
    return Card(
      color: status.color,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(status.icon, color: Colors.white, size: 36),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    status.label,
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(status.description, style: white),
            if (status == PlateStatus.offRoad && info?.cancelledOn != null)
              Text(
                'תאריך ביטול: ${formatIsoDate(info!.cancelledOn!)}',
                style: white,
              ),
            if (info?.licenseValidUntil case final until?)
              Text('תוקף רישיון הרכב: ${formatIsoDate(until)}', style: white),
            Text('נבדק: ${formatDateTime(result.checkedAt)}', style: white),
            if (status == PlateStatus.error)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.white,
                  ),
                  onPressed: onRetry,
                  icon: const Icon(Icons.refresh),
                  label: const Text('נסה שוב'),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _VehicleCard extends StatelessWidget {
  const _VehicleCard(this.info);

  final VehicleInfo info;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('ודא שהרכב שלפניך הוא:', style: theme.textTheme.titleSmall),
            const SizedBox(height: 4),
            Text(info.summary, style: theme.textTheme.headlineSmall),
            if (info.vehicleType case final type?) Text(type),
            const SizedBox(height: 8),
            Text(
              'אם הרכב שאתה רואה שונה, ייתכן שהמספר נקרא לא נכון או שהלוחית מזויפת.',
              style: theme.textTheme.bodySmall,
            ),
          ],
        ),
      ),
    );
  }
}

class _StolenCard extends StatelessWidget {
  const _StolenCard({required this.outcome, required this.onCheck});

  final StolenCheckOutcome? outcome;
  final VoidCallback onCheck;

  @override
  Widget build(BuildContext context) {
    final outcome = this.outcome;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('בדיקת גניבה', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 4),
            if (outcome == null)
              const Text(
                'הבדיקה נעשית באתר הרשמי של משטרת ישראל. המספר ימולא אוטומטית, ואתה לוחץ "בדוק רכב".',
              )
            else
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: Icon(outcome.icon, color: outcome.color, size: 32),
                title: Text(
                  outcome.label,
                  style: TextStyle(
                    color: outcome.color,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            const SizedBox(height: 8),
            OutlinedButton.icon(
              onPressed: onCheck,
              icon: const Icon(Icons.local_police),
              label: Text(outcome == null ? 'בדוק באתר המשטרה' : 'בדוק שוב'),
            ),
          ],
        ),
      ),
    );
  }
}

class _ReportCard extends StatelessWidget {
  const _ReportCard({
    required this.urgent,
    required this.sharing,
    required this.photos,
    required this.onCall,
    required this.onShare,
    required this.onViewPhoto,
    required this.onRemovePhoto,
  });

  final bool urgent;
  final bool sharing;
  final List<String> photos;
  final VoidCallback onCall;
  final VoidCallback onShare;
  final ValueChanged<String> onViewPhoto;
  final ValueChanged<String> onRemovePhoto;

  String get _shareLabel => switch (photos.length) {
    0 => 'שתף פרטי דיווח (כולל מיקום)',
    1 => 'שתף דיווח עם מיקום ותמונה',
    final n => 'שתף דיווח עם מיקום ו-$n תמונות',
  };

  @override
  Widget build(BuildContext context) {
    final red = Colors.red.shade700;
    return Card(
      shape: urgent
          ? RoundedRectangleBorder(
              side: BorderSide(color: red, width: 2),
              borderRadius: BorderRadius.circular(12),
            )
          : null,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'דיווח למשטרה',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 4),
            Text(
              urgent
                  ? 'אם הרכב בתנועה או חונה לידך, דווח למוקד 100 ומסור את המספר והמיקום. אל תתעמת עם הנהג.'
                  : 'אם יש לך חשד לגבי הרכב, אפשר לדווח למוקד 100.',
            ),
            const SizedBox(height: 12),
            FilledButton.icon(
              style: FilledButton.styleFrom(backgroundColor: red),
              onPressed: onCall,
              icon: const Icon(Icons.phone),
              label: const Text('התקשר 100'),
            ),
            if (photos.isNotEmpty) ...[
              const SizedBox(height: 12),
              Text(
                'תמונות מהסריקה',
                style: Theme.of(context).textTheme.titleSmall,
              ),
              const SizedBox(height: 4),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final (i, path) in photos.indexed)
                    _PhotoThumb(
                      path,
                      index: i + 1,
                      onTap: () => onViewPhoto(path),
                      onRemove: () => onRemovePhoto(path),
                    ),
                ],
              ),
            ],
            const SizedBox(height: 8),
            OutlinedButton.icon(
              onPressed: sharing ? null : onShare,
              icon: sharing
                  ? const SizedBox.square(
                      dimension: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.share),
              label: Text(_shareLabel),
            ),
            const SizedBox(height: 4),
            Text(
              photos.isEmpty
                  ? 'שתף רק עם המשטרה. אין לפרסם פרטי רכבים ברשתות החברתיות.'
                  : 'שתף רק עם המשטרה. אין לפרסם תמונות של רכבים או של אנשים ברשתות החברתיות. '
                        'טקסט הדיווח מועתק גם ללוח, למקרה שהאפליקציה שתבחר לא תצרף אותו לתמונות.',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ),
      ),
    );
  }
}

class _PhotoThumb extends StatelessWidget {
  const _PhotoThumb(
    this.path, {
    required this.index,
    required this.onTap,
    required this.onRemove,
  });

  final String path;
  final int index;
  final VoidCallback onTap;
  final VoidCallback onRemove;

  static const _size = 96.0;

  @override
  Widget build(BuildContext context) {
    final pixels = (_size * MediaQuery.devicePixelRatioOf(context)).round();
    return SizedBox.square(
      dimension: _size,
      child: Stack(
        fit: StackFit.expand,
        children: [
          Semantics(
            button: true,
            label: 'תמונה $index, הקש להגדלה',
            child: ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: InkWell(
                onTap: onTap,
                child: Image.file(
                  File(path),
                  fit: BoxFit.cover,
                  cacheWidth: pixels,
                  errorBuilder: (_, _, _) => const ColoredBox(
                    color: Colors.black12,
                    child: Icon(Icons.broken_image),
                  ),
                ),
              ),
            ),
          ),
          PositionedDirectional(
            top: 0,
            end: 0,
            child: IconButton.filledTonal(
              tooltip: 'הסר תמונה $index מהדיווח',
              visualDensity: VisualDensity.compact,
              iconSize: 18,
              icon: const Icon(Icons.close),
              onPressed: onRemove,
            ),
          ),
        ],
      ),
    );
  }
}

class _PlateEditDialog extends StatefulWidget {
  const _PlateEditDialog({required this.initial});

  final String initial;

  @override
  State<_PlateEditDialog> createState() => _PlateEditDialogState();
}

class _PlateEditDialogState extends State<_PlateEditDialog> {
  late final _controller = TextEditingController(text: widget.initial);

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('תיקון מספר'),
      content: TextField(
        controller: _controller,
        autofocus: true,
        keyboardType: TextInputType.number,
        textDirection: TextDirection.ltr,
        inputFormatters: [
          FilteringTextInputFormatter.digitsOnly,
          LengthLimitingTextInputFormatter(8),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('ביטול'),
        ),
        FilledButton(
          onPressed: () => Navigator.pop(context, _controller.text),
          child: const Text('בדוק'),
        ),
      ],
    );
  }
}
