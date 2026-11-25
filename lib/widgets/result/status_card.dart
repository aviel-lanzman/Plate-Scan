import 'package:flutter/material.dart';

import '../../models/vehicle_result.dart';
import '../../util/format.dart';
import '../status_style.dart';

/// The headline status of a lookup, in the status colour. [onRetry] looks the
/// plate up again; it is offered when the lookup failed or came back partial.
class StatusCard extends StatelessWidget {
  const StatusCard(this.result, {super.key, required this.onRetry});

  final VehicleResult result;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final status = result.status;
    final info = result.info;
    final partial = result.partial && status != PlateStatus.error;
    const white = TextStyle(color: Colors.white);
    return Card(
      color: status.color,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(status.icon, color: Colors.white, size: 36),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    status.label,
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(status.description, style: white),
            if (status == PlateStatus.offRoad && info?.cancelledOn != null)
              Text(
                'תאריך ביטול: ${formatIsoDate(info!.cancelledOn!)}',
                style: white,
              ),
            if (info?.licenseValidUntil case final until?)
              Text('תוקף רישיון הרכב: ${formatIsoDate(until)}', style: white),
            Text('נבדק: ${formatDateTime(result.checkedAt)}', style: white),
            if (partial)
              const Padding(
                padding: EdgeInsets.only(top: 8),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(Icons.info_outline, color: Colors.white, size: 20),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'אחד ממקורות המידע לא ענה, ולכן הסטטוס עלול להיות חלקי.',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            if (status == PlateStatus.error || partial)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.white,
                  ),
                  onPressed: onRetry,
                  icon: const Icon(Icons.refresh),
                  label: Text(partial ? 'בדוק שוב' : 'נסה שוב'),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
