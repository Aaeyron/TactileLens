import 'package:flutter/material.dart';

class ProfileStyles {
  // ==========================
  // Screen Layout
  // ==========================

  static const EdgeInsets screenPadding =
      EdgeInsets.all(20);

  // ==========================
  // Header
  // ==========================

  static const String screenTitle = "Profile";

  static const TextStyle titleStyle = TextStyle(
    fontSize: 22,
    fontWeight: FontWeight.w600,
    color: Colors.black87,
    letterSpacing: 0.2,
  );

  // Keeps the title perfectly centered
  static const double titleRightSpacing = 52;

  // ==========================
  // Back Button
  // ==========================

  static const Alignment backButtonAlignment =
      Alignment.topLeft;

  static const double backIconSize = 28;

  static const Color backIconColor =
      Colors.black87;

  // ==========================
  // Profile Avatar
  // ==========================

  static const double profileAvatarTopSpacing = 30;

  static const double profileAvatarRadius = 60;

  static const double profileAvatarIconSize = 64;

  static const Color profileAvatarBackgroundColor =
      Color(0xFFE5E7EB);

  static const Color profileAvatarIconColor =
      Color(0xFF6B7280);

// ==========================
// Profile Information
// ==========================

static const double profileNameTopSpacing = 20;

static const double profileEmailTopSpacing = 6;

static const TextStyle profileNameStyle = TextStyle(
  fontSize: 24,
  fontWeight: FontWeight.w600,
  color: Colors.black87,
);

static const TextStyle profileEmailStyle = TextStyle(
  fontSize: 15,
  fontWeight: FontWeight.w400,
  color: Colors.black87,
);

// ==========================
// Menu Card
// ==========================

static const double menuTopSpacing = 40;

static const double menuBorderRadius = 10;

// ListTile Layout
static const double menuHorizontalPadding = 20;
static const double menuVerticalPadding = 6;
static const double menuTileHeight = 62;

// Icons
static const double menuIconSize = 26;
static const double menuArrowSize = 22;

// Divider
static const double menuDividerIndent = 20;

// Colors
static const Color menuBackgroundColor = Colors.white;

static const Color menuIconColor =
    Color(0xFF4B5563);

static const Color menuArrowColor =
    Color(0xFF9CA3AF);

static const Color menuDividerColor =
    Color(0xFFE5E7EB);

// Text
static const TextStyle menuTitleStyle = TextStyle(
  fontSize: 16,
  fontWeight: FontWeight.w600,
  color: Colors.black87,
);

// ==========================
// Secondary Menu Card
// ==========================

static const double secondaryMenuTopSpacing = 20;

// ==========================
// Logout Card
// ==========================

static const double logoutMenuTopSpacing = 20;

static const Color logoutIconColor = Color(0xFFDC2626);

static const Color logoutTextColor = Color(0xFFDC2626);

static const TextStyle logoutTitleStyle = TextStyle(
  fontSize: 16,
  fontWeight: FontWeight.w600,
  color: logoutTextColor,
);

}