import 'package:flutter/material.dart';

abstract final class SettingsScreenStyles {
  // ============================================================
  // CONTENT
  // ============================================================

  static const String screenTitle = 'Settings';

  static const String screenDescription =
      'Customize accessibility, scanning, recognition, and Braille '
      'preferences.';

  static const String backTooltip = 'Return to Profile';

  static const String accessibilityTitle = 'Accessibility';
  static const String scanningTitle = 'Scanning and Recognition';
  static const String brailleTitle = 'Braille Output';
  static const String resetTitle = 'Reset';

  static const String textSizeTitle = 'Text Size';
  static const String textSizeDescription =
      'Adjust the size of text displayed throughout the application.';

  static const String highContrastTitle = 'High Contrast';
  static const String highContrastDescription =
      'Increase visual contrast to make interface elements easier to read.';

  static const String reduceAnimationsTitle = 'Reduce Animations';
  static const String reduceAnimationsDescription =
      'Minimize screen transitions and movement throughout the application.';

  static const String hapticFeedbackTitle = 'Haptic Feedback';
  static const String hapticFeedbackDescription =
      'Use vibration feedback during supported actions.';

  static const String recognitionPreferenceTitle = 'Recognition Preference';

  static const String recognitionPreferenceDescription =
      'Choose between faster processing and greater recognition accuracy.';

  static const String preserveLayoutTitle = 'Preserve Document Layout';
  static const String preserveLayoutDescription =
      'Position recognized text and equations like the original document.';

  static const String autoSaveTitle = 'Automatically Save Scans';
  static const String autoSaveDescription =
      'Add successful scans to the application history automatically.';

  static const String contractedUebTitle = 'Contracted UEB';
  static const String contractedUebDescription =
      'Use contracted Unified English Braille for recognized text.';

  static const String nemethTitle = 'Nemeth Mathematics';
  static const String nemethDescription =
      'Mathematical expressions automatically use Nemeth Braille.';

  static const String automaticLabel = 'Automatic';

  static const String resetSettingsTitle = 'Reset All Settings';
  static const String resetSettingsDescription =
      'Restore every preference to its original default value.';

  static const String resetDialogTitle = 'Reset settings?';

  static const String resetDialogDescription =
      'All accessibility, scanning, recognition, and Braille preferences '
      'will return to their default values.';

  static const String cancelLabel = 'Cancel';
  static const String resetLabel = 'Reset';

  static const String defaultTextSizeLabel = 'Default';
  static const String largeTextSizeLabel = 'Large';
  static const String extraLargeTextSizeLabel = 'Extra large';

  static const String fasterRecognitionLabel = 'Faster';
  static const String accurateRecognitionLabel = 'More accurate';

  static const String loadErrorMessage = 'Unable to load your settings.';
  static const String saveErrorMessage =
      'Unable to save this preference. Please try again.';

  static const String resetSuccessMessage =
      'Settings restored to their default values.';

  static const String resetErrorMessage =
      'Unable to reset your settings. Please try again.';

  // ============================================================
  // COLORS
  // ============================================================

  static const Color primaryColor = Color(0xFF1268F3);
  static const Color primaryDarkColor = Color(0xFF0758DD);
  static const Color primarySoftColor = Color(0xFFEDF4FF);

  static const Color backgroundColor = Color(0xFFF4F7FC);
  static const Color surfaceColor = Colors.white;

  static const Color textPrimaryColor = Color(0xFF10213D);
  static const Color textSecondaryColor = Color(0xFF42526B);
  static const Color textMutedColor = Color(0xFF728096);

  static const Color outlineColor = Color(0xFFDDE5F0);
  static const Color dividerColor = Color(0xFFE5EBF3);

  static const Color switchInactiveThumbColor = Color(0xFF94A3B8);
  static const Color switchInactiveTrackColor = Color(0xFFDCE3EC);

  static const Color dangerColor = Color(0xFFD14343);
  static const Color dangerSoftColor = Color(0xFFFFEEEE);

  static const Color dialogBarrierColor = Color(0x66000000);

  // ============================================================
  // ANIMATION
  // ============================================================

  static const Duration entranceDuration = Duration(milliseconds: 420);
  static const Duration entranceDelay = Duration(milliseconds: 100);
  static const Curve entranceCurve = Curves.easeOutCubic;
  static const Offset entranceBeginOffset = Offset(0, 0.025);

  static const Duration snackBarDuration = Duration(seconds: 3);

  // ============================================================
  // HEADER
  // ============================================================

  static const double headerHorizontalPadding = 14;
  static const double headerTopPadding = 12;
  static const double headerBottomPadding = 27;

  static const double headerBackSpacing = 5;
  static const double headerTextSpacing = 15;
  static const double headerDescriptionWidth = 285;

  static const EdgeInsets headerDescriptionPadding = EdgeInsets.symmetric(
    horizontal: 5,
  );

