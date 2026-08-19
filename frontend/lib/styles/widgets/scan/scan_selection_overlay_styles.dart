import 'package:flutter/material.dart';

abstract final class ScanSelectionOverlayStyles {
  // ==========================================================
  // CONTENT
  // ==========================================================

  static const String semanticLabel = 'Adjust the document crop area';

  static const String resetLabel = 'Reset';
  static const String resetTooltip = 'Reset the crop area';

  // ==========================================================
  // COLORS
  // ==========================================================

  static const Color primaryColor = Color(0xFF1268F3);
  static const Color surfaceColor = Colors.white;

  static const Color outsideMaskColor = Color(0x8A000000);

  static const Color cropBorderColor = Color(0xE6FFFFFF);

  static const Color gridColor = Color(0x8FFFFFFF);

  static const Color handleFillColor = Colors.white;

  static const Color handleBorderColor = primaryColor;

  static const Color resetBackgroundColor = Color(0xD9141B25);

  static const Color resetForegroundColor = Colors.white;

  // ==========================================================
  // DEFAULT FRAME
  // ==========================================================

  static const double defaultHorizontalInset = 23;
  static const double defaultVerticalInset = 66;

  static const double minimumSelectionWidth = 96;
  static const double minimumSelectionHeight = 96;

  // ==========================================================
  // CROP BORDER
  // ==========================================================

  static const double cropBorderWidth = 1.4;

  static const double cropCornerRadius = 8;

  static const double cornerLength = 36;
  static const double cornerStrokeWidth = 5;

  // ==========================================================
  // HANDLES
  // ==========================================================

  static const double handleRadius = 9;
  static const double handleBorderWidth = 3;

  static const double handleTouchRadius = 30;

  // ==========================================================
  // GRID
  // ==========================================================

  static const double gridStrokeWidth = 1;

  static const int gridDivisionCount = 3;

  // ==========================================================
  // RESET BUTTON
  // ==========================================================

  static const double resetRight = 16;
  static const double resetBottom = 84;

  static const double resetIconSize = 18;
  static const double resetIconSpacing = 6;

  static const EdgeInsets resetButtonPadding = EdgeInsets.symmetric(
    horizontal: 13,
    vertical: 9,
  );

  static const BorderRadius resetButtonRadius = BorderRadius.all(
    Radius.circular(22),
  );

  static const TextStyle resetButtonTextStyle = TextStyle(
    color: resetForegroundColor,
    fontSize: 13,
    fontWeight: FontWeight.w600,
  );

  static const List<BoxShadow> resetButtonShadow = <BoxShadow>[
    BoxShadow(color: Color(0x52000000), blurRadius: 12, offset: Offset(0, 5)),
  ];
}
