import 'package:flutter/material.dart';

class AccountInformationStyles {
  const AccountInformationStyles._();

  // ==========================================================
  // SHARED COLORS
  // ==========================================================

  static const Color primaryTextColor = Colors.black87;

  static const Color appPrimaryColor =
      Color(0xFF0D47A1);

  static const Color dividerColor =
      Color(0xFFE6EAF0);

  // ==========================================================
  // SCREEN LAYOUT
  // ==========================================================

  static const EdgeInsets screenPadding =
      EdgeInsets.all(20);

  // ==========================================================
  // SCREEN HEADER
  // ==========================================================

  static const String screenTitle =
      "Account Information";

  static const TextStyle screenTitleStyle = TextStyle(
    fontFamily: 'Poppins',
    fontSize: 20,
    fontWeight: FontWeight.w600,
    color: primaryTextColor,
    letterSpacing: 0.2,
  );

  static const IconData backIcon =
      Icons.arrow_back_rounded;

  static const double backIconSize = 22;

  static const double headerSpacing = 12;

  static const double headerBottomSpacing = 24;

  // ==========================================================
  // PROFILE SUMMARY CARD
  // ==========================================================

  static const Color profileCardBackgroundColor =
      appPrimaryColor;

  static const double profileCardBorderRadius = 16;

  static const EdgeInsets profileCardPadding =
      EdgeInsets.symmetric(
        horizontal: 20,
        vertical: 18,
      );

  static const double profileAvatarRadius = 34;

  static const TextStyle profileNameStyle =
      TextStyle(
        fontFamily: 'Poppins',
        fontSize: 20,
        fontWeight: FontWeight.w600,
        color: Colors.white,
      );

  // ==========================================================
  // PERSONAL DETAILS CARD
  // ==========================================================

  static const double cardBorderRadius = 12;

  static final BoxDecoration cardDecoration =
      BoxDecoration(
        color: Colors.white,
        borderRadius:
            BorderRadius.circular(cardBorderRadius),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      );

  // ==========================================================
  // PERSONAL DETAILS HEADER
  // ==========================================================

  static const String personalDetailsTitle =
      "Personal Details";

  static const EdgeInsets personalDetailsPadding =
      EdgeInsets.fromLTRB(20, 20, 20, 12);

  static const TextStyle personalDetailsTitleStyle =
      TextStyle(
        fontFamily: 'Poppins',
        fontSize: 15,
        fontWeight: FontWeight.w600,
        color: appPrimaryColor,
      );

  // ==========================================================
  // EDIT BUTTON
  // ==========================================================

  static const String editButtonTitle =
      "Edit";

  static const IconData editButtonIcon =
      Icons.mode_edit_outline_rounded;

  static const double editButtonIconSize = 16;

  static const double editButtonRadius = 8;

  static const double editButtonBorderWidth = 1.2;

  static const EdgeInsets editButtonPadding =
      EdgeInsets.symmetric(
        horizontal: 12,
        vertical: 7,
      );

  static const TextStyle editButtonStyle =
      TextStyle(
        fontFamily: 'Poppins',
        fontSize: 13,
        fontWeight: FontWeight.w600,
        color: appPrimaryColor,
      );

  // ==========================================================
  // INFORMATION TILES
  // ==========================================================

  static const EdgeInsets infoTilePadding =
      EdgeInsets.symmetric(
        horizontal: 20,
        vertical: 18,
      );

  static const double infoIconSize = 22;

  static const TextStyle infoTitleStyle =
      TextStyle(
        fontFamily: 'Poppins',
        fontSize: 13,
        fontWeight: FontWeight.w400,
        color: primaryTextColor,
      );

  static const TextStyle infoValueStyle =
      TextStyle(
        fontFamily: 'Poppins',
        fontSize: 13,
        fontWeight: FontWeight.w400,
        color: primaryTextColor,
      );

  // ==========================================================
  // DIVIDER
  // ==========================================================

  static const double dividerThickness = 1.0;
}