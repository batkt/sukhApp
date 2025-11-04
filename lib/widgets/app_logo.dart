import 'package:flutter/material.dart';
import 'dart:ui';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class AppLogo extends StatelessWidget {
  final double? minHeight;
  final double? maxHeight;
  final double? minWidth;
  final double? maxWidth;
  final double? borderRadius;
  final double? blurSigma;
  final double opacity;
  final bool showImage;

  const AppLogo({
    super.key,
    this.minHeight,
    this.maxHeight,
    this.minWidth,
    this.maxWidth,
    this.borderRadius,
    this.blurSigma,
    this.opacity = 0.2,
    this.showImage = true,
  });

  @override
  Widget build(BuildContext context) {
    final effectiveMinHeight = minHeight ?? 80.h;
    final effectiveMaxHeight = maxHeight ?? 154.h;
    final effectiveMinWidth = minWidth ?? 154.w;
    final effectiveMaxWidth = maxWidth ?? 154.w;
    final effectiveBorderRadius = borderRadius ?? 36.w;
    final effectiveBlurSigma = blurSigma ?? 10.w;

    return ConstrainedBox(
      constraints: BoxConstraints(
        minHeight: effectiveMinHeight,
        maxHeight: effectiveMaxHeight,
        minWidth: effectiveMinWidth,
        maxWidth: effectiveMaxWidth,
      ),
      child: showImage
          ? SizedBox(
              width: effectiveMaxWidth,
              height: effectiveMaxHeight,
              child: Image.asset(
                'lib/assets/img/logo_3.png',
                fit: BoxFit.contain,
              ),
            )
          : AspectRatio(
              aspectRatio: 1,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(effectiveBorderRadius),
                child: BackdropFilter(
                  filter: ImageFilter.blur(
                    sigmaX: effectiveBlurSigma,
                    sigmaY: effectiveBlurSigma,
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
