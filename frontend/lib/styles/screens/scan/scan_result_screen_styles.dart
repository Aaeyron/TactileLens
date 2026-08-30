import 'package:flutter/material.dart';

abstract final class ScanResultScreenStyles {
  // ============================================================
  // COLORS
  // ============================================================

  static const Color primaryColor = Color(0xFF1268F3);
  static const Color primaryDarkColor = Color(0xFF0758DD);

  static const Color backgroundColor = Color(0xFFF4F7FC);
  static const Color surfaceColor = Colors.white;

  static const Color textPrimaryColor = Color(0xFF10213D);
  static const Color textSecondaryColor = Color(0xFF42526B);

  static const Color outlineColor = Color(0xFFDCE4EE);
  static const Color innerOutlineColor = Color(0xFFE4EAF2);

  static const Color imagePreviewBackgroundColor = Color(0xFFF4F6F9);

  static const Color formulaBackgroundColor = Color(0xFFF5F8FC);

  static const Color tableBackgroundColor = Colors.white;

  static const Color tableAlternatingRowColor = Color(0xFFF8FAFD);

  static const Color tableLabelBackgroundColor = Color(0xFFEAF2FF);

  static const Color tableBorderColor = Color(0xFFCAD7E7);

  static const Color brailleBackgroundColor = Color(0xFFF5F8FC);

  static const Color shadowColor = Color(0x10000000);

  static const Color successColor = Color(0xFF1FAE5B);

  static const Color successBackgroundColor = Color(0xFFF5FCF8);

  static const Color successIconBackgroundColor = Color(0xFFE3F6EA);

  static const Color successOutlineColor = Color(0xFFCFE9D9);

  // ============================================================
  // FONT FALLBACKS
  // ============================================================

  static const List<String> recognizedContentFontFallback = <String>[
    'Roboto',
    'Noto Sans',
    'sans-serif',
  ];

  static const List<String> brailleFontFallback = <String>[
    'Noto Sans Symbols 2',
    'Noto Sans Symbols',
    'Noto Sans',
    'Roboto',
    'sans-serif',
  ];

  // ============================================================
  // ENTRANCE ANIMATION
  // ============================================================

  static const Duration entranceAnimationDuration = Duration(milliseconds: 540);

  static const Duration entranceAnimationDelay = Duration(milliseconds: 100);

  static const Duration entranceSequenceDuration = Duration(milliseconds: 640);

  static const Curve entranceCurve = Interval(
    0.15625,
    1,
    curve: Curves.easeOutCubic,
  );

  static const Offset entranceBeginOffset = Offset(0, 0.025);

  // ============================================================
  // INTEGRATED BLUE HEADER
  // ============================================================

