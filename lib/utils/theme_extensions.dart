import 'package:flutter/material.dart';
import 'package:sukh_app/constants/constants.dart';
import 'package:sukh_app/utils/responsive_helper.dart';

extension ThemeColors on BuildContext {
  bool get isDarkMode => Theme.of(this).brightness == Brightness.dark;

  Color get backgroundColor =>
      isDarkMode ? AppColors.darkBackground : AppColors.lightBackground;

  Color get surfaceColor =>
      isDarkMode ? AppColors.darkSurface : AppColors.lightSurface;

  Color get textPrimaryColor =>
      isDarkMode ? AppColors.darkTextPrimary : AppColors.lightTextPrimary;

  Color get textSecondaryColor =>
      isDarkMode ? AppColors.darkTextSecondary : AppColors.lightTextSecondary;

  Color get inputGrayColor =>
      isDarkMode ? AppColors.darkInputGray : AppColors.lightInputGray;

  Color get surfaceElevatedColor => isDarkMode
      ? AppColors.darkSurfaceElevated
      : AppColors.lightSurfaceElevated;

  // Helper for white/black text based on theme
  Color get adaptiveTextColor =>
      isDarkMode ? AppColors.darkTextPrimary : AppColors.lightTextPrimary;

  // Helper for surface colors with opacity
  Color get surfaceColorWithOpacity =>
      isDarkMode ? Colors.white.withOpacity(0.03) : AppColors.lightSurface;

  // Helper for border colors (modern minimal design)
  Color get borderColor =>
      isDarkMode ? AppColors.darkBorderColor : AppColors.lightBorderColor;

  // Helper for card/container background
  Color get cardBackgroundColor =>
      isDarkMode ? AppColors.darkSurface : AppColors.lightSurface;

  // Helper for accent background (subtle green tint)
  Color get accentBackgroundColor => isDarkMode
      ? AppColors.darkAccentBackground
      : AppColors.lightAccentBackground;
}

/// Extension for consistent text styles across the app
extension AppTextStyles on BuildContext {
  /// Standard title text style - consistent across all pages
  TextStyle titleStyle({Color? color, FontWeight? fontWeight}) {
    return TextStyle(
      fontFamily: 'Inter',
      fontSize: responsiveFontSize(
        small: 20,
        medium: 22,
        large: 24,
        tablet: 26,
      ),
      fontWeight: fontWeight ?? FontWeight.bold,
      color: color ?? textPrimaryColor,
    );
  }

  /// Standard description text style - consistent across all pages
  TextStyle descriptionStyle({Color? color, FontWeight? fontWeight}) {
    return TextStyle(
      fontFamily: 'Inter',
      fontSize: responsiveFontSize(
        small: 14,
        medium: 15,
        large: 16,
        tablet: 17,
      ),
      fontWeight: fontWeight ?? FontWeight.normal,
      color: color ?? textPrimaryColor,
      height: 1.4,
    );
  }

  /// Secondary description text style (for less important text)
  TextStyle secondaryDescriptionStyle({Color? color, FontWeight? fontWeight}) {
    return TextStyle(
      fontFamily: 'Inter',
      fontSize: responsiveFontSize(
        small: 13,
        medium: 14,
        large: 15,
        tablet: 16,
      ),
      fontWeight: fontWeight ?? FontWeight.normal,
      color: color ?? textSecondaryColor,
      height: 1.4,
    );
  }

  /// Large title style (for main headings)
  TextStyle largeTitleStyle({Color? color, FontWeight? fontWeight}) {
    return TextStyle(
      fontFamily: 'Inter',
      fontSize: responsiveFontSize(
        small: 24,
        medium: 26,
        large: 28,
        tablet: 30,
      ),
      fontWeight: fontWeight ?? FontWeight.bold,
      color: color ?? textPrimaryColor,
    );
  }

  /// Expanded section text style (bigger text for expanded sections)
  TextStyle expandedTextStyle({Color? color, FontWeight? fontWeight}) {
    return TextStyle(
      fontFamily: 'Inter',
      fontSize: responsiveFontSize(
        small: 16,
        medium: 17,
        large: 18,
        tablet: 19,
      ),
      fontWeight: fontWeight ?? FontWeight.normal,
      color: color ?? textPrimaryColor,
      height: 1.5,
    );
  }

  /// Expanded section title style (for labels in expanded sections)
  TextStyle expandedTitleStyle({Color? color, FontWeight? fontWeight}) {
    return TextStyle(
      fontFamily: 'Inter',
      fontSize: responsiveFontSize(
        small: 17,
        medium: 18,
        large: 19,
        tablet: 20,
      ),
      fontWeight: fontWeight ?? FontWeight.bold,
      color: color ?? AppColors.deepGreen,
    );
  }
}
