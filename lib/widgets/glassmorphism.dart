import 'package:flutter/material.dart';
import 'package:sukh_app/widgets/optimized_glass.dart';

/// Backwards-compatible lightweight glass widget.
///
/// NOTE: This intentionally does NOT use blur to avoid GPU overload.
class Glassmorphism extends StatelessWidget {
  final double blur; // kept for API compatibility (ignored)
  final double opacity;
  final Widget child;
  final BorderRadius borderRadius;
  const Glassmorphism({
    super.key,
    required this.blur,
    required this.opacity,
    required this.child,
    this.borderRadius = const BorderRadius.all(Radius.circular(50)),
  });

  @override
  Widget build(BuildContext context) {
    return OptimizedGlass(
      borderRadius: borderRadius,
      opacity: opacity,
      child: child,
    );
  }
}
