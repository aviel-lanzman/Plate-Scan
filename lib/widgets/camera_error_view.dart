import 'package:flutter/material.dart';

/// Shown instead of the camera preview when the camera could not start.
/// Offers a retry, and the app settings when a denied permission is the cause.
class CameraErrorView extends StatelessWidget {
  const CameraErrorView({
    super.key,
    required this.message,
    required this.onRetry,
    this.onOpenSettings,
  });

  final String message;
  final VoidCallback onRetry;

  /// Null when the app settings cannot help with this error.
  final VoidCallback? onOpenSettings;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(message, textAlign: TextAlign.center),
            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh),
              label: const Text('נסה שוב'),
            ),
            if (onOpenSettings case final openSettings?)
              TextButton.icon(
                onPressed: openSettings,
                icon: const Icon(Icons.settings),
                label: const Text('פתח הגדרות'),
              ),
          ],
        ),
      ),
    );
  }
}
