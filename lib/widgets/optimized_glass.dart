import 'package:flutter/material.dart';
import 'package:sukh_app/utils/theme_extensions.dart';
import 'dart:ui';

/// iOS 26 style glassmorphism widget with theme support
/// Modern glassy effect with backdrop blur and translucent surface
class OptimizedGlass extends StatelessWidget {
  final Widget child;
  final BorderRadius borderRadius;
  final double opacity;
  final double borderOpacity;
  final double blurIntensity;

  const OptimizedGlass({
    super.key,
    required this.child,
    required this.borderRadius,
    this.opacity = 0.15,
    this.borderOpacity = 0.18,
    this.blurIntensity = 10.0,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = context.isDarkMode;
    
    // iOS 26 style glassmorphism colors
    final baseColor = isDark 
        ? Colors.white 
        : Colors.white;
    final borderColor = isDark
        ? Colors.white.withOpacity(borderOpacity * 0.6)
        : Colors.white.withOpacity(borderOpacity);
    
    return RepaintBoundary(
      child: ClipRRect(
        borderRadius: borderRadius,
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: blurIntensity, sigmaY: blurIntensity),
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: isDark
                    ? [
                        // Dark mode: subtle dark glass
                        Colors.white.withOpacity(opacity * 0.3),
                        Colors.white.withOpacity(opacity * 0.2),
                        Colors.white.withOpacity(opacity * 0.15),
                      ]
                    : [
                        // Light mode: bright glass
                        baseColor.withOpacity(opacity * 1.2),
                        baseColor.withOpacity(opacity),
                        baseColor.withOpacity(opacity * 0.8),
                      ],
              ),
              borderRadius: borderRadius,
              border: Border.all(
                color: borderColor,
                width: 1.5,
              ),
              boxShadow: [
                BoxShadow(
                  color: isDark
                      ? Colors.black.withOpacity(0.3)
                      : Colors.black.withOpacity(0.05),
                  blurRadius: 20,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: child,
          ),
        ),
      ),
    );
  }
}


