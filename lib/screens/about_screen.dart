import 'package:flutter/material.dart';

import '../util/app_name.dart';
import 'legal_doc_screen.dart';

/// Usage guidelines, legal documents and open-source licences.
class AboutScreen extends StatelessWidget {
  const AboutScreen({super.key, required this.onShowGuidelines});

  /// Shows the first-run guidelines again.
  final VoidCallback onShowGuidelines;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    void open(LegalDoc doc) => Navigator.push(
      context,
      MaterialPageRoute<void>(builder: (_) => LegalDocScreen(doc)),
    );
    return Scaffold(
      appBar: AppBar(title: const Text('מידע ותנאי שימוש')),
      body: ListView(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(appName(), style: theme.textTheme.headlineSmall),
                const SizedBox(height: 8),
                const Text(
                  'אפליקציה חינמית, ללא פרסומות וללא חשבונות משתמש, שפותחה בהתנדבות לטובת הציבור. '
                  'היא אינה קשורה למשטרת ישראל, למשרד התחבורה או לכל גוף ממשלתי אחר. '
                  'המידע מוצג כפי שהוא מתקבל ממאגרי המידע הציבוריים, ואינו מהווה אישור לכך שרכב גנוב או לא.',
                ),
              ],
            ),
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.rule),
            title: const Text('הנחיות שימוש'),
            onTap: onShowGuidelines,
          ),
          for (final (doc, icon) in [
            (LegalDoc.terms, Icons.gavel),
            (LegalDoc.privacy, Icons.privacy_tip_outlined),
            (LegalDoc.accessibility, Icons.accessibility_new),
          ])
            ListTile(
              leading: Icon(icon),
              title: Text(doc.title),
              trailing: const Icon(Icons.chevron_left),
              onTap: () => open(doc),
            ),
          ListTile(
            leading: const Icon(Icons.code),
            title: const Text('רישיונות קוד פתוח'),
            trailing: const Icon(Icons.chevron_left),
            onTap: () =>
                showLicensePage(context: context, applicationName: appName()),
          ),
        ],
      ),
    );
  }
}
