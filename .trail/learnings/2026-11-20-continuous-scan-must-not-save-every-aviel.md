---
title: "Continuous scan must not save every passing car to history, for privacy"
author: Aviel
date: 2026-11-20
standing: true
id: l-7c3148c6
scope: repo
status: active
src: init-sessions
touches:
  - lib/screens/continuous_scan_screen.dart
  - lib/services/report_service.dart
---

## Decided
- Saving every car seen would keep data on bystanders. Reports are also worded neutrally so a misread plate does not read as an accusation.
- In the code: In lib/screens/continuous_scan_screen.dart, save only vehicles that raised an alert or that the user opened. The report in lib/services/report_service.dart is titled 'vehicle details for police check' and states it does not establish an offence.

_From past Claude sessions here, Oct 20._
