import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:sukh_app/constants/constants.dart';
import 'package:sukh_app/models/ger_buliin_gishuun_model.dart';
import 'package:sukh_app/screens/gerBul/gishuun_urikh_sheet.dart';
import 'package:sukh_app/services/ger_bul_service.dart';
import 'package:sukh_app/services/storage_service.dart';
import 'package:sukh_app/utils/theme_extensions.dart';
import 'package:sukh_app/widgets/glass_snackbar.dart';

/// Гэр бүлийн гишүүд.
///
/// Үндсэн эзэмшигч энд гишүүдээ урьж, эрхийг нь солиж, хасна.
/// Гишүүн өөрөө орж ирвэл хэний дансыг харж байгаагаа хараад, хүсвэл
/// гишүүнчлэлээсээ гарах боломжтой.
class GerBulPage extends StatefulWidget {
  const GerBulPage({super.key});

  @override
  State<GerBulPage> createState() => _GerBulPageState();
}

class _GerBulPageState extends State<GerBulPage> {
  GerBuliinJagsaalt? _jagsaalt;
  bool _isLoading = true;
  String? _aldaa;

  /// Нэвтэрсэн хүн өөрөө гишүүн үү (тийм бол урих/хасах эрхгүй)
  bool _biGishuunEsekh = false;
  String? _undsenEzemshigchNer;

  @override
  void initState() {
    super.initState();
    _achaalya();
  }

  Future<void> _achaalya({bool chimeegui = false}) async {
    if (!chimeegui) setState(() => _isLoading = true);

    try {
      final jagsaalt = await GerBulService.gishuudAvya();
      final ner = await StorageService.getUndsenEzemshigchNer();

      if (!mounted) return;
      setState(() {
        _jagsaalt = jagsaalt;
        _biGishuunEsekh = jagsaalt.gishuunEsekh;
        _undsenEzemshigchNer = ner;
        _aldaa = null;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _aldaa = e.toString().replaceAll('Exception: ', '');
        _isLoading = false;
      });
    }
  }

  Future<void> _uriya() async {
    final amjilttai = await showGishuunUrikhSheet(context);
    if (amjilttai == true && mounted) {
      await _achaalya(chimeegui: true);
    }
  }

  Future<void> _erkhSoliyo(GerBuliinGishuun gishuun) async {
    final shine = gishuun.tulukhErkhtei
        ? GishuuniiErkh.kharakh
        : GishuuniiErkh.kharakhTuluk;

    final batalgaa = await _batalgaaAvya(
      garchig: 'Эрх солих',
      utga:
          '${gishuun.buenNer}-д "$shine" эрх олгох уу?\n\n'
          '${GishuuniiErkh.tailbar(shine)}',
      tovch: 'Солих',
    );
    if (batalgaa != true) return;

    try {
      await GerBulService.erkhSoliyo(gishuuniiId: gishuun.id, erkh: shine);
      if (!mounted) return;
      showGlassSnackBar(
        context,
        message: 'Эрх шинэчлэгдлээ',
        icon: Icons.check_circle_outline,
        iconColor: Colors.green,
      );
      await _achaalya(chimeegui: true);
    } catch (e) {
      if (!mounted) return;
      showGlassSnackBar(
        context,
        message: e.toString(),
        icon: Icons.error_outline,
        iconColor: Colors.red,
      );
    }
  }

  Future<void> _gishuunKhasya(GerBuliinGishuun gishuun) async {
    final batalgaa = await _batalgaaAvya(
      garchig: 'Гишүүн хасах',
      utga:
          '${gishuun.buenNer}-г гэр бүлийн гишүүнээс хасах уу?\n\n'
          'Тэр хүн таны тоот, гэрээ, төлбөрийн мэдээллийг цаашид харахаа болино.',
      tovch: 'Хасах',
      ankhaaruulga: true,
    );
    if (batalgaa != true) return;

    try {
      await GerBulService.gishuunKhasya(gishuuniiId: gishuun.id);
      if (!mounted) return;
      showGlassSnackBar(
        context,
        message: 'Гишүүн хасагдлаа',
        icon: Icons.check_circle_outline,
        iconColor: Colors.green,
      );
      await _achaalya(chimeegui: true);
    } catch (e) {
      if (!mounted) return;
      showGlassSnackBar(
        context,
        message: e.toString(),
        icon: Icons.error_outline,
        iconColor: Colors.red,
      );
    }
  }

