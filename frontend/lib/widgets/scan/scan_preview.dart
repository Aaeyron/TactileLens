import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../styles/widgets/scan/scan_preview_styles.dart';
import 'scan_selection_overlay.dart';

abstract final class _ScanPreviewText {
  static const String imageLoadFailure = 'Selected image will appear here';
}

class ScanPreview extends StatelessWidget {
  const ScanPreview({
    super.key,
    required this.selectedImage,
    required this.deviceOrientation,
    required this.onRegionSelected,
    required this.onSelectionCleared,
  });

  final File selectedImage;

  final DeviceOrientation deviceOrientation;

  final void Function(Rect selectedRegion, Size previewSize) onRegionSelected;

  final VoidCallback onSelectionCleared;

  int _contentQuarterTurns() {
    return switch (deviceOrientation) {
      DeviceOrientation.portraitUp => 0,
      DeviceOrientation.landscapeLeft => 1,
      DeviceOrientation.portraitDown => 2,
      DeviceOrientation.landscapeRight => 3,
    };
  }

  @override
  Widget build(BuildContext context) {
    return RotatedBox(
      quarterTurns: _contentQuarterTurns(),
      child: DecoratedBox(
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
                key: ValueKey<String>(selectedImage.path),
                fit: ScanPreviewStyles.imageFit,
                alignment: Alignment.center,
                width: double.infinity,
                height: double.infinity,
                gaplessPlayback: true,
                filterQuality: ScanPreviewStyles.imageFilterQuality,
                errorBuilder:
                    (
                      BuildContext context,
                      Object error,
                      StackTrace? stackTrace,
                    ) {
                      return const ColoredBox(
                        color: ScanPreviewStyles.backgroundColor,
                        child: Center(
                          child: Text(
                            _ScanPreviewText.imageLoadFailure,
                            textAlign: TextAlign.center,
                            style: ScanPreviewStyles.placeholderStyle,
                          ),
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
                    key: ValueKey<String>(
                      '${selectedImage.path}-'
                      '${deviceOrientation.name}-'
                      '${previewSize.width}-'
                      '${previewSize.height}',
                    ),
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
      ),
    );
  }
}
