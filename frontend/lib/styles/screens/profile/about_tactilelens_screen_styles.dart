import 'package:flutter/material.dart';

abstract final class AboutTactileLensScreenStyles {
  static const String fontFamily = 'Poppins';

  // Brand palette
  static const Color primaryColor = Color(0xFF0D47A1);
  static const Color primaryDarkColor = Color(0xFF0D47A1);
  static const Color primaryAccentColor = Color(0xFF0D47A1);
  static const Color primarySoftColor = Color(0xFFEAF2FC);
  static const Color primaryFaintColor = Color(0xFFFFFFFF);
  static const Color backgroundColor = Color(0xFFFFFFFF);
  static const Color cardColor = Color(0xFFFFFFFF);
  static const Color textPrimaryColor = Color(0xFF11112B);
  static const Color textSecondaryColor = Color(0xFF4E4D66);
  static const Color borderColor = Color(0x3D0D47A1);
  static const Color featureBorderColor = Color(0x3D0D47A1);
  static const Color shadowColor = Color(0x1A0D47A1);
  static const Color heroHighlightColor = Color(0xFFFFFFFF);
  static const Color heroEndColor = Color(0xFFFFFFFF);

  // Layout
  static const double contentMaxWidth = 640;
  static const double compactBreakpoint = 360;
  static const int regularGridColumns = 3;
  static const int compactGridColumns = 2;
  static const double featureGridAspectRatio = 0.86;
  static const double compactFeatureGridAspectRatio = 0.95;
  static const double appBarElevation = 0;
  static const double appBarScrolledUnderElevation = 0;
  static const double cardBorderWidth = 1;
  static const double featureBorderWidth = 1.15;
  static const double dividerThickness = 1;
  static const Offset projectValueOffset = Offset(0, 0);
  static const double projectLabelColumnWidth = 92;

  // Spacing and padding
  static const EdgeInsets screenPadding = EdgeInsets.fromLTRB(18, 18, 18, 32);
  static const EdgeInsets appBarTitlePadding = EdgeInsets.zero;
  static const EdgeInsets heroPadding = EdgeInsets.symmetric(horizontal: 24, vertical: 26);
  static const EdgeInsets informationCardPadding = EdgeInsets.all(18);
  static const EdgeInsets featureCardPadding = EdgeInsets.symmetric(horizontal: 10, vertical: 16);
  static const EdgeInsets projectCardPadding = EdgeInsets.fromLTRB(16, 8, 8, 8);
  static const EdgeInsets projectRowPadding = EdgeInsets.symmetric(vertical: 9);
  static const EdgeInsets footerCardPadding = EdgeInsets.all(18);
  static const EdgeInsets badgePadding = EdgeInsets.symmetric(horizontal: 14, vertical: 7);
  static const EdgeInsets roundIconPadding = EdgeInsets.all(14);
  static const EdgeInsets smallIconPadding = EdgeInsets.all(10);
  static const EdgeInsets featureIconPadding = EdgeInsets.all(10);

  static const double space2 = 2;
  static const double space4 = 4;
  static const double space6 = 6;
  static const double space8 = 8;
  static const double space10 = 10;
  static const double space12 = 12;
  static const double space14 = 14;
  static const double space16 = 16;
  static const double space18 = 18;
  static const double space20 = 20;
  static const double space24 = 24;
  static const double space28 = 28;
  static const double gridSpacing = 10;

  // Shapes
  static const double cardRadiusValue = 18;
  static const double featureRadiusValue = 16;
  static const double badgeRadiusValue = 24;
  static const double iconRadiusValue = 16;
  static const BorderRadius cardRadius = BorderRadius.all(Radius.circular(cardRadiusValue));
  static const BorderRadius featureRadius = BorderRadius.all(Radius.circular(featureRadiusValue));
  static const BorderRadius badgeRadius = BorderRadius.all(Radius.circular(badgeRadiusValue));
  static const BorderRadius iconRadius = BorderRadius.all(Radius.circular(iconRadiusValue));
  static const Border cardBorder = Border.fromBorderSide(
    BorderSide(color: borderColor, width: cardBorderWidth),
  );
  static const Border projectDividerBorder = Border(
    bottom: BorderSide(color: borderColor, width: dividerThickness),
  );
  static const Border featureCardBorder = Border.fromBorderSide(
    BorderSide(
      color: featureBorderColor,
      width: featureBorderWidth,
    ),
  );
  static const Border accentContainerBorder = Border.fromBorderSide(
    BorderSide(color: borderColor, width: cardBorderWidth),
  );

