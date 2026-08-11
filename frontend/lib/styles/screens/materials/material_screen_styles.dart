import 'package:flutter/material.dart';

abstract final class MaterialScreenStyles {
  // ============================================================
  // COLORS
  // ============================================================

  static const Color primaryColor = Color(0xFF0D47A1);
  static const Color backgroundColor = Color(0xFFF8F9FC);
  static const Color surfaceColor = Colors.white;
  static const Color textPrimaryColor = Color(0xFF111827);
  static const Color textSecondaryColor = Color(0xFF667085);
  static const Color textMutedColor = Color(0xFF98A2B3);
  static const Color outlineColor = Color(0xFFE2E8F0);
  static const Color selectedBackgroundColor = Color(0xFFEFF4FF);
  static const Color summaryBackgroundColor = Color(0xFFF4F7FF);
  static const Color destructiveColor = Color(0xFFD92D20);
  static const Color shadowColor = Color(0x0D000000);

  // ============================================================
  // HEADER
  // ============================================================

  static const Size headerSize = Size.fromHeight(100);

  static const EdgeInsets headerPadding = EdgeInsets.symmetric(
    horizontal: 20,
    vertical: 12,
  );

  static const String pageTitle = 'Materials';

  static const TextStyle pageTitleStyle = TextStyle(
    fontFamily: 'Poppins',
    fontSize: 21,
    fontWeight: FontWeight.w600,
    color: textPrimaryColor,
  );

  // ============================================================
  // TEXT
  // ============================================================

  static const String pageDescription =
      'Manage your saved scans and uploaded learning materials.';

  static const String searchHint = 'Search your materials...';

  static const String allFilterLabel = 'All';
  static const String scannedFilterLabel = 'Scanned';
  static const String uploadedFilterLabel = 'Uploaded';

  static const String newestSortLabel = 'Newest first';
  static const String oldestSortLabel = 'Oldest first';
  static const String titleSortLabel = 'Title A–Z';

  static const String totalMaterialsLabel = 'Total';
  static const String scannedMaterialsLabel = 'Scanned';
  static const String uploadedMaterialsLabel = 'Uploaded';

  static const String loadingLabel = 'Loading your materials...';

  static const String errorTitle = 'Unable to load materials';

  static const String errorDescription = 'Check your connection and try again.';

  static const String emptySearchTitle = 'No matching materials';

  static const String emptySearchDescription =
      'Try another search term or filter.';

  static const String retryLabel = 'Try Again';

  static const String deleteDialogTitle = 'Delete Material';

  static const String deleteDialogDescription =
      'Are you sure you want to permanently delete this material?';

  static const String cancelLabel = 'Cancel';
  static const String deleteLabel = 'Delete';

  static const String deleteSuccessMessage = 'Material deleted successfully.';

  static const String deleteFailureMessage = 'Unable to delete the material.';

  static const String clearSearchTooltip = 'Clear material search';

  static const String sortTooltip = 'Sort materials';

  // ============================================================
  // ICONS
  // ============================================================

  static const IconData searchIcon = Icons.search_rounded;
  static const IconData clearSearchIcon = Icons.close_rounded;
  static const IconData allFilterIcon = Icons.folder_copy_outlined;
  static const IconData scannedFilterIcon = Icons.document_scanner_outlined;
  static const IconData uploadedFilterIcon = Icons.upload_file_outlined;
  static const IconData sortIcon = Icons.sort_rounded;
  static const IconData errorIcon = Icons.cloud_off_outlined;
  static const IconData emptySearchIcon = Icons.search_off_rounded;

  // ============================================================
  // LAYOUT
  // ============================================================

  static const EdgeInsets contentPadding = EdgeInsets.fromLTRB(16, 18, 16, 28);

  static const double sectionSpacing = 18;
  static const double itemSpacing = 12;
  static const double compactSpacing = 8;
  static const double filterSpacing = 10;
  static const double cardSpacing = 14;
  static const double zero = 0;

