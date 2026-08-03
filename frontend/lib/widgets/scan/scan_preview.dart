import 'dart:io';

import 'package:flutter/material.dart';
import '../../styles/widgets/scan/scan_widget_styles.dart';
import 'scan_selection_overlay.dart';

class ScanPreview extends StatelessWidget {
  final File? selectedImage;
  
  final void Function(
  Rect selectedRegion,
  Size previewSize,
) onRegionSelected;

  const ScanPreview({
  super.key,
  required this.selectedImage,
  required this.onRegionSelected,
});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      height: ScanWidgetStyles.previewHeight,

      decoration: BoxDecoration(
        color: ScanWidgetStyles.previewBackgroundColor,
        borderRadius: ScanWidgetStyles.previewBorderRadius,
        border: Border.all(
          color: ScanWidgetStyles.previewBorderColor,
          width: ScanWidgetStyles.previewBorderWidth,
        ),
      ),

      child: selectedImage == null
          ? const Center(
              child: Text(
                ScanWidgetStyles.previewPlaceholderText,
                style: ScanWidgetStyles.previewPlaceholderStyle,
              ),
            )
          : ClipRRect(
        borderRadius:
            ScanWidgetStyles.previewBorderRadius,
        child: Stack(
          fit: StackFit.expand,
          children: [
              Image.file(
                selectedImage!,
                fit: BoxFit.cover,
              ),
              LayoutBuilder(
              builder: (context, constraints) {
                return ScanSelectionOverlay(
                  onRegionSelected: (rect) {
                    onRegionSelected(
                      rect,
                      Size(
                        constraints.maxWidth,
                        constraints.maxHeight,
                      ),
                    );
                  },
                );
              },
            ),
          ],
        ),
      )
    );
  }
}