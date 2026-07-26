import 'dart:io';
import 'package:camera/camera.dart';

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
      ResolutionPreset.high,
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

  final XFile image = await _controller!.takePicture();

  return File(image.path);
}

  // ============================================================
  // Dispose Camera
  // ============================================================

  Future<void> dispose() async {
    await _controller?.dispose();
    _controller = null;
  }
}