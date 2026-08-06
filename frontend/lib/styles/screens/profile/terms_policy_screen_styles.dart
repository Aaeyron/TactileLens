import 'package:flutter/material.dart';

abstract final class TermsPolicyScreenStyles {
  static const String fontFamily = 'Poppins';

  // Brand palette
  static const Color primaryColor = Color(0xFF0D47A1);
  static const Color primaryDarkColor = Color(0xFF083475);
  static const Color primarySoftColor = Color(0xFFEAF2FC);
  static const Color primaryFaintColor = Color(0xFFF6F9FD);
  static const Color backgroundColor = Color(0xFFFAFCFF);
  static const Color cardColor = Color(0xFFFFFFFF);
  static const Color textPrimaryColor = Color(0xFF11152E);
  static const Color textSecondaryColor = Color(0xFF4E5872);
  static const Color borderColor = Color(0xFFD8E4F3);
  static const Color dividerColor = Color(0xFFE3EBF5);
  static const Color shadowColor = Color(0x140D47A1);
  static const Color transparentColor = Colors.transparent;

  // Responsive layout
  static const double contentMaxWidth = 640;
  static const double compactBreakpoint = 360;
  static const double appBarElevation = 0;
  static const double appBarScrolledUnderElevation = 0;
  static const double cardBorderWidth = 1;
  static const double segmentBorderWidth = 1.25;
  static const double dividerThickness = 1;
  static const double compactPolicyIconBoxSize = 48;
  static const double policyIconBoxSize = 56;
  static const double heroIconBoxSize = 86;
  static const double segmentHeight = 50;
  static const double checkboxSize = 22;
  static const int policyBodyMaxLines = 12;

  // Padding
  static const EdgeInsets screenPadding = EdgeInsets.fromLTRB(18, 18, 18, 32);
  static const EdgeInsets heroPadding = EdgeInsets.symmetric(
    horizontal: 22,
    vertical: 28,
  );
  static const EdgeInsets compactHeroPadding = EdgeInsets.all(18);
  static const EdgeInsets segmentOuterPadding = EdgeInsets.all(3);
  static const EdgeInsets segmentPadding = EdgeInsets.symmetric(
    horizontal: 12,
    vertical: 10,
  );
  static const EdgeInsets policyCardPadding = EdgeInsets.symmetric(
    horizontal: 20,
    vertical: 6,
  );
  static const EdgeInsets compactPolicyCardPadding = EdgeInsets.symmetric(
    horizontal: 14,
    vertical: 4,
  );
  static const EdgeInsets policyItemPadding = EdgeInsets.symmetric(vertical: 20);
  static const EdgeInsets notePadding = EdgeInsets.all(18);
  static const EdgeInsets checkboxPadding = EdgeInsets.symmetric(
    horizontal: 6,
    vertical: 8,
  );
  static const EdgeInsets iconPadding = EdgeInsets.all(12);

  // Spacing
  static const double space4 = 4;
  static const double space6 = 6;
  static const double space8 = 8;
  static const double space10 = 10;
  static const double space12 = 12;
  static const double space14 = 14;
  static const double space16 = 16;
  static const double space18 = 18;
  static const double space20 = 20;
  static const double space24 = 24;

  // Shapes
  static const double cardRadiusValue = 18;
  static const double heroIconRadiusValue = 24;
  static const double iconRadiusValue = 16;
  static const double segmentRadiusValue = 28;
  static const BorderRadius cardRadius = BorderRadius.all(
    Radius.circular(cardRadiusValue),
  );
  static const BorderRadius heroIconRadius = BorderRadius.all(
    Radius.circular(heroIconRadiusValue),
  );
  static const BorderRadius iconRadius = BorderRadius.all(
    Radius.circular(iconRadiusValue),
  );
  static const BorderRadius segmentRadius = BorderRadius.all(
    Radius.circular(segmentRadiusValue),
  );
  static const Border cardBorder = Border.fromBorderSide(
    BorderSide(color: borderColor, width: cardBorderWidth),
  );
  static const Border segmentBorder = Border.fromBorderSide(
    BorderSide(color: borderColor, width: segmentBorderWidth),
  );
  static const Border itemDividerBorder = Border(
    bottom: BorderSide(color: dividerColor, width: dividerThickness),
  );

