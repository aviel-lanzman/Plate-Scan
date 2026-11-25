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
import 'package:plate_scan/screens/home_screen.dart';
import 'package:plate_scan/screens/history_screen.dart';
import 'package:plate_scan/screens/legal_doc_screen.dart';
import 'package:plate_scan/screens/report_guide_screen.dart';
import 'package:plate_scan/screens/stolen_check_screen.dart';
import 'package:plate_scan/screens/result_screen.dart';
import 'package:plate_scan/services/history_store.dart';
import 'package:plate_scan/services/vehicle_lookup_service.dart';
import 'package:plate_scan/widgets/plate_result_tile.dart';
import 'package:shared_preferences/shared_preferences.dart';

AppServices _services() => AppServices(
  lookup: VehicleLookupService(
    client: MockClient((request) async {
      final id = request.url.queryParameters['resource_id'];
      final records = id == '851ecab1-0622-4dbe-a6c7-f950cf82abf9'
          ? [
              <String, Object?>{
                'mispar_rechev': 7735636,
                'tozeret_nm': 'סיאט ספרד',
                'kinuy_mishari': 'TOLEDO',
                'bitul_dt': '2026-10-15',
              },
            ]
          : <Object?>[];
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

    await tester.tap(find.text('איך מדווחים למשטרה'));
    await tester.pumpAndSettle();
    expect(find.text('הרכב לפניך עכשיו? חייג 100'), findsOneWidget);
    expect(find.text('שמור תיעוד: שלח לעצמך בוואטסאפ'), findsOneWidget);
  });

  testWidgets('report guide fits at 200% text size', (tester) async {
    tester.view
      ..physicalSize = const Size(360 * 3, 640 * 3)
      ..devicePixelRatio = 3;
    tester.platformDispatcher.textScaleFactorTestValue = 2;
    addTearDown(tester.view.reset);
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);

    await tester.pumpWidget(
      _wrap(ReportGuideScreen(report: _services().report)),
    );
    await tester.scrollUntilVisible(find.text('מה לא לעשות'), 300);
    expect(find.text('מה לא לעשות'), findsOneWidget);
  });

  testWidgets('editing the plate keeps the route and looks up the new plate', (
    tester,
  ) async {
    final observer = _RouteCounter();
    final services = _services();
    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('he', 'IL'),
        supportedLocales: const [Locale('he', 'IL')],
        localizationsDelegates: GlobalMaterialLocalizations.delegates,
        navigatorObservers: [observer],
        home: Builder(
          builder: (context) => TextButton(
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute<void>(
                builder: (_) =>
                    ResultScreen(services: services, plate: '7735636'),
              ),
            ),
            child: const Text('open'),
          ),
        ),
      ),
    );
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
    expect(find.text('77-356-36'), findsOneWidget);
    final pushes = observer.pushes;

    await tester.tap(find.byTooltip('תיקון מספר'));
    await tester.pumpAndSettle();
    // An invalid number keeps the dialog open and says why.
    await tester.enterText(find.byType(TextField), '123');
    await tester.tap(find.text('בדוק'));
    await tester.pumpAndSettle();
    expect(find.text('יש להזין 4 עד 8 ספרות'), findsOneWidget);
    expect(find.text('תיקון מספר'), findsWidgets);

    await tester.enterText(find.byType(TextField), '1234567');
    await tester.tap(find.text('בדוק'));
    await tester.pumpAndSettle();

    expect(find.text('12-345-67'), findsOneWidget);
    expect(find.text('77-356-36'), findsNothing);
    expect(find.text('ירד מהכביש'), findsOneWidget);
    // Same route: nothing was replaced, pushed or popped.
    expect(observer.pushes, pushes);
    expect(observer.replaces, 0);
    expect(observer.pops, 0);
  });

  testWidgets('Back does not accept the first-run terms', (tester) async {
    await tester.pumpWidget(PlateScanApp(services: _services()));
    await tester.pumpAndSettle();
    expect(find.text('לפני שמתחילים'), findsOneWidget);

    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();

    expect(find.text('לפני שמתחילים'), findsOneWidget);
    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getBool('disclaimer_accepted_v2'), isNull);
  });

  testWidgets('home explains an invalid typed number', (tester) async {
    SharedPreferences.setMockInitialValues({'disclaimer_accepted_v2': true});
    await tester.pumpWidget(_wrap(HomeScreen(services: _services())));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), '123');
    await tester.tap(find.text('בדוק'));
    await tester.pumpAndSettle();
    expect(find.text('יש להזין 4 עד 8 ספרות'), findsOneWidget);
    expect(find.byType(ResultScreen), findsNothing);
  });

  testWidgets('a partial result says a source did not answer', (tester) async {
    final partial = VehicleResult(
      plate: '7735636',
      status: PlateStatus.active,
      checkedAt: DateTime(2026),
      partial: true,
    );
    await tester.pumpWidget(
      _wrap(
        ResultScreen(services: _services(), plate: '7735636', initial: partial),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.textContaining('אחד ממקורות המידע לא ענה'), findsOneWidget);
    expect(find.widgetWithText(OutlinedButton, 'בדוק שוב'), findsOneWidget);
  });

  testWidgets('a partial result fits at 200% text size', (tester) async {
    tester.view
      ..physicalSize = const Size(360 * 3, 640 * 3)
      ..devicePixelRatio = 3;
    tester.platformDispatcher.textScaleFactorTestValue = 2;
    addTearDown(tester.view.reset);
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);

    final partial = VehicleResult(
      plate: '7735636',
      status: PlateStatus.active,
      checkedAt: DateTime(2026),
      partial: true,
    );
    await tester.pumpWidget(
      _wrap(
        Scaffold(
          body: PlateResultTile(
            plate: '7735636',
            status: partial.status,
            partial: true,
            time: '10:00',
            onTap: () {},
          ),
        ),
      ),
    );
    expect(find.byIcon(Icons.info_outline), findsOneWidget);
    await tester.pumpWidget(
      _wrap(
        ResultScreen(services: _services(), plate: '7735636', initial: partial),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.textContaining('אחד ממקורות המידע לא ענה'), findsOneWidget);
  });

  test('Back leaves the stolen check from the police page itself', () {
    expect(isCheckPagePath('/apps/police/stolencar/'), isTrue);
    expect(isCheckPagePath('/apps/police/stolencar'), isTrue);
    expect(isCheckPagePath('/Apps/Police/StolenCar/results'), isTrue);
    expect(isCheckPagePath('/he/departments/israel_police'), isFalse);
    expect(isCheckPagePath('/apps/police/stolencars'), isFalse);
  });

  test('the stolen-check page only navigates within gov.il over https', () {
    expect(
      isAllowedMainFrameUrl('https://www.gov.il/apps/police/stolencar/'),
      isTrue,
    );
    expect(isAllowedMainFrameUrl('https://gov.il/he'), isTrue);
    expect(isAllowedMainFrameUrl('https://evil.example/gov.il'), isFalse);
    expect(isAllowedMainFrameUrl('https://notgov.il/'), isFalse);
    expect(isAllowedMainFrameUrl('http://www.gov.il/'), isFalse);
    expect(isAllowedMainFrameUrl('intent://x'), isFalse);
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

/// Counts page routes only, not the dialogs on top of them.
class _RouteCounter extends NavigatorObserver {
  int pushes = 0;
  int pops = 0;
  int replaces = 0;

  @override
  void didPush(Route<dynamic> route, Route<dynamic>? previousRoute) {
    if (route is PageRoute) pushes++;
  }

  @override
  void didPop(Route<dynamic> route, Route<dynamic>? previousRoute) {
    if (route is PageRoute) pops++;
  }

  @override
  void didReplace({Route<dynamic>? newRoute, Route<dynamic>? oldRoute}) =>
      replaces++;
}

class _BrokenHistory extends HistoryStore {
  @override
  Future<List<VehicleResult>> load() => Future.error(Exception('storage down'));
}
