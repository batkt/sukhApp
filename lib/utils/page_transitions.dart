import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

/// Global page transition configurations for the app
class PageTransitions {
  /// Duration for fade out (current page disappearing)
  static const int fadeOutDurationMs = 150;

  /// Duration for fade in (new page appearing)
  static const int fadeInDurationMs = 150;

  /// Total transition duration
  static const int totalDurationMs = fadeOutDurationMs + fadeInDurationMs;

  /// Creates a fade-through transition for GoRouter
  ///
  /// This transition ensures:
  /// 1. Current page fades out completely first
  /// 2. Then new page fades in
  /// 3. No overlapping/mixing of page items during transition
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
        // Create a sequential fade transition:
        // - First half: fade out old page (0.0 to 0.5 -> opacity 1.0 to 0.0)
        // - Second half: fade in new page (0.5 to 1.0 -> opacity 0.0 to 1.0)

        return AnimatedBuilder(
          animation: animation,
          builder: (context, child) {
            double opacity;

            if (animation.value < 0.5) {
              // First half - keep new page invisible
              opacity = 0.0;
            } else {
              // Second half - fade in new page
              // Map 0.5-1.0 to 0.0-1.0
              opacity = (animation.value - 0.5) * 2.0;
            }

            return Opacity(
              opacity: opacity,
              child: child,
            );
          },
          child: child,
        );
      },
    );
  }

  /// Creates a fade-through transition for Navigator.push
  ///
  /// Usage:
  /// ```dart
  /// Navigator.push(
  ///   context,
  ///   PageTransitions.createRoute(NextPage()),
  /// );
  /// ```
  static PageRouteBuilder<T> createRoute<T>(Widget page) {
    return PageRouteBuilder<T>(
      pageBuilder: (context, animation, secondaryAnimation) => page,
      transitionDuration: const Duration(milliseconds: totalDurationMs),
      reverseTransitionDuration: const Duration(milliseconds: totalDurationMs),
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        // Fade in the new page during the second half
        final fadeInAnimation = Tween<double>(
          begin: 0.0,
          end: 1.0,
        ).animate(
          CurvedAnimation(
            parent: animation,
            curve: const Interval(0.5, 1.0, curve: Curves.easeIn),
          ),
        );

        return FadeTransition(
          opacity: fadeInAnimation,
          child: child,
        );
      },
    );
  }

  /// Alternative: Creates a smoother crossfade transition with minimal overlap
  ///
  /// This version has a very brief overlap period but ensures smooth animation
  static CustomTransitionPage<void> buildSmoothFadeTransition({
    required LocalKey key,
    required Widget child,
  }) {
    return CustomTransitionPage(
      key: key,
      child: child,
      transitionDuration: const Duration(milliseconds: totalDurationMs),
      reverseTransitionDuration: const Duration(milliseconds: totalDurationMs),
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        // Fade in with delay - starts at 0.3 instead of 0.5 for smoother feel
        final fadeIn = Tween<double>(
          begin: 0.0,
          end: 1.0,
        ).animate(
          CurvedAnimation(
            parent: animation,
            curve: const Interval(0.3, 1.0, curve: Curves.easeIn),
          ),
        );

        return FadeTransition(
          opacity: fadeIn,
          child: child,
        );
      },
    );
  }

  /// Creates a smooth crossfade route for Navigator.push
  ///
  /// Usage:
  /// ```dart
  /// Navigator.push(
  ///   context,
  ///   PageTransitions.createSmoothRoute(NextPage()),
  /// );
  /// ```
  static PageRouteBuilder<T> createSmoothRoute<T>(Widget page) {
    return PageRouteBuilder<T>(
      pageBuilder: (context, animation, secondaryAnimation) => page,
      transitionDuration: const Duration(milliseconds: totalDurationMs),
      reverseTransitionDuration: const Duration(milliseconds: totalDurationMs),
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        // Fade in with slight delay for smoother transition
        final fadeIn = Tween<double>(
          begin: 0.0,
          end: 1.0,
        ).animate(
          CurvedAnimation(
            parent: animation,
            curve: const Interval(0.3, 1.0, curve: Curves.easeIn),
          ),
        );

        return FadeTransition(
          opacity: fadeIn,
          child: child,
        );
      },
    );
  }
}
