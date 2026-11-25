---
title: Stolen-car check stays semi-automatic because the police site has no public API
author: Aviel
date: 2026-11-20
standing: true
id: l-162c6d57
scope: repo
status: active
src: init-sessions
---

## Decided
- Only the official police site offers the stolen check and it is protected by reCAPTCHA. The off-road check uses the free open government data and is fully automatic.
- In the code: Off-road: GET https://data.gov.il/api/3/action/datastore_search with resource_id and filters {"mispar_rechev":N}, no API key. Stolen: open the police page in an in-app webview with the plate prefilled, and the user taps 'check vehicle'. Do not try to automate or scrape it.

_From past Claude sessions here, Oct 20._
