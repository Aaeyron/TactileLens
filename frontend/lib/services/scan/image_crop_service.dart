import 'dart:io';
import 'dart:ui';

import 'package:flutter/foundation.dart';
import 'package:image/image.dart' as img;
import 'package:path_provider/path_provider.dart';

class ImageCropService {
  static const String _croppedFilePrefix = 'tactilelens_document_crop';

  static const String _croppedFileExtension = 'png';

  /// Crops [imageFile] to the region the user selected on the preview.
  ///
  /// The image is decoded only once, in a background isolate, so the
  /// processing animation keeps running.
  Future<File> cropPreviewRegion({
    required File imageFile,
    required Rect selectedRegion,
    required Size previewSize,
  }) async {
    if (!await imageFile.exists()) {
      throw const ImageCropException('The selected image could not be found.');
    }

    final Directory temporaryDirectory = await getTemporaryDirectory();

    final String uniqueIdentifier = DateTime.now().microsecondsSinceEpoch
        .toString();

    final String outputPath = <String>[
      temporaryDirectory.path,
      '$_croppedFilePrefix'
          '_$uniqueIdentifier'
          '.$_croppedFileExtension',
    ].join(Platform.pathSeparator);

    await compute(writePreviewCrop, (
      sourcePath: imageFile.path,
      outputPath: outputPath,
      selectedRegion: selectedRegion,
      previewSize: previewSize,
    ));

    final File croppedFile = File(outputPath);

    if (!await croppedFile.exists()) {
      throw const ImageCropException('The cropped image could not be saved.');
    }

    return croppedFile;
  }

  /// Runs in a background isolate: decode, apply EXIF orientation, map the
  /// preview selection onto the image, crop, and save as PNG.
  @visibleForTesting
  static void writePreviewCrop(
    ({
      String sourcePath,
      String outputPath,
      Rect selectedRegion,
      Size previewSize,
    })
    job,
  ) {
    final img.Image? decodedImage = img.decodeImage(
      File(job.sourcePath).readAsBytesSync(),
    );

    if (decodedImage == null) {
      throw const ImageCropException(
        'The selected image could not be decoded.',
      );
    }

    /*
 * Camera PNG files contain no EXIF rotation, so this is a no-op
 * for captured images. Uploaded JPEG files may still contain EXIF
 * orientation, which must be converted into physical pixel rotation
 * before crop coordinates are applied.
 */
    final img.Image normalizedImage = img.bakeOrientation(decodedImage);

    final Rect cropRect = mapPreviewRegionToImage(
      selectedRegion: job.selectedRegion,
      previewSize: job.previewSize,
      imageSize: Size(
        normalizedImage.width.toDouble(),
        normalizedImage.height.toDouble(),
      ),
    );

    _validateCropRectangle(cropRect);

    final _CropBounds cropBounds = _calculateCropBounds(
      cropRect: cropRect,
      imageWidth: normalizedImage.width,
      imageHeight: normalizedImage.height,
    );

    final img.Image croppedImage = img.copyCrop(
      normalizedImage,
      x: cropBounds.left,
      y: cropBounds.top,
      width: cropBounds.width,
      height: cropBounds.height,
    );

    File(
      job.outputPath,
    ).writeAsBytesSync(img.encodePng(croppedImage), flush: true);
  }

  /// Maps a selection made on the cover-scaled preview back to image
  /// pixels. Keep this synchronized with ScanPreviewStyles.imageFit.
  static Rect mapPreviewRegionToImage({
    required Rect selectedRegion,
    required Size previewSize,
    required Size imageSize,
  }) {
    if (previewSize.isEmpty || imageSize.isEmpty) {
      throw const FormatException('Invalid image or preview dimensions.');
    }

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

    final Rect previewBounds = Offset.zero & previewSize;

    final Rect clippedRegion = selectedRegion.intersect(previewBounds);

    if (clippedRegion.isEmpty) {
      throw const FormatException('The selected crop area is invalid.');
    }

    final double left =
        ((clippedRegion.left - displayedImageOffset.dx) / coverScale)
            .clamp(0.0, imageSize.width)
            .toDouble();

    final double top =
        ((clippedRegion.top - displayedImageOffset.dy) / coverScale)
            .clamp(0.0, imageSize.height)
            .toDouble();

    final double right =
        ((clippedRegion.right - displayedImageOffset.dx) / coverScale)
            .clamp(0.0, imageSize.width)
            .toDouble();

    final double bottom =
        ((clippedRegion.bottom - displayedImageOffset.dy) / coverScale)
            .clamp(0.0, imageSize.height)
            .toDouble();

    if (right <= left || bottom <= top) {
      throw const FormatException('The selected crop area is too small.');
    }

    return Rect.fromLTRB(
      left.roundToDouble(),
      top.roundToDouble(),
      right.roundToDouble(),
      bottom.roundToDouble(),
    );
  }

  static void _validateCropRectangle(Rect cropRect) {
    final bool hasFiniteValues =
        cropRect.left.isFinite &&
        cropRect.top.isFinite &&
        cropRect.right.isFinite &&
        cropRect.bottom.isFinite;

    if (!hasFiniteValues || cropRect.width <= 0 || cropRect.height <= 0) {
      throw const ImageCropException('The selected crop area is invalid.');
    }
  }

  static _CropBounds _calculateCropBounds({
    required Rect cropRect,
    required int imageWidth,
    required int imageHeight,
  }) {
    if (imageWidth <= 0 || imageHeight <= 0) {
      throw const ImageCropException(
        'The selected image has invalid dimensions.',
      );
    }

    final int left = cropRect.left.floor().clamp(0, imageWidth - 1).toInt();

    final int top = cropRect.top.floor().clamp(0, imageHeight - 1).toInt();

    final int right = cropRect.right.ceil().clamp(left + 1, imageWidth).toInt();

    final int bottom = cropRect.bottom
        .ceil()
        .clamp(top + 1, imageHeight)
        .toInt();

    final int width = right - left;
    final int height = bottom - top;

    if (width <= 0 || height <= 0) {
      throw const ImageCropException(
        'The selected crop area is outside the image.',
      );
    }

    return _CropBounds(left: left, top: top, width: width, height: height);
  }
}

class _CropBounds {
  const _CropBounds({
    required this.left,
    required this.top,
    required this.width,
    required this.height,
  });

  final int left;
  final int top;
  final int width;
  final int height;
}

class ImageCropException implements Exception {
  const ImageCropException(this.message);

  final String message;

  @override
  String toString() => message;
}