  static const LinearGradient headerGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: <Color>[Color(0xFF1474F5), Color(0xFF0758DD)],
  );

  static const double headerHorizontalPadding = 14;
  static const double headerTopPadding = 12;
  static const double headerBottomPadding = 27;

  static const double headerIconSize = 25;
  static const double headerBackSpacing = 5;
  static const double headerDescriptionSpacing = 15;
  static const double headerDescriptionWidth = 275;

  static const EdgeInsets headerDescriptionPadding = EdgeInsets.symmetric(
    horizontal: 5,
  );

  static const BorderRadius headerRadius = BorderRadius.only(
    bottomLeft: Radius.elliptical(190, 34),
    bottomRight: Radius.elliptical(190, 34),
  );

  static const double headerDecorationRight = 18;
  static const double headerDecorationBottom = 20;
  static const double headerDecorationOpacity = 0.18;
  static const double headerDecorationWidth = 49;
  static const double headerDotSize = 4;
  static const double headerDotSpacing = 7;
  static const int headerDotCount = 12;

  static const IconData backIcon = Icons.arrow_back_rounded;

  static const IconData newScanIcon = Icons.center_focus_strong_rounded;

  static final ButtonStyle backButtonStyle = IconButton.styleFrom(
    foregroundColor: surfaceColor,
    backgroundColor: const Color(0x26FFFFFF),
    shape: const CircleBorder(),
  );

  static const TextStyle appBarTitleStyle = TextStyle(
    fontSize: 21,
    height: 1.2,
    fontWeight: FontWeight.w800,
    letterSpacing: -0.25,
    color: surfaceColor,
  );

  static const TextStyle headerDescriptionStyle = TextStyle(
    color: Color(0xFFE9F2FF),
    fontSize: 13.5,
    height: 1.4,
    fontWeight: FontWeight.w500,
  );

  static final ButtonStyle headerActionStyle = TextButton.styleFrom(
    foregroundColor: surfaceColor,
    backgroundColor: const Color(0x1FFFFFFF),
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.all(Radius.circular(12)),
    ),
    textStyle: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700),
  );

  // ============================================================
  // SCREEN LAYOUT
  // ============================================================

  static const EdgeInsets screenPadding = EdgeInsets.fromLTRB(16, 18, 16, 28);

  static const double zero = 0;
  static const double sectionSpacing = 16;
  static const double bottomSpacing = 12;
  static const double itemSpacing = 12;
  static const double compactSpacing = 4;
  static const double sectionHeaderSpacing = 14;
  static const double unifiedBlockSpacing = 14;

  // ============================================================
  // SHARED CONTAINERS
  // ============================================================

  static const BorderRadius cardRadius = BorderRadius.all(Radius.circular(18));

  static const BorderRadius innerCardRadius = BorderRadius.all(
    Radius.circular(14),
  );

  static const Border cardBorder = Border.fromBorderSide(
    BorderSide(color: outlineColor, width: 1),
  );

  static const Border innerCardBorder = Border.fromBorderSide(
    BorderSide(color: innerOutlineColor, width: 1),
  );

  static const List<BoxShadow> cardShadow = <BoxShadow>[
    BoxShadow(color: shadowColor, blurRadius: 12, offset: Offset(0, 3)),
  ];

  // ============================================================
  // SUCCESS BANNER
  // ============================================================

  static const EdgeInsets successBannerPadding = EdgeInsets.all(14);

  static const Border successBorder = Border.fromBorderSide(
    BorderSide(color: successOutlineColor, width: 1),
  );

  static const double successIconContainerSize = 48;
  static const double successDocumentIconSize = 27;
  static const double successCheckIconSize = 34;

  static const IconData successDocumentIcon = Icons.document_scanner_outlined;

  static const IconData successCheckIcon = Icons.check_circle_rounded;

  static const TextStyle successTitleStyle = TextStyle(
    fontFamily: 'Poppins',
    fontSize: 16,
    fontWeight: FontWeight.w600,
    color: textPrimaryColor,
  );

  static const TextStyle successDescriptionStyle = TextStyle(
    fontFamily: 'Poppins',
    fontSize: 13,
    fontWeight: FontWeight.w400,
    color: textPrimaryColor,
  );

  // ============================================================
  // NUMBERED SECTIONS
  // ============================================================

  static const EdgeInsets sectionCardPadding = EdgeInsets.all(14);

  static const double sectionNumberSize = 30;

  static const TextStyle sectionNumberStyle = TextStyle(
    fontFamily: 'Poppins',
    fontSize: 14,
    fontWeight: FontWeight.w600,
    color: surfaceColor,
  );

  static const TextStyle sectionTitleStyle = TextStyle(
    fontFamily: 'Poppins',
    fontSize: 16,
    fontWeight: FontWeight.w600,
    color: textPrimaryColor,
  );

  // ============================================================
  // SECTION ACTIONS
  // ============================================================

  static const IconData copyIcon = Icons.copy_rounded;

  static const double actionIconSize = 21;

  static final ButtonStyle sectionActionStyle = TextButton.styleFrom(
    foregroundColor: primaryColor,
    backgroundColor: primaryColor.withValues(alpha: 0.10),
    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
    textStyle: const TextStyle(
      fontFamily: 'Poppins',
      fontSize: 13,
      fontWeight: FontWeight.w700,
    ),
  );

  // ============================================================
  // SCANNED IMAGE
  // ============================================================

  static const double imageLoadingHeight = 230;
  static const double maximumImagePreviewHeight = 300;
  static const BoxFit imagePreviewFit = BoxFit.contain;

  static const BorderRadius imagePreviewRadius = BorderRadius.all(
    Radius.circular(14),
  );

  static const IconData imageErrorIcon = Icons.broken_image_outlined;

  static const double imageErrorIconSize = 42;

  // ============================================================
  // RECOGNIZED CONTENT
  // ============================================================

  static const EdgeInsets contentPreviewPadding = EdgeInsets.all(16);

  static const EdgeInsets formulaPreviewPadding = EdgeInsets.symmetric(
    horizontal: 14,
    vertical: 10,
  );

  static const BorderRadius formulaRadius = BorderRadius.all(
    Radius.circular(10),
  );

  static const TextStyle recognizedContentStyle = TextStyle(
    fontFamily: 'Poppins',
    fontFamilyFallback: recognizedContentFontFallback,
    fontSize: 14,
    height: 1.65,
    fontWeight: FontWeight.w400,
    color: textPrimaryColor,
  );

  static const TextStyle formulaContentStyle = TextStyle(
    fontFamily: 'Poppins',
    fontFamilyFallback: recognizedContentFontFallback,
    fontSize: 17,
    height: 1.6,
    fontWeight: FontWeight.w500,
    color: textPrimaryColor,
  );

  // Table preview
  static const double tableMinimumColumnWidth = 82;
  static const double tableBorderWidth = 1;

  static const EdgeInsets tableCellPadding = EdgeInsets.symmetric(
    horizontal: 12,
    vertical: 14,
  );

  static const BorderRadius tableRadius = BorderRadius.all(Radius.circular(12));

  static const Border tableOuterBorder = Border.fromBorderSide(
    BorderSide(color: tableBorderColor, width: tableBorderWidth),
  );

  static const TextStyle tableCellTextStyle = TextStyle(
    fontFamily: 'Poppins',
    fontFamilyFallback: recognizedContentFontFallback,
    color: textPrimaryColor,
    fontSize: 14,
    fontWeight: FontWeight.w500,
  );

  static const TextStyle tableLabelTextStyle = TextStyle(
    fontFamily: 'Poppins',
    fontFamilyFallback: recognizedContentFontFallback,
    color: primaryColor,
    fontSize: 14,
    fontWeight: FontWeight.w700,
  );

  // ============================================================
  // BRAILLE OUTPUT
  // ============================================================

  static const EdgeInsets braillePreviewPadding = EdgeInsets.symmetric(
    horizontal: 18,
    vertical: 20,
  );

  static const TextStyle brailleContentStyle = TextStyle(
    fontFamily: 'Noto Sans Symbols 2',
    fontFamilyFallback: brailleFontFallback,
    fontSize: 23,
    height: 1.7,
    fontWeight: FontWeight.w400,
    color: textPrimaryColor,
  );

  static const IconData brailleUnavailableIcon = Icons.translate_rounded;

  static const double brailleUnavailableIconSize = 44;

  // ============================================================
  // EMPTY RESULT
  // ============================================================

  static const EdgeInsets emptyResultPadding = EdgeInsets.all(20);

  static const IconData emptyResultIcon = Icons.find_in_page_outlined;

  static const double emptyResultIconSize = 46;

  static const TextStyle emptyResultTitleStyle = TextStyle(
    fontFamily: 'Poppins',
    fontSize: 16,
    fontWeight: FontWeight.w600,
    color: textPrimaryColor,
  );

  static const TextStyle emptyResultDescriptionStyle = TextStyle(
    fontFamily: 'Poppins',
    fontSize: 13,
    height: 1.5,
    fontWeight: FontWeight.w400,
    color: textSecondaryColor,
  );

  // ============================================================
  // SAVE TO MATERIALS
  // ============================================================

  static const double saveButtonHeight = 54;

  static const BorderRadius saveButtonRadius = BorderRadius.all(
    Radius.circular(14),
  );

  static const IconData saveMaterialIcon = Icons.library_add_outlined;

  static const IconData savedMaterialIcon = Icons.check_circle_outline_rounded;

  static const double saveMaterialIconSize = 22;

  static const double saveProgressIndicatorSize = 22;

  static const double saveProgressIndicatorStrokeWidth = 2.5;

  static const int maximumMaterialTitleLength = 150;

  static const int maximumMaterialSubjectLength = 100;

  static const int maximumMaterialDescriptionLength = 500;

  static const EdgeInsets saveButtonPadding = EdgeInsets.symmetric(
    horizontal: 18,
    vertical: 12,
  );

  // Save dialog animation
  static const Color saveDialogBarrierColor = Color(0x73000000);

  static const Duration saveDialogAnimationDuration = Duration(
    milliseconds: 320,
  );

  static const Curve saveDialogEntranceCurve = Curves.easeOutCubic;

  static const Curve saveDialogExitCurve = Curves.easeInCubic;

  static const double saveDialogInitialScale = 0.94;

  static const Offset saveDialogInitialOffset = Offset(0, 0.035);

  static const EdgeInsets saveDialogContentPadding = EdgeInsets.fromLTRB(
    24,
    8,
    24,
    16,
  );

  static const EdgeInsets saveDialogActionsPadding = EdgeInsets.fromLTRB(
    16,
    0,
    16,
    12,
  );

  static const BorderRadius saveDialogRadius = BorderRadius.all(
    Radius.circular(18),
  );

  static const double saveDialogFieldSpacing = 14;

  static const TextStyle saveButtonTextStyle = TextStyle(
    fontFamily: 'Poppins',
    fontSize: 15,
    fontWeight: FontWeight.w600,
  );

  static const TextStyle saveDialogTitleStyle = TextStyle(
    fontFamily: 'Poppins',
    fontSize: 18,
    fontWeight: FontWeight.w600,
    color: textPrimaryColor,
  );

  static const TextStyle saveDialogDescriptionStyle = TextStyle(
    fontFamily: 'Poppins',
    fontSize: 13,
    height: 1.5,
    fontWeight: FontWeight.w400,
    color: textSecondaryColor,
  );

  static const TextStyle saveInputTextStyle = TextStyle(
    fontFamily: 'Poppins',
    fontSize: 14,
    fontWeight: FontWeight.w400,
    color: textPrimaryColor,
  );

  static final ButtonStyle saveMaterialButtonStyle = FilledButton.styleFrom(
    minimumSize: const Size(double.infinity, saveButtonHeight),
    backgroundColor: primaryColor,
    foregroundColor: surfaceColor,
    disabledBackgroundColor: outlineColor,
    disabledForegroundColor: textSecondaryColor,
    padding: saveButtonPadding,
    shape: const RoundedRectangleBorder(borderRadius: saveButtonRadius),
    textStyle: saveButtonTextStyle,
  );

  static final ButtonStyle saveDialogCancelStyle = TextButton.styleFrom(
    foregroundColor: textSecondaryColor,
    textStyle: const TextStyle(
      fontFamily: 'Poppins',
      fontSize: 13,
      fontWeight: FontWeight.w600,
    ),
  );

  static final ButtonStyle saveDialogConfirmStyle = FilledButton.styleFrom(
    backgroundColor: primaryColor,
    foregroundColor: surfaceColor,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.all(Radius.circular(10)),
    ),
    textStyle: const TextStyle(
      fontFamily: 'Poppins',
      fontSize: 13,
      fontWeight: FontWeight.w600,
    ),
  );

  static const InputDecoration saveTitleInputDecoration = InputDecoration(
    filled: true,
    fillColor: surfaceColor,
    border: OutlineInputBorder(
      borderRadius: BorderRadius.all(Radius.circular(12)),
      borderSide: BorderSide(color: outlineColor),
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.all(Radius.circular(12)),
      borderSide: BorderSide(color: outlineColor),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.all(Radius.circular(12)),
      borderSide: BorderSide(color: primaryColor, width: 1.5),
    ),
  );

  static const InputDecoration saveSubjectInputDecoration = InputDecoration(
    filled: true,
    fillColor: surfaceColor,
    border: OutlineInputBorder(
      borderRadius: BorderRadius.all(Radius.circular(12)),
      borderSide: BorderSide(color: outlineColor),
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.all(Radius.circular(12)),
      borderSide: BorderSide(color: outlineColor),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.all(Radius.circular(12)),
      borderSide: BorderSide(color: primaryColor, width: 1.5),
    ),
  );

  static const InputDecoration saveDescriptionInputDecoration = InputDecoration(
    alignLabelWithHint: true,
    filled: true,
    fillColor: surfaceColor,
    border: OutlineInputBorder(
      borderRadius: BorderRadius.all(Radius.circular(12)),
      borderSide: BorderSide(color: outlineColor),
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.all(Radius.circular(12)),
      borderSide: BorderSide(color: outlineColor),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.all(Radius.circular(12)),
      borderSide: BorderSide(color: primaryColor, width: 1.5),
    ),
  );

  // ============================================================
  // SNACKBAR
  // ============================================================

  static const Duration snackBarDuration = Duration(seconds: 2);

  static const SnackBarBehavior snackBarBehavior = SnackBarBehavior.floating;

  static const Color snackBarBackgroundColor = primaryColor;

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
}
