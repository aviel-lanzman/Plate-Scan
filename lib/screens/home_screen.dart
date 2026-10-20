import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../app_services.dart';
import '../services/plate_parser.dart';
import '../util/app_name.dart';
import 'about_screen.dart';
import 'continuous_scan_screen.dart';
import 'history_screen.dart';
import 'legal_doc_screen.dart';
import 'result_screen.dart';
import 'single_scan_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key, required this.services});

  final AppServices services;

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  // v2 added the terms of use and report photos, so v1 users accept again.
  static const _disclaimerKey = 'disclaimer_accepted_v2';

  final _plateController = TextEditingController();
  String? _plateError;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _showDisclaimerOnce());
  }

  @override
  void dispose() {
    _plateController.dispose();
    super.dispose();
  }

  Future<void> _showDisclaimerOnce() async {
    SharedPreferences? prefs;
    try {
      prefs = await SharedPreferences.getInstance();
      if (prefs.getBool(_disclaimerKey) == true) return;
    } on Object {
      // Without storage, show the disclaimer every launch rather than never.
    }
    if (!mounted) return;
    await _showDisclaimer(firstRun: true);
    await prefs?.setBool(_disclaimerKey, true);
  }

  /// On first run the user accepts the terms; later it is just a reminder.
  Future<void> _showDisclaimer({bool firstRun = false}) => showDialog<void>(
    context: context,
    barrierDismissible: !firstRun,
    builder: (context) => AlertDialog(
      title: const Text('לפני שמתחילים'),
      content: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '• אין להשתמש באפליקציה בזמן נהיגה. הסריקה הרציפה מיועדת לנוסע בלבד.\n\n'
              '• אין להתעמת עם נהג או לנסות לעצור רכב. אם נתקלת ברכב חשוד, דווח למוקד 100.\n\n'
              '• המידע מגיע ממאגרי משרד התחבורה ומאתר משטרת ישראל, ואינו מהווה אישור לכך שרכב גנוב או לא. '
              'המאגרים מתעדכנים מדי יום, וזיהוי המספר מהמצלמה עלול לטעות. תמיד ודא שהמספר נקרא נכון.\n\n'
              '• שתף דיווחים ותמונות רק עם המשטרה. אין לפרסם מספרי רכב, תמונות או חשדות ברשתות החברתיות.\n\n'
              '• רק מספר הרישוי נשלח לבדיקה. ההיסטוריה ותמונות הסריקה נשמרות במכשיר בלבד.\n\n'
              '• האפליקציה אינה קשורה למשטרת ישראל, למשרד התחבורה או לכל גוף ממשלתי אחר. '
              'מקורות המידע: מאגרי משרד התחבורה באתר data.gov.il, '
              'ושירות "רכב גנוב" של משטרת ישראל באתר gov.il.',
            ),
            if (firstRun) ...[
              const SizedBox(height: 16),
              const Text(
                'בלחיצה על "מסכים" אתה מאשר את תנאי השימוש ואת מדיניות הפרטיות.',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              Wrap(
                children: [
                  for (final doc in [LegalDoc.terms, LegalDoc.privacy])
                    TextButton(
                      onPressed: () => Navigator.push(
                        context,
                        MaterialPageRoute<void>(
                          builder: (_) => LegalDocScreen(doc),
                        ),
                      ),
                      child: Text(doc.title),
                    ),
                ],
              ),
            ],
          ],
        ),
      ),
      actions: [
        FilledButton(
          onPressed: () => Navigator.pop(context),
          child: Text(firstRun ? 'מסכים' : 'סגור'),
        ),
      ],
    ),
  );

  void _open(Widget screen) =>
      Navigator.push(context, MaterialPageRoute<void>(builder: (_) => screen));

  void _checkManual() {
    final plate = normalizePlate(_plateController.text);
    if (!isValidPlate(plate)) {
      setState(() => _plateError = 'יש להזין 4 עד 8 ספרות');
      return;
    }
    setState(() => _plateError = null);
    FocusScope.of(context).unfocus();
    _open(ResultScreen(services: widget.services, plate: plate));
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: Text(appName()),
        actions: [
          IconButton(
            tooltip: 'מידע ותנאי שימוש',
            icon: const Icon(Icons.info_outline),
            onPressed: () =>
                _open(AboutScreen(onShowGuidelines: _showDisclaimer)),
          ),
        ],
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Text(
              'סרוק לוחית רישוי ובדוק אם הרכב ירד מהכביש או דווח כגנוב',
              style: theme.textTheme.titleMedium,
            ),
            const SizedBox(height: 16),
            _ModeCard(
              icon: Icons.center_focus_strong,
              title: 'כוון וצלם',
              subtitle: 'בדיקה מלאה של רכב אחד',
              onTap: () => _open(SingleScanScreen(services: widget.services)),
            ),
            _ModeCard(
              icon: Icons.videocam,
              title: 'סריקה רציפה',
              subtitle: 'בודק כל לוחית שנקלטת ומתריע על רכב שירד מהכביש. לנוסעים בלבד, לא בזמן נהיגה.',
              onTap: () =>
                  _open(ContinuousScanScreen(services: widget.services)),
            ),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text('הקלדת מספר', style: theme.textTheme.titleMedium),
                    const SizedBox(height: 12),
                    TextField(
                      controller: _plateController,
                      keyboardType: TextInputType.number,
                      textDirection: TextDirection.ltr,
                      textAlign: TextAlign.center,
                      style: theme.textTheme.headlineSmall,
                      inputFormatters: [
                        FilteringTextInputFormatter.digitsOnly,
                        LengthLimitingTextInputFormatter(8),
                      ],
                      decoration: InputDecoration(
                        hintText: '1234567',
                        errorText: _plateError,
                        border: const OutlineInputBorder(),
                      ),
                      onSubmitted: (_) => _checkManual(),
                    ),
                    const SizedBox(height: 12),
                    FilledButton.icon(
                      onPressed: _checkManual,
                      icon: const Icon(Icons.search),
                      label: const Text('בדוק'),
                    ),
                  ],
                ),
              ),
            ),
            Card(
              child: ListTile(
                leading: const Icon(Icons.history),
                title: const Text('היסטוריית בדיקות'),
                trailing: const Icon(Icons.chevron_left),
                onTap: () => _open(HistoryScreen(services: widget.services)),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'מקורות: מאגרי משרד התחבורה ב-data.gov.il ואתר משטרת ישראל. '
              'האפליקציה אינה אפליקציה ממשלתית. בחירום: 100.',
              style: theme.textTheme.bodySmall,
            ),
            // The accessibility regulations ask for the statement to be easy
            // to find, so the documents are linked here too.
            Wrap(
              children: [
                for (final doc in LegalDoc.values)
                  TextButton(
                    onPressed: () => _open(LegalDocScreen(doc)),
                    child: Text(doc.title),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _ModeCard extends StatelessWidget {
  const _ModeCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              CircleAvatar(
                radius: 28,
                backgroundColor: scheme.primaryContainer,
                child: Icon(icon, size: 30, color: scheme.onPrimaryContainer),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: Theme.of(context).textTheme.titleLarge),
                    const SizedBox(height: 4),
                    Text(subtitle),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
