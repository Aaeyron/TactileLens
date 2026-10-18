import 'package:flutter/material.dart';

abstract final class SkeletonStyles {
  // ==========================================================
  // SHIMMER
  // ==========================================================

  /// One sweep of the highlight from left to right.
  static const Duration shimmerDuration = Duration(milliseconds: 1400);

  /// Half-width of the highlight band, as a fraction of each shape.
  static const double shimmerBandHalfWidth = 0.35;

  // ==========================================================
  // SHAPES
  // ==========================================================

  static const BorderRadius lineRadius = BorderRadius.all(Radius.circular(5));

  /// Vertical inset of a text bar inside its line, as a fraction of the
  /// font size, so the bar looks like text rather than a full block.
  static const double lineInsetFactor = 0.18;

  static const double fallbackFontSize = 14;
}
