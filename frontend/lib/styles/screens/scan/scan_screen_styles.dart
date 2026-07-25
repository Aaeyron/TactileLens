import 'package:flutter/material.dart';

class ScanScreenStyles {
  const ScanScreenStyles._();

  // ============================================================
  // SCREEN
  // ============================================================

  static const Color backgroundColor =
      Colors.white;

  static const EdgeInsets contentPadding =
      EdgeInsets.all(20);


  // ============================================================
  // SPACING
  // ============================================================

  static const double sectionSpacing =
      20.0;

  static const double buttonSpacing =
      12.0;

  // ============================================================
  // BUTTONS
  // ============================================================

  static const double buttonHeight =
      52.0;

  static const BorderRadius buttonRadius =
      BorderRadius.all(
        Radius.circular(14),
      );

  static const Color primaryButtonColor =
      Color(0xFF0D47A1);

  static const TextStyle buttonTextStyle =
      TextStyle(
    fontSize: 15,
    fontWeight: FontWeight.w600,
    color: Colors.white,
  );

// ============================================================
// SCREEN LAYOUT SPACING
// ============================================================

static const double topContentSpacing = 40.0;

// ============================================================
// CAMERA SCREEN SPACING
// ============================================================

// Space from the top of the screen to the scan mode selector.
static const double modeSelectorTopSpacing = 35.0;

// Space between the scan mode selector and the live camera.
static const double toggleBottomSpacing = 20.0;

// Space between the live camera and the bottom action buttons.
static const double cameraBottomSpacing = 24.0;

// ============================================================
// BACK BUTTON
// ============================================================

static const double backButtonTopSpacing = 10.0;

static const double backButtonBottomSpacing = 16.0;

static const Color backButtonColor =
    Color(0xFF0D47A1);

}