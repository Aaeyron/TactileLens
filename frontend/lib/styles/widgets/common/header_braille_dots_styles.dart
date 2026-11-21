import 'package:flutter/material.dart';

/// The Braille dots in the corner of every header bar: two Braille cells
/// side by side (4 columns x 3 rows), white at low opacity.
abstract final class HeaderBrailleDotsStyles {
  static const int columns = 4;
  static const int rows = 3;

  static const double dotSize = 4;
  static const double dotSpacing = 7;

  static const Color dotColor = Colors.white;
  static const double opacity = 0.18;

  /// 4 x 4 + 3 x 7 = 37.
  static const double width = columns * dotSize + (columns - 1) * dotSpacing;

  /// 3 x 4 + 2 x 7 = 26.
  static const double height = rows * dotSize + (rows - 1) * dotSpacing;
}
