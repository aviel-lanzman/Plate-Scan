import 'package:flutter/material.dart';

import '../models/vehicle_result.dart';

extension PlateStatusStyle on PlateStatus {
  Color get color => switch (this) {
    PlateStatus.offRoad => Colors.red.shade700,
    PlateStatus.inactive => Colors.deepOrange.shade600,
    PlateStatus.licenseExpired => Colors.amber.shade800,
    PlateStatus.active => Colors.green.shade700,
    PlateStatus.notFound => Colors.grey.shade600,
    PlateStatus.error => Colors.blueGrey.shade600,
  };

  IconData get icon => switch (this) {
    PlateStatus.offRoad => Icons.dangerous,
    PlateStatus.inactive => Icons.warning_amber,
    PlateStatus.licenseExpired => Icons.event_busy,
    PlateStatus.active => Icons.check_circle,
    PlateStatus.notFound => Icons.help_outline,
    PlateStatus.error => Icons.cloud_off,
  };
}

/// Compact coloured status (icon + text); a spinner while still checking.
class StatusLabel extends StatelessWidget {
  const StatusLabel(this.status, {super.key});

  final PlateStatus? status;

  @override
  Widget build(BuildContext context) {
    final status = this.status;
    if (status == null) {
      return const Row(
        children: [
          SizedBox.square(
            dimension: 14,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
          SizedBox(width: 6),
          Text('בודק...'),
        ],
      );
    }
    return Row(
      children: [
        Icon(status.icon, color: status.color, size: 18),
        const SizedBox(width: 4),
        Flexible(
          child: Text(
            status.label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(color: status.color, fontWeight: FontWeight.bold),
          ),
        ),
      ],
    );
  }
}

extension StolenCheckStyle on StolenCheckOutcome {
  Color get color => switch (this) {
    StolenCheckOutcome.stolen => Colors.red.shade700,
    StolenCheckOutcome.clean => Colors.green.shade700,
    StolenCheckOutcome.error => Colors.blueGrey.shade600,
  };

  IconData get icon => switch (this) {
    StolenCheckOutcome.stolen => Icons.local_police,
    StolenCheckOutcome.clean => Icons.verified_user,
    StolenCheckOutcome.error => Icons.error_outline,
  };
}
