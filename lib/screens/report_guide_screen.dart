import 'package:flutter/material.dart';

import '../services/report_service.dart';

/// How to report a finding to the police, and how to keep a record of it.
class ReportGuideScreen extends StatelessWidget {
  const ReportGuideScreen({super.key, required this.report});

  final ReportService report;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('איך מדווחים למשטרה')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _Section(
            icon: Icons.phone,
            title: 'הרכב לפניך עכשיו? חייג 100',
            points: const [
              '100 הוא מוקד החירום של המשטרה, והוא פעיל 24 שעות. זה המספר גם לרכב שדווח כגנוב וגם לרכב שירד מהכביש ונוסע.',
              'מסור למוקדן את מספר הרישוי, המיקום המדויק, כיוון הנסיעה, ויצרן, דגם וצבע (הם מופיעים בתוצאת הבדיקה).',
              'אל תתעמת עם הנהג, אל תרדוף אחרי הרכב ואל תחסום אותו.',
              '110 הוא מוקד מידע (א\'–ה\', 8:00–22:00) שאינו שולח ניידות, ולכן לא מתאים לאירוע שקורה עכשיו.',
              'אפליקציית "100 - חירום" הרשמית של המשטרה שולחת את המיקום שלך יחד עם השיחה.',
            ],
            action: FilledButton.icon(
              style: FilledButton.styleFrom(
                backgroundColor: Colors.red.shade700,
                foregroundColor: Colors.white,
              ),
              onPressed: report.callPolice,
              icon: const Icon(Icons.phone),
              label: const Text('התקשר 100'),
            ),
          ),
          const _Section(
            icon: Icons.save_alt,
            title: 'שמור תיעוד: שלח לעצמך בוואטסאפ',
            points: [
              'למשטרה אין קו וואטסאפ לדיווחים, ולכן כדאי לשמור את הממצאים אצלך.',
              'במסך התוצאה לחץ "שתף דיווח", ובוואטסאפ בחר את הצ\'אט עם עצמך. כך יישמרו מספר הרכב, הסטטוס, המיקום, השעה והתמונות מהסריקה.',
              'התמונות נמחקות מהאפליקציה כשסוגרים את מסך התוצאה, אז שלח אותן לפני כן.',
              'אם המשטרה מבקשת פרטים או תמונות, תוכל להעביר אותם מהצ\'אט הזה.',
            ],
          ),
          _Section(
            icon: Icons.description_outlined,
            title: 'לא דחוף? תלונה מקוונת',
            points: const [
              'אם הרכב כבר לא שם, אפשר להגיש תלונה באתר המשטרה ולצרף את התמונות ששמרת.',
              'נדרשת כניסה עם ההזדהות הלאומית. התלונה לא מתאימה למקרה חירום.',
            ],
            action: OutlinedButton.icon(
              onPressed: report.openOnlineComplaint,
              icon: const Icon(Icons.open_in_new),
              label: const Text('תלונה מקוונת באתר המשטרה'),
            ),
          ),
          const _Section(
            icon: Icons.sms_outlined,
            title: 'לבעלי מוגבלות שמיעה או דיבור',
            points: [
              'אפשר לשלוח SMS למשטרה למספר 052-2020100. הקו מיועד רק לבעלי מוגבלות שמיעה או דיבור.',
              'במסך התוצאה יש כפתור שמכין את ההודעה עם פרטי הרכב והמיקום.',
            ],
          ),
          const _Section(
            icon: Icons.block,
            title: 'מה לא לעשות',
            points: [
              'אל תפרסם מספרי רכב, תמונות או חשדות ברשתות החברתיות או בקבוצות. החוק מגן על תלונה בתום לב למשטרה, אבל לא על פרסום ברבים.',
              'ודא שהמספר נקרא נכון ושהרכב שלפניך מתאים לפרטים הרשומים. טעות בזיהוי עלולה לפגוע באדם חף מפשע.',
              'מסירת הודעה כוזבת למשטרה היא עבירה.',
            ],
          ),
        ],
      ),
    );
  }
}

class _Section extends StatelessWidget {
  const _Section({
    required this.icon,
    required this.title,
    required this.points,
    this.action,
  });

  final IconData icon;
  final String title;
  final List<String> points;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Icon(icon, color: theme.colorScheme.primary),
                const SizedBox(width: 8),
                Expanded(
                  child: Semantics(
                    header: true,
                    child: Text(title, style: theme.textTheme.titleMedium),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            for (final point in points)
              Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Text('• $point'),
              ),
            if (action case final action?) ...[
              const SizedBox(height: 4),
              action,
            ],
          ],
        ),
      ),
    );
  }
}
