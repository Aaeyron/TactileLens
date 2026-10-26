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
  /// One beam sweep plus the cells rising and settling.
  static const Duration loopDuration = Duration(milliseconds: 3200);

  /// The gentle pulse when the result is ready.
  static const Duration finishDuration = Duration(milliseconds: 300);

  /// After this long the "Still working" line appears.
  static const Duration stillWorkingAfter = Duration(seconds: 20);

  // Share of the loop: the beam sweeps down during [0, sweepEnd], the cells
  // hold until settleStart, then sink back during [settleStart, 1].
  static const double sweepEnd = 0.72;
  static const double settleStart = 0.88;

  // Colors: the scan screen's palette.
  static const Color scrimColor = ScanScreenStyles.processingOverlayColor;
  static const Color beamColor = Color(0xFF6FA8FF);
  static const Color beamLineColor = ScanScreenStyles.primarySoftColor;
  static const Color cardColor = Color(0xE6020B16);
  static const Color cardBorderColor =
      ScanScreenStyles.activeControlBorderColor;
  static const Color raisedDotColor = ScanScreenStyles.surfaceColor;
  static const Color dotShadowColor = Color(0x66000000);
  static const Color flatDotColor = Color(0x40D8E1ED);
  static const Color emptyDotColor = Color(0x1FD8E1ED);

  // Beam
  static const double beamHeight = 96;
  static const double beamLineHeight = 2;
  static const double beamMaxOpacity = 0.32;
  static const double beamLineOpacity = 0.7;

  // Braille cells (a cell is 2 dots wide and 3 dots high)
  static const double dotRadius = 5;
  static const double flatDotRadius = 3;
  static const double dotSpacing = 15;
  static const double cellSpacing = 22;
  static const double dotLift = 2.5;
  static const double finishPulseScale = 0.18;

  // Card
  static const EdgeInsets screenPadding = EdgeInsets.all(20);
  static const EdgeInsets cardPadding = EdgeInsets.fromLTRB(24, 22, 24, 20);
  static const BorderRadius cardRadius = BorderRadius.all(Radius.circular(20));
  static const double cardMaxWidth = 340;
  static const double cellsToTextSpacing = 18;
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
}
