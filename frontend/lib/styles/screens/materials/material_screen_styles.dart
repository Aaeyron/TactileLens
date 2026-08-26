import 'package:flutter/material.dart';

abstract final class MaterialScreenStyles {
  // Colors
  static const Color backgroundColor = Color(0xFFF3F4F6);
  static const Color surfaceColor = Colors.white;

  static const Color primaryColor = Color(0xFF164EAD);
  static const Color primaryBrightColor = Color(0xFF1268F3);

  static const Color textPrimaryColor = Color(0xFF1D2433);
  static const Color textSecondaryColor = Color(0xFF475467);
  static const Color textMutedColor = Color(0xFF98A2B3);

  static const Color outlineColor = Color(0xFFD0D5DD);
  static const Color strongOutlineColor = Color(0xFFB8C2D1);

  static const Color filterBackgroundColor = Colors.white;

  static const Color recentCardBackgroundColor = Colors.white;
  static const Color thumbnailBackgroundColor = Color(0xFFF8FAFC);

  static const Color blueFolderBackgroundColor = Colors.white;
  static const Color blueFolderOutlineColor = Color(0xFFD0D5DD);

  static const Color folderColor = Color(0xFFF5A623);
  static const Color folderSelectedColor = Color(0xFFE89200);

  // Icons
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

  // General
  static const int maximumFolderNameLength = 80;

  static const EdgeInsets contentPadding = EdgeInsets.fromLTRB(16, 24, 16, 30);

  static const double searchTopSpacing = 20;
  static const double filterTopSpacing = 13;
  static const double sectionSpacing = 26;
  static const double sectionContentSpacing = 13;
  static const double bottomSpacing = 24;

  // Animation
  static const Duration entranceAnimationDuration = Duration(milliseconds: 520);

  static const Duration entranceAnimationDelay = Duration(milliseconds: 180);

  static const Curve entranceAnimationCurve = Curves.easeOutCubic;

  static const double entranceFadeBegin = 0;
  static const double entranceFadeEnd = 1;

  static const Offset entranceSlideBegin = Offset(0, 0.025);

  // Page header
  static const Color pageHeaderBackgroundColor = primaryColor;

  static const EdgeInsets pageHeaderPadding = EdgeInsets.symmetric(
    horizontal: 20,
    vertical: 20,
  );

  static const BorderRadius pageHeaderRadius = BorderRadius.all(
    Radius.circular(14),
  );

  static const Border pageHeaderBorder = Border.fromBorderSide(
    BorderSide(color: Color(0xFF2D67BF), width: 1),
  );

  static const List<BoxShadow> pageHeaderShadow = <BoxShadow>[
    BoxShadow(color: Color(0x33164EAD), blurRadius: 16, offset: Offset(0, 6)),
  ];

  static const double pageDescriptionSpacing = 7;

  // Search
  static const double searchHeight = 44;
  static const double sortButtonSpacing = 2;

  static const TextStyle searchTextStyle = TextStyle(
    color: textPrimaryColor,
    fontSize: 13,
  );

  static const InputDecoration searchDecoration = InputDecoration(
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
  static const double folderSectionContentSpacing = 10;

  static const BorderRadius folderSectionRadius = BorderRadius.all(
    Radius.circular(12),
  );

  static const double addFolderButtonSize = 34;
  static const double addFolderButtonIconSize = 25;

  static const double emptyFolderHeight = 76;

  static const double folderCardHeight = 134;
  static const double folderCardWidth = 104;
  static const double folderSpacing = 10;

  static const double folderIconSize = 39;
  static const double folderIconSpacing = 10;
  static const double folderCountSpacing = 6;

  static const EdgeInsets folderPadding = EdgeInsets.symmetric(
    horizontal: 9,
    vertical: 10,
  );

  static const BorderRadius folderRadius = BorderRadius.all(
    Radius.circular(12),
  );

  static const Color warmFolderBackgroundColor = Color(0xFFFFF7E5);
  static const Color warmFolderOutlineColor = Color(0xFFF2E2B9);
  static const Color warmFolderColor = Color(0xFFF5B51B);

  static const Color purpleFolderBackgroundColor = Color(0xFFF2EDFF);
  static const Color purpleFolderOutlineColor = Color(0xFFE0D6FA);
  static const Color purpleFolderColor = Color(0xFF7047C7);

  static const Color selectedFolderBackgroundColor = Color(0xFFEAF2FF);

  static const Duration folderSelectionDuration = Duration(milliseconds: 220);

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

  static const Offset materialMenuOffset = Offset(20, -17);

  static const BorderRadius thumbnailRadius = BorderRadius.all(
    Radius.circular(5),
  );

  static const BorderRadius categoryRadius = BorderRadius.all(
    Radius.circular(10),
  );

  static const Border cardBorder = Border.fromBorderSide(
    BorderSide(color: outlineColor, width: 1),
  );

  static const double materialMenuButtonSize = 36;
  static const double materialMenuIconSize = 21;

  static const EdgeInsets materialMenuPadding = EdgeInsets.zero;

  static const BoxConstraints materialMenuConstraints = BoxConstraints.tightFor(
    width: materialMenuButtonSize,
    height: materialMenuButtonSize,
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

  static final ButtonStyle createFolderButtonStyle = FilledButton.styleFrom(
    backgroundColor: primaryColor,
    foregroundColor: surfaceColor,
    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
  );

  // Typography
  static const TextStyle pageTitleStyle = TextStyle(
    color: Colors.white,
    fontSize: 24,
    height: 1.15,
    fontWeight: FontWeight.w800,
  );

  static const TextStyle pageDescriptionStyle = TextStyle(
    color: Color(0xFFE4EEFF),
    fontSize: 14,
    height: 1.4,
    fontWeight: FontWeight.w500,
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
    color: textPrimaryColor,
    fontSize: 12,
    height: 1.22,
    fontWeight: FontWeight.w700,
  );

  static const TextStyle folderCountStyle = TextStyle(
    color: textSecondaryColor,
    fontSize: 10.5,
    height: 1.2,
    fontWeight: FontWeight.w500,
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

  static const TextStyle emptyFolderStyle = TextStyle(
    color: textMutedColor,
    fontSize: 12,
    fontWeight: FontWeight.w500,
  );
}
