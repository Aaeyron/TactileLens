import 'package:flutter/material.dart';

class HomeStyles {
  // ==========================
  // Background
  // ==========================

  static const Color backgroundColor = Color(0xFFF8F9FA);

  // ==========================
  // Header
  // ==========================

  static const Color headerColor = Colors.white;

  static const double headerHeight = 150.0;

  static const List<BoxShadow> headerShadow = [
    BoxShadow(
      color: Colors.black12,
      blurRadius: 12,
      spreadRadius: 1,
      offset: Offset(0, 4),
    ),
  ];

  // ==========================
  // Main Content
  // ==========================

  static const EdgeInsets contentPadding = EdgeInsets.symmetric(
    horizontal: 20,
    vertical: 20,
  );

  // ==========================
  // Placeholder Text
  // ==========================

  static const TextStyle placeholderStyle = TextStyle(
    fontSize: 22,
    fontWeight: FontWeight.bold,
    color: Colors.grey,
  );

  // ==========================
  // Main Home Card
  // ==========================

  // Layout
  static const double mainCardHeight = 220.0;

  static const EdgeInsets mainCardPadding =
      EdgeInsets.all(24);

  static const double mainCardTitleSpacing = 12.0;

  // Appearance
  static const Color mainCardColor = Color(0xFF0D47A1);

  static const BorderRadius mainCardRadius =
      BorderRadius.all(
    Radius.circular(20),
  );

  static const List<BoxShadow> mainCardShadow = [
    BoxShadow(
      color: Colors.black12,
      blurRadius: 8,
      offset: Offset(0, 3),
    ),
  ];

  // Text Styles
  static const TextStyle mainCardTitleStyle =
      TextStyle(
    fontSize: 24,
    fontWeight: FontWeight.bold,
    color: Colors.white,
  );

  static const TextStyle mainCardSubtitleStyle =
      TextStyle(
    fontSize: 15,
    color: Colors.white70,
    height: 1.5,
  );

  // ==========================
  // Feature Cards
  // ==========================

  // Layout
  static const double featureCardHeight = 150.0;

  static const EdgeInsets featureCardPadding =
      EdgeInsets.all(16);

  static const double featureCardSpacing = 12.0;

  // Appearance
  static const Color featureCardColor =
      Colors.white;

  static const BorderRadius featureCardRadius =
      BorderRadius.all(
    Radius.circular(18),
  );

  static const List<BoxShadow> featureCardShadow = [
    BoxShadow(
      color: Colors.black12,
      blurRadius: 8,
      offset: Offset(0, 3),
    ),
  ];

  // Icon
  static const double featureIconSize = 30.0;

  static const Color featureIconColor =
      Color(0xFF0D47A1);

  // Text Styles
  static const TextStyle featureTitleStyle =
      TextStyle(
    fontSize: 15,
    fontWeight: FontWeight.w600,
    color: Colors.black87,
  );

  static const double featureDescriptionSpacing =
      6.0;

  static const TextStyle featureDescriptionStyle =
      TextStyle(
    fontSize: 12,
    color: Colors.grey,
    height: 1.3,
  );

  // ==========================
  // General Section Title
  // ==========================

  static const TextStyle sectionTitleStyle =
      TextStyle(
    fontSize: 18,
    fontWeight: FontWeight.bold,
    color: Colors.black87,
  );

  static const double sectionSpacing = 20.0;

  static const double sectionTitleBottomSpacing =
      12.0;

  // ==========================
  // Recent Scan Card
  // ==========================

  // Layout
  static const double recentCardHeight = 180.0;

  static const EdgeInsets recentCardPadding =
      EdgeInsets.all(18);

  // Appearance
  static const Color recentCardColor =
      Colors.white;

  static const BorderRadius recentCardRadius =
      BorderRadius.all(
    Radius.circular(18),
  );

  static const List<BoxShadow> recentCardShadow = [
    BoxShadow(
      color: Colors.black12,
      blurRadius: 8,
      offset: Offset(0, 3),
    ),
  ];

  // ==========================
  // Recent Scan Content
  // ==========================

  // Empty State Icon Container
  static const double recentEmptyIconContainerSize =
      68.0;

  static const Color recentEmptyIconBackgroundColor =
      Color(0xFFEAF2FF);

  static const BorderRadius recentEmptyIconRadius =
      BorderRadius.all(
    Radius.circular(18),
  );

  // Icon
  static const double recentIconSize = 26.0;

  static const Color recentIconColor =
      Color(0xFF0D47A1);

  // Spacing
  static const double recentIconTextSpacing =
      15.0;

  static const double recentSubtitleTopSpacing =
      4.0;

  // Text Styles
  static const TextStyle recentTitleStyle =
      TextStyle(
    fontSize: 15,
    fontWeight: FontWeight.w600,
    color: Colors.black87,
  );

  static const TextStyle recentSubtitleStyle =
      TextStyle(
    fontSize: 13,
    color: Colors.grey,
  );
}