import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../styles/widgets/scan/scan_widget_styles.dart';

class ScanSelectionOverlay extends StatefulWidget {
  const ScanSelectionOverlay({
    super.key,
    required this.onRegionSelected,
    required this.onSelectionCleared,
  });

  final ValueChanged<Rect> onRegionSelected;
  final VoidCallback onSelectionCleared;

  @override
  State<ScanSelectionOverlay> createState() =>
      _ScanSelectionOverlayState();
}

class _ScanSelectionOverlayState
    extends State<ScanSelectionOverlay> {
  Offset? _startPoint;
  Offset? _currentPoint;

  Rect? get _selectedRegion {
    final Offset? startPoint = _startPoint;
    final Offset? currentPoint = _currentPoint;

    if (startPoint == null || currentPoint == null) {
      return null;
    }

    return Rect.fromLTRB(
      math.min(startPoint.dx, currentPoint.dx),
      math.min(startPoint.dy, currentPoint.dy),
      math.max(startPoint.dx, currentPoint.dx),
      math.max(startPoint.dy, currentPoint.dy),
    );
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (
        BuildContext context,
        BoxConstraints constraints,
      ) {
        final Size overlaySize = Size(
          constraints.maxWidth,
          constraints.maxHeight,
        );

        return GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: _clearSelection,
          onPanStart: (DragStartDetails details) {
            final Offset position = _restrictToBounds(
              details.localPosition,
              overlaySize,
            );

            setState(() {
              _startPoint = position;
              _currentPoint = position;
            });
          },
          onPanUpdate: (DragUpdateDetails details) {
            if (_startPoint == null) return;

            setState(() {
              _currentPoint = _restrictToBounds(
                details.localPosition,
                overlaySize,
              );
            });
          },
          onPanEnd: (_) => _finishSelection(),
          onPanCancel: _cancelCurrentSelection,
          child: CustomPaint(
            painter: _SelectionPainter(
              selectedRegion: _selectedRegion,
            ),
            child: const SizedBox.expand(),
          ),
        );
      },
    );
  }

  Offset _restrictToBounds(
    Offset position,
    Size overlaySize,
  ) {
    return Offset(
      position.dx
          .clamp(0.0, overlaySize.width)
          .toDouble(),
      position.dy
          .clamp(0.0, overlaySize.height)
          .toDouble(),
    );
  }

  void _finishSelection() {
    final Rect? selectedRegion = _selectedRegion;

    if (selectedRegion == null ||
        selectedRegion.width <
            ScanWidgetStyles.minimumSelectionWidth ||
        selectedRegion.height <
            ScanWidgetStyles.minimumSelectionHeight) {
      _clearSelection();
      return;
    }

    widget.onRegionSelected(selectedRegion);
  }

  void _cancelCurrentSelection() {
    _clearSelection();
  }

  void _clearSelection() {
    if (_startPoint == null && _currentPoint == null) {
      widget.onSelectionCleared();
      return;
    }

    setState(() {
      _startPoint = null;
      _currentPoint = null;
    });

    widget.onSelectionCleared();
  }
}

class _SelectionPainter extends CustomPainter {
  const _SelectionPainter({
    required this.selectedRegion,
  });

  final Rect? selectedRegion;

  @override
  void paint(Canvas canvas, Size size) {
    final Rect? region = selectedRegion;

    if (region == null) return;

    final Paint fillPaint = Paint()
      ..color = ScanWidgetStyles.selectionFillColor
      ..style = PaintingStyle.fill;

    final Paint borderPaint = Paint()
      ..color = ScanWidgetStyles.selectionBorderColor
      ..style = PaintingStyle.stroke
      ..strokeWidth =
          ScanWidgetStyles.selectionBorderWidth;

    canvas.drawRect(region, fillPaint);
    canvas.drawRect(region, borderPaint);
  }

  @override
  bool shouldRepaint(
    covariant _SelectionPainter oldDelegate,
  ) {
    return oldDelegate.selectedRegion != selectedRegion;
  }
}