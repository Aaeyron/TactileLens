import 'package:flutter/material.dart';

abstract final class HistoryScreenStyles {
  // ============================================================
  // COLORS
  // ============================================================

  static const Color primaryColor = Color(0xFF1268F3);
  static const Color primaryDarkColor = Color(0xFF0758DD);

  static const Color backgroundColor = Color(0xFFF4F7FC);
  static const Color surfaceColor = Colors.white;

  static const Color textPrimaryColor = Color(0xFF10213D);
  static const Color textSecondaryColor = Color(0xFF42526B);
  static const Color textMutedColor = Color(0xFF728096);

  static const Color outlineColor = Color(0xFFDDE5F0);
  static const Color filterBackgroundColor = surfaceColor;
  static const Color cardBackgroundColor = surfaceColor;
  static const Color previewBackgroundColor = Color(0xFFF2F6FC);

  // ============================================================
  // ICONS
  // ============================================================

  static const IconData historyIcon = Icons.history_rounded;
  static const IconData searchIcon = Icons.search_rounded;
  static const IconData clearSearchIcon = Icons.close_rounded;
  static const IconData sortIcon = Icons.tune_rounded;

  static const IconData moreActionsIcon = Icons.more_vert_rounded;
  static const IconData favoriteIcon = Icons.star_border_rounded;

  static const IconData renameIcon = Icons.edit_outlined;
  static const IconData deleteIcon = Icons.delete_outline_rounded;

  static const IconData emptyIcon = Icons.history_toggle_off_rounded;
  static const IconData emptySearchIcon = Icons.search_off_rounded;
  static const IconData errorIcon = Icons.cloud_off_outlined;

  static const double moreActionIconSize = 22;

  // ============================================================
  // LAYOUT
  // ============================================================

  static const double zero = 0;

  static const EdgeInsets contentPadding = EdgeInsets.fromLTRB(14, 14, 14, 30);

  static const double filterTopSpacing = 13;
  static const double sectionSpacing = 18;
  static const double bottomSpacing = 28;

  static const double sortSpacing = 2;
  static const double filterSpacing = 9;

  static const double groupSpacing = 18;
  static const double groupTitleSpacing = 9;

  // Kept for compatibility with existing code.
  static const EdgeInsets screenPadding = contentPadding;

  // ============================================================
  // FULL-WIDTH HEADER
  // ============================================================

