import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;
import 'package:plate_scan/services/report_photos.dart';

/// A [width]x[height] NV21 frame of one colour.
CapturedFrame _nv21(
  int width,
  int height, {
  required int y,
  required int u,
  required int v,
}) {
  final bytes = Uint8List(width * height * 3 ~/ 2)
    ..fillRange(0, width * height, y);
  for (var i = width * height; i < bytes.length; i += 2) {
    bytes[i] = v;
    bytes[i + 1] = u;
  }
  return CapturedFrame(
    bytes: bytes,
    width: width,
    height: height,
    bytesPerRow: width,
    format: FrameFormat.nv21,
    rotation: 90,
    plates: const ['1234567'],
  );
}

void main() {
  group('encodeFrameJpeg', () {
    test('converts NV21 colours and rotates upright', () {
      final jpeg = encodeFrameJpeg(_nv21(32, 16, y: 76, u: 85, v: 255));
      final decoded = img.decodeJpg(jpeg)!;
      expect((decoded.width, decoded.height), (16, 32));
      final pixel = decoded.getPixel(8, 16);
      expect(pixel.r, greaterThan(220));
      expect(pixel.g, lessThan(40));
      expect(pixel.b, lessThan(40));
    });

    test('honours BGRA row padding', () {
      const width = 32, height = 16, stride = width * 4 + 16;
      final bytes = Uint8List(stride * height);
      for (var y = 0; y < height; y++) {
        for (var x = 0; x < width; x++) {
          bytes.setAll(y * stride + x * 4, [255, 0, 0, 255]); // blue
        }
      }
      final jpeg = encodeFrameJpeg(
        CapturedFrame(
          bytes: bytes,
          width: width,
          height: height,
          bytesPerRow: stride,
          format: FrameFormat.bgra8888,
          rotation: 0,
          plates: const [],
        ),
      );
      final decoded = img.decodeJpg(jpeg)!;
      expect((decoded.width, decoded.height), (width, height));
      final pixel = decoded.getPixel(31, 15);
      expect(pixel.b, greaterThan(220));
      expect(pixel.r, lessThan(40));
    });

    test('rejects a truncated NV21 frame', () {
      final frame = _nv21(32, 16, y: 0, u: 128, v: 128);
      expect(
        () => encodeFrameJpeg(
          CapturedFrame(
            bytes: frame.bytes.sublist(0, 32 * 16),
            width: 32,
            height: 16,
            bytesPerRow: 32,
            format: FrameFormat.nv21,
            rotation: 0,
            plates: const [],
          ),
        ),
        throwsFormatException,
      );
    });
  });

  test('spread keeps the first and last of evenly spaced items', () {
    expect(ReportPhotos.spread([1, 2], 3), [1, 2]);
    expect(ReportPhotos.spread([1, 2, 3, 4, 5, 6], 3), [1, 4, 6]);
    expect(ReportPhotos.spread([1, 2, 3, 4, 5, 6], 1), [6]);
  });

  group('ReportPhotos', () {
    late Directory dir;
    late ReportPhotos photos;

    setUp(() async {
      dir = await Directory.systemTemp.createTemp('report_photos_test');
      photos = ReportPhotos(directory: () async => dir);
    });

    tearDown(() => dir.delete(recursive: true));

    test('saves up to maxPhotos JPEGs and deletes them', () async {
      final frames = List.generate(
        5,
        (_) => _nv21(32, 16, y: 128, u: 128, v: 128),
      );
      final paths = await photos.save('1234567', frames);
      expect(paths, hasLength(ReportPhotos.maxPhotos));
      for (final path in paths) {
        expect(path, contains('1234567_'));
        expect(img.decodeJpg(File(path).readAsBytesSync()), isNotNull);
      }
      await photos.delete([...paths, '${dir.path}/missing.jpg']);
      expect(dir.listSync(), isEmpty);
    });

    test('saves nothing without frames', () async {
      expect(await photos.save('1234567', const []), isEmpty);
    });

    test('deleteAll removes every photo', () async {
      await photos.save('1234567', [_nv21(32, 16, y: 0, u: 128, v: 128)]);
      await photos.deleteAll();
      expect(dir.existsSync(), isFalse);
      // Saving again recreates the directory.
      final paths = await photos.save('1234567', [
        _nv21(32, 16, y: 0, u: 128, v: 128),
      ]);
      expect(File(paths.single).existsSync(), isTrue);
    });
  });
}
