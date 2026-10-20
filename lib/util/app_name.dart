import 'dart:ui';

/// The app's display name, matching the launcher label: Hebrew when the
/// device language is Hebrew (reported as "he" or the legacy "iw").
String appName([Locale? deviceLocale]) {
  final code =
      (deviceLocale ?? PlatformDispatcher.instance.locale).languageCode;
  return code == 'he' || code == 'iw' ? 'סורק לוחיות' : 'PlateScan';
}
