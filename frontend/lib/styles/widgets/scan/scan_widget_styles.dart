import 'package:flutter/material.dart';

class ScanWidgetStyles {
  const ScanWidgetStyles._();

  // ============================================================
  // SHARED COLORS
  // ============================================================

  static const Color primaryBlue = Color(0xFF0D47A1);

  static const Color white = Colors.white;

  // ============================================================
  // SCAN ACTION BUTTONS
  // ============================================================

  // Layout
  static const double actionButtonBottomPadding = 8.0;

  /// Moves the gallery button slightly toward the center.
  static const double galleryButtonHorizontalOffset = 18.0;

  // Gallery Button
  static const double galleryButtonSize = 52.0;
  static const double galleryBorderWidth = 1.0;
  static const double galleryIconSize = 30.0;

  static const Color galleryBackgroundColor = white;

  static const Color galleryBorderColor =
      Color(0xFFE5E7EB);

  static const IconData galleryButtonIcon =
      Icons.photo_library_outlined;

  // Capture / Scan Button
  static const double captureButtonSize = 88.0;
  static const double captureBorderWidth = 5.0;
  static const double captureIconSize = 34.0;

  static const Color captureIconColor = white;

  static const IconData captureButtonIcon =
      Icons.camera_alt_rounded;

  static const IconData scanButtonIcon =
      Icons.document_scanner_outlined;

  // ============================================================
  // UPLOAD PREVIEW AREA
  // ============================================================

  static const double uploadAreaHeight = 180.0;

  static const Color uploadAreaColor =
      Color(0xFFF1F5F9);

  static const BorderRadius uploadAreaRadius =
      BorderRadius.all(
        Radius.circular(18),
      );

  static const IconData uploadAreaIcon =
      Icons.document_scanner_outlined;

  static const double uploadIconSize = 60.0;

  static const Color uploadIconColor =
      primaryBlue;

  // ============================================================
  // SCAN PREVIEW
  // ============================================================

  // Layout
  static const double previewHeight = 450.0;

  // Background
  static const Color previewBackgroundColor =
      white;

  // Border
  static const BorderRadius previewBorderRadius =
      BorderRadius.zero;

  static const Color previewBorderColor =
      Color(0xFFD6DCE5);

  static const double previewBorderWidth = 1.5;

  // Placeholder
  static const String previewPlaceholderText =
      "Selected image will appear here";

  static const TextStyle previewPlaceholderStyle =
      TextStyle(
        fontSize: 15,
        color: Colors.grey,
        fontWeight: FontWeight.w500,
      );

  // ============================================================
  // CAMERA PREVIEW
  // ============================================================

  // Layout
  static const EdgeInsets cameraPreviewMargin =
      EdgeInsets.symmetric(horizontal: 20);

  // Border
  static const double cameraPreviewBorderWidth = 2.0;

  static const Color cameraBorderColor =
      primaryBlue;

  // Shadow
  static const double cameraPreviewShadowBlur = 12.0;

  static const Offset cameraPreviewShadowOffset =
      Offset(0, 4);

  // Messages
  static const String cameraErrorText =
      "Unable to open camera.";
}