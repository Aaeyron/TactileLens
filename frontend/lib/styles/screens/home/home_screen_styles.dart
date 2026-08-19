import 'package:flutter/material.dart';

abstract final class HomeStyles {
  // Text content
  static const String logoAsset = 'assets/icons/tactilelens_app_icon.png';

  static const String appName = 'TactileLens';
  static const String greetingPrefix = 'Hello';
  static const String defaultUserName = 'Learner';
  static const String defaultRole = 'Student';
  static const String defaultInitial = 'T';

  static const String welcomeDescription =
      'Transform printed materials into accessible learning.';

  static const String guestWelcomeDescription =
      'Create accessible materials locally while using offline mode.';

  static const String offlineRolePrefix = 'Offline';

  static const String quickActionsTitle = 'Quick Actions';

  static const String scanTitle = 'Scan Material';
  static const String scanDescription =
      'Use the camera to recognize printed text and equations.';

  static const String uploadTitle = 'Upload File';
  static const String uploadDescription =
      'Choose an image or document from your device.';

  static const String materialsTitle = 'View Materials';
  static const String materialsDescription =
      'Review saved scans, uploads, and Braille output.';

  static const String recentMaterialsTitle = 'Recent Materials';
  static const String viewAllLabel = 'View All';

  static const String loadingMaterialsTitle = 'Loading your materials';

  static const String loadingMaterialsDescription =
      'Your latest accessible materials are being prepared.';

  static const String materialsErrorTitle = 'Materials unavailable';

  static const String loadFailureMessage =
      'Unable to load your Home information.';

  static const String retryLabel = 'Try Again';

  static const String emptyMaterialsTitle = 'No materials yet';

  static const String emptyMaterialsDescription =
      'Scan or upload your first material to see it here.';

  static const String scanNowLabel = 'Scan Now';

  static const String encouragementTitle = 'Keep going!';

  static const String encouragementDescription =
      'Continue exploring and creating accessible learning materials.';

  static const String todayLabel = 'Today';
  static const String yesterdayLabel = 'Yesterday';

  static const String byteLabel = 'B';
  static const String kilobyteLabel = 'KB';
  static const String megabyteLabel = 'MB';

  static const String pdfFileType = 'pdf';
  static const String imageFileType = 'image';
  static const String jpgFileType = 'jpg';
  static const String jpegFileType = 'jpeg';
  static const String pngFileType = 'png';

  static const String metadataSeparator = '  •  ';

  // Colors
  static const Color backgroundColor = Colors.white;
  static const Color surfaceColor = Colors.white;

  static const Color primaryColor = Color(0xFF0D47A1);
  static const Color primaryBrightColor = Color(0xFF1268F3);

  static const Color titleColor = Color(0xFF07143D);
  static const Color bodyColor = Color(0xFF53658F);
  static const Color mutedColor = Color(0xFF8291B1);

  static const Color outlineColor = Color(0xFFBCD0EA);
  static const Color dividerColor = Color(0xFFDCE6F3);

  static const Color softBlueColor = Colors.white;

  static const Color avatarBackgroundColor = Colors.white;

  static const Color illustrationBackgroundColor = Colors.white;

  static const Color illustrationBookColor = primaryBrightColor;

  static const Color scanIconBackgroundColor = Colors.white;

  static const Color uploadColor = primaryBrightColor;

  static const Color uploadIconBackgroundColor = Colors.white;

  static const Color materialsColor = primaryBrightColor;

  static const Color materialsIconBackgroundColor = Colors.white;

  static const Color pdfColor = primaryBrightColor;
  static const Color imageColor = primaryBrightColor;

  static const Color encouragementBackgroundColor = Colors.white;

  // Icons
  static const IconData offlineIcon = Icons.offline_bolt_outlined;
  static const IconData syncedIcon = Icons.cloud_done_outlined;

  static const IconData illustrationBookIcon = Icons.menu_book_rounded;

  static const IconData illustrationSearchIcon = Icons.search_rounded;

  static const IconData profileStatusIcon = Icons.verified_user_outlined;

  static const IconData scanIcon = Icons.document_scanner_outlined;

  static const IconData uploadIcon = Icons.upload_file_outlined;

