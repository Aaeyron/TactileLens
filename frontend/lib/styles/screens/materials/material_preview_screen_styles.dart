import 'package:flutter/material.dart';

abstract final class MaterialDetailScreenStyles {
  // ============================================================
  // COLORS
  // ============================================================

  static const Color primaryColor = Color(0xFF1268F3);
  static const Color primaryDarkColor = Color(0xFF0758DD);
  static const Color backgroundColor = Color(0xFFF4F7FC);
  static const Color surfaceColor = Colors.white;
  static const Color textPrimaryColor = Color(0xFF111827);
  static const Color textSecondaryColor = Color(0xFF667085);
  static const Color textMutedColor = Color(0xFF98A2B3);
  static const Color outlineColor = Color(0xFFE2E8F0);
  static const Color softBackgroundColor = Color(0xFFF4F7FC);
  static const Color scannedBadgeColor = Color(0xFFEAF2FF);
  static const Color uploadedBadgeColor = Color(0xFFECFDF3);
  static const Color uploadedBadgeTextColor = Color(0xFF067647);
  static const Color imageBackgroundColor = Color(0xFFF1F5F9);
  static const Color shadowColor = Color(0x0D000000);

  // ============================================================
  // HEADER
  // ============================================================

  static const double headerHeight = 156;

  static const EdgeInsets headerPadding = EdgeInsets.fromLTRB(14, 10, 20, 24);

  static const BorderRadius headerRadius = BorderRadius.only(
    bottomLeft: Radius.circular(28),
    bottomRight: Radius.circular(28),
  );

