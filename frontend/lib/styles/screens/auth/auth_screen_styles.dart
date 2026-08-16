import 'package:flutter/material.dart';

abstract final class AuthStyles {
  // ==========================
  // Content
  // ==========================

  static const String logoAsset = 'assets/icons/tactilelens_app_icon.png';

  static const String logoSemanticLabel = 'TactileLens application logo';

  static const String welcomeText = 'Welcome to';
  static const String appNameFirstPart = 'Tactile';
  static const String appNameSecondPart = 'Lens';
  static const String tagline = 'See. Translate. Empower.';

  static const String description =
      'Scan printed materials and convert them\n'
      'into Nemeth Braille and accessible text.';

  static const String signInLabel = 'Sign In';
  static const String signUpLabel = 'Sign Up';
  static const String guestLabel = 'Continue without an account';
  static const String orLabel = 'or';

  static const String scanningTitle = 'Smart Scanning';
  static const String scanningDescription = 'Capture printed\nmaterials easily';

  static const String translationTitle = 'AI Translation';
  static const String translationDescription =
      'Convert to Nemeth\nBraille and text';

  static const String accessibilityTitle = 'Accessible';
  static const String accessibilityDescription =
      'Empowering learning\nfor everyone';

  // ==========================
  // Colors
  // ==========================

  static const Color backgroundColor = Color(0xFFF9FBFF);
  static const Color primaryColor = Color(0xFF0D47A1);
  static const Color brightPrimaryColor = Color(0xFF0969F9);
  static const Color darkTitleColor = Color(0xFF061541);
  static const Color descriptionColor = Color(0xFF34446E);
  static const Color secondaryTextColor = Color(0xFF66759B);
  static const Color surfaceColor = Colors.white;
  static const Color dividerColor = Color(0xFFD4E2F7);
  static const Color forwardIconColor = Color(0xFF7F96C2);
  static const Color guestBackgroundColor = Color(0xFFF1F6FF);
  static const Color featureIconBackgroundColor = Color(0xFFF7FAFF);
  static const Color featureDividerColor = Color(0xFFC8D9F5);
  static const Color decorationDotColor = Color(0xFFDCEAFF);
  static const Color inactiveIndicatorColor = Color(0xFFC9D9F3);

  // ==========================
  // Icons
  // ==========================

  static const IconData signInIcon = Icons.person_outline_rounded;

  static const IconData signUpIcon = Icons.person_add_alt_1_outlined;

  static const IconData guestIcon = Icons.login_rounded;

  static const IconData forwardIcon = Icons.chevron_right_rounded;

  static const IconData scanningIcon = Icons.document_scanner_outlined;

  static const IconData translationIcon = Icons.translate_rounded;

  static const IconData accessibilityIcon = Icons.volume_up_outlined;

  // ==========================
  // Screen layout
  // ==========================

  static const EdgeInsets pagePadding = EdgeInsets.symmetric(
    horizontal: 28,
    vertical: 20,
  );

  static const double topSpacing = 18;
  static const double bottomSpacing = 28;

  static const double logoContainerSize = 150;
  static const EdgeInsets logoPadding = EdgeInsets.all(16);
  static const double logoBottomSpacing = 25;

  static const double titleIndicatorSpacing = 12;
  static const double taglineTopSpacing = 14;
  static const double descriptionTopSpacing = 10;
  static const double actionsTopSpacing = 28;

  static const double buttonHeight = 54;
  static const double buttonSpacing = 14;
  static const double buttonIconSize = 21;
  static const double forwardIconSize = 24;

  static const double dividerVerticalSpacing = 12;
  static const EdgeInsets orLabelPadding = EdgeInsets.symmetric(horizontal: 18);

  static const double featuresTopSpacing = 38;

  // ==========================
  // Logo
  // ==========================

  static const BorderRadius logoRadius = BorderRadius.all(Radius.circular(34));

  static const List<BoxShadow> logoShadow = <BoxShadow>[
    BoxShadow(
      color: Color(0x241C64E8),
      blurRadius: 30,
      spreadRadius: 2,
      offset: Offset(0, 12),
    ),
  ];

