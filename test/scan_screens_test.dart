import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:plate_scan/widgets/camera_error_view.dart';
import 'package:plate_scan/widgets/camera_view.dart';

void main() {
  testWidgets('error view offers retry, and settings only when given', (
    tester,
  ) async {
    var retries = 0;
    var settings = 0;
    Future<void> pump({VoidCallback? onOpenSettings}) => tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: CameraErrorView(
            message: 'שגיאה',
            onRetry: () => retries++,
            onOpenSettings: onOpenSettings,
          ),
        ),
      ),
    );

    await pump();
    expect(find.text('פתח הגדרות'), findsNothing);
    await tester.tap(find.text('נסה שוב'));
    expect(retries, 1);

    await pump(onOpenSettings: () => settings++);
    await tester.tap(find.text('פתח הגדרות'));
    expect(settings, 1);
    expect(retries, 1);
  });

  testWidgets('camera spinner is announced while the camera starts', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(home: Scaffold(body: CameraView(null))),
    );
    expect(find.bySemanticsLabel('מפעיל מצלמה'), findsOneWidget);
  });
}
