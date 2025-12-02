import 'dart:ui';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

void showGlassSnackBar(
  BuildContext context, {
  required String message,
  IconData icon = Icons.info,
  Color textColor = Colors.white,
  Color iconColor = Colors.white,
  double opacity = 0.1,
  double blur = 10,
  Duration duration = const Duration(seconds: 2),
}) {
  final overlay = Overlay.of(context);
  OverlayEntry? overlayEntry;

  overlayEntry = OverlayEntry(
    builder: (context) => _SnackBarWidget(
      message: message,
      icon: icon,
      textColor: textColor,
      iconColor: iconColor,
      opacity: opacity,
      blur: blur,
      onDismiss: () {
        overlayEntry?.remove();
      },
    ),
  );

  overlay.insert(overlayEntry);

  // Auto-dismiss after duration
  Timer(duration, () {
    overlayEntry?.remove();
  });
}

class _SnackBarWidget extends StatefulWidget {
  final String message;
  final IconData icon;
  final Color textColor;
  final Color iconColor;
  final double opacity;
  final double blur;
  final VoidCallback onDismiss;

  const _SnackBarWidget({
    required this.message,
    required this.icon,
    required this.textColor,
    required this.iconColor,
    required this.opacity,
    required this.blur,
    required this.onDismiss,
  });

  @override
  State<_SnackBarWidget> createState() => _SnackBarWidgetState();
}

class _SnackBarWidgetState extends State<_SnackBarWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
      reverseDuration: const Duration(milliseconds: 200),
    );

    _slideAnimation =
        Tween<Offset>(begin: const Offset(0, -1), end: Offset.zero).animate(
          CurvedAnimation(
            parent: _controller,
            curve: Curves.easeOut,
            reverseCurve: Curves.easeIn,
          ),
        );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: Curves.easeOut,
        reverseCurve: Curves.easeIn,
      ),
    );

    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Positioned(
      top: MediaQuery.of(context).padding.top + 10.h,
      left: 16.w,
      right: 16.w,
      child: SlideTransition(
        position: _slideAnimation,
        child: FadeTransition(
          opacity: _fadeAnimation,
          child: Material(
            color: Colors.transparent,
            child: GestureDetector(
              onVerticalDragUpdate: (details) {
                if (details.delta.dy < 0) {
                  _controller.reverse().then((_) {
                    widget.onDismiss();
                  });
                }
              },
              child: ClipRRect(
                borderRadius: BorderRadius.circular(16.w),
                child: BackdropFilter(
                  filter: ImageFilter.blur(
                    sigmaX: widget.blur,
                    sigmaY: widget.blur,
                  ),
                  child: Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: 20.w,
                      vertical: 16.h,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(widget.opacity),
                      borderRadius: BorderRadius.circular(16.w),
                      border: Border.all(color: Colors.white.withOpacity(0.3)),
                    ),
                    child: Row(
                      children: [
                        Icon(widget.icon, color: widget.iconColor, size: 32.sp),
                        SizedBox(width: 16.w),
                        Expanded(
                          child: Text(
                            widget.message,
                            style: TextStyle(
                              color: widget.textColor,
                              fontSize: 15.sp,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