  static const List<BoxShadow> cardShadow = <BoxShadow>[
    BoxShadow(
      color: shadowColor,
      blurRadius: 18,
      spreadRadius: 1,
      offset: Offset(0, 6),
    ),
  ];

  static const LinearGradient heroGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: <Color>[heroHighlightColor, heroEndColor],
  );

  // Icon sizing
  static const double heroLogoBoxSize = 82;
  static const double heroLogoIconSize = 48;
  static const double informationIconSize = 34;
  static const double featureIconSize = 25;
  static const double projectIconSize = 19;
  static const double footerIconSize = 28;

  // Icons
  static const IconData appIcon = Icons.more_vert_rounded;
  static const IconData missionIcon = Icons.track_changes_rounded;
  static const IconData overviewIcon = Icons.menu_book_rounded;
  static const IconData scanIcon = Icons.camera_alt_outlined;
  static const IconData aiIcon = Icons.auto_awesome_rounded;
  static const IconData offlineIcon = Icons.cloud_off_rounded;
  static const IconData organizedIcon = Icons.folder_outlined;
  static const IconData privacyIcon = Icons.shield_outlined;
  static const IconData educatorIcon = Icons.groups_2_outlined;
  static const IconData projectTypeIcon = Icons.school_outlined;
  static const IconData institutionIcon = Icons.account_balance_outlined;
  static const IconData courseIcon = Icons.computer_outlined;
  static const IconData yearIcon = Icons.calendar_month_outlined;
  static const IconData aboutProjectIcon = Icons.description_outlined;

  // Typography
  static const TextStyle appBarTitleStyle = TextStyle(
    fontFamily: fontFamily,
    color: textPrimaryColor,
    fontSize: 20,
    fontWeight: FontWeight.w700,
    letterSpacing: -0.25,
  );
  static const TextStyle heroTitleStyle = TextStyle(
    fontFamily: fontFamily,
    color: textPrimaryColor,
    fontSize: 30,
    fontWeight: FontWeight.w800,
    height: 1.05,
    letterSpacing: -0.8,
  );
  static const TextStyle heroTaglineStyle = TextStyle(
    fontFamily: fontFamily,
    color: primaryColor,
    fontSize: 15,
    fontWeight: FontWeight.w600,
    height: 1.3,
  );
  static const TextStyle badgeTextStyle = TextStyle(
    fontFamily: fontFamily,
    color: textPrimaryColor,
    fontSize: 12.5,
    fontWeight: FontWeight.w600,
  );
  static const TextStyle sectionTitleStyle = TextStyle(
    fontFamily: fontFamily,
    color: primaryColor,
    fontSize: 18,
    fontWeight: FontWeight.w800,
    letterSpacing: -0.2,
  );
  static const TextStyle cardTitleStyle = TextStyle(
    fontFamily: fontFamily,
    color: primaryColor,
    fontSize: 16,
    fontWeight: FontWeight.w800,
    height: 1.25,
  );
  static const TextStyle bodyStyle = TextStyle(
    fontFamily: fontFamily,
    color: textPrimaryColor,
    fontSize: 14,
    fontWeight: FontWeight.w400,
    height: 1.55,
  );
  static const TextStyle featureTitleStyle = TextStyle(
    fontFamily: fontFamily,
    color: textPrimaryColor,
    fontSize: 13.5,
    fontWeight: FontWeight.w700,
    height: 1.25,
  );
  static const TextStyle featureBodyStyle = TextStyle(
    fontFamily: fontFamily,
    color: textSecondaryColor,
    fontSize: 12,
    fontWeight: FontWeight.w400,
    height: 1.35,
  );
  static const TextStyle projectLabelStyle = TextStyle(
    fontFamily: fontFamily,
    color: primaryColor,
    fontSize: 12.5,
    fontWeight: FontWeight.w700,
  );
  static const TextStyle projectValueStyle = TextStyle(
    fontFamily: fontFamily,
    color: textSecondaryColor,
    fontSize: 12.5,
    fontWeight: FontWeight.w500,
  );
  static const TextStyle footerTitleStyle = TextStyle(
    fontFamily: fontFamily,
    color: primaryColor,
    fontSize: 14,
    fontWeight: FontWeight.w800,
  );
  static const TextStyle footerBodyStyle = TextStyle(
    fontFamily: fontFamily,
    color: textPrimaryColor,
    fontSize: 12.5,
    height: 1.45,
  );
}
