import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:sukh_app/constants/constants.dart';
import 'package:sukh_app/screens/Home/support_chat_page.dart';
import 'package:sukh_app/services/storage_service.dart';
import 'package:sukh_app/utils/theme_extensions.dart';
import 'package:sukh_app/widgets/glass_snackbar.dart';

class DraggableFloatingChatbot extends StatefulWidget {
  final Size screenSize;
  final double topPadding;
  final double bottomPadding;

  const DraggableFloatingChatbot({
    super.key,
    required this.screenSize,
    required this.topPadding,
    required this.bottomPadding,
  });

  @override
  State<DraggableFloatingChatbot> createState() => _DraggableFloatingChatbotState();
}

class _DraggableFloatingChatbotState extends State<DraggableFloatingChatbot>
    with SingleTickerProviderStateMixin {
  Offset? _position;
  bool _isDragging = false;
  bool _isOverDelete = false;
  bool _isDismissing = false;
  double _dragDistance = 0.0;

  late AnimationController _animController;
  Animation<Offset>? _snapAnimation;

  final double _buttonSize = 56.0;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 260),
    );
    _animController.addListener(() {
      if (_snapAnimation != null) {
        setState(() {
          _position = _snapAnimation!.value;
        });
      }
    });

    _loadInitialPosition();
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  Future<void> _loadInitialPosition() async {
    final pos = await StorageService.getChatbotPosition();
    if (!mounted) return;

    if (pos != null && pos['x'] != null && pos['y'] != null) {
      setState(() {
        _position = Offset(pos['x']!, pos['y']!);
      });
    }
  }

  Offset _getDefaultPosition() {
    final size = _buttonSize.w;
    final defaultX = widget.screenSize.width - size - 16.w;
    final defaultY = widget.screenSize.height - widget.bottomPadding - 100.h;
    return Offset(defaultX, defaultY);
  }

  void _openChat() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const SupportChatPage(extra: {}),
      ),
    );
  }

  void _dismissChatbot() async {
    setState(() {
      _isDismissing = true;
    });

    await StorageService.setChatbotEnabled(false);

    if (mounted) {
      showGlassSnackBar(
        context,
        message: 'Туслах чатботыг хаалаа. "Тохиргоо" цэснээс хүссэн үедээ дахин гаргаж ирэх боломжтой.',
        icon: Icons.delete_outline_rounded,
        duration: const Duration(seconds: 4),
      );
    }
  }

  void _showOptionsModal() {
    final isDark = context.isDarkMode;
    HapticFeedback.mediumImpact();

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 20.h),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1E242B) : Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24.r)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.15),
              blurRadius: 20,
              offset: const Offset(0, -4),
            ),
          ],
        ),
        child: SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40.w,
                height: 4.h,
                decoration: BoxDecoration(
                  color: isDark ? Colors.white24 : Colors.black12,
                  borderRadius: BorderRadius.circular(2.r),
                ),
              ),
              SizedBox(height: 16.h),
              Text(
                'Туслах чатбот',
                style: TextStyle(
                  fontSize: 16.sp,
                  fontWeight: FontWeight.bold,
                  color: context.textPrimaryColor,
                ),
              ),
              SizedBox(height: 16.h),
              ListTile(
                leading: Container(
                  padding: EdgeInsets.all(8.w),
                  decoration: BoxDecoration(
                    color: AppColors.deepGreen.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(10.r),
                  ),
                  child: Icon(Icons.chat_bubble_outline_rounded, color: AppColors.deepGreen, size: 20.sp),
                ),
                title: Text(
                  'Чатлах',
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 14.sp,
                    color: context.textPrimaryColor,
                  ),
                ),
                onTap: () {
                  Navigator.pop(ctx);
                  _openChat();
                },
              ),
              ListTile(
                leading: Container(
                  padding: EdgeInsets.all(8.w),
                  decoration: BoxDecoration(
                    color: Colors.blueAccent.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(10.r),
                  ),
                  child: Icon(Icons.refresh_rounded, color: Colors.blueAccent, size: 20.sp),
                ),
                title: Text(
                  'Байрлал шинэчлэх (Баруун доор)',
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 14.sp,
                    color: context.textPrimaryColor,
                  ),
                ),
                onTap: () {
                  Navigator.pop(ctx);
                  final def = _getDefaultPosition();
                  _animateTo(def);
                  StorageService.setChatbotPosition(def.dx, def.dy);
                },
              ),
              ListTile(
                leading: Container(
                  padding: EdgeInsets.all(8.w),
                  decoration: BoxDecoration(
                    color: Colors.redAccent.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(10.r),
                  ),
                  child: Icon(Icons.delete_outline_rounded, color: Colors.redAccent, size: 20.sp),
                ),
                title: Text(
                  'Нүүр хуудаснаас хаах / устгах',
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 14.sp,
                    color: Colors.redAccent,
                  ),
                ),
                subtitle: Text(
                  'Тохиргоо цэснээс хүссэн үедээ буцааж гаргах боломжтой',
                  style: TextStyle(fontSize: 11.sp, color: context.textSecondaryColor),
                ),
                onTap: () {
                  Navigator.pop(ctx);
                  _dismissChatbot();
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _animateTo(Offset target) {
    if (_position == null) return;
    _snapAnimation = Tween<Offset>(
      begin: _position!,
      end: target,
    ).animate(
      CurvedAnimation(
        parent: _animController,
        curve: Curves.easeOutCubic,
      ),
    );
    _animController.forward(from: 0.0);
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<bool>(
      valueListenable: StorageService.chatbotEnabledNotifier,
      builder: (context, isEnabled, child) {
        if (!isEnabled || _isDismissing) return const SizedBox.shrink();

        final buttonW = _buttonSize.w;
        final currentPos = _position ?? _getDefaultPosition();
        final isDark = context.isDarkMode;

        final minX = 12.w;
        final maxX = widget.screenSize.width - buttonW - 12.w;
        final minY = widget.topPadding + 50.h;
        final maxY = widget.screenSize.height - widget.bottomPadding - 65.h;

        // Delete center coordinates
        final deleteCenter = Offset(
          widget.screenSize.width / 2,
          widget.screenSize.height - widget.bottomPadding - 40.h,
        );

        return Stack(
          children: [
            // 1. DELETE TARGET (Smooth Fade & Slide in during dragging)
            AnimatedPositioned(
              duration: const Duration(milliseconds: 200),
              curve: Curves.easeOutCubic,
              bottom: _isDragging ? widget.bottomPadding + 18.h : widget.bottomPadding - 40.h,
              left: (widget.screenSize.width - (_isOverDelete ? 170.w : 145.w)) / 2,
              child: AnimatedOpacity(
                duration: const Duration(milliseconds: 200),
                opacity: _isDragging ? 1.0 : 0.0,
                child: AnimatedScale(
                  duration: const Duration(milliseconds: 200),
                  scale: _isDragging ? 1.0 : 0.8,
                  child: Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: _isOverDelete ? 22.w : 16.w,
                      vertical: _isOverDelete ? 12.h : 10.h,
                    ),
                    decoration: BoxDecoration(
                      color: _isOverDelete
                          ? const Color(0xFFFF3B30)
                          : (isDark
                              ? Colors.black.withOpacity(0.85)
                              : const Color(0xFF1E293B).withOpacity(0.9)),
                      borderRadius: BorderRadius.circular(100.r),
                      border: Border.all(
                        color: _isOverDelete
                            ? Colors.white
                            : Colors.white.withOpacity(0.35),
                        width: _isOverDelete ? 2 : 1,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: (_isOverDelete ? const Color(0xFFFF3B30) : Colors.black)
                              .withOpacity(0.4),
                          blurRadius: _isOverDelete ? 22 : 10,
                          spreadRadius: _isOverDelete ? 3 : 0,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          _isOverDelete
                              ? Icons.delete_forever_rounded
                              : Icons.delete_outline_rounded,
                          color: Colors.white,
                          size: _isOverDelete ? 22.sp : 18.sp,
                        ),
                        SizedBox(width: 6.w),
                        Text(
                          _isOverDelete ? 'Энд тавьж устгах' : 'Хаах / Устгах',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: _isOverDelete ? 13.sp : 12.sp,
                            fontWeight: _isOverDelete ? FontWeight.bold : FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),

            // 2. DRAGGABLE CHATBOT BUBBLE (Isolated smooth positioning)
            Positioned(
              left: currentPos.dx,
              top: currentPos.dy,
              child: GestureDetector(
                onPanStart: (details) {
                  _animController.stop();
                  setState(() {
                    _isDragging = true;
                    _dragDistance = 0.0;
                  });
                  HapticFeedback.selectionClick();
                },
                onPanUpdate: (details) {
                  _dragDistance += details.delta.distance;
                  final newX = (currentPos.dx + details.delta.dx).clamp(minX, maxX);
                  final newY = (currentPos.dy + details.delta.dy).clamp(minY, maxY);

                  final botCenter = Offset(newX + buttonW / 2, newY + buttonW / 2);
                  final dist = (botCenter - deleteCenter).distance;
                  final isOver = dist < 80.w;

                  if (isOver != _isOverDelete) {
                    if (isOver) {
                      HapticFeedback.mediumImpact();
                    }
                  }

                  setState(() {
                    _position = Offset(newX, newY);
                    _isOverDelete = isOver;
                  });
                },
                onPanEnd: (details) {
                  if (_dragDistance < 8.0) {
                    // Small touch is treated as a tap
                    setState(() {
                      _isDragging = false;
                      _isOverDelete = false;
                    });
                    _openChat();
                    return;
                  }

                  if (_isOverDelete) {
                    HapticFeedback.heavyImpact();
                    setState(() {
                      _isDragging = false;
                      _isOverDelete = false;
                    });
                    _dismissChatbot();
                  } else {
                    // Snap smoothly to nearest horizontal edge
                    final snapX = (currentPos.dx + buttonW / 2 < widget.screenSize.width / 2)
                        ? minX
                        : maxX;
                    final targetPos = Offset(snapX, currentPos.dy.clamp(minY, maxY));

                    setState(() {
                      _isDragging = false;
                      _isOverDelete = false;
                    });

                    _animateTo(targetPos);
                    StorageService.setChatbotPosition(targetPos.dx, targetPos.dy);
                  }
                },
                onTap: _openChat,
                onLongPress: _showOptionsModal,
                child: AnimatedScale(
                  scale: _isOverDelete ? 0.82 : (_isDragging ? 1.08 : 1.0),
                  duration: const Duration(milliseconds: 160),
                  curve: Curves.easeOutCubic,
                  child: Container(
                    width: buttonW,
                    height: buttonW,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: LinearGradient(
                        colors: _isOverDelete
                            ? [const Color(0xFFFF6B6B), const Color(0xFFFF3B30)]
                            : [AppColors.deepGreen, AppColors.deepGreenDark],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: (_isOverDelete
                                  ? const Color(0xFFFF3B30)
                                  : AppColors.deepGreen)
                              .withOpacity(_isDragging ? 0.5 : 0.32),
                          blurRadius: _isDragging ? 18 : 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        Icon(
                          _isOverDelete
                              ? Icons.close_rounded
                              : Icons.support_agent_rounded,
                          size: 28.sp,
                          color: Colors.white,
                        ),
                        if (!_isDragging && !_isOverDelete)
                          Positioned(
                            top: 10.w,
                            right: 12.w,
                            child: Container(
                              width: 8.w,
                              height: 8.w,
                              decoration: BoxDecoration(
                                color: const Color(0xFF4ADE80),
                                shape: BoxShape.circle,
                                border: Border.all(color: Colors.white, width: 1.5),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}