  // Effects
  static const LinearGradient heroGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: <Color>[primarySoftColor, backgroundColor],
  );
  static const LinearGradient selectedSegmentGradient = LinearGradient(
    begin: Alignment.centerLeft,
    end: Alignment.centerRight,
    colors: <Color>[primaryDarkColor, primaryColor],
  );
  static const List<BoxShadow> cardShadow = <BoxShadow>[
    BoxShadow(color: shadowColor, blurRadius: 18, offset: Offset(0, 6)),
  ];
  static const List<BoxShadow> selectedSegmentShadow = <BoxShadow>[
    BoxShadow(color: shadowColor, blurRadius: 10, offset: Offset(0, 3)),
  ];
  static const Duration segmentAnimationDuration = Duration(milliseconds: 220);
  static const Curve segmentAnimationCurve = Curves.easeOutCubic;

  // Icons
  static const IconData heroIcon = Icons.verified_user_rounded;
  static const IconData acceptanceIcon = Icons.description_outlined;
  static const IconData appUseIcon = Icons.phone_android_rounded;
  static const IconData responsibilityIcon = Icons.shield_outlined;
  static const IconData intellectualPropertyIcon = Icons.lock_outline_rounded;
  static const IconData liabilityIcon = Icons.warning_amber_rounded;
  static const IconData informationIcon = Icons.info_outline_rounded;
  static const IconData collectionIcon = Icons.inventory_2_outlined;
  static const IconData dataUseIcon = Icons.manage_search_rounded;
  static const IconData dataProtectionIcon = Icons.security_rounded;
  static const IconData userRightsIcon = Icons.person_outline_rounded;
  static const IconData updatesIcon = Icons.sync_rounded;

  // Icon sizes
  static const double heroIconSize = 52;
  static const double policyIconSize = 29;
  static const double noteIconSize = 32;

  // Typography
  static const TextStyle appBarTitleStyle = TextStyle(
    fontFamily: fontFamily,
    color: textPrimaryColor,
    fontSize: 20,
    fontWeight: FontWeight.w700,
    letterSpacing: -0.25,
  );
  static const TextStyle heroTitleStyle = TextStyle(
    fontFamily: fontFamily,
    color: textPrimaryColor,
    fontSize: 28,
    fontWeight: FontWeight.w800,
    height: 1.15,
    letterSpacing: -0.6,
  );
  static const TextStyle heroSubtitleStyle = TextStyle(
    fontFamily: fontFamily,
    color: primaryColor,
    fontSize: 15,
    fontWeight: FontWeight.w500,
    height: 1.5,
  );
  static const TextStyle selectedSegmentStyle = TextStyle(
    fontFamily: fontFamily,
    color: cardColor,
    fontSize: 14,
    fontWeight: FontWeight.w700,
  );
  static const TextStyle unselectedSegmentStyle = TextStyle(
    fontFamily: fontFamily,
    color: primaryColor,
    fontSize: 14,
    fontWeight: FontWeight.w700,
  );
  static const TextStyle policyTitleStyle = TextStyle(
    fontFamily: fontFamily,
    color: primaryColor,
    fontSize: 16,
    fontWeight: FontWeight.w700,
    height: 1.35,
  );
  static const TextStyle policyBodyStyle = TextStyle(
    fontFamily: fontFamily,
    color: textPrimaryColor,
    fontSize: 13.5,
    fontWeight: FontWeight.w400,
    height: 1.55,
  );
  static const TextStyle noteTitleStyle = TextStyle(
    fontFamily: fontFamily,
    color: primaryColor,
    fontSize: 14,
    fontWeight: FontWeight.w700,
  );
  static const TextStyle noteBodyStyle = TextStyle(
    fontFamily: fontFamily,
    color: textPrimaryColor,
    fontSize: 12.5,
    fontWeight: FontWeight.w400,
    height: 1.5,
  );
  static const TextStyle agreementStyle = TextStyle(
    fontFamily: fontFamily,
    color: textPrimaryColor,
    fontSize: 12.5,
    fontWeight: FontWeight.w500,
    height: 1.4,
  );
}
