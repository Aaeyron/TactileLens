import 'package:flutter/material.dart';

class MaterialsStyles {
  const MaterialsStyles._();

  // ============================================================
  // PAGE
  // ============================================================

  static const Color backgroundColor =
      Color(0xFFF8F9FA);

  static const EdgeInsets contentPadding =
      EdgeInsets.symmetric(
    horizontal: 20,
    vertical: 20,
  );

  // ============================================================
  // PAGE HEADER
  // ============================================================

  static const double pageTitleBottomSpacing =
      8.0;

  static const double pageDescriptionBottomSpacing =
      24.0;

  static const double sectionSpacing =
      24.0;

  static const TextStyle pageTitleStyle =
      TextStyle(
    fontSize: 28,
    fontWeight: FontWeight.bold,
    color: Colors.black87,
  );

  static const TextStyle pageDescriptionStyle =
      TextStyle(
    fontSize: 15,
    color: Colors.grey,
    height: 1.5,
  );

  // ============================================================
  // UPLOAD MATERIAL BUTTON
  // ============================================================

  static const double uploadButtonHeight =
      56.0;

  static const BorderRadius uploadButtonRadius =
      BorderRadius.all(
    Radius.circular(16),
  );

  static const Color uploadButtonColor =
      Color(0xFF0D47A1);

  static const double uploadButtonIconSize =
      22.0;

  static const TextStyle uploadButtonTextStyle =
      TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w600,
    color: Colors.white,
  );

  // ============================================================
  // EMPTY MATERIALS CARD
  // ============================================================

  static const double emptyCardHeight =
      260.0;

  static const EdgeInsets emptyCardPadding =
      EdgeInsets.all(24);

  static const Color emptyCardColor =
      Colors.white;

  static const BorderRadius emptyCardRadius =
      BorderRadius.all(
    Radius.circular(18),
  );

  static const List<BoxShadow> emptyCardShadow = [
    BoxShadow(
      color: Colors.black12,
      blurRadius: 8,
      offset: Offset(0, 3),
    ),
  ];

  // ============================================================
  // EMPTY MATERIALS CONTENT
  // ============================================================

  static const double emptyIconContainerSize =
      70.0;

  static const Color emptyIconBackgroundColor =
      Color(0xFFEAF2FF);

  static const BorderRadius emptyIconRadius =
      BorderRadius.all(
    Radius.circular(18),
  );

  static const double emptyIconSize =
      30.0;

  static const Color emptyIconColor =
      Color(0xFF0D47A1);

  static const double emptyIconTextSpacing =
      18.0;

  static const double emptySubtitleTopSpacing =
      6.0;

  static const TextStyle emptyTitleStyle =
      TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w600,
    color: Colors.black87,
  );

  static const TextStyle emptySubtitleStyle =
      TextStyle(
    fontSize: 13,
    color: Colors.grey,
    height: 1.5,
  );

  // ============================================================
  // MATERIAL CARD
  // ============================================================

  static const double materialCardPadding =
      18.0;

  static const Color materialCardColor =
      Colors.white;

  static const BorderRadius materialCardRadius =
      BorderRadius.all(
    Radius.circular(18),
  );

  static const List<BoxShadow> materialCardShadow = [
    BoxShadow(
      color: Colors.black12,
      blurRadius: 8,
      offset: Offset(0, 3),
    ),
  ];

  // ============================================================
  // MATERIAL FILE ICON
  // ============================================================

  static const double materialIconContainerSize =
      52.0;

  static const Color materialIconBackgroundColor =
      Color(0xFFEAF2FF);

  static const BorderRadius materialIconRadius =
      BorderRadius.all(
    Radius.circular(14),
  );

  static const double materialIconSize =
      26.0;

  static const Color materialIconColor =
      Color(0xFF0D47A1);

  // ============================================================
  // MATERIAL CARD TEXT
  // ============================================================

  static const TextStyle materialTitleStyle =
      TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w600,
    color: Colors.black87,
  );

  static const TextStyle materialFileNameStyle =
      TextStyle(
    fontSize: 13,
    color: Colors.grey,
  );

  static const TextStyle materialInfoStyle =
      TextStyle(
    fontSize: 12,
    color: Colors.grey,
  );

  // ============================================================
  // MATERIAL CARD SPACING
  // ============================================================

  static const double materialIconTextSpacing =
      14.0;

  static const double materialTitleFileSpacing =
      4.0;

  static const double materialInfoSpacing =
      6.0;

  // ============================================================
  // MATERIAL CARD ACTIONS
  // ============================================================

  static const double materialActionIconSize =
      22.0;

  static const Color materialActionIconColor =
      Colors.grey;

  static const Color materialDeleteIconColor =
      Colors.red;


// ============================================================
// MATERIAL LIST
// ============================================================

static const double materialListSpacing = 14.0;

}