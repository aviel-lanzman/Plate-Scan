import 'dart:io';

import 'package:flutter/material.dart';

/// Runs a launch action (call, browser, SMS) and says so in a SnackBar when
/// it fails or cannot open anything, instead of leaving the user guessing.
Future<void> launchOrExplain(
  BuildContext context,
  Future<bool> Function() launch,
  String failure,
) async {
  var ok = false;
  try {
    ok = await launch();
  } on Object {
    // Reported below like any other failure to open.
  }
  if (!ok && context.mounted) {
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(failure)));
  }
}

/// How to report the vehicle to the police: call, share a record, online
/// complaint or SMS, plus the scan photos that go with the record.
class ReportCard extends StatelessWidget {
  const ReportCard({
    super.key,
    required this.urgent,
    required this.sharing,
    required this.photos,
    required this.onCall,
    required this.onShare,
    required this.onSms,
    required this.onComplaint,
    required this.onGuide,
    required this.onViewPhoto,
    required this.onRemovePhoto,
  });

  final bool urgent;
  final bool sharing;
  final List<String> photos;
  final VoidCallback onCall;
  final VoidCallback onShare;
  final VoidCallback onSms;
  final VoidCallback onComplaint;
  final VoidCallback onGuide;
  final ValueChanged<String> onViewPhoto;
  final ValueChanged<String> onRemovePhoto;

  // The location is attached only when it could be read, so the label does
  // not promise it.
  String get _shareLabel => switch (photos.length) {
    0 => 'שתף פרטי דיווח',
    1 => 'שתף דיווח עם תמונה',
    final n => 'שתף דיווח עם $n תמונות',
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
                  ? 'אם הרכב לפניך עכשיו, חייג 100 ומסור את המספר, המיקום, כיוון הנסיעה ותיאור הרכב. אל תתעמת עם הנהג ואל תרדוף אחריו.'
                  : 'אם יש לך חשד לגבי הרכב, אפשר לדווח למוקד 100.',
            ),
            const SizedBox(height: 12),
            FilledButton.icon(
              // White on red in both themes; the default dark-theme
              // foreground is a dark blue that is unreadable on red.
              style: FilledButton.styleFrom(
                backgroundColor: red,
                foregroundColor: Colors.white,
              ),
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
              'לתיעוד, לחץ "שתף" ובחר בוואטסאפ את הצ\'אט עם עצמך. '
              'המיקום מצורף אם שירותי המיקום פעילים. '
              'למשטרה אין קו וואטסאפ לדיווחים, אבל התיעוד ישמש אותך אם המשטרה תבקש פרטים'
              '${photos.isEmpty ? '' : ' או תמונות'}, או לתלונה מקוונת. אל תפרסם אותו ברשתות החברתיות.'
              '${photos.isEmpty ? '' : ' טקסט הדיווח מועתק גם ללוח, למקרה שהאפליקציה שתבחר לא תצרף אותו לתמונות.'}',
              style: Theme.of(context).textTheme.bodySmall,
            ),
            const SizedBox(height: 8),
            TextButton.icon(
              onPressed: onGuide,
              icon: const Icon(Icons.help_outline),
              label: const Text('איך מדווחים למשטרה?'),
            ),
            TextButton.icon(
              onPressed: onComplaint,
              icon: const Icon(Icons.open_in_new),
              label: const Text('תלונה מקוונת באתר המשטרה (לא לחירום)'),
            ),
            TextButton.icon(
              onPressed: sharing ? null : onSms,
              icon: const Icon(Icons.sms_outlined),
              label: const Text('SMS למשטרה, לבעלי מוגבלות שמיעה או דיבור'),
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

  // Three fit side by side in the report card on a 360dp-wide phone.
  static const _size = 88.0;

  @override
  Widget build(BuildContext context) {
    final pixels = (_size * MediaQuery.devicePixelRatioOf(context)).round();
    final scheme = Theme.of(context).colorScheme;
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
                  errorBuilder: (_, _, _) => ColoredBox(
                    color: scheme.surfaceContainerHighest,
                    child: Icon(
                      Icons.broken_image,
                      color: scheme.onSurfaceVariant,
                    ),
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
