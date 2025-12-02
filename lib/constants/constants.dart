import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

String googleApiKey = "";

double height = 825.h;
double width = 375.w;

class AppColors {
  // Premium Dark Theme Colors
  static const Color darkBackground = Color(0xFF0a0e27); // Deep navy background
  static const Color darkSurface = Color(0xFF1a1a2e); // Slightly lighter navy
  static const Color darkText = Colors.white;
  static const Color darkTextSecondary = Color(0xFFCAD2DB);
  static const Color darkInputGray = Color(0xFF73797F);

  // Premium Sophisticated Gold (True Metallic Gold Tones)
  static const Color goldPrimary = Color(
    0xFFB8860B,
  ); // Dark goldenrod - rich, deep gold
  static const Color goldSecondary = Color(
    0xFFDAA520,
  ); // Goldenrod - classic metallic gold
  static const Color goldAccent = Color(
    0xFFCD7F32,
  ); // Bronze gold - warm metallic
  static const Color goldDark = Color(0xFF8B6914); // Deep antique gold
  static const Color goldLight = Color(
    0xFFD4AF37,
  ); // Metallic gold - true luxury gold

  // Legacy support
  static const Color grayColor = Color(0xFFCAD2DB);
  static const Color inputGrayColor = Color(0xFF73797F);
  static const Color accentColor = goldSecondary; // Use goldenrod as accent
}
