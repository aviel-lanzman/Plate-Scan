---
title: Report photos are deleted when the screen closes and at every launch
author: Aviel
date: 2026-11-20
standing: true
id: l-1f470dac
scope: repo
status: active
src: init-sessions
touches:
  - lib/screens/result_screen.dart
  - lib/main.dart
  - lib/services/report_photos.dart
---

## Decided
- Photos of vehicles are sensitive. They were first left on disk until a 24-hour cleanup, so deletion was moved to the screen that owns them.
- In the code: The result screen (lib/screens/result_screen.dart) owns photos and deletes them on close or removal. lib/main.dart purges all at launch. Logic in lib/services/report_photos.dart. Photos leave the device only through the share sheet.

_From past Claude sessions here, Oct 20._
