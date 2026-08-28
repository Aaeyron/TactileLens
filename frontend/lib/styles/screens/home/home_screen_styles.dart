import 'package:flutter/material.dart';

abstract final class HomeStyles {
  // ============================================================
  // COLORS
  // ============================================================

  static const Color backgroundColor = Color(0xFFF4F7FC);
  static const Color surfaceColor = Colors.white;

  static const Color primaryColor = Color(0xFF1268F3);
  static const Color primaryDarkColor = Color(0xFF0B4FCC);
  static const Color primaryLightColor = Color(0xFF4894FF);

  static const Color titleColor = Color(0xFF10213D);
  static const Color bodyColor = Color(0xFF42526B);
  static const Color mutedColor = Color(0xFF728096);

  static const Color outlineColor = Color(0xFFDDE5F0);
  static const Color dividerColor = Color(0xFFE8EDF4);

  static const Color thumbnailBackgroundColor = Color(0xFFF2F6FC);
  static const Color recentArrowColor = Color(0xFF8B98AA);

  static const Color quickScanIconBackgroundColor = Color(0xFFEAF3FF);
  static const Color secondaryActionIconBackgroundColor = Color(0xFFEDF4FF);

  // ============================================================
  // ICONS
  // ============================================================

  static const IconData scanIcon = Icons.document_scanner_rounded;
  static const IconData cameraIcon = Icons.photo_camera_rounded;

  static const IconData notificationIcon = Icons.notifications_none_rounded;

  static const IconData materialsIcon = Icons.folder_copy_outlined;
  static const IconData historyIcon = Icons.history_rounded;
  static const IconData forwardIcon = Icons.chevron_right_rounded;

  static const IconData errorIcon = Icons.cloud_off_outlined;
  static const IconData emptyIcon = Icons.history_toggle_off_rounded;

  static const IconData pdfIcon = Icons.picture_as_pdf_outlined;
  static const IconData imageIcon = Icons.image_outlined;
  static const IconData documentIcon = Icons.description_outlined;

  // ============================================================
  // GENERAL
  // ============================================================

  static const int maximumRecentMaterials = 3;

  static const EdgeInsets contentPadding = EdgeInsets.fromLTRB(18, 12, 18, 28);

  static const double sectionSpacing = 22;
  static const double recentHeaderSpacing = 6;
  static const double bottomSpacing = 28;

  // ============================================================
  // ENTRANCE ANIMATION
  // ============================================================

  static const Duration entranceAnimationDuration = Duration(milliseconds: 540);

  static const Duration entranceAnimationDelay = Duration(milliseconds: 100);

  static const Curve entranceAnimationCurve = Curves.easeOutCubic;

  static const double entranceFadeBegin = 0;
  static const double entranceFadeEnd = 1;

  static const Offset entranceSlideBegin = Offset(0, 0.025);

  // ============================================================
  // FULL-WIDTH HOME HEADER
  // ============================================================

