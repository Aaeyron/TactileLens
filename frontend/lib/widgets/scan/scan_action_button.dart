import 'package:flutter/material.dart';

import '../../styles/widgets/scan/scan_widget_styles.dart';

class ScanActionButton extends StatelessWidget {
final bool hasCapturedImage;
final VoidCallback onCameraPressed;
final VoidCallback onScanPressed;
final VoidCallback onUploadPressed;

 const ScanActionButton({
  super.key,
  required this.hasCapturedImage,
  required this.onCameraPressed,
  required this.onScanPressed,
  required this.onUploadPressed,
});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(
        bottom: ScanWidgetStyles.actionButtonBottomPadding,
          ),

      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [

          // ============================================================
          // Upload Button (Left)
          // ============================================================

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
                  color: Colors.black.withOpacity(0.06),
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

          const Spacer(),

            // ============================================================
            // Camera Capture Button (Center)
            // ============================================================

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
                      color: Colors.black.withOpacity(0.18),
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

            const Spacer(),

          // ============================================================
          // Empty Space (Right)
          // Keeps the capture button perfectly centered.
          // ============================================================

          const SizedBox(
           width: ScanWidgetStyles.galleryButtonSize,
          ),
        ],
      ),
    );
  }
}