  static const IconData materialsIcon = Icons.grid_view_rounded;

  static const IconData forwardIcon = Icons.arrow_forward_rounded;

  static const IconData errorIcon = Icons.cloud_off_outlined;

  static const IconData emptyMaterialsIcon = Icons.folder_open_outlined;

  static const IconData pdfIcon = Icons.picture_as_pdf_outlined;

  static const IconData imageIcon = Icons.image_outlined;

  static const IconData documentIcon = Icons.description_outlined;

  static const IconData viewMaterialIcon = Icons.visibility_outlined;

  static const IconData encouragementIcon = Icons.workspace_premium_outlined;

  // Numeric values
  static const double zero = 0;
  static const double bytesPerKilobyte = 1024;

  static const int maximumRecentMaterials = 3;
  static const int actionDescriptionMaximumLines = 3;

  static const int welcomeTextFlex = 3;
  static const int welcomeIllustrationFlex = 2;

  // Screen layout
  static const EdgeInsets screenPadding = EdgeInsets.fromLTRB(20, 20, 20, 24);

  static const double greetingTopSpacing = 34;
  static const double sectionSpacing = 28;
  static const double sectionTitleSpacing = 14;
  static const double bottomContentSpacing = 24;

  // Home entrance animation
  static const Duration entranceAnimationDuration = Duration(milliseconds: 550);

  static const Curve entranceAnimationCurve = Curves.easeOutCubic;

  static const double entranceFadeBegin = 0;
  static const double entranceFadeEnd = 1;

  static const Offset entranceSlideBegin = Offset(0, 0.035);

  static const Duration entranceAnimationDelay = Duration(milliseconds: 180);

  // Brand header
  static const double logoSize = 52;
  static const double logoTextSpacing = 14;

  static const BorderRadius logoRadius = BorderRadius.all(Radius.circular(14));

  static const double statusButtonSize = 44;
  static const double statusIconSize = 23;

  // Welcome section
  static const double greetingDescriptionSpacing = 12;
  static const double welcomeContentSpacing = 16;
  static const double illustrationHeight = 142;

  static const BorderRadius illustrationRadius = BorderRadius.all(
    Radius.circular(24),
  );

  static const double illustrationBookIconSize = 86;
  static const double illustrationSearchIconSize = 52;
  static const double illustrationSearchRight = 8;
  static const double illustrationSearchBottom = 8;

  // Shared cards
  static const BorderRadius cardRadius = BorderRadius.all(Radius.circular(20));

  static const double cardBorderWidth = 1.2;

  static const Border cardBorder = Border.fromBorderSide(
    BorderSide(color: outlineColor, width: cardBorderWidth),
  );

  static const List<BoxShadow> cardShadow = <BoxShadow>[
    BoxShadow(
      color: Color(0x1A0D47A1),
      blurRadius: 18,
      spreadRadius: 1,
      offset: Offset(0, 6),
    ),
  ];

  static const Border smallContainerBorder = Border.fromBorderSide(
    BorderSide(color: outlineColor, width: 1),
  );

  static const List<BoxShadow> smallContainerShadow = <BoxShadow>[
    BoxShadow(color: Color(0x120D47A1), blurRadius: 10, offset: Offset(0, 3)),
  ];
  // Profile
  static const EdgeInsets profileCardPadding = EdgeInsets.all(18);

  static const double avatarSize = 58;
  static const double profileContentSpacing = 14;
  static const double profileRoleSpacing = 4;
  static const double profileStatusIconSize = 24;

  // Quick actions
  static const double wideQuickActionsBreakpoint = 700;
  static const double quickActionCardHeight = 236;
  static const double compactQuickActionWidth = 214;
  static const double quickActionSpacing = 12;

  static const EdgeInsets quickActionPadding = EdgeInsets.all(18);

  static const double actionIconContainerSize = 54;
  static const double actionIconSize = 28;
  static const double actionDescriptionSpacing = 8;
  static const double actionArrowSpacing = 12;
  static const double actionArrowSize = 24;

  // Recent materials
  static const EdgeInsets recentMaterialPadding = EdgeInsets.symmetric(
    horizontal: 16,
    vertical: 15,
  );

