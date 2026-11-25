---
title: "Dependency upgrades are done one at a time, because release builds can break silently and need a phone test"
author: Aviel
date: 2026-11-20
branch: master
cost: { minutes: 112, tokens: 508604 }
id: l-6218b9b0
scope: repo
status: active
src: agent
touches:
  - android/app/src/main/res/xml/data_extraction_rules.xml
  - android/app/src/main/AndroidManifest.xml
  - android/app/build.gradle.kts
  - docs/privacy-policy.html
  - store/PLAY_STORE.md
  - lib/services/history_store.dart
  - test/report_and_history_test.dart
  - analysis_options.yaml
  - lib/screens/continuous_scan_screen.dart
  - lib/main.dart
---

## Decided
- Only the text-recognition library (ML Kit) was moved to its new major version in the Nov 20 audit fixes. It was verified by analysis, tests and a release APK build, not on a phone, and its iOS side moved from CocoaPods to Swift Package Manager (iOS 15+), which was not built here.
- Saves to the check history run one after another so two alerts arriving together cannot overwrite each other. The queue belongs to the store object; the app creates exactly one store.

## Tried and ruled out
- A lockfile-wide upgrade (27 packages) was run and reverted. It moved the camera, JNI and shared-preferences plugins, the same ones whose class renaming once broke camera reading and history in release only. Without a phone to test on, that risk was not worth patch-level updates.
- geolocator's newest version does not resolve with the current SDK constraint, so it stayed.
- A single queue shared by every store (a static field) looked safer, but it carried a pending step from one widget test into the next: the fake clock of the finished test never completes it, so later tests timed out ("pumpAndSettle timed out", 30 s timeout) only when the whole file ran, never alone.

## Watch out
- After any plugin upgrade, test a release APK on a real phone: scan a plate, open the history, share a report.

In the code: pubspec.yaml (google_mlkit_text_recognition ^1.0.3), pubspec.lock. To undo the ML Kit upgrade restore those two files.
- An entry that cannot be read is skipped and the raw stored text is kept under a second key until the user clears the history; it is never restored automatically.

In the code: lib/services/history_store.dart (_queue, _serialised, history_v1_unreadable), test/report_and_history_test.dart.