  static const LinearGradient logoGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: <Color>[Color(0xFF4878FF), Color(0xFF153AB8)],
  );

  // ==========================
  // Typography
  // ==========================

  static const TextStyle welcomeStyle = TextStyle(
    color: darkTitleColor,
    fontSize: 19,
    height: 1.2,
    fontWeight: FontWeight.w700,
  );

  static const TextStyle appNameDarkStyle = TextStyle(
    color: darkTitleColor,
    fontSize: 43,
    height: 1.05,
    fontWeight: FontWeight.w800,
    letterSpacing: -1.4,
  );

  static const TextStyle appNameBlueStyle = TextStyle(
    color: brightPrimaryColor,
    fontSize: 43,
    height: 1.05,
    fontWeight: FontWeight.w800,
    letterSpacing: -1.4,
  );

  static const TextStyle taglineStyle = TextStyle(
    color: brightPrimaryColor,
    fontSize: 17,
    height: 1.25,
    fontWeight: FontWeight.w700,
  );

  static const TextStyle descriptionStyle = TextStyle(
    color: descriptionColor,
    fontSize: 13.5,
    height: 1.45,
    fontWeight: FontWeight.w400,
  );

  static const TextStyle primaryButtonTextStyle = TextStyle(
    color: surfaceColor,
    fontSize: 15,
    fontWeight: FontWeight.w700,
  );

  static const TextStyle secondaryButtonTextStyle = TextStyle(
    color: darkTitleColor,
    fontSize: 15,
    fontWeight: FontWeight.w700,
  );

  static const TextStyle guestButtonTextStyle = TextStyle(
    color: darkTitleColor,
    fontSize: 14,
    fontWeight: FontWeight.w600,
  );

  static const TextStyle orLabelStyle = TextStyle(
    color: secondaryTextColor,
    fontSize: 13,
    fontWeight: FontWeight.w500,
  );

  static const TextStyle featureTitleStyle = TextStyle(
    color: darkTitleColor,
    fontSize: 11.5,
    height: 1.2,
    fontWeight: FontWeight.w700,
  );

  static const TextStyle featureDescriptionStyle = TextStyle(
    color: secondaryTextColor,
    fontSize: 9.5,
    height: 1.25,
    fontWeight: FontWeight.w400,
  );

  // ==========================
  // Buttons
  // ==========================

  static const BorderRadius buttonRadius = BorderRadius.all(
    Radius.circular(15),
  );

  static final ButtonStyle signInButtonStyle = ElevatedButton.styleFrom(
    backgroundColor: brightPrimaryColor,
    foregroundColor: surfaceColor,
    elevation: 6,
    shadowColor: const Color(0x401B65E9),
    padding: const EdgeInsets.symmetric(horizontal: 18),
    shape: const RoundedRectangleBorder(borderRadius: buttonRadius),
  );

  static final ButtonStyle signUpButtonStyle = OutlinedButton.styleFrom(
    backgroundColor: surfaceColor,
    foregroundColor: brightPrimaryColor,
    elevation: 4,
    shadowColor: const Color(0x241B65E9),
    padding: const EdgeInsets.symmetric(horizontal: 18),
    side: const BorderSide(color: Color(0xFFD8E4F8), width: 1.2),
    shape: const RoundedRectangleBorder(borderRadius: buttonRadius),
  );

  static final ButtonStyle guestButtonStyle = OutlinedButton.styleFrom(
    backgroundColor: guestBackgroundColor,
    foregroundColor: brightPrimaryColor,
    elevation: 3,
    shadowColor: const Color(0x1F1B65E9),
    padding: const EdgeInsets.symmetric(horizontal: 18),
    side: const BorderSide(color: Color(0xFFE0EAFB), width: 1),
    shape: const RoundedRectangleBorder(borderRadius: buttonRadius),
  );

  // ==========================
  // Title indicator
  // ==========================

  static const double indicatorLineWidth = 16;
  static const double indicatorHeight = 2;
  static const double indicatorThickness = 1.5;
  static const double indicatorDotSize = 5;
  static const double indicatorSpacing = 4;

  // ==========================
  // Dividers
  // ==========================

  static const double dividerThickness = 1;
  static const double featureDividerWidth = 1;
  static const double featureDividerHeight = 74;

  static const EdgeInsets featureDividerMargin = EdgeInsets.symmetric(
    horizontal: 10,
  );

  // ==========================
  // Feature section
  // ==========================

  static const double featureIconContainerSize = 48;
  static const double featureIconSize = 25;
  static const double featureTitleTopSpacing = 10;
  static const double featureDescriptionTopSpacing = 5;

  static const BorderRadius featureIconRadius = BorderRadius.all(
    Radius.circular(14),
  );

  static const List<BoxShadow> featureIconShadow = <BoxShadow>[
    BoxShadow(color: Color(0x191B65E9), blurRadius: 14, offset: Offset(0, 6)),
  ];

  // ==========================
  // Background decoration
  // ==========================

  static const double topDecorationSize = 270;
  static const double bottomDecorationSize = 330;
  static const double topDecorationOffset = -130;
  static const double bottomDecorationOffset = -180;

  static const double topDotDecorationTop = 30;
  static const double middleDotDecorationTop = 170;
  static const double dotDecorationSide = 24;

  static const int decorationDotCount = 6;
  static const double decorationDotSize = 6;
  static const double decorationDotSpacing = 9;

  static const LinearGradient backgroundDecorationGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: <Color>[Color(0xFFDDEAFF), Color(0xFFF3F7FF)],
  );

  static const List<BoxShadow> decorationDotShadow = <BoxShadow>[
    BoxShadow(color: Color(0x1F1769E8), blurRadius: 4, offset: Offset(0, 2)),
  ];

  // ==========================
  // Bottom indicator
  // ==========================

  static const double pageIndicatorSize = 7;
  static const double pageIndicatorSpacing = 5;
}
