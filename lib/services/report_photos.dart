import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/foundation.dart';
import 'package:image/image.dart' as img;
import 'package:path_provider/path_provider.dart';

enum FrameFormat { nv21, bgra8888 }

/// A camera frame in which plates were read, kept briefly so it can be saved
/// as a photo for a police report.
class CapturedFrame {
  const CapturedFrame({
    required this.bytes,
    required this.width,
    required this.height,
    required this.bytesPerRow,
    required this.format,
    required this.rotation,
    required this.plates,
  });

  final Uint8List bytes;
  final int width;
  final int height;
  final int bytesPerRow;
  final FrameFormat format;

  /// Clockwise degrees (0, 90, 180 or 270) that make the frame upright.
  final int rotation;

  /// Plates read in this frame.
  final List<String> plates;
}

/// Saves the frames a plate was read in as JPEG files to attach to a report.
///
/// The files live in the app's temporary directory. The screen that took
/// them deletes them when it closes, and [deleteAll] runs at launch for any
/// left behind when the app was killed. They leave the device only through
/// the share sheet.
class ReportPhotos {
  ReportPhotos({Future<Directory> Function()? directory})
    : _directory = directory ?? _defaultDirectory;

  static const maxPhotos = 3;

  final Future<Directory> Function() _directory;

  static Future<Directory> _defaultDirectory() async =>
      Directory('${(await getTemporaryDirectory()).path}/report_photos');

  /// Writes up to [maxPhotos] of [frames], spread over the time the plate was
  /// in view, and returns their paths. Photos are optional evidence, so a
  /// failure returns what was saved instead of throwing.
  Future<List<String>> save(String plate, List<CapturedFrame> frames) async {
    if (frames.isEmpty) return const [];
    try {
      final dir = await _directory();
      await dir.create(recursive: true);
      final stamp = DateTime.now().millisecondsSinceEpoch;
      final picked = spread(frames, maxPhotos);
      final paths = [
        for (var i = 0; i < picked.length; i++)
          '${dir.path}/${plate}_${stamp}_${i + 1}.jpg',
      ];
      return await compute(_writeJpegs, (picked, paths));
    } on Object catch (e) {
      debugPrint('ReportPhotos: could not save photos of $plate: $e');
      return const [];
    }
  }

  /// Deletes [paths], ignoring files that are already gone.
  Future<void> delete(Iterable<String> paths) async {
    for (final path in paths) {
      try {
        await File(path).delete();
      } on Object {
        // Already deleted, e.g. by deleteAll().
      }
    }
  }

  /// Deletes every saved photo. Only safe when no screen is using them.
  Future<void> deleteAll() async {
    try {
      final dir = await _directory();
      if (await dir.exists()) await dir.delete(recursive: true);
    } on Object catch (e) {
      debugPrint('ReportPhotos: could not delete photos: $e');
    }
  }

  /// Up to [count] items evenly spaced through [items], first and last
  /// included.
  @visibleForTesting
  static List<T> spread<T>(List<T> items, int count) {
    if (items.length <= count) return items;
    if (count == 1) return [items.last];
    return [
      for (var i = 0; i < count; i++)
        items[(i * (items.length - 1) / (count - 1)).round()],
    ];
  }
}

List<String> _writeJpegs((List<CapturedFrame>, List<String>) job) {
  final (frames, paths) = job;
  final written = <String>[];
  for (var i = 0; i < frames.length; i++) {
    try {
      File(paths[i]).writeAsBytesSync(encodeFrameJpeg(frames[i]));
      written.add(paths[i]);
    } on Object catch (e) {
      debugPrint('ReportPhotos: could not encode frame: $e');
    }
  }
  return written;
}

/// Converts [frame] to an upright JPEG.
Uint8List encodeFrameJpeg(CapturedFrame frame, {int quality = 85}) {
  final image = switch (frame.format) {
    FrameFormat.nv21 => _fromNv21(frame),
    FrameFormat.bgra8888 => img.Image.fromBytes(
      width: frame.width,
      height: frame.height,
      bytes: frame.bytes.buffer,
      bytesOffset: frame.bytes.offsetInBytes,
      rowStride: frame.bytesPerRow,
      numChannels: 4,
      order: img.ChannelOrder.bgra,
    ),
  };
  final upright = frame.rotation == 0
      ? image
      : img.copyRotate(image, angle: frame.rotation);
  return img.encodeJpg(upright, quality: quality);
}

/// NV21: a full-size Y plane followed by interleaved V/U at half resolution.
img.Image _fromNv21(CapturedFrame frame) {
  final CapturedFrame(:width, :height, bytesPerRow: stride, bytes: src) = frame;
  final uvStart = stride * height;
  if (src.length < uvStart + stride * (height ~/ 2)) {
    throw const FormatException('NV21 frame is shorter than its size');
  }
  // Clamped, so out-of-range channel values saturate instead of wrapping.
  final rgb = Uint8ClampedList(width * height * 3);
  var o = 0;
  for (var y = 0; y < height; y++) {
    final yRow = y * stride;
    final uvRow = uvStart + (y >> 1) * stride;
    for (var x = 0; x < width; x++) {
      final luma = src[yRow + x];
      final uv = uvRow + (x & ~1);
      final v = src[uv] - 128;
      final u = src[uv + 1] - 128;
      // BT.601 in fixed point (coefficients x 1024).
      rgb[o++] = luma + ((1436 * v) >> 10);
      rgb[o++] = luma - ((352 * u + 731 * v) >> 10);
      rgb[o++] = luma + ((1815 * u) >> 10);
    }
  }
  return img.Image.fromBytes(
    width: width,
    height: height,
    bytes: rgb.buffer,
    numChannels: 3,
  );
}
