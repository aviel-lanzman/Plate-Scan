import 'package:flutter_test/flutter_test.dart';
import 'package:plate_scan/models/vehicle_result.dart';
import 'package:plate_scan/services/history_store.dart';
import 'package:plate_scan/services/report_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

VehicleResult _result(
  String plate, {
  PlateStatus status = PlateStatus.active,
}) => VehicleResult(
  plate: plate,
  status: status,
  checkedAt: DateTime(2026, 10, 20, 9, 5),
  info: const VehicleInfo(
    manufacturer: 'סיאט ספרד',
    model: 'TOLEDO',
    color: 'כחול פנינה',
    year: 2002,
    cancelledOn: '2026-10-15',
  ),
);

void main() {
  group('ReportService.buildReport', () {
    test('includes plate, status, vehicle, location and time', () {
      final text = ReportService.buildReport(
        _result(
          '7735636',
          status: PlateStatus.offRoad,
        ).withStolenCheck(StolenCheckOutcome.clean),
        latitude: 32.0853,
        longitude: 34.781768,
        accuracyMeters: 12.4,
        at: DateTime(2026, 10, 20, 9, 5),
      );
      expect(text, contains('מספר רישוי: 77-356-36'));
      expect(text, contains('ירד מהכביש (ביטול סופי מתאריך 15/10/2026)'));
      expect(text, contains('לא מופיע במאגר הרכבים הגנובים'));
      expect(text, contains('סיאט ספרד TOLEDO, כחול פנינה, 2002'));
      expect(text, contains('https://maps.google.com/?q=32.085300,34.781768'));
      expect(text, contains('±12'));
      expect(text, contains('20/10/2026 09:05'));
    });

    test('includes when the car was seen and the attached photos', () {
      final text = ReportService.buildReport(
        _result('7735636', status: PlateStatus.offRoad),
        seenAt: DateTime(2026, 10, 20, 9, 1),
        photoCount: 3,
        at: DateTime(2026, 10, 20, 9, 5),
      );
      expect(text, contains('הרכב נצפה: 20/10/2026 09:01'));
      expect(text, contains('זמן הדיווח: 20/10/2026 09:05'));
      expect(text, contains('מצורפות 3 תמונות מהסריקה'));
    });

    test('omits location when unavailable', () {
      final text = ReportService.buildReport(
        _result('1234567'),
        at: DateTime(2026, 10, 20),
      );
      expect(text, isNot(contains('מיקום')));
      expect(text, contains('בדיקת גניבה באתר המשטרה: לא נבדק'));
    });
  });

  group('HistoryStore', () {
    setUp(() => SharedPreferences.setMockInitialValues({}));

    test('adds newest first and replaces the same plate', () async {
      final store = HistoryStore();
      await store.add(_result('1111111'));
      await store.add(_result('2222222'));
      await store.add(_result('1111111', status: PlateStatus.offRoad));
      final entries = await store.load();
      expect(entries.map((e) => e.plate), ['1111111', '2222222']);
      expect(entries.first.status, PlateStatus.offRoad);
    });

    test('caps the number of entries', () async {
      final store = HistoryStore();
      for (var i = 0; i < HistoryStore.maxEntries + 5; i++) {
        await store.add(_result('${1000000 + i}'));
      }
      expect(await store.load(), hasLength(HistoryStore.maxEntries));
    });

    test('clear and corrupt data', () async {
      final store = HistoryStore();
      await store.add(_result('1111111'));
      await store.clear();
      expect(await store.load(), isEmpty);

      SharedPreferences.setMockInitialValues({'history_v1': 'not json'});
      expect(await HistoryStore().load(), isEmpty);
    });
  });
}
