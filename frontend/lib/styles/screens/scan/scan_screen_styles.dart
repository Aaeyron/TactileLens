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
  // PAGE TITLE
  // ============================================================

  static const TextStyle pageTitleStyle =
      TextStyle(
    fontSize: 24,
    fontWeight: FontWeight.bold,
    color: Colors.black87,
  );


  static const double titleDescriptionSpacing =
      8.0;


  // ============================================================
  // PAGE DESCRIPTION
  // ============================================================

  static const TextStyle pageDescriptionStyle =
      TextStyle(
    fontSize: 14,
    color: Colors.grey,
    height: 1.5,
  );


  // ============================================================
  // UPLOAD PREVIEW AREA
  // ============================================================

  static const double uploadAreaHeight =
      180.0;


  static const Color uploadAreaColor =
      Color(0xFFF1F5F9);


  static const BorderRadius uploadAreaRadius =
      BorderRadius.all(
        Radius.circular(18),
      );


  static const double uploadIconSize =
      60.0;


  static const Color uploadIconColor =
      Color(0xFF0D47A1);


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

}