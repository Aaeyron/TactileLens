import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:image/image.dart' as img;

/// Makes a captured or picked image upright, once, right after capture or
/// pick, so every later step (preview, crop, upload, offline scan) sees
/// upright pixels and no EXIF.
///
/// - The EXIF orientation is applied to the pixels, then all EXIF is
///   removed (orientation, and anything else such as location).
/// - Camera only, when the camera wrote no rotation: a photo taken
///   sideways that still has portrait pixels is turned 90 degrees, and one
///   taken upside-down is turned 180 degrees, from the way the phone was
///   held ([capturedIn]). If the camera wrote a rotation, it is trusted.
/// - A gallery image without any EXIF is used as it is.
///
/// The JPEG decoder applies the EXIF orientation itself and drops the
/// tag, so the orientation is read from the original bytes first.
///
/// Phones differ in what their camera writes, so the camera rules are
/// checked on a phone (see docs/architecture.md).
class ImageOrientationService {
  const ImageOrientationService();

  /// Upright copy of [source] as a metadata-free PNG next to [source], or
  /// [source] itself when nothing needed to change.
  Future<File> normalizeFile(
    File source, {
    DeviceOrientation? capturedIn,
  }) async {
    final String? output = await compute(writeNormalized, (
      sourcePath: source.path,
      outputDirectory: source.parent.path,
      capturedIn: capturedIn,
    ));

    if (output == null) {
      throw const FormatException('The image could not be decoded.');
    }

    return File(output);
  }

  /// Runs in a background isolate (camera captures and gallery picks).
  /// Returns the path of the upright image (the source path when
  /// unchanged), or null if it cannot be decoded.
  static String? writeNormalized(
    ({String sourcePath, String outputDirectory, DeviceOrientation? capturedIn})
    job,
  ) {
    final Uint8List bytes = File(job.sourcePath).readAsBytesSync();

    // A gallery image with no EXIF at all is already upright and clean.
    if (job.capturedIn == null && _exifOf(bytes) == null) {
      return _decode(bytes) == null ? null : job.sourcePath;
    }

    final img.Image? upright = normalizeBytes(
      bytes,
      capturedIn: job.capturedIn,
    );

    if (upright == null) {
      return null;
    }

    final String outputPath = <String>[
      job.outputDirectory,
      'tactilelens_${job.capturedIn == null ? 'picked' : 'capture'}_'
          '${DateTime.now().microsecondsSinceEpoch}.png',
    ].join(Platform.pathSeparator);

    File(outputPath).writeAsBytesSync(img.encodePng(upright), flush: true);

    return outputPath;
  }

  /// The upright, metadata-free image in [bytes], or null if it cannot be
  /// decoded.
  static img.Image? normalizeBytes(
    Uint8List bytes, {
    DeviceOrientation? capturedIn,
  }) {
    final int exifOrientation = _exifOf(bytes)?.imageIfd.orientation ?? 1;
    final img.Image? decoded = _decode(bytes);

    if (decoded == null) {
      return null;
    }

    // JPEG: already applied by the decoder. Other formats: applied here.
    img.Image upright = img.bakeOrientation(decoded);

    // The camera wrote no rotation: use how the phone was held.
    if (capturedIn != null && exifOrientation == 1) {
      final bool portraitPixels = upright.height > upright.width;

      switch (capturedIn) {
        case DeviceOrientation.landscapeLeft when portraitPixels:
          upright = img.copyRotate(upright, angle: -90);
        case DeviceOrientation.landscapeRight when portraitPixels:
          upright = img.copyRotate(upright, angle: 90);
        case DeviceOrientation.portraitDown:
          upright = img.copyRotate(upright, angle: 180);
        default:
          break;
      }
    }

    return upright..exif = img.ExifData();
  }

  static img.Image? _decode(Uint8List bytes) {
    try {
      return img.decodeImage(bytes);
    } catch (_) {
      return null;
    }
  }

  /// The EXIF of a JPEG, or null when there is none (or not a JPEG).
  static img.ExifData? _exifOf(Uint8List bytes) {
    try {
      final img.ExifData? exif = img.decodeJpgExif(bytes);
      return exif == null || exif.isEmpty ? null : exif;
    } catch (_) {
      return null;
    }
  }
}
