import 'package:flutter/material.dart';

abstract final class HistoryScreenStyles {
  // ============================================================
  // COLORS
  // ============================================================

  static const Color primaryColor = Color(0xFF0D47A1);
  static const Color backgroundColor = Color(0xFFFFFFFF);
  static const Color surfaceColor = Color(0xFFFFFFFF);

  static const Color textPrimaryColor = Color(0xFF111827);
  static const Color textSecondaryColor = Color(0xFF667085);
  static const Color textMutedColor = Color(0xFF98A2B3);

  static const Color outlineColor = Color(0xFFDCE4EE);
  static const Color softBackgroundColor = Color(0xFFF5F8FC);
  static const Color selectedBackgroundColor = Color(0xFFEAF1FB);
  static const Color shadowColor = Color(0x10000000);
  static const Color destructiveColor = Color(0xFFB42318);

  // ============================================================
  // SCREEN LAYOUT
  // ============================================================

  static const EdgeInsets screenPadding = EdgeInsets.fromLTRB(16, 18, 16, 28);

  static const double sectionSpacing = 18;
  static const double itemSpacing = 12;
  static const double compactSpacing = 6;
  static const double toolbarBottomSpacing = 4;
  static const double zero = 0;

  // ============================================================
  // HEADER
  // ============================================================

  static const String screenTitle = 'History';

  static const String screenDescription =
      'View your previous scans and results';

  static const String clearAllLabel = 'Clear All';

  static const String clearAllTooltip = 'Delete all scan history';

  static const IconData historyIcon = Icons.history_rounded;

  static const IconData clearAllIcon = Icons.delete_outline_rounded;

  static const IconData backButtonIcon = Icons.arrow_back_rounded;

  static const String backButtonTooltip = 'Go back';

  static const double headerIconSize = 30;
  static const double clearAllIconSize = 21;
  static const double backButtonIconSize = 27;

  static const TextStyle titleStyle = TextStyle(
    fontFamily: 'Poppins',
    fontSize: 25,
    fontWeight: FontWeight.w700,
    color: textPrimaryColor,
  );

  static const TextStyle descriptionStyle = TextStyle(
    fontFamily: 'Poppins',
    fontSize: 13,
    height: 1.4,
    fontWeight: FontWeight.w400,
    color: textSecondaryColor,
  );

  static final ButtonStyle clearAllButtonStyle = TextButton.styleFrom(
    foregroundColor: primaryColor,
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
    textStyle: const TextStyle(
      fontFamily: 'Poppins',
      fontSize: 13,
      fontWeight: FontWeight.w600,
    ),
  );

  static const Size headerSize = Size.fromHeight(100);

  static const EdgeInsets headerPadding = EdgeInsets.symmetric(
    horizontal: 20,
    vertical: 12,
  );

  // ============================================================
  // FILTERS
  // ============================================================

  static const String allFilterLabel = 'All';

  static const String contentFilterLabel = 'Text & Equation';

  static const String brailleFilterLabel = 'Braille Output';

  static const IconData allFilterIcon = Icons.description_outlined;

  static const IconData contentFilterIcon = Icons.text_fields_rounded;

  static const IconData brailleFilterIcon = Icons.translate_rounded;

  static const double filterHeight = 46;
  static const double filterIconSize = 20;
  static const double filterSpacing = 10;

  static const EdgeInsets filterPadding = EdgeInsets.symmetric(
    horizontal: 16,
    vertical: 10,
  );

  static const BorderRadius filterRadius = BorderRadius.all(
    Radius.circular(14),
  );

  static const TextStyle selectedFilterTextStyle = TextStyle(
    fontFamily: 'Poppins',
    fontSize: 13,
    fontWeight: FontWeight.w600,
    color: surfaceColor,
  );

  static const TextStyle unselectedFilterTextStyle = TextStyle(
    fontFamily: 'Poppins',
    fontSize: 13,
    fontWeight: FontWeight.w500,
    color: textSecondaryColor,
  );

  // ============================================================
  // SEARCH
  // ============================================================

  static const String searchHint = 'Search your scans...';

  static const String searchTooltip = 'Search scan history';

  static const IconData searchIcon = Icons.search_rounded;

  static const IconData clearSearchIcon = Icons.close_rounded;

  static const double searchHeight = 52;
  static const double searchIconSize = 24;

  static const BorderRadius searchRadius = BorderRadius.all(
    Radius.circular(14),
  );

  static const TextStyle searchTextStyle = TextStyle(
    fontFamily: 'Poppins',
    fontSize: 14,
    fontWeight: FontWeight.w400,
    color: textPrimaryColor,
  );

  static const TextStyle searchHintStyle = TextStyle(
    fontFamily: 'Poppins',
    fontSize: 14,
    fontWeight: FontWeight.w400,
    color: textMutedColor,
  );

