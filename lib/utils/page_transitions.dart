import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

/// Global page transition configurations for the app
class PageTransitions {
  /// Total transition duration (standard 300ms for smooth sliding)
  static const int totalDurationMs = 300;

  /// Creates a horizontal slide transition for GoRouter
  /// Maintains the old method name so we don't have to rewrite app_router.dart
  static CustomTransitionPage<void> buildFadeThroughTransition({
    required LocalKey key,
    required Widget child,
  }) {
    return CustomTransitionPage(
      key: key,
      child: child,
      transitionDuration: const Duration(milliseconds: totalDurationMs),
      reverseTransitionDuration: const Duration(milliseconds: totalDurationMs),
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        const curve = Curves.easeOutCubic;

        // Primary: slide in from right to center (dx: 1.0 -> 0.0)
        final primaryTween = Tween(begin: const Offset(1.0, 0.0), end: Offset.zero)
            .chain(CurveTween(curve: curve));
            
        // Secondary: slide out slightly to the left (dx: 0.0 -> -0.3) for parallax
        final secondaryTween = Tween(begin: Offset.zero, end: const Offset(-0.3, 0.0))
            .chain(CurveTween(curve: curve));

        return SlideTransition(
          position: animation.drive(primaryTween),
          child: SlideTransition(
            position: secondaryAnimation.drive(secondaryTween),
            child: child,
          ),
        );
      },
    );
  }

  /// Creates a horizontal slide transition for Navigator.push
  static PageRouteBuilder<T> createRoute<T>(Widget page) {
    return PageRouteBuilder<T>(
      pageBuilder: (context, animation, secondaryAnimation) => page,
      transitionDuration: const Duration(milliseconds: totalDurationMs),
      reverseTransitionDuration: const Duration(milliseconds: totalDurationMs),
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        const curve = Curves.easeOutCubic;

        final primaryTween = Tween(begin: const Offset(1.0, 0.0), end: Offset.zero)
            .chain(CurveTween(curve: curve));
            
        final secondaryTween = Tween(begin: Offset.zero, end: const Offset(-0.3, 0.0))
            .chain(CurveTween(curve: curve));

        return SlideTransition(
          position: animation.drive(primaryTween),
          child: SlideTransition(
            position: secondaryAnimation.drive(secondaryTween),
            child: child,
          ),
        );
      },
    );
  }

  /// Alias for buildSmoothFadeTransition using the new slide animation
  static CustomTransitionPage<void> buildSmoothFadeTransition({
    required LocalKey key,
    required Widget child,
  }) {
    return buildFadeThroughTransition(key: key, child: child);
  }

  /// Alias for createSmoothRoute using the new slide animation 
  static PageRouteBuilder<T> createSmoothRoute<T>(Widget page) {
    return createRoute<T>(page);
  }
}
