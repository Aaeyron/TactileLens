import 'dart:io';
import 'dart:typed_data';
import 'dart:ui';

import 'package:image/image.dart' as img;
import 'package:path_provider/path_provider.dart';

class ImageCropService {
  static const String _croppedFilePrefix = 'tactilelens_document_crop';

  static const String _croppedFileExtension = 'png';

  Future<File> cropImage({
    required File imageFile,
    required Rect cropRect,
  }) async {
    if (!await imageFile.exists()) {
      throw const ImageCropException('The selected image could not be found.');
    }

    _validateCropRectangle(cropRect);

    final Uint8List bytes = await imageFile.readAsBytes();

    final img.Image? decodedImage = img.decodeImage(bytes);

    if (decodedImage == null) {
      throw const ImageCropException(
        'The selected image could not be decoded.',
      );
    }

    /*
     * Convert the EXIF camera orientation into actual pixel
     * orientation. This ensures portrait and landscape images use
     * the same dimensions that the user sees in the preview.
     */
    /*
 * Camera captures are already normalized and saved as PNG.
 * Uploaded images are decoded in their stored pixel orientation.
 * Do not apply orientation a second time here.
 */
    final img.Image normalizedImage = decodedImage;

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

    final Directory temporaryDirectory = await getTemporaryDirectory();

    final String uniqueIdentifier = DateTime.now().microsecondsSinceEpoch
        .toString();

    final String outputPath = <String>[
      temporaryDirectory.path,
      '$_croppedFilePrefix'
          '_$uniqueIdentifier'
          '.$_croppedFileExtension',
    ].join(Platform.pathSeparator);

    final File croppedFile = File(outputPath);

    await croppedFile.writeAsBytes(img.encodePng(croppedImage), flush: true);

    if (!await croppedFile.exists()) {
      throw const ImageCropException('The cropped image could not be saved.');
    }

    return croppedFile;
  }

  void _validateCropRectangle(Rect cropRect) {
    final bool hasFiniteValues =
        cropRect.left.isFinite &&
        cropRect.top.isFinite &&
        cropRect.right.isFinite &&
        cropRect.bottom.isFinite;

    if (!hasFiniteValues || cropRect.width <= 0 || cropRect.height <= 0) {
      throw const ImageCropException('The selected crop area is invalid.');
    }
  }

  _CropBounds _calculateCropBounds({
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
