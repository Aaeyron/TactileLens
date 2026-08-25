import 'package:flutter/material.dart';

abstract final class MaterialScreenStyles {
  // Text
  static const String pageTitle = 'Materials';

  static const String searchHint = 'Search Materials';

  static const String allFilterLabel = 'All';
  static const String textFilterLabel = 'Text';
  static const String mathFilterLabel = 'Math';
  static const String uebFilterLabel = 'UEB';
  static const String nemethFilterLabel = 'Nemeth';

  static const String foldersTitle = 'Folders';
  static const String recentMaterialsTitle = 'Recent Materials';
  static const String viewAllLabel = 'See all';

  static const String itemSingular = 'Item';
  static const String itemPlural = 'Items';

  static const String mathNemethLabel = 'Math • Nemeth';
  static const String textUebLabel = 'Text • UEB';

  static const String loadingLabel = 'Loading your materials...';

  static const String errorTitle = 'Unable to load materials';
  static const String errorDescription = 'Check your connection and try again.';

  static const String emptySearchTitle = 'No matching materials';
  static const String emptySearchDescription =
      'Try another search term or material type.';

  static const String retryLabel = 'Try Again';

  static const String deleteDialogTitle = 'Delete Material';

  static const String deleteDialogDescription =
      'Are you sure you want to permanently delete this material? '
      'This action cannot be undone.';

  static const String cancelLabel = 'Cancel';
  static const String deleteLabel = 'Delete';
  static const String previewLabel = 'Preview';

  static const String deleteSuccessMessage = 'Material deleted successfully.';

  static const String deleteFailureMessage = 'Unable to delete the material.';

  static const String clearSearchTooltip = 'Clear material search';
  static const String sortTooltip = 'Sort materials';
  static const String materialOptionsTooltip = 'Material options';

  static const String newestSortLabel = 'Newest first';
  static const String oldestSortLabel = 'Oldest first';
  static const String titleSortLabel = 'Title A–Z';

  // Material types
  static const String pdfType = 'pdf';
  static const String imageType = 'image';
  static const String jpgType = 'jpg';
  static const String jpegType = 'jpeg';
  static const String pngType = 'png';

  // Colors
  static const Color backgroundColor = Colors.white;
  static const Color surfaceColor = Colors.white;

  static const Color primaryColor = Color(0xFF164EAD);
  static const Color primaryBrightColor = Color(0xFF1268F3);

  static const Color textPrimaryColor = Color(0xFF1D2433);
  static const Color textSecondaryColor = Color(0xFF475467);
  static const Color textMutedColor = Color(0xFF98A2B3);

  static const Color outlineColor = Color(0xFFD0D5DD);
  static const Color filterBackgroundColor = Color(0xFFF2F4F7);

  static const Color recentCardBackgroundColor = Color(0xFFF7FAFF);
  static const Color thumbnailBackgroundColor = Colors.white;

  static const Color yellowFolderColor = Color(0xFFFFB800);
  static const Color yellowFolderBackgroundColor = Color(0xFFFFF8E7);
  static const Color yellowFolderOutlineColor = Color(0xFFF5DFA8);

  static const Color blueFolderBackgroundColor = Color(0xFFEDF4FF);
  static const Color blueFolderOutlineColor = Color(0xFFBBD4FF);

  // Icons
  static const IconData searchIcon = Icons.search_rounded;
  static const IconData clearSearchIcon = Icons.close_rounded;
  static const IconData sortIcon = Icons.tune_rounded;

  static const IconData folderIcon = Icons.folder_rounded;
  static const IconData imageIcon = Icons.image_outlined;
  static const IconData documentIcon = Icons.description_outlined;

  static const IconData moreIcon = Icons.more_vert_rounded;
  static const IconData previewIcon = Icons.visibility_outlined;
  static const IconData deleteIcon = Icons.delete_outline_rounded;

  static const IconData errorIcon = Icons.cloud_off_outlined;
  static const IconData emptySearchIcon = Icons.search_off_rounded;

  // General
  static const int maximumVisibleFolders = 3;

  static const EdgeInsets contentPadding = EdgeInsets.fromLTRB(16, 24, 16, 30);

  static const double searchTopSpacing = 20;
  static const double filterTopSpacing = 13;
  static const double sectionSpacing = 26;
  static const double sectionContentSpacing = 13;
  static const double bottomSpacing = 24;

