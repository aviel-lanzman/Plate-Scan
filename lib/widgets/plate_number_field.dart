import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../services/plate_parser.dart';

/// The message to show under a plate field, or null when [text] is a valid
/// plate number.
String? plateNumberError(String text) =>
    isValidPlate(normalizePlate(text)) ? null : 'יש להזין 4 עד 8 ספרות';

/// A text field for typing a plate number: digits only, at most 8, always
/// left to right. The owner validates with [plateNumberError] and passes the
/// result as [errorText], so an invalid number is explained instead of being
/// silently ignored.
class PlateNumberField extends StatelessWidget {
  const PlateNumberField({
    super.key,
    required this.controller,
    this.errorText,
    this.onChanged,
    this.onSubmitted,
    this.autofocus = false,
    this.hintText,
    this.style,
  });

  final TextEditingController controller;
  final String? errorText;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onSubmitted;
  final bool autofocus;
  final String? hintText;
  final TextStyle? style;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      autofocus: autofocus,
      keyboardType: TextInputType.number,
      textDirection: TextDirection.ltr,
      textAlign: TextAlign.center,
      style: style,
      inputFormatters: [
        FilteringTextInputFormatter.digitsOnly,
        LengthLimitingTextInputFormatter(8),
      ],
      decoration: InputDecoration(
        hintText: hintText,
        errorText: errorText,
        border: const OutlineInputBorder(),
      ),
      onChanged: onChanged,
      onSubmitted: onSubmitted,
    );
  }
}
