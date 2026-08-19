import 'package:flutter/material.dart';

abstract final class ScanPreviewStyles {
  static const double previewHeight = 500;

  static const Color backgroundColor = Color(0xFF111820);

  static const Color borderColor = Colors.transparent;

  static const double borderWidth = 0;

  static const BorderRadius borderRadius = BorderRadius.zero;

  static const BoxFit imageFit = BoxFit.cover;

  static const String placeholderText = 'Selected image will appear here';

  static const Color placeholderColor = Color(0xFFD8E1ED);

  static const TextStyle placeholderStyle = TextStyle(
    color: placeholderColor,
    fontSize: 15,
    fontWeight: FontWeight.w500,
  );
}
