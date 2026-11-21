import 'package:flutter/material.dart';

import '../../screens/scan/scan_screen_styles.dart';

abstract final class ScanProgressOverlayStyles {
  // Text
  /// Until the first real step is known.
  static const String scanningLabel = 'Scanning your document…';
  static const String onlineLabel = 'Online';
  static const String onDeviceLabel = 'On this device';
  static const String stillWorkingLabel =
      'Still working, large pages take longer.';

  /// What TalkBack says when a scan starts (before the first step), and
  /// when it is done.
  static const String scanningAnnouncement = 'Scanning, please wait';
  static const String completeAnnouncement = 'Scan complete';

  // Timing
  /// After this long the "Still working" line appears.
  static const Duration stillWorkingAfter = Duration(seconds: 20);

  /// One writing cycle: the word is written, held, faded, then a short
  /// rest before it starts again.
  static const Duration writingCycle = Duration(milliseconds: 2800);

  /// Parts of the cycle (0..1): writing ends, the hold ends, the fade ends.
  static const double writePhaseEnd = 0.58;
  static const double holdPhaseEnd = 0.74;
  static const double fadePhaseEnd = 0.92;

  /// The check mark when the result is ready.
  static const Duration checkDuration = Duration(milliseconds: 320);

  // Colors: navy and gold on the scan screen's dark card.
  static const Color scrimColor = ScanScreenStyles.processingOverlayColor;
  static const Color cardColor = Color(0xE6020B16);
  static const Color cardBorderColor =
      ScanScreenStyles.activeControlBorderColor;

  /// Raised dots and the check mark (gold; about 11:1 on the card).
  static const Color raisedDotColor = Color(0xFFF2B84B);
  static const Color dotShadowColor = Color(0x66000000);

  /// Unraised positions (navy).
  static const Color emptyDotColor = Color(0x80165CC4);

  // Braille cells (a cell is 2 dots wide and 3 dots high)
  static const double dotRadius = 5;
  static const double flatDotRadius = 3;
  static const double dotSpacing = 15;
  static const double cellSpacing = 22;
  static const double dotLift = 2.5;

  // Check mark slot to the right of the cells.
  static const double checkGap = 14;
  static const double checkSize = 26;
  static const double checkStroke = 3.5;

  // Card
  static const EdgeInsets screenPadding = EdgeInsets.all(20);
  static const EdgeInsets cardPadding = EdgeInsets.fromLTRB(24, 22, 24, 20);
  static const BorderRadius cardRadius = BorderRadius.all(Radius.circular(20));
  static const double cardMaxWidth = 340;

  /// The space the old progress bar used (12 + 3 + 12), so the card keeps
  /// its layout.
  static const double cellsToTextSpacing = 27;
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
