import 'package:flutter/material.dart';

abstract final class SplashScreenStyles {
  static const String logoAsset = 'assets/icons/tactilelens_app_icon.png';

  static const String appName = 'TactileLens';

  // Palette: source of truth
  static const Color darkBlueColor = Color(0xFF0B2E9E);
  static const Color primaryColor = Color(0xFF1746C7);
  static const Color secondaryColor = Color(0xFF3B82F6);
  static const Color accentColor = Color(0xFF93C5FD);
  static const Color backgroundColor = darkBlueColor;
  static const Color titleColor = Colors.white;
  static const Color whiteColor = Colors.white;

  static const double screenHorizontalPadding = 32;
  static const double logoSize = 132;
  static const double logoRadius = 32;

  static const double titleTopSpacing = 24;

  /// Shown at least this long, so the logo does not flash.
  static const Duration minimumDuration = Duration(milliseconds: 1500);

  /// Moves on after this long even if loading has not finished.
  static const Duration maximumDuration = Duration(seconds: 5);

  static const EdgeInsets screenPadding = EdgeInsets.symmetric(
    horizontal: screenHorizontalPadding,
  );

  static const BorderRadius logoBorderRadius = BorderRadius.all(
    Radius.circular(logoRadius),
  );

  static const TextStyle titleStyle = TextStyle(
    color: titleColor,
    fontSize: 42,
    height: 1.1,
    fontWeight: FontWeight.w800,
    letterSpacing: -0.5,
  );

  static const List<BoxShadow> logoShadow = <BoxShadow>[
    BoxShadow(
      color: Color(0x40000000),
      blurRadius: 28,
      spreadRadius: 2,
      offset: Offset(0, 12),
    ),
  ];
}
