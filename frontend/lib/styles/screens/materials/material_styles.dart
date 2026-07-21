import 'package:flutter/material.dart';

class MaterialsStyles {
  const MaterialsStyles._();

// ==========================
// Background
// ==========================

static const Color backgroundColor = Color(0xFFF8F9FA);

// ==========================
// Main Content
// ==========================

static const EdgeInsets contentPadding =
    EdgeInsets.symmetric(
  horizontal: 20,
  vertical: 20,
);

// ==========================
// Page Header
// ==========================

 // Layout
static const double pageTitleBottomSpacing = 8.0;

static const double pageDescriptionBottomSpacing = 24.0;

static const double sectionSpacing = 24.0;

// Text Styles
static const TextStyle pageTitleStyle = TextStyle(
  fontSize: 28,
  fontWeight: FontWeight.bold,
  color: Colors.black87,
);

static const TextStyle pageDescriptionStyle = TextStyle(
  fontSize: 15,
  color: Colors.grey,
  height: 1.5,
);


// ==========================
// Upload Material Button
// ==========================
// Layout
static const double uploadButtonHeight = 56.0;

static const BorderRadius uploadButtonRadius =
    BorderRadius.all(
  Radius.circular(16),
);

// Appearance
static const Color uploadButtonColor =
    Color(0xFF0D47A1);

// Icon
static const double uploadButtonIconSize = 22.0;

// Text
static const TextStyle uploadButtonTextStyle =
    TextStyle(
  fontSize: 16,
  fontWeight: FontWeight.w600,
  color: Colors.white,
);

// ==========================
// Empty Materials Card
// ==========================

  // Layout
static const double emptyCardHeight = 260.0;

static const EdgeInsets emptyCardPadding =
    EdgeInsets.all(24);

// Appearance
static const Color emptyCardColor = Colors.white;

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

// ==========================
// Empty Materials Content
// ==========================

 // Icon Container
static const double emptyIconContainerSize = 70.0;

static const Color emptyIconBackgroundColor =
    Color(0xFFEAF2FF);

static const BorderRadius emptyIconRadius =
    BorderRadius.all(
  Radius.circular(18),
);

// Icon
static const double emptyIconSize = 30.0;

static const Color emptyIconColor =
    Color(0xFF0D47A1);

// Spacing
static const double emptyIconTextSpacing = 18.0;

static const double emptySubtitleTopSpacing = 6.0;

// Text Styles
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
}