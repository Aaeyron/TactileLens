import 'package:flutter/material.dart';

abstract final class ScanResultScreenStyles {
  // ============================================================
  // BRAND AND SURFACE COLORS
  // ============================================================

  static const Color primaryColor = Color(0xFF0D47A1);
  static const Color backgroundColor = Color(0xFFFFFFFF);
  static const Color surfaceColor = Color(0xFFFFFFFF);
  static const Color primarySoftColor = Color(0xFFF2F6FC);
  static const Color primaryTintColor = Color(0xFFE8F0FB);

  static const Color textPrimaryColor = Color(0xFF10213A);
  static const Color textSecondaryColor = Color(0xFF5D6B7E);
  static const Color outlineColor = Color(0xFFD7E0EC);
  static const Color dividerColor = Color(0xFFE7ECF3);
  static const Color shadowColor = Color(0x14000000);

  // ============================================================
  // SCREEN
  // ============================================================

  static const EdgeInsets screenPadding = EdgeInsets.fromLTRB(
    20.0,
    20.0,
    20.0,
    32.0,
  );

  static const double sectionSpacing = 22.0;
  static const double itemSpacing = 12.0;
  static const double compactSpacing = 8.0;

  // ============================================================
  // APP BAR
  // ============================================================

  static const Color appBarBackgroundColor = backgroundColor;
  static const Color appBarForegroundColor = primaryColor;
  static const double appBarElevation = 0.0;

  static const String appBarTitle = 'Scan Result';

  static const TextStyle appBarTitleStyle = TextStyle(
    fontFamily: 'Poppins',
    fontSize: 18.0,
    fontWeight: FontWeight.w600,
    color: textPrimaryColor,
  );

  // ============================================================
  // IMAGE PREVIEW
  // ============================================================

  static const double imagePreviewHeight = 220.0;
  static const BoxFit imagePreviewFit = BoxFit.contain;

  static const BorderRadius imagePreviewRadius =
      BorderRadius.all(Radius.circular(18.0));

  static const Color imagePreviewBackgroundColor =
      primarySoftColor;

  static const Color imagePreviewBorderColor = outlineColor;
  static const double imagePreviewBorderWidth = 1.2;

  static const IconData imageErrorIcon =
      Icons.broken_image_outlined;

  static const double imageErrorIconSize = 42.0;

  static const String imageErrorText =
      'Unable to display the scanned image.';

  // ============================================================
  // GENERAL CONTAINERS
  // ============================================================

  static const EdgeInsets cardPadding = EdgeInsets.all(16.0);

  static const BorderRadius cardRadius =
      BorderRadius.all(Radius.circular(16.0));

  static const double cardBorderWidth = 1.0;

  static const List<BoxShadow> cardShadow = <BoxShadow>[
    BoxShadow(
      color: shadowColor,
      blurRadius: 12.0,
      offset: Offset(0.0, 4.0),
    ),
  ];

  // ============================================================
  // STATUS CARD
  // ============================================================

  static const String statusTitle = 'Recognition Complete';

  static const String statusDescription =
      'Review the recognized text and equations before continuing.';

  static const IconData statusIcon =
      Icons.check_circle_outline_rounded;

  static const double statusIconContainerSize = 52.0;
  static const double statusIconSize = 28.0;

  static const BorderRadius statusIconRadius =
      BorderRadius.all(Radius.circular(14.0));

  static const TextStyle statusTitleStyle = TextStyle(
    fontFamily: 'Poppins',
    fontSize: 16.0,
    fontWeight: FontWeight.w600,
    color: primaryColor,
  );

  static const TextStyle statusDescriptionStyle = TextStyle(
    fontFamily: 'Poppins',
    fontSize: 13.0,
    height: 1.5,
    fontWeight: FontWeight.w400,
    color: textSecondaryColor,
  );

  // ============================================================
  // METRICS
  // ============================================================

  static const String textMetricLabel = 'Text';
  static const String formulaMetricLabel = 'Equations';
  static const String pageMetricLabel = 'Pages';
  static const String timeMetricLabel = 'Time';

  static const String secondUnit = 's';

  static const IconData textMetricIcon =
      Icons.notes_rounded;

  static const IconData formulaMetricIcon =
      Icons.functions_rounded;

  static const IconData pageMetricIcon =
      Icons.description_outlined;

  static const IconData timeMetricIcon =
      Icons.timer_outlined;

  static const double metricSpacing = 10.0;
  static const EdgeInsets metricPadding =
      EdgeInsets.symmetric(
    horizontal: 12.0,
    vertical: 10.0,
  );

  static const BorderRadius metricRadius =
      BorderRadius.all(Radius.circular(12.0));

  static const double metricIconSize = 20.0;

