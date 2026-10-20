import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:plate_scan/app_services.dart';
import 'package:plate_scan/main.dart';
import 'package:plate_scan/models/vehicle_result.dart';
import 'package:plate_scan/screens/history_screen.dart';
import 'package:plate_scan/screens/legal_doc_screen.dart';
import 'package:plate_scan/screens/result_screen.dart';
import 'package:plate_scan/services/history_store.dart';
import 'package:plate_scan/services/vehicle_lookup_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

AppServices _services() => AppServices(
  lookup: VehicleLookupService(
    client: MockClient((request) async {
      final id = request.url.queryParameters['resource_id'];
      final records = id == '851ecab1-0622-4dbe-a6c7-f950cf82abf9'
          ? [
              {
                'mispar_rechev': 7735636,
                'tozeret_nm': 'סיאט ספרד',
                'kinuy_mishari': 'TOLEDO',
                'bitul_dt': '2026-10-15',
              },
            ]
          : [];
      return http.Response.bytes(
        utf8.encode(
          jsonEncode({
            'success': true,
            'result': {'records': records},
          }),
        ),
        200,
      );
    }),
  ),
  history: HistoryStore(),
);

Widget _wrap(Widget child) => MaterialApp(
  locale: const Locale('he', 'IL'),
  supportedLocales: const [Locale('he', 'IL')],
  localizationsDelegates: GlobalMaterialLocalizations.delegates,
  home: child,
);

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  testWidgets('home shows the disclaimer once, then the modes', (tester) async {
    await tester.pumpWidget(PlateScanApp(services: _services()));
    await tester.pumpAndSettle();
    expect(find.text('לפני שמתחילים'), findsOneWidget);

    await tester.tap(find.text('מסכים'));
    await tester.pumpAndSettle();
    expect(find.text('כוון וצלם'), findsOneWidget);
    expect(find.text('סריקה רציפה'), findsOneWidget);

    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getBool('disclaimer_accepted_v2'), isTrue);
  });

  testWidgets('result screen shows an off-road vehicle and saves it', (
    tester,
  ) async {
    final services = _services();
    await tester.pumpWidget(
      _wrap(ResultScreen(services: services, plate: '7735636')),
    );
    await tester.pumpAndSettle();

    expect(find.text('77-356-36'), findsOneWidget);
    expect(find.text('ירד מהכביש'), findsOneWidget);
    expect(find.text('סיאט ספרד TOLEDO'), findsOneWidget);
    await tester.scrollUntilVisible(find.text('התקשר 100'), 200);
    expect(find.text('התקשר 100'), findsOneWidget);

    final history = await services.history.load();
    expect(history.single.plate, '7735636');
  });

  testWidgets('history shows an error instead of spinning forever', (
    tester,
  ) async {
    await tester.pumpWidget(
      _wrap(HistoryScreen(services: AppServices(history: _BrokenHistory()))),
    );
    await tester.pumpAndSettle();
    expect(find.text('לא ניתן לטעון את ההיסטוריה'), findsOneWidget);
    expect(find.byType(CircularProgressIndicator), findsNothing);
  });

  // Android allows font scaling up to 200%; overflow errors fail the test.
  testWidgets('screens fit a small phone at 200% text size', (tester) async {
    tester.view
      ..physicalSize = const Size(360 * 3, 640 * 3)
      ..devicePixelRatio = 3;
    tester.platformDispatcher.textScaleFactorTestValue = 2;
    addTearDown(tester.view.reset);
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);

    final services = _services();
    await tester.pumpWidget(PlateScanApp(services: services));
    await tester.pumpAndSettle();
    await tester.tap(find.text('מסכים'));
    await tester.pumpAndSettle();

    await tester.scrollUntilVisible(find.byType(TextField), 200);
    await tester.enterText(find.byType(TextField), '7735636');
    await tester.testTextInput.receiveAction(TextInputAction.done);
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(
      find.text('SMS למשטרה, לבעלי מוגבלות שמיעה או דיבור'),
      200,
      scrollable: find.byType(Scrollable).last,
    );

    await tester.tap(find.byType(BackButton));
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(
      find.text('היסטוריית בדיקות'),
      200,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.tap(find.text('היסטוריית בדיקות'));
    await tester.pumpAndSettle();
    expect(find.text('ירד מהכביש'), findsOneWidget);
  });

  testWidgets('about lists the bundled legal documents', (tester) async {
    SharedPreferences.setMockInitialValues({'disclaimer_accepted_v2': true});
    await tester.pumpWidget(PlateScanApp(services: _services()));
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('מידע ותנאי שימוש'));
    await tester.pumpAndSettle();

    for (final doc in LegalDoc.values) {
      expect(find.text(doc.title), findsOneWidget);
      final html = await rootBundle.loadString(doc.asset);
      expect(html, contains('<html lang="he" dir="rtl">'));
    }
    expect(find.text('רישיונות קוד פתוח'), findsOneWidget);
  });

  test('a failed save does not throw', () async {
    await _BrokenHistory().add(
      VehicleResult(
        plate: '1234567',
        status: PlateStatus.active,
        checkedAt: DateTime(2026),
      ),
    );
  });
}

class _BrokenHistory extends HistoryStore {
  @override
  Future<List<VehicleResult>> load() => Future.error(Exception('storage down'));
}
