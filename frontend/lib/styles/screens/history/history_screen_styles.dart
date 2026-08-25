import 'package:flutter/material.dart';

abstract final class HistoryScreenStyles {
  // Text
  static const String screenTitle = 'History';
  static const String searchHint = 'Search History';

  static const String allFilterLabel = 'All';
  static const String textFilterLabel = 'Text';
  static const String mathFilterLabel = 'Math';
  static const String uebFilterLabel = 'UEB';
  static const String nemethFilterLabel = 'Nemeth';

  static const String todayLabel = 'Today';
  static const String yesterdayLabel = 'Yesterday';

  static const String mathBadgeLabel = 'Math Equation';
  static const String textBadgeLabel = 'Printed Text';

  static const String nemethLabel = 'Nemeth';
  static const String uebLabel = 'UEB';

  static const String brailleTranslationLabel = 'Braille Translation';

  static const String notAvailableLabel = 'not available';

  static const String emptyRecognizedContent =
      'No recognized content was saved.';

  static const String newestLabel = 'Newest first';
  static const String oldestLabel = 'Oldest first';
  static const String titleSortLabel = 'Title A–Z';

  static const String searchTooltip = 'Search scan history';
  static const String clearSearchTooltip = 'Clear history search';
  static const String sortTooltip = 'Sort scan history';

  static const String loadingLabel = 'Loading your scan history...';

  static const String emptyTitle = 'No scan history yet';
  static const String emptyDescription =
      'Your successful scans will appear here.';

  static const String emptySearchTitle = 'No matching scans';
  static const String emptySearchDescription =
      'Try another search word or filter.';

  static const String errorTitle = 'Unable to load history';
  static const String retryLabel = 'Try Again';

  static const String recognizedContentTitle = 'Recognized Content';

  static const String brailleContentTitle = 'Braille Output';

  static const String noBrailleContent =
      'No Braille output was saved for this scan.';

  static const String closeLabel = 'Close';

  static const String renameLabel = 'Rename';
  static const String deleteLabel = 'Delete';

  static const String moreActionsTooltip = 'More history actions';

  static const String favoriteTooltip = 'Add to favorites';

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

  static const String historyListSemanticLabel = 'Saved scan history';

  // Colors
  static const Color primaryColor = Color(0xFF164EAD);
  static const Color backgroundColor = Colors.white;
  static const Color surfaceColor = Colors.white;

  static const Color textPrimaryColor = Color(0xFF1D2939);
  static const Color textSecondaryColor = Color(0xFF475467);
  static const Color textMutedColor = Color(0xFF98A2B3);

  static const Color outlineColor = Color(0xFFBFC9D6);
  static const Color filterBackgroundColor = Color(0xFFF2F4F7);
  static const Color cardBackgroundColor = Color(0xFFF5F9FF);
  static const Color previewBackgroundColor = Color(0xFFEEF2F7);

  // Icons
  static const IconData historyIcon = Icons.history_rounded;
  static const IconData searchIcon = Icons.search_rounded;
  static const IconData clearSearchIcon = Icons.close_rounded;
  static const IconData sortIcon = Icons.tune_rounded;

  static const IconData moreActionsIcon =
    Icons.more_vert_rounded;

  static const double moreActionIconSize = 22;

  static const IconData favoriteIcon =
    Icons.star_border_rounded;

  static const IconData renameIcon = Icons.edit_outlined;
  static const IconData deleteIcon = Icons.delete_outline_rounded;

  static const IconData emptyIcon = Icons.history_toggle_off_rounded;

  static const IconData emptySearchIcon = Icons.search_off_rounded;

  static const IconData errorIcon = Icons.cloud_off_outlined;

  // Layout
  static const double zero = 0;

  static const EdgeInsets screenPadding = EdgeInsets.fromLTRB(21, 24, 21, 30);

  static const double searchTopSpacing = 20;
  static const double filterTopSpacing = 13;
  static const double sectionSpacing = 25;
  static const double bottomSpacing = 28;

  static const double sortSpacing = 2;
  static const double filterSpacing = 10;

  static const double groupSpacing = 20;
  static const double groupTitleSpacing = 11;

  // Search
  static const double searchHeight = 44;

  static const BorderRadius searchRadius = BorderRadius.all(Radius.circular(9));

  static const TextStyle searchTextStyle = TextStyle(
    color: textPrimaryColor,
    fontSize: 13,
  );

