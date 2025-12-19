import 'package:flutter/material.dart';
import 'package:sukh_app/constants/constants.dart';
import 'package:sukh_app/utils/theme_extensions.dart';

class AppBackground extends StatelessWidget {
  final Widget child;
  final bool showImage;
  
  const AppBackground({
    super.key, 
    required this.child,
    this.showImage = true,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = context.isDarkMode;
    
    // Gradient background with black, white, deep green, and blue
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: isDark
              ? [
                  // Dark mode: darker gradient
                  const Color(0xFF000000), // Black
                  const Color(0xFF0A1F1A), // Dark deep green
                  const Color(0xFF0D4F3C), // Deep green
                  const Color(0xFF1A3A4A), // Dark blue-green
                  const Color(0xFF0F1419), // Dark background
                ]
              : [
                  // Light mode: light gradient with white base
                  const Color(0xFFFFFFFF), // White
                  const Color(0xFFF0F9F6), // Very light green tint
                  const Color(0xFFE8F4F0), // Light green
                  const Color(0xFFE0F0F5), // Light blue-green
                  const Color(0xFFFFFFFF), // White
                ],
          stops: const [0.0, 0.3, 0.5, 0.7, 1.0],
        ),
        image: (isDark && showImage)
            ? const DecorationImage(
                image: AssetImage('lib/assets/img/background_image.png'),
                fit: BoxFit.none,
                scale: 3,
                opacity: 0.15, // Very subtle in dark mode
              )
            : null,
      ),
      child: child,
    );
  }
}

