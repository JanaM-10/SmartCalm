import 'package:flutter/material.dart';

/// SmartCalm app color palette.
/// Primary/background: #01122B, Secondary/accent: #C2E7F0
class AppColors {
  AppColors._();

  static const Color primary = Color(0xFF01122B);
  static const Color secondary = Color(0xFFC2E7F0);

  /// Lighter shade for gradient top (light blue)
  static const Color gradientTop = Color(0xFFD4EEF4);
  static const Color gradientBottom = secondary;

  /// Form field background and borders
  static const Color fieldBackground = Colors.white;
  static const Color fieldBorder = Color(0xFFE0E0E0);
  static const Color labelText = Color(0xFF37474F);
  static const Color hintText = Color(0xFF9E9E9E);
  static const Color validationText = Color(0xFF757575);
  static const Color linkText = Color(0xFF01122B);
}
