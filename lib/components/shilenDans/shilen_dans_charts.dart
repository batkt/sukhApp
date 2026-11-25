import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:intl/intl.dart' show NumberFormat;
import 'package:sukh_app/constants/constants.dart';
import 'package:sukh_app/utils/theme_extensions.dart';

class ShilenDansColors {
  static const Color nogoon = Color(0xFF10B981);
  static const Color saaral = Color(0xFF94A3B8);
}

final NumberFormat _too = NumberFormat('#,##0', 'en_US');
String shilenDansMungu(num? v) => v == null ? '—' : '${_too.format(v.round())} ₮';
double shilenDansToDouble(dynamic v) => v is num ? v.toDouble() : double.tryParse('$v') ?? 0;

class CircleDonutChart extends StatefulWidget {
  const CircleDonutChart({
    super.key,
    required this.tolovlogoot,
    required this.orlogo,
    required this.avlaga,
    required this.zardal,
    this.avlagaAilToo = 0,
    this.onTolovlogootTap,
    this.onOrlogoTap,
    this.onAvlagaTap,
    this.onZardalTap,
  });

  final double tolovlogoot;
  final double orlogo;
  final double avlaga;
  final double zardal;
  final int avlagaAilToo;
  final VoidCallback? onTolovlogootTap;
  final VoidCallback? onOrlogoTap;
  final VoidCallback? onAvlagaTap;
  final VoidCallback? onZardalTap;

  static const Color tolovlogootColor = Color(0xFF2563EB); // Цэнхэр (Төлөвлөгөөт)
  static const Color orlogoColor = Color(0xFF10B981);      // Маргад ногоон (Орлого)
  static const Color avlagaColor = Color(0xFFF59E0B);      // Алтлаг шаргал (Авлага)
  static const Color zardalColor = Color(0xFFEF4444);      // Шүрэн улаан (Зардал)

  @override
  State<CircleDonutChart> createState() => CircleDonutChartState();
}

class _DonutSlice {
  const _DonutSlice({
    required this.index,
    required this.startAngle,
    required this.sweepAngle,
    required this.color,
  });

  final int index;
  final double startAngle;
  final double sweepAngle;
  final Color color;
}

