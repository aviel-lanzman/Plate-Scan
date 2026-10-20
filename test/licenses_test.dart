import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:plate_scan/util/licenses.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('native Android licences reach the licence page', () async {
    debugDefaultTargetPlatformOverride = TargetPlatform.android;
    addTearDown(() => debugDefaultTargetPlatformOverride = null);
    registerNativeLicenses();

    final entries = await LicenseRegistry.licenses.toList();
    final packages = {for (final e in entries) ...e.packages};
    expect(packages, contains('com.google.mlkit:text-recognition'));
    expect(packages, contains('androidx.camera:camera-core'));
    final apache = entries.firstWhere(
      (e) => e.packages.contains('androidx.camera:camera-camera2'),
    );
    expect(
      apache.paragraphs.map((p) => p.text).join('\n'),
      contains('Apache License'),
    );
  });
}
