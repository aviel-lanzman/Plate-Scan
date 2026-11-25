---
title: A plate is confirmed only after the same reading appears in 3 of 6 frames
author: Aviel
date: 2026-11-20
standing: true
id: l-aab540a7
scope: repo
status: active
src: init-sessions
touches:
  - lib/services/plate_parser.dart
  - test/plate_parser_test.dart
---

## Decided
- Single OCR frames misread plates, so a plate needs repeated agreement. This left users stuck when a plate was only read now and then. We added 'this is the number' and 'not the number' buttons.
- In the code: Logic in lib/services/plate_parser.dart: 7 or 8 digit plates, OCR fixes O->0, I->1, S->5, B->8, Z->2. The reject button ignores that reading for the rest of the scan. Tests in test/plate_parser_test.dart.

_From past Claude sessions here, Oct 20._
