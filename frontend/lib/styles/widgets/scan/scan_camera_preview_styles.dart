import 'package:flutter/material.dart';

abstract final class ScanCameraPreviewStyles {
  static const Color primaryColor = Color(0xFF1268F3);
  static const Color backgroundColor = Color(0xFF111820);
  static const Color placeholderColor = Color(0xFFD8E1ED);
  static const Color focusIndicatorColor = Colors.white;

  static const double previewHeight = 500;
  static const double previewBorderWidth = 0;

  static const BorderRadius previewBorderRadius = BorderRadius.zero;

  static const Color previewBorderColor = Colors.transparent;

  static const BoxFit previewImageFit = BoxFit.cover;

  static const String cameraErrorText = 'Unable to open camera.';

  static const TextStyle placeholderStyle = TextStyle(
    color: placeholderColor,
    fontSize: 15,
    fontWeight: FontWeight.w500,
  );

  static const double loadingIndicatorSize = 38;
  static const double loadingIndicatorStrokeWidth = 3;

  static const double focusIndicatorSize = 60;
  static const double focusIndicatorHalfSize = 30;
  static const double focusIndicatorBorderWidth = 2;

  static const BorderRadius focusIndicatorRadius = BorderRadius.all(
    Radius.circular(8),
  );

  static const Duration focusIndicatorDuration = Duration(milliseconds: 800);
}
