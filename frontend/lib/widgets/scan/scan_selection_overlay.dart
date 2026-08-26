import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../styles/widgets/scan/scan_selection_overlay_styles.dart';

abstract final class _ScanSelectionOverlayText {
  static const String semanticLabel = 'Adjust the document crop area';

  static const String resetLabel = 'Reset';
  static const String resetTooltip = 'Reset the crop area';
}

enum _CropDragMode { move, topLeft, topRight, bottomLeft, bottomRight }

class ScanSelectionOverlay extends StatefulWidget {
  const ScanSelectionOverlay({
    super.key,
    required this.onRegionSelected,
    required this.onSelectionCleared,
  });

  final ValueChanged<Rect> onRegionSelected;
  final VoidCallback onSelectionCleared;

  @override
  State<ScanSelectionOverlay> createState() {
    return _ScanSelectionOverlayState();
  }
}

class _ScanSelectionOverlayState extends State<ScanSelectionOverlay> {
  Rect? _selectedRegion;
  Size? _overlaySize;

  _CropDragMode? _activeDragMode;

  Offset? _dragStartPoint;
  Rect? _dragStartRegion;

  bool _isAdjusting = false;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        final Size overlaySize = Size(
          constraints.maxWidth,
          constraints.maxHeight,
        );

        _scheduleRegionForSize(overlaySize);

