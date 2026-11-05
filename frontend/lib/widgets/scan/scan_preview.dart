import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../styles/widgets/scan/scan_preview_styles.dart';
import 'scan_selection_overlay.dart';

abstract final class _ScanPreviewText {
  static const String imageLoadFailure = 'Selected image will appear here';
}

class ScanPreview extends StatefulWidget {
  const ScanPreview({
    super.key,
    required this.selectedImage,
    required this.deviceOrientation,
    required this.onRegionSelected,
    required this.onSelectionCleared,
    this.imageSize,
  });

  final File selectedImage;

  final DeviceOrientation deviceOrientation;

  final void Function(Rect selectedRegion, Size previewSize) onRegionSelected;

  final VoidCallback onSelectionCleared;

  /// The image's pixel size, when already known (tests). Otherwise it is
  /// read from the image once it is decoded.
  final Size? imageSize;

  @override
  State<ScanPreview> createState() => _ScanPreviewState();
}

class _ScanPreviewState extends State<ScanPreview> {
  Size? _decodedSize;
  ImageStream? _stream;
  ImageStreamListener? _listener;

  Size? get _imageSize => widget.imageSize ?? _decodedSize;

  @override
  void initState() {
    super.initState();
    _readImageSize();
  }

  @override
  void didUpdateWidget(ScanPreview oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (oldWidget.selectedImage.path != widget.selectedImage.path) {
      _decodedSize = null;
      _readImageSize();
    }
  }

  @override
  void dispose() {
    _stopListening();
    super.dispose();
  }

  /// The overlay needs the image's size to keep the same part of the page
  /// selected when the preview is rotated.
  void _readImageSize() {
    _stopListening();

    if (widget.imageSize != null) {
      return;
    }

    final ImageStream stream = FileImage(
      widget.selectedImage,
    ).resolve(ImageConfiguration.empty);

    final ImageStreamListener listener = ImageStreamListener(
      (ImageInfo info, bool _) {
        if (!mounted) {
          return;
        }

        setState(() {
          _decodedSize = Size(
            info.image.width.toDouble(),
            info.image.height.toDouble(),
          );
        });
        _stopListening();
      },
      onError: (Object error, StackTrace? stackTrace) {
        // Without the size, a rotation scales the crop proportionally.
        _stopListening();
      },
    );

    _stream = stream;
    _listener = listener;
    stream.addListener(listener);
  }

  void _stopListening() {
    final ImageStreamListener? listener = _listener;

    if (listener != null) {
      _stream?.removeListener(listener);
    }

    _stream = null;
    _listener = null;
  }

  int _contentQuarterTurns() {
    return switch (widget.deviceOrientation) {
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
                widget.selectedImage,
                key: ValueKey<String>(widget.selectedImage.path),
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

                  // Keyed by the image only: rotating the phone (a new
                  // orientation and preview size) keeps the teacher's crop.
                  return ScanSelectionOverlay(
                    key: ValueKey<String>(widget.selectedImage.path),
                    imageSize: _imageSize,
                    onRegionSelected: (Rect selectedRegion) {
                      widget.onRegionSelected(selectedRegion, previewSize);
                    },
                    onSelectionCleared: widget.onSelectionCleared,
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
