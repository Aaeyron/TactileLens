import 'package:flutter/material.dart';

abstract final class TermsPolicyScreenStyles {
  // ============================================================
  // CONTENT
  // ============================================================

  static const String screenTitle = 'Terms & Policy';

  static const String screenDescription =
      'Understand how TactileLens should be used and how your data is handled.';

  static const String backTooltip = 'Return to Profile';

  static const String introductionTitle = 'Clear, Safe, and Responsible';

  static const String introductionDescription =
      'These guidelines explain your responsibilities and our commitment '
      'to protecting accessible learning information.';

  static const String effectiveDate = 'Effective August 2026';

  static const String termsTabLabel = 'Terms of Use';
  static const String privacyTabLabel = 'Privacy Policy';

  static const String termsTabAccessibilityLabel = 'Open Terms of Use';

  static const String privacyTabAccessibilityLabel = 'Open Privacy Policy';

  static const String selectedTabHint = 'This section is currently selected';

  static const String unselectedTabHint = 'Double tap to open this section';

  static const String termsContentTitle = 'Terms of Use';

  static const String termsContentDescription =
      'Guidelines for using TactileLens safely and responsibly.';

  static const String privacyContentTitle = 'Privacy Policy';

  static const String privacyContentDescription =
      'How account information and learning data are processed and protected.';

  static const String termsNoticeTitle = 'Important Reminder';

  static const String termsNoticeDescription =
      'AI-generated recognition and Braille output should always be reviewed '
      'before being distributed as a final accessible learning material.';

  static const String privacyNoticeTitle = 'Your Privacy Matters';

  static const String privacyNoticeDescription =
      'Guest data remains local to the device, while registered account data '
      'may use online services when synchronization is available.';

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

  static const Color noticeBackgroundColor = Color(0xFFFFFAEB);
  static const Color noticeBorderColor = Color(0xFFF2D38A);

  static const Color privacyNoticeBackgroundColor = Color(0xFFF0F7FF);
  static const Color privacyNoticeBorderColor = Color(0xFFCCE0FF);

  // ============================================================
  // ANIMATION
  // ============================================================

  static const Duration entranceDuration = Duration(milliseconds: 420);
  static const Duration entranceDelay = Duration(milliseconds: 100);
  static const Curve entranceCurve = Curves.easeOutCubic;
  static const Offset entranceBeginOffset = Offset(0, 0.025);

  static const Duration contentSwitchDuration = Duration(milliseconds: 280);
  static const Curve contentSwitchCurve = Curves.easeOutCubic;
  static const Offset contentSwitchBeginOffset = Offset(0.025, 0);

  static const Duration tabAnimationDuration = Duration(milliseconds: 230);
  static const Curve tabAnimationCurve = Curves.easeOutCubic;

  // ============================================================
  // HEADER
  // ============================================================

  static const double headerHorizontalPadding = 14;
  static const double headerTopPadding = 12;
  static const double headerBottomPadding = 27;

  static const double headerBackSpacing = 5;
  static const double headerTextSpacing = 15;

  static const double headerDescriptionWidth = 280;

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

  static const double sectionSpacing = 18;
  static const double cardSpacing = 13;
  static const double bottomSpacing = 30;

  // ============================================================
  // CARDS
  // ============================================================

  static const BorderRadius cardRadius = BorderRadius.all(Radius.circular(15));

  static const Border cardBorder = Border.fromBorderSide(
    BorderSide(color: outlineColor, width: 1),
  );

  static const List<BoxShadow> cardShadow = <BoxShadow>[
    BoxShadow(color: Color(0x0D102A43), blurRadius: 12, offset: Offset(0, 4)),
  ];

  // ============================================================
  // INTRODUCTION
  // ============================================================

  static const EdgeInsets introductionPadding = EdgeInsets.all(17);

  static const double introductionContentSpacing = 13;
  static const double introductionDescriptionSpacing = 6;
  static const double effectiveDateSpacing = 10;

  // ============================================================
  // TABS
  // ============================================================

  static const double tabContainerHeight = 64;

  static const EdgeInsets tabContainerPadding = EdgeInsets.all(4);

  static const BorderRadius tabContainerRadius = BorderRadius.all(
    Radius.circular(16),
  );

  static const BorderRadius tabRadius = BorderRadius.all(Radius.circular(12));

  static const EdgeInsets tabContentPadding = EdgeInsets.symmetric(
    horizontal: 9,
    vertical: 8,
  );

  static const double tabSpacing = 5;

  static const double tabIconContainerSize = 30;
  static const double tabIconSize = 17;
  static const double tabIconSpacing = 7;

  static const BorderRadius tabIconContainerRadius = BorderRadius.all(
    Radius.circular(9),
  );

  static const double selectedCheckSpacing = 5;
  static const double selectedCheckIconSize = 15;

  static const double selectedTabScale = 1;
  static const double unselectedTabScale = 0.985;

