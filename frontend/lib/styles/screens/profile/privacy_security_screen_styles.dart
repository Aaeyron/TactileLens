import 'package:flutter/material.dart';

abstract final class PrivacySecurityScreenStyles {
  static const String fontFamily = 'Poppins';

  // Brand palette
  static const Color primaryColor = Color(0xFF0D47A1);
  static const Color primaryDarkColor = Color(0xFF083475);
  static const Color primarySoftColor = Color(0xFFEAF2FC);
  static const Color primaryFaintColor = Color(0xFFF6F9FD);
  static const Color backgroundColor = Color(0xFFFFFFFF);
  static const Color cardColor = Color(0xFFFFFFFF);
  static const Color textPrimaryColor = Color(0xFF11152E);
  static const Color textSecondaryColor = Color(0xFF4E5872);
  static const Color borderColor = Color(0x3D0D47A1);
  static const Color shadowColor = Color(0x1A0D47A1);

  // Responsive layout
  static const double contentMaxWidth = 680;
  static const double compactBreakpoint = 380;
  static const int regularGridColumns = 3;
  static const int compactGridColumns = 2;
  static const double regularGridAspectRatio = 1.43;
  static const double compactGridAspectRatio = 1.18;
  static const double appBarElevation = 0;
  static const double appBarScrolledUnderElevation = 0;
  static const double borderWidth = 1;
  static const double heroIconBoxSize = 104;
  static const double compactHeroIconBoxSize = 84;
  static const double topicIconBoxSize = 64;
  static const double compactTopicIconBoxSize = 54;
  static const double featureIconBoxSize = 46;
  static const int topicDescriptionMaxLines = 3;
  static const int featureDescriptionMaxLines = 3;

  // Padding
  static const EdgeInsets screenPadding = EdgeInsets.fromLTRB(18, 18, 18, 32);
  static const EdgeInsets heroPadding = EdgeInsets.symmetric(
    horizontal: 24,
    vertical: 28,
  );
  static const EdgeInsets compactHeroPadding = EdgeInsets.all(18);
  static const EdgeInsets topicCardPadding = EdgeInsets.symmetric(
    horizontal: 18,
    vertical: 12,
  );
  static const EdgeInsets compactTopicCardPadding = EdgeInsets.all(12);
  static const EdgeInsets featureCardPadding = EdgeInsets.all(12);
  static const EdgeInsets overviewPadding = EdgeInsets.all(20);
  static const EdgeInsets footerPadding = EdgeInsets.symmetric(vertical: 22);
  static const EdgeInsets iconPadding = EdgeInsets.all(10);

  // Spacing
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
  static const double gridSpacing = 10;

  // Shapes
  static const double cardRadiusValue = 18;
  static const double heroIconRadiusValue = 28;
  static const double iconRadiusValue = 16;
  static const BorderRadius cardRadius = BorderRadius.all(
    Radius.circular(cardRadiusValue),
  );
  static const BorderRadius heroIconRadius = BorderRadius.all(
    Radius.circular(heroIconRadiusValue),
  );
  static const BorderRadius iconRadius = BorderRadius.all(
    Radius.circular(iconRadiusValue),
  );
  static const Border cardBorder = Border.fromBorderSide(
    BorderSide(color: borderColor, width: borderWidth),
  );

