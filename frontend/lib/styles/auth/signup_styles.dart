import 'package:flutter/material.dart';

class SignUpStyles {

  // Colors

  static const Color backgroundColor = Colors.white;

  static const Color titleColor = Colors.black;

  static const Color descriptionColor = Colors.grey;

  // Padding

  static const EdgeInsets pagePadding = EdgeInsets.symmetric(
    horizontal: 24,
    vertical: 16,
  );

  // Text Styles

  static const TextStyle titleStyle = TextStyle(
    fontSize: 30,
    fontWeight: FontWeight.bold,
    color: titleColor,
  );

  static const TextStyle descriptionStyle = TextStyle(
    fontSize: 16,
    color: descriptionColor,
    height: 1.5,
  );

}