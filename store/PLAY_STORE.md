# העלאה ל-Google Play

## מה כבר מוכן בפרויקט

| קובץ | מה זה |
|---|---|
| `store/play_icon_512.png` | אייקון לחנות (512×512) |
| `store/feature_graphic_1024x500.png` | תמונה ראשית (Feature graphic) |
| `store/screenshots/` | צילומי מסך לטלפון (1080×1920) |
| `docs/privacy-policy.html` | מדיניות פרטיות, בעברית ובאנגלית |
| `docs/terms.html` | תנאי שימוש, בעברית ובאנגלית |
| `docs/accessibility.html` | הצהרת נגישות, בעברית ובאנגלית |
| `android/key.properties.example` | תבנית לפרטי מפתח החתימה |

- **מזהה האפליקציה:** `il.aviel.plate_scan`. אי אפשר לשנות אותו אחרי ההעלאה הראשונה.
- **גרסה:** `1.0.0+1` (ב-`pubspec.yaml`). בכל העלאה חדשה צריך להעלות את המספר שאחרי ה-`+`.
- **targetSdk:** 36, כפי שגוגל פליי דורש.

## שלבים

### 1. מפתח העלאה (פעם אחת)

את המפתח והסיסמה יוצרים בעצמך. אל תשתף אותם עם אף אחד.

```bash
mkdir -p ~/keys
/snap/android-studio/current/jbr/bin/keytool -genkey -v \
  -keystore ~/keys/platescan-upload.jks \
  -keyalg RSA -keysize 2048 -validity 10000 -alias upload
cp android/key.properties.example android/key.properties
# ערוך את android/key.properties והכנס את הסיסמאות שבחרת
```

- **גיבוי:** שמור עותק של קובץ ה-`.jks` ושל הסיסמה במקום בטוח מחוץ למחשב, למשל במנהל סיסמאות. בלעדיהם אי אפשר לעדכן את האפליקציה בחנות, אלא אם מבקשים מגוגל איפוס מפתח, תהליך שלוקח זמן.
- **git:** הקבצים `key.properties` ו-`*.jks` כבר נמצאים ב-`.gitignore`.
- **טלפון:** אחרי החתימה במפתח החדש, ההתקנה בטלפון שלך תדרוש קודם להסיר את הגרסה הנוכחית, שחתומה במפתח debug. ההיסטוריה תימחק.

### 2. בניית הקובץ להעלאה

```bash
flutter build appbundle --release
# הקובץ: build/app/outputs/bundle/release/app-release.aab
```

אם `android/key.properties` חסר, הבילד ייחתם במפתח debug ו-Play ידחה אותו.

### בדיקה לפני כל העלאה

גרסת release מכווצת את הקוד (R8), ושלוש תקלות הופיעו רק בה ולא בדיבאג: זיהוי המצלמה, שמירת ההיסטוריה וחלון הפתיחה. לכן לפני כל העלאה כדאי להתקין גרסת release על הטלפון ולבדוק את הפעולות העיקריות:

```bash
flutter build apk --release --target-platform android-arm64
adb install -r build/app/outputs/flutter-apk/app-release.apk
```

בדוק: כוון וצלם, סריקה רציפה (כולל צליל ההתרעה), הקלדת מספר, בדיקת גניבה, היסטוריה, שיתוף דיווח עם תמונות (שהתמונות עומדות נכון ושהטקסט מצורף), כפתור ה-SMS, המסמכים במסך "מידע ותנאי שימוש", ושהחלון "לפני שמתחילים" לא חוזר בכל פתיחה.

וודא שלא נשאר `YOUR_EMAIL` במסמכים, כי הם מוצגים גם בתוך האפליקציה:

```bash
grep -l YOUR_EMAIL docs/*.html   # צריך להחזיר כלום
```

הכללים שמונעים את התקלות האלה נמצאים ב-`android/app/proguard-rules.pro`. פלאגין חדש שקורא לקוד native דרך JNI עלול לדרוש כלל נוסף שם.

### 3. מדיניות הפרטיות בכתובת ציבורית

1. החלף את `YOUR_EMAIL` בכתובת המייל שלך בשלושת המסמכים ב-`docs/` (מדיניות פרטיות, תנאי שימוש, הצהרת נגישות). הכתובת תהיה ציבורית, ותופיע גם בתוך האפליקציה.
2. העלה את הפרויקט ל-GitHub, ובהגדרות הריפו בחר **Pages** ← Branch `main`, תיקייה `/docs`.
3. הכתובת תהיה `https://<username>.github.io/<repo>/privacy-policy.html`. תנאי השימוש והצהרת הנגישות יהיו לידה (`terms.html`, `accessibility.html`).

### 4. Play Console

