import 'package:flutter/material.dart';

import '../../styles/widgets/scan/scan_widget_styles.dart';

class ScanActionButton extends StatelessWidget {
final bool hasCapturedImage;
final VoidCallback onCameraPressed;
final VoidCallback onScanPressed;
final VoidCallback onUploadPressed;
final VoidCallback onFlashPressed; 
final bool flashEnabled;

 const ScanActionButton({
  super.key,
  required this.hasCapturedImage,
  required this.onCameraPressed,
  required this.onScanPressed,
  required this.onUploadPressed,
  required this.onFlashPressed,
  required this.flashEnabled,
});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(
        bottom: ScanWidgetStyles.actionButtonBottomPadding,
          ),

     child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 30),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [

            // Upload Button
            GestureDetector(
              onTap: onUploadPressed,
              child: Container(
                width: ScanWidgetStyles.galleryButtonSize,
                height: ScanWidgetStyles.galleryButtonSize,
                decoration: BoxDecoration(
                  color: ScanWidgetStyles.galleryBackgroundColor,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: ScanWidgetStyles.galleryBorderColor,
                    width: ScanWidgetStyles.galleryBorderWidth,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.06),
                      blurRadius: 10,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: const Icon(
                  ScanWidgetStyles.galleryButtonIcon,
                  size: ScanWidgetStyles.galleryIconSize,
                  color: ScanWidgetStyles.primaryBlue,
                ),
              ),
            ),

            const Expanded(child: SizedBox()),

            // Camera Button (perfectly centered)
            GestureDetector(
              onTap: hasCapturedImage ? onScanPressed : onCameraPressed,
              child: Container(
                width: ScanWidgetStyles.captureButtonSize,
                height: ScanWidgetStyles.captureButtonSize,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: ScanWidgetStyles.primaryBlue,
                  border: Border.all(
                    color: ScanWidgetStyles.galleryBackgroundColor,
                    width: ScanWidgetStyles.captureBorderWidth,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.18),
                      blurRadius: 16,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: Center(
                  child: Icon(
                    hasCapturedImage
                        ? ScanWidgetStyles.scanButtonIcon
                        : ScanWidgetStyles.captureButtonIcon,
                    color: ScanWidgetStyles.captureIconColor,
                    size: ScanWidgetStyles.captureIconSize,
                  ),
                ),
              ),
            ),

            const Expanded(child: SizedBox()),

            // Flash Button
            GestureDetector(
              onTap: onFlashPressed,
              child: Container(
                width: ScanWidgetStyles.galleryButtonSize,
                height: ScanWidgetStyles.galleryButtonSize,
                decoration: BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: ScanWidgetStyles.galleryBorderColor,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.06),
                      blurRadius: 10,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Icon(
                  flashEnabled
                      ? Icons.flash_on_rounded
                      : Icons.flash_off_rounded,
                  color: flashEnabled
                      ? ScanWidgetStyles.primaryBlue
                      : Colors.grey,
                  size: 30,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}