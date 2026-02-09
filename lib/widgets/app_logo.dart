import 'package:flutter/material.dart';
import 'dart:math';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:sukh_app/constants/constants.dart';
import 'package:sukh_app/widgets/optimized_glass.dart';

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

  bool _isDecember() {
    // For testing, you can temporarily return true
    // return true; // Uncomment to test
    return DateTime.now().month == 12;
  }

  @override
  Widget build(BuildContext context) {
    final effectiveMinHeight = minHeight ?? 80.h;
    final effectiveMaxHeight = maxHeight ?? 154.h;
    final effectiveMinWidth = minWidth ?? 154.w;
    final effectiveMaxWidth = maxWidth ?? 154.w;
    final effectiveBorderRadius = borderRadius ?? 36.w;
    // blurSigma kept for API compatibility; no blur applied.
    // ignore: unused_local_variable
    final effectiveBlurSigma = blurSigma ?? 10.w;
    final isDecember = _isDecember();

    return ConstrainedBox(
      constraints: BoxConstraints(
        minHeight: effectiveMinHeight,
        maxHeight: effectiveMaxHeight,
        minWidth: effectiveMinWidth,
        maxWidth: effectiveMaxWidth,
      ),
      child: showImage
          ? ValueListenableBuilder<String>(
              valueListenable: AppLogoNotifier.currentIcon,
              builder: (context, iconName, _) {
                final logoPath = AppLogoAssets.getAssetPath(iconName);
                return OverflowBox(
              maxWidth: effectiveMaxWidth * 1.5,
              maxHeight: effectiveMaxHeight * 1.5,
              alignment: Alignment.topCenter,
              child: Stack(
                clipBehavior: Clip.none,
                alignment: Alignment.topCenter,
                children: [
                  Positioned(
                    left: (effectiveMaxWidth * 1.5 - effectiveMaxWidth) / 2,
                    top: (effectiveMaxHeight * 1.5 - effectiveMaxHeight) / 2,
                    child: SizedBox(
                      width: effectiveMaxWidth,
                      height: effectiveMaxHeight,
                      child: Image.asset(
                        logoPath,
                        fit: BoxFit.contain,
                      ),
                    ),
                  ),
                  if (isDecember)
                    Positioned(
                      top:
                          (effectiveMaxHeight * 1.5 - effectiveMaxHeight) / 2 -
                          effectiveMaxHeight * 0.05,
                      right:
                          (effectiveMaxWidth * 1.5 - effectiveMaxWidth) / 2 -
                          effectiveMaxWidth * 0.3,
                      child: Transform.rotate(
                        angle: pi / 12, // 15 degrees (slightly right)
                        child: Image.asset(
                          'lib/assets/img/santa-hat.png',
                          width: effectiveMaxWidth * 1.0,
                          height: effectiveMaxHeight * 0.7,
                          fit: BoxFit.contain,
                        ),
                      ),
                    ),
                ],
              ),
            );
              },
            )
          : AspectRatio(
              aspectRatio: 1,
              child: OptimizedGlass(
                borderRadius: BorderRadius.circular(effectiveBorderRadius),
                // blurSigma kept for API compatibility; no blur applied.
                opacity: opacity,
                child: const SizedBox.expand(),
              ),
            ),
    );
  }
}

class SantaHatPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..style = PaintingStyle.fill
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..isAntiAlias = true;

    final centerX = size.width / 2;
    final hatBaseY = size.height * 0.7;
    final hatTopY = size.height * 0.05;
    final hatWidth = size.width * 0.75;

    // Draw red hat body - classic Santa hat shape
    paint.color = AppColors.santaRed;

    // Main hat cone
    final hatPath = Path()
      ..moveTo(centerX - hatWidth * 0.25, hatBaseY)
      ..lineTo(centerX, hatTopY)
      ..lineTo(centerX + hatWidth * 0.25, hatBaseY)
      ..close();

    canvas.drawPath(hatPath, paint);

    // Add shadow/highlight for depth
    paint.color = AppColors.santaRedDark;
    final shadowPath = Path()
      ..moveTo(centerX - hatWidth * 0.25, hatBaseY)
      ..lineTo(centerX - hatWidth * 0.1, hatBaseY * 0.5)
      ..lineTo(centerX, hatTopY)
      ..lineTo(centerX - hatWidth * 0.25, hatBaseY)
      ..close();
    canvas.drawPath(shadowPath, paint);

    // White fur trim at the bottom - fluffy and wavy
    paint.color = Colors.white;
    final furTrimPath = Path();
    final furY = hatBaseY;
    final furWidth = hatWidth * 0.5;

    // Create wavy fur trim
    for (double i = 0; i <= 1.0; i += 0.1) {
      final x = centerX - furWidth * 0.5 + (furWidth * i);
      final wave = sin(i * pi) * 3;
      final y = furY + wave;
      if (i == 0) {
        furTrimPath.moveTo(x, y);
      } else {
        furTrimPath.lineTo(x, y);
      }
    }
    furTrimPath
      ..lineTo(centerX + furWidth * 0.5, furY + 8)
      ..lineTo(centerX - furWidth * 0.5, furY + 8)
      ..close();

    canvas.drawPath(furTrimPath, paint);

    // White pom-pom at the tip - larger and more prominent
    final pomPomX = centerX;
    final pomPomY = hatTopY;
    final pomPomRadius = size.width * 0.12;

    // Main pom-pom with gradient effect
    paint.color = Colors.white;
    canvas.drawCircle(Offset(pomPomX, pomPomY), pomPomRadius, paint);

    // Highlight on pom-pom
    paint.color = Colors.white.withOpacity(0.8);
    canvas.drawCircle(
      Offset(pomPomX - pomPomRadius * 0.3, pomPomY - pomPomRadius * 0.3),
      pomPomRadius * 0.6,
      paint,
    );

    // Shadow on pom-pom
    paint.color = Colors.white.withOpacity(0.4);
    canvas.drawCircle(
      Offset(pomPomX + pomPomRadius * 0.2, pomPomY + pomPomRadius * 0.2),
      pomPomRadius * 0.5,
      paint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
