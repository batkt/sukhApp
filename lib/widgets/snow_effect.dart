import 'package:flutter/material.dart';

/// SnowEffect widget - returns child directly without animation
/// (snow_fall_animation package was removed)
class SnowEffect extends StatelessWidget {
  final Widget child;

  const SnowEffect({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    // Just return the child without snow animation
    return child;
  }
}
