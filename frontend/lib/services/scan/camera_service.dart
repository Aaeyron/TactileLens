import 'dart:io';

import 'package:camera/camera.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image/image.dart' as img;

class CameraService {
  CameraController? _controller;

  bool _isCapturing = false;

  CameraController? get controller => _controller;

  bool get isInitialized {
    return _controller?.value.isInitialized ?? false;
  }

  bool get isCapturing => _isCapturing;

  FlashMode get flashMode {
    return _controller?.value.flashMode ?? FlashMode.off;
  }

  // ============================================================
  // Initialize Camera
  // ============================================================

  Future<void> initialize() async {
    if (isInitialized) {
      return;
    }

    final List<CameraDescription> cameras = await availableCameras();

    if (cameras.isEmpty) {
      throw CameraException(
        'camera_unavailable',
        'No camera is available on this device.',
      );
    }

    final CameraDescription rearCamera = cameras.firstWhere((
      CameraDescription camera,
    ) {
      return camera.lensDirection == CameraLensDirection.back;
    }, orElse: () => cameras.first);

    final CameraController cameraController = CameraController(
      rearCamera,
      ResolutionPreset.veryHigh,
      enableAudio: false,
      imageFormatGroup: ImageFormatGroup.jpeg,
    );

    try {
      await cameraController.initialize();
      await cameraController.setFlashMode(FlashMode.off);

      _controller = cameraController;
    } catch (_) {
      await cameraController.dispose();
      rethrow;
    }
  }

  // ============================================================
  // Capture Image
  // ============================================================

  Future<File> captureImage({required DeviceOrientation orientation}) async {
    final CameraController? cameraController = _controller;

    if (cameraController == null || !cameraController.value.isInitialized) {
      throw CameraException(
        'camera_not_initialized',
        'Camera is not initialized.',
      );
    }

    if (_isCapturing || cameraController.value.isTakingPicture) {
      throw CameraException(
        'capture_in_progress',
        'A picture is already being captured.',
      );
    }

    _isCapturing = true;

    try {
      await Future<void>.delayed(const Duration(milliseconds: 350));

      final DeviceOrientation deviceOrientation =
          cameraController.value.deviceOrientation;

      debugPrint('Requested capture layout: $orientation');

      debugPrint('Camera device orientation: $deviceOrientation');

      final XFile capturedImage = await cameraController.takePicture();

      final File originalFile = File(capturedImage.path);

      if (!await originalFile.exists()) {
        throw CameraException(
          'capture_file_missing',
          'The captured image could not be found.',
        );
      }

      return _normalizeCapturedImage(
        imageFile: originalFile,
        captureOrientation: orientation,
      );
    } finally {
      _isCapturing = false;
    }
  }

  // ============================================================
  // Normalize Captured Orientation
  // ============================================================

  Future<File> _normalizeCapturedImage({
    required File imageFile,
    required DeviceOrientation captureOrientation,
  }) async {
    /*
   * PNG does not retain the JPEG EXIF orientation that caused the
   * later crop and preview stages to rotate the image again.
   */
    final String normalizedPath = <String>[
      imageFile.parent.path,
      'tactilelens_capture_'
          '${DateTime.now().microsecondsSinceEpoch}.png',
    ].join(Platform.pathSeparator);

    /*
 * Some Android cameras return portrait pixel dimensions even
 * though the device was held sideways. Those pixels are rotated
 * once by this angle before saving the metadata-free PNG.
 */
    final num? landscapeRotation = switch (captureOrientation) {
      DeviceOrientation.landscapeLeft => -90,
      DeviceOrientation.landscapeRight => 90,
      _ => null,
    };

    // Decoding and PNG encoding are slow, so they run off the UI isolate.
    final ({int width, int height})? dimensions = await compute(
      _writeNormalizedCapture,
      (
        sourcePath: imageFile.path,
        outputPath: normalizedPath,
        landscapeRotation: landscapeRotation,
      ),
    );

    if (dimensions == null) {
      throw CameraException(
        'capture_decode_failed',
        'The captured image could not be decoded.',
      );
    }

    final File normalizedFile = File(normalizedPath);

    if (!await normalizedFile.exists()) {
      throw CameraException(
        'normalized_capture_missing',
        'The normalized captured image could not be saved.',
      );
    }

    debugPrint(
      'Normalized PNG dimensions: '
      '${dimensions.width}x'
      '${dimensions.height}',
    );

    return normalizedFile;
  }

  // ============================================================
  // Flash
  // ============================================================

  Future<void> toggleFlash() async {
    final CameraController? cameraController = _controller;

    if (cameraController == null ||
        !cameraController.value.isInitialized ||
        _isCapturing) {
      return;
    }

    final FlashMode nextFlashMode =
        cameraController.value.flashMode == FlashMode.off
        ? FlashMode.torch
        : FlashMode.off;

    await cameraController.setFlashMode(nextFlashMode);
  }

  // ============================================================
  // Tap to Focus
  // ============================================================

  Future<void> focusOnPoint(Offset point, Size previewSize) async {
    final CameraController? cameraController = _controller;

    if (cameraController == null ||
        !cameraController.value.isInitialized ||
        _isCapturing ||
        previewSize.isEmpty) {
      return;
    }

    final double normalizedX = (point.dx / previewSize.width)
        .clamp(0.0, 1.0)
        .toDouble();

    final double normalizedY = (point.dy / previewSize.height)
        .clamp(0.0, 1.0)
        .toDouble();

    final Offset focusPoint = Offset(normalizedX, normalizedY);

    if (cameraController.value.focusPointSupported) {
      await cameraController.setFocusPoint(focusPoint);
    }

    if (cameraController.value.exposurePointSupported) {
      await cameraController.setExposurePoint(focusPoint);
    }
  }

  // ============================================================
  // Dispose Camera
  // ============================================================

  Future<void> dispose() async {
    final CameraController? cameraController = _controller;

    _controller = null;
    _isCapturing = false;

    if (cameraController == null) {
      return;
    }

    if (cameraController.value.isInitialized &&
        cameraController.value.flashMode == FlashMode.torch) {
      try {
        await cameraController.setFlashMode(FlashMode.off);
      } catch (error) {
        debugPrint('Unable to disable the camera flash: $error');
      }
    }

    await cameraController.dispose();
  }
}

/// Runs in a background isolate: apply the camera JPEG's EXIF orientation
/// exactly once (Android's camera plugin records the physical device
/// direction there), rotate sideways captures that still have portrait
/// pixels, and save the result as a metadata-free PNG.
({int width, int height})? _writeNormalizedCapture(
  ({String sourcePath, String outputPath, num? landscapeRotation}) job,
) {
  final img.Image? decodedImage = img.decodeImage(
    File(job.sourcePath).readAsBytesSync(),
  );

  if (decodedImage == null) {
    return null;
  }

  img.Image normalizedImage = img.bakeOrientation(decodedImage);

  final num? rotationAngle = job.landscapeRotation;

  if (rotationAngle != null &&
      normalizedImage.height > normalizedImage.width) {
    normalizedImage = img.copyRotate(normalizedImage, angle: rotationAngle);
  }

  File(
    job.outputPath,
  ).writeAsBytesSync(img.encodePng(normalizedImage), flush: true);

  return (width: normalizedImage.width, height: normalizedImage.height);
}
