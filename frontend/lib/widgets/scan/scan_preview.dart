import 'dart:io';

import 'package:flutter/material.dart';

import '../../styles/widgets/scan/scan_preview_styles.dart';
import 'scan_selection_overlay.dart';

class ScanPreview extends StatelessWidget {
  const ScanPreview({
    super.key,
    required this.selectedImage,
    required this.onRegionSelected,
    required this.onSelectionCleared,
  });

  final File selectedImage;

  final void Function(Rect selectedRegion, Size previewSize) onRegionSelected;

  final VoidCallback onSelectionCleared;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      height: ScanPreviewStyles.previewHeight,
      decoration: BoxDecoration(
        color: ScanPreviewStyles.backgroundColor,
        borderRadius: ScanPreviewStyles.borderRadius,
        border: Border.all(
          color: ScanPreviewStyles.borderColor,
          width: ScanPreviewStyles.borderWidth,
        ),
      ),
      child: ClipRRect(
        borderRadius: ScanPreviewStyles.borderRadius,
        child: Stack(
          fit: StackFit.expand,
          children: <Widget>[
            Image.file(
              selectedImage,
              fit: ScanPreviewStyles.imageFit,
              width: double.infinity,
              height: double.infinity,
              gaplessPlayback: true,
              errorBuilder:
                  (BuildContext context, Object error, StackTrace? stackTrace) {
                    return const Center(
                      child: Text(
                        ScanPreviewStyles.placeholderText,
                        textAlign: TextAlign.center,
                        style: ScanPreviewStyles.placeholderStyle,
                      ),
                    );
                  },
            ),
            LayoutBuilder(
              builder: (BuildContext context, BoxConstraints constraints) {
                final Size previewSize = Size(
                  constraints.maxWidth,
                  constraints.maxHeight,
                );

                return ScanSelectionOverlay(
                  key: ValueKey<String>(selectedImage.path),
                  onRegionSelected: (Rect selectedRegion) {
                    onRegionSelected(selectedRegion, previewSize);
                  },
                  onSelectionCleared: onSelectionCleared,
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
