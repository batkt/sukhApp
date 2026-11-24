import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:intl/intl.dart' show NumberFormat;
import 'package:sukh_app/constants/constants.dart';
import 'package:sukh_app/services/api_service.dart';
import 'package:sukh_app/utils/theme_extensions.dart';
import 'package:sukh_app/widgets/standard_app_bar.dart' show buildStandardAppBar;

/// Шилэн данс — СӨХ-ийн сарын орлого, зарцуулалт, дансны үлдэгдэл, айлын
/// авлагыг оршин суугчид ил тод харуулна.
///
/// Өгөгдөл: POST /shilenDans/app (sukhBackv2 controller/shilenDans.js).
/// Вебийн «Нэмэлт тохиргоо → Шилэн данс аппад харуулах» асаалттай үед л
/// нүүр хуудсанд товч гарч, сервер хариу өгнө.
class ShilenDansPage extends StatefulWidget {
  const ShilenDansPage({super.key});

  @override
  State<ShilenDansPage> createState() => _ShilenDansPageState();
}

/// Шилэн дансны өнгө — мокапын ногоон шатлал, авлагад шаргал.
class _Ungu {
  static const Color nogoon = Color(0xFF1E7B3C);
  static const Color dundNogoon = Color(0xFF6FBF7F);
  static const Color tsaivarNogoon = Color(0xFFCDE9D2);
  static const Color sharga = Color(0xFFE8B04A);
  static const Color saaral = Color(0xFF9AA5B1);
}

final NumberFormat _too = NumberFormat('#,##0', 'en_US');
String _mungu(num? v) => v == null ? '—' : '${_too.format(v.round())} ₮';

double _toDouble(dynamic v) => v is num ? v.toDouble() : double.tryParse('$v') ?? 0;

class _ShilenDansPageState extends State<ShilenDansPage> {
  int _tab = 0;
  late String _sar;
  bool _loading = true;
  String? _aldaa;
  bool _khaalttai = false;
  Map<String, dynamic>? _data;

  @override
  void initState() {
    super.initState();
    final odoo = DateTime.now();
    _sar = _sarTulkhuur(odoo);
    _achaalakh();
  }

  String _sarTulkhuur(DateTime d) =>
      '${d.year}-${d.month.toString().padLeft(2, '0')}';

  List<String> get _sarnuud {
    final odoo = DateTime.now();
    return List.generate(12, (i) => _sarTulkhuur(DateTime(odoo.year, odoo.month - i, 1)));
  }

  String _sarNer(String sar) {
    final p = sar.split('-');
    if (p.length != 2) return sar;
    return '${p[0]} · ${int.tryParse(p[1]) ?? p[1]} сар';
  }

