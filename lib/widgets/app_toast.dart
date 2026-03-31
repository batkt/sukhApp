import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:sukh_app/constants/constants.dart';
import 'package:sukh_app/utils/theme_extensions.dart';

class AppToast {
  static OverlayEntry? _overlayEntry;
  static Timer? _timer;
  static final _AppToastManager _manager = _AppToastManager();

  static void show(
    BuildContext context,
    String message, {
    IconData? icon,
    Color? color,
    Duration duration = const Duration(milliseconds: 1500),
    double? progress,
  }) {
    _manager.show(
      context,
      message,
      icon: icon,
      color: color,
      duration: duration,
      progress: progress,
    );
  }

  static void update({
    required String message,
    double? progress,
    IconData? icon,
    Color? color,
  }) {
    _manager.update(
      message: message,
      progress: progress,
      icon: icon,
      color: color,
    );
  }

  static void hide() {
    _manager.hide();
  }
}

class _AppToastManager {
  OverlayEntry? _overlayEntry;
  Timer? _timer;
  final ValueNotifier<_ToastData?> _dataNotifier = ValueNotifier(null);

  void show(
    BuildContext context,
    String message, {
    IconData? icon,
    Color? color,
    Duration duration = const Duration(milliseconds: 1500),
    double? progress,
  }) {
    _timer?.cancel();
    
    final newData = _ToastData(
      message: message,
      icon: icon,
      color: color ?? AppColors.deepGreen,
      progress: progress,
    );

    final overlay = Overlay.maybeOf(context);
    if (overlay == null) {
      debugPrint('AppToast: No Overlay found in context $context. Toasts require an Overlay ancestor.');
      return;
    }

    if (_overlayEntry == null) {
      _dataNotifier.value = newData;
      _overlayEntry = OverlayEntry(
        builder: (context) => _ToastWidget(
          dataNotifier: _dataNotifier,
          onDismiss: hide,
        ),
      );
      overlay.insert(_overlayEntry!);
    } else {
      _dataNotifier.value = newData;
    }

    if (progress == null) {
      _timer = Timer(duration, () => hide());
    }
  }

  void update({
    required String message,
    double? progress,
    IconData? icon,
    Color? color,
  }) {
    if (_overlayEntry != null) {
      _dataNotifier.value = _ToastData(
        message: message,
        progress: progress,
        icon: icon ?? _dataNotifier.value?.icon,
        color: color ?? _dataNotifier.value?.color ?? AppColors.deepGreen,
      );
    }
  }

  void hide() {
    _timer?.cancel();
    _dataNotifier.value = null; // Triggers exit animation
    Future.delayed(const Duration(milliseconds: 150), () {
      _overlayEntry?.remove();
      _overlayEntry = null;
    });
  }
}

class _ToastData {
  final String message;
  final IconData? icon;
  final Color color;
  final double? progress;

  _ToastData({
    required this.message,
    this.icon,
    required this.color,
    this.progress,
  });
}

class _ToastWidget extends StatefulWidget {
  final ValueNotifier<_ToastData?> dataNotifier;
  final VoidCallback onDismiss;

  const _ToastWidget({
    required this.dataNotifier,
    required this.onDismiss,
  });

  @override
  State<_ToastWidget> createState() => _ToastWidgetState();
}

class _ToastWidgetState extends State<_ToastWidget> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _fadeAnimation;
  _ToastData? _currentData;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 150),
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, -0.5),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOutCubic,
    ));

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(_controller);

    widget.dataNotifier.addListener(_handleDataChange);
    _handleDataChange();
  }

  void _handleDataChange() {
    if (widget.dataNotifier.value != null) {
      setState(() {
        _currentData = widget.dataNotifier.value;
      });
      _controller.forward();
    } else {
      _controller.reverse();
    }
  }

  @override
  void dispose() {
    widget.dataNotifier.removeListener(_handleDataChange);
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_currentData == null) return const SizedBox.shrink();

    final mq = MediaQuery.of(context);
    final isDark = context.isDarkMode;
    final topPadding = mq.padding.top + 10.h;

    return Positioned(
      top: topPadding,
      left: 20.w,
      right: 20.w,
      child: FadeTransition(
        opacity: _fadeAnimation,
        child: SlideTransition(
          position: _slideAnimation,
          child: Material(
            color: Colors.transparent,
            child: Container(
              clipBehavior: Clip.antiAlias,
              decoration: BoxDecoration(
                color: isDark ? AppColors.darkSurface : Colors.white,
                borderRadius: BorderRadius.circular(16.r),
                border: Border.all(
                  color: (isDark ? Colors.white : Colors.black).withOpacity(0.06),
                  width: 1,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.08),
                    blurRadius: 15,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
                    child: Row(
                      children: [
                        if (_currentData!.progress != null)
                          SizedBox(
                            width: 20.r,
                            height: 20.r,
                            child: CircularProgressIndicator(
                              value: _currentData!.progress,
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(_currentData!.color),
                              backgroundColor: _currentData!.color.withOpacity(0.2),
                            ),
                          )
                        else if (_currentData!.icon != null)
                          Icon(
                            _currentData!.icon,
                            color: _currentData!.color,
                            size: 22.sp,
                          ),
                        if (_currentData!.progress != null || _currentData!.icon != null)
                          SizedBox(width: 12.w),
                        Expanded(
                          child: Text(
                            _currentData!.message,
                            style: TextStyle(
                              fontSize: 14.sp,
                              fontWeight: FontWeight.w600,
                              color: isDark ? Colors.white : Colors.black87,
                            ),
                          ),
                        ),
                        if (_currentData!.progress != null)
                          Padding(
                            padding: EdgeInsets.only(left: 8.w),
                            child: Text(
                              '${(_currentData!.progress! * 100).toInt()}%',
                              style: TextStyle(
                                fontSize: 12.sp,
                                fontWeight: FontWeight.bold,
                                color: _currentData!.color,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                  if (_currentData!.progress != null)
                    LinearProgressIndicator(
                      value: _currentData!.progress,
                      minHeight: 3.h,
                      backgroundColor: _currentData!.color.withOpacity(0.1),
                      valueColor: AlwaysStoppedAnimation<Color>(_currentData!.color),
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
