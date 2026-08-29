import 'package:flutter/material.dart';

abstract final class AboutTactileLensScreenStyles {
  // ============================================================
  // CONTENT
  // ============================================================

  static const String screenTitle = 'About TactileLens';

  static const String screenDescription =
      'Learn how TactileLens supports accessible and inclusive learning.';

  static const String backTooltip = 'Return to Profile';

  static const String appName = 'TactileLens';
  static const String tagline = 'See. Translate. Empower.';
  static const String versionLabel = 'Version 1.0.0 · Offline First';

  static const String missionTitle = 'Our Mission';

  static const String missionDescription =
      'Empower SPED educators with accurate and accessible tools that '
      'translate printed text and mathematics into UEB and Nemeth Braille.';

  static const String overviewTitle = 'What is TactileLens?';

  static const String overviewDescription =
      'TactileLens is an AI-assisted learning tool that recognizes printed '
      'documents and prepares accessible text and Braille outputs for '
      'educators and learners.';

  static const String featuresTitle = 'Key Features';

  static const String featuresDescription =
      'Tools designed to make learning materials easier to access and manage.';

  static const String projectTitle = 'Project Information';

  static const String projectDescription =
      'Academic and development details behind TactileLens.';

  static const String purposeTitle = 'Built for Inclusive Education';

  static const String purposeDescription =
      'TactileLens is developed to help educators prepare accessible '
      'learning materials while promoting independence and inclusion.';

  // ============================================================
  // COLORS
  // ============================================================

  static const Color primaryColor = Color(0xFF1268F3);
  static const Color primaryDarkColor = Color(0xFF0758DD);

  static const Color backgroundColor = Color(0xFFF4F7FC);
  static const Color surfaceColor = Colors.white;

  static const Color textPrimaryColor = Color(0xFF10213D);
  static const Color textSecondaryColor = Color(0xFF42526B);
  static const Color textMutedColor = Color(0xFF728096);

  static const Color outlineColor = Color(0xFFDDE5F0);
  static const Color dividerColor = Color(0xFFE5EBF3);
  static const Color primarySoftColor = Color(0xFFEDF4FF);

  // ============================================================
  // ANIMATION
  // ============================================================

  static const Duration entranceDuration = Duration(milliseconds: 440);
  static const Curve entranceCurve = Curves.easeOutCubic;
  static const double entranceVerticalOffset = 14;

  // ============================================================
  // HEADER
  // ============================================================

  static const double headerHorizontalPadding = 14;
  static const double headerTopPadding = 12;
  static const double headerBottomPadding = 27;
  static const double headerBackSpacing = 5;
  static const double headerTextSpacing = 15;

  static const double headerDescriptionWidth = 270;

  static const EdgeInsets headerDescriptionPadding = EdgeInsets.symmetric(
    horizontal: 5,
  );

