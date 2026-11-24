import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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
  static const Color nogoon = Color(0xFF10B981);
  static const Color dundNogoon = Color(0xFF6FBF7F);
  static const Color tsaivarNogoon = Color(0xFFCDE9D2);
  static const Color sharga = Color(0xFFE8B04A);
  static const Color saaral = Color(0xFF94A3B8);
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

  void _showZardalModal(BuildContext context, Map<String, dynamic> d, double zardal) {
    final rawZarlaguud = d['zarlaguud'] as List? ?? [];
    final rawAngilalaar = d['zarlagaAngilalaar'] as List? ?? [];
    final sarNer = _sarNer(_sar);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _ZardalJagsaaltModal(
        sarNer: sarNer,
        niitZardal: zardal,
        zarlaguud: rawZarlaguud.map((e) => Map<String, dynamic>.from(e as Map)).toList(),
        angilalaar: rawAngilalaar.map((e) => Map<String, dynamic>.from(e as Map)).toList(),
      ),
    );
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
    double orlogo = _toDouble(d['tulsun'] ?? d['orlogo']);
    if (orlogo <= 0 && saraar.isNotEmpty) {
      final match = saraar.firstWhere(
        (s) => '${s['sar']}' == _sar,
        orElse: () => saraar.last,
      );
      if (_toDouble(match['tulsun']) > 0) {
        orlogo = _toDouble(match['tulsun']);
      }
    }
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
          Expanded(
            child: _Utga(
              ner: 'Энэ сарын зардал',
              utga: _mungu(zardal),
              onTap: () => _showZardalModal(context, d, zardal),
            ),
          ),
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
          onZardalTap: () => _showZardalModal(context, d, zardal),
        ),
      ),
      SizedBox(height: 16.h),
      Text('Орлого, зардал (6 сарын хандлага)',
          style: TextStyle(
              fontSize: 15.sp, fontWeight: FontWeight.w600, color: context.textPrimaryColor)),
      SizedBox(height: 8.h),
      _Kart(
        child: _InteractiveUrsgalGraph(
          saraar: saraar,
          tekstUngu: context.textSecondaryColor,
          shugamUngu: context.borderColor,
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
  const _Utga({
    required this.ner,
    required this.utga,
    this.onTap,
  });

  final String ner;
  final String utga;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final content = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(ner, style: TextStyle(fontSize: 13.sp, color: context.textSecondaryColor)),
            if (onTap != null) ...[
              SizedBox(width: 4.w),
              Icon(Icons.open_in_new_rounded, size: 12.5.sp, color: context.textSecondaryColor),
            ],
          ],
        ),
        SizedBox(height: 2.h),
        Text(
          utga,
          style: TextStyle(
            fontSize: 17.sp,
            fontWeight: FontWeight.w600,
            color: context.textPrimaryColor,
          ),
        ),
      ],
    );

    if (onTap != null) {
      return InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8.r),
        child: Padding(
          padding: EdgeInsets.symmetric(vertical: 2.h),
          child: content,
        ),
      );
    }
    return content;
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

/// Зардлын дэлгэрэнгүй жагсаалт харуулах модал
class _ZardalJagsaaltModal extends StatelessWidget {
  const _ZardalJagsaaltModal({
    required this.sarNer,
    required this.niitZardal,
    required this.zarlaguud,
    required this.angilalaar,
  });

  final String sarNer;
  final double niitZardal;
  final List<Map<String, dynamic>> zarlaguud;
  final List<Map<String, dynamic>> angilalaar;

  IconData _angilalIcon(String angilal) {
    final a = angilal.toLowerCase();
    if (a.contains('цэвэрлэгээ')) return Icons.cleaning_services_outlined;
    if (a.contains('засвар')) return Icons.build_outlined;
    if (a.contains('цалин')) return Icons.badge_outlined;
    if (a.contains('ндш') || a.contains('татвар')) return Icons.account_balance_outlined;
    if (a.contains('цахилгаан')) return Icons.bolt_outlined;
    if (a.contains('ус')) return Icons.water_drop_outlined;
    if (a.contains('дулаан')) return Icons.thermostat_outlined;
    if (a.contains('лифт')) return Icons.elevator_outlined;
    if (a.contains('харуул') || a.contains('хамгаалалт')) return Icons.security_outlined;
    if (a.contains('банк') || a.contains('шимтгэл')) return Icons.credit_card_outlined;
    return Icons.receipt_long_outlined;
  }

