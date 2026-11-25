---
title: Set the permanent store app ID before the first Google Play upload
author: Aviel
date: 2026-11-20
standing: true
id: l-113f98ae
scope: repo
status: active
src: init-sessions
touches:
  - store/PLAY_STORE.md
---

## Decided
- The Play application ID cannot be changed after upload, so it was settled early. It uses a reverse-domain form that does not claim a domain the owner lacks.
- In the code: Current ID is com.aviel.lanzman.platescan, applied to the Android application ID and namespace and the iOS bundle identifier. See store/PLAY_STORE.md. Do not rename it after upload.

_From past Claude sessions here, Oct 20._