  static const InputDecoration searchDecoration = InputDecoration(
    hintText: searchHint,
    hintStyle: TextStyle(color: textMutedColor, fontSize: 13),
    prefixIcon: Icon(searchIcon, color: textMutedColor, size: 21),
    filled: true,
    fillColor: surfaceColor,
    contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 11),
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
      borderSide: BorderSide(color: primaryColor, width: 1.4),
    ),
  );

  // Filters
  static const double filterHeight = 38;

  static const EdgeInsets filterPadding = EdgeInsets.symmetric(horizontal: 20);

  static const BorderRadius filterRadius = BorderRadius.all(Radius.circular(8));

  // Cards
  static const double cardSpacing = 14;
  static const double cardContentSpacing = 9;

  static const EdgeInsets cardPadding = EdgeInsets.symmetric(
    horizontal: 8,
    vertical: 10,
  );

  static const BorderRadius cardRadius = BorderRadius.all(Radius.circular(10));

  static const Border cardBorder = Border.fromBorderSide(
    BorderSide(color: outlineColor, width: 1),
  );

  static const double previewWidth = 128;
  static const double previewHeight = 82;

  static const EdgeInsets previewPadding = EdgeInsets.all(9);

  static const BorderRadius previewRadius = BorderRadius.all(
    Radius.circular(5),
  );

  static const int previewMaximumLines = 6;
  static const int contentMaximumLines = 2;
  static const int brailleMaximumLines = 2;

  static const double brailleLabelSpacing = 3;

  // Badge
  static const EdgeInsets badgePadding = EdgeInsets.symmetric(
    horizontal: 8,
    vertical: 3,
  );

  static const BorderRadius badgeRadius = BorderRadius.all(Radius.circular(10));

  // States
  static const double stateIconSize = 52;

  static const EdgeInsets statePadding = EdgeInsets.symmetric(
    horizontal: 28,
    vertical: 56,
  );

  // Details
  static const BorderRadius detailSheetRadius = BorderRadius.vertical(
    top: Radius.circular(24),
  );

  static const EdgeInsets detailSheetPadding = EdgeInsets.fromLTRB(
    20,
    18,
    20,
    28,
  );

  // Dialogs
  static const BorderRadius dialogRadius = BorderRadius.all(
    Radius.circular(18),
  );

  // Snackbar
  static const Duration snackBarDuration = Duration(seconds: 2);

  static const SnackBarBehavior snackBarBehavior = SnackBarBehavior.floating;

  static const EdgeInsets snackBarMargin = EdgeInsets.all(16);

  static const BorderRadius snackBarRadius = BorderRadius.all(
    Radius.circular(12),
  );

  // Buttons
  static final ButtonStyle retryButtonStyle = FilledButton.styleFrom(
    backgroundColor: primaryColor,
    foregroundColor: surfaceColor,
  );

  // Typography
  static const TextStyle titleStyle = TextStyle(
    color: Colors.black,
    fontSize: 23,
    fontWeight: FontWeight.w800,
  );

  static const TextStyle selectedFilterTextStyle = TextStyle(
    color: surfaceColor,
    fontSize: 11,
    fontWeight: FontWeight.w600,
  );

  static const TextStyle unselectedFilterTextStyle = TextStyle(
    color: textPrimaryColor,
    fontSize: 11,
    fontWeight: FontWeight.w500,
  );

  static const TextStyle groupTitleStyle = TextStyle(
    color: textSecondaryColor,
    fontSize: 14,
    fontWeight: FontWeight.w700,
  );

  static const TextStyle previewTextStyle = TextStyle(
    color: textPrimaryColor,
    fontSize: 8,
    height: 1.35,
  );

  static const TextStyle badgeTextStyle = TextStyle(
    color: surfaceColor,
    fontSize: 9,
    fontWeight: FontWeight.w600,
  );

  static const TextStyle contentStyle = TextStyle(
    color: textPrimaryColor,
    fontSize: 13,
    fontWeight: FontWeight.w500,
  );

  static const TextStyle brailleLabelStyle = TextStyle(
    color: textMutedColor,
    fontSize: 10,
  );

  static const TextStyle brailleStyle = TextStyle(
    fontFamily: 'Noto Sans Symbols 2',
    fontFamilyFallback: <String>[
      'Noto Sans Symbols',
      'Noto Sans',
      'Roboto',
      'sans-serif',
    ],
    color: textPrimaryColor,
    fontSize: 11,
    height: 1.25,
  );

  static const TextStyle brailleUnavailableStyle = TextStyle(
    color: textMutedColor,
    fontSize: 10,
  );

  static const TextStyle stateTitleStyle = TextStyle(
    color: textPrimaryColor,
    fontSize: 17,
    fontWeight: FontWeight.w600,
  );

  static const TextStyle stateDescriptionStyle = TextStyle(
    color: textSecondaryColor,
    fontSize: 13,
    height: 1.5,
  );

  static const TextStyle detailTitleStyle = TextStyle(
    color: textPrimaryColor,
    fontSize: 19,
    fontWeight: FontWeight.w600,
  );

  static const TextStyle detailSectionTitleStyle = TextStyle(
    color: primaryColor,
    fontSize: 14,
    fontWeight: FontWeight.w600,
  );

  static const TextStyle detailContentStyle = TextStyle(
    color: textPrimaryColor,
    fontSize: 13,
    height: 1.6,
  );

  static const TextStyle detailBrailleStyle = TextStyle(
    fontFamily: 'Noto Sans Symbols 2',
    fontFamilyFallback: <String>[
      'Noto Sans Symbols',
      'Noto Sans',
      'Roboto',
      'sans-serif',
    ],
    color: textPrimaryColor,
    fontSize: 21,
    height: 1.7,
  );

  static const TextStyle dialogTitleStyle = TextStyle(
    color: textPrimaryColor,
    fontSize: 18,
    fontWeight: FontWeight.w600,
  );

  static const TextStyle dialogDescriptionStyle = TextStyle(
    color: textSecondaryColor,
    fontSize: 13,
    height: 1.5,
  );

  static const TextStyle snackBarTextStyle = TextStyle(
    color: surfaceColor,
    fontSize: 13,
    fontWeight: FontWeight.w500,
  );
}
