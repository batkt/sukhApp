import 'package:flutter/material.dart';
import 'package:sukh_app/constants/constants.dart';

class SharedBgPainter extends CustomPainter {
  final bool isDark;
  final Color brandColor;

  SharedBgPainter({required this.isDark, required this.brandColor});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint();

    // A. Linear Gradient
    final rect = Offset.zero & size;
    final gradient = LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: [
        brandColor,
        brandColor.withOpacity(0.85),
        isDark ? AppColors.darkBackground : const Color(0xFFF5F9FC),
        isDark ? AppColors.darkBackground : const Color(0xFFF5F9FC),
      ],
      stops: const [0.0, 0.35, 0.45, 1.0],
    );
    paint.shader = gradient.createShader(rect);
    canvas.drawRect(rect, paint);

    // B. Decorative Circles (White, 5% Opacity)
    paint.shader = null;
    paint.color = Colors.white.withOpacity(0.05);

    // Top Right Circle
    canvas.drawCircle(
      Offset(size.width * 0.85, size.height * 0.08),
      size.width * 0.35,
      paint,
    );
    // Mid Left Circle
    canvas.drawCircle(
      Offset(size.width * 0.10, size.height * 0.22),
      size.width * 0.25,
      paint,
    );
    // Mid Right Circle
    canvas.drawCircle(
      Offset(size.width * 0.70, size.height * 0.30),
      size.width * 0.15,
      paint,
    );

    // C. Wave Separator Path
    final waveY = size.height * 0.38;
    final wavePaint = Paint()
      ..color = isDark ? AppColors.darkBackground : const Color(0xFFF5F9FC)
      ..style = PaintingStyle.fill;

    final path = Path();
    path.moveTo(0, waveY);
    path.quadraticBezierTo(
      size.width * 0.25,
      waveY + 40,
      size.width * 0.5,
      waveY - 10,
    );
    path.quadraticBezierTo(
      size.width * 0.75,
      waveY - 50,
      size.width,
      waveY + 10,
    );

    path.lineTo(size.width, size.height);
    path.lineTo(0, size.height);
    path.close();

    canvas.drawPath(path, wavePaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