  static const InputDecoration searchDecoration = InputDecoration(
    hintText: searchHint,
    hintStyle: searchHintStyle,
    prefixIcon: Icon(
      searchIcon,
      color: textSecondaryColor,
      size: searchIconSize,
    ),
    filled: true,
    fillColor: surfaceColor,
    contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 14),
    border: OutlineInputBorder(
      borderRadius: searchRadius,
      borderSide: BorderSide(color: outlineColor),
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: searchRadius,
      borderSide: BorderSide(color: outlineColor),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: searchRadius,
      borderSide: BorderSide(color: primaryColor, width: 1.5),
    ),
  );

  // ============================================================
  // HISTORY CARD
  // ============================================================

  static const EdgeInsets cardPadding = EdgeInsets.all(14);

  static const BorderRadius cardRadius = BorderRadius.all(Radius.circular(17));

  static const Border cardBorder = Border.fromBorderSide(
    BorderSide(color: outlineColor, width: 1),
  );

  static const List<BoxShadow> cardShadow = <BoxShadow>[
    BoxShadow(color: shadowColor, blurRadius: 12, offset: Offset(0, 3)),
  ];

  static const double cardSpacing = 12;

  static const double previewWidth = 102;
  static const double previewHeight = 112;

  static const EdgeInsets previewPadding = EdgeInsets.all(10);

  static const BorderRadius previewRadius = BorderRadius.all(
    Radius.circular(12),
  );

  static const TextStyle previewTextStyle = TextStyle(
    fontFamily: 'Poppins',
    fontSize: 10,
    height: 1.45,
    fontWeight: FontWeight.w400,
    color: textPrimaryColor,
  );

  static const TextStyle previewBrailleStyle = TextStyle(
    fontFamily: 'Noto Sans Symbols 2',
    fontFamilyFallback: <String>[
      'Noto Sans Symbols',
      'Noto Sans',
      'Roboto',
      'sans-serif',
    ],
    fontSize: 14,
    height: 1.5,
    fontWeight: FontWeight.w400,
    color: textPrimaryColor,
  );

  static const int previewMaximumLines = 6;

  static const TextStyle cardTitleStyle = TextStyle(
    fontFamily: 'Poppins',
    fontSize: 15,
    fontWeight: FontWeight.w600,
    color: textPrimaryColor,
  );

  static const TextStyle cardDescriptionStyle = TextStyle(
    fontFamily: 'Poppins',
    fontSize: 13,
    height: 1.45,
    fontWeight: FontWeight.w400,
    color: textSecondaryColor,
  );

  static const int cardTitleMaximumLines = 2;
  static const int cardDescriptionMaximumLines = 2;

  // ============================================================
  // TYPE BADGE
  // ============================================================

  static const String contentBadgeLabel = 'Text & Equation';

  static const String brailleBadgeLabel = 'Braille Output';

  static const EdgeInsets badgePadding = EdgeInsets.symmetric(
    horizontal: 10,
    vertical: 5,
  );

  static const BorderRadius badgeRadius = BorderRadius.all(Radius.circular(10));

  static const TextStyle badgeTextStyle = TextStyle(
    fontFamily: 'Poppins',
    fontSize: 11,
    fontWeight: FontWeight.w600,
    color: primaryColor,
  );

  // ============================================================
  // CARD METADATA
  // ============================================================

  static const IconData calendarIcon = Icons.calendar_today_outlined;

  static const IconData timeIcon = Icons.schedule_rounded;

  static const double metadataIconSize = 15;
  static const double metadataSpacing = 5;

  static const String metadataSeparator = '•';

  static const TextStyle metadataTextStyle = TextStyle(
    fontFamily: 'Poppins',
    fontSize: 11,
    fontWeight: FontWeight.w400,
    color: textMutedColor,
  );

  // ============================================================
  // CARD ACTIONS
  // ============================================================

  static const String viewLabel = 'View';

  static const String viewTooltip = 'View saved scan';

  static const String renameLabel = 'Rename';

  static const String deleteLabel = 'Delete';

  static const String moreActionsTooltip = 'More history actions';

  static const IconData viewIcon = Icons.visibility_outlined;

  static const IconData moreActionsIcon = Icons.more_vert_rounded;

  static const IconData renameIcon = Icons.edit_outlined;

  static const IconData deleteIcon = Icons.delete_outline_rounded;

  static const double actionIconSize = 20;
  static const double moreActionIconSize = 22;

  static final ButtonStyle viewButtonStyle = TextButton.styleFrom(
    foregroundColor: primaryColor,
    backgroundColor: selectedBackgroundColor,
    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.all(Radius.circular(11)),
    ),
    textStyle: const TextStyle(
      fontFamily: 'Poppins',
      fontSize: 12,
      fontWeight: FontWeight.w600,
    ),
  );

  // ============================================================
  // LOADING, EMPTY, AND ERROR STATES
  // ============================================================

  static const String loadingLabel = 'Loading your scan history...';

  static const String emptyTitle = 'No scan history yet';

  static const String emptyDescription =
      'Your successful scans will appear here.';

  static const String emptySearchTitle = 'No matching scans';

  static const String emptySearchDescription =
      'Try another search word or filter.';

  static const String errorTitle = 'Unable to load history';

  static const String retryLabel = 'Try Again';

  static const IconData emptyIcon = Icons.history_toggle_off_rounded;

  static const IconData emptySearchIcon = Icons.search_off_rounded;

  static const IconData errorIcon = Icons.cloud_off_outlined;

  static const double stateIconSize = 58;

  static const EdgeInsets statePadding = EdgeInsets.symmetric(
    horizontal: 28,
    vertical: 56,
  );

  static const TextStyle stateTitleStyle = TextStyle(
    fontFamily: 'Poppins',
    fontSize: 17,
    fontWeight: FontWeight.w600,
    color: textPrimaryColor,
  );

  static const TextStyle stateDescriptionStyle = TextStyle(
    fontFamily: 'Poppins',
    fontSize: 13,
    height: 1.5,
    fontWeight: FontWeight.w400,
    color: textSecondaryColor,
  );

  static final ButtonStyle retryButtonStyle = FilledButton.styleFrom(
    backgroundColor: primaryColor,
    foregroundColor: surfaceColor,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.all(Radius.circular(12)),
    ),
    textStyle: const TextStyle(
      fontFamily: 'Poppins',
      fontSize: 13,
      fontWeight: FontWeight.w600,
    ),
  );

  // ============================================================
  // VIEW DETAILS
  // ============================================================

  static const String recognizedContentTitle = 'Recognized Content';

  static const String brailleContentTitle = 'Braille Output';

  static const String noBrailleContent =
      'No Braille output was saved for this scan.';

  static const String closeLabel = 'Close';

  static const BorderRadius detailSheetRadius = BorderRadius.vertical(
    top: Radius.circular(24),
  );

  static const EdgeInsets detailSheetPadding = EdgeInsets.fromLTRB(
    20,
    18,
    20,
    28,
  );

  static const TextStyle detailTitleStyle = TextStyle(
    fontFamily: 'Poppins',
    fontSize: 19,
    fontWeight: FontWeight.w600,
    color: textPrimaryColor,
  );

  static const TextStyle detailSectionTitleStyle = TextStyle(
    fontFamily: 'Poppins',
    fontSize: 14,
    fontWeight: FontWeight.w600,
    color: primaryColor,
  );

  static const TextStyle detailContentStyle = TextStyle(
    fontFamily: 'Poppins',
    fontSize: 13,
    height: 1.6,
    fontWeight: FontWeight.w400,
    color: textPrimaryColor,
  );

  static const TextStyle detailBrailleStyle = TextStyle(
    fontFamily: 'Noto Sans Symbols 2',
    fontFamilyFallback: <String>[
      'Noto Sans Symbols',
      'Noto Sans',
      'Roboto',
      'sans-serif',
    ],
    fontSize: 21,
    height: 1.7,
    fontWeight: FontWeight.w400,
    color: textPrimaryColor,
  );

  // ============================================================
  // DIALOGS
  // ============================================================

  static const String renameDialogTitle = 'Rename Scan';

  static const String renameFieldLabel = 'Title';

  static const String cancelLabel = 'Cancel';

  static const String saveLabel = 'Save';

  static const String deleteDialogTitle = 'Delete Scan?';

  static const String deleteDialogDescription =
      'This scan will be permanently removed from your history.';

  static const String clearDialogTitle = 'Clear All History?';

  static const String clearDialogDescription =
      'All saved scan-history records will be permanently deleted.';

  static const String confirmDeleteLabel = 'Delete';

  static const String confirmClearLabel = 'Clear All';

  static const String renameSuccessMessage = 'History title updated.';

  static const String deleteSuccessMessage = 'Scan removed from history.';

  static const String clearSuccessMessage = 'Scan history cleared.';

  static const BorderRadius dialogRadius = BorderRadius.all(
    Radius.circular(18),
  );

  static const TextStyle dialogTitleStyle = TextStyle(
    fontFamily: 'Poppins',
    fontSize: 18,
    fontWeight: FontWeight.w600,
    color: textPrimaryColor,
  );

  static const TextStyle dialogDescriptionStyle = TextStyle(
    fontFamily: 'Poppins',
    fontSize: 13,
    height: 1.5,
    fontWeight: FontWeight.w400,
    color: textSecondaryColor,
  );

  // ============================================================
  // SNACKBAR
  // ============================================================

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

  static const String historyListSemanticLabel = 'Saved scan history';

  static const String refreshSemanticLabel = 'Refresh scan history';
}