class CircleDonutChartState extends State<CircleDonutChart>
    with SingleTickerProviderStateMixin {
  late AnimationController _anim;
  late Animation<double> _curve;
  int _selectedIndex = -1;

  static const _colors = [
    CircleDonutChart.tolovlogootColor,
    CircleDonutChart.orlogoColor,
    CircleDonutChart.avlagaColor,
    CircleDonutChart.zardalColor,
  ];

  @override
  void initState() {
    super.initState();
    _anim = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 650),
    );
    _curve = CurvedAnimation(parent: _anim, curve: Curves.easeOutCubic);
    _anim.forward();
  }

  @override
  void didUpdateWidget(covariant CircleDonutChart oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.tolovlogoot != widget.tolovlogoot ||
        oldWidget.orlogo != widget.orlogo ||
        oldWidget.avlaga != widget.avlaga ||
        oldWidget.zardal != widget.zardal) {
      _anim.reset();
      _anim.forward();
    }
  }

  @override
  void dispose() {
    _anim.dispose();
    super.dispose();
  }

  List<_DonutSlice> _computeSlices() {
    final values = [
      math.max(0.0, widget.tolovlogoot),
      math.max(0.0, widget.orlogo),
      math.max(0.0, widget.avlaga),
      math.max(0.0, widget.zardal),
    ];

    final activeIndices = <int>[
      for (var i = 0; i < values.length; i++)
        if (values[i] > 0) i,
    ];
    if (activeIndices.isEmpty) return const [];

    if (activeIndices.length == 1) {
      final idx = activeIndices.first;
      return [
        _DonutSlice(
          index: idx,
          startAngle: -math.pi / 2,
          sweepAngle: 2 * math.pi,
          color: _colors[idx],
        ),
      ];
    }

    const gap = 0.045; // ~2.6 градусын цэвэр зай
    const minSweep = 0.10;
    final totalSweep = 2 * math.pi - activeIndices.length * gap;
    final sum = activeIndices.fold<double>(0, (acc, i) => acc + values[i]);

    final rawSweeps = <int, double>{
      for (final i in activeIndices) i: (values[i] / sum) * totalSweep,
    };

    // Жижиг утгатай сегмент харагдахуйц байхын тулд хамгийн бага өнцгийг хадгална
    var lockedSweep = 0.0;
    var flexibleSum = 0.0;
    final locked = <int>{};
    for (final i in activeIndices) {
      if (rawSweeps[i]! < minSweep) {
        locked.add(i);
        lockedSweep += minSweep;
      } else {
        flexibleSum += values[i];
      }
    }

    final remainingSweep = math.max(0.0, totalSweep - lockedSweep);
    final slices = <_DonutSlice>[];
    var cursor = -math.pi / 2;

    for (final i in activeIndices) {
      final sweep = locked.contains(i)
          ? minSweep
          : (flexibleSum > 0 ? (values[i] / flexibleSum) * remainingSweep : 0.0);
      slices.add(
        _DonutSlice(
          index: i,
          startAngle: cursor,
          sweepAngle: sweep,
          color: _colors[i],
        ),
      );
      cursor += sweep + gap;
    }

    return slices;
  }

  void _openModalForIndex(int idx) {
    switch (idx) {
      case 0:
        widget.onTolovlogootTap?.call();
        break;
      case 1:
        widget.onOrlogoTap?.call();
        break;
      case 2:
        widget.onAvlagaTap?.call();
        break;
      case 3:
        widget.onZardalTap?.call();
        break;
    }
  }

  void _onTapSegment(int idx) {
    HapticFeedback.selectionClick();
    setState(() {
      _selectedIndex = _selectedIndex == idx ? -1 : idx;
    });
  }

  void _handleDonutTap(Offset localPos, Size size, List<_DonutSlice> slices) {
    final center = Offset(size.width / 2, size.height / 2);
    final dx = localPos.dx - center.dx;
    final dy = localPos.dy - center.dy;
    final dist = math.sqrt(dx * dx + dy * dy);

    final innerR = size.width * 0.285;
    final outerR = size.width * 0.48;

    if (dist <= innerR) {
      if (_selectedIndex >= 0) {
        _openModalForIndex(_selectedIndex);
      }
      return;
    }

    if (dist > outerR || slices.isEmpty) {
      if (_selectedIndex != -1) {
        setState(() => _selectedIndex = -1);
      }
      return;
    }

    // Өнцгийг -pi/2-оос эхлэн [0, 2*pi) мужид хөрвүүлнэ
    var angle = math.atan2(dy, dx) - (-math.pi / 2);
    while (angle < 0) {
      angle += 2 * math.pi;
    }
    while (angle >= 2 * math.pi) {
      angle -= 2 * math.pi;
    }

    for (final s in slices) {
      var start = s.startAngle - (-math.pi / 2);
      while (start < 0) {
        start += 2 * math.pi;
      }
      if (angle >= start && angle <= start + s.sweepAngle + 0.04) {
        if (_selectedIndex == s.index) {
          _openModalForIndex(s.index);
        } else {
          _onTapSegment(s.index);
        }
        return;
      }
    }
  }

  Widget _buildMetricTile({
    required int idx,
    required String label,
    required String amount,
    required String subtitle,
    required Color color,
    required bool isDark,
    required VoidCallback onTap,
  }) {
    final isSelected = _selectedIndex == idx;
    final bgColor = isSelected
        ? color.withValues(alpha: isDark ? 0.16 : 0.08)
        : (isDark
            ? Colors.white.withValues(alpha: 0.04)
            : const Color(0xFFF8FAFC));
    final borderColor = isSelected
        ? color.withValues(alpha: 0.55)
        : (isDark
            ? Colors.white.withValues(alpha: 0.08)
            : const Color(0xFFE2E8F0));

    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: EdgeInsets.symmetric(horizontal: 11.w, vertical: 10.h),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(10.r),
          border: Border.all(color: borderColor, width: isSelected ? 1.3 : 1.0),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                Container(
                  width: 8.w,
                  height: 8.w,
                  decoration: BoxDecoration(color: color, shape: BoxShape.circle),
                ),
                SizedBox(width: 6.w),
                Expanded(
                  child: Text(
                    label,
                    style: TextStyle(
                      fontSize: 11.sp,
                      fontWeight: FontWeight.w600,
                      color: isSelected ? color : context.textSecondaryColor,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Icon(
                  Icons.chevron_right_rounded,
                  size: 14.sp,
                  color: isSelected ? color : context.textSecondaryColor,
                ),
              ],
            ),
            SizedBox(height: 5.h),
            FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerLeft,
              child: Text(
                amount,
                style: TextStyle(
                  fontSize: 15.sp,
                  fontWeight: FontWeight.w700,
                  color: context.textPrimaryColor,
                  letterSpacing: -0.2,
                ),
              ),
            ),
            SizedBox(height: 2.h),
            Text(
              subtitle,
              style: TextStyle(
                fontSize: 10.sp,
                color: context.textSecondaryColor,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = context.isDarkMode;
    final slices = _computeSlices();

    final baseTarget = widget.tolovlogoot > 0
        ? widget.tolovlogoot
        : (widget.orlogo + widget.avlaga > 0 ? widget.orlogo + widget.avlaga : 1.0);

    final orlogoPercent = (widget.orlogo / baseTarget * 100);
    final avlagaPercent = (widget.avlaga / baseTarget * 100);
    final orlogoPStr = (orlogoPercent > 0 && orlogoPercent < 1)
        ? orlogoPercent.toStringAsFixed(1)
        : orlogoPercent.round().toString();
    final avlagaPStr = (avlagaPercent > 0 && avlagaPercent < 1)
        ? avlagaPercent.toStringAsFixed(1)
        : avlagaPercent.round().toString();

    const labels = ['ТӨЛӨВЛӨГӨӨТ', 'ОРЛОГО', 'АВЛАГА', 'ЗАРДАЛ'];
    final amounts = [
      widget.tolovlogoot,
      widget.orlogo,
      widget.avlaga,
      widget.zardal,
    ];

    final Widget centerContent;
    if (_selectedIndex >= 0 && _selectedIndex < 4) {
      final selColor = _colors[_selectedIndex];
      centerContent = Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            labels[_selectedIndex],
            style: TextStyle(
              fontSize: 9.sp,
              fontWeight: FontWeight.w700,
              color: selColor,
              letterSpacing: 0.4,
            ),
          ),
          SizedBox(height: 2.h),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              shilenDansMungu(amounts[_selectedIndex]),
              style: TextStyle(
                fontSize: 14.5.sp,
                fontWeight: FontWeight.w800,
                color: context.textPrimaryColor,
              ),
            ),
          ),
          SizedBox(height: 2.h),
          Text(
            'Дэлгэрэнгүй ›',
            style: TextStyle(
              fontSize: 9.sp,
              fontWeight: FontWeight.w600,
              color: selColor,
            ),
          ),
        ],
      );
    } else {
      centerContent = Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'ТӨЛӨЛТ',
            style: TextStyle(
              fontSize: 9.5.sp,
              fontWeight: FontWeight.w600,
              color: context.textSecondaryColor,
              letterSpacing: 0.6,
            ),
          ),
          SizedBox(height: 1.h),
          Text(
            '$orlogoPStr%',
            style: TextStyle(
              fontSize: 25.sp,
              fontWeight: FontWeight.w800,
              color: context.textPrimaryColor,
              height: 1.1,
            ),
          ),
          SizedBox(height: 1.h),
          Text(
            'цугларалт',
            style: TextStyle(
              fontSize: 10.sp,
              color: context.textSecondaryColor,
            ),
          ),
        ],
      );
    }

    final chartSize = 180.w;

    return Column(
      children: [
        SizedBox(height: 4.h),
        Center(
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTapUp: (details) =>
                _handleDonutTap(details.localPosition, Size(chartSize, chartSize), slices),
            child: SizedBox(
              width: chartSize,
              height: chartSize,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  AnimatedBuilder(
                    animation: _curve,
                    builder: (context, _) {
                      return CustomPaint(
                        size: Size(chartSize, chartSize),
                        painter: _CircularStepInfographicPainter(
                          slices: slices,
                          selectedIndex: _selectedIndex,
                          progress: _curve.value,
                          isDark: isDark,
                        ),
                      );
                    },
                  ),
                  SizedBox(
                    width: chartSize * 0.52,
                    child: AnimatedSwitcher(
                      duration: const Duration(milliseconds: 180),
                      child: Container(
                        key: ValueKey<int>(_selectedIndex),
                        alignment: Alignment.center,
                        child: centerContent,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        SizedBox(height: 14.h),
        Row(
          children: [
            Expanded(
              child: _buildMetricTile(
                idx: 0,
                label: 'Төлөвлөгөөт',
                amount: shilenDansMungu(widget.tolovlogoot),
                subtitle: 'Нэхэмжилсэн',
                color: CircleDonutChart.tolovlogootColor,
                isDark: isDark,
                onTap: () {
                  _onTapSegment(0);
                  widget.onTolovlogootTap?.call();
                },
              ),
            ),
            SizedBox(width: 8.w),
            Expanded(
              child: _buildMetricTile(
                idx: 1,
                label: 'Орлого',
                amount: shilenDansMungu(widget.orlogo),
                subtitle: 'Төлөгдсөн · $orlogoPStr%',
                color: CircleDonutChart.orlogoColor,
                isDark: isDark,
                onTap: () {
                  _onTapSegment(1);
                  widget.onOrlogoTap?.call();
                },
              ),
            ),
          ],
        ),
        SizedBox(height: 8.h),
        Row(
          children: [
            Expanded(
              child: _buildMetricTile(
                idx: 2,
                label: 'Авлага',
                amount: shilenDansMungu(widget.avlaga),
                subtitle: widget.avlagaAilToo > 0
                    ? 'Төлөөгүй ${widget.avlagaAilToo} айл'
                    : 'Төлөөгүй · $avlagaPStr%',
                color: CircleDonutChart.avlagaColor,
                isDark: isDark,
                onTap: () {
                  _onTapSegment(2);
                  widget.onAvlagaTap?.call();
                },
              ),
            ),
            SizedBox(width: 8.w),
            Expanded(
              child: _buildMetricTile(
                idx: 3,
                label: 'Зардал',
                amount: shilenDansMungu(widget.zardal),
                subtitle: 'СӨХ-ийн зардал',
                color: CircleDonutChart.zardalColor,
                isDark: isDark,
                onTap: () {
                  _onTapSegment(3);
                  widget.onZardalTap?.call();
                },
              ),
            ),
          ],
        ),
      ],
    );
  }
}

/// Пропорциональ цагираг (Donut) зурагч
class _CircularStepInfographicPainter extends CustomPainter {
  _CircularStepInfographicPainter({
    required this.slices,
    required this.selectedIndex,
    required this.progress,
    required this.isDark,
  });

  final List<_DonutSlice> slices;
  final int selectedIndex;
  final double progress;
  final bool isDark;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final baseOuterR = size.width * 0.455;
    final baseInnerR = size.width * 0.295;
    final midR = (baseOuterR + baseInnerR) / 2;
    final baseThickness = baseOuterR - baseInnerR;

    // Суурь цагираг (track)
    canvas.drawCircle(
      center,
      midR,
      Paint()
        ..color = isDark
            ? Colors.white.withValues(alpha: 0.06)
            : const Color(0xFFF1F5F9)
        ..style = PaintingStyle.stroke
        ..strokeWidth = baseThickness,
    );

    if (slices.isEmpty) return;

    final hasSelection = selectedIndex >= 0;

    for (final slice in slices) {
      final isSel = selectedIndex == slice.index;
      final sweep = slice.sweepAngle * progress;
      if (sweep <= 0.001) continue;

      final outerR = isSel ? baseOuterR + 3.5.w : baseOuterR;
      final innerR = isSel ? baseInnerR - 1.w : baseInnerR;

      final segPath = Path()
        ..arcTo(
          Rect.fromCircle(center: center, radius: outerR),
          slice.startAngle,
          sweep,
          false,
        )
        ..arcTo(
          Rect.fromCircle(center: center, radius: innerR),
          slice.startAngle + sweep,
          -sweep,
          false,
        )
        ..close();

      if (isSel) {
        canvas.drawPath(
          segPath,
          Paint()
            ..color = slice.color.withValues(alpha: 0.35)
            ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6),
        );
      }

      final fillColor = hasSelection && !isSel
          ? slice.color.withValues(alpha: 0.32)
          : slice.color;

      canvas.drawPath(
        segPath,
        Paint()
          ..color = fillColor
          ..style = PaintingStyle.fill,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _CircularStepInfographicPainter old) {
    return old.slices != slices ||
        old.selectedIndex != selectedIndex ||
        old.progress != progress ||
        old.isDark != isDark;
  }
}

class _Tailbar extends StatelessWidget {
  const _Tailbar({required this.ungu, required this.ner, this.tasarkhai = false});

  final Color ungu;
  final String ner;
  final bool tasarkhai;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          width: 18.w,
          height: 2,
          child: tasarkhai
              ? Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    for (var i = 0; i < 3; i++)
                      Container(width: 4.w, height: 2, color: ungu),
                  ],
                )
              : Container(color: ungu),
        ),
        SizedBox(width: 6.w),
        Text(ner, style: TextStyle(fontSize: 12.sp, color: context.textSecondaryColor)),
      ],
    );
  }
}