        return Semantics(
          label: _ScanSelectionOverlayText.semanticLabel,
          child: Stack(
            fit: StackFit.expand,
            children: <Widget>[
              GestureDetector(
                behavior: HitTestBehavior.opaque,
                onPanStart: (DragStartDetails details) {
                  _startDragging(details.localPosition, overlaySize);
                },
                onPanUpdate: (DragUpdateDetails details) {
                  _updateDragging(details.localPosition, overlaySize);
                },
                onPanEnd: (_) {
                  _finishDragging();
                },
                onPanCancel: _finishDragging,
                onDoubleTap: () {
                  _resetSelection(overlaySize);
                },
                child: CustomPaint(
                  painter: _SelectionPainter(
                    selectedRegion: _selectedRegion,
                    isAdjusting: _isAdjusting,
                  ),
                  child: const SizedBox.expand(),
                ),
              ),
              Positioned(
                right: ScanSelectionOverlayStyles.resetRight,
                bottom: ScanSelectionOverlayStyles.resetBottom,
                child: _ResetCropButton(
                  onPressed: () {
                    _resetSelection(overlaySize);
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  void _scheduleRegionForSize(Size overlaySize) {
    if (overlaySize.isEmpty) {
      return;
    }

    if (_overlaySize == overlaySize && _selectedRegion != null) {
      return;
    }

    final Size? previousSize = _overlaySize;
    final Rect? previousRegion = _selectedRegion;

    _overlaySize = overlaySize;

    Rect nextRegion;

    if (previousSize != null &&
        !previousSize.isEmpty &&
        previousRegion != null) {
      nextRegion = Rect.fromLTRB(
        previousRegion.left / previousSize.width * overlaySize.width,
        previousRegion.top / previousSize.height * overlaySize.height,
        previousRegion.right / previousSize.width * overlaySize.width,
        previousRegion.bottom / previousSize.height * overlaySize.height,
      );

      nextRegion = _constrainRegion(nextRegion, overlaySize);
    } else {
      nextRegion = _createDefaultRegion(overlaySize);
    }

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) {
        return;
      }

      setState(() {
        _selectedRegion = nextRegion;
      });

      widget.onRegionSelected(nextRegion);
    });
  }

  Rect _createDefaultRegion(Size overlaySize) {
    final double maximumHorizontalInset = math.max(
      0,
      (overlaySize.width - ScanSelectionOverlayStyles.minimumSelectionWidth) /
          2,
    );

    final double maximumVerticalInset = math.max(
      0,
      (overlaySize.height - ScanSelectionOverlayStyles.minimumSelectionHeight) /
          2,
    );

    final double horizontalInset = math.min(
      ScanSelectionOverlayStyles.defaultHorizontalInset,
      maximumHorizontalInset,
    );

    final double verticalInset = math.min(
      ScanSelectionOverlayStyles.defaultVerticalInset,
      maximumVerticalInset,
    );

    return Rect.fromLTRB(
      horizontalInset,
      verticalInset,
      overlaySize.width - horizontalInset,
      overlaySize.height - verticalInset,
    );
  }

  void _startDragging(Offset position, Size overlaySize) {
    final Rect? selectedRegion = _selectedRegion;

    if (selectedRegion == null) {
      return;
    }

    final Offset restrictedPosition = _restrictToBounds(position, overlaySize);

    final _CropDragMode? dragMode = _findDragMode(
      restrictedPosition,
      selectedRegion,
    );

    if (dragMode == null) {
      return;
    }

    setState(() {
      _activeDragMode = dragMode;
      _dragStartPoint = restrictedPosition;
      _dragStartRegion = selectedRegion;
      _isAdjusting = true;
    });
  }

  void _updateDragging(Offset position, Size overlaySize) {
    final _CropDragMode? dragMode = _activeDragMode;

    final Rect? dragStartRegion = _dragStartRegion;

    final Offset? dragStartPoint = _dragStartPoint;

    if (dragMode == null || dragStartRegion == null || dragStartPoint == null) {
      return;
    }

    final Offset restrictedPosition = _restrictToBounds(position, overlaySize);

    final Rect updatedRegion;

    switch (dragMode) {
      case _CropDragMode.topLeft:
        updatedRegion = Rect.fromLTRB(
          restrictedPosition.dx.clamp(
            0,
            dragStartRegion.right -
                ScanSelectionOverlayStyles.minimumSelectionWidth,
          ),
          restrictedPosition.dy.clamp(
            0,
            dragStartRegion.bottom -
                ScanSelectionOverlayStyles.minimumSelectionHeight,
          ),
          dragStartRegion.right,
          dragStartRegion.bottom,
        );

      case _CropDragMode.topRight:
        updatedRegion = Rect.fromLTRB(
          dragStartRegion.left,
          restrictedPosition.dy.clamp(
            0,
            dragStartRegion.bottom -
                ScanSelectionOverlayStyles.minimumSelectionHeight,
          ),
          restrictedPosition.dx.clamp(
            dragStartRegion.left +
                ScanSelectionOverlayStyles.minimumSelectionWidth,
            overlaySize.width,
          ),
          dragStartRegion.bottom,
        );

      case _CropDragMode.bottomLeft:
        updatedRegion = Rect.fromLTRB(
          restrictedPosition.dx.clamp(
            0,
            dragStartRegion.right -
                ScanSelectionOverlayStyles.minimumSelectionWidth,
          ),
          dragStartRegion.top,
          dragStartRegion.right,
          restrictedPosition.dy.clamp(
            dragStartRegion.top +
                ScanSelectionOverlayStyles.minimumSelectionHeight,
            overlaySize.height,
          ),
        );

      case _CropDragMode.bottomRight:
        updatedRegion = Rect.fromLTRB(
          dragStartRegion.left,
          dragStartRegion.top,
          restrictedPosition.dx.clamp(
            dragStartRegion.left +
                ScanSelectionOverlayStyles.minimumSelectionWidth,
            overlaySize.width,
          ),
          restrictedPosition.dy.clamp(
            dragStartRegion.top +
                ScanSelectionOverlayStyles.minimumSelectionHeight,
            overlaySize.height,
          ),
        );

      case _CropDragMode.move:
        final Offset movement = restrictedPosition - dragStartPoint;

        final double horizontalMovement = movement.dx.clamp(
          -dragStartRegion.left,
          overlaySize.width - dragStartRegion.right,
        );

        final double verticalMovement = movement.dy.clamp(
          -dragStartRegion.top,
          overlaySize.height - dragStartRegion.bottom,
        );

        updatedRegion = dragStartRegion.shift(
          Offset(horizontalMovement, verticalMovement),
        );
    }

    setState(() {
      _selectedRegion = updatedRegion;
    });
  }

  void _finishDragging() {
    final Rect? selectedRegion = _selectedRegion;

    final bool wasAdjusting = _isAdjusting;

    setState(() {
      _activeDragMode = null;
      _dragStartPoint = null;
      _dragStartRegion = null;
      _isAdjusting = false;
    });

    if (wasAdjusting && selectedRegion != null) {
      widget.onRegionSelected(selectedRegion);
    }
  }

  _CropDragMode? _findDragMode(Offset position, Rect region) {
    final double touchRadius = ScanSelectionOverlayStyles.handleTouchRadius;

    if ((position - region.topLeft).distance <= touchRadius) {
      return _CropDragMode.topLeft;
    }

    if ((position - region.topRight).distance <= touchRadius) {
      return _CropDragMode.topRight;
    }

    if ((position - region.bottomLeft).distance <= touchRadius) {
      return _CropDragMode.bottomLeft;
    }

    if ((position - region.bottomRight).distance <= touchRadius) {
      return _CropDragMode.bottomRight;
    }

    if (region.contains(position)) {
      return _CropDragMode.move;
    }

    return null;
  }

  Offset _restrictToBounds(Offset position, Size overlaySize) {
    return Offset(
      position.dx.clamp(0, overlaySize.width).toDouble(),
      position.dy.clamp(0, overlaySize.height).toDouble(),
    );
  }

  Rect _constrainRegion(Rect region, Size overlaySize) {
    if (overlaySize.isEmpty) {
      return Rect.zero;
    }

    final double minimumWidth = math.min(
      ScanSelectionOverlayStyles.minimumSelectionWidth,
      overlaySize.width,
    );

    final double minimumHeight = math.min(
      ScanSelectionOverlayStyles.minimumSelectionHeight,
      overlaySize.height,
    );

    final double width = region.width
        .clamp(minimumWidth, overlaySize.width)
        .toDouble();

    final double height = region.height
        .clamp(minimumHeight, overlaySize.height)
        .toDouble();

    final double left = region.left
        .clamp(0.0, overlaySize.width - width)
        .toDouble();

    final double top = region.top
        .clamp(0.0, overlaySize.height - height)
        .toDouble();

    return Rect.fromLTWH(left, top, width, height);
  }

  void _resetSelection(Size overlaySize) {
    if (overlaySize.isEmpty) {
      widget.onSelectionCleared();
      return;
    }

    final Rect defaultRegion = _createDefaultRegion(overlaySize);

    setState(() {
      _selectedRegion = defaultRegion;
      _activeDragMode = null;
      _dragStartPoint = null;
      _dragStartRegion = null;
      _isAdjusting = false;
    });

    widget.onRegionSelected(defaultRegion);
  }
}

class _ResetCropButton extends StatelessWidget {
  const _ResetCropButton({required this.onPressed});

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: _ScanSelectionOverlayText.resetTooltip,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onPressed,
          borderRadius: ScanSelectionOverlayStyles.resetButtonRadius,
          child: Container(
            padding: ScanSelectionOverlayStyles.resetButtonPadding,
            decoration: const BoxDecoration(
              color: ScanSelectionOverlayStyles.resetBackgroundColor,
              borderRadius: ScanSelectionOverlayStyles.resetButtonRadius,
              boxShadow: ScanSelectionOverlayStyles.resetButtonShadow,
            ),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                Icon(
                  Icons.refresh_rounded,
                  size: ScanSelectionOverlayStyles.resetIconSize,
                  color: ScanSelectionOverlayStyles.resetForegroundColor,
                ),
                SizedBox(width: ScanSelectionOverlayStyles.resetIconSpacing),
                Text(
                  _ScanSelectionOverlayText.resetLabel,
                  style: ScanSelectionOverlayStyles.resetButtonTextStyle,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _SelectionPainter extends CustomPainter {
  const _SelectionPainter({
    required this.selectedRegion,
    required this.isAdjusting,
  });

  final Rect? selectedRegion;
  final bool isAdjusting;

  @override
  void paint(Canvas canvas, Size size) {
    final Rect? region = selectedRegion;

    if (region == null) {
      return;
    }

    _drawOutsideMask(canvas, size, region);
    _drawCropBorder(canvas, region);
    _drawGrid(canvas, region);
    _drawCorners(canvas, region);
    _drawHandles(canvas, region);
  }

  void _drawOutsideMask(Canvas canvas, Size size, Rect region) {
    final Path maskPath = Path()
      ..fillType = PathFillType.evenOdd
      ..addRect(Offset.zero & size)
      ..addRRect(
        RRect.fromRectAndRadius(
          region,
          const Radius.circular(ScanSelectionOverlayStyles.cropCornerRadius),
        ),
      );

    final Paint maskPaint = Paint()
      ..color = ScanSelectionOverlayStyles.outsideMaskColor
      ..style = PaintingStyle.fill;

    canvas.drawPath(maskPath, maskPaint);
  }

  void _drawCropBorder(Canvas canvas, Rect region) {
    final Paint borderPaint = Paint()
      ..color = ScanSelectionOverlayStyles.cropBorderColor
      ..strokeWidth = ScanSelectionOverlayStyles.cropBorderWidth
      ..style = PaintingStyle.stroke;

    canvas.drawRRect(
      RRect.fromRectAndRadius(
        region,
        const Radius.circular(ScanSelectionOverlayStyles.cropCornerRadius),
      ),
      borderPaint,
    );
  }

  void _drawGrid(Canvas canvas, Rect region) {
    final Paint gridPaint = Paint()
      ..color = ScanSelectionOverlayStyles.gridColor
      ..strokeWidth = ScanSelectionOverlayStyles.gridStrokeWidth
      ..style = PaintingStyle.stroke;

    final int divisionCount = ScanSelectionOverlayStyles.gridDivisionCount;

    for (int index = 1; index < divisionCount; index++) {
      final double horizontalPosition =
          region.left + region.width * index / divisionCount;

      final double verticalPosition =
          region.top + region.height * index / divisionCount;

      canvas.drawLine(
        Offset(horizontalPosition, region.top),
        Offset(horizontalPosition, region.bottom),
        gridPaint,
      );

      canvas.drawLine(
        Offset(region.left, verticalPosition),
        Offset(region.right, verticalPosition),
        gridPaint,
      );
    }
  }

  void _drawCorners(Canvas canvas, Rect region) {
    final Paint cornerPaint = Paint()
      ..color = ScanSelectionOverlayStyles.primaryColor
      ..strokeWidth = ScanSelectionOverlayStyles.cornerStrokeWidth
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..style = PaintingStyle.stroke;

    final double length = ScanSelectionOverlayStyles.cornerLength;

    final Path path = Path()
      ..moveTo(region.left, region.top + length)
      ..lineTo(region.left, region.top)
      ..lineTo(region.left + length, region.top)
      ..moveTo(region.right - length, region.top)
      ..lineTo(region.right, region.top)
      ..lineTo(region.right, region.top + length)
      ..moveTo(region.left, region.bottom - length)
      ..lineTo(region.left, region.bottom)
      ..lineTo(region.left + length, region.bottom)
      ..moveTo(region.right - length, region.bottom)
      ..lineTo(region.right, region.bottom)
      ..lineTo(region.right, region.bottom - length);

    canvas.drawPath(path, cornerPaint);
  }

  void _drawHandles(Canvas canvas, Rect region) {
    final Paint fillPaint = Paint()
      ..color = ScanSelectionOverlayStyles.handleFillColor
      ..style = PaintingStyle.fill;

    final Paint borderPaint = Paint()
      ..color = ScanSelectionOverlayStyles.handleBorderColor
      ..strokeWidth = ScanSelectionOverlayStyles.handleBorderWidth
      ..style = PaintingStyle.stroke;

    final List<Offset> handles = <Offset>[
      region.topLeft,
      region.topRight,
      region.bottomLeft,
      region.bottomRight,
    ];

    for (final Offset handle in handles) {
      canvas.drawCircle(
        handle,
        ScanSelectionOverlayStyles.handleRadius,
        fillPaint,
      );

      canvas.drawCircle(
        handle,
        ScanSelectionOverlayStyles.handleRadius,
        borderPaint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _SelectionPainter oldDelegate) {
    return oldDelegate.selectedRegion != selectedRegion ||
        oldDelegate.isAdjusting != isAdjusting;
  }
}
