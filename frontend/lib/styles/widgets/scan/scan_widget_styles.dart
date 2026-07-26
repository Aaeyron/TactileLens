import 'package:flutter/material.dart';

class ScanWidgetStyles {
  const ScanWidgetStyles._();

  // ============================================================
  // SCAN ACTION BUTTONS
  // ============================================================

  static const double actionButtonBottomPadding = 8.0;

  static const double galleryButtonSize = 52.0;
  static const double galleryBorderWidth = 1.0;
  static const double galleryIconSize = 30.0;

  static const double captureButtonSize = 88.0;
  static const double captureBorderWidth = 5.0;
  static const double captureIconSize = 34.0;

  // Colors
static const Color primaryBlue =
    Color(0xFF0D47A1);

static const Color galleryBackgroundColor =
    Colors.white;

static const Color galleryBorderColor =
    Color(0xFFE5E7EB);

static const Color captureIconColor =
    Colors.white;

// Icons
static const IconData galleryButtonIcon =
    Icons.photo_library_outlined;

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
      Color(0xFF0D47A1);

  // ============================================================
  // SCAN PREVIEW
  // ============================================================

  static const double previewHeight = 450.0;

  static const Color previewBackgroundColor =
      Colors.white;

  static const BorderRadius previewBorderRadius =
      BorderRadius.all(
        Radius.circular(20),
      );

  static const Color previewBorderColor =
      Color(0xFFD6DCE5);

  static const double previewBorderWidth = 1.5;

  static const String previewPlaceholderText =
      "Selected image will appear here";

  static const TextStyle previewPlaceholderStyle =
      TextStyle(
        fontSize: 15,
        color: Colors.grey,
        fontWeight: FontWeight.w500,
      );
}