  // ============================================================
  // DESCRIPTION TOOLBAR
  // ============================================================

  static const TextStyle pageDescriptionStyle = TextStyle(
    fontFamily: 'Poppins',
    fontSize: 13,
    height: 1.45,
    fontWeight: FontWeight.w400,
    color: textSecondaryColor,
  );

  // ============================================================
  // SUMMARY
  // ============================================================

  static const EdgeInsets summaryPadding = EdgeInsets.symmetric(
    horizontal: 14,
    vertical: 14,
  );

  static const BorderRadius summaryRadius = BorderRadius.all(
    Radius.circular(16),
  );

  static const Border summaryBorder = Border.fromBorderSide(
    BorderSide(color: outlineColor),
  );

  static const TextStyle summaryValueStyle = TextStyle(
    fontFamily: 'Poppins',
    fontSize: 18,
    fontWeight: FontWeight.w700,
    color: primaryColor,
  );

  static const TextStyle summaryLabelStyle = TextStyle(
    fontFamily: 'Poppins',
    fontSize: 11,
    fontWeight: FontWeight.w500,
    color: textSecondaryColor,
  );

  static const Color summaryDividerColor = outlineColor;
  static const double summaryDividerHeight = 34;

  // ============================================================
  // SEARCH
  // ============================================================

  static const double searchHeight = 52;

  static const BorderRadius searchRadius = BorderRadius.all(
    Radius.circular(14),
  );

  static const TextStyle searchTextStyle = TextStyle(
    fontFamily: 'Poppins',
    fontSize: 14,
    fontWeight: FontWeight.w400,
    color: textPrimaryColor,
  );

  static const InputDecoration searchDecoration = InputDecoration(
    hintText: searchHint,
    hintStyle: TextStyle(
      fontFamily: 'Poppins',
      fontSize: 14,
      color: textMutedColor,
    ),
    prefixIcon: Icon(searchIcon, color: textSecondaryColor),
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
  // FILTERS
  // ============================================================

  static const double filterHeight = 44;
  static const double filterIconSize = 19;

  static const EdgeInsets filterPadding = EdgeInsets.symmetric(horizontal: 16);

  static const BorderRadius filterRadius = BorderRadius.all(
    Radius.circular(22),
  );

  static const TextStyle selectedFilterTextStyle = TextStyle(
    fontFamily: 'Poppins',
    fontSize: 13,
    fontWeight: FontWeight.w600,
    color: surfaceColor,
  );

  static const TextStyle filterTextStyle = TextStyle(
    fontFamily: 'Poppins',
    fontSize: 13,
    fontWeight: FontWeight.w500,
    color: textSecondaryColor,
  );

  // ============================================================
  // SORT
  // ============================================================

  static const double sortIconSize = 22;

  static const BorderRadius sortButtonRadius = BorderRadius.all(
    Radius.circular(12),
  );

  static final ButtonStyle sortButtonStyle = IconButton.styleFrom(
    foregroundColor: primaryColor,
    backgroundColor: selectedBackgroundColor,
    shape: const RoundedRectangleBorder(borderRadius: sortButtonRadius),
  );

  // ============================================================
  // STATES
  // ============================================================

  static const EdgeInsets statePadding = EdgeInsets.symmetric(
    horizontal: 24,
    vertical: 56,
  );

  static const double stateIconSize = 52;

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
    color: textSecondaryColor,
  );

  static final ButtonStyle retryButtonStyle = FilledButton.styleFrom(
    backgroundColor: primaryColor,
    foregroundColor: surfaceColor,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.all(Radius.circular(12)),
    ),
  );

  // ============================================================
  // DIALOG
  // ============================================================

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
    color: textSecondaryColor,
  );

  static final ButtonStyle deleteButtonStyle = FilledButton.styleFrom(
    backgroundColor: destructiveColor,
    foregroundColor: surfaceColor,
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
}