  @override
  Widget build(BuildContext context) {
    final isDark = context.isDarkMode;
    final hasItems = zarlaguud.isNotEmpty || angilalaar.isNotEmpty;

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.82,
      ),
      decoration: BoxDecoration(
        color: context.surfaceColor,
        borderRadius: BorderRadius.vertical(top: Radius.circular(22.r)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.25),
            blurRadius: 20,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SizedBox(height: 10.h),
            Center(
              child: Container(
                width: 36.w,
                height: 4.h,
                decoration: BoxDecoration(
                  color: context.borderColor,
                  borderRadius: BorderRadius.circular(2.r),
                ),
              ),
            ),
            SizedBox(height: 12.h),
            // Толгой
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 18.w),
              child: Row(
                children: [
                  Container(
                    width: 38.w,
                    height: 38.w,
                    decoration: BoxDecoration(
                      color: const Color(0xFFEF4444).withValues(alpha: 0.12),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.receipt_long_rounded,
                      color: Color(0xFFEF4444),
                      size: 20,
                    ),
                  ),
                  SizedBox(width: 10.w),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Энэ сарын зардал',
                          style: TextStyle(
                            fontSize: 16.sp,
                            fontWeight: FontWeight.w700,
                            color: context.textPrimaryColor,
                          ),
                        ),
                        SizedBox(height: 1.h),
                        Text(
                          '$sarNer · ${zarlaguud.isNotEmpty ? '${zarlaguud.length} зарлага' : '${angilalaar.length} ангилал'}',
                          style: TextStyle(
                            fontSize: 12.sp,
                            color: context.textSecondaryColor,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: Icon(Icons.close_rounded, color: context.textSecondaryColor, size: 22.sp),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                ],
              ),
            ),
            SizedBox(height: 12.h),
            // Нийт зардал карт
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 18.w),
              child: Container(
                padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
                decoration: BoxDecoration(
                  color: const Color(0xFFEF4444).withValues(alpha: isDark ? 0.16 : 0.08),
                  borderRadius: BorderRadius.circular(14.r),
                  border: Border.all(
                    color: const Color(0xFFEF4444).withValues(alpha: 0.25),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Нийт зарцуулалт',
                      style: TextStyle(
                        fontSize: 13.sp,
                        fontWeight: FontWeight.w500,
                        color: context.textSecondaryColor,
                      ),
                    ),
                    Text(
                      _mungu(niitZardal),
                      style: TextStyle(
                        fontSize: 18.sp,
                        fontWeight: FontWeight.w800,
                        color: const Color(0xFFEF4444),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            SizedBox(height: 12.h),
            Divider(height: 1, color: context.borderColor),
            // Жагсаалт
            Flexible(
              child: !hasItems
                  ? Padding(
                      padding: EdgeInsets.symmetric(vertical: 40.h, horizontal: 20.w),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.receipt_long_outlined,
                            size: 42.w,
                            color: context.textSecondaryColor.withValues(alpha: 0.5),
                          ),
                          SizedBox(height: 10.h),
                          Text(
                            'Зардлын бичилт байхгүй байна',
                            style: TextStyle(
                              fontSize: 14.sp,
                              fontWeight: FontWeight.w600,
                              color: context.textPrimaryColor,
                            ),
                          ),
                          SizedBox(height: 4.h),
                          Text(
                            'Энэ сард гарсан зарлага хараахан бүртгэгдээгүй байна.',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 12.sp,
                              color: context.textSecondaryColor,
                            ),
                          ),
                        ],
                      ),
                    )
                  : ListView.separated(
                      shrinkWrap: true,
                      padding: EdgeInsets.fromLTRB(18.w, 10.h, 18.w, 20.h),
                      itemCount: zarlaguud.isNotEmpty ? zarlaguud.length : angilalaar.length,
                      separatorBuilder: (_, _) =>
                          Divider(height: 14.h, color: context.borderColor.withValues(alpha: 0.6)),
                      itemBuilder: (context, index) {
                        if (zarlaguud.isNotEmpty) {
                          final item = zarlaguud[index];
                          final angilal = '${item['angilal'] ?? 'Бусад'}';
                          final tailbar = '${item['tailbar'] ?? ''}'.trim();
                          final ajiltan = '${item['ajiltniiNer'] ?? ''}'.trim();
                          final ognoo = '${item['ognoo'] ?? ''}'.split('T').first;
                          final dun = _toDouble(item['dun']);

                          final ded = [
                            if (ognoo.isNotEmpty) ognoo,
                            if (ajiltan.isNotEmpty) ajiltan,
                          ].join(' · ');

                          return Padding(
                            padding: EdgeInsets.symmetric(vertical: 4.h),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                Container(
                                  width: 38.w,
                                  height: 38.w,
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFEF4444).withValues(alpha: 0.1),
                                    borderRadius: BorderRadius.circular(10.r),
                                  ),
                                  child: Icon(
                                    _angilalIcon(angilal),
                                    color: const Color(0xFFEF4444),
                                    size: 19.w,
                                  ),
                                ),
                                SizedBox(width: 12.w),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        angilal,
                                        style: TextStyle(
                                          fontSize: 13.5.sp,
                                          fontWeight: FontWeight.w600,
                                          color: context.textPrimaryColor,
                                        ),
                                      ),
                                      if (tailbar.isNotEmpty && tailbar != '..') ...[
                                        SizedBox(height: 2.h),
                                        Text(
                                          tailbar,
                                          style: TextStyle(
                                            fontSize: 12.sp,
                                            color: context.textSecondaryColor,
                                          ),
                                          maxLines: 2,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ],
                                      if (ded.isNotEmpty) ...[
                                        SizedBox(height: 2.h),
                                        Text(
                                          ded,
                                          style: TextStyle(
                                            fontSize: 11.sp,
                                            color: context.textSecondaryColor.withValues(alpha: 0.8),
                                          ),
                                        ),
                                      ],
                                    ],
                                  ),
                                ),
                                SizedBox(width: 8.w),
                                Text(
                                  '−${_mungu(dun)}',
                                  style: TextStyle(
                                    fontSize: 14.sp,
                                    fontWeight: FontWeight.w700,
                                    color: const Color(0xFFEF4444),
                                    letterSpacing: -0.2,
                                  ),
                                ),
                              ],
                            ),
                          );
                        } else {
                          final item = angilalaar[index];
                          final angilal = '${item['angilal'] ?? 'Бусад'}';
                          final dun = _toDouble(item['dun']);
                          final huvi = niitZardal > 0
                              ? (dun / niitZardal * 100).toStringAsFixed(1)
                              : '0';

                          return Padding(
                            padding: EdgeInsets.symmetric(vertical: 4.h),
                            child: Row(
                              children: [
                                Container(
                                  width: 38.w,
                                  height: 38.w,
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFEF4444).withValues(alpha: 0.1),
                                    borderRadius: BorderRadius.circular(10.r),
                                  ),
                                  child: Icon(
                                    _angilalIcon(angilal),
                                    color: const Color(0xFFEF4444),
                                    size: 19.w,
                                  ),
                                ),
                                SizedBox(width: 12.w),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        angilal,
                                        style: TextStyle(
                                          fontSize: 13.5.sp,
                                          fontWeight: FontWeight.w600,
                                          color: context.textPrimaryColor,
                                        ),
                                      ),
                                      SizedBox(height: 2.h),
                                      Text(
                                        'Нийт зардлын $huvi%',
                                        style: TextStyle(
                                          fontSize: 11.5.sp,
                                          color: context.textSecondaryColor,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                SizedBox(width: 8.w),
                                Text(
                                  '−${_mungu(dun)}',
                                  style: TextStyle(
                                    fontSize: 14.sp,
                                    fontWeight: FontWeight.w700,
                                    color: const Color(0xFFEF4444),
                                  ),
                                ),
                              ],
                            ),
                          );
                        }
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Санхүүгийн бүтэц — Нэгдмэл Донут тойрог (Unified Hero Donut & Zardal Arc)
class _CircleDonutChart extends StatefulWidget {
  const _CircleDonutChart({
    required this.tolovlogoot,
    required this.orlogo,
    required this.avlaga,
    required this.zardal,
    this.onZardalTap,
  });

