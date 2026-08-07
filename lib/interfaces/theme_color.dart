import 'package:flutter/material.dart';

/// Preset accent colors the user can pick for the app theme.
///
/// Each value carries a human-readable [label] for the settings UI and the
/// [seedColor] used to derive the Material 3 color scheme. Green is the brand
/// default and matches the original hardcoded seed.
enum ThemeColor {
  green('Green', Color(0xFF4CAF50)),
  blue('Blue', Color(0xFF2196F3)),
  purple('Purple', Color(0xFF9C27B0)),
  orange('Orange', Color(0xFFFF9800)),
  pink('Pink', Color(0xFFE91E63)),
  teal('Teal', Color(0xFF009688)),
  red('Red', Color(0xFFF44336));

  const ThemeColor(this.label, this.seedColor);

  final String label;
  final Color seedColor;
}
