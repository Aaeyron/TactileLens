import 'package:flutter/material.dart';

abstract final class ScanActionButtonStyles {
  static const Color primaryColor = Color(0xFF1268F3);
  static const Color surfaceColor = Colors.white;
  static const Color disabledColor = Color(0xFF9E9E9E);

  static const Color subtleShadowColor = Color(0x0F000000);

  static const Color captureShadowColor = Color(0x2E000000);

  static const double bottomPadding = 8;

  static const EdgeInsets horizontalPadding = EdgeInsets.symmetric(
    horizontal: 30,
  );

  static const MainAxisAlignment alignment = MainAxisAlignment.spaceBetween;

  static const CrossAxisAlignment crossAlignment = CrossAxisAlignment.end;

  static const double enabledOpacity = 1;
  static const double disabledOpacity = 0.55;

  static const Duration opacityDuration = Duration(milliseconds: 180);

  static const double secondaryButtonSize = 52;
  static const double secondaryBorderWidth = 1;
  static const double galleryIconSize = 30;

  static const Color secondaryButtonColor = surfaceColor;

  static const Color secondaryBorderColor = Color(0xFFE5E7EB);

  static const IconData galleryIcon = Icons.photo_library_outlined;

  static const double flashIconSize = 30;

  static const Color flashEnabledColor = primaryColor;

  static const Color flashDisabledColor = disabledColor;

  static const IconData flashEnabledIcon = Icons.flash_on_rounded;

  static const IconData flashDisabledIcon = Icons.flash_off_rounded;

  static const List<BoxShadow> secondaryButtonShadow = <BoxShadow>[
    BoxShadow(color: subtleShadowColor, blurRadius: 10, offset: Offset(0, 2)),
  ];

  static const double captureButtonSize = 88;
  static const double captureBorderWidth = 5;
  static const double captureIconSize = 34;

  static const Color captureIconColor = surfaceColor;

  static const IconData captureIcon = Icons.camera_alt_rounded;

  static const IconData scanIcon = Icons.document_scanner_outlined;

  static const List<BoxShadow> captureButtonShadow = <BoxShadow>[
    BoxShadow(color: captureShadowColor, blurRadius: 16, offset: Offset(0, 6)),
  ];

  static const double processingIndicatorSize = 30;

  static const double processingIndicatorStrokeWidth = 3;

  static const Color processingIndicatorColor = surfaceColor;

  static const String uploadButtonLabel = 'Upload image';

  static const String cameraButtonLabel = 'Capture image';

  static const String scanButtonLabel = 'Scan document';

  static const String processingButtonLabel = 'Scanning document';

  static const String flashButtonLabel = 'Toggle camera flash';
}