  final double tolovlogoot;
  final double orlogo;
  final double avlaga;
  final double zardal;
  final VoidCallback? onZardalTap;

  static const Color tolovlogootColor = Color(0xFF2563EB); // Цэнхэр (Төлөвлөгөөт)
  static const Color orlogoColor = Color(0xFF10B981);      // Маргад ногоон (Орлого)
  static const Color avlagaColor = Color(0xFFF59E0B);      // Алтлаг шаргал (Авлага)
  static const Color zardalColor = Color(0xFFEF4444);      // Шүрэн улаан (Зардал)

  @override
  State<_CircleDonutChart> createState() => _CircleDonutChartState();
}

class _CircleDonutChartState extends State<_CircleDonutChart>
    with SingleTickerProviderStateMixin {
  late AnimationController _anim;
  late Animation<double> _curve;
  int _selectedIndex = 1; // Анхдагчаар "Орлого"-г сонгоно

  @override
  void initState() {
    super.initState();
    _anim = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
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
    HapticFeedback.selectionClick();
    setState(() {
      _selectedIndex = _selectedIndex == idx ? -1 : idx;
    });
  }

  void _handleDonutTap(Offset localPos, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final dx = localPos.dx - center.dx;
    final dy = localPos.dy - center.dy;
    final dist = math.sqrt(dx * dx + dy * dy);

    // Хэрэв голын дотоод хэсэгт дарвал:
    if (dist <= 48.w) {
      if (_selectedIndex == 3) {
        widget.onZardalTap?.call();
      } else {
        setState(() {
          _selectedIndex = (_selectedIndex + 1) % 4;
        });
      }
      return;
    }

    // Хэрэв дотор зардал нуман дээр дарвал (48.w <= dist <= 68.w):
    if (dist <= 68.w) {
      _onTapSegment(3);
      return;
    }

    // Гадна тойргийн өнцгөөр нь Орлого, Авлага ялгах:
    var angle = math.atan2(dy, dx);
    var relAngle = angle - (-math.pi / 2);
    while (relAngle < 0) {
      relAngle += 2 * math.pi;
    }
    while (relAngle >= 2 * math.pi) {
      relAngle -= 2 * math.pi;
    }

    final baseTarget = widget.tolovlogoot > 0
        ? widget.tolovlogoot
        : (widget.orlogo + widget.avlaga > 0 ? widget.orlogo + widget.avlaga : 1.0);
    final orlogoRatio = (widget.orlogo / baseTarget).clamp(0.0, 1.0);
    final sweepOrlogo = widget.orlogo > 0 ? math.max(0.28, 2 * math.pi * orlogoRatio) : 0.0;

    if (relAngle <= sweepOrlogo) {
      _onTapSegment(1); // Орлого
    } else {
      _onTapSegment(2); // Авлага
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = context.isDarkMode;

    final baseTarget = widget.tolovlogoot > 0
        ? widget.tolovlogoot
        : (widget.orlogo + widget.avlaga > 0 ? widget.orlogo + widget.avlaga : 1.0);

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

    final icons = [
      Icons.receipt_long_rounded,
      Icons.account_balance_wallet_rounded,
      Icons.pending_actions_rounded,
      Icons.shopping_bag_outlined,
    ];

    final ratios = [
      1.0,
      (widget.orlogo / baseTarget).clamp(0.0, 1.0),
      (widget.avlaga / baseTarget).clamp(0.0, 1.0),
      (widget.zardal / baseTarget).clamp(0.0, 1.0),
    ];

    final percentages = ratios.map((r) => r * 100).toList();

    // Төвийн мэдээлэл
    IconData centerIcon;
    String centerTitle;
    String centerValue;
    String centerSubtitle;
    Color centerColor;

    if (_selectedIndex >= 0 && _selectedIndex < 4) {
      final idx = _selectedIndex;
      centerIcon = icons[idx];
      centerTitle = titles[idx];
      centerValue = _mungu(values[idx]);
      final p = percentages[idx];
      final pStr = (p > 0 && p < 1) ? p.toStringAsFixed(1) : p.round().toString();

      if (idx == 0) {
        centerSubtitle = '100% (Нэхэмжлэл)';
      } else if (idx == 3) {
        centerSubtitle = 'Жагсаалт харах ›';
      } else {
        centerSubtitle = '$pStr% (${subtitles[idx]})';
      }
      centerColor = colors[idx];
    } else {
      centerIcon = Icons.pie_chart_rounded;
      centerTitle = 'Төлөлт';
      final cp = percentages[1];
      final cpStr = (cp > 0 && cp < 1) ? cp.toStringAsFixed(1) : cp.round().toString();
      centerValue = '$cpStr%';
      centerSubtitle = 'орлогын гүйцэтгэл';
      centerColor = context.textPrimaryColor;
    }

    return Column(
      children: [
        // Дээд талын 4 төрлийн сонгогч таб
        Container(
          padding: EdgeInsets.all(3.w),
          decoration: BoxDecoration(
            color: isDark ? AppColors.darkSurface : const Color(0xFFF1F5F9),
            borderRadius: BorderRadius.circular(12.r),
            border: Border.all(color: context.borderColor),
          ),
          child: Row(
            children: List.generate(4, (i) {
              final isSel = _selectedIndex == i;
              final col = colors[i];
              return Expanded(
                child: GestureDetector(
                  onTap: () => _onTapSegment(i),
                  behavior: HitTestBehavior.opaque,
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 180),
                    padding: EdgeInsets.symmetric(vertical: 6.h),
                    decoration: BoxDecoration(
                      color: isSel ? col : Colors.transparent,
                      borderRadius: BorderRadius.circular(9.r),
                      boxShadow: isSel
                          ? [
                              BoxShadow(
                                color: col.withValues(alpha: 0.3),
                                blurRadius: 6,
                                offset: const Offset(0, 2),
                              ),
                            ]
                          : null,
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      titles[i],
                      style: TextStyle(
                        fontSize: 11.sp,
                        fontWeight: isSel ? FontWeight.w700 : FontWeight.w600,
                        color: isSel
                            ? Colors.white
                            : (isDark ? Colors.white70 : const Color(0xFF475569)),
                      ),
                    ),
                  ),
                ),
              );
            }),
          ),
        ),
        SizedBox(height: 12.h),

        // Нэгдмэл Донут график (Single Hero Donut & Inner Zardal Arc)
        SizedBox(
          height: 196.h,
          child: LayoutBuilder(
            builder: (ctx, constraints) {
              final size = Size(190.w, 190.w);
              return Center(
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTapUp: (details) => _handleDonutTap(details.localPosition, size),
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
                              painter: _SingleDonutPainter(
                                orlogo: widget.orlogo,
                                avlaga: widget.avlaga,
                                zardal: widget.zardal,
                                tolovlogoot: widget.tolovlogoot,
                                selectedIndex: _selectedIndex,
                                progress: _curve.value,
                                isDark: isDark,
                              ),
                            ),
                          );
                        },
                      ),
                      // Төв дэх KPI мэдээлэл
                      Padding(
                        padding: EdgeInsets.symmetric(horizontal: 26.w),
                        child: AnimatedSwitcher(
                          duration: const Duration(milliseconds: 200),
                          child: InkWell(
                            key: ValueKey<int>(_selectedIndex),
                            onTap: () {
                              if (_selectedIndex == 3) {
                                widget.onZardalTap?.call();
                              } else {
                                setState(() {
                                  _selectedIndex = (_selectedIndex + 1) % 4;
                                });
                              }
                            },
                            borderRadius: BorderRadius.circular(16.r),
                            child: Padding(
                              padding: EdgeInsets.symmetric(horizontal: 6.w, vertical: 4.h),
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Container(
                                    width: 32.w,
                                    height: 32.w,
                                    decoration: BoxDecoration(
                                      color: centerColor.withValues(alpha: 0.14),
                                      shape: BoxShape.circle,
                                    ),
                                    child: Icon(
                                      centerIcon,
                                      size: 16.w,
                                      color: centerColor,
                                    ),
                                  ),
                                  SizedBox(height: 3.h),
                                  Text(
                                    centerTitle,
                                    style: TextStyle(
                                      fontSize: 11.sp,
                                      fontWeight: FontWeight.w600,
                                      color: context.textSecondaryColor,
                                    ),
                                  ),
                                  SizedBox(height: 1.h),
                                  FittedBox(
                                    fit: BoxFit.scaleDown,
                                    child: Text(
                                      centerValue,
                                      style: TextStyle(
                                        fontSize: _selectedIndex >= 0 ? 16.sp : 20.sp,
                                        fontWeight: FontWeight.w800,
                                        color: centerColor,
                                        letterSpacing: -0.3,
                                      ),
                                    ),
                                  ),
                                  SizedBox(height: 3.h),
                                  Container(
                                    padding: EdgeInsets.symmetric(horizontal: 7.w, vertical: 2.h),
                                    decoration: BoxDecoration(
                                      color: centerColor.withValues(alpha: 0.12),
                                      borderRadius: BorderRadius.circular(8.r),
                                    ),
                                    child: Text(
                                      centerSubtitle,
                                      style: TextStyle(
                                        fontSize: 9.5.sp,
                                        fontWeight: FontWeight.w700,
                                        color: centerColor,
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
                icon: icons[0],
                title: 'Төлөвлөгөөт',
                subtitle: 'Нэхэмжилсэн',
                amount: _mungu(widget.tolovlogoot),
                percent: percentages[0],
                isSelected: _selectedIndex == 0,
                onTap: () => _onTapSegment(0),
              ),
            ),
            SizedBox(width: 8.w),
            Expanded(
              child: _ChartLegendItem(
                color: _CircleDonutChart.orlogoColor,
                icon: icons[1],
                title: 'Орлого',
                subtitle: 'Төлөгдсөн',
                amount: _mungu(widget.orlogo),
                percent: percentages[1],
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
                icon: icons[2],
                title: 'Авлага',
                subtitle: 'Төлөөгүй үлдсэн',
                amount: _mungu(widget.avlaga),
                percent: percentages[2],
                isSelected: _selectedIndex == 2,
                onTap: () => _onTapSegment(2),
              ),
            ),
            SizedBox(width: 8.w),
            Expanded(
              child: _ChartLegendItem(
                color: _CircleDonutChart.zardalColor,
                icon: icons[3],
                title: 'Зардал',
                subtitle: 'СӨХ-ийн зардал',
                amount: _mungu(widget.zardal),
                percent: percentages[3],
                isSelected: _selectedIndex == 3,
                actionText: 'Жагсаалт ›',
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

class _ChartLegendItem extends StatelessWidget {
  const _ChartLegendItem({
    required this.color,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.amount,
    required this.percent,
    required this.isSelected,
    required this.onTap,
    this.actionText,
  });

  final Color color;
  final IconData icon;
  final String title;
  final String subtitle;
  final String amount;
  final double percent;
  final bool isSelected;
  final VoidCallback onTap;
  final String? actionText;

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
              ? color.withValues(alpha: isDark ? 0.22 : 0.08)
              : (isDark ? AppColors.darkSurface : const Color(0xFFF8FAFC)),
          borderRadius: BorderRadius.circular(12.r),
          border: Border.all(
            color: isSelected ? color : context.borderColor,
            width: isSelected ? 1.6 : 0.9,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: color.withValues(alpha: 0.16),
                    blurRadius: 8,
                    offset: const Offset(0, 3),
                  ),
                ]
              : null,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 22.w,
                  height: 22.w,
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.14),
                    borderRadius: BorderRadius.circular(6.r),
                  ),
                  child: Icon(icon, size: 12.5.w, color: color),
                ),
                SizedBox(width: 6.w),
                Expanded(
                  child: Text(
                    title,
                    style: TextStyle(
                      fontSize: 11.5.sp,
                      fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600,
                      color: isSelected ? color : context.textPrimaryColor,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                if (actionText != null)
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 5.w, vertical: 1.5.h),
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(6.r),
                    ),
                    child: Text(
                      actionText!,
                      style: TextStyle(
                        fontSize: 9.5.sp,
                        fontWeight: FontWeight.w700,
                        color: color,
                      ),
                    ),
                  )
                else
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 5.w, vertical: 1.5.h),
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: isSelected ? 0.22 : 0.1),
                      borderRadius: BorderRadius.circular(6.r),
                    ),
                    child: Text(
                      percent > 0 && percent < 1
                          ? '${percent.toStringAsFixed(1)}%'
                          : '${percent.round()}%',
                      style: TextStyle(
                        fontSize: 9.5.sp,
                        fontWeight: FontWeight.w700,
                        color: color,
                      ),
                    ),
                  ),
              ],
            ),
            SizedBox(height: 6.h),
            Text(
              amount,
              style: TextStyle(
                fontSize: 13.5.sp,
                fontWeight: FontWeight.w800,
                color: isSelected ? color : context.textPrimaryColor,
                letterSpacing: -0.2,
              ),
              overflow: TextOverflow.ellipsis,
            ),
            SizedBox(height: 2.h),
            Text(
              subtitle,
              style: TextStyle(
                fontSize: 9.5.sp,
                color: context.textSecondaryColor,
              ),
              overflow: TextOverflow.ellipsis,
            ),
            SizedBox(height: 6.h),
            ClipRRect(
              borderRadius: BorderRadius.circular(2.r),
              child: Container(
                height: 3.h,
                width: double.infinity,
                color: color.withValues(alpha: 0.12),
                child: FractionallySizedBox(
                  alignment: Alignment.centerLeft,
                  widthFactor: (percent / 100).clamp(0.06, 1.0),
                  child: Container(color: color),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SingleDonutPainter extends CustomPainter {
  _SingleDonutPainter({
    required this.orlogo,
    required this.avlaga,
    required this.zardal,
    required this.tolovlogoot,
    required this.selectedIndex,
    required this.progress,
    required this.isDark,
  });

  final double orlogo;
  final double avlaga;
  final double zardal;
  final double tolovlogoot;
  final int selectedIndex;
  final double progress;
  final bool isDark;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final outerRadius = 80.w;
    final outerStroke = 14.w;
    final innerRadius = 59.w;
    final innerStroke = 7.w;

    final baseTarget = tolovlogoot > 0
        ? tolovlogoot
        : (orlogo + avlaga > 0 ? orlogo + avlaga : 1.0);

    const startAngle = -math.pi / 2; // 12 цаг

    // ── 1. Гадна суурь зам (Төлөвлөгөөт 100%) ──
    final isTolovlogootSelected = selectedIndex == 0;
    final trackColor = _CircleDonutChart.tolovlogootColor.withValues(
      alpha: isTolovlogootSelected ? (isDark ? 0.35 : 0.25) : (isDark ? 0.14 : 0.08),
    );
    final trackStroke = isTolovlogootSelected ? outerStroke + 3.w : outerStroke;

    if (isTolovlogootSelected) {
      canvas.drawCircle(
        center,
        outerRadius,
        Paint()
          ..color = _CircleDonutChart.tolovlogootColor.withValues(alpha: 0.25)
          ..style = PaintingStyle.stroke
          ..strokeWidth = trackStroke + 6.w
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6),
      );
    }
    canvas.drawCircle(
      center,
      outerRadius,
      Paint()
        ..color = trackColor
        ..style = PaintingStyle.stroke
        ..strokeWidth = trackStroke,
    );

    // ── 2. Орлого (Маргад ногоон нум) ──
    final orlogoRatio = (orlogo / baseTarget).clamp(0.0, 1.0);
    final rawSweepOrlogo = (2 * math.pi * orlogoRatio) * progress;
    final sweepOrlogo = orlogo > 0 ? math.max(0.28, rawSweepOrlogo) : 0.0;
    final isOrlogoSelected = selectedIndex == 1;

    if (sweepOrlogo > 0) {
      final orlogoStroke = isOrlogoSelected ? outerStroke + 4.w : outerStroke;
      final orlogoColor = _CircleDonutChart.orlogoColor;

      // Glow aura
      if (isOrlogoSelected) {
        canvas.drawArc(
          Rect.fromCircle(center: center, radius: outerRadius),
          startAngle,
          sweepOrlogo,
          false,
          Paint()
            ..color = orlogoColor.withValues(alpha: 0.4)
            ..style = PaintingStyle.stroke
            ..strokeWidth = orlogoStroke + 6.w
            ..strokeCap = StrokeCap.round
            ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 7),
        );
      }

      // Main arc
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: outerRadius),
        startAngle,
        sweepOrlogo,
        false,
        Paint()
          ..color = orlogoColor
          ..style = PaintingStyle.stroke
          ..strokeWidth = orlogoStroke
          ..strokeCap = StrokeCap.round,
      );

      // Jewel tip
      final tipAngle = startAngle + sweepOrlogo;
      final tipPos = Offset(
        center.dx + outerRadius * math.cos(tipAngle),
        center.dy + outerRadius * math.sin(tipAngle),
      );
      canvas.drawCircle(
        tipPos,
        orlogoStroke / 2 + 1.5,
        Paint()..color = orlogoColor.withValues(alpha: 0.4),
      );
      canvas.drawCircle(
        tipPos,
        orlogoStroke / 2 - 0.5,
        Paint()..color = orlogoColor,
      );
      canvas.drawCircle(
        tipPos,
        2.2,
        Paint()..color = Colors.white,
      );
    }

    // ── 3. Авлага (Алтлаг шар нум) ──
    final avlagaRatio = (avlaga / baseTarget).clamp(0.0, 1.0);
    final gap = 0.05;
    final avlagaStart = startAngle + sweepOrlogo + (sweepOrlogo > 0 ? gap : 0.0);
    final availableForAvlaga =
        math.max(0.0, 2 * math.pi - sweepOrlogo - (sweepOrlogo > 0 ? gap * 2 : 0.0));
    final rawSweepAvlaga = (availableForAvlaga * avlagaRatio) * progress;
    final sweepAvlaga = avlaga > 0 ? math.max(0.28, rawSweepAvlaga) : 0.0;
    final isAvlagaSelected = selectedIndex == 2;

    if (sweepAvlaga > 0) {
      final avlagaStroke = isAvlagaSelected ? outerStroke + 4.w : outerStroke;
      final avlagaColor = _CircleDonutChart.avlagaColor;

      if (isAvlagaSelected) {
        canvas.drawArc(
          Rect.fromCircle(center: center, radius: outerRadius),
          avlagaStart,
          sweepAvlaga,
          false,
          Paint()
            ..color = avlagaColor.withValues(alpha: 0.4)
            ..style = PaintingStyle.stroke
            ..strokeWidth = avlagaStroke + 6.w
            ..strokeCap = StrokeCap.round
            ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 7),
        );
      }

      canvas.drawArc(
        Rect.fromCircle(center: center, radius: outerRadius),
        avlagaStart,
        sweepAvlaga,
        false,
        Paint()
          ..color = avlagaColor
          ..style = PaintingStyle.stroke
          ..strokeWidth = avlagaStroke
          ..strokeCap = StrokeCap.round,
      );

      final tipAngle = avlagaStart + sweepAvlaga;
      final tipPos = Offset(
        center.dx + outerRadius * math.cos(tipAngle),
        center.dy + outerRadius * math.sin(tipAngle),
      );
      canvas.drawCircle(
        tipPos,
        avlagaStroke / 2 + 1.5,
        Paint()..color = avlagaColor.withValues(alpha: 0.4),
      );
      canvas.drawCircle(
        tipPos,
        avlagaStroke / 2 - 0.5,
        Paint()..color = avlagaColor,
      );
      canvas.drawCircle(
        tipPos,
        2.2,
        Paint()..color = Colors.white,
      );
    }

    // ── 4. Дотор нум — Зардал (Шүрэн улаан) ──
    final isZardalSelected = selectedIndex == 3;
    final innerTrackColor = isDark
        ? Colors.white.withValues(alpha: 0.08)
        : Colors.black.withValues(alpha: 0.06);

    canvas.drawCircle(
      center,
      innerRadius,
      Paint()
        ..color = innerTrackColor
        ..style = PaintingStyle.stroke
        ..strokeWidth = isZardalSelected ? innerStroke + 2.w : innerStroke,
    );

    final zardalRatio = (zardal / baseTarget).clamp(0.0, 1.0);
    final rawSweepZardal = (2 * math.pi * zardalRatio) * progress;
    final sweepZardal = zardal > 0 ? math.max(0.26, rawSweepZardal) : 0.0;

    if (sweepZardal > 0) {
      final zardalStroke = isZardalSelected ? innerStroke + 3.w : innerStroke;
      final zardalColor = _CircleDonutChart.zardalColor;

      if (isZardalSelected) {
        canvas.drawArc(
          Rect.fromCircle(center: center, radius: innerRadius),
          startAngle,
          sweepZardal,
          false,
          Paint()
            ..color = zardalColor.withValues(alpha: 0.4)
            ..style = PaintingStyle.stroke
            ..strokeWidth = zardalStroke + 5.w
            ..strokeCap = StrokeCap.round
            ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6),
        );
      }

      canvas.drawArc(
        Rect.fromCircle(center: center, radius: innerRadius),
        startAngle,
        sweepZardal,
        false,
        Paint()
          ..color = zardalColor
          ..style = PaintingStyle.stroke
          ..strokeWidth = zardalStroke
          ..strokeCap = StrokeCap.round,
      );

      final tipAngle = startAngle + sweepZardal;
      final tipPos = Offset(
        center.dx + innerRadius * math.cos(tipAngle),
        center.dy + innerRadius * math.sin(tipAngle),
      );
      canvas.drawCircle(
        tipPos,
        zardalStroke / 2 + 1.2,
        Paint()..color = zardalColor.withValues(alpha: 0.35),
      );
      canvas.drawCircle(
        tipPos,
        zardalStroke / 2 - 0.5,
        Paint()..color = zardalColor,
      );
      canvas.drawCircle(
        tipPos,
        1.8,
        Paint()..color = Colors.white,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _SingleDonutPainter old) {
    return old.orlogo != orlogo ||
        old.avlaga != avlaga ||
        old.zardal != zardal ||
        old.tolovlogoot != tolovlogoot ||
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

// ── Интерактив 6 сарын орлого, зардал график ───────────────────────────

class _InteractiveUrsgalGraph extends StatefulWidget {
  const _InteractiveUrsgalGraph({
    required this.saraar,
    required this.tekstUngu,
    required this.shugamUngu,
  });

  final List<Map<String, dynamic>> saraar;
  final Color tekstUngu;
  final Color shugamUngu;

  @override
  State<_InteractiveUrsgalGraph> createState() => _InteractiveUrsgalGraphState();
}

class _InteractiveUrsgalGraphState extends State<_InteractiveUrsgalGraph> {
  int? _selectedIndex;

  @override
  void initState() {
    super.initState();
    if (widget.saraar.isNotEmpty) {
      _selectedIndex = widget.saraar.length - 1;
    }
  }

  @override
  void didUpdateWidget(covariant _InteractiveUrsgalGraph oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.saraar.isEmpty) {
      _selectedIndex = null;
    } else if (_selectedIndex == null || _selectedIndex! >= widget.saraar.length) {
      _selectedIndex = widget.saraar.length - 1;
    }
  }

  void _onPositionUpdate(double localDx, double width) {
    if (widget.saraar.isEmpty) return;
    const zuun = 34.0;
    final urgun = width - zuun - 8;
    if (urgun <= 0) return;
    final relX = (localDx - zuun).clamp(0.0, urgun);
    final count = widget.saraar.length;
    final idx = count == 1 ? 0 : ((relX / urgun) * (count - 1)).round().clamp(0, count - 1);
    if (idx != _selectedIndex) {
      setState(() => _selectedIndex = idx);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = context.isDarkMode;
    final saraar = widget.saraar;

    // Сонгосон сарын мэдээлэл
    Map<String, dynamic>? selectedItem;
    if (_selectedIndex != null && _selectedIndex! >= 0 && _selectedIndex! < saraar.length) {
      selectedItem = saraar[_selectedIndex!];
    }

    double selOrlogo = 0;
    double selZardal = 0;
    double selZuruu = 0;
    String selSarNer = '';

    if (selectedItem != null) {
      selOrlogo = _toDouble(selectedItem['tulsun']);
      selZardal = _toDouble(selectedItem['zardal']);
      selZuruu = selOrlogo - selZardal;
      final parts = '${selectedItem['sar']}'.split('-');
      selSarNer = parts.length == 2
          ? '${parts[0]} оны ${int.tryParse(parts[1]) ?? parts[1]}-р сар'
          : '${selectedItem['sar']}';
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
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          padding: EdgeInsets.all(4.w),
                          decoration: BoxDecoration(
                            color: AppColors.primary.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(6.r),
                          ),
                          child: Icon(Icons.calendar_month_rounded, size: 13.w, color: AppColors.primary),
                        ),
                        SizedBox(width: 6.w),
                        Text(
                          selSarNer,
                          style: TextStyle(
                            fontSize: 12.sp,
                            fontWeight: FontWeight.w700,
                            color: context.textPrimaryColor,
                          ),
                        ),
                      ],
                    ),
                    Container(
                      padding: EdgeInsets.symmetric(horizontal: 7.w, vertical: 2.h),
                      decoration: BoxDecoration(
                        color: (selZuruu >= 0 ? const Color(0xFF10B981) : Colors.redAccent).withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(10.r),
                      ),
                      child: Text(
                        'Цэвэр: ${selZuruu >= 0 ? '+' : ''}${_mungu(selZuruu)}',
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
                            const Spacer(),
                            Text(_mungu(selOrlogo), style: TextStyle(fontSize: 11.5.sp, fontWeight: FontWeight.w700, color: const Color(0xFF10B981))),
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
                            const Spacer(),
                            Text(_mungu(selZardal), style: TextStyle(fontSize: 11.5.sp, fontWeight: FontWeight.w700, color: Colors.redAccent)),
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
                    saraar: saraar,
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
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const _Tailbar(ungu: _Ungu.nogoon, ner: 'Орлого (орсон)'),
            SizedBox(width: 16.w),
            const _Tailbar(ungu: _Ungu.saaral, ner: 'Зардал (гарсан)', tasarkhai: true),
          ],
        ),
      ],
    );
  }
}

