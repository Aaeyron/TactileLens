import 'package:flutter/material.dart';

class LogoutDialogStyles {
  const LogoutDialogStyles._();

  // ==========================================================
  // DIALOG SHAPE
  // ==========================================================

  static const double dialogBorderRadius = 20;

  // ==========================================================
  // COLORS
  // ==========================================================

  static const Color logoutIconColor =
      Color(0xFFDC2626);

  static const Color logoutButtonColor =
      Color(0xFFDC2626);

  static const Color logoutButtonTextColor =
      Colors.white;

  // ==========================================================
  // ICONS
  // ==========================================================

  static const IconData logoutIcon =
      Icons.logout_rounded;

  // ==========================================================
  // TEXT
  // ==========================================================

  static const String dialogTitle =
      "Log Out";

  static const String dialogMessage =
      "Are you sure you want to log out?";

  static const String cancelButtonText =
      "Cancel";

  static const String confirmButtonText =
      "Log Out";

  // ==========================================================
  // SPACING
  // ==========================================================

  static const double titleIconSpacing = 10;
}