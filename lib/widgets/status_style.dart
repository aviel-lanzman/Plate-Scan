import 'package:flutter/material.dart';

import '../models/vehicle_result.dart';

/// [color] for text or icons on the page background: lightened in dark mode
/// so it keeps enough contrast.
Color _onPage(Color color, BuildContext context) =>
    Theme.of(context).brightness == Brightness.dark
    ? Color.lerp(color, Colors.white, 0.45)!
    : color;

// Status colours are backgrounds for white text, so each keeps at least the
// 4.5:1 contrast WCAG AA requires.
extension PlateStatusStyle on PlateStatus {
  Color get color => switch (this) {
    PlateStatus.offRoad => Colors.red.shade700,
    PlateStatus.inactive => Colors.deepOrange.shade900,
    PlateStatus.licenseExpired => const Color(0xFF8A5A00),
    PlateStatus.active => Colors.green.shade800,
    PlateStatus.notFound => Colors.grey.shade700,
    PlateStatus.error => Colors.blueGrey.shade600,
  };

  Color textColor(BuildContext context) => _onPage(color, context);

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
        mainAxisSize: MainAxisSize.min,
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
    final color = status.textColor(context);
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(status.icon, color: color, size: 18),
        const SizedBox(width: 4),
        Flexible(
          child: Text(
            status.label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(color: color, fontWeight: FontWeight.bold),
          ),
        ),
      ],
    );
  }
}

extension StolenCheckStyle on StolenCheckOutcome {
  Color get color => switch (this) {
    StolenCheckOutcome.stolen => Colors.red.shade700,
    StolenCheckOutcome.clean => Colors.green.shade800,
    StolenCheckOutcome.error => Colors.blueGrey.shade600,
  };

  Color textColor(BuildContext context) => _onPage(color, context);

  IconData get icon => switch (this) {
    StolenCheckOutcome.stolen => Icons.local_police,
    StolenCheckOutcome.clean => Icons.verified_user,
    StolenCheckOutcome.error => Icons.error_outline,
  };
}