// ── Зураг ──────────────────────────────────────────────────────────────

/// 6 сарын орлого (бүтэн гөлгөр муруй) ба зарцуулалт (тасархай муруй) — сая ₮-өөр.
class _UrsgalPainter extends CustomPainter {
  _UrsgalPainter({
    required this.saraar,
    required this.tekstUngu,
    required this.shugamUngu,
    this.selectedIndex,
    this.accentUngu = const Color(0xFF10B981),
  });

  final List<Map<String, dynamic>> saraar;
  final Color tekstUngu;
  final Color shugamUngu;
  final int? selectedIndex;
  final Color accentUngu;

  @override
  void paint(Canvas canvas, Size size) {
    if (saraar.isEmpty) return;
    const zuun = 34.0;
    const dood = 24.0;
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
      ..color = shugamUngu.withValues(alpha: 0.6)
      ..strokeWidth = 0.7;
    final tekstStyle = TextStyle(fontSize: 8.5, color: tekstUngu);

    _bich(canvas, 'сая ₮', const Offset(0, 0), tekstStyle);
    for (var v = 0.0; v <= ikh + 1e-9; v += alkham) {
      final y = deed + undur - (v / ikh) * undur;
      _drawDashedLine(canvas, Offset(zuun, y), Offset(size.width - 8, y), tor, 4.0, 4.0);
      _bich(canvas, v.toStringAsFixed(alkham < 1 ? 1 : 0), Offset(0, y - 6), tekstStyle);
    }

    double x(int i) =>
        zuun + (saraar.length == 1 ? urgun / 2 : i * urgun / (saraar.length - 1));
    double y(double v) => deed + undur - (v / ikh) * undur;

    final orlogoPoints = <Offset>[];
    final zardalPoints = <Offset>[];
    for (var i = 0; i < saraar.length; i++) {
      orlogoPoints.add(Offset(x(i), y(tulsun[i])));
      zardalPoints.add(Offset(x(i), y(zardal[i])));
    }

    // 1. Орлогын гөлгөр муруйн доорх тааламжтай градиент дэвсгэр
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

    // 2. Сонгогдсон сарын босоо чиглүүлэгч шугам
    if (selectedIndex != null &&
        selectedIndex! >= 0 &&
        selectedIndex! < saraar.length) {
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
    }

    // Цэгүүд зурах
    for (var i = 0; i < saraar.length; i++) {
      // Орлого цэг
      canvas.drawCircle(orlogoPoints[i], 3.2, Paint()..color = const Color(0xFF10B981));
      canvas.drawCircle(orlogoPoints[i], 1.6, Paint()..color = Colors.white);

      // Зардал цэг
      canvas.drawCircle(zardalPoints[i], 3.0, Paint()..color = const Color(0xFF94A3B8));
      canvas.drawCircle(zardalPoints[i], 1.5, Paint()..color = Colors.white);
    }

    // 5. X тэнхлэгийн саруудын текст (сонгогдсон сард тод pill)
    for (var i = 0; i < saraar.length; i++) {
      final isSel = selectedIndex == i;
      final sar = '${saraar[i]['sar']}'.split('-');
      final ner = sar.length == 2 ? '${int.tryParse(sar[1]) ?? sar[1]} сар' : '';
      final tp = _tekst(
        ner,
        isSel
            ? TextStyle(
                fontSize: 9.5,
                fontWeight: FontWeight.w700,
                color: accentUngu,
              )
            : tekstStyle,
      );

      final textPos = Offset(x(i) - tp.width / 2, size.height - dood + 6);

      if (isSel) {
        final pillRect = Rect.fromCenter(
          center: Offset(x(i), size.height - dood + 12),
          width: tp.width + 12,
          height: tp.height + 4,
        );
        canvas.drawRRect(
          RRect.fromRectAndRadius(pillRect, const Radius.circular(6)),
          Paint()..color = accentUngu.withValues(alpha: 0.12),
        );
      }
      tp.paint(canvas, textPos);
    }

    // 6. Сонгогдсон сарын цэгүүдийг 3 давхар гэрэлтүүлж тодруулах
    if (selectedIndex != null &&
        selectedIndex! >= 0 &&
        selectedIndex! < saraar.length) {
      final idx = selectedIndex!;

      // Орлого цэг glow
      final orlogoC = orlogoPoints[idx];
      canvas.drawCircle(
        orlogoC,
        8.0,
        Paint()..color = const Color(0xFF10B981).withValues(alpha: 0.22),
      );
      canvas.drawCircle(orlogoC, 5.0, Paint()..color = const Color(0xFF10B981));
      canvas.drawCircle(orlogoC, 2.2, Paint()..color = Colors.white);

      // Зардал цэг glow
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
      old.saraar != saraar ||
      old.tekstUngu != tekstUngu ||
      old.shugamUngu != shugamUngu ||
      old.selectedIndex != selectedIndex ||
      old.accentUngu != accentUngu;
}
