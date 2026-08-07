import 'package:flutter/material.dart';

class ScanScreenStyles {
  const ScanScreenStyles._();

  // Brand colors
  static const Color primaryColor = Color(0xFF0D47A1);
  static const Color backgroundColor = Colors.white;
  static const Color surfaceColor = Colors.white;
  static const Color onPrimaryColor = Colors.white;
  static const Color shadowColor = Color(0x14000000);

  // Screen layout
  static const EdgeInsets contentPadding = EdgeInsets.all(20);
  static const double sectionSpacing = 20;
  static const double buttonSpacing = 12;
  static const double topContentSpacing = 40;

  // Camera layout
  static const double cameraBottomSpacing = 77;

  // Back button
  static const double backButtonTopSpacing = 10;
  static const double backButtonBottomSpacing = 16;
  static const Color backButtonColor = primaryColor;
  static const double backButtonShadowBlurRadius = 10;
  static const Offset backButtonShadowOffset = Offset(0, 2);

  static const List<BoxShadow> backButtonShadow = <BoxShadow>[
    BoxShadow(
      color: shadowColor,
      blurRadius: backButtonShadowBlurRadius,
      offset: backButtonShadowOffset,
    ),
  ];

  static const BoxDecoration backButtonDecoration = BoxDecoration(
    color: surfaceColor,
    shape: BoxShape.circle,
    boxShadow: backButtonShadow,
  );

  // Action buttons
  static const double buttonHeight = 52;
  static const BorderRadius buttonRadius = BorderRadius.all(
    Radius.circular(14),
  );
  static const Color primaryButtonColor = primaryColor;
  static const TextStyle buttonTextStyle = TextStyle(
    fontSize: 15,
    fontWeight: FontWeight.w600,
    color: onPrimaryColor,
  );

}
