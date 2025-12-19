import 'package:flutter/material.dart';
import 'package:snow_fall_animation/snow_fall_animation.dart';

class SnowEffect extends StatelessWidget {
  final Widget child;

  const SnowEffect({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return Stack(
      alignment: Alignment.topLeft,
      textDirection: TextDirection.ltr,
      children: [
        child,
        IgnorePointer(
          child: SnowFallAnimation(
            config: const SnowfallConfig(
              numberOfSnowflakes: 30,
              speed: 0.6,
              useEmoji: true,
              customEmojis: ['❄️', '❅', '❆'],
              snowColor: Colors.white,
              holdSnowAtBottom: false,
            ),
          ),
        ),
      ],
    );
  }
}
