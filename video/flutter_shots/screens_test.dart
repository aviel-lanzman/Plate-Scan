// Renders app screens with demo data, as PNGs for the product video:
//
//   flutter test video/flutter_shots/screens_test.dart
//
// Writes to video/remotion/public/screens/. Not part of the normal test run.
import 'dart:convert';
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:plate_scan/app_services.dart';
import 'package:plate_scan/models/vehicle_result.dart';
import 'package:plate_scan/screens/result_screen.dart';

const _outDir = 'video/remotion/public/screens';
const _photos = [
  'video/remotion/public/photos/car-1.jpg',
  'video/remotion/public/photos/car-2.jpg',
  'video/remotion/public/photos/car-3.jpg',
];

// 98-765-43 is in none of the data.gov.il datasets, so the screens describe
// no real vehicle.
final _result = VehicleResult(
  plate: '9876543',
  status: PlateStatus.offRoad,
  checkedAt: DateTime(2026, 10, 21, 9, 41),
  info: const VehicleInfo(
    manufacturer: 'יונדאי קוריאה',
    model: 'I20',
    color: 'אפור מטאלי',
    year: 2012,
    vehicleType: 'פרטי',
    cancelledOn: '2026-08-03',
  ),
  stolenCheck: StolenCheckOutcome.stolen,
);

Future<ByteData> _font(String path) async =>
    ByteData.sublistView(await File(path).readAsBytes());

void main() {
  setUpAll(() async {
    // Heebo stands in for the device font, under the name Material uses.
    final heebo = FontLoader('Roboto');
    for (final weight in ['Regular', 'Medium', 'Bold', 'ExtraBold', 'Black']) {
      heebo.addFont(_font('video/assets/fonts/Heebo-$weight.ttf'));
    }
    await heebo.load();
    final flutterRoot = Platform.environment['FLUTTER_ROOT']!;
    await (FontLoader('MaterialIcons')..addFont(
          _font(
            '$flutterRoot/bin/cache/artifacts/material_fonts/MaterialIcons-Regular.otf',
          ),
        ))
        .load();
    await Directory(_outDir).create(recursive: true);
  });

  testWidgets('result screen, full length, with layout', (tester) async {
    // Tall enough for the whole list, so the video can scroll through one
    // image. The status bar is drawn by the video.
    tester.view
      ..physicalSize = const Size(1080, 3 * 1700)
      ..devicePixelRatio = 3;
    tester.platformDispatcher.platformBrightnessTestValue = Brightness.dark;
    addTearDown(tester.view.reset);
    addTearDown(tester.platformDispatcher.clearPlatformBrightnessTestValue);

    final boundary = GlobalKey();
    await tester.pumpWidget(
      RepaintBoundary(
        key: boundary,
        child: MaterialApp(
          debugShowCheckedModeBanner: false,
          locale: const Locale('he', 'IL'),
          supportedLocales: const [Locale('he', 'IL')],
          localizationsDelegates: GlobalMaterialLocalizations.delegates,
          theme: ThemeData(colorSchemeSeed: const Color(0xFF0038B8)),
          darkTheme: ThemeData(
            colorSchemeSeed: const Color(0xFF0038B8),
            brightness: Brightness.dark,
          ),
          home: ResultScreen(
            services: AppServices(),
            plate: _result.plate,
            initial: _result,
            photos: _photos,
            seenAt: DateTime(2026, 10, 21, 9, 40),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    // Photos load and decode in real time, but each step completes on the
    // fake test clock, so alternate real waits with frames until they are
    // painted. (Awaiting precacheImage inside runAsync deadlocks.)
    for (var i = 0; i < 8; i++) {
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 250)),
      );
      await tester.pump();
    }

    // Where things are, in image pixels, for the video to scroll and zoom to.
    Map<String, double> box(Finder finder) {
      final rect = tester.getRect(finder.first);
      return {
        'top': rect.top * 3,
        'bottom': rect.bottom * 3,
        'centerX': rect.center.dx * 3,
        'centerY': rect.center.dy * 3,
      };
    }

    Finder card(String text) =>
        find.ancestor(of: find.text(text), matching: find.byType(Card));
    final layout = {
      'appBarHeight': tester.getRect(find.byType(AppBar)).bottom * 3,
      'contentBottom':
          tester.getRect(find.textContaining('מקור המידע')).bottom * 3,
      'status': box(card('ירד מהכביש')),
      'vehicle': box(card('ודא שהרכב שלפניך הוא:')),
      'stolen': box(card('בדיקת גניבה')),
      'report': box(card('דיווח למשטרה')),
      'call': box(find.text('התקשר 100')),
      'photos': box(find.text('תמונות מהסריקה')),
      'share': box(find.textContaining('שתף דיווח')),
    };

    await tester.runAsync(() async {
      final render =
          boundary.currentContext!.findRenderObject()! as RenderRepaintBoundary;
      final image = await render.toImage(pixelRatio: 3);
      final png = await image.toByteData(format: ui.ImageByteFormat.png);
      await File('$_outDir/result_full.png')
          .writeAsBytes(png!.buffer.asUint8List());
      await File('$_outDir/result_layout.json')
          .writeAsString(const JsonEncoder.withIndent('  ').convert(layout));
    });
  });
}