1. **חשבון מפתח:** פותחים ב-https://play.google.com/console. יש תשלום חד-פעמי של 25$ ואימות זהות.
2. **בדיקה סגורה בחשבון אישי חדש:** לפי הכללים הנוכחיים שאני מכיר, חשבון כזה חייב להריץ בדיקה סגורה (Closed testing) עם לפחות 12 בודקים, ברצף של 14 ימים, לפני שמותר לפרסם בייצור (Production). כדאי לוודא את הדרישה העדכנית בקונסול.
3. **יצירת האפליקציה:** Create app, שפת ברירת מחדל עברית (`he-IL`), App, Free.
4. **מילוי הסעיפים:** לפי הטקסטים בהמשך.
5. **העלאה:** מעלים את ה-`.aab` ל-Closed testing. בהעלאה הראשונה מאשרים Play App Signing: גוגל שומרת את מפתח החתימה הסופי, ואתה מחזיק רק את מפתח ההעלאה.

## דף החנות

### עברית (he-IL)

**שם** (23/30):
```
סורק לוחיות – בדיקת רכב
```

**תיאור קצר** (75/80):
```
סרוק לוחית רישוי ובדוק אם הרכב ירד מהכביש או דווח כגנוב. חינם, בלי פרסומות.
```

**תיאור מלא:**
```
סורק לוחיות מזהה לוחית רישוי ישראלית דרך המצלמה ובודק במאגרי המידע הציבוריים מה מצב הרכב.

מה האפליקציה בודקת:
• ירד מהכביש: רכב בסטטוס "ביטול סופי" שאסור לו לנסוע בכביש
• רכב לא פעיל
• רישיון רכב שפג תוקפו
• פרטי הרכב הרשומים (יצרן, דגם, צבע ושנה), כדי לוודא שהלוחית מתאימה לרכב שלפניך. אם הם לא מתאימים, ייתכן שהלוחית מזויפת.
• בדיקת גניבה באתר הרשמי של משטרת ישראל: המספר ממולא אוטומטית, ואתה לוחץ "בדוק רכב".

שני מצבי סריקה:
• כוון וצלם: בדיקה מלאה של רכב אחד
• סריקה רציפה: בודקת כל לוחית שנקלטת ומתריעה ברטט, צליל ובאנר על רכב שירד מהכביש. לנוסעים בלבד, לא בזמן נהיגה.

דיווח:
כפתור חיוג ל-100, ושיתוף דיווח מוכן בלחיצה אחת: מספר, פרטי רכב, מיקום, שעה ותמונות שהמצלמה קלטה בזמן הסריקה. לבעלי מוגבלות שמיעה או דיבור: SMS מוכן לקו הייעודי של המשטרה. אין דיווח אוטומטי: אתה בוחר למי לשלוח.

פרטיות:
זיהוי הלוחית מתבצע במכשיר. רק מספר הרישוי נשלח לבדיקה. ההיסטוריה ותמונות הסריקה נשמרות במכשיר בלבד, והתמונות נמחקות כשמסיימים. אין חשבונות ואין פרסומות. ספריית זיהוי הטקסט של Google שולחת רק נתוני אבחון טכניים, כמפורט במדיניות הפרטיות.

מקורות המידע:
• כלי רכב שירדו מהכביש: https://data.gov.il/dataset/reshev_bitul_sofi
• מספרי רישוי של כלי רכב: https://data.gov.il/dataset/private-and-commercial-vehicles
• כלי רכב לא פעילים: https://data.gov.il/dataset/rechev_le_pail_with_degem
• בדיקת רכב גנוב, משטרת ישראל: https://www.gov.il/he/service/licence_plate_stolen_vehicle_identification

חשוב:
האפליקציה אינה קשורה למשטרת ישראל, למשרד התחבורה או לכל גוף ממשלתי אחר, ואינה אפליקציה רשמית. המידע אינו מהווה אישור לכך שרכב גנוב או לא, וזיהוי המספר מהמצלמה עלול לטעות. אין להתעמת עם נהגים. במקרה חירום חייגו 100.
```

### English (en-US)

**Title** (30/30):
```
PlateScan: Israeli Plate Check
```

**Short description** (75/80):
```
Scan an Israeli licence plate: off-road, inactive or reported stolen? Free.
```

**Full description:**
```
PlateScan reads Israeli licence plates with your camera and checks the vehicle's status in public government datasets.

What it checks:
• Off the road: vehicles with a final cancellation status that must not be driven
• Inactive vehicles
• Expired vehicle licence
• Registered make, model, colour and year, so you can confirm the plate matches the car in front of you. A mismatch may indicate a forged plate.
• Stolen-vehicle check on the official Israel Police website: the number is filled in for you, and you tap "Check vehicle".

Two scanning modes:
• Point and shoot: a full check of one vehicle
• Continuous: checks every plate it sees and alerts on off-road vehicles. For passengers only, never while driving.

Reporting:
Call 100, or share a ready-made report with one tap: plate, vehicle details, location, time and the photos the camera captured while scanning. For people with hearing or speech disabilities: a ready SMS to the police's dedicated line. Nothing is reported automatically: you choose where it goes.

Privacy:
Recognition runs on your device. Only the plate number is sent for lookup. History and scan photos stay on your phone, and the photos are deleted when you are done. No accounts, no ads. Google's text recognition library sends only technical diagnostics, as described in the privacy policy.

Data sources:
• Vehicles taken off the road: https://data.gov.il/dataset/reshev_bitul_sofi
• Vehicle registry: https://data.gov.il/dataset/private-and-commercial-vehicles
• Inactive vehicles: https://data.gov.il/dataset/rechev_le_pail_with_degem
• Israel Police stolen-vehicle check: https://www.gov.il/en/service/licence_plate_stolen_vehicle_identification

Important:
PlateScan is not affiliated with the Israel Police, the Ministry of Transport or any government body, and is not an official app. Results are not confirmation that a vehicle is or is not stolen, and camera recognition can make mistakes. Never confront drivers. In an emergency, call 100.
```