  // Effects
  static const LinearGradient heroGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: <Color>[cardColor, cardColor],
  );
  static const LinearGradient iconGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: <Color>[primaryColor, primaryDarkColor],
  );
  static const List<BoxShadow> cardShadow = <BoxShadow>[
    BoxShadow(
      color: shadowColor,
      blurRadius: 18,
      spreadRadius: 1,
      offset: Offset(0, 6),
    ),
  ];
  static const List<BoxShadow> heroIconShadow = <BoxShadow>[
    BoxShadow(color: shadowColor, blurRadius: 18, offset: Offset(0, 8)),
  ];

  // Icons
  static const IconData heroIcon = Icons.shield_rounded;
  static const IconData heroLockIcon = Icons.lock_rounded;
  static const IconData dataProtectionIcon = Icons.admin_panel_settings_rounded;
  static const IconData offlinePrivacyIcon = Icons.phone_android_rounded;
  static const IconData onlineSecurityIcon = Icons.lock_person_rounded;
  static const IconData accountAccessIcon = Icons.manage_accounts_rounded;
  static const IconData permissionsIcon = Icons.key_rounded;
  static const IconData controlIcon = Icons.tune_rounded;
  static const IconData secureScanIcon = Icons.camera_alt_rounded;
  static const IconData offlineFeatureIcon = Icons.phonelink_lock_rounded;
  static const IconData protectedOnlineIcon = Icons.vpn_lock_rounded;
  static const IconData permissionControlIcon = Icons.verified_user_rounded;
  static const IconData savedMaterialsIcon = Icons.folder_rounded;
  static const IconData userControlIcon = Icons.account_circle_rounded;
  static const IconData overviewIcon = Icons.info_outline_rounded;
  static const IconData checkIcon = Icons.check_circle_outline_rounded;
  static const IconData brandIcon = Icons.more_vert_rounded;

  // Icon sizes
  static const double heroIconSize = 58;
  static const double heroLockIconSize = 30;
  static const double topicIconSize = 34;
  static const double featureIconSize = 29;
  static const double overviewIconSize = 30;
  static const double checkIconSize = 19;
  static const double brandIconSize = 34;

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
    fontSize: 28,
    fontWeight: FontWeight.w800,
    height: 1.15,
    letterSpacing: -0.6,
  );
  static const TextStyle heroSubtitleStyle = TextStyle(
    fontFamily: fontFamily,
    color: primaryColor,
    fontSize: 14.5,
    fontWeight: FontWeight.w500,
    height: 1.5,
  );
  static const TextStyle topicTitleStyle = TextStyle(
    fontFamily: fontFamily,
    color: primaryColor,
    fontSize: 16,
    fontWeight: FontWeight.w700,
    height: 1.3,
  );
  static const TextStyle topicDescriptionStyle = TextStyle(
    fontFamily: fontFamily,
    color: textPrimaryColor,
    fontSize: 12.5,
    fontWeight: FontWeight.w400,
    height: 1.45,
  );
  static const TextStyle sectionTitleStyle = TextStyle(
    fontFamily: fontFamily,
    color: primaryColor,
    fontSize: 18,
    fontWeight: FontWeight.w800,
    letterSpacing: -0.2,
  );
  static const TextStyle featureTitleStyle = TextStyle(
    fontFamily: fontFamily,
    color: primaryColor,
    fontSize: 12.5,
    fontWeight: FontWeight.w700,
    height: 1.25,
  );
  static const TextStyle featureDescriptionStyle = TextStyle(
    fontFamily: fontFamily,
    color: textSecondaryColor,
    fontSize: 10.5,
    fontWeight: FontWeight.w400,
    height: 1.35,
  );
  static const TextStyle overviewTitleStyle = TextStyle(
    fontFamily: fontFamily,
    color: primaryColor,
    fontSize: 16,
    fontWeight: FontWeight.w700,
  );
  static const TextStyle overviewTextStyle = TextStyle(
    fontFamily: fontFamily,
    color: textPrimaryColor,
    fontSize: 11.5,
    fontWeight: FontWeight.w400,
    height: 1.4,
  );
  static const TextStyle overviewEmphasisStyle = TextStyle(
    fontFamily: fontFamily,
    color: textPrimaryColor,
    fontSize: 11.5,
    fontWeight: FontWeight.w700,
    height: 1.4,
  );
  static const TextStyle brandTitleStyle = TextStyle(
    fontFamily: fontFamily,
    color: primaryColor,
    fontSize: 20,
    fontWeight: FontWeight.w800,
  );
  static const TextStyle brandTaglineStyle = TextStyle(
    fontFamily: fontFamily,
    color: primaryColor,
    fontSize: 12.5,
    fontWeight: FontWeight.w500,
  );
}
