import 'package:flutter/material.dart';

class ProfileStyles {
  const ProfileStyles._();

  // ==========================================================
  // SHARED COLORS
  // ==========================================================

  static const Color primaryTextColor = Colors.black87;
  static const Color menuBackgroundColor = Colors.white;

  static const Color backIconColor = Colors.black87;

  static const Color profileAvatarBackgroundColor =
      Color(0xFFE5E7EB);

  static const Color profileAvatarIconColor =
      Color(0xFF6B7280);

  static const Color menuIconColor =
      Color(0xFF4B5563);

  static const Color menuArrowColor =
      Color(0xFF9CA3AF);

  static const Color menuDividerColor =
      Color(0xFFE5E7EB);

  static const Color logoutTextColor =
      Color(0xFFDC2626);

  static const Color logoutIconColor =
      Color(0xFFDC2626);

  // ==========================================================
  // SCREEN LAYOUT
  // ==========================================================

  static const EdgeInsets screenPadding =
      EdgeInsets.all(20);

  // ==========================================================
  // HEADER
  // ==========================================================

  static const String screenTitle = "Profile";

  static const TextStyle titleStyle = TextStyle(
    fontSize: 22,
    fontWeight: FontWeight.w600,
    color: primaryTextColor,
    letterSpacing: 0.2,
  );

  static const double titleRightSpacing = 52;

  // ==========================================================
  // BACK BUTTON
  // ==========================================================

  static const Alignment backButtonAlignment =
      Alignment.topLeft;

  static const double backIconSize = 28;

  static const IconData backIcon =
      Icons.arrow_back;

  // ==========================================================
  // PROFILE AVATAR
  // ==========================================================

  static const double profileAvatarTopSpacing = 30;

  static const double profileAvatarRadius = 60;

  static const double profileAvatarIconSize = 64;

  static const IconData profileAvatarIcon =
      Icons.person;

  // ==========================================================
  // PROFILE INFORMATION
  // ==========================================================

  static const double profileNameTopSpacing = 20;

  static const double profileEmailTopSpacing = 6;

  static const TextStyle profileNameStyle =
      TextStyle(
        fontSize: 24,
        fontWeight: FontWeight.w600,
        color: primaryTextColor,
      );

  static const TextStyle profileEmailStyle =
      TextStyle(
        fontSize: 15,
        fontWeight: FontWeight.w400,
        color: primaryTextColor,
      );

  // ==========================================================
  // MENU CARD
  // ==========================================================

  static const double menuTopSpacing = 40;
  static const double secondaryMenuTopSpacing = 20;
  static const double logoutMenuTopSpacing = 20;

  static const double menuBorderRadius = 10;

  static const double menuHorizontalPadding = 20;
  static const double menuVerticalPadding = 6;
  static const double menuTileHeight = 62;

  static const double menuIconSize = 26;
  static const double menuArrowSize = 22;

  static const double menuDividerIndent = 20;

  static const Clip menuClipBehavior =
      Clip.antiAlias;

  static final List<BoxShadow> menuShadow = [
    BoxShadow(
      color: Colors.black.withValues(alpha: 0.05),
      blurRadius: 12,
      offset: const Offset(0, 4),
    ),
  ];

  // ==========================================================
  // MENU TEXT STYLES
  // ==========================================================

  static const TextStyle menuTitleStyle =
      TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.w600,
        color: primaryTextColor,
      );

  static const TextStyle logoutTitleStyle =
      TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.w600,
        color: logoutTextColor,
      );

  // ==========================================================
  // MENU TITLES
  // ==========================================================

  static const String activityTitle =
      "My Activity";

  static const String savedItemsTitle =
      "Saved Items";

  static const String termsTitle =
      "Terms & Policy";

  static const String settingsTitle =
      "Settings";

  static const String privacyTitle =
      "Privacy & Security";

  static const String logoutTitle =
      "Log Out";

  // ==========================================================
  // MENU ICONS
  // ==========================================================

  static const IconData activityIcon =
      Icons.history;

  static const IconData savedItemsIcon =
      Icons.bookmark_border;

  static const IconData termsIcon =
      Icons.description_outlined;

  static const IconData settingsIcon =
      Icons.settings_outlined;

  static const IconData privacyIcon =
      Icons.shield_outlined;

  static const IconData logoutIcon =
      Icons.logout_rounded;

  static const IconData menuArrowIcon =
      Icons.chevron_right;
}