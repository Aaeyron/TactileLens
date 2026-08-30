import 'package:flutter/material.dart';

abstract final class MainStyles {
  // Colors
  static const Color navBackgroundColor = Colors.white;
  static const Color selectedItemColor = Color(0xFF1268F3);
  static const Color unselectedItemColor = Color(0xFF667085);
  static const Color navBorderColor = Color(0xFFD1D5DB);

  static const Color fabBackgroundColor = Color(0xFF1268F3);
  static const Color fabIconColor = Colors.white;

  // Labels
  static const String homeLabel = 'Home';
  static const String materialsLabel = 'Materials';
  static const String historyLabel = 'History';
  static const String profileLabel = 'Profile';
  static const String scanTooltip = 'Scan Material';

  // Bottom navigation
  static const double navElevation = 10;
  static const double navBorderWidth = 1;
  static const double bottomBarHeight = 76;
  static const double iconSize = 24;
  static const double iconLabelSpacing = 4;
  static const double labelFontSize = 11;

  static const FontWeight selectedLabelWeight = FontWeight.w700;
  static const FontWeight unselectedLabelWeight = FontWeight.w500;

  static const EdgeInsets navigationItemPadding = EdgeInsets.symmetric(
    horizontal: 3,
    vertical: 8,
  );

  // Floating camera button
  static const double fabSize = 64;
  static const double fabIconSize = 30;
  static const double fabElevation = 8;
  static const double fabMargin = 10;

  static const Offset fabOffset = Offset(0, 20);

  static const FloatingActionButtonLocation fabLocation =
      FloatingActionButtonLocation.centerDocked;

  static const NotchedShape bottomBarShape = CircularNotchedRectangle();

  static const double centerGapWidth = 64;
}
