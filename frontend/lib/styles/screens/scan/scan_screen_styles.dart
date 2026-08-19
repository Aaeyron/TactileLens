import 'package:flutter/material.dart';

abstract final class ScanScreenStyles {
  // ==========================================================
  // TEXT CONTENT
  // ==========================================================

  static const String screenTitle = 'Scan Material';

  static const String screenDescription =
      'Align your document within the frame';

  static const String cameraReadyLabel = 'Ready to scan';
  static const String imageReadyLabel = 'Image ready';

  static const String cameraInstruction = 'Position the document in the frame';

  static const String imageInstruction = 'Review the image before scanning';

  static const String uploadLabel = 'Upload';
  static const String flashLabel = 'Flash';
  static const String retakeLabel = 'Retake';

  static const String captureSemanticLabel = 'Capture document';

  static const String scanSemanticLabel = 'Scan document with AI';

  static const String backTooltip = 'Go back';
  static const String helpTooltip = 'Scanning help';

  static const String helpTitle = 'Scanning tips';

  static const String helpDescription =
      'For clearer text and more accurate Braille output:';

  static const String lightingTip =
      'Use bright and even lighting without shadows.';

  static const String alignmentTip =
      'Keep the complete document inside the blue frame.';

  static const String stabilityTip =
      'Hold the device steady and keep the text in focus.';

  static const String printedMaterialTip =
      'Use clear printed text and equations whenever possible.';

  static const String closeLabel = 'Got it';

  static const String previewDialogTitle = 'Preview image to scan';

  static const String cancelLabel = 'Cancel';
  static const String sendToAiLabel = 'Send to AI';

  static const String scanFailureMessage =
      'Unable to scan the document. Please try again.';

  static const String textAndEquationHistoryTitle = 'Text and Equation Scan';

  static const String equationHistoryTitle = 'Equation Scan';

  static const String textHistoryTitle = 'Printed Text Scan';

  static const String documentHistoryTitle = 'Document Scan';

  static const String historySaveFailureMessage =
      'The scan was completed, but it could not be added to History.';

  // ==========================================================
  // COLORS
  // ==========================================================

  static const Color backgroundColor = Color(0xFF020B16);
  static const Color headerColor = Color(0xFF020B16);
  static const Color controlPanelColor = Color(0xFF020B16);

  static const Color cameraBackgroundColor = Color(0xFF111820);

  static const Color primaryColor = Color(0xFF1268F3);
  static const Color primaryDarkColor = Color(0xFF0D47A1);
  static const Color primarySoftColor = Color(0xFF94BBFF);

  static const Color surfaceColor = Colors.white;
  static const Color onPrimaryColor = Colors.white;

  static const Color primaryTextColor = Colors.white;
  static const Color secondaryTextColor = Color(0xFFD8E1ED);

  static const Color mutedTextColor = Color(0xFF9EABC0);

  static const Color translucentSurfaceColor = Color(0xC910151C);

  static const Color controlBackgroundColor = Color(0xFF17202A);

  static const Color controlBorderColor = Color(0xFF728094);

  static const Color activeControlBorderColor = Color(0xFF4C91FF);

  static const Color outsideFrameOverlayColor = Color(0x30000000);

  static const Color dialogBackgroundColor = Color(0xFFF8FBFF);

  static const Color destructiveColor = Color(0xFFE45050);

  // ==========================================================
  // HEADER
  // ==========================================================

  static const EdgeInsets headerPadding = EdgeInsets.fromLTRB(16, 14, 16, 18);

  static const double headerIconButtonSize = 48;
  static const double headerIconSize = 31;
  static const double helpIconSize = 30;
  static const double headerSideWidth = 52;

  static const double titleDescriptionSpacing = 6;

  static const TextStyle headerTitleStyle = TextStyle(
    color: primaryTextColor,
    fontSize: 24,
    height: 1.15,
    fontWeight: FontWeight.w700,
    letterSpacing: -0.3,
  );

  static const TextStyle headerDescriptionStyle = TextStyle(
    color: secondaryTextColor,
    fontSize: 14,
    height: 1.35,
    fontWeight: FontWeight.w400,
  );

  // ==========================================================
  // CAMERA PREVIEW
  // ==========================================================

  static const double frameHorizontalInset = 23;
  static const double frameVerticalInset = 66;
  static const double frameCornerLength = 47;
  static const double frameCornerWidth = 5;
  static const double frameCornerRadius = 12;

  static const double cameraOverlayTopSpacing = 24;
  static const double cameraOverlayBottomSpacing = 25;

  static const double statusIconSize = 20;
  static const double instructionIconSize = 21;

  static const double overlayHorizontalPadding = 18;
  static const double overlayVerticalPadding = 12;
  static const double overlaySpacing = 10;

