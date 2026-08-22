import 'package:flutter/material.dart';

abstract final class MaterialScreenStyles {
  // Text

  static const String pageTitle = 'Materials';

  static const String pageDescription =
      'View, manage, and organize your saved learning materials in one place.';

  static const String backTooltip = 'Go back to the previous screen';

  static const String searchHint = 'Search materials...';

  static const String allFilterLabel = 'All';
  static const String pdfFilterLabel = 'PDF';
  static const String imageFilterLabel = 'Image';
  static const String documentFilterLabel = 'Document';

  static const String newestSortLabel = 'Newest first';

  static const String oldestSortLabel = 'Oldest first';

  static const String titleSortLabel = 'Title A–Z';

  static const String materialsSectionTitle = 'Your Materials';

  static const String materialCountSingular = 'material';

  static const String materialCountPlural = 'materials';

  static const String loadingLabel = 'Loading your materials...';

  static const String errorTitle = 'Unable to load materials';

  static const String errorDescription = 'Check your connection and try again.';

  static const String emptySearchTitle = 'No matching materials';

  static const String emptySearchDescription =
      'Try another search term or file type.';

  static const String retryLabel = 'Try Again';

  static const String deleteDialogTitle = 'Delete Material';

  static const String deleteDialogDescription =
      'Are you sure you want to permanently delete this material? This action cannot be undone.';

  static const String cancelLabel = 'Cancel';
  static const String deleteLabel = 'Delete';

  static const String deleteSuccessMessage = 'Material deleted successfully.';

  static const String deleteFailureMessage = 'Unable to delete the material.';

  static const String clearSearchTooltip = 'Clear material search';

  static const String sortTooltip = 'Sort materials';

  static const String pdfType = 'pdf';
  static const String imageType = 'image';
  static const String jpgType = 'jpg';
  static const String jpegType = 'jpeg';
  static const String pngType = 'png';

  // Colors
  static const Color backgroundColor = Colors.white;
  static const Color surfaceColor = Colors.white;

  static const Color primaryColor = Color(0xFF0D47A1);

  static const Color primaryBrightColor = Color(0xFF1268F3);

  static const Color textPrimaryColor = Color(0xFF07143D);

  static const Color textSecondaryColor = Color(0xFF53658F);

  static const Color textMutedColor = Color(0xFF8291B1);

  static const Color outlineColor = Color(0xFFBCD0EA);

  static const Color dividerColor = Color(0xFFDCE6F3);

  static const Color softBlueColor = Color(0xFFEDF4FF);

  // Icons

  static const IconData heroIcon = Icons.folder_rounded;

  static const IconData backIcon = Icons.arrow_back_rounded;

  static const IconData searchIcon = Icons.search_rounded;

  static const IconData clearSearchIcon = Icons.close_rounded;

  static const IconData allFilterIcon = Icons.folder_copy_outlined;

  static const IconData pdfFilterIcon = Icons.picture_as_pdf_outlined;

  static const IconData imageFilterIcon = Icons.image_outlined;

  static const IconData documentFilterIcon = Icons.description_outlined;

  static const IconData sortIcon = Icons.tune_rounded;

  static const IconData errorIcon = Icons.cloud_off_outlined;

  static const IconData emptySearchIcon = Icons.search_off_rounded;

  static const IconData deleteIcon = Icons.delete_outline_rounded;

  // General layout
  static const double zero = 0;

  static const EdgeInsets contentPadding = EdgeInsets.fromLTRB(20, 20, 20, 28);

  static const double searchTopSpacing = 28;
  static const double filterTopSpacing = 18;
  static const double sectionSpacing = 28;
  static const double materialsHeaderSpacing = 14;
  static const double uploadTopSpacing = 24;
  static const double bottomSpacing = 24;
  static const double itemSpacing = 14;
  static const double compactSpacing = 8;
  static const double filterSpacing = 10;
  static const double cardSpacing = 14;

  // Page introduction
  static const double heroContentSpacing = 18;

  static const double heroIconContainerSize = 112;
  static const double heroIconSize = 70;

  static const BorderRadius heroIconRadius = BorderRadius.all(
    Radius.circular(26),
  );

  static const double backIconSize = 25;
  static const double backTitleSpacing = 8;
  static const double pageDescriptionSpacing = 14;

  // Shared containers
  static const double cardBorderWidth = 1.2;

  static const BorderRadius cardRadius = BorderRadius.all(Radius.circular(20));

  static const Border cardBorder = Border.fromBorderSide(
    BorderSide(color: outlineColor, width: cardBorderWidth),
  );

  static const List<BoxShadow> cardShadow = <BoxShadow>[
    BoxShadow(
      color: Color(0x180D47A1),
      blurRadius: 18,
      spreadRadius: 1,
      offset: Offset(0, 6),
    ),
  ];

  static const Border smallContainerBorder = Border.fromBorderSide(
    BorderSide(color: outlineColor, width: 1),
  );

  static const List<BoxShadow> smallContainerShadow = <BoxShadow>[
    BoxShadow(color: Color(0x100D47A1), blurRadius: 10, offset: Offset(0, 3)),
  ];

  // Search
  static const double searchHeight = 64;

  static const BorderRadius searchRadius = BorderRadius.all(
    Radius.circular(20),
  );

