import 'package:flutter/material.dart';

import '../services/plate_parser.dart';

/// Renders a plate number styled like an Israeli yellow licence plate.
class PlateBadge extends StatelessWidget {
  const PlateBadge(this.plate, {super.key, this.fontSize = 32});

  /// Digits only.
  final String plate;
  final double fontSize;

  @override
  Widget build(BuildContext context) {
    // Plates read left-to-right even in an RTL layout.
    return Directionality(
      textDirection: TextDirection.ltr,
      child: Container(
        decoration: BoxDecoration(
          color: const Color(0xFFFFCC00),
          border: Border.all(color: Colors.black, width: 2),
          borderRadius: BorderRadius.circular(6),
        ),
        clipBehavior: Clip.antiAlias,
        child: IntrinsicHeight(
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                color: const Color(0xFF0038B8),
                padding: EdgeInsets.symmetric(horizontal: fontSize * 0.2),
                alignment: Alignment.center,
                child: Text(
                  'IL',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: fontSize * 0.45,
                  ),
                ),
              ),
              Padding(
                padding: EdgeInsets.symmetric(
                  horizontal: fontSize * 0.4,
                  vertical: fontSize * 0.1,
                ),
                child: Text(
                  formatPlate(plate),
                  style: TextStyle(
                    color: Colors.black,
                    fontWeight: FontWeight.w900,
                    fontSize: fontSize,
                    letterSpacing: 1.5,
                    fontFeatures: const [FontFeature.tabularFigures()],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