  static const TextStyle metricValueStyle = TextStyle(
    fontFamily: 'Poppins',
    fontSize: 14.0,
    fontWeight: FontWeight.w600,
    color: primaryColor,
  );

  static const TextStyle metricLabelStyle = TextStyle(
    fontFamily: 'Poppins',
    fontSize: 11.0,
    fontWeight: FontWeight.w500,
    color: textSecondaryColor,
  );

  // ============================================================
  // CONTENT SECTION
  // ============================================================

  static const String contentSectionTitle =
      'Recognized Content';

  static const String contentSectionDescription =
      'Content is displayed in the reading order detected by PaddleOCR-VL.';

  static const TextStyle sectionTitleStyle = TextStyle(
    fontFamily: 'Poppins',
    fontSize: 18.0,
    fontWeight: FontWeight.w600,
    color: primaryColor,
  );

  static const TextStyle sectionDescriptionStyle = TextStyle(
    fontFamily: 'Poppins',
    fontSize: 13.0,
    height: 1.5,
    fontWeight: FontWeight.w400,
    color: textSecondaryColor,
  );

  // ============================================================
  // RECOGNIZED BLOCKS
  // ============================================================

  static const String textBlockLabel = 'English Text';
  static const String formulaBlockLabel = 'Equation';
  static const String unknownBlockLabel = 'Document Content';

  static const IconData textBlockIcon =
      Icons.subject_rounded;

  static const IconData formulaBlockIcon =
      Icons.functions_rounded;

  static const IconData unknownBlockIcon =
      Icons.article_outlined;

  static const IconData copyIcon =
      Icons.copy_rounded;

  static const double blockHeaderIconSize = 21.0;
  static const double copyIconSize = 20.0;

  static const double blockIconContainerSize = 40.0;

  static const BorderRadius blockIconRadius =
      BorderRadius.all(Radius.circular(11.0));

  static const EdgeInsets blockContentPadding =
      EdgeInsets.all(16.0);

  static const Color textBlockBackgroundColor = surfaceColor;
  static const Color formulaBlockBackgroundColor =
      primarySoftColor;

  static const TextStyle blockNumberStyle = TextStyle(
    fontFamily: 'Poppins',
    fontSize: 11.0,
    fontWeight: FontWeight.w500,
    color: textSecondaryColor,
  );

  static const TextStyle blockLabelStyle = TextStyle(
    fontFamily: 'Poppins',
    fontSize: 14.0,
    fontWeight: FontWeight.w600,
    color: primaryColor,
  );

  static const TextStyle blockContentStyle = TextStyle(
    fontFamily: 'Poppins',
    fontSize: 14.0,
    height: 1.6,
    fontWeight: FontWeight.w400,
    color: textPrimaryColor,
  );

  static const TextStyle formulaContentStyle = TextStyle(
    fontFamily: 'Poppins',
    fontSize: 15.0,
    height: 1.6,
    fontWeight: FontWeight.w500,
    color: textPrimaryColor,
  );

  static const Color copyIconColor = primaryColor;
  static const String copyTooltip = 'Copy recognized content';

  // ============================================================
  // EMPTY RESULT
  // ============================================================

  static const IconData emptyResultIcon =
      Icons.find_in_page_outlined;

  static const double emptyResultIconSize = 48.0;

  static const String emptyResultTitle =
      'No content recognized';

  static const String emptyResultDescription =
      'Try scanning again with clearer lighting and a sharper image.';

  static const TextStyle emptyResultTitleStyle = TextStyle(
    fontFamily: 'Poppins',
    fontSize: 16.0,
    fontWeight: FontWeight.w600,
    color: textPrimaryColor,
  );

  static const TextStyle emptyResultDescriptionStyle =
      TextStyle(
    fontFamily: 'Poppins',
    fontSize: 13.0,
    height: 1.5,
    fontWeight: FontWeight.w400,
    color: textSecondaryColor,
  );

  // ============================================================
  // SNACKBAR
  // ============================================================

  static const String copiedMessage =
      'Recognized content copied.';

  static const Duration snackBarDuration =
      Duration(seconds: 2);

  static const Color snackBarBackgroundColor =
      primaryColor;

  static const TextStyle snackBarTextStyle = TextStyle(
    fontFamily: 'Poppins',
    fontSize: 13.0,
    fontWeight: FontWeight.w500,
    color: surfaceColor,
  );

  static const SnackBarBehavior snackBarBehavior =
      SnackBarBehavior.floating;

  static const EdgeInsets snackBarMargin =
      EdgeInsets.all(16.0);

  static const BorderRadius snackBarRadius =
      BorderRadius.all(Radius.circular(12.0));

  // ============================================================
  // ACCESSIBILITY
  // ============================================================

  static const String imageSemanticLabel =
      'Image processed by PaddleOCR-VL';

  static const String resultSemanticLabel =
      'Recognized document content';
}