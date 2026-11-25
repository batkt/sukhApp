import 'package:flutter/material.dart';
import 'package:sukh_app/utils/theme_extensions.dart';

/// Зөөлөн гэрлийн шилжилттэй (pulse) skeleton хайрцаг.
class SkeletonBox extends StatefulWidget {
  const SkeletonBox({
    super.key,
    this.width,
    required this.height,
    this.borderRadius = 12,
  });

  final double? width;
  final double height;
  final double borderRadius;

  @override
  State<SkeletonBox> createState() => _SkeletonBoxState();
}

class _SkeletonBoxState extends State<SkeletonBox>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1100),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = context.isDarkMode;
    final base = isDark ? Colors.white.withValues(alpha: 0.06) : const Color(0xFFE9EEF2);
    final highlight = isDark ? Colors.white.withValues(alpha: 0.12) : const Color(0xFFF4F7F9);

    return AnimatedBuilder(
      animation: _ctrl,
      builder: (_, _) => Container(
        width: widget.width,
        height: widget.height,
        decoration: BoxDecoration(
          color: Color.lerp(base, highlight, _ctrl.value),
          borderRadius: BorderRadius.circular(widget.borderRadius),
        ),
      ),
    );
  }
}
