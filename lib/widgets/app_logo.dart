import 'package:flutter/material.dart';
import 'dart:ui';

class AppLogo extends StatelessWidget {
  final double minHeight;
  final double maxHeight;
  final double minWidth;
  final double maxWidth;
  final double borderRadius;
  final double blurSigma;
  final double opacity;
  final bool showImage;

  const AppLogo({
    super.key,
    this.minHeight = 80,
    this.maxHeight = 154,
    this.minWidth = 154,
    this.maxWidth = 154,
    this.borderRadius = 36,
    this.blurSigma = 10,
    this.opacity = 0.2,
    this.showImage = true,
  });

  @override
  Widget build(BuildContext context) {
    return ConstrainedBox(
      constraints: BoxConstraints(
        minHeight: minHeight,
        maxHeight: maxHeight,
        minWidth: minWidth,
        maxWidth: maxWidth,
      ),
      child: showImage
          ? SizedBox(
              width: maxWidth,
              height: maxHeight,
              child: Image.asset(
                'lib/assets/img/logo_3.png',
                fit: BoxFit.contain,
              ),
            )
          : AspectRatio(
              aspectRatio: 1,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(borderRadius),
                child: BackdropFilter(
                  filter: ImageFilter.blur(
                    sigmaX: blurSigma,
                    sigmaY: blurSigma,
                  ),
                  child: Container(
                    color: Colors.white.withValues(alpha: opacity),
                  ),
                ),
              ),
            ),
    );
  }
}
