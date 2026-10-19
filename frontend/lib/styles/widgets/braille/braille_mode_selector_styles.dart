import 'package:flutter/material.dart';

abstract final class BrailleModeSelectorStyles {
  // ============================================================
  // TEXT
  // ============================================================

  static const String semanticLabel = 'Braille mode';
  static const String uncontractedLabel = 'Braille 1 (Spell Out)';
  static const String contractedLabel = 'Braille 2 (Contracted)';

  static const String unsupportedPlatformNote =
      'Braille 1 is available on Android.';
  static const String noSourceTextNote = 'Braille 1 needs a newer scan.';
  static const String mathOnlyNote =
      'This scan has only math (Nemeth Braille).';
  static const String fallbackNote =
      'Braille 1 could not be created. Showing Braille 2.';
  static const String copyMenuTooltip = 'Copy text or Braille';
  static const String copyTextLabel = 'Copy text';
  static const String copyBrailleLabel = 'Copy Braille';
  static const IconData copyIcon = Icons.copy_rounded;

  static const String savedUncontractedNote =
      'Saved in Braille 1. Word pairing and switching modes are available '
      'on Android.';

  // ============================================================
  // COLORS (app palette)
  // ============================================================

  static const Color primaryColor = Color(0xFF003797);
  static const Color selectedBackgroundColor = Color(0xFFEDF3FB);
  static const Color surfaceColor = Colors.white;
  static const Color outlineColor = Color(0xFFDDE5F0);
  static const Color textColor = Color(0xFF10213D);
  static const Color mutedColor = Color(0xFF728096);

  // ============================================================
  // LAYOUT
  // ============================================================

  static const double chipSpacing = 8;
  static const double noteSpacing = 6;

  // ============================================================
  // BUTTONS (scan result and material preview)
  // ============================================================

  /// Minimum touch target.
  static const double buttonMinHeight = 48;
  static const double buttonIconSize = 18;

  static const IconData selectedIcon = Icons.check_rounded;

  static const EdgeInsets buttonPadding = EdgeInsets.symmetric(
    horizontal: 14,
    vertical: 10,
  );

  static const BorderRadius buttonRadius = BorderRadius.all(
    Radius.circular(12),
  );

  static final ButtonStyle selectedButtonStyle = FilledButton.styleFrom(
    backgroundColor: primaryColor,
    foregroundColor: surfaceColor,
    minimumSize: const Size(0, buttonMinHeight),
    padding: buttonPadding,
    shape: const RoundedRectangleBorder(borderRadius: buttonRadius),
  );

  static final ButtonStyle unselectedButtonStyle = OutlinedButton.styleFrom(
    foregroundColor: primaryColor,
    backgroundColor: surfaceColor,
    disabledForegroundColor: mutedColor,
    minimumSize: const Size(0, buttonMinHeight),
    padding: buttonPadding,
    side: const BorderSide(color: primaryColor),
    shape: const RoundedRectangleBorder(borderRadius: buttonRadius),
  );

  // ============================================================
  // TYPOGRAPHY
  // ============================================================

  static const TextStyle chipLabelStyle = TextStyle(
    fontFamily: 'Poppins',
    fontSize: 13,
    fontWeight: FontWeight.w600,
  );

  static const TextStyle noteStyle = TextStyle(
    fontFamily: 'Poppins',
    fontSize: 12,
    height: 1.35,
    color: mutedColor,
  );
}