  static const LinearGradient headerGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: <Color>[Color(0xFF1474F5), Color(0xFF0758DD)],
  );

  static const BorderRadius headerRadius = BorderRadius.only(
    bottomLeft: Radius.elliptical(190, 34),
    bottomRight: Radius.elliptical(190, 34),
  );

  static const double decorationRight = 18;
  static const double decorationBottom = 22;
  static const double decorationOpacity = 0.18;
  static const double decorationWidth = 49;
  static const double decorationDotSize = 4;
  static const double decorationDotSpacing = 7;
  static const int decorationDotCount = 12;

  static const IconData backIcon = Icons.arrow_back_rounded;
  static const double backIconSize = 25;

  static final ButtonStyle backButtonStyle = IconButton.styleFrom(
    foregroundColor: surfaceColor,
    backgroundColor: const Color(0x26FFFFFF),
    shape: const CircleBorder(),
  );

  // ============================================================
  // LAYOUT
  // ============================================================

  static const EdgeInsets contentPadding = EdgeInsets.fromLTRB(14, 18, 14, 32);

  static const double sectionSpacing = 20;
  static const double sectionTitleBottomSpacing = 10;
  static const double bottomSpacing = 24;

  // ============================================================
  // CARDS
  // ============================================================

  static const BorderRadius cardRadius = BorderRadius.all(Radius.circular(15));

  static const Border cardBorder = Border.fromBorderSide(
    BorderSide(color: outlineColor, width: 1),
  );

  static const List<BoxShadow> cardShadow = <BoxShadow>[
    BoxShadow(color: Color(0x0D102A43), blurRadius: 12, offset: Offset(0, 4)),
  ];

  static const Border itemDividerBorder = Border(
    bottom: BorderSide(color: dividerColor, width: 1),
  );

  // ============================================================
  // SETTING ITEMS
  // ============================================================

  static const EdgeInsets settingItemPadding = EdgeInsets.fromLTRB(
    15,
    15,
    13,
    15,
  );

  static const double settingContentSpacing = 13;
  static const double settingDescriptionSpacing = 5;
  static const double settingControlSpacing = 10;

  static const double iconContainerSize = 42;
  static const double iconSize = 21;

  static const BorderRadius iconContainerRadius = BorderRadius.all(
    Radius.circular(12),
  );

  static const EdgeInsets dropdownPadding = EdgeInsets.symmetric(
    horizontal: 11,
    vertical: 2,
  );

  static const BorderRadius dropdownRadius = BorderRadius.all(
    Radius.circular(10),
  );

  static const Border dropdownBorder = Border.fromBorderSide(
    BorderSide(color: outlineColor, width: 1),
  );

  static const double dropdownMaximumWidth = 145;

  // ============================================================
  // RESET
  // ============================================================

  static const EdgeInsets resetItemPadding = EdgeInsets.all(15);

  static const BorderRadius dialogRadius = BorderRadius.all(
    Radius.circular(18),
  );

  static const EdgeInsets snackBarMargin = EdgeInsets.fromLTRB(16, 0, 16, 18);

  static const BorderRadius snackBarRadius = BorderRadius.all(
    Radius.circular(12),
  );

  // ============================================================
  // ICONS
  // ============================================================

  static const IconData textSizeIcon = Icons.text_fields_rounded;
  static const IconData highContrastIcon = Icons.contrast_rounded;

  static const IconData reduceAnimationsIcon = Icons.motion_photos_off_rounded;

  static const IconData hapticFeedbackIcon = Icons.vibration_rounded;
  static const IconData recognitionIcon = Icons.speed_rounded;

  static const IconData preserveLayoutIcon = Icons.dashboard_customize_rounded;

  static const IconData autoSaveIcon = Icons.history_rounded;
  static const IconData contractedUebIcon = Icons.translate_rounded;
  static const IconData nemethIcon = Icons.functions_rounded;
  static const IconData resetIcon = Icons.restart_alt_rounded;

  // ============================================================
  // TYPOGRAPHY
  // ============================================================

  static const TextStyle headerTitleStyle = TextStyle(
    color: surfaceColor,
    fontSize: 21,
    fontWeight: FontWeight.w800,
    letterSpacing: -0.25,
  );

  static const TextStyle headerDescriptionStyle = TextStyle(
    color: Color(0xFFE9F2FF),
    fontSize: 13.5,
    height: 1.4,
    fontWeight: FontWeight.w500,
  );

  static const TextStyle sectionTitleStyle = TextStyle(
    color: textPrimaryColor,
    fontSize: 16,
    fontWeight: FontWeight.w800,
    letterSpacing: -0.15,
  );

  static const TextStyle settingTitleStyle = TextStyle(
    color: textPrimaryColor,
    fontSize: 14.5,
    fontWeight: FontWeight.w700,
  );

  static const TextStyle settingDescriptionStyle = TextStyle(
    color: textSecondaryColor,
    fontSize: 12.5,
    height: 1.4,
  );

  static const TextStyle dropdownTextStyle = TextStyle(
    color: textPrimaryColor,
    fontSize: 12.5,
    fontWeight: FontWeight.w700,
  );

  static const TextStyle informationValueStyle = TextStyle(
    color: primaryColor,
    fontSize: 12.5,
    fontWeight: FontWeight.w800,
  );

  static const TextStyle resetTitleStyle = TextStyle(
    color: dangerColor,
    fontSize: 14.5,
    fontWeight: FontWeight.w800,
  );

  static const TextStyle dialogTitleStyle = TextStyle(
    color: textPrimaryColor,
    fontSize: 19,
    fontWeight: FontWeight.w800,
  );

  static const TextStyle dialogDescriptionStyle = TextStyle(
    color: textSecondaryColor,
    fontSize: 13.5,
    height: 1.45,
  );

  static const TextStyle snackBarTextStyle = TextStyle(
    color: surfaceColor,
    fontSize: 13,
    fontWeight: FontWeight.w600,
  );
}
