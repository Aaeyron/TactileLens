import 'dart:io';

import 'package:image/image.dart' as img;
import 'package:path_provider/path_provider.dart';
import 'package:flutter/material.dart';

class ImageCropService {
  Future<File> cropImage({
    required File imageFile,
    required Rect cropRect,
  }) async {
    final bytes = await imageFile.readAsBytes();

    final img.Image? originalImage = img.decodeImage(bytes);

    if (originalImage == null) {
      throw Exception("Failed to decode image.");
    }

    final img.Image croppedImage = img.copyCrop(
      originalImage,
      x: cropRect.left.round(),
      y: cropRect.top.round(),
      width: cropRect.width.round(),
      height: cropRect.height.round(),
    );

    final directory = await getTemporaryDirectory();

    final croppedFile = File(
      "${directory.path}/cropped_equation.png",
    );

    await croppedFile.writeAsBytes(
  img.encodePng(croppedImage),
);

debugPrint("========== CROPPED IMAGE ==========");
debugPrint("Saved at: ${croppedFile.path}");
debugPrint(
  "Crop Size: ${croppedImage.width} x ${croppedImage.height}",
);

return croppedFile;
  }
}