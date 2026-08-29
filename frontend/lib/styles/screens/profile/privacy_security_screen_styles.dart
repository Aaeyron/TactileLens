import 'package:flutter/material.dart';

abstract final class PrivacySecurityScreenStyles {
  // ============================================================
  // CONTENT
  // ============================================================

  static const String screenTitle = 'Privacy & Security';

  static const String screenDescription =
      'Understand how your account, learning content, and device data are protected.';

  static const String backTooltip = 'Return to Profile';

  static const String statusTitle = 'Protection Overview';
  static const String statusBadgeLabel = 'Protected';

  static const String statusDescription =
      'TactileLens combines local storage, account authentication, and '
      'controlled permissions to protect learning information.';

  static const String privacyTopicsTitle = 'How Your Data Is Protected';

  static const String privacyTopicsDescription =
      'A clear overview of privacy and security throughout TactileLens.';

  static const String securityFeaturesTitle = 'Security Features';

  static const String securityFeaturesDescription =
      'Core protections used across scanning, materials, and accounts.';

  static const String overviewTitle = 'Privacy Overview';

  static const String promiseTitle = 'Our Privacy Commitment';

  static const String promiseDescription =
      'TactileLens is designed to support accessible education while '
      'respecting user control, privacy, and responsible data handling.';

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

  static const Color successColor = Color(0xFF16A765);
  static const Color successSoftColor = Color(0xFFE9F8F0);

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

  static const double headerDescriptionWidth = 285;

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
  static const double cardSpacing = 13;
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
  // SECURITY STATUS
  // ============================================================

  static const EdgeInsets statusCardPadding = EdgeInsets.all(17);

  static const double statusIconContainerSize = 72;

  static const BorderRadius statusIconRadius = BorderRadius.all(
    Radius.circular(20),
  );