  static const LinearGradient headerGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: <Color>[Color(0xFF1474F5), Color(0xFF0758DD)],
  );

  static const double headerHorizontalPadding = 15;
  static const double headerTopPadding = 20;
  static const double headerBottomPadding = 17;

  static const EdgeInsets headerContainerPadding = EdgeInsets.zero;

  static const BorderRadius headerContainerRadius = BorderRadius.only(
    bottomLeft: Radius.circular(28),
    bottomRight: Radius.circular(28),
  );

  static const Border headerContainerBorder = Border();

  static const double headerDescriptionSpacing = 7;
  static const double headerDescriptionWidth = 245;

  static const double headerDecorationRight = 2;
  static const double headerDecorationTop = 28;
  static const double headerDecorationOpacity = 0.18;
  static const double headerDecorationWidth = 47;
  static const double headerDotSize = 4;
  static const double headerDotSpacing = 7;
  static const int headerDotCount = 12;

  // ============================================================
  // SEARCH
  // ============================================================

  static const double searchTopSpacing = 16;
  static const double searchHeight = 48;
  static const double searchSuffixIconSize = 21;

  static const BorderRadius searchRadius = BorderRadius.all(
    Radius.circular(13),
  );

  static const TextStyle searchTextStyle = TextStyle(
    color: textPrimaryColor,
    fontSize: 13.5,
  );

  static const InputDecoration searchDecoration = InputDecoration(
    hintStyle: TextStyle(color: textMutedColor, fontSize: 13.5),
    prefixIcon: Icon(searchIcon, color: textMutedColor, size: 21),
    filled: true,
    fillColor: surfaceColor,
    contentPadding: EdgeInsets.symmetric(horizontal: 13, vertical: 12),
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

  static const double filterHeight = 38;

  static const EdgeInsets filterPadding = EdgeInsets.symmetric(horizontal: 18);

  static const BorderRadius filterRadius = BorderRadius.all(
    Radius.circular(10),
  );

  // ============================================================
  // HISTORY GROUPS AND CARDS
  // ============================================================

  static const double cardSpacing = 8;
  static const double cardContentSpacing = 12;

  static const EdgeInsets cardPadding = EdgeInsets.fromLTRB(7, 8, 3, 8);

  static const BorderRadius cardRadius = BorderRadius.all(Radius.circular(12));

  static const Border cardBorder = Border.fromBorderSide(
    BorderSide(color: outlineColor, width: 1),
  );

  static const List<BoxShadow> cardShadow = <BoxShadow>[
    BoxShadow(color: Color(0x0D102A43), blurRadius: 10, offset: Offset(0, 4)),
  ];

  static const double previewWidth = 68;
  static const double previewHeight = 94;

  static const EdgeInsets previewPadding = EdgeInsets.all(7);

  static const BorderRadius previewRadius = BorderRadius.all(
    Radius.circular(7),
  );

  static const Border previewBorder = Border.fromBorderSide(
    BorderSide(color: outlineColor, width: 0.8),
  );

  static const int previewMaximumLines = 7;
  static const int contentMaximumLines = 2;
  static const int brailleMaximumLines = 1;

  static const double cardMetadataSpacing = 4;
  static const double cardDateSpacing = 4;
  static const double braillePreviewSpacing = 8;
  static const double trailingIconSize = 22;

  // Existing compatibility constants.
  static const double brailleLabelSpacing = 3;

  static const EdgeInsets badgePadding = EdgeInsets.symmetric(
    horizontal: 8,
    vertical: 3,
  );

  static const BorderRadius badgeRadius = BorderRadius.all(Radius.circular(10));

  // ============================================================
  // STATES
  // ============================================================

  static const double stateIconSize = 52;

  static const EdgeInsets statePadding = EdgeInsets.symmetric(
    horizontal: 28,
    vertical: 56,
  );

  // ============================================================
  // DETAILS
  // ============================================================

  static const BorderRadius detailSheetRadius = BorderRadius.vertical(
    top: Radius.circular(24),
  );

  static const EdgeInsets detailSheetPadding = EdgeInsets.fromLTRB(
    20,
    18,
    20,
    28,
  );

  // ============================================================
  // DIALOGS AND SNACKBAR
  // ============================================================

  static const BorderRadius dialogRadius = BorderRadius.all(
    Radius.circular(18),
  );

  static const Duration snackBarDuration = Duration(seconds: 2);

  static const SnackBarBehavior snackBarBehavior = SnackBarBehavior.floating;

  static const EdgeInsets snackBarMargin = EdgeInsets.all(16);

  static const BorderRadius snackBarRadius = BorderRadius.all(
    Radius.circular(12),
  );

  static final ButtonStyle retryButtonStyle = FilledButton.styleFrom(
    backgroundColor: primaryColor,
    foregroundColor: surfaceColor,
  );

  // ============================================================
  // TYPOGRAPHY
  // ============================================================

  static const TextStyle headerTitleStyle = TextStyle(
    color: surfaceColor,
    fontSize: 25,
    height: 1.15,
    fontWeight: FontWeight.w800,
    letterSpacing: -0.35,
  );

  static const TextStyle headerDescriptionStyle = TextStyle(
    color: Color(0xFFE9F2FF),
    fontSize: 13.5,
    height: 1.42,
    fontWeight: FontWeight.w500,
  );

  static const TextStyle titleStyle = TextStyle(
    color: textPrimaryColor,
    fontSize: 23,
    fontWeight: FontWeight.w800,
  );

  static const TextStyle selectedFilterTextStyle = TextStyle(
    color: surfaceColor,
    fontSize: 12,
    fontWeight: FontWeight.w700,
  );

  static const TextStyle unselectedFilterTextStyle = TextStyle(
    color: textPrimaryColor,
    fontSize: 12,
    fontWeight: FontWeight.w600,
  );

  static const TextStyle groupTitleStyle = TextStyle(
    color: textPrimaryColor,
    fontSize: 14,
    fontWeight: FontWeight.w700,
  );

  static const TextStyle previewTextStyle = TextStyle(
    color: textPrimaryColor,
    fontSize: 7.5,
    height: 1.3,
  );

  static const TextStyle badgeTextStyle = TextStyle(
    color: surfaceColor,
    fontSize: 9,
    fontWeight: FontWeight.w600,
  );

  static const TextStyle cardTitleStyle = TextStyle(
    color: textPrimaryColor,
    fontSize: 13.5,
    height: 1.2,
    fontWeight: FontWeight.w700,
  );

  static const TextStyle cardMetadataStyle = TextStyle(
    color: textSecondaryColor,
    fontSize: 11,
    height: 1.2,
    fontWeight: FontWeight.w500,
  );

  static const TextStyle cardDateStyle = TextStyle(
    color: textMutedColor,
    fontSize: 10.5,
    height: 1.2,
    fontWeight: FontWeight.w500,
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
    fontSize: 16,
    height: 1.25,
    letterSpacing: 1.3,
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
