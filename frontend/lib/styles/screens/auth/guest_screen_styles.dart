import 'package:flutter/material.dart';

class GuestStyles {
  const GuestStyles._();

  // ==========================================================
  // COLORS
  // ==========================================================

  static const Color backgroundColor = Colors.white;

  static const Color primaryColor = Color(0xFF0D47A1);

  static const Color titleColor = Colors.black;

  static const Color descriptionColor = Colors.grey;

  // ==========================================================
  // PADDING
  // ==========================================================

  static const EdgeInsets pagePadding = EdgeInsets.all(24);

  // ==========================================================
  // SPACING
  // ==========================================================

  static const double titleTopSpacing = 20;

  static const double titleBottomSpacing = 10;

  static const double descriptionBottomSpacing = 40;

  static const double nicknameBottomSpacing = 30;

  static const double roleTitleBottomSpacing = 10;

  // ==========================================================
  // TEXT STYLES
  // ==========================================================

  static const TextStyle titleStyle = TextStyle(
    fontFamily: 'Poppins',
    fontSize: 24,
    fontWeight: FontWeight.w600,
    color: titleColor,
  );

  static const TextStyle descriptionStyle = TextStyle(
    fontFamily: 'Poppins',
    fontSize: 15,
    color: descriptionColor,
    height: 1.5,
  );

  static const TextStyle roleTitleStyle = TextStyle(
    fontFamily: 'Poppins',
    fontSize: 15,
    fontWeight: FontWeight.w600,
    color: titleColor,
  );

  static const TextStyle buttonTextStyle = TextStyle(
    fontFamily: 'Poppins',
    fontSize: 16,
    fontWeight: FontWeight.w600,
    color: Colors.white,
  );

  // ==========================================================
  // BUTTON
  // ==========================================================

  static const double buttonHeight = 55;

  static const double buttonTopSpacing = 24.0;
}