  static const LinearGradient securityGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: <Color>[Color(0xFF1474F5), Color(0xFF0758DD)],
  );

  static const List<BoxShadow> statusIconShadow = <BoxShadow>[
    BoxShadow(color: Color(0x291268F3), blurRadius: 14, offset: Offset(0, 5)),
  ];

  static const double statusShieldSize = 40;
  static const double statusLockSize = 19;

  static const double statusContentSpacing = 14;
  static const double statusBadgeSpacing = 8;
  static const double statusDescriptionSpacing = 7;

  static const EdgeInsets statusBadgePadding = EdgeInsets.symmetric(
    horizontal: 8,
    vertical: 5,
  );

  static const BorderRadius statusBadgeRadius = BorderRadius.all(
    Radius.circular(14),
  );

  static const double statusBadgeIconSize = 13;
  static const double statusBadgeIconSpacing = 4;

  // ============================================================
  // SECTION HEADINGS
  // ============================================================

  static const double sectionDescriptionSpacing = 4;

  // ============================================================
  // PRIVACY TOPICS
  // ============================================================

  static const EdgeInsets topicRowPadding = EdgeInsets.all(16);

  static const Border topicDividerBorder = Border(
    bottom: BorderSide(color: dividerColor, width: 1),
  );

  static const double topicContentSpacing = 13;
  static const double topicDescriptionSpacing = 5;

  // ============================================================
  // ICON CONTAINERS
  // ============================================================

  static const double iconContainerSize = 43;
  static const double iconSize = 21;

  static const BorderRadius iconContainerRadius = BorderRadius.all(
    Radius.circular(12),
  );

  // ============================================================
  // SECURITY FEATURES
  // ============================================================

  static const double featureSingleColumnBreakpoint = 340;
  static const double featureSpacing = 10;
  static const double featureMinimumHeight = 74;

  static const EdgeInsets featureCardPadding = EdgeInsets.all(13);

  static const BorderRadius featureCardRadius = BorderRadius.all(
    Radius.circular(14),
  );

  static const List<BoxShadow> featureShadow = <BoxShadow>[
    BoxShadow(color: Color(0x09102A43), blurRadius: 8, offset: Offset(0, 3)),
  ];

  static const double featureContentSpacing = 10;
  static const double featureCheckSize = 18;

  // ============================================================
  // PRIVACY OVERVIEW
  // ============================================================

  static const EdgeInsets overviewPadding = EdgeInsets.all(17);

  static const double overviewHeaderSpacing = 12;
  static const double overviewListSpacing = 16;
  static const double overviewRowSpacing = 11;
  static const double overviewCheckSize = 18;
  static const double overviewContentSpacing = 9;

  // ============================================================
  // PRIVACY PROMISE
  // ============================================================

  static const EdgeInsets promiseCardPadding = EdgeInsets.all(18);

  static const IconData promiseIcon = Icons.volunteer_activism_outlined;
  static const double promiseIconSize = 31;
  static const double promiseContentSpacing = 14;
  static const double promiseDescriptionSpacing = 6;

  // ============================================================
  // ICONS
  // ============================================================

  static const IconData heroIcon = Icons.shield_rounded;
  static const IconData heroLockIcon = Icons.lock_rounded;

  static const IconData dataProtectionIcon =
      Icons.admin_panel_settings_outlined;

  static const IconData offlinePrivacyIcon = Icons.phone_android_rounded;

  static const IconData onlineSecurityIcon = Icons.vpn_lock_outlined;
  static const IconData accountAccessIcon = Icons.manage_accounts_outlined;
  static const IconData permissionsIcon = Icons.key_outlined;
  static const IconData controlIcon = Icons.tune_rounded;

  static const IconData secureScanIcon = Icons.camera_alt_outlined;
  static const IconData offlineFeatureIcon = Icons.phonelink_lock_outlined;
  static const IconData protectedOnlineIcon = Icons.language_rounded;

  static const IconData permissionControlIcon = Icons.verified_user_outlined;

  static const IconData savedMaterialsIcon = Icons.folder_outlined;
  static const IconData userControlIcon = Icons.person_outline_rounded;

  static const IconData overviewIcon = Icons.fact_check_outlined;
  static const IconData checkIcon = Icons.check_circle_rounded;

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

  static const TextStyle statusTitleStyle = TextStyle(
    color: textPrimaryColor,
    fontSize: 17,
    fontWeight: FontWeight.w800,
  );

  static const TextStyle statusDescriptionStyle = TextStyle(
    color: textSecondaryColor,
    fontSize: 12.5,
    height: 1.45,
  );

  static const TextStyle statusBadgeTextStyle = TextStyle(
    color: successColor,
    fontSize: 10.5,
    fontWeight: FontWeight.w800,
  );

  static const TextStyle sectionTitleStyle = TextStyle(
    color: textPrimaryColor,
    fontSize: 18,
    fontWeight: FontWeight.w800,
    letterSpacing: -0.2,
  );

  static const TextStyle sectionDescriptionStyle = TextStyle(
    color: textSecondaryColor,
    fontSize: 12.5,
    height: 1.4,
  );

  static const TextStyle topicTitleStyle = TextStyle(
    color: textPrimaryColor,
    fontSize: 14.5,
    fontWeight: FontWeight.w800,
  );

  static const TextStyle topicDescriptionStyle = TextStyle(
    color: textSecondaryColor,
    fontSize: 12.5,
    height: 1.45,
  );

  static const TextStyle featureTitleStyle = TextStyle(
    color: textPrimaryColor,
    fontSize: 12.5,
    height: 1.3,
    fontWeight: FontWeight.w700,
  );

  static const TextStyle overviewTitleStyle = TextStyle(
    color: textPrimaryColor,
    fontSize: 16,
    fontWeight: FontWeight.w800,
  );

  static const TextStyle overviewEmphasisStyle = TextStyle(
    color: textPrimaryColor,
    fontSize: 12.5,
    height: 1.4,
    fontWeight: FontWeight.w800,
  );

  static const TextStyle overviewTextStyle = TextStyle(
    color: textSecondaryColor,
    fontSize: 12.5,
    height: 1.4,
  );

  static const TextStyle promiseTitleStyle = TextStyle(
    color: surfaceColor,
    fontSize: 16,
    fontWeight: FontWeight.w800,
  );

  static const TextStyle promiseBodyStyle = TextStyle(
    color: Color(0xFFE9F2FF),
    fontSize: 12.75,
    height: 1.48,
  );
}
