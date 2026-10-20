import 'package:geolocator/geolocator.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';

import '../models/vehicle_result.dart';
import '../util/format.dart';
import 'plate_parser.dart';

/// Reporting is always user-initiated: there is no public API for filing a
/// police report, so the app dials 100 or hands a prepared text to the share
/// sheet.
class ReportService {
  static final policeNumber = Uri(scheme: 'tel', path: '100');

  Future<bool> callPolice() => launchUrl(policeNumber);

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

  Future<void> share(String text) =>
      SharePlus.instance.share(ShareParams(text: text));

  static String buildReport(
    VehicleResult result, {
    double? latitude,
    double? longitude,
    double? accuracyMeters,
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
      'זמן: ${formatDateTime(at ?? DateTime.now())}',
      'מקור: מאגרי משרד התחבורה ב-data.gov.il',
    ];
    return lines.join('\n');
  }
}
