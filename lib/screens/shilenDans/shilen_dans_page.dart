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

/// Шилэн дансны өнгө — мокапын ногоон шатлал, саарал.
class _Ungu {
  static const Color nogoon = Color(0xFF10B981);
  static const Color saaral = Color(0xFF94A3B8);
}

final NumberFormat _too = NumberFormat('#,##0', 'en_US');
String _mungu(num? v) => v == null ? '—' : '${_too.format(v.round())} ₮';

double _toDouble(dynamic v) => v is num ? v.toDouble() : double.tryParse('$v') ?? 0;

class _ShilenDansPageState extends State<ShilenDansPage> {
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

  void _showTolovlogootModal(BuildContext context, Map<String, dynamic> d) {
    final rawSaraar = d['saraar'] as List? ?? [];
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _TolovlogootModal(
        saraar: rawSaraar.map((e) => Map<String, dynamic>.from(e as Map)).toList(),
      ),
    );
  }

  void _showOrlogoModal(BuildContext context, Map<String, dynamic> d, double orlogo) {
    final rawOrloguud = d['orloguud'] as List? ?? [];
    final sarNer = _sarNer(_sar);
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _OrlogoJagsaaltModal(
        sarNer: sarNer,
        sarOrlogo: orlogo,
        orloguud: rawOrloguud.map((e) => Map<String, dynamic>.from(e as Map)).toList(),
      ),
    );
  }

  void _showAvlagaModal(BuildContext context, Map<String, dynamic> d) {
    final ail = Map<String, dynamic>.from(d['ailiinAvlaga'] as Map? ?? {});
    final niit = _toDouble(ail['niit']);
    final khetersen = _toDouble(ail['khetersen']);
    final boloogui = _toDouble(ail['boloogui']);
    final ailToo = (ail['khetersenAilToo'] as num?)?.toInt() ?? 0;
    final ailuud = ail['ailuud'] is List
        ? (ail['ailuud'] as List).map((e) => Map<String, dynamic>.from(e as Map)).toList()
        : <Map<String, dynamic>>[];

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _AvlagaJagsaaltModal(
        niitAvlaga: niit,
        khetersenAvlaga: khetersen,
        bolooguiAvlaga: boloogui,
        ailToo: ailToo,
        ailuud: ailuud,
      ),
    );
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
        child: _body(isDark),
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
        children: _toimTab(d, isDark),
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
          Expanded(
            child: _Utga(
              ner: 'Энэ сарын орлого',
              utga: _mungu(orlogo),
              onTap: () => _showOrlogoModal(context, d, orlogo),
            ),
          ),
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
          onTolovlogootTap: () => _showTolovlogootModal(context, d),
          onOrlogoTap: () => _showOrlogoModal(context, d, orlogo),
          onAvlagaTap: () => _showAvlagaModal(context, d),
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
        dedNer: '${ail['khetersenAilToo'] ?? 0} айл · Жагсаалт харах ›',
        utga: _mungu(_toDouble(ail['khetersen'])),
        ungu: _toDouble(ail['khetersen']) > 0 ? const Color(0xFF9A6A12) : null,
        onTap: () => _showAvlagaModal(context, d),
      ),
      _Mur(
        ner: 'Төлөөгүй (нийт)',
        utga: _mungu(_toDouble(d['tuluugui'])),
        onTap: () => _showAvlagaModal(context, d),
      ),
      _Mur(ner: 'Миний төлбөр', utga: _mungu(_toDouble(d['miniiTulbur']))),
    ];
  }
}

// ── Жижиг widget-ууд ────────────────────────────────────────────────────

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
    this.dedNer,
    this.onTap,
  });

  final String ner;
  final String utga;
  final Color? ungu;
  final String? dedNer;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final content = Container(
      padding: EdgeInsets.symmetric(vertical: 12.h),
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: context.borderColor)),
      ),
      child: Row(
        children: [
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
              if (onTap != null) ...[
                SizedBox(width: 4.w),
                Icon(
                  Icons.chevron_right_rounded,
                  size: 18.sp,
                  color: context.textSecondaryColor.withValues(alpha: 0.6),
                ),
              ],
            ],
          ),
        ],
      ),
    );

    if (onTap != null) {
      return InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8.r),
        child: content,
      );
    }
    return content;
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

/// Айлын авлагын дэлгэрэнгүй жагсаалт харуулах модал
class _AvlagaJagsaaltModal extends StatefulWidget {
  const _AvlagaJagsaaltModal({
    required this.niitAvlaga,
    required this.khetersenAvlaga,
    required this.bolooguiAvlaga,
    required this.ailToo,
    required this.ailuud,
  });

  final double niitAvlaga;
  final double khetersenAvlaga;
  final double bolooguiAvlaga;
  final int ailToo;
  final List<Map<String, dynamic>> ailuud;

  @override
  State<_AvlagaJagsaaltModal> createState() => _AvlagaJagsaaltModalState();
}

class _AvlagaJagsaaltModalState extends State<_AvlagaJagsaaltModal> {
  final TextEditingController _searchCtrl = TextEditingController();
  int _filterIndex = 0; // 0: Бүгд, 1: Хугацаа хэтэрсэн, 2: Хэтрээгүй

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = context.isDarkMode;
    final q = _searchCtrl.text.trim().toLowerCase();

