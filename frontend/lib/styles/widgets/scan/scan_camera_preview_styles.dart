import 'package:flutter/material.dart';

abstract final class ScanCameraPreviewStyles {
  // Colors
  static const Color primaryColor = Color(0xFF1268F3);
  static const Color backgroundColor = Color(0xFF111820);
  static const Color placeholderColor = Color(0xFFD8E1ED);
  static const Color focusIndicatorColor = Colors.white;
  static const Color previewBorderColor = Colors.transparent;

  // Camera preview
  static const double portraitPreviewHeight = 500;
  static const double landscapePreviewHeight = 280;
  static const double previewBorderWidth = 0;

  static const BorderRadius previewBorderRadius = BorderRadius.zero;

  static const BoxFit previewImageFit = BoxFit.cover;

  // Placeholder
  static const TextStyle placeholderStyle = TextStyle(
    color: placeholderColor,
    fontSize: 15,
    fontWeight: FontWeight.w500,
  );

  // Loading indicator
  static const double loadingIndicatorSize = 38;
  static const double loadingIndicatorStrokeWidth = 3;

  // Focus indicator
  static const double focusIndicatorSize = 60;
  static const double focusIndicatorHalfSize = 30;
  static const double focusIndicatorBorderWidth = 2;

  static const BorderRadius focusIndicatorRadius = BorderRadius.all(
    Radius.circular(8),
  );

  static const Duration focusIndicatorDuration = Duration(milliseconds: 800);
}
