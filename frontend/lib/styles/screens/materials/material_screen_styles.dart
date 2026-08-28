import 'package:flutter/material.dart';

abstract final class MaterialScreenStyles {
  // ============================================================
  // COLORS
  // ============================================================

  static const Color backgroundColor = Color(0xFFF4F7FC);
  static const Color surfaceColor = Colors.white;

  static const Color primaryColor = Color(0xFF1268F3);
  static const Color primaryBrightColor = Color(0xFF1268F3);
  static const Color primaryDarkColor = Color(0xFF0758DD);

  static const Color textPrimaryColor = Color(0xFF10213D);
  static const Color textSecondaryColor = Color(0xFF42526B);
  static const Color textMutedColor = Color(0xFF728096);

  static const Color outlineColor = Color(0xFFDDE5F0);
  static const Color strongOutlineColor = Color(0xFFC6D2E1);

  static const Color filterBackgroundColor = Colors.white;
  static const Color recentCardBackgroundColor = Colors.white;
  static const Color thumbnailBackgroundColor = Color(0xFFF2F6FC);

  static const Color blueFolderBackgroundColor = Colors.white;
  static const Color blueFolderOutlineColor = outlineColor;

  static const Color folderColor = primaryColor;
  static const Color folderSelectedColor = primaryDarkColor;

  static const Color folderIconBackgroundColor = Color(0xFFEDF4FF);
  static const Color addFolderOutlineColor = Color(0xFFAAC8F8);
  static const Color selectedFolderBackgroundColor = Color(0xFFEAF3FF);

  // ============================================================
  // ICONS
  // ============================================================

  static const IconData searchIcon = Icons.search_rounded;
  static const IconData clearSearchIcon = Icons.close_rounded;
  static const IconData sortIcon = Icons.tune_rounded;

  static const IconData folderIcon = Icons.folder_rounded;
  static const IconData addFolderIcon = Icons.create_new_folder_outlined;

  static const IconData imageIcon = Icons.image_outlined;
  static const IconData documentIcon = Icons.description_outlined;

  static const IconData moreIcon = Icons.more_vert_rounded;
  static const IconData previewIcon = Icons.visibility_outlined;
  static const IconData deleteIcon = Icons.delete_outline_rounded;

  static const IconData errorIcon = Icons.cloud_off_outlined;
  static const IconData emptySearchIcon = Icons.search_off_rounded;

  static const IconData moveToFolderIcon = Icons.folder_open_rounded;
  static const IconData unfiledIcon = Icons.folder_off_outlined;
  static const IconData selectedFolderIcon = Icons.check_circle_rounded;

  // ============================================================
  // GENERAL
  // ============================================================

  static const int maximumFolderNameLength = 80;

  static const EdgeInsets contentPadding = EdgeInsets.fromLTRB(14, 18, 14, 30);

  static const double sectionSpacing = 24;
  static const double sectionContentSpacing = 9;
  static const double bottomSpacing = 26;

  // ============================================================
  // ANIMATION
  // ============================================================

  static const Duration entranceAnimationDuration = Duration(milliseconds: 520);

  static const Duration entranceAnimationDelay = Duration(milliseconds: 120);

  static const Curve entranceAnimationCurve = Curves.easeOutCubic;

  static const double entranceFadeBegin = 0;
  static const double entranceFadeEnd = 1;

  static const Offset entranceSlideBegin = Offset(0, 0.025);

  // ============================================================
  // FULL-WIDTH HEADER
  // ============================================================