  static const LinearGradient greetingGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: <Color>[Color(0xFF1474F5), Color(0xFF0758DD)],
  );

  static const double headerSectionHeight = 400;
  static const double blueHeaderHeight = 218;

  static const double headerHorizontalPadding = 20;
  static const double headerTopPadding = 14;
  static const double headerBottomPadding = 60;

  static const BorderRadius blueHeaderRadius = BorderRadius.only(
    bottomLeft: Radius.circular(30),
    bottomRight: Radius.circular(30),
  );

  static const double quickScanCardTop = 200;

  static const double greetingSubtitleSpacing = 6;

  static const double headerBrailleRight = 3;
  static const double headerBrailleBottom = 25;

  static const double heroDecorationOpacity = 0.18;
  static const double heroDecorationWidth = 45;
  static const double heroDotSize = 4;
  static const double heroDotSpacing = 7;
  static const int heroDotCount = 12;

  static const double notificationButtonSize = 42;
  static const double notificationIconSize = 25;
  static const double notificationTapRadius = 25;

  // ============================================================
  // SHARED CARDS
  // ============================================================

  static const Border cardBorder = Border.fromBorderSide(
    BorderSide(color: outlineColor, width: 1),
  );

  static const List<BoxShadow> cardShadow = <BoxShadow>[
    BoxShadow(color: Color(0x120F2748), blurRadius: 18, offset: Offset(0, 7)),
  ];

  static const List<BoxShadow> subtleCardShadow = <BoxShadow>[
    BoxShadow(color: Color(0x0D102A43), blurRadius: 12, offset: Offset(0, 4)),
  ];

  // ============================================================
  // QUICK SCAN
  // ============================================================

  static const EdgeInsets quickScanCardPadding = EdgeInsets.all(17);

  static const BorderRadius quickScanCardRadius = BorderRadius.all(
    Radius.circular(18),
  );

  static const double quickScanDescriptionSpacing = 6;
  static const double quickScanIconSpacing = 14;
  static const double quickScanButtonSpacing = 16;

  static const double quickScanIconContainerSize = 64;
  static const double quickScanIconSize = 34;

  static const BorderRadius quickScanIconRadius = BorderRadius.all(
    Radius.circular(18),
  );

  static const double quickScanButtonHeight = 46;
  static const double quickScanButtonIconSize = 19;

  static final ButtonStyle quickScanButtonStyle = FilledButton.styleFrom(
    backgroundColor: primaryColor,
    foregroundColor: surfaceColor,
    elevation: 0,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.all(Radius.circular(12)),
    ),
    textStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
  );

  // ============================================================
  // SECONDARY QUICK ACTIONS
  // ============================================================

  static const double secondaryActionSpacing = 12;

  static const EdgeInsets secondaryActionPadding = EdgeInsets.all(14);

  static const BorderRadius secondaryActionRadius = BorderRadius.all(
    Radius.circular(16),
  );

  static const double secondaryActionIconContainerSize = 38;
  static const double secondaryActionIconSize = 20;

  static const BorderRadius secondaryActionIconRadius = BorderRadius.all(
    Radius.circular(10),
  );

  static const double secondaryActionArrowSize = 20;
  static const double secondaryActionTitleSpacing = 12;
  static const double secondaryActionDescriptionSpacing = 5;

  // ============================================================
  // RECENT ACTIVITY
  // ============================================================

  static const BorderRadius recentListRadius = BorderRadius.all(
    Radius.circular(16),
  );

  static const EdgeInsets recentCardPadding = EdgeInsets.symmetric(
    horizontal: 12,
    vertical: 11,
  );

  static const double recentDividerHeight = 1;
  static const double recentDividerThickness = 1;
  static const double recentDividerIndent = 78;

  static const double thumbnailWidth = 54;
  static const double thumbnailHeight = 62;
  static const double thumbnailIconSize = 25;

  static const Border thumbnailBorder = Border.fromBorderSide(
    BorderSide(color: Color(0xFFDDE4EE), width: 1),
  );

  static const BorderRadius thumbnailRadius = BorderRadius.all(
    Radius.circular(8),
  );

  static const double recentContentSpacing = 12;
  static const double recentMetadataSpacing = 4;
  static const double recentDateSpacing = 4;
  static const double recentTrailingSpacing = 8;
  static const double recentArrowSize = 21;

  // ============================================================
  // STATE CARDS
  // ============================================================

  static const EdgeInsets stateCardPadding = EdgeInsets.symmetric(
    horizontal: 24,
    vertical: 28,
  );

  static const double stateIconContainerSize = 52;
  static const double stateIconSize = 27;

  static const double stateProgressSize = 32;
  static const double stateProgressStrokeWidth = 3;

  static const double stateContentSpacing = 13;
  static const double stateDescriptionSpacing = 6;
  static const double stateActionSpacing = 16;

  static final ButtonStyle stateActionButtonStyle = FilledButton.styleFrom(
    backgroundColor: primaryColor,
    foregroundColor: surfaceColor,
    elevation: 0,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.all(Radius.circular(11)),
    ),
  );

  // ============================================================
  // BUTTONS
  // ============================================================

  static final ButtonStyle viewAllButtonStyle = TextButton.styleFrom(
    foregroundColor: primaryColor,
    padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
    minimumSize: const Size(48, 34),
    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
    textStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
  );

  // ============================================================
  // TYPOGRAPHY
  // ============================================================

  static const TextStyle appNameStyle = TextStyle(
    color: surfaceColor,
    fontSize: 18,
    height: 1.2,
    fontWeight: FontWeight.w700,
    letterSpacing: -0.2,
  );

  static const TextStyle greetingStyle = TextStyle(
    color: surfaceColor,
    fontSize: 25,
    height: 1.12,
    fontWeight: FontWeight.w800,
    letterSpacing: -0.45,
  );

  static const TextStyle greetingDescriptionStyle = TextStyle(
    color: Color(0xFFE9F2FF),
    fontSize: 13.5,
    height: 1.35,
    fontWeight: FontWeight.w500,
  );

  static const TextStyle quickScanTitleStyle = TextStyle(
    color: titleColor,
    fontSize: 18,
    height: 1.2,
    fontWeight: FontWeight.w800,
    letterSpacing: -0.2,
  );

  static const TextStyle quickScanDescriptionStyle = TextStyle(
    color: bodyColor,
    fontSize: 12.5,
    height: 1.42,
    fontWeight: FontWeight.w400,
  );

  static const TextStyle secondaryActionTitleStyle = TextStyle(
    color: titleColor,
    fontSize: 14,
    height: 1.2,
    fontWeight: FontWeight.w700,
  );

  static const TextStyle secondaryActionDescriptionStyle = TextStyle(
    color: bodyColor,
    fontSize: 11,
    height: 1.35,
    fontWeight: FontWeight.w400,
  );

  static const TextStyle sectionTitleStyle = TextStyle(
    color: titleColor,
    fontSize: 16,
    height: 1.2,
    fontWeight: FontWeight.w800,
    letterSpacing: -0.15,
  );

  static const TextStyle recentTitleStyle = TextStyle(
    color: titleColor,
    fontSize: 13.5,
    height: 1.2,
    fontWeight: FontWeight.w700,
  );

  static const TextStyle recentMetadataStyle = TextStyle(
    color: bodyColor,
    fontSize: 11,
    height: 1.2,
    fontWeight: FontWeight.w500,
  );

  static const TextStyle relativeTimeStyle = TextStyle(
    color: mutedColor,
    fontSize: 10.5,
    height: 1.2,
    fontWeight: FontWeight.w500,
  );

  static const TextStyle stateTitleStyle = TextStyle(
    color: titleColor,
    fontSize: 16,
    fontWeight: FontWeight.w700,
  );

  static const TextStyle stateDescriptionStyle = TextStyle(
    color: mutedColor,
    fontSize: 13,
    height: 1.4,
  );
}
