import 'package:flutter/material.dart';

abstract final class ScanPreviewStyles {
  // Preview dimensions
  static const double portraitPreviewHeight = 500;
  static const double landscapePreviewHeight = 280;

  // Preview appearance
  static const Color backgroundColor = Color(0xFF111820);
  static const Color borderColor = Colors.transparent;

  static const double borderWidth = 0;

  static const BorderRadius borderRadius = BorderRadius.zero;

  /*
   * Keep this synchronized with the cover-scaling calculation in
   * ScanScreen._mapPreviewRegionToImage().
   */
  static const BoxFit imageFit = BoxFit.cover;

  static const FilterQuality imageFilterQuality = FilterQuality.medium;

  // Placeholder
  static const Color placeholderColor = Color(0xFFD8E1ED);

  static const TextStyle placeholderStyle = TextStyle(
    color: placeholderColor,
    fontSize: 15,
    fontWeight: FontWeight.w500,
  );
}
