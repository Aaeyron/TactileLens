import 'dart:io';
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';

class CameraService {
  CameraController? _controller;

  CameraController? get controller => _controller;

  bool get isInitialized =>
      _controller?.value.isInitialized ?? false;

  // ============================================================
  // Initialize Camera
  // ============================================================

  Future<void> initialize() async {
    final cameras = await availableCameras();

    if (cameras.isEmpty) {
      throw Exception('No camera available.');
    }

    final rearCamera = cameras.firstWhere(
      (camera) =>
          camera.lensDirection == CameraLensDirection.back,
      orElse: () => cameras.first,
    );

    _controller = CameraController(
      rearCamera,
      ResolutionPreset.veryHigh,
      enableAudio: false,
    );

    await _controller!.initialize();
  }

// ============================================================
// Capture Image
// ============================================================

Future<File> captureImage() async {
  if (!isInitialized) {
    throw Exception('Camera is not initialized.');
  }

  await Future.delayed(
  const Duration(milliseconds: 250),
);

final XFile image = await _controller!.takePicture();

  return File(image.path);
}

// ============================================================
// Flash
// ============================================================

FlashMode get flashMode =>
    _controller?.value.flashMode ?? FlashMode.off;

Future<void> toggleFlash() async {
  if (!isInitialized) return;

  if (_controller!.value.flashMode == FlashMode.off) {
    await _controller!.setFlashMode(FlashMode.torch);
  } else {
    await _controller!.setFlashMode(FlashMode.off);
  }
}

// ============================================================
// Dispose Camera
// ============================================================

  Future<void> dispose() async {
    await _controller?.dispose();
    _controller = null;
  }

// ============================================================
// Tap to Focus
// ============================================================

Future<void> focusOnPoint(Offset point, Size previewSize) async {
  if (!isInitialized) return;

  final double x = point.dx / previewSize.width;
  final double y = point.dy / previewSize.height;

  await _controller!.setFocusPoint(
    Offset(x, y),
  );
}

}