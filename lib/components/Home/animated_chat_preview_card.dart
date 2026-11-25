import 'dart:async';

import 'package:flutter/cupertino.dart' show CupertinoIcons;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:sukh_app/constants/constants.dart';

/// Нүүр хуудасны «Үйлчилгээ» хэсгийн доор байрлах хөдөлгөөнт чат карт.
/// Миний байр болон Бүх байр чатуудын хооронд автоматаар болон swipe-аар шилжинэ.
class AnimatedChatPreviewCard extends StatefulWidget {
  const AnimatedChatPreviewCard({
    super.key,
    required this.isDark,
    required this.chats,
    required this.formatTime,
    required this.onTap,
  });

  final bool isDark;
  final List<Map<String, dynamic>> chats;
  final String Function(dynamic) formatTime;
  final VoidCallback onTap;

  @override
  State<AnimatedChatPreviewCard> createState() => _AnimatedChatPreviewCardState();
}

class _AnimatedChatPreviewCardState extends State<AnimatedChatPreviewCard>
    with TickerProviderStateMixin {
  static const Color _pine = Color(0xFF0A3328);
  static const Color _mint = Color(0xFF7DF0C6);

  late final AnimationController _pulseCtrl;
  late final AnimationController _sheenCtrl;
  Timer? _switchTimer;
  int _activeIdx = 0;
  int _slideDir = 1;
  bool _pressed = false;

  @override
  void initState() {
    super.initState();
    _pulseCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    )..repeat(reverse: true);
    _sheenCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 3600),
    )..repeat();
    _restartAutoSwitch();
  }

  @override
  void didUpdateWidget(covariant AnimatedChatPreviewCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.chats.length != widget.chats.length) {
      if (_activeIdx >= widget.chats.length) _activeIdx = 0;
      _restartAutoSwitch();
    }
  }

  void _restartAutoSwitch() {
    _switchTimer?.cancel();
    if (widget.chats.length > 1) {
      _switchTimer = Timer.periodic(const Duration(seconds: 4), (_) {
        if (!mounted || widget.chats.length < 2) return;
        setState(() {
          _slideDir = 1;
          _activeIdx = (_activeIdx + 1) % widget.chats.length;
        });
      });
    }
  }

  void _goToIndex(int nextIdx, int dir) {
    if (widget.chats.length < 2) return;
    HapticFeedback.selectionClick();
    setState(() {
      _slideDir = dir;
      _activeIdx = (nextIdx + widget.chats.length) % widget.chats.length;
    });
    _restartAutoSwitch();
  }

  @override
  void dispose() {
    _switchTimer?.cancel();
    _pulseCtrl.dispose();
    _sheenCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = widget.isDark;
    final chats = widget.chats;
    final safeIdx = chats.isEmpty ? 0 : (_activeIdx % chats.length);
    final chat = chats.isNotEmpty ? chats[safeIdx] : null;
    final suuliin = chat?['suuliinMessej'] is Map
        ? Map<String, dynamic>.from(chat!['suuliinMessej'] as Map)
        : null;
    final turul = chat?['turul']?.toString() ?? '';
    final scopeLabel = turul == 'buh' ? 'Бүх байр' : 'Миний байр';
    final chatTitle = (chat?['ner']?.toString().trim().isNotEmpty ?? false)
        ? chat!['ner'].toString().trim()
        : (chats.isEmpty ? 'Байрны чат' : scopeLabel);
    final sender = suuliin?['ilgeegchNer']?.toString().trim() ?? '';
    final rawText = suuliin?['text']?.toString().trim() ?? '';
    final hasMsg = suuliin != null;
    final msgText = hasMsg
        ? (rawText.isNotEmpty ? rawText : 'Зураг / файл илгээсэн')
        : 'Хөршүүд болон СӨХ-тэйгээ шууд харилцаарай';
    final timeText = widget.formatTime(suuliin?['ognoo']);
    final senderInitial = sender.isNotEmpty
        ? sender.characters.first.toUpperCase()
        : 'С';

    final fg = isDark ? Colors.white : const Color(0xFF0F2A21);
    final accent = isDark ? _mint : const Color(0xFF0E8F68);
    final cardBorder = isDark
        ? Colors.white.withValues(alpha: 0.14)
        : AppColors.deepGreen.withValues(alpha: 0.10);
    final panelBg = isDark
        ? Colors.white.withValues(alpha: 0.10)
        : Colors.white.withValues(alpha: 0.78);
    final panelBorder = isDark
        ? Colors.white.withValues(alpha: 0.15)
        : AppColors.deepGreen.withValues(alpha: 0.08);
    final btnBg = isDark ? Colors.white : AppColors.deepGreen;
    final btnFg = isDark ? AppColors.deepGreen : Colors.white;

    return GestureDetector(
      onTapDown: (_) => setState(() => _pressed = true),
      onTapCancel: () => setState(() => _pressed = false),
      onTapUp: (_) => setState(() => _pressed = false),
      onTap: widget.onTap,
      onHorizontalDragEnd: chats.length > 1
          ? (details) {
              final vx = details.primaryVelocity ?? 0;
              if (vx < -180) {
                _goToIndex(_activeIdx + 1, 1);
              } else if (vx > 180) {
                _goToIndex(_activeIdx - 1, -1);
              }
            }
          : null,
      child: AnimatedScale(
        scale: _pressed ? 0.975 : 1.0,
        duration: const Duration(milliseconds: 120),
        curve: Curves.easeOutCubic,
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(28.r),
            boxShadow: [
              BoxShadow(
                color: (isDark ? Colors.black : AppColors.deepGreen)
                    .withValues(alpha: isDark ? 0.28 : 0.08),
                blurRadius: 20,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(28.r),
            child: Stack(
              children: [
                Positioned.fill(
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: isDark
                            ? const [Color(0xFF1A7A5E), Color(0xFF0E5642), _pine]
                            : const [Color(0xFFFFFFFF), Color(0xFFF0FAF5), Color(0xFFDCF2E7)],
                      ),
                    ),
                  ),
                ),
                Positioned(
                  top: -70,
                  right: -50,
                  child: AnimatedBuilder(
                    animation: _pulseCtrl,
                    builder: (_, _) => Transform.scale(
                      scale: 0.95 + _pulseCtrl.value * 0.1,
                      child: Container(
                        width: 190,
                        height: 190,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: RadialGradient(
                            colors: [
                              (isDark ? _mint : const Color(0xFF6EE7B7))
                                  .withValues(alpha: isDark ? 0.24 : 0.30),
                              Colors.transparent,
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                Positioned.fill(
                  child: IgnorePointer(
                    child: AnimatedBuilder(
                      animation: _sheenCtrl,
                      builder: (_, _) {
                        final t = (_sheenCtrl.value * 2.4) - 0.7;
                        return DecoratedBox(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment(t - 0.5, -1),
                              end: Alignment(t + 0.5, 1),
                              colors: [
                                Colors.transparent,
                                Colors.white.withValues(alpha: isDark ? 0.06 : 0.35),
                                Colors.transparent,
                              ],
                              stops: const [0.0, 0.5, 1.0],
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ),
                Positioned.fill(
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(28.r),
                      border: Border.all(color: cardBorder),
                    ),
                  ),
                ),
                Padding(
                  padding: EdgeInsets.fromLTRB(18.w, 16.h, 16.w, 16.h),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Row(
                        children: [
                          Icon(
                            CupertinoIcons.chat_bubble_2_fill,
                            color: accent,
                            size: 18.sp,
                          ),
                          SizedBox(width: 8.w),
                          Expanded(
                            child: AnimatedSwitcher(
                              duration: const Duration(milliseconds: 300),
                              switchInCurve: Curves.easeOutCubic,
                              switchOutCurve: Curves.easeInCubic,
                              transitionBuilder: (child, anim) => FadeTransition(
                                opacity: anim,
                                child: SlideTransition(
                                  position: Tween<Offset>(
                                    begin: Offset(0.18 * _slideDir, 0),
                                    end: Offset.zero,
                                  ).animate(anim),
                                  child: child,
                                ),
                              ),
                              child: Column(
                                key: ValueKey<String>('hdr-$safeIdx-$chatTitle'),
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Flexible(
                                        child: Text(
                                          chatTitle,
                                          style: TextStyle(
                                            fontSize: 15.5.sp,
                                            fontWeight: FontWeight.w700,
                                            color: fg,
                                            letterSpacing: -0.3,
                                          ),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                      SizedBox(width: 6.w),
                                      Container(
                                        padding: EdgeInsets.symmetric(
                                          horizontal: 6.5.w,
                                          vertical: 2.h,
                                        ),
                                        decoration: BoxDecoration(
                                          gradient: LinearGradient(
                                            colors: isDark
                                                ? const [Color(0xFF34D399), Color(0xFF10B981)]
                                                : const [Color(0xFF0E8F68), Color(0xFF1A7A5E)],
                                          ),
                                          borderRadius: BorderRadius.circular(100),
                                        ),
                                        child: Text(
                                          'ШИНЭ',
                                          style: TextStyle(
                                            fontSize: 8.5.sp,
                                            fontWeight: FontWeight.w800,
                                            color: isDark ? const Color(0xFF062E22) : Colors.white,
                                            letterSpacing: 0.4,
                                          ),
                                        ),
                                      ),
                                      if (chats.length > 1) ...[
                                        SizedBox(width: 5.w),
                                        Container(
                                          padding: EdgeInsets.symmetric(
                                            horizontal: 7.w,
                                            vertical: 2.h,
                                          ),
                                          decoration: BoxDecoration(
                                            color: accent.withValues(alpha: 0.14),
                                            borderRadius: BorderRadius.circular(100),
                                          ),
                                          child: Text(
                                            scopeLabel,
                                            style: TextStyle(
                                              fontSize: 9.5.sp,
                                              fontWeight: FontWeight.w700,
                                              color: accent,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ],
                                  ),
                                  SizedBox(height: 2.h),
                                  Text(
                                    turul == 'buh'
                                        ? 'Бүх байрны хөршүүд болон СӨХ-тэй харилцах нийтлэг чат'
                                        : 'Өөрийн байр болон бүх байрны хөршүүд, СӨХ-тэй чатлах боломжтой',
                                    style: TextStyle(
                                      fontSize: 11.sp,
                                      color: fg.withValues(alpha: 0.68),
                                    ),
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ],
                              ),
                            ),
                          ),
                          SizedBox(width: 8.w),
                          Container(
                            padding: EdgeInsets.symmetric(
                              horizontal: 11.w,
                              vertical: 6.5.h,
                            ),
                            decoration: BoxDecoration(
                              color: btnBg,
                              borderRadius: BorderRadius.circular(100),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  'Чатлах',
                                  style: TextStyle(
                                    fontSize: 11.5.sp,
                                    fontWeight: FontWeight.w600,
                                    color: btnFg,
                                  ),
                                ),
                                SizedBox(width: 3.w),
                                Icon(
                                  Icons.arrow_forward_ios_rounded,
                                  size: 10.sp,
                                  color: btnFg,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 12.h),
                      AnimatedSwitcher(
                        duration: const Duration(milliseconds: 300),
                        switchInCurve: Curves.easeOutCubic,
                        switchOutCurve: Curves.easeInCubic,
                        transitionBuilder: (child, anim) => FadeTransition(
                          opacity: anim,
                          child: SlideTransition(
                            position: Tween<Offset>(
                              begin: Offset(0.16 * _slideDir, 0),
                              end: Offset.zero,
                            ).animate(anim),
                            child: child,
                          ),
                        ),
                        child: Container(
                          key: ValueKey<String>('msg-$safeIdx-$sender-$msgText-$timeText'),
                          width: double.infinity,
                          padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 10.h),
                          decoration: BoxDecoration(
                            color: panelBg,
                            borderRadius: BorderRadius.circular(16.r),
                            border: Border.all(color: panelBorder),
                          ),
                          child: Row(
                            children: [
                              Container(
                                width: 26.w,
                                height: 26.w,
                                decoration: BoxDecoration(
                                  color: accent.withValues(alpha: isDark ? 0.22 : 0.14),
                                  shape: BoxShape.circle,
                                ),
                                alignment: Alignment.center,
                                child: Text(
                                  senderInitial,
                                  style: TextStyle(
                                    fontSize: 11.5.sp,
                                    fontWeight: FontWeight.w700,
                                    color: accent,
                                  ),
                                ),
                              ),
                              SizedBox(width: 9.w),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    if (sender.isNotEmpty && hasMsg)
                                      Text(
                                        sender,
                                        style: TextStyle(
                                          fontSize: 11.sp,
                                          fontWeight: FontWeight.w700,
                                          color: accent,
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    Text(
                                      msgText,
                                      style: TextStyle(
                                        fontSize: 12.5.sp,
                                        fontWeight: hasMsg ? FontWeight.w500 : FontWeight.w400,
                                        color: fg.withValues(alpha: hasMsg ? 0.9 : 0.65),
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ],
                                ),
                              ),
                              if (timeText.isNotEmpty) ...[
                                SizedBox(width: 8.w),
                                Text(
                                  timeText,
                                  style: TextStyle(
                                    fontSize: 10.5.sp,
                                    fontWeight: FontWeight.w600,
                                    color: fg.withValues(alpha: 0.52),
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                      ),
                      if (chats.length > 1) ...[
                        SizedBox(height: 9.h),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: List.generate(chats.length, (i) {
                            final active = i == safeIdx;
                            return GestureDetector(
                              behavior: HitTestBehavior.opaque,
                              onTap: () => _goToIndex(i, i > safeIdx ? 1 : -1),
                              child: Padding(
                                padding: EdgeInsets.symmetric(
                                  horizontal: 3.w,
                                  vertical: 2.h,
                                ),
                                child: AnimatedContainer(
                                  duration: const Duration(milliseconds: 240),
                                  curve: Curves.easeOutCubic,
                                  width: active ? 16.w : 5.w,
                                  height: 4.5.h,
                                  decoration: BoxDecoration(
                                    color: active
                                        ? accent
                                        : fg.withValues(alpha: 0.2),
                                    borderRadius: BorderRadius.circular(100),
                                  ),
                                ),
                              ),
                            );
                          }),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