  Future<void> _urilgaTsutsalya(GerBuliinUrilga urilga) async {
    final batalgaa = await _batalgaaAvya(
      garchig: 'Урилга цуцлах',
      utga: '${urilga.utas} руу илгээсэн урилгыг цуцлах уу?',
      tovch: 'Цуцлах',
      ankhaaruulga: true,
    );
    if (batalgaa != true) return;

    try {
      await GerBulService.gishuunKhasya(utas: urilga.utas);
      if (!mounted) return;
      showGlassSnackBar(
        context,
        message: 'Урилга цуцлагдлаа',
        icon: Icons.check_circle_outline,
        iconColor: Colors.green,
      );
      await _achaalya(chimeegui: true);
    } catch (e) {
      if (!mounted) return;
      showGlassSnackBar(
        context,
        message: e.toString(),
        icon: Icons.error_outline,
        iconColor: Colors.red,
      );
    }
  }

  Future<void> _kodDakhinIlgeeye(GerBuliinUrilga urilga) async {
    try {
      await GerBulService.kodDakhinIlgeeye(urilga.utas);
      if (!mounted) return;
      showGlassSnackBar(
        context,
        message: '${urilga.utas} руу код дахин илгээлээ',
        icon: Icons.sms_outlined,
        iconColor: Colors.green,
      );
    } catch (e) {
      if (!mounted) return;
      showGlassSnackBar(
        context,
        message: e.toString(),
        icon: Icons.error_outline,
        iconColor: Colors.red,
      );
    }
  }

  Future<void> _gishuunchleleesGarya() async {
    final batalgaa = await _batalgaaAvya(
      garchig: 'Гишүүнчлэлээс гарах',
      utga:
          'Та гэр бүлийн гишүүнчлэлээсээ гарах уу?\n\n'
          'Гарсны дараа энэ дансны мэдээллийг харах боломжгүй болж, '
          'системээс автоматаар гарна.',
      tovch: 'Гарах',
      ankhaaruulga: true,
    );
    if (batalgaa != true) return;

    try {
      await GerBulService.gishuunchleleesGarya();
      if (!mounted) return;
      context.go('/newtrekh');
    } catch (e) {
      if (!mounted) return;
      showGlassSnackBar(
        context,
        message: e.toString(),
        icon: Icons.error_outline,
        iconColor: Colors.red,
      );
    }
  }

