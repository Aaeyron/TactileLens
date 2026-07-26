import 'dart:io';

import 'package:file_picker/file_picker.dart';

class ScanService {
  ScanService();

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
}