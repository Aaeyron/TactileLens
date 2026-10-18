import 'package:flutter/material.dart';

abstract final class SplashScreenStyles {
  static const String logoAsset = 'assets/icons/tactilelens_app_icon.png';

  static const String appName = 'TactileLens';
  static const String getStartedLabel = 'Get Started';

  // Palette: source of truth
  static const Color darkBlueColor = Color(0xFF0B2E9E);
  static const Color primaryColor = Color(0xFF1746C7);
  static const Color secondaryColor = Color(0xFF3B82F6);
  static const Color accentColor = Color(0xFF93C5FD);
  static const Color backgroundColor = darkBlueColor;
  static const Color titleColor = Colors.white;
  static const Color whiteColor = Colors.white;

  static const double zero = 0;
  static const double fullOpacity = 1;

  static const double screenHorizontalPadding = 32;
  static const double logoSize = 132;
  static const double logoRadius = 32;

  static const double titleTopSpacing = 24;
  static const double buttonHeight = 54;
  static const double bottomPadding = 28;

  static const Duration progressInterval = Duration(milliseconds: 55);
  static const Duration minimumSplashDuration = Duration(milliseconds: 3400);
  static const Duration entranceAnimationDuration = Duration(
    milliseconds: 1200,
  );
  static const Duration transitionDuration = Duration(milliseconds: 300);

  static const Curve entranceCurve = Curves.easeOutCubic;
  static const Curve switchCurve = Curves.easeInOutCubic;

  static const Offset brandingBeginOffset = Offset(0, 0.15);
  static const Offset switchBeginOffset = Offset(0, 0.2);
  static const double logoInitialScale = 0.85;

  static const EdgeInsets screenPadding = EdgeInsets.symmetric(
    horizontal: screenHorizontalPadding,
  );

  static const BorderRadius logoBorderRadius = BorderRadius.all(
    Radius.circular(logoRadius),
  );

  static const BorderRadius buttonRadius = BorderRadius.all(
    Radius.circular(16),
  );

  static const TextStyle titleStyle = TextStyle(
    color: titleColor,
    fontSize: 42,
    height: 1.1,
    fontWeight: FontWeight.w800,
    letterSpacing: -0.5,
  );

  static const TextStyle buttonTextStyle = TextStyle(
    color: darkBlueColor,
    fontSize: 17,
    fontWeight: FontWeight.w700,
    letterSpacing: 0.2,
  );

  static const List<BoxShadow> logoShadow = <BoxShadow>[
    BoxShadow(
      color: Color(0x40000000),
      blurRadius: 28,
      spreadRadius: 2,
      offset: Offset(0, 12),
    ),
  ];

  static ButtonStyle getStartedButtonStyle = ElevatedButton.styleFrom(
    backgroundColor: whiteColor,
    foregroundColor: darkBlueColor,
    elevation: 3,
    shadowColor: const Color(0x33000000),
    shape: const RoundedRectangleBorder(borderRadius: buttonRadius),
    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
  );
}
