import 'package:flutter/material.dart';

class MaterialWidgetStyles {
  const MaterialWidgetStyles._();

  // ============================================================
  // UPLOAD MATERIAL BUTTON
  // ============================================================

  static const double uploadButtonHeight = 56.0;

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
      16.0;

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
  // MATERIAL PREVIEW
  // ============================================================

  static const double materialPreviewWidth =
      100.0;

  static const double materialPreviewHeight =
      130.0;

  static const Color materialPreviewBackgroundColor =
      Color(0xFFF1F5F9);

  static const BorderRadius materialPreviewRadius =
      BorderRadius.all(
    Radius.circular(12),
  );

  static const Color materialPreviewBorderColor =
    Color(0xFFCBD5E1);

  static const double materialPreviewBorderWidth =
    1.0;

  static const double materialPreviewIconSize =
      36.0;

  static const Color materialPreviewIconColor =
      Color(0xFF0D47A1);


  // ============================================================
  // MATERIAL CARD TEXT
  // ============================================================

  static const TextStyle materialTitleStyle =
    TextStyle(
  fontSize: 17,
  fontWeight: FontWeight.w700,
  color: Color(0xFF1F2937),
  height: 1.2,
);

static const TextStyle materialSubjectStyle =
    TextStyle(
  fontSize: 14,
  fontWeight: FontWeight.w500,
  color: Color(0xFF4B5563),
);

static const TextStyle materialDateStyle =
    TextStyle(
  fontSize: 12,
  fontWeight: FontWeight.w400,
  color: Color(0xFF6B7280),
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