### פרטים נוספים בדף החנות

| שדה | ערך |
|---|---|
| קטגוריה | Auto & Vehicles |
| מייל ליצירת קשר | המייל שלך (מוצג בחנות) |
| מדיניות פרטיות | הכתובת משלב 3 |
| גרפיקה | `store/play_icon_512.png`, `store/feature_graphic_1024x500.png`, `store/screenshots/*.png` |

## תשובות לשאלונים ב-App content

### App access

All functionality is available without special access. אין התחברות.

### Ads

No.

### Content rating (IARC)

- **קטגוריה:** Utility / Productivity / Other.
- **תשובות:** "No" לכל שאלות האלימות, המין, השפה, הסמים וההימורים.
- **אינטראקציה:** אין תוכן שמשתמשים יוצרים או משתפים ביניהם, ואין שיתוף מיקום עם משתמשים אחרים.
- **דירוג צפוי:** לכל הגילאים.

### Target audience

18+. כך האפליקציה לא נכנסת לדרישות של Families.

### Data safety

**Does your app collect or share any of the required user data types? Yes**, בגלל ספריית ML Kit בלבד. הטופס חייב לכלול גם נתונים שספריות צד שלישי שולחות, ו-ML Kit שולחת ל-Google נתוני אבחון ([גילוי הנתונים של ML Kit](https://developers.google.com/ml-kit/android-data-disclosure)).

| סוג נתון | Collected | Shared | פרטים |
|---|---|---|---|
| Device or other IDs | Yes | No | מזהה התקנה של ML Kit |
| App info and performance → Diagnostics | Yes | No | מדדי ביצועים וקודי שגיאה של ML Kit |

לשני הסוגים ענה:
- **Is this data processed ephemerally?** No.
- **Is it required or optional?** Required (אי אפשר לכבות את זה ב-ML Kit).
- **Purpose:** Analytics. זו המטרה ש-Google מצהירה: diagnostics and usage analytics.
- **Encrypted in transit:** Yes.
- **Users can request deletion:** No. לנו אין גישה לנתונים, הם אצל Google.

כל השאר לא נחשב איסוף או שיתוף:
- **מצלמה:** מעובדת במכשיר.
- **תמונות לדיווח:** נשמרות זמנית במכשיר, ויוצאות ממנו רק כשהמשתמש לוחץ "שתף" ובוחר אפליקציה. גוגל מחריגה העברה שהמשתמש יוזם וציפה לה.
- **מיקום:** נקרא רק כשהמשתמש לוחץ "שתף" או "SMS", ויוצא מהמכשיר רק דרך האפליקציה שהמשתמש בוחר. אותה החרגה.
- **מספר רישוי:** נשלח ל-data.gov.il לצורך הבדיקה. זה לא מידע על המשתמש. אם הסוקר יעיר, אפשר להוסיף אותו כ-"Other user-generated content", Collected: No.
- **היסטוריה:** נשמרת במכשיר בלבד.

### Government apps

האם האפליקציה מפותחת מטעם גוף ממשלתי? **No.**

### Health / Financial features / News

לא רלוונטי (None / No).

## סיכונים מול מדיניות Google Play

- **מידע ממשלתי:** גוגל דורשת מאפליקציה שמציגה מידע ממשלתי לציין את המקורות ולהבהיר שאינה קשורה לממשלה. זה כבר מופיע בתיאור, בחלון הפתיחה באפליקציה ובתחתית מסך הבית. אין להשתמש בסמל המשטרה או המדינה, בשם "משטרה" בכותרת האפליקציה, או בצבעים ובעיצוב שנראים רשמיים.
- **WebView של אתר המשטרה:** המדיניות אוסרת אפליקציה שכל מטרתה להציג אתר של מישהו אחר. כאן זו פונקציה אחת מתוך רבות (זיהוי, מאגרי משרד התחבורה, התרעות, דיווח), כך שהסיכון נמוך. אם הסוקר יעיר על זה, אפשר לפתוח את האתר בדפדפן החיצוני, אבל אז המספר לא ימולא אוטומטית.
- **צילומי מסך:** אסור שיופיעו בהם לוחיות רישוי אמיתיות של אנשים אחרים. בצילומים שהוכנו מופיעים מספרים מהמאגר הציבורי בלבד, בלי צילום של רכב.
