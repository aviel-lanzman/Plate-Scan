---
title: "Play Console answers: online content declared, testers list starts with the owner only, pushes go over SSH"
author: Aviel
date: 2026-11-25
branch: master
cost: { minutes: 61, tokens: 509223 }
id: l-d7beeae4
scope: repo
status: active
src: agent
touches:
  - analysis_options.yaml
  - lib/main.dart
  - lib/screens/continuous_scan_screen.dart
  - lib/screens/plate_camera_host.dart
  - lib/screens/single_scan_screen.dart
  - lib/services/plate_camera.dart
  - lib/widgets/camera_error_view.dart
  - lib/widgets/camera_view.dart
  - test/scan_screens_test.dart
  - lib/screens/history_screen.dart
---

## Decided
- The content rating questionnaire answers "Online content: Yes", because the app shows vehicle data fetched from data.gov.il and embeds the police website. Every follow-up (violence, sexuality, language, drugs, age-restricted goods, location sharing, purchases, rewards, browser, news) is No. The rating came out "all ages".
- Data safety declares only what ML Kit sends: Device or other IDs and Diagnostics, collected, not shared, not ephemeral, required, purpose Analytics, encrypted in transit, no deletion request.
- The closed test targets Israel only. Its tester list starts with the developer's own address; real testers are added by the owner.
- GitHub Pages serves the legal documents from the master branch, /docs folder.

## Tried and ruled out
- Answering No to online content, as the store guide first said: the app's main output is data that is not in the package, so a reviewer could call that a misrepresentation.
- git push over HTTPS from the agent's shell: there is no credential helper, so it fails asking for a username. The SSH key for the aviel-lanzman account works.

## Watch out
- The Play Console app ID is 4975693388759217953 under developer account 6674718244686998441 (Lanzman Studio, signed in as the second Google account, /u/1/). The first account (/u/0/) has no developer account.
- A personal account needs 12 opted-in testers for 14 consecutive days before production access can be requested.

In the code: store/PLAY_STORE.md (Content rating section updated). Push with: git push git@github.com:aviel-lanzman/Plate-Scan.git master
