import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

/// Компоненттой шууд нэгдсэн, байрлал (layout) алдагдуулахгүй
/// хөдөлгөөнт тусламж, зааварчилгааны хайрцаг
class GuidedComponent extends StatefulWidget {
  static VoidCallback? onTriggerGuide;
  static void trigger() => onTriggerGuide?.call();

  final int stepIndex;
  final int activeStep;
  final int totalSteps;
  final String title;
  final String description;
  final String tag;
  final IconData icon;
  final bool tipBelow;
  final double borderRadius;
  final EdgeInsets? tipMargin;
  final VoidCallback onNext;
  final VoidCallback onSkip;
  final Widget child;

  const GuidedComponent({
    super.key,
    required this.stepIndex,
    required this.activeStep,
    required this.totalSteps,
    required this.title,
    required this.description,
    required this.tag,
    required this.icon,
    this.tipBelow = true,
    this.borderRadius = 24.0,
    this.tipMargin,
    required this.onNext,
    required this.onSkip,
    required this.child,
  });

  @override
  State<GuidedComponent> createState() => _GuidedComponentState();
}

class _GuidedComponentState extends State<GuidedComponent>
    with TickerProviderStateMixin {
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  late AnimationController _floatController;
  late AnimationController _cardAnimController;
  late Animation<double> _cardScaleAnimation;
  late Animation<double> _cardFadeAnimation;

  @override
  void initState() {
    super.initState();

    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1600),
    )..repeat(reverse: true);

    _pulseAnimation = CurvedAnimation(
      parent: _pulseController,
      curve: Curves.easeInOutSine,
    );

    _floatController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2200),
    )..repeat(reverse: true);

    _cardAnimController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 350),
    );

    _cardScaleAnimation = Tween<double>(begin: 0.9, end: 1.0).animate(
      CurvedAnimation(
        parent: _cardAnimController,
        curve: Curves.easeOutBack,
      ),
    );

    _cardFadeAnimation = CurvedAnimation(
      parent: _cardAnimController,
      curve: Curves.easeIn,
    );

    if (widget.activeStep == widget.stepIndex) {
      _cardAnimController.forward();
      _scrollToSelf();
    }
  }

  @override
  void didUpdateWidget(covariant GuidedComponent oldWidget) {
    super.didUpdateWidget(oldWidget);
    final isNowActive = widget.activeStep == widget.stepIndex;
    final wasActive = oldWidget.activeStep == oldWidget.stepIndex;

    if (isNowActive && !wasActive) {
      _cardAnimController.reset();
      _cardAnimController.forward();
      _scrollToSelf();
    } else if (!isNowActive && wasActive) {
      _cardAnimController.reverse();
    }
  }

  void _scrollToSelf() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      try {
        Scrollable.ensureVisible(
          context,
          duration: const Duration(milliseconds: 450),
          curve: Curves.easeInOutCubic,
          alignment: 0.22,
        );
      } catch (_) {}
    });
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _floatController.dispose();
    _cardAnimController.dispose();
    super.dispose();
  }

  void _handleNext() {
    HapticFeedback.lightImpact();
    widget.onNext();
  }

  void _handleSkip() {
    HapticFeedback.mediumImpact();
    widget.onSkip();
  }

  @override
  Widget build(BuildContext context) {
    final bool isGuideActive = widget.activeStep >= 0;
    final bool isCurrent = widget.activeStep == widget.stepIndex;

    return AnimatedOpacity(
      duration: const Duration(milliseconds: 300),
      opacity: (!isGuideActive || isCurrent) ? 1.0 : 0.32,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Дээр байрлах Tooltip
          if (!widget.tipBelow && isCurrent) ...[
            _buildAnimatedTipCard(isCurrent, pointingDown: true),
            SizedBox(height: 16.h),
          ],

          // Үндсэн Компонент (Идэвхтэй үед намуухан, цэвэрхэн хүрээтэй)
          AnimatedBuilder(
            animation: _pulseAnimation,
            builder: (context, child) {
              if (!isCurrent) return child!;
              final double pulseVal = _pulseAnimation.value;

              return Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(widget.borderRadius + 4),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF10B981)
                          .withValues(alpha: 0.10 + 0.08 * pulseVal),
                      blurRadius: 10 + 6 * pulseVal,
                      spreadRadius: 0,
                    ),
                  ],
                ),
                child: Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: 4.w,
                    vertical: 4.h,
                  ),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(widget.borderRadius + 4),
                    border: Border.all(
                      color: const Color(0xFF10B981).withValues(alpha: 0.85),
                      width: 1.5,
                    ),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(widget.borderRadius),
                    child: child,
                  ),
                ),
              );
            },
            child: widget.child,
          ),

          // Доор байрлах Tooltip
          if (widget.tipBelow && isCurrent) ...[
            SizedBox(height: 16.h),
            _buildAnimatedTipCard(isCurrent, pointingDown: false),
          ],
        ],
      ),
    );
  }

  Widget _buildAnimatedTipCard(bool isCurrent, {required bool pointingDown}) {
    final isLast = widget.stepIndex == widget.totalSteps - 1;

    return AnimatedBuilder(
      animation: Listenable.merge([_floatController, _cardAnimController]),
      builder: (context, child) {
        final floatOffsetY = sin(_floatController.value * pi) * 3.5;

        return Transform.translate(
          offset: Offset(0, floatOffsetY),
          child: FadeTransition(
            opacity: _cardFadeAnimation,
            child: ScaleTransition(
              scale: _cardScaleAnimation,
              alignment: pointingDown ? Alignment.bottomCenter : Alignment.topCenter,
              child: Stack(
                clipBehavior: Clip.none,
                alignment: Alignment.center,
                children: [
                  // Гол Tooltip Card
                  Container(
                    margin: widget.tipMargin ?? EdgeInsets.symmetric(
                      horizontal: 4.w,
                    ),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          Color(0xFF14532D), // Deep rich green
                          Color(0xFF093928),
                          Color(0xFF042419), // Deep dark green
                        ],
                      ),
                      borderRadius: BorderRadius.circular(22.r),
                      border: Border.all(
                        color: const Color(0xFF34D399).withValues(alpha: 0.35),
                        width: 1.2,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.35),
                          blurRadius: 18,
                          offset: const Offset(0, 6),
                        ),
                        BoxShadow(
                          color: const Color(0xFF10B981).withValues(alpha: 0.08),
                          blurRadius: 10,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(22.r),
                      child: Stack(
                        children: [
                          // Баруун дээд цацраг
                          Positioned(
                            top: -25.h,
                            right: -25.w,
                            child: Container(
                              width: 110.w,
                              height: 110.w,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: const Color(0xFF34D399).withValues(alpha: 0.16),
                              ),
                            ),
                          ),

                          Padding(
                            padding: EdgeInsets.fromLTRB(18.w, 16.h, 18.w, 15.h),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // Дээд гарчиг ба Tag
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Container(
                                      padding: EdgeInsets.symmetric(
                                        horizontal: 10.w,
                                        vertical: 4.h,
                                      ),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFF34D399).withValues(alpha: 0.18),
                                        borderRadius: BorderRadius.circular(100),
                                        border: Border.all(
                                          color: const Color(0xFF34D399).withValues(alpha: 0.45),
                                        ),
                                      ),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Icon(
                                            widget.icon,
                                            color: const Color(0xFF34D399),
                                            size: 13.sp,
                                          ),
                                          SizedBox(width: 5.w),
                                          Text(
                                            widget.tag,
                                            style: TextStyle(
                                              color: const Color(0xFF6EE7B7),
                                              fontSize: 10.sp,
                                              fontWeight: FontWeight.w700,
                                              letterSpacing: 0.8,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    Text(
                                      '${widget.stepIndex + 1} / ${widget.totalSteps}',
                                      style: TextStyle(
                                        color: Colors.white.withValues(alpha: 0.55),
                                        fontSize: 11.sp,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ],
                                ),

                                SizedBox(height: 10.h),

                                // Гарчиг
                                Text(
                                  widget.title,
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 15.sp,
                                    fontWeight: FontWeight.w700,
                                    letterSpacing: -0.2,
                                  ),
                                ),

                                SizedBox(height: 6.h),

                                // Тайлбар
                                Text(
                                  widget.description,
                                  style: TextStyle(
                                    color: const Color(0xFFD1FAE5).withValues(alpha: 0.95),
                                    fontSize: 12.sp,
                                    height: 1.45,
                                    fontWeight: FontWeight.w400,
                                  ),
                                ),

                                SizedBox(height: 16.h),

                                // Доод удирдлагын товчнууд
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    // Алгасах товч
                                    GestureDetector(
                                      onTap: _handleSkip,
                                      behavior: HitTestBehavior.opaque,
                                      child: Padding(
                                        padding: EdgeInsets.symmetric(
                                          vertical: 6.h,
                                          horizontal: 4.w,
                                        ),
                                        child: Text(
                                          'Алгасах',
                                          style: TextStyle(
                                            color: Colors.white.withValues(alpha: 0.6),
                                            fontSize: 12.sp,
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                      ),
                                    ),

                                    // Алхмуудын цэгэн индикатор
                                    Row(
                                      children: List.generate(widget.totalSteps, (index) {
                                        final bool isStepActive = index == widget.stepIndex;
                                        return AnimatedContainer(
                                          duration: const Duration(milliseconds: 300),
                                          curve: Curves.easeOutCubic,
                                          margin: EdgeInsets.symmetric(horizontal: 2.5.w),
                                          width: isStepActive ? 18.w : 5.w,
                                          height: 5.h,
                                          decoration: BoxDecoration(
                                            color: isStepActive
                                                ? const Color(0xFF34D399)
                                                : Colors.white.withValues(alpha: 0.22),
                                            borderRadius: BorderRadius.circular(10.r),
                                            boxShadow: isStepActive
                                                ? [
                                                    BoxShadow(
                                                      color: const Color(0xFF34D399).withValues(alpha: 0.25),
                                                      blurRadius: 3,
                                                    ),
                                                  ]
                                                : null,
                                          ),
                                        );
                                      }),
                                    ),

                                    // Дараах / Ойлголоо товч
                                    ElevatedButton(
                                      onPressed: _handleNext,
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: const Color(0xFF10B981),
                                        foregroundColor: Colors.white,
                                        elevation: 4,
                                        shadowColor: const Color(0xFF10B981).withValues(alpha: 0.5),
                                        padding: EdgeInsets.symmetric(
                                          horizontal: isLast ? 16.w : 14.w,
                                          vertical: 8.h,
                                        ),
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(12.r),
                                        ),
                                      ),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Text(
                                            isLast ? 'Ойлголоо' : 'Дараах',
                                            style: TextStyle(
                                              fontSize: 12.sp,
                                              fontWeight: FontWeight.w700,
                                              letterSpacing: 0.2,
                                            ),
                                          ),
                                          SizedBox(width: 4.w),
                                          Icon(
                                            isLast ? Icons.check_rounded : Icons.arrow_forward_rounded,
                                            size: 14.sp,
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  // Заагч сум (Pointer Arrow)
                  Positioned(
                    top: !pointingDown ? -9.5.h : null,
                    bottom: pointingDown ? -9.5.h : null,
                    child: _PointerTriangle(
                      pointingUp: !pointingDown,
                      color: pointingDown ? const Color(0xFF042419) : const Color(0xFF14532D),
                      borderColor: const Color(0xFF34D399).withValues(alpha: 0.35),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class _PointerTriangle extends StatelessWidget {
  final bool pointingUp;
  final Color color;
  final Color borderColor;

  const _PointerTriangle({
    required this.pointingUp,
    required this.color,
    required this.borderColor,
  });

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: Size(22.w, 10.h),
      painter: _PointerTrianglePainter(
        pointingUp: pointingUp,
        fillColor: color,
        strokeColor: borderColor,
      ),
    );
  }
}

class _PointerTrianglePainter extends CustomPainter {
  final bool pointingUp;
  final Color fillColor;
  final Color strokeColor;

  _PointerTrianglePainter({
    required this.pointingUp,
    required this.fillColor,
    required this.strokeColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final fillPath = Path();
    if (pointingUp) {
      fillPath.moveTo(size.width / 2, 0);
      fillPath.lineTo(size.width, size.height);
      fillPath.lineTo(0, size.height);
    } else {
      fillPath.moveTo(0, 0);
      fillPath.lineTo(size.width, 0);
      fillPath.lineTo(size.width / 2, size.height);
    }
    fillPath.close();

    final fillPaint = Paint()
      ..color = fillColor
      ..style = PaintingStyle.fill;

    canvas.drawPath(fillPath, fillPaint);

    final strokePath = Path();
    if (pointingUp) {
      strokePath.moveTo(0, size.height);
      strokePath.lineTo(size.width / 2, 0);
      strokePath.lineTo(size.width, size.height);
    } else {
      strokePath.moveTo(0, 0);
      strokePath.lineTo(size.width / 2, size.height);
      strokePath.lineTo(size.width, 0);
    }

    final strokePaint = Paint()
      ..color = strokeColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;

    canvas.drawPath(strokePath, strokePaint);
  }

  @override
  bool shouldRepaint(covariant _PointerTrianglePainter oldDelegate) {
    return oldDelegate.pointingUp != pointingUp ||
        oldDelegate.fillColor != fillColor ||
        oldDelegate.strokeColor != strokeColor;
  }
}
