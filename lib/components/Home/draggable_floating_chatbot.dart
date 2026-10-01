import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:sukh_app/constants/constants.dart';
import 'package:sukh_app/screens/Home/ai_tuslakh_page.dart';
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
      duration: const Duration(milliseconds: 320),
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
        // Вэбийн AI туслахтай ижил (оператор руу шилжих товчтой)
        builder: (context) => const AiTuslakhPage(),
      ),
    );
  }

  void _dismissChatbot() async {
    setState(() {
      _isDismissing = true;
    });

    final def = _getDefaultPosition();
    _position = def;
    await StorageService.setChatbotPosition(def.dx, def.dy);
    await StorageService.setChatbotEnabled(false);

    if (mounted) {
      showGlassSnackBar(
        context,
        message: 'Туслах чатботыг хаалаа. "Тохиргоо" цэснээс хүссэн үедээ дахин гаргаж ирэх боломжтой.',
        icon: Icons.delete_outline_rounded,
        duration: const Duration(seconds: 4),
      );
      setState(() {
        _isDismissing = false;
      });
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
              color: Colors.black.withValues(alpha: 0.15),
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
                  fontWeight: FontWeight.w600,
                  color: context.textPrimaryColor,
                ),
              ),
              SizedBox(height: 16.h),
              ListTile(
                leading: Container(
                  padding: EdgeInsets.all(8.w),
                  decoration: BoxDecoration(
                    color: AppColors.deepGreen.withValues(alpha: 0.12),
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
                    color: Colors.blueAccent.withValues(alpha: 0.12),
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
                    color: Colors.redAccent.withValues(alpha: 0.12),
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
    final start = _position ?? _getDefaultPosition();
    _snapAnimation = Tween<Offset>(
      begin: start,
      end: target,
    ).animate(
      CurvedAnimation(
        parent: _animController,
        curve: Curves.easeOutBack,
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
            // 1. DELETE TARGET — дугуй бай + шошго нь ДЭЭР нь (бөмбөлөг шошгыг
            //    дарж халхлахгүй). Бай нь deleteCenter дээр төвлөрнө.
            Positioned(
              left: 0,
              right: 0,
              top: deleteCenter.dy - 32.w - 44.h,
              child: IgnorePointer(
                child: AnimatedOpacity(
                  duration: const Duration(milliseconds: 200),
                  opacity: _isDragging ? 1.0 : 0.0,
                  child: AnimatedSlide(
                    duration: const Duration(milliseconds: 220),
                    curve: Curves.easeOutCubic,
                    offset: _isDragging ? Offset.zero : const Offset(0, 0.4),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        AnimatedContainer(
                          duration: const Duration(milliseconds: 180),
                          padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 6.h),
                          decoration: BoxDecoration(
                            color: _isOverDelete
                                ? const Color(0xFFFF3B30)
                                : (isDark
                                    ? Colors.black.withValues(alpha: 0.85)
                                    : const Color(0xFF1E293B).withValues(alpha: 0.88)),
                            borderRadius: BorderRadius.circular(100.r),
                          ),
                          child: Text(
                            _isOverDelete ? 'Устгана' : 'Устгахын тулд энд чирнэ үү',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 12.sp,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        SizedBox(height: 10.h),
                        AnimatedScale(
                          duration: const Duration(milliseconds: 180),
                          scale: _isOverDelete ? 1.15 : 1.0,
                          child: Container(
                            width: 64.w,
                            height: 64.w,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: _isOverDelete
                                  ? const Color(0xFFFF3B30)
                                  : const Color(0xFFFF3B30).withValues(alpha: 0.18),
                              border: Border.all(
                                color: const Color(0xFFFF3B30).withValues(alpha: _isOverDelete ? 1 : 0.6),
                                width: 2,
                              ),
                              boxShadow: _isOverDelete
                                  ? [
                                      BoxShadow(
                                        color: const Color(0xFFFF3B30).withValues(alpha: 0.45),
                                        blurRadius: 22,
                                        spreadRadius: 2,
                                      ),
                                    ]
                                  : null,
                            ),
                            child: Icon(
                              Icons.delete_outline_rounded,
                              color: _isOverDelete ? Colors.white : const Color(0xFFFF3B30),
                              size: 26.sp,
                            ),
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
                              .withValues(alpha: _isDragging ? 0.5 : 0.32),
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
