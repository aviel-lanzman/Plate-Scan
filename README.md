# PlateScan

אפליקציית Flutter (אנדרואיד + iOS) שמזהה לוחית רישוי ישראלית דרך המצלמה ובודקת:

- **ירד מהכביש / לא פעיל / רישיון פג**: אוטומטית, מול מאגרי משרד התחבורה ב-[data.gov.il](https://data.gov.il) (API חינמי, בלי מפתח).
- **גנוב**: באתר הרשמי של משטרת ישראל (`gov.il/apps/police/stolencar`) בתוך WebView. המספר ממולא אוטומטית, והמשתמש לוחץ "בדוק רכב" (האתר מוגן ב-reCAPTCHA ואין API ציבורי).
- **דיווח**: כפתור חיוג ל-100, שיתוף דיווח עם מיקום GPS ועד 3 תמונות מהסריקה, SMS לקו המשטרה לבעלי מוגבלות שמיעה או דיבור, וקישור לתלונה המקוונת. אין דיווח אוטומטי: למשטרה אין API ואין קו וואטסאפ לדיווחים.

זיהוי הטקסט רץ על המכשיר (Google ML Kit, Latin). רק מספר הרישוי נשלח לבדיקה, וההיסטוריה נשמרת במכשיר בלבד. תמונות הסריקה נשמרות בתיקייה זמנית ונמחקות כשהמסך שצילם אותן נסגר (ובכל פתיחה של האפליקציה).

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
- `lib/services/report_service.dart`: חיוג, SMS, מיקום ושיתוף
- `lib/services/report_photos.dart`: שמירת הפריימים שבהם נקראה הלוחית כ-JPEG לדיווח

המידע אינו מהווה אישור לכך שרכב גנוב או לא. אין להשתמש בזמן נהיגה ואין להתעמת עם נהגים.

## אייקון והעלאה לחנות

- `assets/icon/`: מקורות האייקון. נוצרים עם `python3 tool/make_icons.py .`, ומתקינים באפליקציה עם `dart run flutter_launcher_icons`.
- `store/`: גרפיקה ל-Google Play, צילומי מסך (`tool/frame_shots.py`) ומדריך העלאה מלא: [store/PLAY_STORE.md](store/PLAY_STORE.md).
- `docs/`: מדיניות פרטיות, תנאי שימוש והצהרת נגישות. אותם קבצים מוצגים בתוך האפליקציה ומתארחים ב-GitHub Pages.
- `assets/licenses/android.txt`: רישיונות הספריות הנייטיב של אנדרואיד, שמוצגים במסך רישיונות הקוד הפתוח. אחרי שינוי בפלאגינים מריצים `JAVA_HOME=/snap/android-studio/current/jbr python3 tool/native_licenses.py`.