  Future<void> _achaalakh() async {
    setState(() {
      _loading = true;
      _aldaa = null;
    });
    try {
      final res = await ApiService.fetchShilenDans(sar: _sar);
      if (!mounted) return;
      setState(() {
        _khaalttai = res['khaalttai'] == true;
        _data = _khaalttai ? null : res;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _aldaa = e.toString().replaceFirst('Exception: ', '');
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = context.isDarkMode;
    return Scaffold(
      backgroundColor: isDark ? AppColors.darkBackground : Colors.white,
      appBar: buildStandardAppBar(context, title: 'Шилэн данс'),
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: EdgeInsets.fromLTRB(16.w, 8.h, 16.w, 4.h),
              child: _Segment(
                songolt: const ['Тойм', 'Айлын авлага'],
                index: _tab,
                onChanged: (i) => setState(() => _tab = i),
              ),
            ),
            Expanded(child: _body(isDark)),
          ],
        ),
      ),
    );
  }

  Widget _body(bool isDark) {
    if (_loading && _data == null) {
      return const Center(child: CircularProgressIndicator(color: AppColors.primary));
    }
    if (_khaalttai) {
      return _Medegdel(
        icon: Icons.visibility_off_outlined,
        text: 'Танай СӨХ шилэн дансаа аппад нээгээгүй байна.',
      );
    }
    if (_aldaa != null && _data == null) {
      return _Medegdel(
        icon: Icons.error_outline,
        text: _aldaa!,
        onRetry: _achaalakh,
      );
    }
    final d = _data ?? const {};
    return RefreshIndicator(
      color: AppColors.primary,
      onRefresh: _achaalakh,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: EdgeInsets.fromLTRB(16.w, 8.h, 16.w, 24.h),
        children: _tab == 0 ? _toimTab(d, isDark) : _avlagaTab(d, isDark),
      ),
    );
  }

  // ── Тойм ──────────────────────────────────────────────────────────────
  List<Widget> _toimTab(Map<String, dynamic> d, bool isDark) {
    final saraar = (d['saraar'] as List? ?? [])
        .map((e) => Map<String, dynamic>.from(e as Map))
        .toList();
    // Орлого = оршин суугчдын төлсөн мөнгө, зардал = СӨХ-ийн зарлага
    final orlogo = _toDouble(d['tulsun']);
    final zardal = _toDouble(d['zardal']);
    final khurimtlal = _toDouble(d['khurimtlal']);
    final nekhemjilsen = _toDouble(d['nekhemjilsen']);
    final ail = Map<String, dynamic>.from(d['ailiinAvlaga'] as Map? ?? {});
    final avlaga = _toDouble(d['tuluugui'] ?? ail['niit']);
    final ner = [d['baiguullagiinNer'], d['barilgiinNer']]
        .where((e) => e != null && '$e'.isNotEmpty)
        .join(' · ');

    return [
      Row(
        children: [
          Expanded(
            child: Text(
              ner,
              style: TextStyle(fontSize: 13.sp, color: context.textSecondaryColor),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          _SarSongolt(
            value: _sar,
            sarnuud: _sarnuud,
            ner: _sarNer,
            onChanged: (v) {
              setState(() => _sar = v);
              _achaalakh();
            },
          ),
        ],
      ),
      SizedBox(height: 12.h),
      _Kart(
        ungu: _Ungu.nogoon.withValues(alpha: isDark ? 0.18 : 0.08),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Энэ сарын хуримтлал',
                style: TextStyle(fontSize: 13.sp, color: context.textSecondaryColor)),
            SizedBox(height: 4.h),
            Text(
              '${khurimtlal < 0 ? '−' : ''}${_mungu(khurimtlal.abs())}',
              style: TextStyle(
                fontSize: 28.sp,
                fontWeight: FontWeight.w600,
                color: khurimtlal < 0 ? Colors.redAccent : context.textPrimaryColor,
              ),
            ),
            SizedBox(height: 2.h),
            Text('Орлого − Зардал',
                style: TextStyle(fontSize: 11.sp, color: context.textSecondaryColor)),
          ],
        ),
      ),
      SizedBox(height: 12.h),
      Row(
        children: [
          Expanded(child: _Utga(ner: 'Энэ сарын орлого', utga: _mungu(orlogo))),
          Container(width: 1, height: 36.h, color: context.borderColor),
          SizedBox(width: 12.w),
          Expanded(child: _Utga(ner: 'Энэ сарын зардал', utga: _mungu(zardal))),
        ],
      ),
      Divider(height: 28.h, color: context.borderColor),
      Text('Санхүүгийн бүтэц',
          style: TextStyle(
              fontSize: 15.sp, fontWeight: FontWeight.w600, color: context.textPrimaryColor)),
      SizedBox(height: 8.h),
      _Kart(
        child: _CircleDonutChart(
          tolovlogoot: nekhemjilsen,
          orlogo: orlogo,
          avlaga: avlaga,
          zardal: zardal,
        ),
      ),
      SizedBox(height: 16.h),
      Text('Орлого, зардал (6 сарын хандлага)',
          style: TextStyle(
              fontSize: 15.sp, fontWeight: FontWeight.w600, color: context.textPrimaryColor)),
      SizedBox(height: 8.h),
      _Kart(
        child: Column(
          children: [
            SizedBox(
              height: 170.h,
              child: CustomPaint(
                size: Size.infinite,
                painter: _UrsgalPainter(
                  saraar: saraar,
                  tekstUngu: context.textSecondaryColor,
                  shugamUngu: context.borderColor,
                ),
              ),
            ),
            SizedBox(height: 8.h),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const _Tailbar(ungu: _Ungu.nogoon, ner: 'Орлого'),
                SizedBox(width: 16.w),
                const _Tailbar(ungu: _Ungu.saaral, ner: 'Зардал', tasarkhai: true),
              ],
            ),
          ],
        ),
      ),
      SizedBox(height: 8.h),
      _Mur(
        ner: 'Хугацаа хэтэрсэн айл',
        dedNer: '${ail['khetersenAilToo'] ?? 0} айл',
        utga: _mungu(_toDouble(ail['khetersen'])),
        ungu: _toDouble(ail['khetersen']) > 0 ? const Color(0xFF9A6A12) : null,
      ),
      _Mur(ner: 'Төлөөгүй (нийт)', utga: _mungu(_toDouble(d['tuluugui']))),
      _Mur(ner: 'Миний төлбөр', utga: _mungu(_toDouble(d['miniiTulbur']))),
    ];
  }

  // ── Айлын авлага ──────────────────────────────────────────────────────
  List<Widget> _avlagaTab(Map<String, dynamic> d, bool isDark) {
    final ail = Map<String, dynamic>.from(d['ailiinAvlaga'] as Map? ?? {});
    final niit = _toDouble(ail['niit']);
    final khetersen = _toDouble(ail['khetersen']);
    final boloogui = _toDouble(ail['boloogui']);
    final khetersenKhuvi = niit > 0 ? khetersen / niit : 0.0;
    final ailToo = (ail['khetersenAilToo'] as num?)?.toInt() ?? 0;
    // Сервер тоот + дүн + хэтэрсэн хоног явуулна
    final ailuud = ail['ailuud'] is List
        ? (ail['ailuud'] as List).map((e) => Map<String, dynamic>.from(e as Map)).toList()
        : <Map<String, dynamic>>[];

    return [
      _Kart(
        ungu: _Ungu.nogoon.withValues(alpha: isDark ? 0.18 : 0.08),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Нийт авлага',
                style: TextStyle(fontSize: 13.sp, color: context.textSecondaryColor)),
            SizedBox(height: 4.h),
            Text(
              _mungu(niit),
              style: TextStyle(
                fontSize: 28.sp,
                fontWeight: FontWeight.w600,
                color: context.textPrimaryColor,
              ),
            ),
            if (niit > 0) ...[
              SizedBox(height: 10.h),
              ClipRRect(
                borderRadius: BorderRadius.circular(6.r),
                child: SizedBox(
                  height: 22.h,
                  child: Row(
                    children: [
                      if (khetersen > 0)
                        Expanded(
                          flex: math.max(1, (khetersenKhuvi * 1000).round()),
                          child: _BarKheseg(
                            ungu: _Ungu.sharga,
                            tekst: '${(khetersenKhuvi * 100).round()}%',
                          ),
                        ),
                      if (boloogui > 0)
                        Expanded(
                          flex: math.max(1, ((1 - khetersenKhuvi) * 1000).round()),
                          child: _BarKheseg(
                            ungu: _Ungu.tsaivarNogoon,
                            tekst: '${((1 - khetersenKhuvi) * 100).round()}%',
                            tekstUngu: _Ungu.nogoon,
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
      SizedBox(height: 8.h),
      _Mur(tseg: _Ungu.sharga, ner: 'Хугацаа хэтэрсэн', utga: _mungu(khetersen)),
      _Mur(tseg: _Ungu.tsaivarNogoon, ner: 'Хугацаа болоогүй', utga: _mungu(boloogui)),
      SizedBox(height: 16.h),
      Row(
        children: [
          Expanded(
            child: Text(
              'Хугацаа хэтэрсэн айл',
              style: TextStyle(
                fontSize: 15.sp,
                fontWeight: FontWeight.w600,
                color: context.textPrimaryColor,
              ),
            ),
          ),
          Container(
            padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 3.h),
            decoration: BoxDecoration(
              color: _Ungu.sharga.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(12.r),
            ),
            child: Text(
              '$ailToo',
              style: TextStyle(
                fontSize: 13.sp,
                fontWeight: FontWeight.w600,
                color: const Color(0xFF9A6A12),
              ),
            ),
          ),
        ],
      ),
      SizedBox(height: 4.h),
      Text(
        '30 хоногоос дээш төлөгдөөгүй нэхэмжлэлтэй айл',
        style: TextStyle(fontSize: 12.sp, color: context.textSecondaryColor),
      ),
      SizedBox(height: 8.h),
      if (ailuud.isEmpty)
        Padding(
          padding: EdgeInsets.symmetric(vertical: 16.h),
          child: Text(
            'Хугацаа хэтэрсэн айл алга.',
            style: TextStyle(fontSize: 13.sp, color: context.textSecondaryColor),
          ),
        )
      else
        for (final a in ailuud)
          _Mur(
            ner: '${a['toot'] ?? '—'} тоот',
            utga: _mungu(_toDouble(a['dun'])),
            dedUtga: ((a['khonog'] as num?)?.toInt() ?? 0) > 0
                ? '${(a['khonog'] as num?)?.toInt()} хоног'
                : null,
            ungu: const Color(0xFFC05621),
          ),
    ];
  }
}

// ── Жижиг widget-ууд ────────────────────────────────────────────────────

class _Segment extends StatelessWidget {
  const _Segment({
    required this.songolt,
    required this.index,
    required this.onChanged,
  });

  final List<String> songolt;
  final int index;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    final isDark = context.isDarkMode;
    return Container(
      padding: EdgeInsets.all(3.w),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : const Color(0xFFF2F4F3),
        borderRadius: BorderRadius.circular(10.r),
        border: Border.all(color: context.borderColor),
      ),
      child: Row(
        children: [
          for (var i = 0; i < songolt.length; i++)
            Expanded(
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: () => onChanged(i),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
                  padding: EdgeInsets.symmetric(vertical: 10.h),
                  decoration: BoxDecoration(
                    color: i == index
                        ? _Ungu.nogoon.withValues(alpha: isDark ? 0.35 : 0.14)
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(8.r),
                  ),
                  child: Text(
                    songolt[i],
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 13.sp,
                      fontWeight: i == index ? FontWeight.w600 : FontWeight.w400,
                      color: i == index
                          ? (isDark ? _Ungu.dundNogoon : _Ungu.nogoon)
                          : context.textSecondaryColor,
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _SarSongolt extends StatelessWidget {
  const _SarSongolt({
    required this.value,
    required this.sarnuud,
    required this.ner,
    required this.onChanged,
  });

  final String value;
  final List<String> sarnuud;
  final String Function(String) ner;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 10.w),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8.r),
        border: Border.all(color: context.borderColor),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: value,
          isDense: true,
          icon: Icon(Icons.keyboard_arrow_down_rounded,
              size: 18.sp, color: context.textSecondaryColor),
          style: TextStyle(fontSize: 13.sp, color: context.textPrimaryColor),
          dropdownColor: context.cardBackgroundColor,
          items: [
            for (final s in sarnuud) DropdownMenuItem(value: s, child: Text(ner(s))),
          ],
          onChanged: (v) {
            if (v != null && v != value) onChanged(v);
          },
        ),
      ),
    );
  }
}

class _Kart extends StatelessWidget {
  const _Kart({required this.child, this.ungu});

  final Widget child;
  final Color? ungu;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(14.w),
      decoration: BoxDecoration(
        color: ungu ?? context.cardBackgroundColor,
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(color: context.borderColor),
      ),
      child: child,
    );
  }
}

class _Utga extends StatelessWidget {
  const _Utga({required this.ner, required this.utga});

  final String ner;
  final String utga;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(ner, style: TextStyle(fontSize: 13.sp, color: context.textSecondaryColor)),
        SizedBox(height: 2.h),
        Text(
          utga,
          style: TextStyle(
            fontSize: 17.sp,
            fontWeight: FontWeight.w500,
            color: context.textPrimaryColor,
          ),
        ),
      ],
    );
  }
}

