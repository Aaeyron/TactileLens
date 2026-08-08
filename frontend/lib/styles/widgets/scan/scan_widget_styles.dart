import 'package:flutter/material.dart';

abstract final class ScanWidgetStyles {
  // ============================================================
  // SHARED COLORS
  // ============================================================

  static const Color primaryBlue = Color(0xFF0D47A1);
  static const Color white = Color(0xFFFFFFFF);
  static const Color disabledColor = Color(0xFF9E9E9E);

  static const Color subtleShadowColor = Color(0x0F000000);
  static const Color captureShadowColor = Color(0x2E000000);

  // ============================================================
  // SCAN ACTION BUTTONS
  // ============================================================

  // Layout
  static const double actionButtonBottomPadding = 8.0;

  static const EdgeInsets actionButtonHorizontalPadding =
      EdgeInsets.symmetric(horizontal: 30.0);

  static const MainAxisAlignment actionButtonAlignment =
      MainAxisAlignment.spaceBetween;

  static const CrossAxisAlignment actionButtonCrossAlignment =
      CrossAxisAlignment.end;

  // Disabled state
  static const double enabledButtonOpacity = 1.0;
  static const double disabledButtonOpacity = 0.55;

  static const Duration buttonOpacityDuration =
      Duration(milliseconds: 180);

  // Gallery and flash buttons
  static const double galleryButtonSize = 52.0;
  static const double galleryBorderWidth = 1.0;
  static const double galleryIconSize = 30.0;

  static const Color galleryBackgroundColor = white;
  static const Color galleryBorderColor = Color(0xFFE5E7EB);

  static const IconData galleryButtonIcon =
      Icons.photo_library_outlined;

  // Flash button
  static const double flashIconSize = 30.0;
  static const Color flashEnabledColor = primaryBlue;
  static const Color flashDisabledColor = disabledColor;

  static const IconData flashEnabledIcon =
      Icons.flash_on_rounded;

  static const IconData flashDisabledIcon =
      Icons.flash_off_rounded;

  // Secondary button shadow
  static const double secondaryButtonShadowBlurRadius = 10.0;

  static const Offset secondaryButtonShadowOffset =
      Offset(0.0, 2.0);

  static const List<BoxShadow> secondaryButtonShadow = [
    BoxShadow(
      color: subtleShadowColor,
      blurRadius: secondaryButtonShadowBlurRadius,
      offset: secondaryButtonShadowOffset,
    ),
  ];

  // Capture / scan button
  static const double captureButtonSize = 88.0;
  static const double captureBorderWidth = 5.0;
  static const double captureIconSize = 34.0;

  static const Color captureIconColor = white;

  static const IconData captureButtonIcon =
      Icons.camera_alt_rounded;

  static const IconData scanButtonIcon =
      Icons.document_scanner_outlined;

  static const double captureButtonShadowBlurRadius = 16.0;

  static const Offset captureButtonShadowOffset =
      Offset(0.0, 6.0);

  static const List<BoxShadow> captureButtonShadow = [
    BoxShadow(
      color: captureShadowColor,
      blurRadius: captureButtonShadowBlurRadius,
      offset: captureButtonShadowOffset,
    ),
  ];

  // Processing indicator
  static const double processingIndicatorSize = 30.0;
  static const double processingIndicatorStrokeWidth = 3.0;
  static const Color processingIndicatorColor = white;

  // Accessibility labels
  static const String uploadButtonLabel = 'Upload image';
  static const String cameraButtonLabel = 'Capture image';
  static const String scanButtonLabel = 'Scan document';
  static const String processingButtonLabel = 'Scanning document';
  static const String flashButtonLabel = 'Toggle camera flash';

  // ============================================================
  // UPLOAD PREVIEW AREA
  // ============================================================

  static const double uploadAreaHeight = 180.0;
  static const Color uploadAreaColor = Color(0xFFF1F5F9);

  static const BorderRadius uploadAreaRadius =
      BorderRadius.all(Radius.circular(18.0));

  static const IconData uploadAreaIcon =
      Icons.document_scanner_outlined;

  static const double uploadIconSize = 60.0;
  static const Color uploadIconColor = primaryBlue;

  // ============================================================
  // SCAN PREVIEW
  // ============================================================

  static const double previewHeight = 500.0;
  static const Color previewBackgroundColor = white;

  static const BorderRadius previewBorderRadius =
      BorderRadius.zero;

  static const Color previewBorderColor = Color(0xFFD6DCE5);
  static const double previewBorderWidth = 1.5;

  static const String previewPlaceholderText =
      'Selected image will appear here';

  static const TextStyle previewPlaceholderStyle = TextStyle(
    fontSize: 15.0,
    color: disabledColor,
    fontWeight: FontWeight.w500,
  );

 static const BoxFit previewImageFit = BoxFit.cover;

// ============================================================
// SELECTION OVERLAY
// ============================================================

static const Color selectionFillColor =
    Color(0x260D47A1);

static const Color selectionBorderColor =
    primaryBlue;

static const double selectionBorderWidth = 2.0;

static const double minimumSelectionWidth = 24.0;

static const double minimumSelectionHeight = 24.0;

  // ============================================================
  // CAMERA PREVIEW
  // ============================================================

  static const EdgeInsets cameraPreviewMargin =
      EdgeInsets.symmetric(horizontal: 20.0);

  static const double cameraPreviewBorderWidth = 2.0;
  static const Color cameraBorderColor = primaryBlue;

  static const double cameraPreviewShadowBlur = 12.0;

  static const Offset cameraPreviewShadowOffset =
      Offset(0.0, 4.0);

  static const List<BoxShadow> cameraPreviewShadow = [
    BoxShadow(
      color: subtleShadowColor,
      blurRadius: cameraPreviewShadowBlur,
      offset: cameraPreviewShadowOffset,
    ),
  ];

  // Focus indicator
  static const double focusIndicatorSize = 60.0;
  static const double focusIndicatorHalfSize = 30.0;
  static const double focusIndicatorBorderWidth = 2.0;

  static const BorderRadius focusIndicatorRadius =
      BorderRadius.all(Radius.circular(8.0));

  static const Color focusIndicatorColor = white;

  static const Duration focusIndicatorDuration =
      Duration(milliseconds: 800);

  // Messages
  static const String cameraErrorText = 'Unable to open camera.';
}