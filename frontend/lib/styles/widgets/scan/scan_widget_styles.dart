import 'package:flutter/material.dart';

class ScanWidgetStyles {
  const ScanWidgetStyles._();

  // ============================================================
  // BUTTONS
  // ============================================================

  static const double buttonHeight = 52.0;

  static const double buttonSpacing = 12.0;

  static const BorderRadius buttonRadius =
      BorderRadius.all(
        Radius.circular(14),
      );

  static const Color primaryButtonColor =
      Color(0xFF0D47A1);

  static const Color secondaryButtonColor =
      Colors.white;

  static const Color buttonIconColor =
      Colors.white;

  static const TextStyle buttonTextStyle =
      TextStyle(
        fontSize: 15,
        fontWeight: FontWeight.w600,
        color: Colors.white,
      );

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

// ============================================================
// UPLOAD PREVIEW AREA
// ============================================================

static const IconData uploadAreaIcon =
    Icons.document_scanner_outlined;

  static const double uploadIconSize = 60.0;

  static const Color uploadIconColor =
      Color(0xFF0D47A1);

  // ============================================================
// BUTTON ICONS
// ============================================================

static const IconData cameraButtonIcon =
    Icons.camera_alt_outlined;

static const IconData uploadButtonIcon =
    Icons.upload_file_outlined;

// ============================================================
// BUTTON LABELS
// ============================================================

static const String cameraButtonText =
    "Camera";

static const String uploadButtonText =
    "Upload";


// ============================================================
// SCAN PREVIEW
// ============================================================

static const double previewHeight = 320.0;

static const Color previewBackgroundColor =
    Colors.white;

static const BorderRadius previewBorderRadius =
    BorderRadius.all(
      Radius.circular(18),
    );

static const Color previewBorderColor =
    Color(0xFFE5E7EB);

static const double previewBorderWidth = 1.2;

static const String previewPlaceholderText =
    "Selected image will appear here";

static const TextStyle previewPlaceholderStyle =
    TextStyle(
      fontSize: 15,
      color: Colors.grey,
      fontWeight: FontWeight.w500,
    );

}