import 'package:flutter/material.dart';

abstract final class HomeStyles {
  // Content
  static const String greetingPrefix = 'Hi';
  static const String defaultUserName = 'Learner';
  static const String defaultRole = 'Student';
  static const String educatorRole = 'educator';

  static const String greetingDescription = 'Let’s make learning accessible.';

  static const String educatorGreetingDescription =
      'Let’s make teaching accessible.';

  static const String quickActionsTitle = 'Quick Actions';

  static const String scanActionTitle = 'Scan Material';
  static const String scanActionDescription =
      'Use your camera to capture printed text and mathematical equations.';

  static const String materialsActionTitle = 'Materials';
  static const String materialsActionDescription =
      'Open, organize, and review your saved accessible learning materials.';

  static const String historyActionTitle = 'Scan History';
  static const String historyActionDescription =
      'Review your previous scans, recognized content, and Braille results.';

  static const String recentActivityTitle = 'Recent Activity';
  static const String viewAllLabel = 'See all';

  static const String mathNemethLabel = 'Math • Nemeth';
  static const String textUebLabel = 'Text • UEB';

  static const String loadingTitle = 'Loading activity';
  static const String loadingDescription =
      'Your recent materials are being prepared.';

  static const String errorTitle = 'Activity unavailable';
  static const String loadFailureMessage =
      'Unable to load your recent activity.';

  static const String retryLabel = 'Try Again';

  static const String emptyTitle = 'No recent activity';
  static const String emptyDescription =
      'Scan your first learning material to see it here.';

  static const String scanNowLabel = 'Scan Now';

  static const String justNowLabel = 'Now';
  static const String minuteSuffix = 'm ago';
  static const String hourSuffix = 'h ago';
  static const String daySuffix = 'd ago';

  static const String pdfFileType = 'pdf';
  static const String imageFileType = 'image';
  static const String jpgFileType = 'jpg';
  static const String jpegFileType = 'jpeg';
  static const String pngFileType = 'png';

  // Colors
  static const Color backgroundColor = Color(0xFFF3F4F6);
  static const Color surfaceColor = Colors.white;

  static const Color primaryColor = Color(0xFF164EAD);
  static const Color secondaryActionColor = Color(0xFF164EAD);

  static const Color titleColor = Color(0xFF151B2A);
  static const Color bodyColor = Color(0xFF344054);
  static const Color mutedColor = Color(0xFF667085);

  static const Color outlineColor = Color(0xFFD0D5DD);
  static const Color thumbnailBackgroundColor = Color(0xFFF8FAFC);

  static const Color primaryActionIconBackground = Color(0xFF0878E8);

  static const Color secondaryActionIconBackground = Color(0x26FFFFFF);

  static const Color actionIconColor = Colors.white;

  // Icons
  static const IconData scanIcon = Icons.document_scanner_outlined;
  static const IconData materialsIcon = Icons.folder_outlined;
  static const IconData historyIcon = Icons.history_rounded;
  static const IconData forwardIcon = Icons.chevron_right_rounded;

  static const IconData errorIcon = Icons.cloud_off_outlined;
  static const IconData emptyIcon = Icons.history_toggle_off_rounded;
  static const IconData pdfIcon = Icons.picture_as_pdf_outlined;
  static const IconData imageIcon = Icons.image_outlined;
  static const IconData documentIcon = Icons.description_outlined;

  // General
  static const int maximumRecentMaterials = 3;

  // Screen
  static const EdgeInsets screenPadding = EdgeInsets.fromLTRB(24, 28, 24, 30);

  static const double greetingBottomSpacing = 22;
  static const double greetingSubtitleSpacing = 7;
  static const double sectionSpacing = 42;

  // Greeting card
  static const EdgeInsets greetingCardPadding = EdgeInsets.symmetric(
    horizontal: 20,
    vertical: 20,
  );

  static const BorderRadius greetingCardRadius = BorderRadius.all(
    Radius.circular(14),
  );

  static const List<BoxShadow> greetingCardShadow = <BoxShadow>[
    BoxShadow(color: Color(0x33164EAD), blurRadius: 16, offset: Offset(0, 6)),
  ];
  static const double recentHeaderSpacing = 13;
  static const double bottomSpacing = 28;

  // Animation
  static const Duration entranceAnimationDuration = Duration(milliseconds: 520);

  static const Duration entranceAnimationDelay = Duration(milliseconds: 180);

  static const Curve entranceAnimationCurve = Curves.easeOutCubic;

  static const double entranceFadeBegin = 0;
  static const double entranceFadeEnd = 1;

  static const Offset entranceSlideBegin = Offset(0, 0.025);

