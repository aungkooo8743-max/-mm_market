import 'package:flutter/material.dart';
class AppTheme {
  static const primaryColor = Color(0xFF1565C0);
  static ThemeData get light => ThemeData(useMaterial3: true, colorScheme: ColorScheme.fromSeed(seedColor: primaryColor));
  static ThemeData get dark => ThemeData(useMaterial3: true, colorScheme: ColorScheme.fromSeed(seedColor: primaryColor, brightness: Brightness.dark));
}
