import 'package:flutter/material.dart';

abstract final class ScanUploadAreaStyles {
  static const Color primaryColor = Color(0xFF1268F3);

  static const double height = 180;

  static const Color backgroundColor = Color(0xFFF1F5F9);

  static const BorderRadius borderRadius = BorderRadius.all(
    Radius.circular(18),
  );

  static const IconData icon = Icons.document_scanner_outlined;

  static const double iconSize = 60;
  static const Color iconColor = primaryColor;
}
