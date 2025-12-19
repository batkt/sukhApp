import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

String googleApiKey = "";

double height = 825.h;
double width = 375.w;

class AppColors {
  // Deep Green Primary Colors
  static const Color deepGreen = Color(0xFF0D4F3C); // Deep green primary
  static const Color deepGreenDark = Color(0xFF0A3D2E); // Darker deep green
  static const Color deepGreenLight = Color(0xFF1A6B55); // Lighter deep green
  static const Color deepGreenAccent = Color(0xFF2D8F6F); // Accent green

  // Dark Mode Colors - Modern dark theme with deep green accents
  static const Color darkBackground = Color(0xFF0F1419); // Rich dark background
  static const Color darkSurface = Color(0xFF1A1F26); // Elevated dark surface
  static const Color darkTextPrimary = Color(0xFFF5F7FA); // Soft white text
  static const Color darkTextSecondary = Color(0xFFA0AEC0); // Muted gray text
  static const Color darkInputGray = Color(0xFF4A5568); // Dark input gray
  static const Color darkSurfaceElevated = Color(
    0xFF252B35,
  ); // Elevated dark surface

  // Dark mode complementary colors
  static const Color darkAccentBackground = Color(
    0xFF0D1F1A,
  ); // Dark green tint
  static const Color darkBorderColor = Color(0xFF2D3748); // Subtle dark border

  // Light Mode Colors - Modern minimal design with deep green complement
  static const Color lightBackground = Color(
    0xFFFFFFFF,
  ); // Pure white background
  static const Color lightSurface = Color(
    0xFFFAFAFA,
  ); // Very subtle gray surface
  static const Color lightTextPrimary = Color(0xFF1A1A1A); // Near black text
  static const Color lightTextSecondary = Color(0xFF2D3748); // Darker gray text for better visibility
  static const Color lightInputGray = Color(
    0xFFCBD5E0,
  ); // Light border/input gray - darker for better visibility
  static const Color lightSurfaceElevated = Color(
    0xFFF7F7F7,
  ); // Subtle elevated surface

  // Complementary colors for deep green (modern palette)
  static const Color lightAccentBackground = Color(
    0xFFF0F9F6,
  ); // Very light green tint
  static const Color lightBorderColor = Color(
    0xFFE8EDEB,
  ); // Subtle green-gray border

  // Theme-aware getters (will be used with Theme extension)
  static Color getBackground(bool isDark) =>
      isDark ? darkBackground : lightBackground;
  static Color getSurface(bool isDark) => isDark ? darkSurface : lightSurface;
  static Color getTextPrimary(bool isDark) =>
      isDark ? darkTextPrimary : lightTextPrimary;
  static Color getTextSecondary(bool isDark) =>
      isDark ? darkTextSecondary : lightTextSecondary;
  static Color getInputGray(bool isDark) =>
      isDark ? darkInputGray : lightInputGray;
  static Color getSurfaceElevated(bool isDark) =>
      isDark ? darkSurfaceElevated : lightSurfaceElevated;

  // Primary accent colors (Deep Green)
  static const Color primary = deepGreen; // Deep green primary
  static const Color primaryLight = deepGreenLight; // Lighter deep green
  static const Color primaryDark = deepGreenDark; // Darker deep green
  static const Color secondary = deepGreenAccent; // Accent green
  static const Color secondaryLight = Color(0xFF4DB896); // Lighter accent
  static const Color secondaryAccent = deepGreenAccent; // Accent green

  // Legacy gold colors (mapped to deep green for compatibility)
  static const Color goldPrimary = deepGreen; // Maps to deep green
  static const Color goldSecondary = deepGreenAccent; // Maps to accent
  static const Color goldAccent = deepGreen; // Maps to deep green
  static const Color goldDark = deepGreenDark; // Maps to dark green
  static const Color goldLight = deepGreenLight; // Maps to light green

  // Legacy support (mapped to new colors)
  static const Color grayColor = Color(0xFFCAD2DB);
  static const Color inputGrayColor = Color(0xFF73797F);
  static const Color inputGray =
      darkInputGray; // Backward compatibility - defaults to dark
  static const Color accentColor = primary; // Use deep green as accent
  static const Color darkText = darkTextPrimary; // Legacy name
  static const Color textPrimary = darkTextPrimary; // Legacy name
  static const Color textSecondary = darkTextSecondary; // Legacy name

  // Semantic colors
  static const Color success = Color(0xFF10B981); // Green for success states
  static const Color warning = Color(0xFFF59E0B); // Orange/Amber for warnings
  static const Color error = Color(0xFFEF4444); // Red for errors
  static const Color info = Color(0xFF3B82F6); // Blue for info
  static const Color neutralGray = Color(0xFF6B7280); // Neutral gray

  // Santa hat colors (special use case)
  static const Color santaRed = Color(0xFFC41E3A); // Santa hat red
  static const Color santaRedDark = Color(0xFFA01A2E); // Santa hat dark red

  // Gradient colors for backgrounds
  static List<Color> getGradientColors(bool isDark) {
    if (isDark) {
      return [
        const Color(0xFF000000), // Black
        const Color(0xFF0A1F1A), // Dark deep green
        const Color(0xFF0D4F3C), // Deep green
        const Color(0xFF1A3A4A), // Dark blue-green
        const Color(0xFF0F1419), // Dark background
      ];
    } else {
      return [
        const Color(0xFFFFFFFF), // White
        const Color(0xFFF0F9F6), // Very light green tint
        const Color(0xFFE8F4F0), // Light green
        const Color(0xFFE0F0F5), // Light blue-green
        const Color(0xFFFFFFFF), // White
      ];
    }
  }

  // Theme-aware deepGreen color (darker for light mode, lighter for dark mode)
  static Color getDeepGreen(bool isDark) {
    return isDark ? deepGreenLight : deepGreen; // Lighter green for dark mode, standard for light mode
  }
}
