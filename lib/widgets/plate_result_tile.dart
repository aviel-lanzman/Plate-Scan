import 'package:flutter/material.dart';

import '../models/vehicle_result.dart';
import 'plate_badge.dart';
import 'status_style.dart';

/// A plate with its status, vehicle and time: side by side normally, stacked
/// when large text would leave the details too little room.
class PlateResultTile extends StatelessWidget {
  const PlateResultTile({
    super.key,
    required this.plate,
    required this.status,
    this.stolen,
    this.summary,
    required this.time,
    required this.onTap,
  });

  final String plate;

  /// Null while the plate is still being checked.
  final PlateStatus? status;
  final StolenCheckOutcome? stolen;
  final String? summary;
  final String time;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final stacked = MediaQuery.textScalerOf(context).scale(10) > 13;
    final stolen = this.stolen;
    final summary = this.summary;
    final details = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Flexible(child: StatusLabel(status)),
            if (stolen != null) ...[
              const SizedBox(width: 8),
              Icon(
                stolen.icon,
                color: stolen.textColor(context),
                semanticLabel: stolen.label,
                size: 18,
              ),
            ],
          ],
        ),
        if (summary != null && summary.isNotEmpty)
          Text(
            summary,
            maxLines: stacked ? 2 : 1,
            overflow: TextOverflow.ellipsis,
            style: theme.textTheme.bodyMedium,
          ),
        Text(time, style: theme.textTheme.bodySmall),
      ],
    );
    final badge = PlateBadge(plate, fontSize: 16);
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        child: stacked
            ? Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [badge, const SizedBox(height: 6), details],
              )
            : Row(
                children: [
                  badge,
                  const SizedBox(width: 12),
                  Expanded(child: details),
                ],
              ),
      ),
    );
  }
}