// ── Интерактив сарын өдрүүдийн орлого, зардал график ────────────────────

class InteractiveUrsgalGraph extends StatefulWidget {
  const InteractiveUrsgalGraph({
    super.key,
    required this.sar,
    required this.orloguud,
    required this.zarlaguud,
    required this.tekstUngu,
    required this.shugamUngu,
  });

  final String sar;
  final List<Map<String, dynamic>> orloguud;
  final List<Map<String, dynamic>> zarlaguud;
  final Color tekstUngu;
  final Color shugamUngu;

  @override
  State<InteractiveUrsgalGraph> createState() => InteractiveUrsgalGraphState();
}

class InteractiveUrsgalGraphState extends State<InteractiveUrsgalGraph> {
  int? _selectedIndex;
  late List<Map<String, dynamic>> _odroor;

  @override
  void initState() {
    super.initState();
    _odroor = _buildDailyData();
    _pickDefaultIndex();
  }

  @override
  void didUpdateWidget(covariant InteractiveUrsgalGraph oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.sar != widget.sar ||
        oldWidget.orloguud != widget.orloguud ||
        oldWidget.zarlaguud != widget.zarlaguud) {
      _odroor = _buildDailyData();
      _pickDefaultIndex();
    }
  }

  void _pickDefaultIndex() {
    if (_odroor.isEmpty) {
      _selectedIndex = null;
      return;
    }
    // Хамгийн сүүлд гүйлгээ хийгдсэн өдөр, эсвэл сүүлийн өдрийг сонгоно
    int lastActive = _odroor.length - 1;
    for (var i = _odroor.length - 1; i >= 0; i--) {
      if (shilenDansToDouble(_odroor[i]['tulsun']) > 0 ||
          shilenDansToDouble(_odroor[i]['zardal']) > 0) {
        lastActive = i;
        break;
      }
    }
    _selectedIndex = lastActive;
  }

  List<Map<String, dynamic>> _buildDailyData() {
    final parts = widget.sar.split('-');
    final now = DateTime.now();
    final year = parts.length == 2 ? (int.tryParse(parts[0]) ?? now.year) : now.year;
    final month = parts.length == 2 ? (int.tryParse(parts[1]) ?? now.month) : now.month;
    final daysInMonth = DateTime(year, month + 1, 0).day;
    final isCurrentMonth = year == now.year && month == now.month;
    final maxDay = isCurrentMonth ? math.min(now.day, daysInMonth) : daysInMonth;

    final orlogoByDay = <int, double>{};
    for (final o in widget.orloguud) {
      final raw = '${o['ognoo'] ?? o['createdAt'] ?? ''}'.split('T').first;
      if (!raw.startsWith(widget.sar)) continue;
      final segs = raw.split('-');
      if (segs.length == 3) {
        final d = int.tryParse(segs[2]);
        if (d != null && d >= 1 && d <= daysInMonth) {
          orlogoByDay[d] = (orlogoByDay[d] ?? 0) + shilenDansToDouble(o['dun']);
        }
      }
    }

    final zardalByDay = <int, double>{};
    for (final z in widget.zarlaguud) {
      final raw = '${z['ognoo'] ?? ''}'.split('T').first;
      if (!raw.startsWith(widget.sar)) continue;
      final segs = raw.split('-');
      if (segs.length == 3) {
        final d = int.tryParse(segs[2]);
        if (d != null && d >= 1 && d <= daysInMonth) {
          zardalByDay[d] = (zardalByDay[d] ?? 0) + shilenDansToDouble(z['dun']);
        }
      }
    }

    return List.generate(maxDay, (i) {
      final day = i + 1;
      return {
        'odor': day,
        'ognoo': '${widget.sar}-${day.toString().padLeft(2, '0')}',
        'tulsun': orlogoByDay[day] ?? 0.0,
        'zardal': zardalByDay[day] ?? 0.0,
      };
    });
  }

  void _onPositionUpdate(double localDx, double width) {
    if (_odroor.isEmpty) return;
    const zuun = 38.0;
    final urgun = width - zuun - 10;
    if (urgun <= 0) return;
    final relX = (localDx - zuun).clamp(0.0, urgun);
    final count = _odroor.length;
    final idx = count == 1 ? 0 : ((relX / urgun) * (count - 1)).round().clamp(0, count - 1);
    if (idx != _selectedIndex) {
      setState(() => _selectedIndex = idx);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = context.isDarkMode;
    final odroor = _odroor;

    Map<String, dynamic>? selectedItem;
    if (_selectedIndex != null && _selectedIndex! >= 0 && _selectedIndex! < odroor.length) {
      selectedItem = odroor[_selectedIndex!];
    }

    double selOrlogo = 0;
    double selZardal = 0;
    double selZuruu = 0;
    String selOgnooNer = '';

    if (selectedItem != null) {
      selOrlogo = shilenDansToDouble(selectedItem['tulsun']);
      selZardal = shilenDansToDouble(selectedItem['zardal']);
      selZuruu = selOrlogo - selZardal;
      final parts = '${selectedItem['ognoo']}'.split('-');
      selOgnooNer = parts.length == 3
          ? '${int.tryParse(parts[1]) ?? parts[1]}-р сарын ${int.tryParse(parts[2]) ?? parts[2]}'
          : '${selectedItem['ognoo']}';
    }

    return Column(
      children: [
        if (selectedItem != null) ...[
          Container(
            padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 8.h),
            decoration: BoxDecoration(
              color: isDark ? AppColors.darkSurface : const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(12.r),
              border: Border.all(color: context.borderColor, width: 0.8),
            ),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Flexible(
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            padding: EdgeInsets.all(4.w),
                            decoration: BoxDecoration(
                              color: AppColors.primary.withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(6.r),
                            ),
                            child: Icon(Icons.calendar_today_rounded, size: 12.w, color: AppColors.primary),
                          ),
                          SizedBox(width: 6.w),
                          Flexible(
                            child: Text(
                              selOgnooNer,
                              style: TextStyle(
                                fontSize: 12.sp,
                                fontWeight: FontWeight.w700,
                                color: context.textPrimaryColor,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ),
                    SizedBox(width: 8.w),
                    Container(
                      padding: EdgeInsets.symmetric(horizontal: 7.w, vertical: 2.h),
                      decoration: BoxDecoration(
                        color: (selZuruu >= 0 ? const Color(0xFF10B981) : Colors.redAccent).withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(10.r),
                      ),
                      child: Text(
                        'Цэвэр: ${selZuruu >= 0 ? '+' : ''}${shilenDansMungu(selZuruu)}',
                        style: TextStyle(
                          fontSize: 10.5.sp,
                          fontWeight: FontWeight.w700,
                          color: selZuruu >= 0 ? const Color(0xFF10B981) : Colors.redAccent,
                        ),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 6.h),
                Row(
                  children: [
                    Expanded(
                      child: Container(
                        padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 5.h),
                        decoration: BoxDecoration(
                          color: const Color(0xFF10B981).withValues(alpha: 0.08),
                          borderRadius: BorderRadius.circular(8.r),
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 6.w,
                              height: 6.w,
                              decoration: const BoxDecoration(
                                color: Color(0xFF10B981),
                                shape: BoxShape.circle,
                              ),
                            ),
                            SizedBox(width: 5.w),
                            Text('Орлого:', style: TextStyle(fontSize: 10.5.sp, color: context.textSecondaryColor)),
                            SizedBox(width: 4.w),
                            Expanded(
                              child: FittedBox(
                                fit: BoxFit.scaleDown,
                                alignment: Alignment.centerRight,
                                child: Text(
                                  shilenDansMungu(selOrlogo),
                                  style: TextStyle(
                                    fontSize: 11.5.sp,
                                    fontWeight: FontWeight.w700,
                                    color: const Color(0xFF10B981),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    SizedBox(width: 8.w),
                    Expanded(
                      child: Container(
                        padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 5.h),
                        decoration: BoxDecoration(
                          color: Colors.redAccent.withValues(alpha: 0.08),
                          borderRadius: BorderRadius.circular(8.r),
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 6.w,
                              height: 6.w,
                              decoration: const BoxDecoration(
                                color: Colors.redAccent,
                                shape: BoxShape.circle,
                              ),
                            ),
                            SizedBox(width: 5.w),
                            Text('Зардал:', style: TextStyle(fontSize: 10.5.sp, color: context.textSecondaryColor)),
                            SizedBox(width: 4.w),
                            Expanded(
                              child: FittedBox(
                                fit: BoxFit.scaleDown,
                                alignment: Alignment.centerRight,
                                child: Text(
                                  shilenDansMungu(selZardal),
                                  style: TextStyle(
                                    fontSize: 11.5.sp,
                                    fontWeight: FontWeight.w700,
                                    color: Colors.redAccent,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          SizedBox(height: 10.h),
        ],
        LayoutBuilder(
          builder: (context, constraints) {
            return GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTapDown: (details) =>
                  _onPositionUpdate(details.localPosition.dx, constraints.maxWidth),
              onPanUpdate: (details) =>
                  _onPositionUpdate(details.localPosition.dx, constraints.maxWidth),
              child: SizedBox(
                height: 175.h,
                child: CustomPaint(
                  size: Size.infinite,
                  painter: _UrsgalPainter(
                    odroor: odroor,
                    selectedIndex: _selectedIndex,
                    tekstUngu: widget.tekstUngu,
                    shugamUngu: widget.shugamUngu,
                    accentUngu: AppColors.primary,
                  ),
                ),
              ),
            );
          },
        ),
        SizedBox(height: 8.h),
        Wrap(
          alignment: WrapAlignment.center,
          spacing: 16.w,
          runSpacing: 6.h,
          children: const [
            _Tailbar(ungu: ShilenDansColors.nogoon, ner: 'Орлого (орсон)'),
            _Tailbar(ungu: ShilenDansColors.saaral, ner: 'Зардал (гарсан)', tasarkhai: true),
          ],
        ),
      ],
    );
  }
}

// ── Зураг ──────────────────────────────────────────────────────────────

/// Сарын өдрүүдийн орлого (бүтэн гөлгөр муруй) ба зарцуулалт (тасархай муруй).
class _UrsgalPainter extends CustomPainter {
  _UrsgalPainter({
    required this.odroor,
    required this.tekstUngu,
    required this.shugamUngu,
    this.selectedIndex,
    this.accentUngu = const Color(0xFF10B981),
  });

  final List<Map<String, dynamic>> odroor;
  final Color tekstUngu;
  final Color shugamUngu;
  final int? selectedIndex;
  final Color accentUngu;

  @override
  void paint(Canvas canvas, Size size) {
    if (odroor.isEmpty) return;
    const zuun = 38.0;
    const dood = 24.0;
    const deed = 16.0;
    final urgun = size.width - zuun - 10;
    final undur = size.height - dood - deed;
    if (urgun <= 0 || undur <= 0) return;

    final rawMax = odroor.fold<double>(
      0,
      (acc, e) => math.max(acc, math.max(shilenDansToDouble(e['tulsun']), shilenDansToDouble(e['zardal']))),
    );
    final double divisor;
    final String unitLabel;
    if (rawMax >= 1e6) {
      divisor = 1e6;
      unitLabel = 'сая ₮';
    } else if (rawMax >= 1e3) {
      divisor = 1e3;
      unitLabel = 'мян. ₮';
    } else {
      divisor = 1;
      unitLabel = '₮';
    }

    final tulsun = odroor.map((e) => shilenDansToDouble(e['tulsun']) / divisor).toList();
    final zardal = odroor.map((e) => shilenDansToDouble(e['zardal']) / divisor).toList();
    var ikh = [...tulsun, ...zardal].fold<double>(0, math.max);
    if (ikh <= 0) ikh = 1;
    final alkham = _goyAlkham(ikh / 4);
    ikh = (ikh / alkham).ceil() * alkham;

    final tor = Paint()
      ..color = shugamUngu.withValues(alpha: 0.6)
      ..strokeWidth = 0.7;
    final tekstStyle = TextStyle(fontSize: 8.5, color: tekstUngu);

    _bich(canvas, unitLabel, const Offset(0, 0), tekstStyle);
    for (var v = 0.0; v <= ikh + 1e-9; v += alkham) {
      final y = deed + undur - (v / ikh) * undur;
      _drawDashedLine(canvas, Offset(zuun, y), Offset(size.width - 10, y), tor, 4.0, 4.0);
      _bich(canvas, v.toStringAsFixed(alkham < 1 ? 1 : 0), Offset(0, y - 6), tekstStyle);
    }

    double x(int i) =>
        zuun + (odroor.length == 1 ? urgun / 2 : i * urgun / (odroor.length - 1));
    double y(double v) => deed + undur - (v / ikh) * undur;

    final orlogoPoints = <Offset>[];
    final zardalPoints = <Offset>[];
    for (var i = 0; i < odroor.length; i++) {
      orlogoPoints.add(Offset(x(i), y(tulsun[i])));
      zardalPoints.add(Offset(x(i), y(zardal[i])));
    }

    // 1. Орлогын гөлгөр муруйн доорх градиент дэвсгэр
    if (orlogoPoints.length > 1) {
      final orlogoSmooth = _buildSmoothPath(orlogoPoints);
      final fillPath = Path.from(orlogoSmooth)
        ..lineTo(orlogoPoints.last.dx, deed + undur)
        ..lineTo(orlogoPoints.first.dx, deed + undur)
        ..close();

      final fillPaint = Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            const Color(0xFF10B981).withValues(alpha: 0.24),
            const Color(0xFF10B981).withValues(alpha: 0.08),
            const Color(0xFF10B981).withValues(alpha: 0.0),
          ],
          stops: const [0.0, 0.6, 1.0],
        ).createShader(Rect.fromLTWH(zuun, deed, urgun, undur))
        ..style = PaintingStyle.fill;

      canvas.drawPath(fillPath, fillPaint);
    }

    // 2. Сонгогдсон өдрийн босоо чиглүүлэгч шугам
    if (selectedIndex != null &&
        selectedIndex! >= 0 &&
        selectedIndex! < odroor.length) {
      final selX = x(selectedIndex!);
      final guidePaint = Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            accentUngu.withValues(alpha: 0.4),
            accentUngu.withValues(alpha: 0.05),
          ],
        ).createShader(Rect.fromLTWH(selX - 1, deed, 2, undur))
        ..strokeWidth = 1.4;
      canvas.drawLine(Offset(selX, deed), Offset(selX, deed + undur), guidePaint);
    }

    // 3. Зардлын тасархай гөлгөр шугам
    if (zardalPoints.length > 1) {
      final zardalSmooth = _buildSmoothPath(zardalPoints);
      final zardalPaint = Paint()
        ..color = const Color(0xFF94A3B8)
        ..strokeWidth = 1.8
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round;
      _drawDashedPath(canvas, zardalSmooth, zardalPaint, 5.0, 4.0);
    } else if (zardalPoints.length == 1) {
      canvas.drawCircle(zardalPoints[0], 3.5, Paint()..color = const Color(0xFF94A3B8));
    }

    // 4. Орлогын бүтэн гөлгөр ногоон шугам
    if (orlogoPoints.length > 1) {
      final orlogoSmooth = _buildSmoothPath(orlogoPoints);
      final orlogoPaint = Paint()
        ..color = const Color(0xFF10B981)
        ..strokeWidth = 2.4
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round;
      canvas.drawPath(orlogoSmooth, orlogoPaint);
    } else if (orlogoPoints.length == 1) {
      canvas.drawCircle(orlogoPoints[0], 3.5, Paint()..color = const Color(0xFF10B981));
    }

    // 5. X тэнхлэгийн өдрүүдийн текст (давхцалгүй зайтай)
    final count = odroor.length;
    final step = count <= 7 ? 1 : (count <= 15 ? 3 : 5);
    final labelIndices = <int>{0};
    for (var i = step - 1; i < count - 1; i += step) {
      if (i > 0) labelIndices.add(i);
    }
    if (count > 1) labelIndices.add(count - 1);

    // Сүүлийн хоёр шошго хэт ойрхон бол өмнөхийг нь хасна
    final sortedLabels = labelIndices.toList()..sort();
    final visibleLabels = <int>[];
    const minLabelGap = 24.0;
    for (final i in sortedLabels) {
      if (visibleLabels.isNotEmpty &&
          (x(i) - x(visibleLabels.last)).abs() < minLabelGap) {
        if (i == count - 1) {
          visibleLabels.removeLast();
        } else {
          continue;
        }
      }
      visibleLabels.add(i);
    }

    final selX = (selectedIndex != null && selectedIndex! >= 0 && selectedIndex! < count)
        ? x(selectedIndex!)
        : null;

    for (final i in visibleLabels) {
      if (selX != null && i != selectedIndex && (x(i) - selX).abs() < minLabelGap) {
        continue;
      }
      final dayStr = '${odroor[i]['odor']}';
      final isSel = selectedIndex == i;
      final tp = _tekst(
        dayStr,
        isSel
            ? TextStyle(
                fontSize: 9.5,
                fontWeight: FontWeight.w700,
                color: accentUngu,
              )
            : tekstStyle,
      );
      final clampedX = (x(i) - tp.width / 2).clamp(zuun, size.width - tp.width - 2);
      final textPos = Offset(clampedX, size.height - dood + 6);
      if (isSel) {
        final pillRect = Rect.fromCenter(
          center: Offset(clampedX + tp.width / 2, size.height - dood + 12),
          width: tp.width + 10,
          height: tp.height + 4,
        );
        canvas.drawRRect(
          RRect.fromRectAndRadius(pillRect, const Radius.circular(6)),
          Paint()..color = accentUngu.withValues(alpha: 0.12),
        );
      }
      tp.paint(canvas, textPos);
    }

    // Сонгогдсон өдөр нь үндсэн шошгонд байхгүй бол тусад нь зурна
    if (selectedIndex != null &&
        selectedIndex! >= 0 &&
        selectedIndex! < count &&
        !visibleLabels.contains(selectedIndex)) {
      final i = selectedIndex!;
      final dayStr = '${odroor[i]['odor']}';
      final tp = _tekst(
        dayStr,
        TextStyle(
          fontSize: 9.5,
          fontWeight: FontWeight.w700,
          color: accentUngu,
        ),
      );
      final clampedX = (x(i) - tp.width / 2).clamp(zuun, size.width - tp.width - 2);
      final pillRect = Rect.fromCenter(
        center: Offset(clampedX + tp.width / 2, size.height - dood + 12),
        width: tp.width + 10,
        height: tp.height + 4,
      );
      canvas.drawRRect(
        RRect.fromRectAndRadius(pillRect, const Radius.circular(6)),
        Paint()..color = accentUngu.withValues(alpha: 0.12),
      );
      tp.paint(canvas, Offset(clampedX, size.height - dood + 6));
    }

    // 6. Сонгогдсон өдрийн цэгүүдийг 3 давхар гэрэлтүүлж тодруулах
    if (selectedIndex != null &&
        selectedIndex! >= 0 &&
        selectedIndex! < odroor.length) {
      final idx = selectedIndex!;

      final orlogoC = orlogoPoints[idx];
      canvas.drawCircle(
        orlogoC,
        8.0,
        Paint()..color = const Color(0xFF10B981).withValues(alpha: 0.22),
      );
      canvas.drawCircle(orlogoC, 5.0, Paint()..color = const Color(0xFF10B981));
      canvas.drawCircle(orlogoC, 2.2, Paint()..color = Colors.white);

      final zardalC = zardalPoints[idx];
      canvas.drawCircle(
        zardalC,
        8.0,
        Paint()..color = const Color(0xFF94A3B8).withValues(alpha: 0.22),
      );
      canvas.drawCircle(zardalC, 5.0, Paint()..color = const Color(0xFF94A3B8));
      canvas.drawCircle(zardalC, 2.2, Paint()..color = Colors.white);
    }
  }

  Path _buildSmoothPath(List<Offset> points) {
    final path = Path();
    if (points.isEmpty) return path;
    path.moveTo(points[0].dx, points[0].dy);
    if (points.length == 1) return path;

    for (var i = 0; i < points.length - 1; i++) {
      final p0 = i > 0 ? points[i - 1] : points[i];
      final p1 = points[i];
      final p2 = points[i + 1];
      final p3 = i + 2 < points.length ? points[i + 2] : p2;

      final cp1x = p1.dx + (p2.dx - p0.dx) / 5.5;
      final cp1y = p1.dy + (p2.dy - p0.dy) / 5.5;
      final cp2x = p2.dx - (p3.dx - p1.dx) / 5.5;
      final cp2y = p2.dy - (p3.dy - p1.dy) / 5.5;

      path.cubicTo(cp1x, cp1y, cp2x, cp2y, p2.dx, p2.dy);
    }
    return path;
  }

  void _drawDashedPath(Canvas canvas, Path path, Paint paint, double dash, double gap) {
    for (final metric in path.computeMetrics()) {
      var distance = 0.0;
      while (distance < metric.length) {
        final next = math.min(distance + dash, metric.length);
        canvas.drawPath(metric.extractPath(distance, next), paint);
        distance += dash + gap;
      }
    }
  }

  void _drawDashedLine(Canvas canvas, Offset p1, Offset p2, Paint paint, double dash, double gap) {
    final totalDist = (p2 - p1).distance;
    var d = 0.0;
    while (d < totalDist) {
      final start = Offset.lerp(p1, p2, d / totalDist)!;
      final end = Offset.lerp(p1, p2, math.min(d + dash, totalDist) / totalDist)!;
      canvas.drawLine(start, end, paint);
      d += dash + gap;
    }
  }

  double _goyAlkham(double v) {
    if (v <= 0) return 1;
    final zereg = math.pow(10, (math.log(v) / math.ln10).floor()).toDouble();
    final n = v / zereg;
    final goy = n <= 1 ? 1 : n <= 2 ? 2 : n <= 5 ? 5 : 10;
    return goy * zereg;
  }

  TextPainter _tekst(String t, TextStyle s) =>
      TextPainter(text: TextSpan(text: t, style: s), textDirection: TextDirection.ltr)
        ..layout();

  void _bich(Canvas canvas, String t, Offset o, TextStyle s) => _tekst(t, s).paint(canvas, o);

  @override
  bool shouldRepaint(covariant _UrsgalPainter old) =>
      old.odroor != odroor ||
      old.tekstUngu != tekstUngu ||
      old.shugamUngu != shugamUngu ||
      old.selectedIndex != selectedIndex ||
      old.accentUngu != accentUngu;
}