  Future<bool?> _batalgaaAvya({
    required String garchig,
    required String utga,
    required String tovch,
    bool ankhaaruulga = false,
  }) {
    final isDark = context.isDarkMode;
    return showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: isDark ? const Color(0xFF1E1E1E) : Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20.r),
        ),
        title: Text(
          garchig,
          style: TextStyle(
            fontSize: 17.sp,
            fontWeight: FontWeight.w800,
            color: context.textPrimaryColor,
          ),
        ),
        content: Text(
          utga,
          style: TextStyle(
            fontSize: 14.sp,
            height: 1.5,
            color: context.textSecondaryColor,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(
              'Болих',
              style: TextStyle(
                color: context.textSecondaryColor,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(
              tovch,
              style: TextStyle(
                color: ankhaaruulga ? Colors.redAccent : AppColors.deepGreen,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.surfaceColor,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildHeader(),
          Expanded(
            child: _isLoading
                ? const Center(
                    child: CircularProgressIndicator(
                      color: AppColors.deepGreen,
                    ),
                  )
                : RefreshIndicator(
                    color: AppColors.deepGreen,
                    onRefresh: () => _achaalya(chimeegui: true),
                    child: SingleChildScrollView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      padding: EdgeInsets.fromLTRB(16.w, 8.h, 16.w, 40.h),
                      child: _buildBody(),
                    ),
                  ),
          ),
        ],
      ),
      floatingActionButton: (!_isLoading && !_biGishuunEsekh)
          ? FloatingActionButton.extended(
              onPressed: (_jagsaalt?.nemekhBolomjtoi ?? false) ? _uriya : null,
              backgroundColor: (_jagsaalt?.nemekhBolomjtoi ?? false)
                  ? AppColors.deepGreen
                  : context.inputGrayColor,
              icon: const Icon(Icons.person_add_alt_1, color: Colors.white),
              label: Text(
                'Гишүүн урих',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                  fontSize: 14.sp,
                ),
              ),
            )
          : null,
    );
  }

  Widget _buildHeader() {
    final isDark = context.isDarkMode;
    return SafeArea(
      bottom: false,
      child: Padding(
        padding: EdgeInsets.fromLTRB(16.w, 16.h, 16.w, 8.h),
        child: Row(
          children: [
            GestureDetector(
              onTap: () => Navigator.pop(context),
              child: Container(
                padding: EdgeInsets.all(8.w),
                decoration: BoxDecoration(
                  color: AppColors.deepGreen,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.deepGreen.withOpacity(0.3),
                      blurRadius: 6,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: Icon(
                  Icons.arrow_back_rounded,
                  color: Colors.white,
                  size: 20.sp,
                ),
              ),
            ),
            SizedBox(width: 16.w),
            Text(
              'Гэр бүлийн гишүүн',
              style: TextStyle(
                fontSize: 16.sp,
                fontWeight: FontWeight.w800,
                color: isDark ? Colors.white : context.textPrimaryColor,
                letterSpacing: -0.3,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBody() {
    if (_aldaa != null) return _buildAldaa();

    final jagsaalt = _jagsaalt;
    if (jagsaalt == null) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (_biGishuunEsekh) _buildGishuuniiKart() else _buildTailbarKart(),
        SizedBox(height: 20.h),

        if (jagsaalt.khooson && !_biGishuunEsekh)
          _buildKhooson()
        else ...[
          if (jagsaalt.gishuud.isNotEmpty) ...[
            _buildKheseg('Гишүүд', Icons.people_alt_outlined),
            ...jagsaalt.gishuud.map(_buildGishuunMur),
            SizedBox(height: 20.h),
          ],
          if (jagsaalt.urilguud.isNotEmpty) ...[
            _buildKheseg('Хүлээгдэж буй урилга', Icons.schedule_outlined),
            ...jagsaalt.urilguud.map(_buildUrilgaMur),
          ],
        ],

        if (_biGishuunEsekh) ...[
          SizedBox(height: 24.h),
          _buildGarakhTovch(),
        ],

        SizedBox(height: 80.h),
      ],
    );
  }

  Widget _buildAldaa() {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 60.h),
      child: Column(
        children: [
          Icon(
            Icons.cloud_off_rounded,
            size: 48.sp,
            color: context.textSecondaryColor,
          ),
          SizedBox(height: 16.h),
          Text(
            _aldaa!,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 14.sp,
              color: context.textSecondaryColor,
              height: 1.5,
            ),
          ),
          SizedBox(height: 20.h),
          TextButton.icon(
            onPressed: _achaalya,
            icon: const Icon(Icons.refresh, color: AppColors.deepGreen),
            label: const Text(
              'Дахин оролдох',
              style: TextStyle(
                color: AppColors.deepGreen,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Үндсэн эзэмшигчид зориулсан танилцуулга
  Widget _buildTailbarKart() {
    final khyazgaar = _jagsaalt?.khyazgaar ?? 5;
    final ashiglasan =
        (_jagsaalt?.gishuud.length ?? 0) + (_jagsaalt?.urilguud.length ?? 0);

    return Container(
      padding: EdgeInsets.all(18.w),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppColors.deepGreen, AppColors.deepGreenDark],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20.r),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.family_restroom_rounded, color: Colors.white, size: 22.sp),
              SizedBox(width: 10.w),
              Expanded(
                child: Text(
                  'Гэр бүлийнхээ гишүүдийг нэмээрэй',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 15.sp,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 10.h),
          Text(
            'Нэмсэн гишүүн өөрийн утас, нууц кодоороо нэвтэрч, таны тоот, '
            'гэрээ, нэхэмжлэх, төлбөрийн мэдээллийг ижилхэн харна.',
            style: TextStyle(
              color: Colors.white.withOpacity(0.85),
              fontSize: 12.5.sp,
              height: 1.5,
            ),
          ),
          SizedBox(height: 14.h),
          Container(
            padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 6.h),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.15),
              borderRadius: BorderRadius.circular(20.r),
            ),
            child: Text(
              '$ashiglasan / $khyazgaar гишүүн',
              style: TextStyle(
                color: Colors.white,
                fontSize: 11.5.sp,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Гишүүн өөрөө орж ирсэн үеийн танилцуулга
  Widget _buildGishuuniiKart() {
    return Container(
      padding: EdgeInsets.all(18.w),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppColors.deepGreen, AppColors.deepGreenDark],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20.r),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.verified_user_outlined, color: Colors.white, size: 22.sp),
              SizedBox(width: 10.w),
              Expanded(
                child: Text(
                  'Та гэр бүлийн гишүүн байна',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 15.sp,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 10.h),
          Text(
            _undsenEzemshigchNer != null && _undsenEzemshigchNer!.isNotEmpty
                ? '$_undsenEzemshigchNer-ийн байрны мэдээллийг харж байна.'
                : 'Үндсэн эзэмшигчийн байрны мэдээллийг харж байна.',
            style: TextStyle(
              color: Colors.white.withOpacity(0.85),
              fontSize: 12.5.sp,
              height: 1.5,
            ),
          ),
          SizedBox(height: 14.h),
          FutureBuilder<String>(
            future: StorageService.getGishuuniiErkh(),
            builder: (context, snapshot) {
              final khadgalsan = snapshot.data ?? GishuuniiErkh.kharakhTuluk;
              return Container(
                padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 6.h),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(20.r),
                ),
                child: Text(
                  'Эрх: $khadgalsan',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 11.5.sp,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildKheseg(String garchig, IconData icon) {
    return Padding(
      padding: EdgeInsets.only(left: 4.w, bottom: 10.h),
      child: Row(
        children: [
          Icon(icon, size: 16.sp, color: AppColors.deepGreen),
          SizedBox(width: 8.w),
          Text(
            garchig.toUpperCase(),
            style: TextStyle(
              fontSize: 11.sp,
              fontWeight: FontWeight.w800,
              color: AppColors.deepGreen,
              letterSpacing: 1.0,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildKart({required Widget child}) {
    final isDark = context.isDarkMode;
    return Container(
      margin: EdgeInsets.only(bottom: 10.h),
      padding: EdgeInsets.all(14.w),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(
          color: isDark
              ? Colors.white.withOpacity(0.05)
              : AppColors.deepGreen.withOpacity(0.08),
          width: 1,
        ),
      ),
      child: child,
    );
  }

  Widget _buildGishuunMur(GerBuliinGishuun gishuun) {
    return _buildKart(
      child: Row(
        children: [
          _buildAvatar(gishuun.uge, AppColors.deepGreen),
          SizedBox(width: 12.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  gishuun.buenNer,
                  style: TextStyle(
                    fontSize: 14.5.sp,
                    fontWeight: FontWeight.w700,
                    color: context.textPrimaryColor,
                  ),
                ),
                SizedBox(height: 3.h),
                Text(
                  '${gishuun.kholboo} · ${gishuun.utas}',
                  style: TextStyle(
                    fontSize: 12.sp,
                    color: context.textSecondaryColor,
                  ),
                ),
                SizedBox(height: 6.h),
                _buildErkhShoshgo(gishuun.erkh),
              ],
            ),
          ),
          if (!_biGishuunEsekh)
            PopupMenuButton<String>(
              icon: Icon(
                Icons.more_vert_rounded,
                color: context.textSecondaryColor,
                size: 20.sp,
              ),
              onSelected: (utga) {
                if (utga == 'erkh') _erkhSoliyo(gishuun);
                if (utga == 'khasakh') _gishuunKhasya(gishuun);
              },
              itemBuilder: (ctx) => [
                PopupMenuItem(
                  value: 'erkh',
                  child: Text(
                    gishuun.tulukhErkhtei
                        ? 'Зөвхөн харах болгох'
                        : 'Төлөх эрх нэмэх',
                  ),
                ),
                const PopupMenuItem(
                  value: 'khasakh',
                  child: Text(
                    'Гишүүнээс хасах',
                    style: TextStyle(color: Colors.redAccent),
                  ),
                ),
              ],
            ),
        ],
      ),
    );
  }

  Widget _buildUrilgaMur(GerBuliinUrilga urilga) {
    return _buildKart(
      child: Row(
        children: [
          _buildAvatar(
            urilga.utas.isNotEmpty ? urilga.utas[0] : '?',
            AppColors.warning,
          ),
          SizedBox(width: 12.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  urilga.buenNer,
                  style: TextStyle(
                    fontSize: 14.5.sp,
                    fontWeight: FontWeight.w700,
                    color: context.textPrimaryColor,
                  ),
                ),
                SizedBox(height: 3.h),
                Text(
                  '${urilga.kholboo} · ${urilga.utas}',
                  style: TextStyle(
                    fontSize: 12.sp,
                    color: context.textSecondaryColor,
                  ),
                ),
                SizedBox(height: 6.h),
                Row(
                  children: [
                    Icon(
                      Icons.hourglass_bottom_rounded,
                      size: 12.sp,
                      color: AppColors.warning,
                    ),
                    SizedBox(width: 4.w),
                    Text(
                      'Код хүлээгдэж байна · ${urilga.uldsenKhugatsaa}',
                      style: TextStyle(
                        fontSize: 11.sp,
                        color: AppColors.warning,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          if (!_biGishuunEsekh)
            PopupMenuButton<String>(
              icon: Icon(
                Icons.more_vert_rounded,
                color: context.textSecondaryColor,
                size: 20.sp,
              ),
              onSelected: (utga) {
                if (utga == 'dakhin') _kodDakhinIlgeeye(urilga);
                if (utga == 'tsutsal') _urilgaTsutsalya(urilga);
              },
              itemBuilder: (ctx) => [
                const PopupMenuItem(
                  value: 'dakhin',
                  child: Text('Код дахин илгээх'),
                ),
                const PopupMenuItem(
                  value: 'tsutsal',
                  child: Text(
                    'Урилга цуцлах',
                    style: TextStyle(color: Colors.redAccent),
                  ),
                ),
              ],
            ),
        ],
      ),
    );
  }

  Widget _buildAvatar(String uge, Color ungu) {
    return Container(
      width: 42.w,
      height: 42.w,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: ungu.withOpacity(0.12),
        shape: BoxShape.circle,
        border: Border.all(color: ungu.withOpacity(0.25), width: 1),
      ),
      child: Text(
        uge,
        style: TextStyle(
          color: ungu,
          fontSize: 15.sp,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }

  Widget _buildErkhShoshgo(String erkh) {
    final tulukhErkhtei = erkh != GishuuniiErkh.kharakh;
    final ungu = tulukhErkhtei ? AppColors.deepGreen : context.inputGrayColor;

    return Container(
      padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 3.h),
      decoration: BoxDecoration(
        color: ungu.withOpacity(0.1),
        borderRadius: BorderRadius.circular(6.r),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            tulukhErkhtei
                ? Icons.credit_card_rounded
                : Icons.visibility_outlined,
            size: 11.sp,
            color: ungu,
          ),
          SizedBox(width: 4.w),
          Text(
            erkh,
            style: TextStyle(
              fontSize: 10.5.sp,
              fontWeight: FontWeight.w700,
              color: ungu,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildKhooson() {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 40.h),
      child: Column(
        children: [
          Container(
            width: 84.w,
            height: 84.w,
            decoration: BoxDecoration(
              color: AppColors.deepGreen.withOpacity(0.08),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.family_restroom_rounded,
              size: 40.sp,
              color: AppColors.deepGreen,
            ),
          ),
          SizedBox(height: 20.h),
          Text(
            'Одоогоор гишүүн алга',
            style: TextStyle(
              fontSize: 16.sp,
              fontWeight: FontWeight.w800,
              color: context.textPrimaryColor,
            ),
          ),
          SizedBox(height: 8.h),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 30.w),
            child: Text(
              'Гэр бүлийнхээ гишүүнийг утасны дугаараар нь урьвал, '
              'тэр хүн SMS-ээр ирэх кодоор баталгаажуулж нэвтэрнэ.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 13.sp,
                height: 1.6,
                color: context.textSecondaryColor,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGarakhTovch() {
    return SizedBox(
      width: double.infinity,
      child: TextButton.icon(
        onPressed: _gishuunchleleesGarya,
        style: TextButton.styleFrom(
          padding: EdgeInsets.symmetric(vertical: 14.h),
          backgroundColor: Colors.redAccent.withOpacity(0.08),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14.r),
          ),
        ),
        icon: const Icon(Icons.logout_rounded, color: Colors.redAccent),
        label: Text(
          'Гишүүнчлэлээс гарах',
          style: TextStyle(
            color: Colors.redAccent,
            fontWeight: FontWeight.w700,
            fontSize: 14.sp,
          ),
        ),
      ),
    );
  }
}
