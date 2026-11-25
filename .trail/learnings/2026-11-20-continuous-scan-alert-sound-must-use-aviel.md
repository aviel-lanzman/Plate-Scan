---
title: "Continuous scan alert sound must use the media stream, not system sound or notification"
author: Aviel
date: 2026-11-20
standing: true
id: l-ec9caba9
scope: repo
status: active
src: init-sessions
---

## Watch out
- The default system alert sound only plays on desktop, so phones were silent. The notification stream was then muted by silent and Do Not Disturb modes.
- In the code: Beep via a ToneGenerator on the media stream through a method channel in android/app/src/main/kotlin/il/aviel/plate_scan/MainActivity.kt. Other platforms fall back to SystemSound.

_From past Claude sessions here, Oct 20._
