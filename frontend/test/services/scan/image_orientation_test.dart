import 'dart:io';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;
import 'package:mobile/services/scan/image_orientation_service.dart';

/// 40 x 20, upright: left half red, right half blue, top-left 10 x 10
/// green, so any rotation or mirror is visible.
img.Image _upright() {
  final img.Image image = img.Image(width: 40, height: 20);
  img.fill(image, color: img.ColorRgb8(255, 0, 0));
  img.fillRect(
    image,
    x1: 20,
    y1: 0,
    x2: 39,
    y2: 19,
    color: img.ColorRgb8(0, 0, 255),
  );
  img.fillRect(
    image,
    x1: 0,
    y1: 0,
    x2: 9,
    y2: 9,
    color: img.ColorRgb8(0, 255, 0),
  );
  return image;
}

/// A JPEG whose pixels are stored so that a viewer applying EXIF
/// [orientation] shows [_upright], as a camera or another app writes it.
/// It also carries another tag, which must not survive.
Uint8List _jpegWithOrientation(int orientation) {
  final img.Image upright = _upright();
  final img.Image stored = switch (orientation) {
    1 => upright,
    2 => img.flipHorizontal(upright.clone()),
    3 => img.copyRotate(upright, angle: 180),
    4 => img.flipVertical(upright.clone()),
    5 => img.flipHorizontal(img.copyRotate(upright, angle: 90)),
    6 => img.copyRotate(upright, angle: -90),
    7 => img.flipHorizontal(img.copyRotate(upright, angle: -90)),
    8 => img.copyRotate(upright, angle: 90),
    _ => throw ArgumentError(orientation),
  }.clone();

  stored.exif.imageIfd.orientation = orientation;
  stored.exif.imageIfd['Make'] = img.IfdValueAscii('TestPhone');
  return img.encodeJpg(stored, quality: 100);
}

/// Pixels written with no EXIF at all, as some cameras do.
Uint8List _noExif(img.Image pixels) => img.encodePng(pixels);

bool _isUpright(img.Image? image) {
  if (image == null) {
    return false;
  }

  bool near(img.Pixel p, int r, int g, int b) =>
      (p.r - r).abs() < 60 && (p.g - g).abs() < 60 && (p.b - b).abs() < 60;

  return image.width == 40 &&
      image.height == 20 &&
      near(image.getPixel(3, 3), 0, 255, 0) && // green top-left
      near(image.getPixel(15, 15), 255, 0, 0) && // red left
      near(image.getPixel(30, 10), 0, 0, 255); // blue right
}

void main() {
  group('gallery: all 8 EXIF orientations come out upright', () {
    for (int orientation = 1; orientation <= 8; orientation++) {
      test('orientation $orientation', () {
        final img.Image? result = ImageOrientationService.normalizeBytes(
          _jpegWithOrientation(orientation),
        );

        expect(_isUpright(result), isTrue);
        expect(result!.exif.isEmpty, isTrue, reason: 'EXIF is stripped');
      });
    }
  });

  group('camera', () {
    test(
      'a rotation written by the camera is trusted, however it was held',
      () {
        for (int orientation = 2; orientation <= 8; orientation++) {
          for (final DeviceOrientation held in DeviceOrientation.values) {
            final img.Image? result = ImageOrientationService.normalizeBytes(
              _jpegWithOrientation(orientation),
              capturedIn: held,
            );

            expect(_isUpright(result), isTrue, reason: '$orientation $held');
          }
        }
      },
    );

    test('held sideways, portrait pixels, no rotation written: turned', () {
      expect(
        _isUpright(
          ImageOrientationService.normalizeBytes(
            _noExif(img.copyRotate(_upright(), angle: 90)),
            capturedIn: DeviceOrientation.landscapeLeft,
          ),
        ),
        isTrue,
      );
      expect(
        _isUpright(
          ImageOrientationService.normalizeBytes(
            _noExif(img.copyRotate(_upright(), angle: -90)),
            capturedIn: DeviceOrientation.landscapeRight,
          ),
        ),
        isTrue,
      );
    });

    test('held sideways, already landscape pixels: unchanged', () {
      for (final DeviceOrientation held in <DeviceOrientation>[
        DeviceOrientation.landscapeLeft,
        DeviceOrientation.landscapeRight,
      ]) {
        expect(
          _isUpright(
            ImageOrientationService.normalizeBytes(
              _noExif(_upright()),
              capturedIn: held,
            ),
          ),
          isTrue,
          reason: '$held',
        );
      }
    });

    test('held upside-down, no rotation written: turned 180 degrees', () {
      expect(
        _isUpright(
          ImageOrientationService.normalizeBytes(
            _noExif(img.copyRotate(_upright(), angle: 180)),
            capturedIn: DeviceOrientation.portraitDown,
          ),
        ),
        isTrue,
      );
    });

    test('held upright, no rotation written: unchanged', () {
      expect(
        _isUpright(
          ImageOrientationService.normalizeBytes(
            _noExif(_upright()),
            capturedIn: DeviceOrientation.portraitUp,
          ),
        ),
        isTrue,
      );
    });
  });

  group('files', () {
    late Directory directory;

    setUp(() => directory = Directory.systemTemp.createTempSync('orient'));
    tearDown(() => directory.deleteSync(recursive: true));

    test('a rotated gallery JPEG is rewritten upright, without EXIF', () {
      final File source = File('${directory.path}/photo.jpg')
        ..writeAsBytesSync(_jpegWithOrientation(6));

      final String? output = ImageOrientationService.writeNormalized((
        sourcePath: source.path,
        outputDirectory: directory.path,
        capturedIn: null,
      ));

      expect(output, isNot(source.path));
      expect(output, endsWith('.png'));
      final img.Image written = img.decodePng(File(output!).readAsBytesSync())!;
      expect(_isUpright(written), isTrue);
      expect(written.exif.isEmpty, isTrue);
    });

    test('a gallery image without EXIF is used as it is', () {
      final File source = File('${directory.path}/scan.png')
        ..writeAsBytesSync(img.encodePng(_upright()));

      final String? output = ImageOrientationService.writeNormalized((
        sourcePath: source.path,
        outputDirectory: directory.path,
        capturedIn: null,
      ));

      expect(output, source.path);
    });

    test('a file that is not an image gives null', () {
      final File source = File('${directory.path}/broken.jpg')
        ..writeAsBytesSync(<int>[1, 2, 3]);

      expect(
        ImageOrientationService.writeNormalized((
          sourcePath: source.path,
          outputDirectory: directory.path,
          capturedIn: null,
        )),
        isNull,
      );
    });
  });
}
