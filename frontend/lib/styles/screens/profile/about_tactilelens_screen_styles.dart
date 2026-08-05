import 'package:flutter/material.dart';

abstract class AboutTactileLensScreenStyles {
  // Palette Colors
  static const Color primaryColor = Color(0xFF2563EB); // Deep modern blue
  static const Color primaryLightColor = Color(0xFFEFF6FF); // Subtle blue fill
  static const Color backgroundColor = Color(0xFFF8FAFC); // Clean off-white
  static const Color cardColor = Colors.white;
  static const Color textDark = Color(0xFF0F172A); // Slate 900
  static const Color textMuted = Color(0xFF64748B); // Slate 500
  static const Color iconAccent = Color(0xFF3B82F6);

  // Paddings & Spacings
  static const EdgeInsets screenPadding = EdgeInsets.symmetric(horizontal: 16.0, vertical: 20.0);
  static const EdgeInsets cardPadding = EdgeInsets.all(18.0);
  static const EdgeInsets headerCardPadding = EdgeInsets.all(24.0);
  static const EdgeInsets featureTilePadding = EdgeInsets.symmetric(vertical: 6.0, horizontal: 12.0);

  static const SizedBox spaceXs = SizedBox(height: 6.0);
  static const SizedBox spaceSm = SizedBox(height: 12.0);
  static const SizedBox spaceMd = SizedBox(height: 20.0);
  static const SizedBox spaceLg = SizedBox(height: 28.0);

  // Radius & Shadows
  static final BorderRadius cardRadius = BorderRadius.circular(16.0);
  static final BorderRadius headerRadius = BorderRadius.circular(20.0);
  
  static final List<BoxShadow> softShadow = [
    BoxShadow(
      color: Colors.black.withOpacity(0.04),
      blurRadius: 10.0,
      offset: const Offset(0, 4),
    ),
  ];

  // Icons
  static const IconData appIcon = Icons.visibility_rounded;
  static const double appIconSize = 52.0;
  static const IconData featureIcon = Icons.check_circle_rounded;
  static const IconData developerIcon = Icons.groups_rounded;

  // Text Styles
  static const TextStyle appBarTitleStyle = TextStyle(
    fontWeight: FontWeight.w700,
    fontSize: 20.0,
  );

  static const TextStyle appTitleStyle = TextStyle(
    fontSize: 26.0,
    fontWeight: FontWeight.bold,
    color: textDark,
    letterSpacing: -0.5,
  );

  static const TextStyle versionBadgeStyle = TextStyle(
    color: primaryColor,
    fontWeight: FontWeight.w600,
    fontSize: 13.0,
  );

  static const TextStyle sectionTitleStyle = TextStyle(
    fontSize: 18.0,
    fontWeight: FontWeight.w700,
    color: textDark,
  );

  static const TextStyle bodyTextStyle = TextStyle(
    fontSize: 14.5,
    height: 1.55,
    color: textMuted,
  );

  static const TextStyle featureTitleStyle = TextStyle(
    fontSize: 14.5,
    fontWeight: FontWeight.w600,
    color: textDark,
  );

  static const TextStyle devTitleStyle = TextStyle(
    fontSize: 15.0,
    fontWeight: FontWeight.bold,
    color: textDark,
  );

  static const TextStyle devSubtitleStyle = TextStyle(
    fontSize: 13.5,
    color: textMuted,
  );
}