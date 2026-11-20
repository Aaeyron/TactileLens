import 'package:flutter/material.dart';

import '../../screens/scan/scan_screen_styles.dart';

abstract final class ScanProgressOverlayStyles {
  // Text
  static const String scanningLabel = 'Scanning your document…';
  static const String onlineLabel = 'Online';
  static const String onDeviceLabel = 'On this device';
  static const String stillWorkingLabel =
      'Still working, large pages take longer.';

  /// What TalkBack says when a scan starts, and when it is done.
  static const String scanningAnnouncement = 'Scanning, please wait';
  static const String completeAnnouncement = 'Scan complete';

  // Timing
  /// After this long the "Still working" line appears.
  static const Duration stillWorkingAfter = Duration(seconds: 20);

  // Colors: the scan screen's palette.
  static const Color scrimColor = ScanScreenStyles.processingOverlayColor;
  static const Color cardColor = Color(0xE6020B16);
  static const Color cardBorderColor =
      ScanScreenStyles.activeControlBorderColor;
  static const Color raisedDotColor = ScanScreenStyles.surfaceColor;
  static const Color dotShadowColor = Color(0x66000000);
  static const Color emptyDotColor = Color(0x1FD8E1ED);

  // Braille cells (a cell is 2 dots wide and 3 dots high)
  static const double dotRadius = 5;
  static const double flatDotRadius = 3;
  static const double dotSpacing = 15;
  static const double cellSpacing = 22;
  static const double dotLift = 2.5;

  // Progress bar (the only moving part; hidden with reduce motion)
  static const double barHeight = 3;
  static const BorderRadius barRadius = BorderRadius.all(Radius.circular(2));
  static const Color barColor = ScanScreenStyles.primarySoftColor;
  static const Color barTrackColor = Color(0x1FD8E1ED);

  // Card
  static const EdgeInsets screenPadding = EdgeInsets.all(20);
  static const EdgeInsets cardPadding = EdgeInsets.fromLTRB(24, 22, 24, 20);
  static const BorderRadius cardRadius = BorderRadius.all(Radius.circular(20));
  static const double cardMaxWidth = 340;
  // cellsToBarSpacing + barHeight + barToTextSpacing = the old 18 between
  // the cells and the text plus the bar, so the card keeps its layout.
  static const double cellsToBarSpacing = 12;
  static const double barToTextSpacing = 12;
  static const double lineSpacing = 6;

  static const TextStyle scanningTextStyle =
      ScanScreenStyles.processingTextStyle;

  static const TextStyle modeTextStyle = TextStyle(
    color: ScanScreenStyles.secondaryTextColor,
    fontSize: 13,
    fontWeight: FontWeight.w500,
  );

  static const TextStyle stillWorkingTextStyle = TextStyle(
    color: ScanScreenStyles.mutedTextColor,
    fontSize: 13,
    fontWeight: FontWeight.w500,
  );

  // Cancel (online scans): a quiet text button with a 48 dp target.
  static const double cancelSpacing = 10;

  static final ButtonStyle cancelButtonStyle = TextButton.styleFrom(
    foregroundColor: ScanScreenStyles.surfaceColor,
    minimumSize: const Size(96, 48),
    tapTargetSize: MaterialTapTargetSize.padded,
    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
    shape: const StadiumBorder(
      side: BorderSide(color: ScanScreenStyles.activeControlBorderColor),
    ),
    textStyle: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
  );
}