  static const LinearGradient headerGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: <Color>[Color(0xFF1677FF), Color(0xFF0758DD)],
  );

  static const double headerIconSize = 25;

  static const String screenTitle = 'Material Preview';

  static const String screenSubtitle =
      'Review saved content and accessible output.';

  static const String backTooltip = 'Go back to materials';

  static const IconData backIcon = Icons.arrow_back_rounded;

  static const TextStyle headerTitleStyle = TextStyle(
    fontFamily: 'Poppins',
    fontSize: 22,
    height: 1.2,
    fontWeight: FontWeight.w700,
    letterSpacing: -0.25,
    color: surfaceColor,
  );

  static const TextStyle headerSubtitleStyle = TextStyle(
    fontFamily: 'Poppins',
    fontSize: 12.5,
    height: 1.45,
    fontWeight: FontWeight.w400,
    color: Color(0xFFEAF2FF),
  );

  static final ButtonStyle headerBackButtonStyle = IconButton.styleFrom(
    foregroundColor: surfaceColor,
    backgroundColor: const Color(0x24FFFFFF),
    shape: const CircleBorder(),
  );

  // ============================================================
  // ENTRANCE ANIMATION
  // ============================================================

  static const Duration entranceDuration = Duration(milliseconds: 520);

  static const Curve entranceCurve = Curves.easeOutCubic;

  static const double entranceOffsetY = 18;

  // ============================================================
  // SCREEN LAYOUT
  // ============================================================

  static const EdgeInsets screenPadding = EdgeInsets.fromLTRB(14, 18, 14, 36);

  static const double sectionSpacing = 14;
  static const double itemSpacing = 12;
  static const double compactSpacing = 7;
  static const double metadataSpacing = 8;
  static const double zero = 0;

  // ============================================================
  // CARDS
  // ============================================================

  static const BorderRadius cardRadius = BorderRadius.all(Radius.circular(16));

  static const BorderRadius innerRadius = BorderRadius.all(Radius.circular(12));

  static const Border cardBorder = Border.fromBorderSide(
    BorderSide(color: outlineColor),
  );

  static const Border innerBorder = Border.fromBorderSide(
    BorderSide(color: outlineColor),
  );

  static const List<BoxShadow> cardShadow = <BoxShadow>[
    BoxShadow(color: Color(0x100F172A), blurRadius: 16, offset: Offset(0, 5)),
  ];

  static const EdgeInsets cardPadding = EdgeInsets.all(16);

  // ============================================================
  // MATERIAL INFORMATION
  // ============================================================

  static const String scannedBadgeLabel = 'Scanned Material';

  static const String uploadedBadgeLabel = 'Uploaded Material';

  static const String noSubjectLabel = 'No subject provided';

  static const String noDescriptionLabel = 'No description was provided.';

  static const EdgeInsets badgePadding = EdgeInsets.symmetric(
    horizontal: 11,
    vertical: 6,
  );

  static const BorderRadius badgeRadius = BorderRadius.all(Radius.circular(20));

  static const TextStyle scannedBadgeTextStyle = TextStyle(
    fontFamily: 'Poppins',
    fontSize: 12,
    fontWeight: FontWeight.w600,
    color: primaryColor,
  );

  static const TextStyle uploadedBadgeTextStyle = TextStyle(
    fontFamily: 'Poppins',
    fontSize: 12,
    fontWeight: FontWeight.w600,
    color: uploadedBadgeTextColor,
  );

  static const TextStyle materialTitleStyle = TextStyle(
    fontFamily: 'Poppins',
    fontSize: 21,
    height: 1.3,
    fontWeight: FontWeight.w700,
    color: textPrimaryColor,
  );

  static const TextStyle subjectStyle = TextStyle(
    fontFamily: 'Poppins',
    fontSize: 14,
    fontWeight: FontWeight.w500,
    color: primaryColor,
  );

  static const TextStyle descriptionStyle = TextStyle(
    fontFamily: 'Poppins',
    fontSize: 13,
    height: 1.55,
    fontWeight: FontWeight.w400,
    color: textSecondaryColor,
  );

  static const IconData calendarIcon = Icons.calendar_today_outlined;

  static const IconData fileIcon = Icons.insert_drive_file_outlined;

  static const IconData storageIcon = Icons.data_usage_rounded;

  static const double metadataIconSize = 17;

  static const TextStyle metadataTextStyle = TextStyle(
    fontFamily: 'Poppins',
    fontSize: 12,
    fontWeight: FontWeight.w400,
    color: textSecondaryColor,
  );

  // ============================================================
  // IMAGE OR FILE PREVIEW
  // ============================================================

  static const double imagePreviewHeight = 280;
  static const BoxFit imagePreviewFit = BoxFit.contain;

  static const BorderRadius imagePreviewRadius = BorderRadius.all(
    Radius.circular(14),
  );

  static const double filePreviewHeight = 190;
  static const double filePreviewIconSize = 58;

  static const IconData imageErrorIcon = Icons.broken_image_outlined;

  static const double imageErrorIconSize = 46;

  static const String imageErrorTitle = 'Preview unavailable';

  static const String imageErrorDescription =
      'The material image could not be displayed.';

  static const String filePreviewDescription =
      'A visual preview is not available for this file type.';

  static const TextStyle fileNameStyle = TextStyle(
    fontFamily: 'Poppins',
    fontSize: 14,
    fontWeight: FontWeight.w600,
    color: textPrimaryColor,
  );

  // ============================================================
  // CONTENT SECTIONS
  // ============================================================

  static const String recognizedSectionTitle = 'Recognized Content';

  static const String brailleSectionTitle = 'Braille Output';

  static const String fileInformationTitle = 'File Information';

  static const String copyLabel = 'Copy';
  static const String copyBrailleLabel = 'Copy Braille';

  static const String copyContentTooltip = 'Copy recognized content';

  static const String copyBrailleTooltip = 'Copy Braille output';

  static const IconData copyIcon = Icons.copy_rounded;

  static const double actionIconSize = 20;

  static const TextStyle sectionTitleStyle = TextStyle(
    fontFamily: 'Poppins',
    fontSize: 16,
    fontWeight: FontWeight.w600,
    color: textPrimaryColor,
  );

  static final ButtonStyle sectionActionStyle = TextButton.styleFrom(
    foregroundColor: const Color(0xFF1677FF),
    backgroundColor: const Color(0xFF1677FF).withValues(alpha: 0.10),
    padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 7),
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
    textStyle: const TextStyle(
      fontFamily: 'Poppins',
      fontSize: 12,
      fontWeight: FontWeight.w700,
    ),
  );

  static const EdgeInsets contentPadding = EdgeInsets.all(15);

  static const TextStyle recognizedContentStyle = TextStyle(
    fontFamily: 'Poppins',
    fontSize: 14,
    height: 1.65,
    fontWeight: FontWeight.w400,
    color: textPrimaryColor,
  );

  static const List<String> brailleFontFallback = <String>[
    'Noto Sans Symbols 2',
    'Noto Sans Symbols',
    'Noto Sans',
    'Roboto',
    'sans-serif',
  ];

  static const TextStyle brailleContentStyle = TextStyle(
    fontFamily: 'Noto Sans Symbols 2',
    fontFamilyFallback: brailleFontFallback,
    fontSize: 23,
    height: 1.7,
    fontWeight: FontWeight.w400,
    color: textPrimaryColor,
  );

  // ============================================================
  // FILE INFORMATION
  // ============================================================

  static const String fileNameLabel = 'File name';
  static const String fileTypeLabel = 'File type';
  static const String fileSizeLabel = 'File size';
  static const String uploadDateLabel = 'Saved on';

  static const TextStyle informationLabelStyle = TextStyle(
    fontFamily: 'Poppins',
    fontSize: 12,
    fontWeight: FontWeight.w500,
    color: textSecondaryColor,
  );

  static const TextStyle informationValueStyle = TextStyle(
    fontFamily: 'Poppins',
    fontSize: 13,
    fontWeight: FontWeight.w600,
    color: textPrimaryColor,
  );

  // ============================================================
  // EMPTY CONTENT
  // ============================================================

  static const IconData emptyContentIcon = Icons.notes_rounded;

  static const double emptyContentIconSize = 42;

  static const String emptyContentTitle = 'No recognized content';

  static const String emptyBrailleTitle = 'No Braille output';

  static const String emptyContentDescription =
      'This material does not contain saved OCR content.';

  static const String emptyBrailleDescription =
      'This material does not contain a saved Braille translation.';

  static const EdgeInsets emptyStatePadding = EdgeInsets.symmetric(
    horizontal: 20,
    vertical: 28,
  );

  static const TextStyle emptyTitleStyle = TextStyle(
    fontFamily: 'Poppins',
    fontSize: 15,
    fontWeight: FontWeight.w600,
    color: textPrimaryColor,
  );

  static const TextStyle emptyDescriptionStyle = TextStyle(
    fontFamily: 'Poppins',
    fontSize: 12,
    height: 1.5,
    color: textSecondaryColor,
  );

  // ============================================================
  // SNACKBAR
  // ============================================================

  static const String contentCopiedMessage = 'Recognized content copied.';

  static const String brailleCopiedMessage = 'Braille output copied.';

  static const Duration snackBarDuration = Duration(seconds: 2);

  static const SnackBarBehavior snackBarBehavior = SnackBarBehavior.floating;

  static const EdgeInsets snackBarMargin = EdgeInsets.all(16);

  static const BorderRadius snackBarRadius = BorderRadius.all(
    Radius.circular(12),
  );

  static const TextStyle snackBarTextStyle = TextStyle(
    fontFamily: 'Poppins',
    fontSize: 13,
    fontWeight: FontWeight.w500,
    color: surfaceColor,
  );

  // ============================================================
  // ACCESSIBILITY
  // ============================================================

  static const String imageSemanticLabel = 'Saved material image';

  static const String recognizedContentSemanticLabel =
      'Recognized material content';

  static const String brailleSemanticLabel = 'Saved Braille output';
}