class _Mur extends StatelessWidget {
  const _Mur({
    required this.ner,
    required this.utga,
    this.ungu,
    this.tseg,
    this.dedNer,
    this.dedUtga,
  });

  final String ner;
  final String utga;
  final Color? ungu;
  final Color? tseg;
  final String? dedNer;
  final String? dedUtga;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(vertical: 12.h),
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: context.borderColor)),
      ),
      child: Row(
        children: [
          if (tseg != null) ...[
            Container(
              width: 10.w,
              height: 10.w,
              decoration: BoxDecoration(color: tseg, shape: BoxShape.circle),
            ),
            SizedBox(width: 10.w),
          ],
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(ner, style: TextStyle(fontSize: 14.sp, color: context.textPrimaryColor)),
                if (dedNer != null)
                  Text(dedNer!,
                      style: TextStyle(fontSize: 12.sp, color: context.textSecondaryColor)),
              ],
            ),
          ),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                utga,
                style: TextStyle(
                  fontSize: 14.sp,
                  fontWeight: FontWeight.w600,
                  color: ungu ?? context.textPrimaryColor,
                ),
              ),
              if (dedUtga != null && dedUtga!.isNotEmpty) ...[
                SizedBox(width: 6.w),
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 6.w, vertical: 2.h),
                  decoration: BoxDecoration(
                    color: _Ungu.sharga.withValues(alpha: 0.16),
                    borderRadius: BorderRadius.circular(5.r),
                  ),
                  child: Text(
                    dedUtga!,
                    style: TextStyle(
                      fontSize: 11.sp,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF9A6A12),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }
}

