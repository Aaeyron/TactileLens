import 'package:flutter/material.dart';

/// A spinner while the scan screen is busy (camera starting, a capture
/// being processed). With the system "reduce motion" setting it is a still
/// hourglass instead, so nothing moves.
class ScanBusyIndicator extends StatelessWidget {
  const ScanBusyIndicator({
    super.key,
    required this.strokeWidth,
    required this.color,
  });

  final double strokeWidth;
  final Color color;

  @override
  Widget build(BuildContext context) {
    if (MediaQuery.disableAnimationsOf(context)) {
      return LayoutBuilder(
        builder: (BuildContext context, BoxConstraints constraints) {
          final double size = constraints.hasBoundedWidth
              ? constraints.maxWidth
              : 24;

          return Icon(Icons.hourglass_top_rounded, size: size, color: color);
        },
      );
    }

    return CircularProgressIndicator(strokeWidth: strokeWidth, color: color);
  }
}