  // Search
  static const double searchHeight = 44;
  static const double sortButtonSpacing = 2;

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
      borderRadius: BorderRadius.all(Radius.circular(9)),
      borderSide: BorderSide(color: outlineColor),
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.all(Radius.circular(9)),
      borderSide: BorderSide(color: outlineColor),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.all(Radius.circular(9)),
      borderSide: BorderSide(color: primaryColor, width: 1.4),
    ),
  );

  // Filters
  static const double filterHeight = 38;
  static const double filterSpacing = 10;

  static const EdgeInsets filterPadding = EdgeInsets.symmetric(horizontal: 20);

  static const BorderRadius filterRadius = BorderRadius.all(Radius.circular(8));

  // Folders
  static const double folderCardHeight = 129;
  static const double folderCardWidth = 100;
  static const double folderSpacing = 15;
  static const double folderIconSize = 43;
  static const double folderIconSpacing = 8;
  static const double folderCountSpacing = 5;

  static const EdgeInsets folderPadding = EdgeInsets.symmetric(
    horizontal: 9,
    vertical: 12,
  );

  static const BorderRadius folderRadius = BorderRadius.all(
    Radius.circular(12),
  );

  // Recent material cards
  static const double materialCardSpacing = 11;
  static const double materialContentSpacing = 10;

  static const double thumbnailWidth = 128;
  static const double thumbnailHeight = 68;
  static const double thumbnailIconSize = 32;

  static const double categorySpacing = 5;
  static const double metadataSpacing = 5;

  static const EdgeInsets materialCardPadding = EdgeInsets.symmetric(
    horizontal: 9,
    vertical: 10,
  );

  static const EdgeInsets categoryPadding = EdgeInsets.symmetric(
    horizontal: 7,
    vertical: 3,
  );

  static const BorderRadius materialCardRadius = BorderRadius.all(
    Radius.circular(10),
  );

  static const BorderRadius thumbnailRadius = BorderRadius.all(
    Radius.circular(5),
  );

  static const BorderRadius categoryRadius = BorderRadius.all(
    Radius.circular(10),
  );

  static const Border cardBorder = Border.fromBorderSide(
    BorderSide(color: outlineColor, width: 1),
  );

  // States and dialog
  static const EdgeInsets statePadding = EdgeInsets.symmetric(
    horizontal: 24,
    vertical: 42,
  );

  static const double stateIconSize = 45;

  static const BorderRadius stateRadius = BorderRadius.all(Radius.circular(12));

  static const BorderRadius dialogRadius = BorderRadius.all(
    Radius.circular(18),
  );

  static const double dialogButtonIconSize = 18;

  // Snackbar
  static const Duration snackBarDuration = Duration(seconds: 2);

  // Buttons
  static final ButtonStyle viewAllButtonStyle = TextButton.styleFrom(
    foregroundColor: primaryColor,
    padding: const EdgeInsets.symmetric(horizontal: 4),
    textStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
  );

  static final ButtonStyle deleteButtonStyle = FilledButton.styleFrom(
    backgroundColor: primaryColor,
    foregroundColor: surfaceColor,
  );

  // Typography
  static const TextStyle pageTitleStyle = TextStyle(
    color: Colors.black,
    fontSize: 23,
    fontWeight: FontWeight.w800,
  );

  static const TextStyle sectionTitleStyle = TextStyle(
    color: textSecondaryColor,
    fontSize: 14,
    fontWeight: FontWeight.w700,
  );

  static const TextStyle selectedFilterTextStyle = TextStyle(
    color: surfaceColor,
    fontSize: 11,
    fontWeight: FontWeight.w600,
  );

  static const TextStyle filterTextStyle = TextStyle(
    color: textPrimaryColor,
    fontSize: 11,
    fontWeight: FontWeight.w500,
  );

  static const TextStyle folderTitleStyle = TextStyle(
    color: textSecondaryColor,
    fontSize: 13,
    height: 1.2,
    fontWeight: FontWeight.w700,
  );

  static const TextStyle folderCountStyle = TextStyle(
    color: textSecondaryColor,
    fontSize: 11,
    fontWeight: FontWeight.w400,
  );

  static const TextStyle materialTitleStyle = TextStyle(
    color: textPrimaryColor,
    fontSize: 14,
    fontWeight: FontWeight.w700,
  );

  static const TextStyle categoryStyle = TextStyle(
    color: surfaceColor,
    fontSize: 9,
    fontWeight: FontWeight.w600,
  );

  static const TextStyle metadataStyle = TextStyle(
    color: textMutedColor,
    fontSize: 10,
    fontWeight: FontWeight.w400,
  );

  static const TextStyle stateTitleStyle = TextStyle(
    color: textPrimaryColor,
    fontSize: 16,
    fontWeight: FontWeight.w700,
  );

  static const TextStyle stateDescriptionStyle = TextStyle(
    color: textSecondaryColor,
    fontSize: 13,
    height: 1.4,
  );

  static const TextStyle dialogTitleStyle = TextStyle(
    color: textPrimaryColor,
    fontSize: 18,
    fontWeight: FontWeight.w700,
  );

  static const TextStyle dialogDescriptionStyle = TextStyle(
    color: textSecondaryColor,
    fontSize: 14,
    height: 1.5,
  );
}
