import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

String googleApiKey = "";

double height = 825.h;
double width = 375.w;

class AppColors {
  // Font Noir Pro Color Palette
  static const Color darkBackground = Color(0xFF111418); // Dark background
  static const Color darkSurface = Color(
    0xFF1A1F24,
  ); // Slightly lighter surface
  static const Color textPrimary = Color(
    0xFFFCFCFC,
  ); // Primary text (off-white)
  static const Color textSecondary = Color(0xFFCAD2DB); // Secondary text
  static const Color inputGray = Color(0xFF73797F); // Input gray

  // Font Noir Pro Accent Colors
  static const Color accentLight = Color(0xFFBAFFD8); // Light green/cyan
  static const Color accentBlue = Color(0xFF96DDED); // Light blue/cyan

  // Primary accent colors (using Font Noir Pro palette)
  static const Color primary = Color(0xFF96DDED); // Light blue/cyan (primary)
  static const Color primaryLight = Color(
    0xFFBAFFD8,
  ); // Light green/cyan (secondary)
  static const Color primaryDark = Color(0xFF7BC4D4); // Darker blue variant
  static const Color secondary = Color(0xFFBAFFD8); // Light green/cyan
  static const Color secondaryLight = Color(
    0xFFD4FFE8,
  ); // Lighter green variant

  // Legacy gold colors (mapped to new colors for compatibility)
  static const Color goldPrimary = Color(0xFF96DDED); // Maps to primary blue
  static const Color goldSecondary = Color(0xFFBAFFD8); // Maps to primary light
  static const Color goldAccent = Color(0xFF96DDED); // Maps to primary
  static const Color goldDark = Color(0xFF7BC4D4); // Maps to primary dark
  static const Color goldLight = Color(0xFFBAFFD8); // Maps to primary light

  // Legacy support (mapped to new colors)
  static const Color grayColor = Color(0xFFCAD2DB);
  static const Color inputGrayColor = Color(0xFF73797F);
  static const Color accentColor = primary; // Use primary blue as accent
  static const Color darkText = textPrimary; // Legacy name
  static const Color darkTextSecondary = textSecondary; // Legacy name
  static const Color darkInputGray = inputGray; // Legacy name

  // Additional colors for UI components
  static const Color darkSurfaceElevated = Color(
    0xFF252B32,
  ); // Elevated surface
  static const Color secondaryAccent = Color(0xFFBAFFD8); // Light green accent

  // Semantic colors
  static const Color success = Color(0xFF10B981); // Green for success states
  static const Color warning = Color(0xFFF59E0B); // Orange/Amber for warnings
  static const Color error = Color(0xFFEF4444); // Red for errors
  static const Color info = Color(0xFF3B82F6); // Blue for info
  static const Color neutralGray = Color(0xFF6B7280); // Neutral gray

  // Santa hat colors (special use case)
  static const Color santaRed = Color(0xFFC41E3A); // Santa hat red
  static const Color santaRedDark = Color(0xFFA01A2E); // Santa hat dark red
}
