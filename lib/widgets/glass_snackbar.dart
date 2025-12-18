import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:sukh_app/utils/responsive_helper.dart';

void showGlassSnackBar(
  BuildContext context, {
  required String message,
  IconData icon = Icons.info,
  Color textColor = Colors.white,
  Color iconColor = Colors.white,
  double opacity = 0.1,
  double blur = 10, // kept for API compatibility (ignored)
  Duration duration = const Duration(seconds: 2),
}) {
  try {
    final overlay = Overlay.of(context, rootOverlay: true);
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
          try {
            overlayEntry?.remove();
          } catch (e) {
            // Ignore errors when removing overlay (widget might be disposed)
            print('Error removing overlay entry: $e');
          }
        },
      ),
    );

    overlay.insert(overlayEntry);

    // Auto-dismiss after duration
    Timer(duration, () {
      try {
        overlayEntry?.remove();
      } catch (e) {
        // Ignore errors when removing overlay (widget might be disposed)
        print('Error auto-dismissing snackbar: $e');
      }
    });
  } catch (e) {
    // Fallback to regular SnackBar if overlay fails
    print('Error showing glass snackbar, using fallback: $e');
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        duration: duration,
      ),
    );
  }
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
    // Determine background color based on icon color (error = red, success = green)
    final bool isError = widget.iconColor == Colors.red;
    final bool isSuccess = widget.iconColor == Colors.green;
    
    // Use a more opaque background with a distinct color
    Color backgroundColor;
    if (isError) {
      backgroundColor = Colors.red.withOpacity(0.95);
    } else if (isSuccess) {
      backgroundColor = Colors.green.withOpacity(0.95);
    } else {
      backgroundColor = Colors.black.withOpacity(0.85);
    }
    
    return Positioned(
      top: MediaQuery.of(context).padding.top + context.responsiveSpacing(small: 10, medium: 12, large: 14, tablet: 16),
      left: context.responsiveSpacing(small: 16, medium: 20, large: 24, tablet: 28),
      right: context.responsiveSpacing(small: 16, medium: 20, large: 24, tablet: 28),
      child: SlideTransition(
        position: _slideAnimation,
        child: FadeTransition(
          opacity: _fadeAnimation,
          child: Material(
            color: Colors.transparent,
            elevation: 8,
            borderRadius: BorderRadius.circular(16.w),
            child: GestureDetector(
              onVerticalDragUpdate: (details) {
                if (details.delta.dy < 0) {
                  _controller.reverse().then((_) {
                    widget.onDismiss();
                  });
                }
              },
              child: Container(
                decoration: BoxDecoration(
                  color: backgroundColor,
                  borderRadius: BorderRadius.circular(context.responsiveBorderRadius(
                    small: 16,
                    medium: 18,
                    large: 20,
                    tablet: 22,
                  )),
                  border: Border.all(
                    color: widget.iconColor.withOpacity(0.3),
                    width: 1.5,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.3),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                      spreadRadius: 0,
                    ),
                    BoxShadow(
                      color: widget.iconColor.withOpacity(0.2),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                      spreadRadius: 0,
                    ),
                  ],
                ),
                padding: EdgeInsets.symmetric(
                  horizontal: context.responsiveSpacing(small: 20, medium: 24, large: 28, tablet: 32),
                  vertical: context.responsiveSpacing(small: 16, medium: 18, large: 20, tablet: 22),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: EdgeInsets.all(context.responsiveSpacing(small: 8, medium: 10, large: 12, tablet: 14)),
                      decoration: BoxDecoration(
                        color: widget.iconColor.withOpacity(0.2),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        widget.icon,
                        color: widget.iconColor,
                        size: context.responsiveIconSize(
                          small: 24,
                          medium: 26,
                          large: 28,
                          tablet: 30,
                        ),
                      ),
                    ),
                    SizedBox(width: context.responsiveSpacing(small: 16, medium: 18, large: 20, tablet: 22)),
                    Expanded(
                      child: Text(
                        widget.message,
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: context.responsiveFontSize(
                            small: 15,
                            medium: 16,
                            large: 17,
                            tablet: 18,
                          ),
                          fontWeight: FontWeight.w600,
                          letterSpacing: 0.2,
                          shadows: [
                            Shadow(
                              color: Colors.black.withOpacity(0.3),
                              offset: const Offset(0, 1),
                              blurRadius: 2,
                            ),
                          ],
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
    );
  }
}
