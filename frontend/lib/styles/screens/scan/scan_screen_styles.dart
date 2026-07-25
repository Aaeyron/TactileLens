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

static const double cameraTopSpacing = 100.0;

static const double cameraBottomSpacing = 24.0;

}