  static const Color unselectedTabBackgroundColor = Color(0xFFF7F9FC);
  static const Color unselectedTabBorderColor = Color(0xFFE1E8F2);

  static const Color selectedTabIconBackgroundColor = Color(0x33FFFFFF);
  static const Color unselectedTabIconBackgroundColor = Color(0xFFE6F0FF);

  static const Color tabSplashColor = Color(0x331268F3);
  static const Color tabHighlightColor = Color(0x141268F3);

  static const IconData selectedTabIcon = Icons.check_circle_rounded;

  static const LinearGradient selectedTabGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: <Color>[Color(0xFF1474F5), Color(0xFF0758DD)],
  );

  static const List<BoxShadow> tabShadow = <BoxShadow>[
    BoxShadow(color: Color(0x09102A43), blurRadius: 8, offset: Offset(0, 3)),
  ];

  static const List<BoxShadow> selectedTabShadow = <BoxShadow>[
    BoxShadow(color: Color(0x291268F3), blurRadius: 10, offset: Offset(0, 4)),
  ];

  // ============================================================
  // POLICY CONTENT
  // ============================================================

  static const double sectionDescriptionSpacing = 4;
  static const double policyListSpacing = 12;

  static const EdgeInsets policyItemPadding = EdgeInsets.all(16);

  static const Border policyDividerBorder = Border(
    bottom: BorderSide(color: dividerColor, width: 1),
  );

  static const double policyContentSpacing = 13;
  static const double policyBodySpacing = 6;

  static const double policyIconContainerSize = 44;
  static const double policyIconSize = 21;

  static const BorderRadius policyIconRadius = BorderRadius.all(
    Radius.circular(12),
  );

  static const LinearGradient iconHighlightGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: <Color>[Color(0xFF66A6FF), Color(0xFF1268F3)],
  );

  static const double numberBadgeSize = 18;
  static const double numberBadgeRight = -5;
  static const double numberBadgeTop = -5;

  // ============================================================
  // NOTICE
  // ============================================================

  static const EdgeInsets noticePadding = EdgeInsets.all(16);
  static const double noticeContentSpacing = 12;
  static const double noticeDescriptionSpacing = 5;

  // ============================================================
  // ICONS
  // ============================================================

  static const IconData heroIcon = Icons.verified_user_outlined;

  static const IconData termsIcon = Icons.description_outlined;
  static const IconData privacyIcon = Icons.shield_outlined;

  static const IconData acceptanceIcon = Icons.task_alt_rounded;
  static const IconData appUseIcon = Icons.phone_android_rounded;
  static const IconData responsibilityIcon = Icons.groups_outlined;

  static const IconData intellectualPropertyIcon = Icons.copyright_rounded;

  static const IconData accuracyIcon = Icons.fact_check_outlined;
  static const IconData liabilityIcon = Icons.warning_amber_rounded;

  static const IconData collectionIcon = Icons.inventory_2_outlined;
  static const IconData dataUseIcon = Icons.manage_search_rounded;
  static const IconData offlineIcon = Icons.cloud_off_outlined;
  static const IconData dataProtectionIcon = Icons.security_rounded;
  static const IconData userRightsIcon = Icons.person_outline_rounded;
  static const IconData updatesIcon = Icons.sync_rounded;

  static const IconData informationIcon = Icons.info_outline_rounded;

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

  static const TextStyle introductionTitleStyle = TextStyle(
    color: textPrimaryColor,
    fontSize: 17,
    fontWeight: FontWeight.w800,
  );

  static const TextStyle bodyStyle = TextStyle(
    color: textSecondaryColor,
    fontSize: 13,
    height: 1.48,
  );

  static const TextStyle effectiveDateStyle = TextStyle(
    color: primaryColor,
    fontSize: 12,
    fontWeight: FontWeight.w700,
  );

  static const TextStyle selectedTabStyle = TextStyle(
    color: surfaceColor,
    fontSize: 12.5,
    fontWeight: FontWeight.w800,
    letterSpacing: -0.1,
  );

  static const TextStyle unselectedTabStyle = TextStyle(
    color: textPrimaryColor,
    fontSize: 12.5,
    fontWeight: FontWeight.w700,
    letterSpacing: -0.1,
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

  static const TextStyle policyTitleStyle = TextStyle(
    color: textPrimaryColor,
    fontSize: 14.5,
    fontWeight: FontWeight.w800,
  );

  static const TextStyle policyBodyStyle = TextStyle(
    color: textSecondaryColor,
    fontSize: 12.75,
    height: 1.5,
  );

  static const TextStyle numberBadgeTextStyle = TextStyle(
    color: surfaceColor,
    fontSize: 10,
    fontWeight: FontWeight.w800,
  );

  static const TextStyle noticeTitleStyle = TextStyle(
    color: textPrimaryColor,
    fontSize: 14,
    fontWeight: FontWeight.w800,
  );

  static const TextStyle noticeBodyStyle = TextStyle(
    color: textSecondaryColor,
    fontSize: 12.5,
    height: 1.45,
  );
}
