import 'dart:math';
import 'package:flutter/material.dart';

class ScanSelectionOverlay extends StatefulWidget {
  final ValueChanged<Rect> onRegionSelected;

  const ScanSelectionOverlay({
    super.key,
    required this.onRegionSelected,
  });

  @override
  State<ScanSelectionOverlay> createState() =>
      _ScanSelectionOverlayState();
}

class _ScanSelectionOverlayState
    extends State<ScanSelectionOverlay> {

  Offset? _startPoint;
  Offset? _currentPoint;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onPanStart: (details) {
        setState(() {
          _startPoint = details.localPosition;
          _currentPoint = details.localPosition;
        });
      },

      onPanUpdate: (details) {
        setState(() {
          _currentPoint = details.localPosition;
        });
      },
            onPanEnd: (_) {
        if (_startPoint == null || _currentPoint == null) {
          return;
        }

        final Rect selectedRegion = Rect.fromLTRB(
          min(_startPoint!.dx, _currentPoint!.dx),
          min(_startPoint!.dy, _currentPoint!.dy),
          max(_startPoint!.dx, _currentPoint!.dx),
          max(_startPoint!.dy, _currentPoint!.dy),
        );

        widget.onRegionSelected(selectedRegion);
      },
      
      child: CustomPaint(
        painter: _SelectionPainter(
          startPoint: _startPoint,
          currentPoint: _currentPoint,
        ),
        child: Container(
          color: Colors.transparent,
        ),
      ),
    );
  }
}

// ============================================================
// Selection Painter
// ============================================================

class _SelectionPainter extends CustomPainter {

  final Offset? startPoint;
  final Offset? currentPoint;

  _SelectionPainter({
    required this.startPoint,
    required this.currentPoint,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (startPoint == null || currentPoint == null) {
      return;
    }

    final rect = Rect.fromLTRB(
      min(startPoint!.dx, currentPoint!.dx),
      min(startPoint!.dy, currentPoint!.dy),
      max(startPoint!.dx, currentPoint!.dx),
      max(startPoint!.dy, currentPoint!.dy),
    );

    final fillPaint = Paint()
      ..color = Colors.blue.withValues(alpha: 0.15);

    final borderPaint = Paint()
      ..color = Colors.blue
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;

    canvas.drawRect(rect, fillPaint);
    canvas.drawRect(rect, borderPaint);
  }

  @override
  bool shouldRepaint(covariant _SelectionPainter oldDelegate) {
    return true;
  }
}