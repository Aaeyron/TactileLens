import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:image_picker/image_picker.dart';

class ScanService {
  ScanService();

  final ImagePicker _imagePicker = ImagePicker();

  // ============================================================
  // Upload Image or PDF
  // ============================================================

  Future<File?> pickFile() async {
    final result = await FilePicker.pickFiles(
      type: FileType.custom,
      allowedExtensions: [
        'jpg',
        'jpeg',
        'png',
        'pdf',
      ],
    );

    if (result == null) {
      return null;
    }

    final path = result.files.single.path;

    if (path == null) {
      return null;
    }

    return File(path);
  }

  // ============================================================
  // Capture Image
  // ============================================================

  Future<File?> captureImage() async {
    final XFile? image = await _imagePicker.pickImage(
      source: ImageSource.camera,
      imageQuality: 100,
    );

    if (image == null) {
      return null;
    }

    return File(image.path);
  }
}