  static const LinearGradient pageHeaderGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: <Color>[Color(0xFF1474F5), Color(0xFF0758DD)],
  );

  static const EdgeInsets pageHeaderPadding = EdgeInsets.zero;

  static const double headerHorizontalPadding = 15;
  static const double headerTopPadding = 20;
  static const double headerBottomPadding = 17;

  static const BorderRadius pageHeaderRadius = BorderRadius.only(
    bottomLeft: Radius.circular(28),
    bottomRight: Radius.circular(28),
  );

  static const Border pageHeaderBorder = Border();
  static const List<BoxShadow> pageHeaderShadow = <BoxShadow>[];

  static const Color pageHeaderBackgroundColor = primaryColor;

  static const double pageDescriptionSpacing = 7;
  static const double pageDescriptionWidth = 250;

  static const double headerDecorationRight = 2;
  static const double headerDecorationTop = 25;
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
  static const double sortButtonSpacing = 0;

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
      borderRadius: BorderRadius.all(Radius.circular(13)),
      borderSide: BorderSide(color: outlineColor),
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.all(Radius.circular(13)),
      borderSide: BorderSide(color: outlineColor),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.all(Radius.circular(13)),
      borderSide: BorderSide(color: primaryColor, width: 1.5),
    ),
  );

  // ============================================================
  // FILTERS — RETAINED FOR EXISTING LOGIC
  // ============================================================

  static const double filterTopSpacing = 12;
  static const double filterHeight = 38;
  static const double filterSpacing = 10;

  static const EdgeInsets filterPadding = EdgeInsets.symmetric(horizontal: 20);

  static const BorderRadius filterRadius = BorderRadius.all(Radius.circular(8));

  // ============================================================
  // FOLDERS
  // ============================================================

  static const double folderSectionContentSpacing = 9;

  static const BorderRadius folderSectionRadius = BorderRadius.all(
    Radius.circular(14),
  );

  static const double addFolderButtonSize = 34;
  static const double addFolderButtonIconSize = 25;

  static const double emptyFolderHeight = 76;

  static const double folderCardHeight = 112;
  static const double folderCardWidth = 94;
  static const double folderSpacing = 8;

  static const double folderIconContainerSize = 42;
  static const double folderIconSize = 29;
  static const double folderIconSpacing = 8;
  static const double folderCountSpacing = 5;

  static const EdgeInsets folderPadding = EdgeInsets.symmetric(
    horizontal: 8,
    vertical: 10,
  );

  static const BorderRadius folderRadius = BorderRadius.all(
    Radius.circular(12),
  );

  static const BorderRadius folderIconContainerRadius = BorderRadius.all(
    Radius.circular(10),
  );

  static const List<BoxShadow> folderCardShadow = <BoxShadow>[
    BoxShadow(color: Color(0x0D102A43), blurRadius: 10, offset: Offset(0, 4)),
  ];

  static const Color warmFolderBackgroundColor = surfaceColor;
  static const Color warmFolderOutlineColor = outlineColor;
  static const Color warmFolderColor = primaryColor;

  static const Color purpleFolderBackgroundColor = surfaceColor;
  static const Color purpleFolderOutlineColor = outlineColor;
  static const Color purpleFolderColor = primaryColor;

  static const Duration folderSelectionDuration = Duration(milliseconds: 220);

  static const double addFolderOutlineWidth = 1.2;
  static const double addFolderCardIconSize = 37;
  static const double addFolderLabelSpacing = 10;
  static const double addFolderProgressSize = 27;

  // ============================================================
  // MATERIAL CARDS
  // ============================================================

  static const double materialCardHeight = 91;
  static const double materialCardSpacing = 8;
  static const double materialContentSpacing = 11;

  static const double thumbnailWidth = 66;
  static const double thumbnailHeight = 73;
  static const double thumbnailIconSize = 27;

  static const BoxFit thumbnailImageFit = BoxFit.cover;
  static const FilterQuality thumbnailFilterQuality = FilterQuality.medium;

  static const Border thumbnailBorder = Border.fromBorderSide(
    BorderSide(color: outlineColor, width: 0.8),
  );

  static const double categorySpacing = 4;
  static const double metadataSpacing = 4;

  static const EdgeInsets materialCardPadding = EdgeInsets.fromLTRB(7, 8, 4, 8);

  static const BorderRadius materialCardRadius = BorderRadius.all(
    Radius.circular(12),
  );

  static const BorderRadius thumbnailRadius = BorderRadius.all(
    Radius.circular(7),
  );

  static const BorderRadius categoryRadius = BorderRadius.all(
    Radius.circular(10),
  );

  static const Border cardBorder = Border.fromBorderSide(
    BorderSide(color: outlineColor, width: 1),
  );

  static const double materialMenuButtonSize = 38;
  static const double materialMenuIconSize = 22;

  static const EdgeInsets materialMenuPadding = EdgeInsets.zero;

  static const BoxConstraints materialMenuConstraints = BoxConstraints.tightFor(
    width: materialMenuButtonSize,
    height: materialMenuButtonSize,
  );

  // ============================================================
  // STATES AND DIALOGS
  // ============================================================

  static const EdgeInsets statePadding = EdgeInsets.symmetric(
    horizontal: 24,
    vertical: 42,
  );

  static const double stateIconSize = 45;

  static const BorderRadius stateRadius = BorderRadius.all(Radius.circular(14));

  static const BorderRadius dialogRadius = BorderRadius.all(
    Radius.circular(18),
  );

  static const Color dialogBarrierColor = Color(0x73000000);

  static const Duration dialogAnimationDuration = Duration(milliseconds: 280);

  static const Curve dialogEntranceCurve = Curves.easeOutBack;
  static const Curve dialogExitCurve = Curves.easeInCubic;

  static const double dialogInitialScale = 0.90;
  static const double dialogButtonIconSize = 18;

  static const InputDecoration folderNameDecoration = InputDecoration(
    prefixIcon: Icon(folderIcon, color: primaryColor),
    filled: true,
    fillColor: Color(0xFFF8FAFC),
    counterStyle: TextStyle(color: textMutedColor, fontSize: 11),
    border: OutlineInputBorder(
      borderRadius: BorderRadius.all(Radius.circular(10)),
      borderSide: BorderSide(color: outlineColor),
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.all(Radius.circular(10)),
      borderSide: BorderSide(color: outlineColor),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.all(Radius.circular(10)),
      borderSide: BorderSide(color: primaryColor, width: 1.5),
    ),
  );

  static const double folderPickerMaximumHeight = 320;
  static const double folderPickerDescriptionSpacing = 16;
  static const double folderPickerOptionSpacing = 8;
  static const double folderPickerIconSpacing = 12;

  static const EdgeInsets folderPickerOptionPadding = EdgeInsets.symmetric(
    horizontal: 14,
    vertical: 12,
  );

  static const BorderRadius folderPickerOptionRadius = BorderRadius.all(
    Radius.circular(12),
  );

  static const Color folderPickerBackgroundColor = Color(0xFFF8FAFC);
  static const Color folderPickerSelectedColor = Color(0xFFEAF3FF);

  // ============================================================
  // SNACKBAR
  // ============================================================

  static const Duration snackBarDuration = Duration(seconds: 2);

  // ============================================================
  // BUTTONS
  // ============================================================

  static final ButtonStyle viewAllButtonStyle = TextButton.styleFrom(
    foregroundColor: primaryColor,
    padding: const EdgeInsets.symmetric(horizontal: 4),
    textStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
  );

  static final ButtonStyle sectionActionButtonStyle = TextButton.styleFrom(
    foregroundColor: primaryColor,
    disabledForegroundColor: primaryColor,
    padding: const EdgeInsets.symmetric(horizontal: 4),
    textStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
  );

  static final ButtonStyle deleteButtonStyle = FilledButton.styleFrom(
    backgroundColor: primaryColor,
    foregroundColor: surfaceColor,
  );

  static final ButtonStyle createFolderButtonStyle = FilledButton.styleFrom(
    backgroundColor: primaryColor,
    foregroundColor: surfaceColor,
    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
  );

  // ============================================================
  // TYPOGRAPHY
  // ============================================================

  static const TextStyle pageTitleStyle = TextStyle(
    color: surfaceColor,
    fontSize: 25,
    height: 1.15,
    fontWeight: FontWeight.w800,
    letterSpacing: -0.35,
  );

  static const TextStyle pageDescriptionStyle = TextStyle(
    color: Color(0xFFE9F2FF),
    fontSize: 13.5,
    height: 1.42,
    fontWeight: FontWeight.w500,
  );

  static const TextStyle sectionTitleStyle = TextStyle(
    color: textPrimaryColor,
    fontSize: 16,
    height: 1.2,
    fontWeight: FontWeight.w800,
    letterSpacing: -0.15,
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
    color: textPrimaryColor,
    fontSize: 12,
    height: 1.2,
    fontWeight: FontWeight.w700,
  );

  static const TextStyle folderCountStyle = TextStyle(
    color: textSecondaryColor,
    fontSize: 10.5,
    height: 1.2,
    fontWeight: FontWeight.w500,
  );

  static const TextStyle addFolderTextStyle = TextStyle(
    color: textPrimaryColor,
    fontSize: 11.5,
    height: 1.2,
    fontWeight: FontWeight.w600,
  );

  static const TextStyle materialTitleStyle = TextStyle(
    color: textPrimaryColor,
    fontSize: 13.5,
    fontWeight: FontWeight.w700,
  );

  static const TextStyle materialCategoryStyle = TextStyle(
    color: textSecondaryColor,
    fontSize: 11,
    height: 1.2,
    fontWeight: FontWeight.w500,
  );

  static const TextStyle metadataStyle = TextStyle(
    color: textMutedColor,
    fontSize: 10.5,
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

  static const TextStyle emptyFolderStyle = TextStyle(
    color: textMutedColor,
    fontSize: 12,
    fontWeight: FontWeight.w500,
  );

  static const TextStyle folderPickerTitleStyle = TextStyle(
    color: textPrimaryColor,
    fontSize: 14,
    fontWeight: FontWeight.w700,
  );

  static const TextStyle folderPickerDescriptionStyle = TextStyle(
    color: textMutedColor,
    fontSize: 11,
    height: 1.35,
  );
}
