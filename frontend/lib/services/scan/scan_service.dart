import 'dart:io';

import 'package:file_picker/file_picker.dart';

class ScanService {
  ScanService();

  Future<File?> pickFile() async {
    final result = await FilePicker.pickFiles(
      type: FileType.custom,
      allowedExtensions: <String>['jpg', 'jpeg', 'png'],
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