    final filtered = widget.ailuud.where((item) {
      final toot = '${item['toot'] ?? ''}'.toLowerCase();
      if (q.isNotEmpty && !toot.contains(q)) return false;
      final khonog = (item['khonog'] as num?)?.toInt() ?? 0;
      if (_filterIndex == 1 && khonog <= 0) return false;
      if (_filterIndex == 2 && khonog > 0) return false;
      return true;
    }).toList();

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.86,
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
                height: 4.5.h,
                decoration: BoxDecoration(
                  color: context.borderColor.withValues(alpha: 0.8),
                  borderRadius: BorderRadius.circular(3.r),
                ),
              ),
            ),
            Padding(
              padding: EdgeInsets.fromLTRB(20.w, 12.h, 14.w, 8.h),
              child: Row(
                children: [
                  Container(
                    width: 34.w,
                    height: 34.w,
                    decoration: BoxDecoration(
                      color: _CircleDonutChart.avlagaColor.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(10.r),
                    ),
                    child: Icon(
                      Icons.pending_actions_rounded,
                      color: _CircleDonutChart.avlagaColor,
                      size: 18.w,
                    ),
                  ),
                  SizedBox(width: 10.w),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Айлын авлагын жагсаалт',
                          style: TextStyle(
                            fontSize: 16.sp,
                            fontWeight: FontWeight.w700,
                            color: context.textPrimaryColor,
                          ),
                        ),
                        SizedBox(height: 1.h),
                        Text(
                          'Нийт ${widget.ailuud.length} айлын үлдэгдэл төлбөр',
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
                    icon: Icon(Icons.close_rounded, size: 22.sp, color: context.textSecondaryColor),
                  ),
                ],
              ),
            ),
            // Карт: Нийт авлага & Хэтэрсэн
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 6.h),
              child: Container(
                padding: EdgeInsets.all(12.w),
                decoration: BoxDecoration(
                  color: isDark ? AppColors.darkBackground : const Color(0xFFF9FAFB),
                  borderRadius: BorderRadius.circular(12.r),
                  border: Border.all(color: context.borderColor),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Нийт авлага',
                              style: TextStyle(fontSize: 11.sp, color: context.textSecondaryColor)),
                          SizedBox(height: 2.h),
                          FittedBox(
                            fit: BoxFit.scaleDown,
                            alignment: Alignment.centerLeft,
                            child: Text(
                              _mungu(widget.niitAvlaga),
                              style: TextStyle(
                                fontSize: 16.sp,
                                fontWeight: FontWeight.w800,
                                color: _CircleDonutChart.avlagaColor,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(width: 1, height: 32.h, color: context.borderColor),
                    SizedBox(width: 12.w),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Хугацаа хэтэрсэн',
                              style: TextStyle(fontSize: 11.sp, color: context.textSecondaryColor)),
                          SizedBox(height: 2.h),
                          FittedBox(
                            fit: BoxFit.scaleDown,
                            alignment: Alignment.centerLeft,
                            child: Text(
                              '${_mungu(widget.khetersenAvlaga)} (${widget.ailToo} айл)',
                              style: TextStyle(
                                fontSize: 13.5.sp,
                                fontWeight: FontWeight.w700,
                                color: widget.khetersenAvlaga > 0 ? const Color(0xFFEF4444) : context.textPrimaryColor,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            // Хайлт болон шүүлтүүр
            Padding(
              padding: EdgeInsets.fromLTRB(16.w, 4.h, 16.w, 8.h),
              child: Row(
                children: [
                  Expanded(
                    child: Container(
                      height: 38.h,
                      decoration: BoxDecoration(
                        color: isDark ? AppColors.darkBackground : const Color(0xFFF3F4F6),
                        borderRadius: BorderRadius.circular(10.r),
                        border: Border.all(color: context.borderColor),
                      ),
                      child: TextField(
                        controller: _searchCtrl,
                        onChanged: (_) => setState(() {}),
                        style: TextStyle(fontSize: 13.sp, color: context.textPrimaryColor),
                        decoration: InputDecoration(
                          hintText: 'Тоотоор хайх (ж: 606)...',
                          hintStyle: TextStyle(fontSize: 12.sp, color: context.textSecondaryColor),
                          prefixIcon: Icon(Icons.search_rounded, size: 18.sp, color: context.textSecondaryColor),
                          suffixIcon: _searchCtrl.text.isNotEmpty
                              ? GestureDetector(
                                  onTap: () {
                                    _searchCtrl.clear();
                                    setState(() {});
                                  },
                                  child: Icon(Icons.cancel_rounded, size: 16.sp, color: context.textSecondaryColor),
                                )
                              : null,
                          border: InputBorder.none,
                          contentPadding: EdgeInsets.symmetric(vertical: 9.h),
                        ),
                      ),
                    ),
                  ),
                  SizedBox(width: 8.w),
                  GestureDetector(
                    onTap: () {
                      setState(() {
                        _filterIndex = (_filterIndex + 1) % 3;
                      });
                    },
                    child: Container(
                      height: 38.h,
                      padding: EdgeInsets.symmetric(horizontal: 10.w),
                      decoration: BoxDecoration(
                        color: _filterIndex != 0
                            ? (_filterIndex == 1
                                ? const Color(0xFFEF4444).withValues(alpha: 0.12)
                                : _CircleDonutChart.orlogoColor.withValues(alpha: 0.12))
                            : (isDark ? AppColors.darkBackground : const Color(0xFFF3F4F6)),
                        borderRadius: BorderRadius.circular(10.r),
                        border: Border.all(
                          color: _filterIndex != 0
                              ? (_filterIndex == 1 ? const Color(0xFFEF4444) : _CircleDonutChart.orlogoColor)
                              : context.borderColor,
                        ),
                      ),
                      alignment: Alignment.center,
                      child: Row(
                        children: [
                          Icon(
                            Icons.filter_list_rounded,
                            size: 16.sp,
                            color: _filterIndex == 1
                                ? const Color(0xFFEF4444)
                                : (_filterIndex == 2
                                    ? _CircleDonutChart.orlogoColor
                                    : context.textSecondaryColor),
                          ),
                          SizedBox(width: 4.w),
                          Text(
                            _filterIndex == 0 ? 'Бүгд' : (_filterIndex == 1 ? 'Хэтэрсэн' : 'Хэвийн'),
                            style: TextStyle(
                              fontSize: 11.5.sp,
                              fontWeight: FontWeight.w600,
                              color: _filterIndex == 1
                                  ? const Color(0xFFEF4444)
                                  : (_filterIndex == 2
                                      ? _CircleDonutChart.orlogoColor
                                      : context.textSecondaryColor),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            // Жагсаалт
            Expanded(
              child: filtered.isEmpty
                  ? Center(
                      child: Padding(
                        padding: EdgeInsets.all(24.w),
                        child: Text(
                          'Айлын авлагын мэдээлэл олдсонгүй',
                          style: TextStyle(fontSize: 13.sp, color: context.textSecondaryColor),
                        ),
                      ),
                    )
                  : ListView.separated(
                      padding: EdgeInsets.fromLTRB(16.w, 4.h, 16.w, 20.h),
                      itemCount: filtered.length,
                      separatorBuilder: (_, i) => Divider(height: 12.h, color: context.borderColor.withValues(alpha: 0.6)),
                      itemBuilder: (ctx, i) {
                        final item = filtered[i];
                        final toot = '${item['toot'] ?? ''}';
                        final tuluugui = _toDouble(item['tuluugui']);
                        final khonog = (item['khonog'] as num?)?.toInt() ?? 0;
                        final isOverdue = khonog > 0;
                        final suuliinTulsun = '${item['suuliinTulsunOgnoo'] ?? ''}'.split('T').first;

                        return Padding(
                          padding: EdgeInsets.symmetric(vertical: 4.h),
                          child: Row(
                            children: [
                              Container(
                                width: 38.w,
                                height: 38.w,
                                decoration: BoxDecoration(
                                  color: (isOverdue ? const Color(0xFFEF4444) : _CircleDonutChart.avlagaColor).withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(10.r),
                                ),
                                alignment: Alignment.center,
                                child: Text(
                                  toot,
                                  style: TextStyle(
                                    fontSize: 12.sp,
                                    fontWeight: FontWeight.w800,
                                    color: isOverdue ? const Color(0xFFEF4444) : _CircleDonutChart.avlagaColor,
                                  ),
                                ),
                              ),
                              SizedBox(width: 12.w),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      '$toot тоот',
                                      style: TextStyle(
                                        fontSize: 14.sp,
                                        fontWeight: FontWeight.w600,
                                        color: context.textPrimaryColor,
                                      ),
                                    ),
                                    SizedBox(height: 2.h),
                                    Row(
                                      children: [
                                        Text(
                                          isOverdue ? '$khonog хоног төлөөгүй' : 'Хугацаа хэтрээгүй',
                                          style: TextStyle(
                                            fontSize: 11.5.sp,
                                            color: isOverdue ? const Color(0xFFDC2626) : context.textSecondaryColor,
                                            fontWeight: isOverdue ? FontWeight.w600 : FontWeight.w400,
                                          ),
                                        ),
                                        if (suuliinTulsun.isNotEmpty) ...[
                                          Text(
                                            ' · Сүүлд: $suuliinTulsun',
                                            style: TextStyle(
                                              fontSize: 10.5.sp,
                                              color: context.textSecondaryColor.withValues(alpha: 0.8),
                                            ),
                                          ),
                                        ],
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                              Text(
                                _mungu(tuluugui),
                                style: TextStyle(
                                  fontSize: 14.sp,
                                  fontWeight: FontWeight.w700,
                                  color: isOverdue ? const Color(0xFFEF4444) : context.textPrimaryColor,
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Сүүлийн орлогын жагсаалт харуулах модал
class _OrlogoJagsaaltModal extends StatefulWidget {
  const _OrlogoJagsaaltModal({
    required this.sarNer,
    required this.sarOrlogo,
    required this.orloguud,
  });

  final String sarNer;
  final double sarOrlogo;
  final List<Map<String, dynamic>> orloguud;

  @override
  State<_OrlogoJagsaaltModal> createState() => _OrlogoJagsaaltModalState();
}

class _OrlogoJagsaaltModalState extends State<_OrlogoJagsaaltModal> {
  final TextEditingController _searchCtrl = TextEditingController();

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = context.isDarkMode;
    final q = _searchCtrl.text.trim().toLowerCase();

    final filtered = widget.orloguud.where((item) {
      if (q.isEmpty) return true;
      final toot = '${item['toot'] ?? ''}'.toLowerCase();
      final tailbar = '${item['tailbar'] ?? ''}'.toLowerCase();
      final ajiltan = '${item['ajiltniiNer'] ?? ''}'.toLowerCase();
      return toot.contains(q) || tailbar.contains(q) || ajiltan.contains(q);
    }).toList();

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.86,
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
                height: 4.5.h,
                decoration: BoxDecoration(
                  color: context.borderColor.withValues(alpha: 0.8),
                  borderRadius: BorderRadius.circular(3.r),
                ),
              ),
            ),
            Padding(
              padding: EdgeInsets.fromLTRB(20.w, 12.h, 14.w, 8.h),
              child: Row(
                children: [
                  Container(
                    width: 34.w,
                    height: 34.w,
                    decoration: BoxDecoration(
                      color: _CircleDonutChart.orlogoColor.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(10.r),
                    ),
                    child: Icon(
                      Icons.account_balance_wallet_rounded,
                      color: _CircleDonutChart.orlogoColor,
                      size: 18.w,
                    ),
                  ),
                  SizedBox(width: 10.w),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Төлбөр төлөлтүүд',
                          style: TextStyle(
                            fontSize: 16.sp,
                            fontWeight: FontWeight.w700,
                            color: context.textPrimaryColor,
                          ),
                        ),
                        SizedBox(height: 1.h),
                        Text(
                          '${widget.sarNer} · Сүүлд орсон орлогууд',
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
                    icon: Icon(Icons.close_rounded, size: 22.sp, color: context.textSecondaryColor),
                  ),
                ],
              ),
            ),
            // Карт: Энэ сарын орлого
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 6.h),
              child: Container(
                padding: EdgeInsets.all(12.w),
                decoration: BoxDecoration(
                  color: isDark ? AppColors.darkBackground : const Color(0xFFF9FAFB),
                  borderRadius: BorderRadius.circular(12.r),
                  border: Border.all(color: context.borderColor),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Сонгосон сарын орлого',
                              style: TextStyle(fontSize: 11.sp, color: context.textSecondaryColor)),
                          SizedBox(height: 2.h),
                          FittedBox(
                            fit: BoxFit.scaleDown,
                            alignment: Alignment.centerLeft,
                            child: Text(
                              _mungu(widget.sarOrlogo),
                              style: TextStyle(
                                fontSize: 16.sp,
                                fontWeight: FontWeight.w800,
                                color: _CircleDonutChart.orlogoColor,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(width: 1, height: 32.h, color: context.borderColor),
                    SizedBox(width: 12.w),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Сүүлийн гүйлгээ',
                              style: TextStyle(fontSize: 11.sp, color: context.textSecondaryColor)),
                          SizedBox(height: 2.h),
                          Text(
                            '${widget.orloguud.length} гүйлгээ',
                            style: TextStyle(
                              fontSize: 14.sp,
                              fontWeight: FontWeight.w700,
                              color: context.textPrimaryColor,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            // Хайлт
            Padding(
              padding: EdgeInsets.fromLTRB(16.w, 4.h, 16.w, 8.h),
              child: Container(
                height: 38.h,
                decoration: BoxDecoration(
                  color: isDark ? AppColors.darkBackground : const Color(0xFFF3F4F6),
                  borderRadius: BorderRadius.circular(10.r),
                  border: Border.all(color: context.borderColor),
                ),
                child: TextField(
                  controller: _searchCtrl,
                  onChanged: (_) => setState(() {}),
                  style: TextStyle(fontSize: 13.sp, color: context.textPrimaryColor),
                  decoration: InputDecoration(
                    hintText: 'Тоот, гүйлгээний утгаар хайх...',
                    hintStyle: TextStyle(fontSize: 12.sp, color: context.textSecondaryColor),
                    prefixIcon: Icon(Icons.search_rounded, size: 18.sp, color: context.textSecondaryColor),
                    suffixIcon: _searchCtrl.text.isNotEmpty
                        ? GestureDetector(
                            onTap: () {
                              _searchCtrl.clear();
                              setState(() {});
                            },
                            child: Icon(Icons.cancel_rounded, size: 16.sp, color: context.textSecondaryColor),
                          )
                        : null,
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.symmetric(vertical: 9.h),
                  ),
                ),
              ),
            ),
            // Жагсаалт
            Expanded(
              child: filtered.isEmpty
                  ? Center(
                      child: Padding(
                        padding: EdgeInsets.all(24.w),
                        child: Text(
                          'Төлбөр төлөлтийн бичилт олдсонгүй',
                          style: TextStyle(fontSize: 13.sp, color: context.textSecondaryColor),
                        ),
                      ),
                    )
                  : ListView.separated(
                      padding: EdgeInsets.fromLTRB(16.w, 4.h, 16.w, 20.h),
                      itemCount: filtered.length,
                      separatorBuilder: (_, i) => Divider(height: 12.h, color: context.borderColor.withValues(alpha: 0.6)),
                      itemBuilder: (ctx, i) {
                        final item = filtered[i];
                        final toot = '${item['toot'] ?? ''}';
                        final dun = _toDouble(item['dun']);
                        final ognoo = '${item['ognoo'] ?? ''}'.split('T').first;
                        final tailbar = '${item['tailbar'] ?? ''}'.trim();
                        final ajiltan = '${item['ajiltniiNer'] ?? ''}'.trim();

                        final ded = [
                          if (ognoo.isNotEmpty) ognoo,
                          if (ajiltan.isNotEmpty) ajiltan,
                        ].join(' · ');

                        return Padding(
                          padding: EdgeInsets.symmetric(vertical: 4.h),
                          child: Row(
                            children: [
                              Container(
                                width: 38.w,
                                height: 38.w,
                                decoration: BoxDecoration(
                                  color: _CircleDonutChart.orlogoColor.withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(10.r),
                                ),
                                alignment: Alignment.center,
                                child: Text(
                                  toot.isNotEmpty ? toot : '₮',
                                  style: TextStyle(
                                    fontSize: 12.sp,
                                    fontWeight: FontWeight.w800,
                                    color: _CircleDonutChart.orlogoColor,
                                  ),
                                ),
                              ),
                              SizedBox(width: 12.w),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      toot.isNotEmpty ? '$toot тоот' : (tailbar.isNotEmpty ? tailbar : 'Төлөлт'),
                                      style: TextStyle(
                                        fontSize: 14.sp,
                                        fontWeight: FontWeight.w600,
                                        color: context.textPrimaryColor,
                                      ),
                                    ),
                                    if (tailbar.isNotEmpty && toot.isNotEmpty) ...[
                                      SizedBox(height: 2.h),
                                      Text(
                                        tailbar,
                                        style: TextStyle(
                                          fontSize: 11.5.sp,
                                          color: context.textSecondaryColor,
                                        ),
                                        maxLines: 1,
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
                              Text(
                                '+${_mungu(dun)}',
                                style: TextStyle(
                                  fontSize: 14.sp,
                                  fontWeight: FontWeight.w700,
                                  color: _CircleDonutChart.orlogoColor,
                                  letterSpacing: -0.2,
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Төлөвлөгөөт нэхэмжлэлийн өмнөх саруудын түүх болон оны шүүлтүүр бүхий модал
class _TolovlogootModal extends StatefulWidget {
  const _TolovlogootModal({
    required this.saraar,
  });

  final List<Map<String, dynamic>> saraar;

  @override
  State<_TolovlogootModal> createState() => _TolovlogootModalState();
}

class _TolovlogootModalState extends State<_TolovlogootModal> {
  int _selectedYear = 2026;
  late List<int> _years;

  @override
  void initState() {
    super.initState();
    final ySet = <int>{};
    for (final s in widget.saraar) {
      final j = (s['jil'] as num?)?.toInt();
      if (j != null && j > 0) {
        ySet.add(j);
      } else {
        final sarStr = '${s['sar'] ?? ''}';
        final parts = sarStr.split('-');
        if (parts.isNotEmpty) {
          final parsed = int.tryParse(parts[0]);
          if (parsed != null && parsed > 2000) ySet.add(parsed);
        }
      }
    }
    if (ySet.isEmpty) {
      ySet.add(DateTime.now().year);
    }
    _years = ySet.toList()..sort((a, b) => b.compareTo(a));
    _selectedYear = _years.first;
  }

  @override
  Widget build(BuildContext context) {
    final isDark = context.isDarkMode;

    final filtered = widget.saraar.where((s) {
      final j = (s['jil'] as num?)?.toInt();
      if (j != null && j > 0) return j == _selectedYear;
      final sarStr = '${s['sar'] ?? ''}';
      return sarStr.startsWith('$_selectedYear');
    }).toList();

    double totalPlanned = 0;
    double totalPaid = 0;
    for (final s in filtered) {
      totalPlanned += _toDouble(s['nekhemjilsen']);
      totalPaid += _toDouble(s['tulsun']);
    }
    final paidPercent = totalPlanned > 0 ? (totalPaid / totalPlanned * 100).toStringAsFixed(1) : '0';

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.86,
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
                height: 4.5.h,
                decoration: BoxDecoration(
                  color: context.borderColor.withValues(alpha: 0.8),
                  borderRadius: BorderRadius.circular(3.r),
                ),
              ),
            ),
            Padding(
              padding: EdgeInsets.fromLTRB(20.w, 12.h, 14.w, 8.h),
              child: Row(
                children: [
                  Container(
                    width: 34.w,
                    height: 34.w,
                    decoration: BoxDecoration(
                      color: _CircleDonutChart.tolovlogootColor.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(10.r),
                    ),
                    child: Icon(
                      Icons.fact_check_rounded,
                      color: _CircleDonutChart.tolovlogootColor,
                      size: 18.w,
                    ),
                  ),
                  SizedBox(width: 10.w),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Төлөвлөгөөт нэхэмжлэлийн түүх',
                          style: TextStyle(
                            fontSize: 16.sp,
                            fontWeight: FontWeight.w700,
                            color: context.textPrimaryColor,
                          ),
                        ),
                        SizedBox(height: 1.h),
                        Text(
                          'Өмнөх саруудын нэхэмжилсэн болон төлөгдсөн дүн',
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
                    icon: Icon(Icons.close_rounded, size: 22.sp, color: context.textSecondaryColor),
                  ),
                ],
              ),
            ),
            // Оны шүүлтүүр (Year selector pills)
            if (_years.length > 1)
              Padding(
                padding: EdgeInsets.fromLTRB(16.w, 0, 16.w, 8.h),
                child: SizedBox(
                  height: 34.h,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    itemCount: _years.length,
                    separatorBuilder: (_, i) => SizedBox(width: 8.w),
                    itemBuilder: (ctx, i) {
                      final yr = _years[i];
                      final isSel = yr == _selectedYear;
                      return GestureDetector(
                        onTap: () => setState(() => _selectedYear = yr),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 160),
                          padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 6.h),
                          decoration: BoxDecoration(
                            color: isSel
                                ? _CircleDonutChart.tolovlogootColor
                                : (isDark ? AppColors.darkBackground : const Color(0xFFF3F4F6)),
                            borderRadius: BorderRadius.circular(20.r),
                            border: Border.all(
                              color: isSel ? _CircleDonutChart.tolovlogootColor : context.borderColor,
                            ),
                          ),
                          alignment: Alignment.center,
                          child: Text(
                            '$yr он',
                            style: TextStyle(
                              fontSize: 12.5.sp,
                              fontWeight: isSel ? FontWeight.w700 : FontWeight.w500,
                              color: isSel ? Colors.white : context.textSecondaryColor,
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ),
            // Карт: Тухайн оны нийт нэхэмжилсэн ба төлөгдсөн
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 4.h),
              child: Container(
                padding: EdgeInsets.all(12.w),
                decoration: BoxDecoration(
                  color: isDark ? AppColors.darkBackground : const Color(0xFFF9FAFB),
                  borderRadius: BorderRadius.circular(12.r),
                  border: Border.all(color: context.borderColor),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('$_selectedYear оны нэхэмжилсэн',
                              style: TextStyle(fontSize: 11.sp, color: context.textSecondaryColor)),
                          SizedBox(height: 2.h),
                          FittedBox(
                            fit: BoxFit.scaleDown,
                            alignment: Alignment.centerLeft,
                            child: Text(
                              _mungu(totalPlanned),
                              style: TextStyle(
                                fontSize: 16.sp,
                                fontWeight: FontWeight.w800,
                                color: _CircleDonutChart.tolovlogootColor,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(width: 1, height: 32.h, color: context.borderColor),
                    SizedBox(width: 12.w),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Төлөгдсөн хувь',
                              style: TextStyle(fontSize: 11.sp, color: context.textSecondaryColor)),
                          SizedBox(height: 2.h),
                          Text(
                            '$paidPercent% (${_mungu(totalPaid)})',
                            style: TextStyle(
                              fontSize: 13.5.sp,
                              fontWeight: FontWeight.w700,
                              color: _CircleDonutChart.orlogoColor,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            SizedBox(height: 6.h),
            // Саруудын жагсаалт
            Expanded(
              child: filtered.isEmpty
                  ? Center(
                      child: Padding(
                        padding: EdgeInsets.all(24.w),
                        child: Text(
                          '$_selectedYear оны төлөвлөгөөт мэдээлэл олдсонгүй',
                          style: TextStyle(fontSize: 13.sp, color: context.textSecondaryColor),
                        ),
                      ),
                    )
                  : ListView.separated(
                      padding: EdgeInsets.fromLTRB(16.w, 4.h, 16.w, 20.h),
                      itemCount: filtered.length,
                      separatorBuilder: (_, i) => Divider(height: 14.h, color: context.borderColor.withValues(alpha: 0.6)),
                      itemBuilder: (ctx, i) {
                        final item = filtered[i];
                        final sarStr = '${item['sar'] ?? ''}';
                        final sarDugaar = item['sarDugaar'] ?? (sarStr.contains('-') ? sarStr.split('-')[1] : sarStr);
                        final nekhemjilsen = _toDouble(item['nekhemjilsen']);
                        final tulsun = _toDouble(item['tulsun']);
                        final pct = nekhemjilsen > 0 ? (tulsun / nekhemjilsen).clamp(0.0, 1.0) : 0.0;
                        final pctStr = nekhemjilsen > 0 ? (tulsun / nekhemjilsen * 100).toStringAsFixed(1) : '0';

                        return Container(
                          padding: EdgeInsets.symmetric(vertical: 6.h),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Container(
                                    padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 3.h),
                                    decoration: BoxDecoration(
                                      color: _CircleDonutChart.tolovlogootColor.withValues(alpha: 0.12),
                                      borderRadius: BorderRadius.circular(6.r),
                                    ),
                                    child: Text(
                                      '$sarDugaar сар',
                                      style: TextStyle(
                                        fontSize: 12.sp,
                                        fontWeight: FontWeight.w700,
                                        color: _CircleDonutChart.tolovlogootColor,
                                      ),
                                    ),
                                  ),
                                  SizedBox(width: 8.w),
                                  Text(
                                    sarStr,
                                    style: TextStyle(fontSize: 12.sp, color: context.textSecondaryColor),
                                  ),
                                  const Spacer(),
                                  Text(
                                    _mungu(nekhemjilsen),
                                    style: TextStyle(
                                      fontSize: 14.sp,
                                      fontWeight: FontWeight.w700,
                                      color: context.textPrimaryColor,
                                    ),
                                  ),
                                ],
                              ),
                              SizedBox(height: 8.h),
                              // Прогресс бар
                              ClipRRect(
                                borderRadius: BorderRadius.circular(4.r),
                                child: Container(
                                  height: 6.h,
                                  color: isDark ? AppColors.darkBackground : const Color(0xFFE5E7EB),
                                  child: FractionallySizedBox(
                                    alignment: Alignment.centerLeft,
                                    widthFactor: pct,
                                    child: Container(
                                      color: _CircleDonutChart.orlogoColor,
                                    ),
                                  ),
                                ),
                              ),
                              SizedBox(height: 6.h),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    'Төлөгдсөн: ${_mungu(tulsun)} ($pctStr%)',
                                    style: TextStyle(
                                      fontSize: 11.5.sp,
                                      fontWeight: FontWeight.w600,
                                      color: _CircleDonutChart.orlogoColor,
                                    ),
                                  ),
                                  if (_toDouble(item['zardal']) > 0)
                                    Text(
                                      'Зардал: ${_mungu(_toDouble(item['zardal']))}',
                                      style: TextStyle(
                                        fontSize: 11.sp,
                                        color: context.textSecondaryColor,
                                      ),
                                    ),
                                ],
                              ),
                            ],
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Санхүүгийн бүтэц — Circular Step Infographic (Хэрэглэгчийн мокап загвартай яг ижил шийдэл)
class _CircleDonutChart extends StatefulWidget {
  const _CircleDonutChart({
    required this.tolovlogoot,
    required this.orlogo,
    required this.avlaga,
    required this.zardal,
    this.onTolovlogootTap,
    this.onOrlogoTap,
    this.onAvlagaTap,
    this.onZardalTap,
  });

  final double tolovlogoot;
  final double orlogo;
  final double avlaga;
  final double zardal;
  final VoidCallback? onTolovlogootTap;
  final VoidCallback? onOrlogoTap;
  final VoidCallback? onAvlagaTap;
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
  int _selectedIndex = -1; // -1: Бүх нийтийн тойм

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

  void _handleInfographicTap(Offset localPos, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final dx = localPos.dx - center.dx;
    final dy = localPos.dy - center.dy;
    final dist = math.sqrt(dx * dx + dy * dy);

    // Голын төв таваг дээр дарвал (радиус ~48.w):
    if (dist <= size.width * 0.24) {
      if (_selectedIndex == 0) {
        widget.onTolovlogootTap?.call();
      } else if (_selectedIndex == 1) {
        widget.onOrlogoTap?.call();
      } else if (_selectedIndex == 2) {
        widget.onAvlagaTap?.call();
      } else if (_selectedIndex == 3) {
        widget.onZardalTap?.call();
      } else {
        setState(() => _selectedIndex = -1);
      }
      return;
    }

    final angle = math.atan2(dy, dx); // [-pi, pi]

    if (angle >= -math.pi && angle < -math.pi / 2) {
      // Top-Left (2-р квадрант) -> Төлөвлөгөөт
      if (_selectedIndex == 0) {
        widget.onTolovlogootTap?.call();
      } else {
        _onTapSegment(0);
      }
    } else if (angle >= -math.pi / 2 && angle < 0) {
      // Top-Right (1-р квадрант) -> Орлого
      if (_selectedIndex == 1) {
        widget.onOrlogoTap?.call();
      } else {
        _onTapSegment(1);
      }
    } else if (angle >= 0 && angle < math.pi / 2) {
      // Bottom-Right (4-р квадрант) -> Зардал
      if (_selectedIndex == 3) {
        widget.onZardalTap?.call();
      } else {
        _onTapSegment(3);
      }
    } else {
      // Bottom-Left (3-р квадрант) -> Авлага
      if (_selectedIndex == 2) {
        widget.onAvlagaTap?.call();
      } else {
        _onTapSegment(2);
      }
    }
  }

  Widget _buildCalloutItem({
    required int idx,
    required String step,
    required String amount,
    required String subtitle,
    required Color color,
    required bool alignLeft,
    required bool isDark,
    String? actionText,
    VoidCallback? onTap,
  }) {
    final isSelected = _selectedIndex == idx;
    return GestureDetector(
      onTap: onTap ?? () => _onTapSegment(idx),
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 6.h),
        decoration: BoxDecoration(
          color: isSelected
              ? color.withValues(alpha: isDark ? 0.20 : 0.09)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(10.r),
          border: Border.all(
            color: isSelected ? color.withValues(alpha: 0.55) : Colors.transparent,
            width: 1.2,
          ),
        ),
        child: Column(
          crossAxisAlignment:
              alignLeft ? CrossAxisAlignment.start : CrossAxisAlignment.end,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (!alignLeft) ...[
                  Container(
                    width: 7.w,
                    height: 7.w,
                    decoration: BoxDecoration(color: color, shape: BoxShape.circle),
                  ),
                  SizedBox(width: 5.w),
                ],
                Text(
                  step,
                  style: TextStyle(
                    fontSize: 10.5.sp,
                    fontWeight: FontWeight.w800,
                    color: color,
                    letterSpacing: 0.5,
                  ),
                ),
                if (alignLeft) ...[
                  SizedBox(width: 5.w),
                  Container(
                    width: 7.w,
                    height: 7.w,
                    decoration: BoxDecoration(color: color, shape: BoxShape.circle),
                  ),
                ],
              ],
            ),
            SizedBox(height: 2.5.h),
            FittedBox(
              fit: BoxFit.scaleDown,
              alignment: alignLeft ? Alignment.centerLeft : Alignment.centerRight,
              child: Text(
                amount,
                style: TextStyle(
                  fontSize: 16.5.sp,
                  fontWeight: FontWeight.w800,
                  color: isSelected ? color : context.textPrimaryColor,
                  letterSpacing: -0.2,
                ),
              ),
            ),
            SizedBox(height: 2.h),
            if (actionText != null)
              Text(
                actionText,
                style: TextStyle(
                  fontSize: 10.sp,
                  fontWeight: FontWeight.w700,
                  color: color,
                ),
              )
            else
              Text(
                subtitle,
                style: TextStyle(
                  fontSize: 10.sp,
                  color: context.textSecondaryColor,
                ),
              ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = context.isDarkMode;

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

    const colors = [
      _CircleDonutChart.tolovlogootColor, // 0: Top-Left (Төлөвлөгөөт)
      _CircleDonutChart.orlogoColor,      // 1: Top-Right (Орлого)
      _CircleDonutChart.avlagaColor,      // 2: Bottom-Left (Авлага)
      _CircleDonutChart.zardalColor,      // 3: Bottom-Right (Зардал)
    ];

    // Тод цул санхүүгийн дүрсүүд
    const icons = [
      Icons.fact_check_rounded,                // Төлөвлөгөөт (Нэхэмжлэх төлөвлөгөөний хуудас)
      Icons.account_balance_wallet_rounded,    // Орлого (Цул цэвэр түрийвч)
      Icons.pending_actions_rounded,            // Авлага (Хүлээгдэж буй хугацаа / үйлдэл)
      Icons.receipt_long_rounded,              // Зардал (Цул зарлагын баримт)
    ];

    // Төвийн таваг дээрх мэдээлэл
    Widget centerText;
    if (_selectedIndex == 0) {
      centerText = Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text('ТӨЛӨВЛӨГӨӨТ',
              style: TextStyle(
                  fontSize: 9.sp,
                  fontWeight: FontWeight.w800,
                  color: _CircleDonutChart.tolovlogootColor)),
          SizedBox(height: 2.h),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(_mungu(widget.tolovlogoot),
                style: TextStyle(
                    fontSize: 14.5.sp,
                    fontWeight: FontWeight.w900,
                    color: _CircleDonutChart.tolovlogootColor)),
          ),
          SizedBox(height: 2.h),
          Text('Түүх харах ›',
              style: TextStyle(
                  fontSize: 8.5.sp,
                  fontWeight: FontWeight.w800,
                  color: _CircleDonutChart.tolovlogootColor)),
        ],
      );
    } else if (_selectedIndex == 1) {
      centerText = Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text('ОРЛОГО',
              style: TextStyle(
                  fontSize: 9.sp,
                  fontWeight: FontWeight.w800,
                  color: _CircleDonutChart.orlogoColor)),
          SizedBox(height: 2.h),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(_mungu(widget.orlogo),
                style: TextStyle(
                    fontSize: 15.sp,
                    fontWeight: FontWeight.w900,
                    color: _CircleDonutChart.orlogoColor)),
          ),
          SizedBox(height: 2.h),
          Text('Төлөлтүүд ›',
              style: TextStyle(
                  fontSize: 8.5.sp,
                  fontWeight: FontWeight.w800,
                  color: _CircleDonutChart.orlogoColor)),
        ],
      );
    } else if (_selectedIndex == 2) {
      centerText = Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text('АВЛАГА',
              style: TextStyle(
                  fontSize: 9.sp,
                  fontWeight: FontWeight.w800,
                  color: _CircleDonutChart.avlagaColor)),
          SizedBox(height: 2.h),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(_mungu(widget.avlaga),
                style: TextStyle(
                    fontSize: 15.sp,
                    fontWeight: FontWeight.w900,
                    color: _CircleDonutChart.avlagaColor)),
          ),
          SizedBox(height: 2.h),
          Text('Айлууд харах ›',
              style: TextStyle(
                  fontSize: 8.5.sp,
                  fontWeight: FontWeight.w800,
                  color: _CircleDonutChart.avlagaColor)),
        ],
      );
    } else if (_selectedIndex == 3) {
      centerText = Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text('ЗАРДАЛ',
              style: TextStyle(
                  fontSize: 9.sp,
                  fontWeight: FontWeight.w800,
                  color: _CircleDonutChart.zardalColor)),
          SizedBox(height: 2.h),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(_mungu(widget.zardal),
                style: TextStyle(
                    fontSize: 15.sp,
                    fontWeight: FontWeight.w900,
                    color: _CircleDonutChart.zardalColor)),
          ),
          SizedBox(height: 2.h),
          Text('Жагсаалт харах ›',
              style: TextStyle(
                  fontSize: 8.5.sp,
                  fontWeight: FontWeight.w800,
                  color: _CircleDonutChart.zardalColor)),
        ],
      );
    } else {
      centerText = Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'САНХҮҮ',
            style: TextStyle(
              fontSize: 9.sp,
              fontWeight: FontWeight.w800,
              color: _CircleDonutChart.tolovlogootColor,
              letterSpacing: 0.5,
            ),
          ),
          Text(
            'БҮТЭЦ',
            style: TextStyle(
              fontSize: 14.5.sp,
              fontWeight: FontWeight.w900,
              color: _CircleDonutChart.orlogoColor,
              letterSpacing: 0.5,
            ),
          ),
          Text(
            'ТОЙМ',
            style: TextStyle(
              fontSize: 8.5.sp,
              fontWeight: FontWeight.w800,
              color: const Color(0xFFE8B04A),
              letterSpacing: 0.5,
            ),
          ),
        ],
      );
    }

    final chartSize = 208.w;

    return Container(
      padding: EdgeInsets.symmetric(vertical: 6.h),
      child: Column(
        children: [
          // ── ДЭЭД ЭГНЭЭ (Төлөвлөгөөт зүүн талд, Орлого баруун талд) ──
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: _buildCalloutItem(
                  idx: 0,
                  step: 'ТӨЛӨВЛӨГӨӨТ',
                  amount: _mungu(widget.tolovlogoot),
                  subtitle: 'Нэхэмжилсэн · 100%',
                  actionText: 'Түүх харах ›',
                  color: _CircleDonutChart.tolovlogootColor,
                  alignLeft: true,
                  isDark: isDark,
                  onTap: () {
                    _onTapSegment(0);
                    widget.onTolovlogootTap?.call();
                  },
                ),
              ),
              SizedBox(width: 12.w),
              Expanded(
                child: _buildCalloutItem(
                  idx: 1,
                  step: 'ОРЛОГО',
                  amount: _mungu(widget.orlogo),
                  subtitle: 'Төлөгдсөн · $orlogoPStr%',
                  actionText: 'Төлөлтүүд ›',
                  color: _CircleDonutChart.orlogoColor,
                  alignLeft: false,
                  isDark: isDark,
                  onTap: () {
                    _onTapSegment(1);
                    widget.onOrlogoTap?.call();
                  },
                ),
              ),
            ],
          ),

          SizedBox(height: 6.h),

          // ── ГОЛЫН ТОМРУУЛСАН ИНФОГРАФИК ДУГУЙ (208.w x 208.w) ──
          Center(
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTapUp: (details) =>
                  _handleInfographicTap(details.localPosition, Size(chartSize, chartSize)),
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
                            colors: colors,
                            icons: icons,
                            selectedIndex: _selectedIndex,
                            progress: _curve.value,
                            isDark: isDark,
                          ),
                        );
                      },
                    ),
                    // Төвийн цагаан өргөгдсөн таваг дээрх текст
                    Padding(
                      padding: EdgeInsets.symmetric(horizontal: 52.w),
                      child: AnimatedSwitcher(
                        duration: const Duration(milliseconds: 200),
                        child: Container(
                          key: ValueKey<int>(_selectedIndex),
                          alignment: Alignment.center,
                          child: centerText,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          SizedBox(height: 6.h),

          // ── ДООД ЭГНЭЭ (Авлага зүүн талд, Зардал баруун талд) ──
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: _buildCalloutItem(
                  idx: 2,
                  step: 'АВЛАГА',
                  amount: _mungu(widget.avlaga),
                  subtitle: 'Төлөөгүй · $avlagaPStr%',
                  actionText: 'Айлууд харах ›',
                  color: _CircleDonutChart.avlagaColor,
                  alignLeft: true,
                  isDark: isDark,
                  onTap: () {
                    _onTapSegment(2);
                    widget.onAvlagaTap?.call();
                  },
                ),
              ),
              SizedBox(width: 12.w),
              Expanded(
                child: _buildCalloutItem(
                  idx: 3,
                  step: 'ЗАРДАЛ',
                  amount: _mungu(widget.zardal),
                  subtitle: 'СӨХ-ийн зардал',
                  actionText: 'Жагсаалт харах ›',
                  color: _CircleDonutChart.zardalColor,
                  alignLeft: false,
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
      ),
    );
  }
}

/// Circular Step Infographic Custom Painter
/// Алдаагүй, цэвэр төгс дугуй хэлбэр (no broken geometry) ба өнцөгт холбогч шугамтай зурагч
class _CircularStepInfographicPainter extends CustomPainter {
  _CircularStepInfographicPainter({
    required this.colors,
    required this.icons,
    required this.selectedIndex,
    required this.progress,
    required this.isDark,
  });

  final List<Color> colors;
  final List<IconData> icons;
  final int selectedIndex;
  final double progress;
  final bool isDark;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final outerR = size.width * 0.42;
    final innerR = size.width * 0.245;
    final centerDiscR = innerR - 2.w;
    const gap = 0.055; // Сегментүүд хоорондын тэгш цэвэр зай (~3.2 градус)

    // 4 квадрантын өнцгүүд ба төв өнцгүүд:
    // idx 0: Top-Left (Төлөвлөгөөт) -> mid: -3*pi/4 (-135°)
    // idx 1: Top-Right (Орлого)      -> mid: -pi/4   (-45°)
    // idx 2: Bottom-Left (Авлага)   -> mid: 3*pi/4  (135°)
    // idx 3: Bottom-Right (Зардал)  -> mid: pi/4    (45°)
    final sectorAngles = [
      {'start': -math.pi, 'mid': -3 * math.pi / 4},     // 0: Top-Left
      {'start': -math.pi / 2, 'mid': -math.pi / 4},     // 1: Top-Right
      {'start': math.pi / 2, 'mid': 3 * math.pi / 4},    // 2: Bottom-Left
      {'start': 0.0, 'mid': math.pi / 4},               // 3: Bottom-Right
    ];

    // ── 1. 4 өнгийн цагираг блок сегментүүд (Албан төгс дугуй) ──
    for (var i = 0; i < 4; i++) {
      final info = sectorAngles[i];
      final start = (info['start']! + gap / 2);
      final sweep = (math.pi / 2 - gap) * progress;
      final mid = info['mid']!;
      final color = colors[i];
      final isSel = selectedIndex == i;

      // Үндсэн дугуй хэлбэрийг эвдэхгүйгээр төв нь ЯГ голдоо байрлана
      final segPath = Path()
        ..arcTo(
          Rect.fromCircle(center: center, radius: outerR),
          start,
          sweep,
          false,
        )
        ..arcTo(
          Rect.fromCircle(center: center, radius: innerR),
          start + sweep,
          -sweep,
          false,
        )
        ..close();

      // Сонгогдсон үед гадна талын тод glow болон цагаан хүрээ
      if (isSel) {
        canvas.drawArc(
          Rect.fromCircle(center: center, radius: outerR + 2.w),
          start,
          sweep,
          false,
          Paint()
            ..color = color.withValues(alpha: 0.5)
            ..style = PaintingStyle.stroke
            ..strokeWidth = 6.w
            ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6),
        );
      }

      // Цул өнгийн сектор
      canvas.drawPath(
        segPath,
        Paint()
          ..color = color
          ..style = PaintingStyle.fill,
      );

      // Сонгогдсон сектор дээр гоёмсог тод цагаан хүрээ
      if (isSel) {
        canvas.drawPath(
          segPath,
          Paint()
            ..color = Colors.white.withValues(alpha: 0.9)
            ..style = PaintingStyle.stroke
            ..strokeWidth = 1.8.w,
        );
      }

      // ── 2. Блок доторх цул цагаан дүрс (White Icon) ──
      final icon = icons[i];
      final iconR = (outerR + innerR) / 2;
      final tp = TextPainter(
        text: TextSpan(
          text: String.fromCharCode(icon.codePoint),
          style: TextStyle(
            fontSize: 22.w,
            fontFamily: icon.fontFamily,
            package: icon.fontPackage,
            color: Colors.white,
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();

      final iconPos = Offset(
        center.dx + iconR * math.cos(mid) - tp.width / 2,
        center.dy + iconR * math.sin(mid) - tp.height / 2,
      );
      tp.paint(canvas, iconPos);

      // ── 3. Өнцөгт холбогч шугам (Angled Connector Lines) ──
      final linePaint = Paint()
        ..color = isSel ? color : color.withValues(alpha: isDark ? 0.75 : 0.55)
        ..style = PaintingStyle.stroke
        ..strokeWidth = isSel ? 1.8.w : 1.2.w
        ..strokeCap = StrokeCap.round;

      final startPt = Offset(
        center.dx + (outerR + 2.w) * math.cos(mid),
        center.dy + (outerR + 2.w) * math.sin(mid),
      );

      final signX = math.cos(mid) > 0 ? 1 : -1;
      final signY = math.sin(mid) > 0 ? 1 : -1;

      final cornerPt = Offset(
        startPt.dx + 9.w * signX,
        startPt.dy + 9.w * signY,
      );
      final endPt = Offset(
        cornerPt.dx + 10.w * signX,
        cornerPt.dy,
      );

      final linePath = Path()
        ..moveTo(startPt.dx, startPt.dy)
        ..lineTo(cornerPt.dx, cornerPt.dy)
        ..lineTo(endPt.dx, endPt.dy);

      canvas.drawPath(linePath, linePaint);

      // Төгсгөлийн цэг (Pin Dot)
      canvas.drawCircle(
        endPt,
        isSel ? 3.w : 2.2.w,
        Paint()..color = color..style = PaintingStyle.fill,
      );
    }

    // ── 4. Голын цагаан өргөгдсөн таваг (Elevated Center Disc) ──
    canvas.drawCircle(
      center,
      centerDiscR,
      Paint()
        ..color = Colors.black.withValues(alpha: isDark ? 0.35 : 0.08)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 5),
    );

    canvas.drawCircle(
      center,
      centerDiscR,
      Paint()
        ..color = isDark ? const Color(0xFF1E293B) : Colors.white
        ..style = PaintingStyle.fill,
    );

    canvas.drawCircle(
      center,
      centerDiscR,
      Paint()
        ..color = isDark ? Colors.white12 : const Color(0xFFE2E8F0)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.w,
    );
  }

  @override
  bool shouldRepaint(covariant _CircularStepInfographicPainter old) {
    return old.colors != colors ||
        old.icons != icons ||
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
