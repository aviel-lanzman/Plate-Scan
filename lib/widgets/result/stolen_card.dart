import 'package:flutter/material.dart';

import '../../models/vehicle_result.dart';
import '../status_style.dart';

/// The stolen-vehicle check: its outcome so far and the way to run it.
class StolenCard extends StatelessWidget {
  const StolenCard({super.key, required this.outcome, required this.onCheck});

  final StolenCheckOutcome? outcome;
  final VoidCallback onCheck;

  @override
  Widget build(BuildContext context) {
    final outcome = this.outcome;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('בדיקת גניבה', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 4),
            if (outcome == null)
              const Text(
                'הבדיקה נעשית באתר הרשמי של משטרת ישראל. המספר ימולא אוטומטית, ואתה לוחץ "בדוק רכב".',
              )
            else
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: Icon(
                  outcome.icon,
                  color: outcome.textColor(context),
                  size: 32,
                ),
                title: Text(
                  outcome.label,
                  style: TextStyle(
                    color: outcome.textColor(context),
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            const SizedBox(height: 8),
            OutlinedButton.icon(
              onPressed: onCheck,
              icon: const Icon(Icons.local_police),
              label: Text(outcome == null ? 'בדוק באתר המשטרה' : 'בדוק שוב'),
            ),
          ],
        ),
      ),
    );
  }
}
