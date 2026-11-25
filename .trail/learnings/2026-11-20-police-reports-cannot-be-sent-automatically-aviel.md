---
title: "Police reports cannot be sent automatically: no WhatsApp line or API exists"
author: Aviel
date: 2026-11-20
standing: true
id: l-18929981
scope: repo
status: active
src: init-sessions
touches:
  - lib/screens/result_screen.dart
  - lib/services/report_service.dart
---

## Tried and ruled out
- Research showed the police offer no WhatsApp channel or API for reports. The app therefore says so and offers the best available routes, so the idea of auto-sending photos to the police was dropped.
- In the code: Report card in lib/screens/result_screen.dart and lib/services/report_service.dart: call 100 (not 110) for urgent cases, SMS to the police line with location for people with hearing or speech disabilities, and the official online complaint link for non-urgent reports. Photos go only through the share sheet.

_From past Claude sessions here, Oct 20._