  // Quick actions
  static const double quickActionsTitleSpacing = 12;

  static const BorderRadius quickActionsRadius = BorderRadius.all(
    Radius.circular(14),
  );

  static const Border quickActionsBorder = Border.fromBorderSide(
    BorderSide(color: outlineColor, width: 1),
  );

  // Quick action rows
  static const EdgeInsets quickActionRowPadding = EdgeInsets.symmetric(
    horizontal: 16,
    vertical: 16,
  );

  static const double quickActionContentSpacing = 14;
  static const double quickActionDescriptionSpacing = 4;

  // Quick action icon
  static const double quickActionIconContainerSize = 52;
  static const double quickActionIconSize = 26;

  static const Color quickActionIconBackgroundColor = Color(0xFFEAF2FF);

  static const BorderRadius quickActionIconRadius = BorderRadius.all(
    Radius.circular(12),
  );

  static const Border quickActionIconBorder = Border.fromBorderSide(
    BorderSide(color: Color(0xFFC7DAF8), width: 1),
  );

  // Quick action arrow
  static const double quickActionArrowSpacing = 10;
  static const double quickActionArrowContainerSize = 32;
  static const double quickActionArrowIconSize = 21;

  static const Color quickActionArrowBackgroundColor = Color(0xFFF2F4F7);

  // Quick action dividers
  static const double quickActionDividerHeight = 1;
  static const double quickActionDividerThickness = 1;
  static const double quickActionDividerIndent = 82;
  static const double quickActionDividerEndIndent = 16;

  static const Color quickActionDividerColor = Color(0xFFE4E7EC);

  // Recent cards
  static const double recentItemSpacing = 10;

  static const BorderRadius recentCardRadius = BorderRadius.all(
    Radius.circular(10),
  );

  static const EdgeInsets recentCardPadding = EdgeInsets.symmetric(
    horizontal: 10,
    vertical: 10,
  );

  static const Border cardBorder = Border.fromBorderSide(
    BorderSide(color: outlineColor, width: 1),
  );

  static const Border thumbnailBorder = Border.fromBorderSide(
    BorderSide(color: Color(0xFFE1E5EA), width: 1),
  );

  static const BorderRadius thumbnailRadius = BorderRadius.all(
    Radius.circular(5),
  );

  static const double thumbnailSize = 48;
  static const double thumbnailIconSize = 25;
  static const double recentContentSpacing = 12;
  static const double recentMetadataSpacing = 3;

  // State cards
  static const EdgeInsets stateCardPadding = EdgeInsets.symmetric(
    horizontal: 24,
    vertical: 28,
  );

  static const double stateIconSize = 40;
  static const double stateContentSpacing = 12;
  static const double stateDescriptionSpacing = 6;
  static const double stateActionSpacing = 16;

  // Buttons
  static final ButtonStyle viewAllButtonStyle = TextButton.styleFrom(
    foregroundColor: primaryColor,
    padding: const EdgeInsets.symmetric(horizontal: 4),
    textStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
  );

  // Typography
  static const TextStyle greetingStyle = TextStyle(
    color: Colors.white,
    fontSize: 24,
    height: 1.15,
    fontWeight: FontWeight.w800,
  );

  static const TextStyle greetingDescriptionStyle = TextStyle(
    color: Color(0xFFE4EEFF),
    fontSize: 14,
    height: 1.4,
    fontWeight: FontWeight.w500,
  );

  static const TextStyle quickActionTitleStyle = TextStyle(
    color: titleColor,
    fontSize: 15,
    fontWeight: FontWeight.w700,
  );

  static const TextStyle quickActionDescriptionStyle = TextStyle(
    color: bodyColor,
    fontSize: 12,
    height: 1.4,
    fontWeight: FontWeight.w400,
  );

  static const TextStyle sectionTitleStyle = TextStyle(
    color: titleColor,
    fontSize: 16,
    fontWeight: FontWeight.w700,
  );

  static const TextStyle recentTitleStyle = TextStyle(
    color: titleColor,
    fontSize: 14,
    fontWeight: FontWeight.w700,
  );

  static const TextStyle recentMetadataStyle = TextStyle(
    color: mutedColor,
    fontSize: 11,
    fontWeight: FontWeight.w400,
  );

  static const TextStyle relativeTimeStyle = TextStyle(
    color: mutedColor,
    fontSize: 10,
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

  static const Color greetingCardBackgroundColor = primaryColor;

  static const Border greetingCardBorder = Border.fromBorderSide(
    BorderSide(color: Color(0xFF2D67BF), width: 1),
  );
}
