import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:intl/intl.dart' show NumberFormat;
import 'package:sukh_app/constants/constants.dart';
import 'package:sukh_app/services/api_service.dart';
import 'package:sukh_app/utils/theme_extensions.dart';
import 'package:sukh_app/widgets/skeleton_box.dart';
import 'package:sukh_app/components/shilenDans/shilen_dans_charts.dart';
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

  void _showKhurimtlalModal(
    BuildContext context,
    double orlogo,
    double zardal,
    double khurimtlal,
  ) {
    final isDark = context.isDarkMode;
    final isNegative = khurimtlal < 0;
    final accent = isNegative ? Colors.redAccent : _Ungu.nogoon;
    final message = isNegative
        ? 'Энэ сарын зардлын хэмжээ орлогын хэмжээнээс их байгаа учир хасахтай харагдаж байна.'
        : 'Энэ сарын орлого нь зардлаас их буюу тэнцүү байгаа тул хуримтлал эерэг харагдаж байна.';

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        decoration: BoxDecoration(
          color: context.surfaceColor,
          borderRadius: BorderRadius.vertical(top: Radius.circular(22.r)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.22),
              blurRadius: 20,
              offset: const Offset(0, -4),
            ),
          ],
        ),
        child: SafeArea(
          top: false,
          child: Padding(
            padding: EdgeInsets.fromLTRB(20.w, 10.h, 20.w, 22.h),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
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
                SizedBox(height: 14.h),
                Row(
                  children: [
                    Container(
                      width: 36.w,
                      height: 36.w,
                      decoration: BoxDecoration(
                        color: accent.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(10.r),
                      ),
                      child: Icon(
                        isNegative
                            ? Icons.info_outline_rounded
                            : Icons.savings_outlined,
                        color: accent,
                        size: 20.w,
                      ),
                    ),
                    SizedBox(width: 10.w),
                    Expanded(
                      child: Text(
                        'Энэ сарын хуримтлал',
                        style: TextStyle(
                          fontSize: 16.sp,
                          fontWeight: FontWeight.w700,
                          color: context.textPrimaryColor,
                        ),
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.of(ctx).pop(),
                      icon: Icon(
                        Icons.close_rounded,
                        size: 22.sp,
                        color: context.textSecondaryColor,
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 10.h),
                Container(
                  padding: EdgeInsets.all(14.w),
                  decoration: BoxDecoration(
                    color: accent.withValues(alpha: isDark ? 0.14 : 0.08),
                    borderRadius: BorderRadius.circular(12.r),
                    border: Border.all(color: accent.withValues(alpha: 0.3)),
                  ),
                  child: Text(
                    message,
                    style: TextStyle(
                      fontSize: 13.5.sp,
                      height: 1.45,
                      fontWeight: FontWeight.w500,
                      color: context.textPrimaryColor,
                    ),
                  ),
                ),
                SizedBox(height: 12.h),
                Container(
                  padding: EdgeInsets.all(12.w),
                  decoration: BoxDecoration(
                    color: isDark ? AppColors.darkBackground : const Color(0xFFF9FAFB),
                    borderRadius: BorderRadius.circular(12.r),
                    border: Border.all(color: context.borderColor),
                  ),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('Энэ сарын орлого',
                              style: TextStyle(fontSize: 12.5.sp, color: context.textSecondaryColor)),
                          Text(_mungu(orlogo),
                              style: TextStyle(
                                fontSize: 13.sp,
                                fontWeight: FontWeight.w600,
                                color: _Ungu.nogoon,
                              )),
                        ],
                      ),
                      SizedBox(height: 6.h),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('Энэ сарын зардал',
                              style: TextStyle(fontSize: 12.5.sp, color: context.textSecondaryColor)),
                          Text(_mungu(zardal),
                              style: TextStyle(
                                fontSize: 13.sp,
                                fontWeight: FontWeight.w600,
                                color: Colors.redAccent,
                              )),
                        ],
                      ),
                      Divider(height: 16.h, color: context.borderColor),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('Хуримтлал (Орлого − Зардал)',
                              style: TextStyle(
                                fontSize: 12.5.sp,
                                fontWeight: FontWeight.w600,
                                color: context.textPrimaryColor,
                              )),
                          Text(
                            '${khurimtlal < 0 ? '−' : ''}${_mungu(khurimtlal.abs())}',
                            style: TextStyle(
                              fontSize: 14.sp,
                              fontWeight: FontWeight.w800,
                              color: accent,
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
      ),
    );
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
        sar: _sar,
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
      return ListView(
        padding: EdgeInsets.fromLTRB(16.w, 12.h, 16.w, 24.h),
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              SkeletonBox(width: 140.w, height: 18.h, borderRadius: 8.r),
              SkeletonBox(width: 100.w, height: 32.h, borderRadius: 8.r),
            ],
          ),
          SizedBox(height: 14.h),
          SkeletonBox(height: 92.h, borderRadius: 14.r),
          SizedBox(height: 12.h),
          Row(
            children: [
              Expanded(child: SkeletonBox(height: 54.h, borderRadius: 12.r)),
              SizedBox(width: 12.w),
              Expanded(child: SkeletonBox(height: 54.h, borderRadius: 12.r)),
            ],
          ),
          SizedBox(height: 22.h),
          SkeletonBox(height: 290.h, borderRadius: 14.r),
          SizedBox(height: 18.h),
          SkeletonBox(height: 210.h, borderRadius: 14.r),
        ],
      );
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
      GestureDetector(
        onTap: () => _showKhurimtlalModal(context, orlogo, zardal, khurimtlal),
        behavior: HitTestBehavior.opaque,
        child: _Kart(
          ungu: _Ungu.nogoon.withValues(alpha: isDark ? 0.18 : 0.08),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Энэ сарын хуримтлал',
                      style: TextStyle(fontSize: 13.sp, color: context.textSecondaryColor)),
                  Icon(
                    Icons.info_outline_rounded,
                    size: 16.sp,
                    color: khurimtlal < 0 ? Colors.redAccent : context.textSecondaryColor,
                  ),
                ],
              ),
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
        child: CircleDonutChart(
          tolovlogoot: nekhemjilsen,
          orlogo: orlogo,
          avlaga: avlaga,
          zardal: zardal,
          avlagaAilToo: (ail['tuluuguiAilToo'] as num?)?.toInt() ?? 0,
          onTolovlogootTap: () => _showTolovlogootModal(context, d),
          onOrlogoTap: () => _showOrlogoModal(context, d, orlogo),
          onAvlagaTap: () => _showAvlagaModal(context, d),
          onZardalTap: () => _showZardalModal(context, d, zardal),
        ),
      ),
      SizedBox(height: 16.h),
      Text('Орлого, зардал (өдрийн хандлага)',
          style: TextStyle(
              fontSize: 15.sp, fontWeight: FontWeight.w600, color: context.textPrimaryColor)),
      SizedBox(height: 8.h),
      _Kart(
        child: InteractiveUrsgalGraph(
          sar: _sar,
          orloguud: (d['orloguud'] as List? ?? [])
              .map((e) => Map<String, dynamic>.from(e as Map))
              .toList(),
          zarlaguud: (d['zarlaguud'] as List? ?? [])
              .map((e) => Map<String, dynamic>.from(e as Map))
              .toList(),
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
        dedNer: ((ail['tuluuguiAilToo'] as num?)?.toInt() ?? 0) > 0
            ? '${ail['tuluuguiAilToo']} айл · Жагсаалт харах ›'
            : null,
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
                      color: CircleDonutChart.avlagaColor.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(10.r),
                    ),
                    child: Icon(
                      Icons.pending_actions_rounded,
                      color: CircleDonutChart.avlagaColor,
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
                                color: CircleDonutChart.avlagaColor,
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
                          enabledBorder: InputBorder.none,
                          focusedBorder: InputBorder.none,
                          filled: false,
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
                                : CircleDonutChart.orlogoColor.withValues(alpha: 0.12))
                            : (isDark ? AppColors.darkBackground : const Color(0xFFF3F4F6)),
                        borderRadius: BorderRadius.circular(10.r),
                        border: Border.all(
                          color: _filterIndex != 0
                              ? (_filterIndex == 1 ? const Color(0xFFEF4444) : CircleDonutChart.orlogoColor)
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
                                    ? CircleDonutChart.orlogoColor
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
                                      ? CircleDonutChart.orlogoColor
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
                                  color: (isOverdue ? const Color(0xFFEF4444) : CircleDonutChart.avlagaColor).withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(10.r),
                                ),
                                alignment: Alignment.center,
                                child: Text(
                                  toot,
                                  style: TextStyle(
                                    fontSize: 12.sp,
                                    fontWeight: FontWeight.w800,
                                    color: isOverdue ? const Color(0xFFEF4444) : CircleDonutChart.avlagaColor,
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
    required this.sar,
    required this.sarNer,
    required this.sarOrlogo,
    required this.orloguud,
  });

  final String sar;
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

    final monthFiltered = widget.orloguud.where((item) {
      final ognoo = '${item['ognoo'] ?? item['createdAt'] ?? ''}'.trim();
      if (ognoo.isEmpty || ognoo == 'null') return false;
      return ognoo.startsWith(widget.sar);
    }).toList();

    final filtered = monthFiltered.where((item) {
      if (q.isEmpty) return true;
      final toot = '${item['toot'] ?? ''}'.toLowerCase();
      final tailbar = '${item['tailbar'] ?? ''}'.toLowerCase();
      final zardal = '${item['zardliinNer'] ?? ''}'.toLowerCase();
      final nemelt = '${item['nemeltTailbar'] ?? ''}'.toLowerCase();
      final turul = '${item['turul'] ?? ''}'.toLowerCase();
      final source = '${item['source'] ?? item['tulburiinKhelber'] ?? ''}'.toLowerCase();
      final ajiltan = '${item['ajiltniiNer'] ?? item['guilgeeKhiisenAjiltniiNer'] ?? ''}'.toLowerCase();
      final ognoo = '${item['ognoo'] ?? ''}'.toLowerCase();
      return toot.contains(q) ||
          tailbar.contains(q) ||
          zardal.contains(q) ||
          nemelt.contains(q) ||
          turul.contains(q) ||
          source.contains(q) ||
          ajiltan.contains(q) ||
          ognoo.contains(q);
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
                      color: CircleDonutChart.orlogoColor.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(10.r),
                    ),
                    child: Icon(
                      Icons.account_balance_wallet_rounded,
                      color: CircleDonutChart.orlogoColor,
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
                                color: CircleDonutChart.orlogoColor,
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
                            '${monthFiltered.length} гүйлгээ',
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
                    hintText: 'Тоот, огноогоор хайх...',
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
                    enabledBorder: InputBorder.none,
                    focusedBorder: InputBorder.none,
                    filled: false,
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
                        final rawToot = '${item['toot'] ?? ''}'.trim();
                        final toot = (rawToot == '—' || rawToot == '-' || rawToot == 'null')
                            ? ''
                            : rawToot;
                        final dun = _toDouble(item['dun']);
                        final rawOgnoo = '${item['ognoo'] ?? item['createdAt'] ?? ''}'.trim();
                        final ognoo = rawOgnoo.split('T').first;
                        final tailbarCandidates = [
                          '${item['tailbar'] ?? ''}'.trim(),
                          '${item['zardliinNer'] ?? ''}'.trim(),
                          '${item['nemeltTailbar'] ?? ''}'.trim(),
                        ].where((s) => s.isNotEmpty && s != 'null' && s != '—').toList();
                        final tailbar = tailbarCandidates.isNotEmpty
                            ? tailbarCandidates.first
                            : '';
                        final turul = '${item['turul'] ?? ''}'.trim();
                        final ajiltan = '${item['ajiltniiNer'] ?? item['guilgeeKhiisenAjiltniiNer'] ?? ''}'.trim();
                        final rawSource = '${item['tulburiinKhelber'] ?? item['khelber'] ?? item['source'] ?? ''}'.trim();

                        String resolveChannel() {
                          if (ajiltan.isNotEmpty && ajiltan != '—' && ajiltan != 'null') {
                            return ajiltan;
                          }
                          final s = rawSource.toLowerCase();
                          final txt = '$tailbar $turul'.toLowerCase();
                          if (s == 'qpay' || txt.contains('qpay')) return 'QPay';
                          if (s == 'bank' || txt.contains('банк') || txt.contains('данс')) {
                            return 'Банк';
                          }
                          if (s == 'gar') return 'Гараар';
                          if (s == 'system' || s == 'excel_import') return 'Систем';
                          if (rawSource.isNotEmpty && rawSource != 'null') return rawSource;
                          return '';
                        }

                        final channel = resolveChannel();
                        final metaParts = [
                          if (ognoo.isNotEmpty && ognoo != 'null') ognoo,
                        ];

                        return Padding(
                          padding: EdgeInsets.symmetric(vertical: 5.h),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              Container(
                                width: 38.w,
                                height: 38.w,
                                decoration: BoxDecoration(
                                  color: CircleDonutChart.orlogoColor.withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(10.r),
                                ),
                                alignment: Alignment.center,
                                child: toot.isNotEmpty
                                    ? Text(
                                        toot,
                                        style: TextStyle(
                                          fontSize: 12.sp,
                                          fontWeight: FontWeight.w800,
                                          color: CircleDonutChart.orlogoColor,
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      )
                                    : Icon(
                                        Icons.payments_outlined,
                                        size: 18.w,
                                        color: CircleDonutChart.orlogoColor,
                                      ),
                              ),
                              SizedBox(width: 12.w),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Flexible(
                                          child: Text(
                                            toot.isNotEmpty ? '$toot тоот' : 'Төлбөр төлөлт',
                                            style: TextStyle(
                                              fontSize: 14.sp,
                                              fontWeight: FontWeight.w600,
                                              color: context.textPrimaryColor,
                                            ),
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                        if (channel.isNotEmpty) ...[
                                          SizedBox(width: 6.w),
                                          Container(
                                            padding: EdgeInsets.symmetric(
                                              horizontal: 6.w,
                                              vertical: 1.5.h,
                                            ),
                                            decoration: BoxDecoration(
                                              color: CircleDonutChart.orlogoColor
                                                  .withValues(alpha: isDark ? 0.18 : 0.10),
                                              borderRadius: BorderRadius.circular(5.r),
                                            ),
                                            child: Text(
                                              channel,
                                              style: TextStyle(
                                                fontSize: 9.5.sp,
                                                fontWeight: FontWeight.w600,
                                                color: CircleDonutChart.orlogoColor,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ],
                                    ),
                                    if (metaParts.isNotEmpty) ...[
                                      SizedBox(height: 2.h),
                                      Text(
                                        metaParts.join(' · '),
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
                                '+${_mungu(dun)}',
                                style: TextStyle(
                                  fontSize: 14.sp,
                                  fontWeight: FontWeight.w700,
                                  color: CircleDonutChart.orlogoColor,
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
  late List<Map<String, dynamic>> _activeSaraar;

  @override
  void initState() {
    super.initState();
    // Эхэлсэн хамгийн эхний идэвхтэй сараас өмнөх хоосон саруудыг хасна
    final sorted = List<Map<String, dynamic>>.from(widget.saraar)
      ..sort((a, b) => '${a['sar'] ?? ''}'.compareTo('${b['sar'] ?? ''}'));
    final firstActiveIdx = sorted.indexWhere((s) =>
        _toDouble(s['nekhemjilsen']) > 0 ||
        _toDouble(s['tulsun']) > 0 ||
        _toDouble(s['zardal']) > 0);
    final trimmed = firstActiveIdx >= 0
        ? sorted.sublist(firstActiveIdx)
        : (sorted.isNotEmpty ? [sorted.last] : <Map<String, dynamic>>[]);
    _activeSaraar = trimmed.reversed.toList();

    final ySet = <int>{};
    for (final s in _activeSaraar) {
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

    final filtered = _activeSaraar.where((s) {
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
                      color: CircleDonutChart.tolovlogootColor.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(10.r),
                    ),
                    child: Icon(
                      Icons.fact_check_rounded,
                      color: CircleDonutChart.tolovlogootColor,
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
                                ? CircleDonutChart.tolovlogootColor
                                : (isDark ? AppColors.darkBackground : const Color(0xFFF3F4F6)),
                            borderRadius: BorderRadius.circular(20.r),
                            border: Border.all(
                              color: isSel ? CircleDonutChart.tolovlogootColor : context.borderColor,
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
                                color: CircleDonutChart.tolovlogootColor,
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
                              color: CircleDonutChart.orlogoColor,
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
                                      color: CircleDonutChart.tolovlogootColor.withValues(alpha: 0.12),
                                      borderRadius: BorderRadius.circular(6.r),
                                    ),
                                    child: Text(
                                      '$sarDugaar сар',
                                      style: TextStyle(
                                        fontSize: 12.sp,
                                        fontWeight: FontWeight.w700,
                                        color: CircleDonutChart.tolovlogootColor,
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
                                      color: CircleDonutChart.orlogoColor,
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
                                      color: CircleDonutChart.orlogoColor,
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

/// Санхүүгийн бүтэц — Пропорциональ цагираг график ба 2×2 үзүүлэлтийн карт.
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