  static const BorderRadius overlayRadius = BorderRadius.all(
    Radius.circular(28),
  );

  static const TextStyle statusTextStyle = TextStyle(
    color: primaryColor,
    fontSize: 14,
    fontWeight: FontWeight.w700,
  );

  static const TextStyle instructionTextStyle = TextStyle(
    color: primaryTextColor,
    fontSize: 14,
    fontWeight: FontWeight.w500,
  );

  static const List<BoxShadow> overlayShadow = <BoxShadow>[
    BoxShadow(color: Color(0x42000000), blurRadius: 14, offset: Offset(0, 6)),
  ];

  // ==========================================================
  // BOTTOM CONTROLS
  // ==========================================================

  static const EdgeInsets controlsPadding = EdgeInsets.fromLTRB(24, 20, 24, 22);

  static const double controlsHeight = 154;

  static const double sideControlSize = 72;
  static const double sideControlIconSize = 31;

  static const double captureOuterSize = 100;
  static const double captureMiddleSize = 88;
  static const double captureInnerSize = 76;
  static const double captureIconSize = 39;

  static const double controlLabelSpacing = 9;

  static const double sideControlBorderWidth = 2;
  static const double captureOuterBorderWidth = 4;
  static const double captureInnerBorderWidth = 2;

  static const TextStyle controlLabelStyle = TextStyle(
    color: primaryTextColor,
    fontSize: 14,
    fontWeight: FontWeight.w600,
  );

  static const List<BoxShadow> captureShadow = <BoxShadow>[
    BoxShadow(color: Color(0x451268F3), blurRadius: 20, offset: Offset(0, 7)),
  ];

  // ==========================================================
  // PROCESSING OVERLAY
  // ==========================================================

  static const Color processingOverlayColor = Color(0xB3000000);

  static const double processingIndicatorSize = 44;
  static const double processingIndicatorWidth = 4;

  static const String processingLabel = 'Scanning your document...';

  static const double processingLabelSpacing = 18;

  static const TextStyle processingTextStyle = TextStyle(
    color: primaryTextColor,
    fontSize: 16,
    fontWeight: FontWeight.w600,
  );

  // ==========================================================
  // HELP SHEET
  // ==========================================================

  static const EdgeInsets helpSheetPadding = EdgeInsets.fromLTRB(
    24,
    16,
    24,
    28,
  );

  static const BorderRadius helpSheetRadius = BorderRadius.vertical(
    top: Radius.circular(28),
  );

  static const double helpHandleWidth = 46;
  static const double helpHandleHeight = 5;

  static const BorderRadius helpHandleRadius = BorderRadius.all(
    Radius.circular(10),
  );

  static const Color helpHandleColor = Color(0xFFD0DAE8);

  static const double helpTitleTopSpacing = 22;
  static const double helpDescriptionSpacing = 8;
  static const double helpTipTopSpacing = 20;
  static const double helpTipSpacing = 16;
  static const double helpTipIconSize = 24;
  static const double helpTipIconSpacing = 14;
  static const double helpButtonTopSpacing = 26;
  static const double helpButtonHeight = 52;

  static const TextStyle helpTitleStyle = TextStyle(
    color: Color(0xFF07143D),
    fontSize: 22,
    fontWeight: FontWeight.w800,
  );

  static const TextStyle helpDescriptionStyle = TextStyle(
    color: Color(0xFF53648F),
    fontSize: 14,
    height: 1.4,
  );

  static const TextStyle helpTipStyle = TextStyle(
    color: Color(0xFF26375E),
    fontSize: 14,
    height: 1.4,
    fontWeight: FontWeight.w500,
  );

  static final ButtonStyle helpButtonStyle = ElevatedButton.styleFrom(
    backgroundColor: primaryColor,
    foregroundColor: onPrimaryColor,
    elevation: 0,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.all(Radius.circular(15)),
    ),
  );

  // ==========================================================
  // PREVIEW DIALOG
  // ==========================================================

  static const BorderRadius dialogRadius = BorderRadius.all(
    Radius.circular(20),
  );

  static const TextStyle dialogTitleStyle = TextStyle(
    color: Color(0xFF07143D),
    fontSize: 20,
    fontWeight: FontWeight.w700,
  );

  static final ButtonStyle sendToAiButtonStyle = TextButton.styleFrom(
    foregroundColor: primaryColor,
  );

  // ==========================================================
  // SNACKBAR
  // ==========================================================

  static const Duration snackBarDuration = Duration(seconds: 3);

  static const EdgeInsets snackBarMargin = EdgeInsets.all(16);

  static const BorderRadius snackBarRadius = BorderRadius.all(
    Radius.circular(14),
  );

  static const TextStyle snackBarTextStyle = TextStyle(
    color: primaryTextColor,
    fontSize: 14,
    fontWeight: FontWeight.w500,
  );
}
