---
title: Release builds silently broke camera reading and history because the code shrinker renamed classes
author: Aviel
date: 2026-11-20
standing: true
id: l-24c905d4
scope: repo
status: active
src: init-sessions
touches:
  - android/app/proguard-rules.pro
---

## Watch out
- Debug builds worked, but in release the code shrinker renamed internal classes that ML Kit and the storage plugins look up by name. Every camera frame failed, and the history screen spun forever.
- In the code: Keep rules in android/app/proguard-rules.pro: ML Kit classes, shared_preferences_android and path_provider_android (JNI), plus kotlin.coroutines.**, kotlin.Result, kotlin.Result$Failure, kotlin.Unit. Always test a release APK on a real phone (flutter build apk --release --target-platform android-arm64), not only debug.

_From past Claude sessions here, Oct 20._
