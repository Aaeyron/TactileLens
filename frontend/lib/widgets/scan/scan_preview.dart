import 'dart:io';

import 'package:flutter/material.dart';

import '../../styles/widgets/scan/scan_widget_styles.dart';
import 'scan_selection_overlay.dart';

class ScanPreview extends StatelessWidget {
  const ScanPreview({
    super.key,
    required this.selectedImage,
    required this.onRegionSelected,
    required this.onSelectionCleared,
  });

  final File selectedImage;

  final void Function(
    Rect selectedRegion,
    Size previewSize,
  ) onRegionSelected;

  final VoidCallback onSelectionCleared;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      height: ScanWidgetStyles.previewHeight,
      decoration: BoxDecoration(
        color: ScanWidgetStyles.previewBackgroundColor,
        borderRadius:
            ScanWidgetStyles.previewBorderRadius,
        border: Border.all(
          color: ScanWidgetStyles.previewBorderColor,
          width: ScanWidgetStyles.previewBorderWidth,
        ),
      ),
      child: ClipRRect(
        borderRadius:
            ScanWidgetStyles.previewBorderRadius,
        child: Stack(
          fit: StackFit.expand,
          children: <Widget>[
            Image.file(
              selectedImage,
              fit: ScanWidgetStyles.previewImageFit,
              width: double.infinity,
              height: double.infinity,
              gaplessPlayback: true,
              errorBuilder: (
                BuildContext context,
                Object error,
                StackTrace? stackTrace,
              ) {
                return const Center(
                  child: Text(
                    ScanWidgetStyles.previewPlaceholderText,
                    style:
                        ScanWidgetStyles.previewPlaceholderStyle,
                  ),
                );
              },
            ),
            LayoutBuilder(
              builder: (
                BuildContext context,
                BoxConstraints constraints,
              ) {
                final Size previewSize = Size(
                  constraints.maxWidth,
                  constraints.maxHeight,
                );

                return ScanSelectionOverlay(
                  key: ValueKey<String>(selectedImage.path),
                  onRegionSelected: (Rect selectedRegion) {
                    onRegionSelected(
                      selectedRegion,
                      previewSize,
                    );
                  },
                  onSelectionCleared:
                      onSelectionCleared,
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}