  static const double recentFileIconContainerSize = 48;
  static const double recentFileIconSize = 26;
  static const double recentMaterialContentSpacing = 12;
  static const double recentMetadataSpacing = 5;
  static const double recentDividerIndent = 76;
  static const double dividerHeight = 1;
  static const double viewMaterialIconSize = 23;
  static const double fileIconBackgroundOpacity = 0.12;

  static const BorderRadius fileIconRadius = BorderRadius.all(
    Radius.circular(13),
  );

  // Empty, loading and error states
  static const EdgeInsets stateCardPadding = EdgeInsets.symmetric(
    horizontal: 24,
    vertical: 30,
  );

  static const double stateIconSize = 42;
  static const double stateContentSpacing = 14;
  static const double stateDescriptionSpacing = 7;
  static const double stateActionSpacing = 18;

  // Encouragement card
  static const EdgeInsets encouragementPadding = EdgeInsets.all(20);

  static const Border encouragementBorder = Border.fromBorderSide(
    BorderSide(color: outlineColor, width: cardBorderWidth),
  );

  static const double encouragementIconSize = 44;
  static const double encouragementContentSpacing = 16;
  static const double encouragementDescriptionSpacing = 5;

  // Buttons
  static const double viewAllIconSize = 19;

  static ButtonStyle viewAllButtonStyle = TextButton.styleFrom(
    foregroundColor: primaryBrightColor,
    padding: const EdgeInsets.symmetric(horizontal: 8),
  );

  static ButtonStyle stateButtonStyle = FilledButton.styleFrom(
    backgroundColor: primaryColor,
    foregroundColor: surfaceColor,
    elevation: 0,
  );

  // Text styles
  static const TextStyle appNameStyle = TextStyle(
    color: titleColor,
    fontSize: 25,
    fontWeight: FontWeight.w800,
    letterSpacing: -0.4,
  );

  static const TextStyle greetingStyle = TextStyle(
    color: titleColor,
    fontSize: 30,
    height: 1.15,
    fontWeight: FontWeight.w800,
    letterSpacing: -0.7,
  );

  static const TextStyle welcomeDescriptionStyle = TextStyle(
    color: bodyColor,
    fontSize: 16,
    height: 1.5,
    fontWeight: FontWeight.w400,
  );

  static const TextStyle profileNameStyle = TextStyle(
    color: titleColor,
    fontSize: 17,
    fontWeight: FontWeight.w700,
  );

  static const TextStyle profileRoleStyle = TextStyle(
    color: primaryBrightColor,
    fontSize: 14,
    fontWeight: FontWeight.w600,
  );

  static const TextStyle avatarTextStyle = TextStyle(
    color: primaryBrightColor,
    fontSize: 25,
    fontWeight: FontWeight.w700,
  );

  static const TextStyle sectionTitleStyle = TextStyle(
    color: titleColor,
    fontSize: 21,
    fontWeight: FontWeight.w800,
    letterSpacing: -0.25,
  );

  static const TextStyle actionTitleStyle = TextStyle(
    color: titleColor,
    fontSize: 16,
    fontWeight: FontWeight.w700,
  );

  static const TextStyle actionDescriptionStyle = TextStyle(
    color: bodyColor,
    fontSize: 13,
    height: 1.45,
  );

  static const TextStyle recentMaterialTitleStyle = TextStyle(
    color: titleColor,
    fontSize: 15,
    fontWeight: FontWeight.w700,
  );

  static const TextStyle recentMetadataStyle = TextStyle(
    color: mutedColor,
    fontSize: 12,
    fontWeight: FontWeight.w500,
  );

  static const TextStyle stateTitleStyle = TextStyle(
    color: titleColor,
    fontSize: 17,
    fontWeight: FontWeight.w700,
  );

  static const TextStyle stateDescriptionStyle = TextStyle(
    color: bodyColor,
    fontSize: 14,
    height: 1.45,
  );

  static const TextStyle encouragementTitleStyle = TextStyle(
    color: primaryBrightColor,
    fontSize: 17,
    fontWeight: FontWeight.w700,
  );

  static const TextStyle encouragementDescriptionStyle = TextStyle(
    color: bodyColor,
    fontSize: 14,
    height: 1.4,
  );
}
