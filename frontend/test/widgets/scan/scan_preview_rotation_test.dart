import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/services/scan/image_crop_service.dart';
import 'package:mobile/widgets/scan/scan_preview.dart';

/// The page photo: portrait, 1200 x 1600 pixels.
const Size _imageSize = Size(1200, 1600);

Rect _imageRegionOf(Rect region, Size previewSize) {
  return ImageCropService.mapPreviewRegionToImage(
    selectedRegion: region,
    previewSize: previewSize,
    imageSize: _imageSize,
  );
}

void _expectClose(Rect actual, Rect expected, {double tolerance = 3}) {
  for (final (double a, double b) in <(double, double)>[
    (actual.left, expected.left),
    (actual.top, expected.top),
    (actual.right, expected.right),
    (actual.bottom, expected.bottom),
  ]) {
    expect(
      (a - b).abs(),
      lessThanOrEqualTo(tolerance),
      reason: '$actual vs $expected',
    );
  }
}

void main() {
  late File image;

  setUp(() {
    final Directory directory = Directory.systemTemp.createTempSync('preview');
    image = File('${directory.path}/page.png')..writeAsBytesSync(<int>[0]);
    addTearDown(() => directory.deleteSync(recursive: true));
  });

  testWidgets('the crop survives rotating the phone and back', (
    WidgetTester tester,
  ) async {
    final List<(Rect, Size)> reported = <(Rect, Size)>[];

    Widget build(DeviceOrientation orientation) {
      return MaterialApp(
        home: Center(
          child: SizedBox(
            width: 360,
            height: 500,
            child: ScanPreview(
              selectedImage: image,
              imageSize: _imageSize,
              deviceOrientation: orientation,
              onRegionSelected: (Rect region, Size previewSize) =>
                  reported.add((region, previewSize)),
              onSelectionCleared: () {},
            ),
          ),
        ),
      );
    }

    await tester.pumpWidget(build(DeviceOrientation.portraitUp));
    await tester.pump();
    final (Rect defaultRegion, Size portraitSize) = reported.last;

    // The teacher drags the top-left corner inwards.
    await tester.dragFrom(
      tester.getTopLeft(find.byType(ScanPreview)) + defaultRegion.topLeft,
      const Offset(60, 80),
    );
    await tester.pump();
    final (Rect userRegion, Size userSize) = reported.last;
    expect(userRegion, isNot(defaultRegion));
    final Rect userImageRegion = _imageRegionOf(userRegion, userSize);

    // Turned sideways: the preview is rotated and shows a different band
    // of the page; the visible part of the same crop stays selected.
    await tester.pumpWidget(build(DeviceOrientation.landscapeLeft));
    await tester.pump();
    final (Rect landscapeRegion, Size landscapeSize) = reported.last;
    expect(landscapeSize, isNot(portraitSize));

    final Rect landscapeImageRegion = _imageRegionOf(
      landscapeRegion,
      landscapeSize,
    );
    final Rect visibleBand = _imageRegionOf(
      Offset.zero & landscapeSize,
      landscapeSize,
    );
    _expectClose(
      landscapeImageRegion,
      userImageRegion.intersect(visibleBand),
      tolerance: 6,
    );

    // And back upright: the teacher's crop, not the default.
    await tester.pumpWidget(build(DeviceOrientation.portraitUp));
    await tester.pump();
    final (Rect backRegion, Size backSize) = reported.last;
    expect(backSize, portraitSize);
    _expectClose(backRegion, userRegion);

    // Let the double-tap recognizer's timer from the drag expire.
    await tester.pump(const Duration(milliseconds: 500));
  });

  test('preview <-> image mapping round-trips', () {
    const Size preview = Size(360, 500);
    const Rect region = Rect.fromLTWH(80, 120, 200, 240);

    final Rect inImage = ImageCropService.mapPreviewRegionToImage(
      selectedRegion: region,
      previewSize: preview,
      imageSize: _imageSize,
    );
    final Rect back = ImageCropService.mapImageRegionToPreview(
      imageRegion: inImage,
      previewSize: preview,
      imageSize: _imageSize,
    );

    _expectClose(back, region, tolerance: 1);
  });
}
