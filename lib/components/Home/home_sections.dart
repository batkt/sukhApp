import 'dart:math' as math;

import 'package:flutter/cupertino.dart' show CupertinoIcons;
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:sukh_app/constants/constants.dart';
import 'package:sukh_app/utils/theme_extensions.dart';

/// Нүүр хуудасны өнгөний токен: ойн ногоон суурь + гаа (mint) өргөлт.
class HomeTone {
  static const Color pine = Color(0xFF0A3328);
  static const Color mint = Color(0xFF7DF0C6);
}

/// Дараагийн төлөлт хүртэлх хоногийг цагирагаар харуулна.
class PaymentDaysRing extends StatelessWidget {
  final double progress;
  final int? days;
  final String caption;
  final Color color;
  final Color foreground;
  final Animation<double> animation;

  const PaymentDaysRing({
    super.key,
    required this.progress,
    required this.days,
    required this.caption,
    required this.color,
    this.foreground = Colors.white,
    required this.animation,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 84,
      height: 84,
      child: AnimatedBuilder(
        animation: animation,
        builder: (context, _) => CustomPaint(
          painter: _RingPainter(
            progress: (progress * animation.value).clamp(0.0, 1.0),
            color: color,
            track: foreground.withValues(alpha: 0.12),
          ),
          child: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  days?.toString() ?? '—',
                  style: TextStyle(
                    color: foreground,
                    fontSize: 24,
                    fontWeight: FontWeight.w600,
                    height: 1.0,
                    letterSpacing: -0.5,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  caption,
                  style: TextStyle(
                    color: foreground.withValues(alpha: 0.7),
                    fontSize: 9.5,
                    fontWeight: FontWeight.w500,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _RingPainter extends CustomPainter {
  final double progress;
  final Color color;
  final Color track;

  _RingPainter({required this.progress, required this.color, required this.track});

  @override
  void paint(Canvas canvas, Size size) {
    const stroke = 6.0;
    final rect = Rect.fromLTWH(
      stroke / 2,
      stroke / 2,
      size.width - stroke,
      size.height - stroke,
    );
    final trackPaint = Paint()
      ..color = track
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke;
    canvas.drawArc(rect, 0, 2 * math.pi, false, trackPaint);
    if (progress > 0) {
      final arc = Paint()
        ..color = color
        ..style = PaintingStyle.stroke
        ..strokeWidth = stroke
        ..strokeCap = StrokeCap.round;
      canvas.drawArc(rect, -math.pi / 2, 2 * math.pi * progress, false, arc);
    }
  }

  @override
  bool shouldRepaint(_RingPainter old) =>
      old.progress != progress || old.color != color || old.track != track;
}

/// Үйлчилгээний icon — нэг өнгөт, дарахад зөөлөн шахагдана.
class UilchilgeeIcon extends StatefulWidget {
  final IconData icon;
  final String label;
  final bool isDark;

  const UilchilgeeIcon({
    super.key,
    required this.icon,
    required this.label,
    required this.isDark,
  });

  @override
  State<UilchilgeeIcon> createState() => _UilchilgeeIconState();
}

class _UilchilgeeIconState extends State<UilchilgeeIcon> {
  bool _darsan = false;

  void _tuluv(bool v) {
    if (_darsan != v) setState(() => _darsan = v);
  }

  @override
  Widget build(BuildContext context) {
    final dark = widget.isDark;
    final tamga = dark ? HomeTone.mint : AppColors.deepGreen;

    return Listener(
      onPointerDown: (_) => _tuluv(true),
      onPointerUp: (_) => _tuluv(false),
      onPointerCancel: (_) => _tuluv(false),
      child: AnimatedScale(
        scale: _darsan ? 0.94 : 1,
        duration: const Duration(milliseconds: 120),
        curve: Curves.easeOut,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 120),
              width: 54.w,
              height: 54.w,
              decoration: BoxDecoration(
                color: dark
                    ? Colors.white.withValues(alpha: _darsan ? 0.11 : 0.06)
                    : (_darsan ? const Color(0xFFE3ECE8) : const Color(0xFFF1F5F3)),
                borderRadius: BorderRadius.circular(16.r),
                border: Border.all(
                  color: dark
                      ? Colors.white.withValues(alpha: 0.07)
                      : AppColors.deepGreen.withValues(alpha: 0.06),
                ),
              ),
              child: Icon(widget.icon, color: tamga, size: 25.sp),
            ),
            SizedBox(height: 8.h),
            Text(
              widget.label,
              style: TextStyle(
                fontSize: 11.5.sp,
                color: context.textPrimaryColor.withValues(alpha: 0.85),
                fontWeight: FontWeight.w500,
                letterSpacing: -0.1,
              ),
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}

/// Нүүр хуудасны «Үйлчилгээ» хэсэг (8 товч бүхий 4×2 самбар).
class AdditionalServicesSection extends StatelessWidget {
  const AdditionalServicesSection({
    super.key,
    required this.onServiceTap,
  });

  final Future<void> Function(String name) onServiceTap;

  static const _services = [
    {'name': 'Зогсоол', 'label': 'Зогсоол', 'icon': CupertinoIcons.car_detailed},
    {'name': 'камер', 'label': 'Камер', 'icon': CupertinoIcons.videocam},
    {'name': 'лифт', 'label': 'Лифт', 'icon': CupertinoIcons.arrow_up_arrow_down_square},
    {'name': 'зочин', 'label': 'Зочин', 'icon': CupertinoIcons.person_badge_plus},
    {'name': 'дуудлага', 'label': 'Дуудлага', 'icon': CupertinoIcons.wrench},
    {'name': 'цэвэрлэгээ', 'label': 'Цэвэрлэгээ', 'icon': CupertinoIcons.sparkles},
    {'name': 'санал', 'label': 'Асуулга', 'icon': CupertinoIcons.chart_bar_square},
    {'name': 'шилэн', 'label': 'Шилэн данс', 'icon': CupertinoIcons.chart_pie},
  ];

  @override
  Widget build(BuildContext context) {
    final isDark = context.isDarkMode;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 4.w),
          child: Text(
            'Үйлчилгээ',
            style: TextStyle(
              fontSize: 17.sp,
              color: context.textPrimaryColor,
              fontWeight: FontWeight.w600,
              letterSpacing: -0.4,
            ),
          ),
        ),
        SizedBox(height: 10.h),
        Container(
          padding: EdgeInsets.fromLTRB(8.w, 14.h, 8.w, 6.h),
          decoration: BoxDecoration(
            color: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.white,
            borderRadius: BorderRadius.circular(26.r),
            border: Border.all(
              color: isDark
                  ? Colors.white.withValues(alpha: 0.06)
                  : Colors.black.withValues(alpha: 0.04),
            ),
          ),
          child: GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            padding: EdgeInsets.zero,
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 4,
              crossAxisSpacing: 4.w,
              mainAxisSpacing: 8.h,
              childAspectRatio: 0.92,
            ),
            itemCount: _services.length,
            itemBuilder: (context, index) {
              final service = _services[index];
              final name = service['name'] as String? ?? '';
              return GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: () => onServiceTap(name),
                child: UilchilgeeIcon(
                  icon: service['icon'] as IconData? ?? Icons.apps_rounded,
                  label: service['label'] as String? ?? '',
                  isDark: isDark,
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}
