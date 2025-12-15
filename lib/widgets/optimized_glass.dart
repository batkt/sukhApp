import 'package:flutter/material.dart';

/// A lightweight "glass" surface optimized for scroll performance.
///
/// - It does **not** use backdrop blur (GPU expensive).
/// - It mimics the glass look with translucent gradients + subtle borders.
class OptimizedGlass extends StatelessWidget {
  final Widget child;
  final BorderRadius borderRadius;
  final double opacity;
  final double borderOpacity;
  final double highlightOpacity;

  const OptimizedGlass({
    super.key,
    required this.child,
    required this.borderRadius,
    this.opacity = 0.08,
    this.borderOpacity = 0.12,
    this.highlightOpacity = 0.10,
  });

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      child: ClipRRect(
        borderRadius: borderRadius,
        child: Stack(
          children: [
            Positioned.fill(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      Colors.white.withOpacity(opacity + highlightOpacity),
                      Colors.white.withOpacity(opacity),
                      Colors.white.withOpacity(opacity * 0.85),
                    ],
                  ),
                  borderRadius: borderRadius,
                  border: Border.all(
                    color: Colors.white.withOpacity(borderOpacity),
                    width: 1,
                  ),
                ),
              ),
            ),
            child,
          ],
        ),
      ),
    );
  }
}


