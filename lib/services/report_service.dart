import 'package:flutter/services.dart';
import 'package:geolocator/geolocator.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';

import '../models/vehicle_result.dart';
import '../util/format.dart';
import 'plate_parser.dart';

/// Reporting is always user-initiated: the police have no public API and no
/// WhatsApp line for reports, so the app dials 100, opens an SMS to the line
/// for deaf and speech-impaired people, or hands a prepared text and the
/// photos taken while scanning to the share sheet.
class ReportService {
  static final policeNumber = Uri(scheme: 'tel', path: '100');

  /// The police SMS line, for people with hearing or speech disabilities
  /// only (listed on gov.il under the 110 information centre).
  static const deafSmsNumber = '0522020100';

  /// Online complaint form; not for emergencies.
  static final onlineComplaint = Uri.parse(
    'https://www.gov.il/he/service/request-file-complaint-online-during-emergency',
  );

  Future<bool> callPolice() => launchUrl(policeNumber);

  // Uri(queryParameters:) encodes spaces as '+', which SMS apps show as is.
  Future<bool> smsPolice(String text) => launchUrl(
    Uri.parse('sms:$deafSmsNumber?body=${Uri.encodeComponent(text)}'),
  );

  Future<bool> openOnlineComplaint() =>
      launchUrl(onlineComplaint, mode: LaunchMode.externalApplication);

  /// Best-effort location; null if unavailable or denied.
  Future<Position?> currentPosition() async {
    try {
      if (!await Geolocator.isLocationServiceEnabled()) return null;
      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        return null;
      }
      return await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          timeLimit: Duration(seconds: 10),
        ),
      );
    } on Object {
      return null;
    }
  }

  /// Shares [text] with [photos] attached. Some apps drop the text when
  /// files are attached, so it is also copied to the clipboard then.
  Future<void> share(String text, {List<String> photos = const []}) async {
    if (photos.isNotEmpty) {
      await Clipboard.setData(ClipboardData(text: text));
    }
    await SharePlus.instance.share(
      ShareParams(
        text: text,
        files: photos.isEmpty
            ? null
            : [for (final path in photos) XFile(path, mimeType: 'image/jpeg')],
      ),
    );
  }

  static String buildReport(
    VehicleResult result, {
    double? latitude,
    double? longitude,
    double? accuracyMeters,
    DateTime? seenAt,
    int photoCount = 0,
    DateTime? at,
  }) {
    final info = result.info;
    final lines = <String>[
      'דיווח על רכב חשוד',
      'מספר רישוי: ${formatPlate(result.plate)}',
      'סטטוס במשרד התחבורה: ${result.status.label}'
          '${result.status == PlateStatus.offRoad && info?.cancelledOn != null ? ' (ביטול סופי מתאריך ${formatIsoDate(info!.cancelledOn!)})' : ''}',
      'בדיקת גניבה באתר המשטרה: ${result.stolenCheck?.label ?? 'לא נבדק'}',
      if (info != null && info.summary.isNotEmpty)
        'פרטי הרכב הרשומים: ${info.summary}',
      if (latitude != null && longitude != null)
        'מיקום: https://maps.google.com/?q=${latitude.toStringAsFixed(6)},${longitude.toStringAsFixed(6)}'
            '${accuracyMeters != null ? ' (דיוק ±${accuracyMeters.round()} מ\')' : ''}',
      if (seenAt != null) 'הרכב נצפה: ${formatDateTime(seenAt)}',
      'זמן הדיווח: ${formatDateTime(at ?? DateTime.now())}',
      if (photoCount == 1) 'מצורפת תמונה מהסריקה',
      if (photoCount > 1) 'מצורפות $photoCount תמונות מהסריקה',
      'מקור: מאגרי משרד התחבורה ב-data.gov.il',
    ];
    return lines.join('\n');
  }
}