  static const double searchDividerWidth = 1;
  static const double searchDividerIndent = 14;

  static const List<BoxShadow> searchShadow = <BoxShadow>[
    BoxShadow(color: Color(0x180D47A1), blurRadius: 18, offset: Offset(0, 6)),
  ];

  static const TextStyle searchTextStyle = TextStyle(
    fontSize: 15,
    fontWeight: FontWeight.w400,
    color: textPrimaryColor,
  );

  static const InputDecoration searchDecoration = InputDecoration(
    hintText: searchHint,
    hintStyle: TextStyle(fontSize: 15, color: textMutedColor),
    prefixIcon: Icon(searchIcon, color: textSecondaryColor),
    filled: true,
    fillColor: Colors.transparent,
    contentPadding: EdgeInsets.symmetric(horizontal: 18, vertical: 17),
    border: InputBorder.none,
    enabledBorder: InputBorder.none,
    focusedBorder: InputBorder.none,
  );

  // Filters
  static const double filterHeight = 48;
  static const double filterIconSize = 20;
  static const double filterBorderWidth = 1.2;

  static const EdgeInsets filterPadding = EdgeInsets.symmetric(horizontal: 18);

  static const BorderRadius filterRadius = BorderRadius.all(
    Radius.circular(24),
  );

  static const List<BoxShadow> filterShadow = <BoxShadow>[
    BoxShadow(color: Color(0x100D47A1), blurRadius: 10, offset: Offset(0, 3)),
  ];

  // Sort
  static const double sortIconSize = 24;

  static final ButtonStyle sortButtonStyle = IconButton.styleFrom(
    foregroundColor: primaryBrightColor,
    backgroundColor: surfaceColor,
    minimumSize: const Size(54, 54),
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.all(Radius.circular(16)),
    ),
  );

  // States
  static const EdgeInsets statePadding = EdgeInsets.symmetric(
    horizontal: 24,
    vertical: 48,
  );

  static const BorderRadius stateCardRadius = BorderRadius.all(
    Radius.circular(20),
  );

  static const double stateIconSize = 52;

  // Dialog
  static const BorderRadius dialogRadius = BorderRadius.all(
    Radius.circular(20),
  );

  static const double dialogButtonIconSize = 19;

  // Snackbar
  static const Duration snackBarDuration = Duration(seconds: 2);

  static const SnackBarBehavior snackBarBehavior = SnackBarBehavior.floating;

  static const EdgeInsets snackBarMargin = EdgeInsets.all(16);

  static const BorderRadius snackBarRadius = BorderRadius.all(
    Radius.circular(14),
  );


  static const TextStyle pageTitleStyle = TextStyle(
    fontSize: 34,
    height: 1.1,
    fontWeight: FontWeight.w800,
    letterSpacing: -0.8,
    color: textPrimaryColor,
  );

  static const TextStyle pageDescriptionStyle = TextStyle(
    fontSize: 16,
    height: 1.5,
    fontWeight: FontWeight.w400,
    color: textSecondaryColor,
  );

  static const TextStyle sectionTitleStyle = TextStyle(
    fontSize: 20,
    fontWeight: FontWeight.w800,
    color: textPrimaryColor,
  );

  static const TextStyle countTextStyle = TextStyle(
    fontSize: 13,
    fontWeight: FontWeight.w600,
    color: textMutedColor,
  );

  static const TextStyle selectedFilterTextStyle = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w700,
    color: surfaceColor,
  );

  static const TextStyle filterTextStyle = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w600,
    color: textPrimaryColor,
  );

  static const TextStyle stateTitleStyle = TextStyle(
    fontSize: 17,
    fontWeight: FontWeight.w700,
    color: textPrimaryColor,
  );

  static const TextStyle stateDescriptionStyle = TextStyle(
    fontSize: 13,
    height: 1.5,
    color: textSecondaryColor,
  );

  static const TextStyle dialogTitleStyle = TextStyle(
    fontSize: 18,
    fontWeight: FontWeight.w700,
    color: textPrimaryColor,
  );

  static const TextStyle dialogDescriptionStyle = TextStyle(
    fontSize: 14,
    height: 1.5,
    color: textSecondaryColor,
  );

  static const TextStyle snackBarTextStyle = TextStyle(
    fontSize: 13,
    fontWeight: FontWeight.w500,
    color: surfaceColor,
  );

  // Buttons
  static final ButtonStyle backButtonStyle = IconButton.styleFrom(
    foregroundColor: primaryColor,
    backgroundColor: surfaceColor,
    side: const BorderSide(color: outlineColor, width: 1),
    shape: const CircleBorder(),
  );

  static final ButtonStyle retryButtonStyle = FilledButton.styleFrom(
    backgroundColor: primaryColor,
    foregroundColor: surfaceColor,
    elevation: 0,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.all(Radius.circular(14)),
    ),
  );

  static final ButtonStyle dialogCancelButtonStyle = TextButton.styleFrom(
    foregroundColor: primaryColor,
  );

  static final ButtonStyle deleteButtonStyle = FilledButton.styleFrom(
    backgroundColor: primaryColor,
    foregroundColor: surfaceColor,
    elevation: 0,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.all(Radius.circular(12)),
    ),
  );
}
