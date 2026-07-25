import 'package:flutter/material.dart';

import '../../styles/widgets/scan/scan_widget_styles.dart';

class ScanActionButtons extends StatelessWidget {
  final VoidCallback onCameraPressed;
  final VoidCallback onUploadPressed;

  const ScanActionButtons({
    super.key,
    required this.onCameraPressed,
    required this.onUploadPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [

        Expanded(
          child: SizedBox(
           height: ScanWidgetStyles.buttonHeight,
            child: ElevatedButton.icon(
              onPressed: onCameraPressed,
              icon: const Icon(
                ScanWidgetStyles.cameraButtonIcon,
              ),
              label: const Text(
                ScanWidgetStyles.cameraButtonText,
              ),
            ),
          ),
        ),

        const SizedBox(
          width: ScanWidgetStyles.buttonSpacing,
        ),

        Expanded(
          child: SizedBox(
           height: ScanWidgetStyles.buttonHeight,
            child: ElevatedButton.icon(
              onPressed: onUploadPressed,
              icon: const Icon(
                ScanWidgetStyles.uploadButtonIcon,
              ),
              label: const Text(
                ScanWidgetStyles.uploadButtonText,
              ),
            ),
          ),
        ),
      ],
    );
  }
}