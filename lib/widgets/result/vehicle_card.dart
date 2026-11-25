import 'package:flutter/material.dart';

import '../../models/vehicle_result.dart';

/// The registered vehicle, so the user can compare it with the car in front
/// of them.
class VehicleCard extends StatelessWidget {
  const VehicleCard(this.info, {super.key});

  final VehicleInfo info;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('ודא שהרכב שלפניך הוא:', style: theme.textTheme.titleSmall),
            const SizedBox(height: 4),
            Text(info.summary, style: theme.textTheme.headlineSmall),
            if (info.vehicleType case final type?) Text(type),
            const SizedBox(height: 8),
            Text(
              'אם הרכב שאתה רואה שונה, ייתכן שהמספר נקרא לא נכון או שהלוחית מזויפת.',
              style: theme.textTheme.bodySmall,
            ),
          ],
        ),
      ),
    );
  }
}
