import 'package:flutter/material.dart';

class MaterialScreenStyles {
  const MaterialScreenStyles._();

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
 // Materials List Container
 // ==========================

 static const double materialsListHeight = 400.0;

 static const Color materialsListBackgroundColor = Colors.white;

 static const BorderRadius materialsListRadius =
     BorderRadius.all(
   Radius.circular(16),
 );

 static const EdgeInsets materialsListPadding =
     EdgeInsets.all(12);

 static const EdgeInsets materialCardMargin =
     EdgeInsets.only(bottom: 12);
    
}