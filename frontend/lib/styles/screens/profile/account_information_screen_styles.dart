import 'package:flutter/material.dart';

class AccountInformationStyles {
  const AccountInformationStyles._();

  // ==========================================================
  // SHARED COLORS
  // ==========================================================

  static const Color primaryTextColor = Colors.black87;

  static const Color appPrimaryColor =
      Color(0xFF0D47A1);

  // ==========================================================
  // SCREEN LAYOUT
  // ==========================================================

  static const EdgeInsets screenPadding =
      EdgeInsets.all(20);

  // ==========================================================
  // SCREEN TITLE
  // ==========================================================

  static const String screenTitle =
      "Account Information";

  static const TextStyle screenTitleStyle = TextStyle(
    fontSize: 20,
    fontWeight: FontWeight.w600,
    color: primaryTextColor,
    letterSpacing: 0.2,
  );

  // ==========================================================
  // HEADER
  // ==========================================================

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

  // ==========================================================
  // PERSONAL DETAILS CARD
  // ==========================================================

  static const EdgeInsets infoTilePadding =
      EdgeInsets.symmetric(
    horizontal: 20,
    vertical: 18,
  );

  static final BoxDecoration cardDecoration =
      BoxDecoration(
    color: Colors.white,
    borderRadius: BorderRadius.circular(12),
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
  // INFO TEXT STYLES
  // ==========================================================

  static const TextStyle infoTitleStyle =
      TextStyle(
    fontSize: 13,
    color: Colors.grey,
    fontWeight: FontWeight.w500,
  );

  static const TextStyle infoValueStyle =
      TextStyle(
    fontSize: 16,
    color: Colors.black87,
    fontWeight: FontWeight.w600,
  );
}