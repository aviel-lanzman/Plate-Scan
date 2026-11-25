import 'dart:io';

import 'package:flutter/material.dart';

/// Shows the photo at [path] full screen, with pinch zoom.
Future<void> showPhotoViewer(BuildContext context, String path) =>
    showDialog<void>(
      context: context,
      builder: (context) => Dialog.fullscreen(
        backgroundColor: Colors.black,
        child: Stack(
          children: [
            Positioned.fill(
              child: InteractiveViewer(
                maxScale: 6,
                child: Image.file(File(path), fit: BoxFit.contain),
              ),
            ),
            SafeArea(
              child: IconButton(
                tooltip: 'סגור',
                color: Colors.white,
                icon: const Icon(Icons.close),
                onPressed: () => Navigator.pop(context),
              ),
            ),
          ],
        ),
      ),
    );