  static const LinearGradient headerGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: <Color>[Color(0xFF1474F5), Color(0xFF0758DD)],
  );

  static const BorderRadius headerRadius = BorderRadius.only(
    bottomLeft: Radius.elliptical(190, 34),
    bottomRight: Radius.elliptical(190, 34),
  );

  static const double decorationRight = 18;
  static const double decorationBottom = 22;
  static const double decorationOpacity = 0.18;
  static const double decorationWidth = 49;
  static const double decorationDotSize = 4;
  static const double decorationDotSpacing = 7;
  static const int decorationDotCount = 12;

  static const IconData backIcon = Icons.arrow_back_rounded;
  static const double backIconSize = 25;

  static final ButtonStyle backButtonStyle = IconButton.styleFrom(
    foregroundColor: surfaceColor,
    backgroundColor: const Color(0x26FFFFFF),
    shape: const CircleBorder(),
  );

  // ============================================================
  // LAYOUT
  // ============================================================

  static const EdgeInsets contentPadding = EdgeInsets.fromLTRB(14, 17, 14, 30);

  static const double sectionSpacing = 22;
  static const double cardSpacing = 12;
  static const double headingBottomSpacing = 12;
  static const double bottomSpacing = 30;

  // ============================================================
  // SHARED CARDS
  // ============================================================

  static const BorderRadius cardRadius = BorderRadius.all(Radius.circular(15));

  static const Border cardBorder = Border.fromBorderSide(
    BorderSide(color: outlineColor, width: 1),
  );

  static const List<BoxShadow> cardShadow = <BoxShadow>[
    BoxShadow(color: Color(0x0D102A43), blurRadius: 12, offset: Offset(0, 4)),
  ];

  // ============================================================
  // BRAND CARD
  // ============================================================

  static const EdgeInsets brandCardPadding = EdgeInsets.symmetric(
    horizontal: 20,
    vertical: 23,
  );

  static const double logoContainerSize = 78;
  static const double logoIconSize = 43;

  static const IconData logoIcon = Icons.document_scanner_rounded;

  static const LinearGradient logoGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: <Color>[Color(0xFF66A6FF), Color(0xFF1268F3)],
  );

  static const BorderRadius logoRadius = BorderRadius.all(Radius.circular(21));

  static const List<BoxShadow> logoShadow = <BoxShadow>[
    BoxShadow(color: Color(0x331268F3), blurRadius: 16, offset: Offset(0, 6)),
  ];

  static const double logoDotsRight = 8;
  static const double logoDotsBottom = 8;

  static const double smallDotsWidth = 15;
  static const double smallDotSize = 2.4;
  static const double smallDotSpacing = 2.6;
  static const int smallDotCount = 6;

  static const double brandNameSpacing = 15;
  static const double taglineSpacing = 5;
  static const double versionSpacing = 15;

  static const EdgeInsets versionBadgePadding = EdgeInsets.symmetric(
    horizontal: 13,
    vertical: 7,
  );

  static const BorderRadius versionBadgeRadius = BorderRadius.all(
    Radius.circular(18),
  );

  static const IconData verifiedIcon = Icons.verified_outlined;
  static const double versionIconSize = 16;
  static const double versionIconSpacing = 6;

  // ============================================================
  // INFORMATION CARDS
  // ============================================================

  static const EdgeInsets informationCardPadding = EdgeInsets.all(17);

  static const double informationContentSpacing = 13;
  static const double cardDescriptionSpacing = 6;

  static const double iconContainerSize = 45;
  static const double compactIconContainerSize = 40;

  static const BorderRadius iconContainerRadius = BorderRadius.all(
    Radius.circular(12),
  );

  static const double informationIconSize = 22;
  static const double compactIconSize = 20;

  // ============================================================
  // FEATURES
  // ============================================================

  static const double featureSingleColumnBreakpoint = 340;
  static const double featureSpacing = 10;
  static const double featureMinimumHeight = 166;

  static const EdgeInsets featureCardPadding = EdgeInsets.all(15);

  static const BorderRadius featureRadius = BorderRadius.all(
    Radius.circular(14),
  );

  static const List<BoxShadow> featureShadow = <BoxShadow>[
    BoxShadow(color: Color(0x09102A43), blurRadius: 8, offset: Offset(0, 3)),
  ];

  static const double featureTitleSpacing = 12;
  static const double featureDescriptionSpacing = 5;

  // ============================================================
  // PROJECT INFORMATION
  // ============================================================

  static const EdgeInsets projectRowPadding = EdgeInsets.symmetric(
    horizontal: 16,
    vertical: 14,
  );

  static const Border projectDividerBorder = Border(
    bottom: BorderSide(color: dividerColor, width: 1),
  );

  static const double projectContentSpacing = 12;
  static const double projectValueSpacing = 4;

  // ============================================================
  // PURPOSE CARD
  // ============================================================

  static const EdgeInsets purposeCardPadding = EdgeInsets.all(18);

  static const LinearGradient purposeGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: <Color>[Color(0xFF1474F5), Color(0xFF0758DD)],
  );

  static const IconData educatorIcon = Icons.groups_2_outlined;
  static const double purposeIconSize = 31;
  static const double purposeContentSpacing = 14;
  static const double purposeDescriptionSpacing = 6;

  // ============================================================
  // ICONS
  // ============================================================

  static const IconData missionIcon = Icons.track_changes_rounded;
  static const IconData overviewIcon = Icons.menu_book_rounded;

  static const IconData scanIcon = Icons.camera_alt_outlined;
  static const IconData aiIcon = Icons.auto_awesome_rounded;
  static const IconData brailleIcon = Icons.translate_rounded;
  static const IconData offlineIcon = Icons.cloud_off_rounded;
  static const IconData organizedIcon = Icons.folder_outlined;
  static const IconData privacyIcon = Icons.shield_outlined;

  static const IconData projectTypeIcon = Icons.school_outlined;
  static const IconData institutionIcon = Icons.account_balance_outlined;
  static const IconData courseIcon = Icons.computer_outlined;
  static const IconData yearIcon = Icons.calendar_month_outlined;

  // ============================================================
  // TYPOGRAPHY
  // ============================================================

  static const TextStyle headerTitleStyle = TextStyle(
    color: surfaceColor,
    fontSize: 21,
    fontWeight: FontWeight.w800,
    letterSpacing: -0.25,
  );

  static const TextStyle headerDescriptionStyle = TextStyle(
    color: Color(0xFFE9F2FF),
    fontSize: 13.5,
    height: 1.4,
    fontWeight: FontWeight.w500,
  );

  static const TextStyle brandTitleStyle = TextStyle(
    color: textPrimaryColor,
    fontSize: 26,
    fontWeight: FontWeight.w800,
    letterSpacing: -0.45,
  );

  static const TextStyle taglineStyle = TextStyle(
    color: primaryColor,
    fontSize: 14,
    fontWeight: FontWeight.w700,
  );

  static const TextStyle versionTextStyle = TextStyle(
    color: primaryColor,
    fontSize: 12,
    fontWeight: FontWeight.w700,
  );

  static const TextStyle sectionTitleStyle = TextStyle(
    color: textPrimaryColor,
    fontSize: 18,
    fontWeight: FontWeight.w800,
    letterSpacing: -0.2,
  );

  static const double sectionDescriptionSpacing = 4;

  static const TextStyle sectionDescriptionStyle = TextStyle(
    color: textSecondaryColor,
    fontSize: 12.5,
    height: 1.4,
  );

  static const TextStyle cardTitleStyle = TextStyle(
    color: textPrimaryColor,
    fontSize: 16,
    fontWeight: FontWeight.w800,
  );

  static const TextStyle bodyStyle = TextStyle(
    color: textSecondaryColor,
    fontSize: 13,
    height: 1.5,
  );

  static const TextStyle featureTitleStyle = TextStyle(
    color: textPrimaryColor,
    fontSize: 14,
    fontWeight: FontWeight.w800,
  );

  static const TextStyle featureBodyStyle = TextStyle(
    color: textSecondaryColor,
    fontSize: 12.25,
    height: 1.42,
  );

  static const TextStyle projectLabelStyle = TextStyle(
    color: textMutedColor,
    fontSize: 12,
    fontWeight: FontWeight.w600,
  );

  static const TextStyle projectValueStyle = TextStyle(
    color: textPrimaryColor,
    fontSize: 13.5,
    height: 1.35,
    fontWeight: FontWeight.w700,
  );

  static const TextStyle purposeTitleStyle = TextStyle(
    color: surfaceColor,
    fontSize: 16,
    fontWeight: FontWeight.w800,
  );

  static const TextStyle purposeBodyStyle = TextStyle(
    color: Color(0xFFE9F2FF),
    fontSize: 12.75,
    height: 1.48,
  );
}