/// Дугуй график (Donut) — Интерактив Төлөвлөгөөт, Орлого, Авлага, Зардал
class _CircleDonutChart extends StatefulWidget {
  const _CircleDonutChart({
    required this.tolovlogoot,
    required this.orlogo,
    required this.avlaga,
    required this.zardal,
  });

  final double tolovlogoot;
  final double orlogo;
  final double avlaga;
  final double zardal;

  static const Color tolovlogootColor = Color(0xFF2563EB); // Цэнхэр
  static const Color orlogoColor = Color(0xFF1E7B3C);      // Ногоон
  static const Color avlagaColor = Color(0xFFE8B04A);      // Шаргал
  static const Color zardalColor = Color(0xFFDC2626);      // Улаан

  @override
  State<_CircleDonutChart> createState() => _CircleDonutChartState();
}

class _CircleDonutChartState extends State<_CircleDonutChart>
    with SingleTickerProviderStateMixin {
  late AnimationController _anim;
  late Animation<double> _curve;
  int _selectedIndex = 1; // Анхдагчаар "Орлого"-г тодотгож сонгоно

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
  void didUpdateWidget(covariant _CircleDonutChart oldWidget) {
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

  void _onTapSegment(int idx) {
    setState(() {
      _selectedIndex = _selectedIndex == idx ? -1 : idx;
    });
  }

  void _handleDonutTap(Offset localPos, Size size, List<double> values) {
    final center = Offset(size.width / 2, size.height / 2);
    final dx = localPos.dx - center.dx;
    final dy = localPos.dy - center.dy;
    final dist = math.sqrt(dx * dx + dy * dy);
    final outerRadius = math.min(size.width, size.height) / 2;
    const innerRadius = 35.0;

    // Зөвхөн donut-ын цагираг дээр дарвал
    if (dist < innerRadius || dist > outerRadius + 15) {
      if (dist < innerRadius) {
        // Төв дээр дарвал ерөнхий тойм руу буцна
        setState(() => _selectedIndex = -1);
      }
      return;
    }

    final total = values.fold<double>(0, (sum, v) => sum + math.max(0, v));
    if (total <= 0) return;

    var angle = math.atan2(dy, dx);
    // 12 цагаас (-pi / 2) эхэлсэн өнцөг рүү шилжүүлэх [0, 2*pi]
    var relAngle = angle + (math.pi / 2);
    if (relAngle < 0) relAngle += 2 * math.pi;

    double curr = 0;
    for (var i = 0; i < values.length; i++) {
      final sweep = (math.max(0, values[i]) / total) * 2 * math.pi;
      if (relAngle >= curr && relAngle <= curr + sweep) {
        _onTapSegment(i);
        return;
      }
      curr += sweep;
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = context.isDarkMode;
    final values = [
      widget.tolovlogoot,
      widget.orlogo,
      widget.avlaga,
      widget.zardal,
    ];
    const colors = [
      _CircleDonutChart.tolovlogootColor,
      _CircleDonutChart.orlogoColor,
      _CircleDonutChart.avlagaColor,
      _CircleDonutChart.zardalColor,
    ];
    final titles = ['Төлөвлөгөөт', 'Орлого', 'Авлага', 'Зардал'];
    final subtitles = ['Нэхэмжилсэн', 'Төлөгдсөн', 'Төлөөгүй үлдсэн', 'СӨХ-ийн зардал'];

    final collectionPercent = widget.tolovlogoot > 0
        ? ((widget.orlogo / widget.tolovlogoot) * 100).round()
        : 0;

    // Төв хэсэгт сонгосон үзүүлэлтээс хамаарч мэдээлэл харуулах
    String centerTitle;
    String centerValue;
    String centerSubtitle;
    Color centerColor;

    if (_selectedIndex >= 0 && _selectedIndex < 4) {
      centerTitle = titles[_selectedIndex];
      centerValue = _mungu(values[_selectedIndex]);
      centerSubtitle = subtitles[_selectedIndex];
      centerColor = colors[_selectedIndex];
    } else {
      centerTitle = 'Төлөлт';
      centerValue = '$collectionPercent%';
      centerSubtitle = 'нийт гүйцэтгэл';
      centerColor = context.textPrimaryColor;
    }

    return Column(
      children: [
        SizedBox(height: 6.h),
        // Интерактив Дугуй график
        SizedBox(
          height: 160.h,
          child: LayoutBuilder(
            builder: (ctx, constraints) {
              final size = Size(150.w, 150.w);
              return Center(
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTapUp: (details) => _handleDonutTap(details.localPosition, size, values),
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      AnimatedBuilder(
                        animation: _curve,
                        builder: (context, _) {
                          return SizedBox(
                            width: size.width,
                            height: size.height,
                            child: CustomPaint(
                              painter: _DonutPainter(
                                values: values,
                                colors: colors,
                                selectedIndex: _selectedIndex,
                                progress: _curve.value,
                                backgroundColor: isDark
                                    ? Colors.white.withValues(alpha: 0.08)
                                    : const Color(0xFFF0F3F1),
                                strokeWidth: 15.w,
                              ),
                            ),
                          );
                        },
                      ),
                      Padding(
                        padding: EdgeInsets.symmetric(horizontal: 24.w),
                        child: AnimatedSwitcher(
                          duration: const Duration(milliseconds: 200),
                          child: Column(
                            key: ValueKey<int>(_selectedIndex),
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                centerTitle,
                                style: TextStyle(
                                  fontSize: 11.sp,
                                  fontWeight: FontWeight.w500,
                                  color: context.textSecondaryColor,
                                ),
                              ),
                              SizedBox(height: 2.h),
                              FittedBox(
                                fit: BoxFit.scaleDown,
                                child: Text(
                                  centerValue,
                                  style: TextStyle(
                                    fontSize: _selectedIndex >= 0 ? 16.sp : 22.sp,
                                    fontWeight: FontWeight.w700,
                                    color: centerColor,
                                    letterSpacing: -0.3,
                                  ),
                                ),
                              ),
                              SizedBox(height: 1.h),
                              Text(
                                centerSubtitle,
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontSize: 10.sp,
                                  color: context.textSecondaryColor,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
        SizedBox(height: 14.h),
        // 4 үзүүлэлтийн интерактив 2x2 карт
        Row(
          children: [
            Expanded(
              child: _ChartLegendItem(
                color: _CircleDonutChart.tolovlogootColor,
                title: 'Төлөвлөгөөт',
                subtitle: 'Нэхэмжилсэн',
                amount: _mungu(widget.tolovlogoot),
                isSelected: _selectedIndex == 0,
                onTap: () => _onTapSegment(0),
              ),
            ),
            SizedBox(width: 8.w),
            Expanded(
              child: _ChartLegendItem(
                color: _CircleDonutChart.orlogoColor,
                title: 'Орлого',
                subtitle: 'Төлөгдсөн',
                amount: _mungu(widget.orlogo),
                isSelected: _selectedIndex == 1,
                onTap: () => _onTapSegment(1),
              ),
            ),
          ],
        ),
        SizedBox(height: 8.h),
        Row(
          children: [
            Expanded(
              child: _ChartLegendItem(
                color: _CircleDonutChart.avlagaColor,
                title: 'Авлага',
                subtitle: 'Төлөөгүй үлдсэн',
                amount: _mungu(widget.avlaga),
                isSelected: _selectedIndex == 2,
                onTap: () => _onTapSegment(2),
              ),
            ),
            SizedBox(width: 8.w),
            Expanded(
              child: _ChartLegendItem(
                color: _CircleDonutChart.zardalColor,
                title: 'Зардал',
                subtitle: 'СӨХ-ийн зардал',
                amount: _mungu(widget.zardal),
                isSelected: _selectedIndex == 3,
                onTap: () => _onTapSegment(3),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _ChartLegendItem extends StatelessWidget {
  const _ChartLegendItem({
    required this.color,
    required this.title,
    required this.subtitle,
    required this.amount,
    required this.isSelected,
    required this.onTap,
  });

  final Color color;
  final String title;
  final String subtitle;
  final String amount;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final isDark = context.isDarkMode;
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 8.h),
        decoration: BoxDecoration(
          color: isSelected
              ? color.withValues(alpha: isDark ? 0.22 : 0.09)
              : (isDark ? AppColors.darkSurface : const Color(0xFFF9FAFA)),
          borderRadius: BorderRadius.circular(10.r),
          border: Border.all(
            color: isSelected ? color : context.borderColor,
            width: isSelected ? 1.6 : 1.0,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: color.withValues(alpha: 0.15),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
                ]
              : null,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
                  width: isSelected ? 10.w : 8.w,
                  height: isSelected ? 10.w : 8.w,
                  decoration: BoxDecoration(color: color, shape: BoxShape.circle),
                ),
                SizedBox(width: 6.w),
                Expanded(
                  child: Text(
                    title,
                    style: TextStyle(
                      fontSize: 12.sp,
                      fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600,
                      color: isSelected ? color : context.textPrimaryColor,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                if (isSelected)
                  Icon(Icons.check_circle_rounded, size: 13.w, color: color),
              ],
            ),
            SizedBox(height: 4.h),
            Text(
              amount,
              style: TextStyle(
                fontSize: 13.5.sp,
                fontWeight: FontWeight.w700,
                color: color,
              ),
              overflow: TextOverflow.ellipsis,
            ),
            SizedBox(height: 1.h),
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
}

class _DonutPainter extends CustomPainter {
  _DonutPainter({
    required this.values,
    required this.colors,
    required this.selectedIndex,
    required this.progress,
    required this.backgroundColor,
    this.strokeWidth = 15.0,
  });

  final List<double> values;
  final List<Color> colors;
  final int selectedIndex;
  final double progress;
  final Color backgroundColor;
  final double strokeWidth;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final baseRadius = (math.min(size.width, size.height) - strokeWidth) / 2;
    if (baseRadius <= 0) return;

    final bgPaint = Paint()
      ..color = backgroundColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth;

    canvas.drawCircle(center, baseRadius, bgPaint);

    final total = values.fold<double>(0, (sum, v) => sum + math.max(0, v));
    if (total <= 0) return;

    double startAngle = -math.pi / 2; // 12 цагаас эхэлнэ
    final nonZeroCount = values.where((v) => v > 0).length;
    final gap = nonZeroCount > 1 ? 0.05 : 0.0;

    for (var i = 0; i < values.length; i++) {
      final val = math.max(0, values[i]);
      if (val <= 0) continue;

      final fullSweep = (val / total) * 2 * math.pi;
      final sweep = fullSweep * progress;
      final effectiveSweep = math.max(0.01, sweep - gap);

      final isSelected = selectedIndex == i;
      final hasSelection = selectedIndex >= 0;

      final paintColor = hasSelection && !isSelected
          ? colors[i].withValues(alpha: 0.35)
          : colors[i];

      final arcRadius = isSelected ? baseRadius + 2.w : baseRadius;
      final arcWidth = isSelected ? strokeWidth + 4.w : strokeWidth;

      final paint = Paint()
        ..color = paintColor
        ..style = PaintingStyle.stroke
        ..strokeWidth = arcWidth
        ..strokeCap = StrokeCap.round;

      canvas.drawArc(
        Rect.fromCircle(center: center, radius: arcRadius),
        startAngle + (gap / 2),
        effectiveSweep,
        false,
        paint,
      );

      startAngle += sweep;
    }
  }

  @override
  bool shouldRepaint(covariant _DonutPainter oldDelegate) {
    return oldDelegate.values != values ||
        oldDelegate.colors != colors ||
        oldDelegate.selectedIndex != selectedIndex ||
        oldDelegate.progress != progress ||
        oldDelegate.backgroundColor != backgroundColor ||
        oldDelegate.strokeWidth != strokeWidth;
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

class _BarKheseg extends StatelessWidget {
  const _BarKheseg({required this.ungu, required this.tekst, this.tekstUngu});

  final Color ungu;
  final String tekst;
  final Color? tekstUngu;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: ungu,
      alignment: Alignment.center,
      child: Text(
        tekst,
        maxLines: 1,
        overflow: TextOverflow.clip,
        style: TextStyle(fontSize: 11.sp, color: tekstUngu ?? Colors.white),
      ),
    );
  }
}

class _Medegdel extends StatelessWidget {
  const _Medegdel({required this.icon, required this.text, this.onRetry});

  final IconData icon;
  final String text;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: EdgeInsets.all(30.w),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 56.w, color: _Ungu.nogoon),
            SizedBox(height: 16.h),
            Text(
              text,
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 15.sp, color: context.textPrimaryColor, height: 1.5),
            ),
            if (onRetry != null) ...[
              SizedBox(height: 12.h),
              TextButton(onPressed: onRetry, child: const Text('Дахин оролдох')),
            ],
          ],
        ),
      ),
    );
  }
}

// ── Зураг ──────────────────────────────────────────────────────────────

/// 6 сарын орлого (бүтэн шугам) ба зарцуулалт (тасархай) — сая ₮-өөр.
class _UrsgalPainter extends CustomPainter {
  _UrsgalPainter({
    required this.saraar,
    required this.tekstUngu,
    required this.shugamUngu,
  });

  final List<Map<String, dynamic>> saraar;
  final Color tekstUngu;
  final Color shugamUngu;

  @override
  void paint(Canvas canvas, Size size) {
    if (saraar.isEmpty) return;
    const zuun = 34.0;
    const dood = 20.0;
    const deed = 14.0;
    final urgun = size.width - zuun - 8;
    final undur = size.height - dood - deed;

    final tulsun = saraar.map((e) => _toDouble(e['tulsun']) / 1e6).toList();
    final zardal = saraar.map((e) => _toDouble(e['zardal']) / 1e6).toList();
    var ikh = [...tulsun, ...zardal].fold<double>(0, math.max);
    if (ikh <= 0) ikh = 1;
    final alkham = _goyAlkham(ikh / 4);
    ikh = (ikh / alkham).ceil() * alkham;

    final tor = Paint()
      ..color = shugamUngu
      ..strokeWidth = 0.6;
    final tekstStyle = TextStyle(fontSize: 9, color: tekstUngu);

    _bich(canvas, 'сая ₮', Offset(0, 0), tekstStyle);
    for (var v = 0.0; v <= ikh + 1e-9; v += alkham) {
      final y = deed + undur - (v / ikh) * undur;
      canvas.drawLine(Offset(zuun, y), Offset(size.width - 8, y), tor);
      _bich(canvas, v.toStringAsFixed(alkham < 1 ? 1 : 0), Offset(0, y - 6), tekstStyle);
    }

    double x(int i) =>
        zuun + (saraar.length == 1 ? urgun / 2 : i * urgun / (saraar.length - 1));
    double y(double v) => deed + undur - (v / ikh) * undur;

    for (var i = 0; i < saraar.length; i++) {
      final sar = '${saraar[i]['sar']}'.split('-');
      final ner = sar.length == 2 ? '${int.tryParse(sar[1]) ?? sar[1]} сар' : '';
      final tp = _tekst(ner, tekstStyle);
      tp.paint(canvas, Offset(x(i) - tp.width / 2, size.height - dood + 6));
    }

    _shugam(canvas, tulsun, x, y, _Ungu.nogoon, false);
    _shugam(canvas, zardal, x, y, _Ungu.saaral, true);
  }

  void _shugam(
    Canvas canvas,
    List<double> utguud,
    double Function(int) x,
    double Function(double) y,
    Color ungu,
    bool tasarkhai,
  ) {
    final paint = Paint()
      ..color = ungu
      ..strokeWidth = 1.8
      ..style = PaintingStyle.stroke;
    for (var i = 0; i < utguud.length - 1; i++) {
      final a = Offset(x(i), y(utguud[i]));
      final b = Offset(x(i + 1), y(utguud[i + 1]));
      if (!tasarkhai) {
        canvas.drawLine(a, b, paint);
      } else {
        final urt = (b - a).distance;
        const tasarkhaiUrt = 5.0;
        for (var t = 0.0; t < urt; t += tasarkhaiUrt * 2) {
          final p1 = Offset.lerp(a, b, t / urt)!;
          final p2 = Offset.lerp(a, b, math.min(1, (t + tasarkhaiUrt) / urt))!;
          canvas.drawLine(p1, p2, paint);
        }
      }
    }
    final tseg = Paint()..color = ungu;
    final dotor = Paint()..color = Colors.white;
    for (var i = 0; i < utguud.length; i++) {
      final c = Offset(x(i), y(utguud[i]));
      canvas.drawCircle(c, 3.4, tseg);
      canvas.drawCircle(c, 1.8, dotor);
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
      old.saraar != saraar || old.tekstUngu != tekstUngu || old.shugamUngu != shugamUngu;
}
