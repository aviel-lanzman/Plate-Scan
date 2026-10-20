# PlateScan

אפליקציית Flutter (אנדרואיד + iOS) שמזהה לוחית רישוי ישראלית דרך המצלמה ובודקת:

- **ירד מהכביש / לא פעיל / רישיון פג**: אוטומטית, מול מאגרי משרד התחבורה ב-[data.gov.il](https://data.gov.il) (API חינמי, בלי מפתח).
- **גנוב**: באתר הרשמי של משטרת ישראל (`gov.il/apps/police/stolencar`) בתוך WebView. המספר ממולא אוטומטית, והמשתמש לוחץ "בדוק רכב" (האתר מוגן ב-reCAPTCHA ואין API ציבורי).
- **דיווח**: כפתור חיוג ל-100 ושיתוף טקסט דיווח עם מיקום GPS. אין דיווח אוטומטי.

זיהוי הטקסט רץ על המכשיר (Google ML Kit, Latin). רק מספר הרישוי נשלח לבדיקה, וההיסטוריה נשמרת במכשיר בלבד.

## מצבים

- **כוון וצלם**: סורק עד שמספר מאושר (3 מתוך 6 פריימים), מאפשר לתקן אותו ובודק.
- **סריקה רציפה**: לנוסע בלבד. בודק כל לוחית חדשה ומתריע ברטט, צליל ובאנר על רכב שירד מהכביש או לא פעיל.

## הרצה

```bash
flutter pub get
flutter test
flutter run            # מכשיר אנדרואיד מחובר או אמולטור
```

iOS: יעד מינימלי 15.5 (דרישת ML Kit). צריך Mac ו-`pod install`.

## מבנה

- `lib/services/plate_parser.dart`: חילוץ מספר מטקסט OCR, והצבעה בין פריימים
- `lib/services/vehicle_lookup_service.dart`: שאילתות data.gov.il ולוגיקת סטטוס
- `lib/services/plate_camera.dart`: זרם מצלמה ו-ML Kit
- `lib/screens/stolen_check_screen.dart`: WebView לאתר המשטרה
- `lib/services/report_service.dart`: חיוג, מיקום ושיתוף

המידע אינו מהווה אישור לכך שרכב גנוב או לא. אין להשתמש בזמן נהיגה ואין להתעמת עם נהגים.

## אייקון והעלאה לחנות

- `assets/icon/`: מקורות האייקון. נוצרים עם `python3 tool/make_icons.py .`, ומתקינים באפליקציה עם `dart run flutter_launcher_icons`.
- `store/`: גרפיקה ל-Google Play, צילומי מסך (`tool/frame_shots.py`) ומדריך העלאה מלא: [store/PLAY_STORE.md](store/PLAY_STORE.md).
- `docs/privacy-policy.html`: מדיניות הפרטיות, לאירוח ב-GitHub Pages.
