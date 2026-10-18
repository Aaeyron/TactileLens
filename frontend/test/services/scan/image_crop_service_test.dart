import 'dart:io';
import 'dart:typed_data';
import 'dart:ui';

import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;
import 'package:mobile/services/scan/image_crop_service.dart';

/// Frozen copy of the crop pipeline as it ran on the UI isolate before it
/// moved to ImageCropService.writePreviewCrop (ScanScreen decode + map,
/// then ImageCropService decode + crop + PNG). The new code must produce
/// byte-identical output.
Uint8List _legacyCrop(
  Uint8List sourceBytes,
  Rect selectedRegion,
  Size previewSize,
) {
  // ScanScreen._prepareImageForScanning: decode only to read the size.
  final img.Image sizingImage = img.bakeOrientation(
    img.decodeImage(sourceBytes)!,
  );

  final Size imageSize = Size(
    sizingImage.width.toDouble(),
    sizingImage.height.toDouble(),
  );

  // ScanScreen._mapPreviewRegionToImage.
  final double widthScale = previewSize.width / imageSize.width;
  final double heightScale = previewSize.height / imageSize.height;
  final double coverScale = widthScale > heightScale
      ? widthScale
      : heightScale;

  final Size displayedImageSize = Size(
    imageSize.width * coverScale,
    imageSize.height * coverScale,
  );

  final Offset displayedImageOffset = Offset(
    (previewSize.width - displayedImageSize.width) / 2,
    (previewSize.height - displayedImageSize.height) / 2,
  );

  final Rect clippedRegion = selectedRegion.intersect(
    Offset.zero & previewSize,
  );

  final Rect cropRect = Rect.fromLTRB(
    ((clippedRegion.left - displayedImageOffset.dx) / coverScale)
        .clamp(0.0, imageSize.width)
        .toDouble()
        .roundToDouble(),
    ((clippedRegion.top - displayedImageOffset.dy) / coverScale)
        .clamp(0.0, imageSize.height)
        .toDouble()
        .roundToDouble(),
    ((clippedRegion.right - displayedImageOffset.dx) / coverScale)
        .clamp(0.0, imageSize.width)
        .toDouble()
        .roundToDouble(),
    ((clippedRegion.bottom - displayedImageOffset.dy) / coverScale)
        .clamp(0.0, imageSize.height)
        .toDouble()
        .roundToDouble(),
  );

  // ImageCropService.cropImage: decode again, then crop.
  final img.Image normalizedImage = img.bakeOrientation(
    img.decodeImage(sourceBytes)!,
  );

  final int imageWidth = normalizedImage.width;
  final int imageHeight = normalizedImage.height;

  final int left = cropRect.left.floor().clamp(0, imageWidth - 1).toInt();
  final int top = cropRect.top.floor().clamp(0, imageHeight - 1).toInt();
  final int right = cropRect.right.ceil().clamp(left + 1, imageWidth).toInt();
  final int bottom = cropRect.bottom
      .ceil()
      .clamp(top + 1, imageHeight)
      .toInt();

  final img.Image croppedImage = img.copyCrop(
    normalizedImage,
    x: left,
    y: top,
    width: right - left,
    height: bottom - top,
  );

  return img.encodePng(croppedImage);
}

img.Image _gradientImage(int width, int height) {
  final img.Image image = img.Image(width: width, height: height);

  for (final img.Pixel pixel in image) {
    pixel
      ..r = (pixel.x * 255) ~/ width
      ..g = (pixel.y * 255) ~/ height
      ..b = (pixel.x + pixel.y) % 256;
  }

  return image;
}

void main() {
  late Directory workDirectory;

  setUp(() {
    workDirectory = Directory.systemTemp.createTempSync('crop_service_test');
  });

  tearDown(() {
    workDirectory.deleteSync(recursive: true);
  });

  Uint8List cropWithService(
    String sourcePath,
    Rect selectedRegion,
    Size previewSize,
  ) {
    final String outputPath = '${workDirectory.path}/output.png';

    ImageCropService.writePreviewCrop((
      sourcePath: sourcePath,
      outputPath: outputPath,
      selectedRegion: selectedRegion,
      previewSize: previewSize,
    ));

    return File(outputPath).readAsBytesSync();
  }

  final Map<String, Uint8List Function()> sources =
      <String, Uint8List Function()>{
        'camera PNG (landscape pixels)': () =>
            img.encodePng(_gradientImage(320, 240)),
        'camera PNG (portrait pixels)': () =>
            img.encodePng(_gradientImage(240, 320)),
        'gallery JPEG with EXIF rotation': () {
          final img.Image image = _gradientImage(320, 240);
          image.exif.imageIfd.orientation = 6;
          return img.encodeJpg(image, quality: 90);
        },
      };

  final Map<String, (Rect, Size)> selections = <String, (Rect, Size)>{
    'centered region': (
      const Rect.fromLTRB(40, 60, 260, 420),
      const Size(300, 480),
    ),
    'region touching the corners': (
      const Rect.fromLTRB(0, 0, 300, 480),
      const Size(300, 480),
    ),
    'region partly outside the preview': (
      const Rect.fromLTRB(-20, 300, 180, 600),
      const Size(300, 480),
    ),
    'wide preview': (
      const Rect.fromLTRB(100, 20, 500, 180),
      const Size(600, 200),
    ),
  };

  for (final MapEntry<String, Uint8List Function()> source
      in sources.entries) {
    for (final MapEntry<String, (Rect, Size)> selection
        in selections.entries) {
      test('${source.key}, ${selection.key}: matches the legacy crop', () {
        final Uint8List sourceBytes = source.value();
        final String sourcePath = '${workDirectory.path}/source.img';
        File(sourcePath).writeAsBytesSync(sourceBytes);

        final (Rect region, Size previewSize) = selection.value;

        expect(
          cropWithService(sourcePath, region, previewSize),
          equals(_legacyCrop(sourceBytes, region, previewSize)),
        );
      });
    }
  }

  test('an undecodable file reports the decode error', () {
    final String sourcePath = '${workDirectory.path}/broken.png';
    File(sourcePath).writeAsStringSync('not an image ' * 20);

    expect(
      () => cropWithService(
        sourcePath,
        const Rect.fromLTRB(0, 0, 10, 10),
        const Size(100, 100),
      ),
      throwsA(isA<ImageCropException>()),
    );
  });
}
