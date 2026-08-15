import 'package:flutter/material.dart';

abstract final class SplashScreenStyles {
  static const String logoAsset = 'assets/icons/tactilelens_app_icon.png';

  static const String appName = 'TactileLens';
  static const String tagline = 'See. Translate. Empower.';
  static const String description =
      'AI-assisted translator for\naccessible learning.';
  static const String loadingMessage =
      'Preparing your accessible experience...';
  static const String getStartedLabel = 'Get Started';

  static const Color backgroundColor = Color(0xFFF9FBFF);
  static const Color topDecorationColor = Color(0xFFEFF5FF);
  static const Color bottomDecorationColor = Color(0xFFE8F1FF);
  static const Color primaryColor = Color(0xFF1746C7);
  static const Color secondaryColor = Color(0xFF3B82F6);
  static const Color accentColor = Color(0xFF93C5FD);
  static const Color inactiveDotColor = Color(0xFFD5E3F8);
  static const Color titleColor = Color(0xFF07143D);
  static const Color bodyColor = Color(0xFF34446E);
  static const Color whiteColor = Colors.white;

  static const double zero = 0;
  static const double fullOpacity = 1;
  static const double decorationOpacity = 0.45;
  static const double illustrationOpacity = 0.5;

  static const double screenHorizontalPadding = 32;
  static const double logoSize = 142;
  static const double logoImageSize = 108;
  static const double logoRadius = 34;

  static const double titleTopSpacing = 30;
  static const double taglineTopSpacing = 6;
  static const double descriptionTopSpacing = 16;
  static const double loadingTopSpacing = 48;
  static const double messageTopSpacing = 22;

  static const double buttonHeight = 54;
  static const double decorationDotSize = 9;
  static const double loadingDotSize = 11;
  static const double activeLoadingDotSize = 14;
  static const double loadingDotSpacing = 12;

  static const double topCircleSize = 310;
  static const double bottomCircleSize = 360;
  static const double bottomIllustrationSize = 94;
  static const double bookIconSize = 70;
  static const double searchIconSize = 52;

  static const double topCircleTop = -170;
  static const double topCircleLeft = -100;
  static const double bottomCircleRight = -170;
  static const double bottomCircleBottom = -120;

  static const double leftBrailleTop = 140;
  static const double leftBrailleLeft = 32;
  static const double rightBrailleTop = 110;
  static const double rightBrailleRight = 30;
  static const double bottomBrailleRight = 30;
  static const double bottomBrailleBottom = 62;

  static const double illustrationLeft = 24;
  static const double illustrationBottom = 26;

  static const int loadingDotCount = 5;

  static const Duration progressInterval = Duration(milliseconds: 55);

  static const Duration minimumSplashDuration = Duration(milliseconds: 3400);

  static const Duration entranceAnimationDuration = Duration(
    milliseconds: 1500,
  );

  static const Duration transitionDuration = Duration(milliseconds: 320);

  static const Curve entranceCurve = Curves.easeOutCubic;
  static const Curve switchCurve = Curves.easeInOutCubic;

  static const Offset brandingBeginOffset = Offset(0, 0.16);
  static const Offset loadingBeginOffset = Offset(0, 0.25);
  static const Offset switchBeginOffset = Offset(0, 0.18);

  static const double logoInitialScale = 0.76;

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
    fontSize: 44,
    height: 1,
    fontWeight: FontWeight.w800,
    letterSpacing: -1.2,
  );

  static const TextStyle taglineStyle = TextStyle(
    color: primaryColor,
    fontSize: 20,
    height: 1.3,
    fontWeight: FontWeight.w700,
  );

  static const TextStyle descriptionStyle = TextStyle(
    color: bodyColor,
    fontSize: 16,
    height: 1.45,
    fontWeight: FontWeight.w400,
  );

  static const TextStyle loadingMessageStyle = TextStyle(
    color: primaryColor,
    fontSize: 14,
    height: 1.3,
    fontWeight: FontWeight.w500,
  );

  static const TextStyle buttonTextStyle = TextStyle(
    color: whiteColor,
    fontSize: 16,
    fontWeight: FontWeight.w700,
  );

  static const LinearGradient logoGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: <Color>[secondaryColor, Color(0xFF0B2E9E)],
  );

  static const List<BoxShadow> logoShadow = <BoxShadow>[
    BoxShadow(
      color: Color(0x331746C7),
      blurRadius: 30,
      spreadRadius: 2,
      offset: Offset(0, 14),
    ),
  ];

  static ButtonStyle getStartedButtonStyle = ElevatedButton.styleFrom(
    backgroundColor: primaryColor,
    foregroundColor: whiteColor,
    elevation: 0,
    shape: const RoundedRectangleBorder(borderRadius: buttonRadius),
  );
}
