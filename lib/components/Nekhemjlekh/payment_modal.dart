import 'package:flutter/material.dart';
import 'package:sukh_app/utils/format_util.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:sukh_app/constants/constants.dart';
import 'package:sukh_app/utils/theme_extensions.dart';
import 'package:sukh_app/services/api_service.dart';
import 'package:sukh_app/services/storage_service.dart';
import 'package:sukh_app/widgets/glass_snackbar.dart';
import 'package:sukh_app/components/Nekhemjlekh/qpay_qr_modal.dart';
import 'package:sukh_app/components/Nekhemjlekh/nekhemjlekh_models.dart';
import 'package:sukh_app/components/Nekhemjlekh/bank_selection_modal.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:sukh_app/utils/error_message.dart';

class PaymentModal extends StatefulWidget {
  final String totalSelectedAmount;
  final int selectedCount;
  final Future<void> Function() onPaymentTap;
  final List<NekhemjlekhItem> invoices;
  /// When all unpaid are selected, use this (globalUldegdel) for payment amount
  final double? contractUldegdel;

  /// Нэг гэрээ сонгосон бол — СӨХ / гараж / агуулахаар ялгаж төлөх боломж
  final String? gereeniiId;
  final String? baiguullagiinId;

  const PaymentModal({
    super.key,
    required this.totalSelectedAmount,
    required this.selectedCount,
    required this.onPaymentTap,
    required this.invoices,
    this.contractUldegdel,
    this.gereeniiId,
    this.baiguullagiinId,
  });

  @override
  State<PaymentModal> createState() => _PaymentModalState();
}

class _PaymentModalState extends State<PaymentModal> {
  bool _isLoadingQPay = false;
  String? _qrImageOwnOrg;
  String? _qrImageWallet;
  List<QPayBank> _qpayBanks = [];
  List<String> _selectedInvoiceIdsForCheck = [];
  String? _gereeniiDugaarForCheck;
  String? _senderInvoiceNoForSocket;
  String _vatReceiveType = 'CITIZEN';
  final TextEditingController _vatTinController = TextEditingController();

  /// Ангиллын үлдэгдэл (Орон сууц / Зогсоол / Агуулах) — вэбийн TransactionModal-тай ижил
  Map<String, double> _angilalUldegdel = {};
  /// null = бүгдийг төлөх
  String? _songosonAngilal;

  @override
  void initState() {
    super.initState();
    _angilalAchaalya();
  }

  /// Нэхэмжлэх бүрийн мөрүүд (сервэрийн дэвтрээс): id → [(нэр, дүн)]
  Map<String, List<MapEntry<String, double>>> _nekhemjlekhiinMurnuud = {};

  /// Ангиллын дүнг ЗӨВХӨН сонгосон нэхэмжлэхүүдээс авна — гэрээний нийт
  /// дэвтрийн үлдэгдлээс биш. Ингэснээр «Сонгосон 140,000» = «СӨХ 135,000 +
  /// Гараж 5,000» гэж нийлбэр нь таарна.
  Future<void> _angilalAchaalya() async {
    final gid = widget.gereeniiId;
    final bid = widget.baiguullagiinId;
    final idnuud = _songosonNekhemjlekhuud.map((i) => i.id).toList();
    if (gid == null || gid.isEmpty || bid == null || bid.isEmpty || idnuud.isEmpty) {
      return;
    }
    final data = await ApiService.fetchNekhemjlekhZadargaa(
          baiguullagiinId: bid,
          gereeniiId: gid,
          nekhemjlekhIdnuud: idnuud,
        ) ??
        // Сервер шинэчлэгдээгүй (endpoint байхгүй) бол дэвтрээс апп дээр бодно
        await _zadargaaDevtreesBodyo(bid, gid);
    if (data == null || !mounted) return;
    double too(dynamic v) => v is num ? v.toDouble() : double.tryParse('$v') ?? 0;
    final angilal = data['angilal'];
    final murnuud = <String, List<MapEntry<String, double>>>{};
    for (final n in (data['nekhemjlekhuud'] as List? ?? const [])) {
      if (n is! Map) continue;
      murnuud['${n['_id']}'] = [
        for (final z in (n['zardluud'] as List? ?? const []))
          if (z is Map) MapEntry('${z['ner']}', too(z['dun'])),
      ];
    }
    setState(() {
      _nekhemjlekhiinMurnuud = murnuud;
      if (angilal is Map) {
        _angilalUldegdel = {
          for (final k in ['Орон сууц', 'Зогсоол', 'Агуулах']) k: too(angilal[k]),
        };
      }
    });
  }

  static String _angilalTaniya(String ner) {
    final n = ner.toLowerCase();
    if (n.contains('гараж') || n.contains('гараш') || n.contains('зогсоол')) {
      return 'Зогсоол';
    }
    if (n.contains('агуулах')) return 'Агуулах';
    return 'Орон сууц';
  }

  /// `/nekhemjlekhZadargaa`-тай ижил томьёо: нэхэмжлэхэд холбогдсон дэвтрийн
  /// мөрүүдийг (dun > 0) нэрээр нь нэгтгэж, нэхэмжлэхийн үлдэгдлийг ангиллын
  /// жингээр хуваарилна.
  Future<Map<String, dynamic>?> _zadargaaDevtreesBodyo(String bid, String gid) async {
    final res = await ApiService.fetchGuilgeeAvlaguud(
      gereeniiId: gid,
      baiguullagiinId: bid,
    );
    final murnuud = (res['jagsaalt'] as List? ?? const []).whereType<Map>().toList();
    if (murnuud.isEmpty) return null;
    double too(dynamic v) => v is num ? v.toDouble() : double.tryParse('$v') ?? 0;
    double r2(double v) => (v * 100).roundToDouble() / 100;
    const angilluud = ['Орон сууц', 'Зогсоол', 'Агуулах'];
    final niitAngilal = {for (final k in angilluud) k: 0.0};
    final nekhemjlekhuud = <Map<String, dynamic>>[];

    for (final inv in _songosonNekhemjlekhuud) {
      final nereer = <String, double>{};
      for (final m in murnuud) {
        if ('${m['nekhemjlekhId'] ?? ''}' != inv.id || too(m['dun']) <= 0) continue;
        final ner = '${m['zardliinNer'] ?? m['tailbar'] ?? m['turul'] ?? 'Төлбөр'}'.trim();
        nereer[ner] = r2((nereer[ner] ?? 0) + too(m['dun']));
      }
      final jin = {for (final k in angilluud) k: 0.0};
      nereer.forEach((ner, dun) => jin[_angilalTaniya(ner)] = jin[_angilalTaniya(ner)]! + dun);
      final jinNiit = jin.values.fold<double>(0, (a, b) => a + b);
      final uldegdel = inv.effectiveNiitTulbur;
      final angilal = {for (final k in angilluud) k: 0.0};
      if (uldegdel > 0) {
        if (jinNiit <= 0) {
          angilal['Орон сууц'] = r2(uldegdel);
        } else {
          var niilber = 0.0;
          for (final k in angilluud) {
            angilal[k] = r2(uldegdel * jin[k]! / jinNiit);
            niilber += angilal[k]!;
          }
          final zuruu = r2(uldegdel - niilber);
          if (zuruu != 0) {
            final tom = angilluud.reduce((a, k) => angilal[k]! > angilal[a]! ? k : a);
            angilal[tom] = r2(angilal[tom]! + zuruu);
          }
        }
      }
      for (final k in angilluud) {
        niitAngilal[k] = r2(niitAngilal[k]! + angilal[k]!);
      }
      nekhemjlekhuud.add({
        '_id': inv.id,
        'zardluud': [
          for (final e in nereer.entries) {'ner': e.key, 'dun': e.value},
        ],
      });
    }
    return {'nekhemjlekhuud': nekhemjlekhuud, 'angilal': niitAngilal};
  }

  /// Үлдэгдэлтэй ангиллууд — 2+ байвал л ялгаж төлөх сонголт харуулна
  List<MapEntry<String, double>> get _tulukhAngilluud => _angilalUldegdel.entries
      .where((e) => e.value > 0.5)
      .toList();

  /// Сонгосон, төлөгдөөгүй нэхэмжлэхүүд — сараар нь эрэмбэлсэн
  List<NekhemjlekhItem> get _songosonNekhemjlekhuud {
    final ur = widget.invoices.where((i) => i.isSelected && !i.isPaid).toList();
    ur.sort((a, b) => a.nekhemjlekhiinOgnoo.compareTo(b.nekhemjlekhiinOgnoo));
    return ur;
  }

  /// Сонгосон нэхэмжлэхүүдийн төлөх дүн. Гэрээний нийт үлдэгдлээс (урьдчилж
  /// төлсөн бол бага байж болно) хэтрүүлж төлүүлэхгүй.
  double get _songosonDun {
    final niit = _songosonNekhemjlekhuud.fold<double>(
        0, (s, i) => s + i.effectiveNiitTulbur);
    final geree = widget.contractUldegdel;
    if (geree != null && geree > 0.5 && geree < niit) return geree;
    return niit;
  }

  /// Хэрэглэгчийн сонгосон сонголтоор яг төлөх дүн — толгой, QPay хоёулаа үүнийг
  double get _tulukhDun => _songosonAngilal != null
      ? (_angilalUldegdel[_songosonAngilal] ?? 0)
      : _songosonDun;

  static String _angilliinNer(String k) => k == 'Орон сууц'
      ? 'СӨХ (орон сууц)'
      : k == 'Зогсоол'
          ? 'Гараж'
          : k;

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isTablet = screenWidth > 600;
    final modalWidth = isTablet ? 500.0 : screenWidth;
    
    return DraggableScrollableSheet(
      initialChildSize: 0.6,
      minChildSize: 0.4,
      maxChildSize: 0.95,
      builder: (_, scrollController) => Container(
        width: modalWidth,
        decoration: BoxDecoration(
          color: context.backgroundColor,
          borderRadius: BorderRadius.vertical(top: Radius.circular(36.r)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.15),
              blurRadius: 40,
              offset: const Offset(0, -10),
            ),
          ],
        ),
        child: Column(
          children: [
            // Handle bar
            Container(
              margin: EdgeInsets.only(top: 14.h),
              width: 44.w,
              height: 5.h,
              decoration: BoxDecoration(
                color: context.isDarkMode
                    ? Colors.white.withOpacity(0.15)
                    : Colors.black.withOpacity(0.1),
                borderRadius: BorderRadius.circular(10.r),
              ),
            ),
            
            // Header
            Padding(
              padding: EdgeInsets.fromLTRB(28.w, 20.h, 28.w, 10.h),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Төлбөрийн мэдээлэл',
                    style: TextStyle(
                      color: context.textPrimaryColor,
                      fontSize: 20.sp,
                      fontWeight: FontWeight.w500,
                      letterSpacing: -0.5,
                    ),
                  ),
                  GestureDetector(
                    onTap: () => Navigator.of(context).pop(),
                    child: Container(
                      padding: EdgeInsets.all(8.w),
                      decoration: BoxDecoration(
                        color: context.isDarkMode ? Colors.white.withOpacity(0.05) : Colors.black.withOpacity(0.05),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.close_rounded,
                        color: context.textSecondaryColor,
                        size: 18.sp,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            
            Expanded(
              child: ListView(
                controller: scrollController,
                padding: EdgeInsets.symmetric(horizontal: 28.w, vertical: 20.h),
                physics: const BouncingScrollPhysics(),
                children: [
                  // Summary Card
                  Container(
                    padding: EdgeInsets.all(24.w),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: context.isDarkMode 
                            ? [AppColors.deepGreen.withOpacity(0.15), AppColors.deepGreen.withOpacity(0.05)]
                            : [AppColors.deepGreen.withOpacity(0.08), AppColors.deepGreen.withOpacity(0.02)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(28.r),
                      border: Border.all(
                        color: AppColors.deepGreen.withOpacity(0.2),
                        width: 1.5,
                      ),
                    ),
                    child: Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Нийт төлөх',
                              style: TextStyle(
                                fontSize: 13.sp,
                                fontWeight: FontWeight.w500,
                                color: context.textSecondaryColor,
                                letterSpacing: 0.5,
                              ),
                            ),
                            Container(
                              padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 6.h),
                              decoration: BoxDecoration(
                                color: AppColors.deepGreen.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(100),
                              ),
                              child: Text(
                                _songosonAngilal != null
                                    ? _angilliinNer(_songosonAngilal!)
                                    : '${_songosonNekhemjlekhuud.length} нэхэмжлэх',
                                style: TextStyle(
                                  fontSize: 10.sp,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.deepGreen,
                                ),
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: 12.h),
                        Row(
                          children: [
                            Text(
                              '${formatNumber(_tulukhDun, 2)}₮',
                              style: TextStyle(
                                fontSize: 28.sp,
                                fontWeight: FontWeight.w600,
                                color: AppColors.deepGreen,
                                letterSpacing: -0.5,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  
                  if (_songosonAngilal == null &&
                      _songosonNekhemjlekhuud.isNotEmpty) ...[
                    SizedBox(height: 16.h),
                    _buildSaraarZadargaa(context),
                  ],
                  if (_tulukhAngilluud.length > 1) ...[
                    SizedBox(height: 24.h),
                    _buildAngilalSelector(context),
                  ],
                  SizedBox(height: 32.h),
                  _buildVATSelector(context),
                  SizedBox(height: 40.h),
                  
                  // Payment button
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    width: double.infinity,
                    height: 56.h,
                    child: ElevatedButton(
                      onPressed: _isLoadingQPay
                          ? null
                          : () => _createQPayAndShowBankList(),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.transparent,
                        shadowColor: Colors.transparent,
                        padding: EdgeInsets.zero,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20.r),
                        ),
                      ),
                      child: Ink(
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [AppColors.deepGreen, Color(0xFF10B981)],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(20.r),
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.deepGreen.withOpacity(0.35),
                              blurRadius: 15,
                              offset: const Offset(0, 8),
                            ),
                          ],
                        ),
                        child: Container(
                          alignment: Alignment.center,
                          child: _isLoadingQPay
                              ? SizedBox(
                                  height: 20.h,
                                  width: 20.h,
                                  child: const CircularProgressIndicator(
                                    strokeWidth: 2.5,
                                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                  ),
                                )
                              : Text(
                                  'ТӨЛБӨР ТӨЛӨХ',
                                  style: TextStyle(
                                    fontSize: 14.sp,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.white,
                                    letterSpacing: 1.0,
                                  ),
                                ),
                        ),
                      ),
                    ),
                  ),
                  SizedBox(height: 20.h),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Сонгосон нэхэмжлэх бүрийг сараар нь, доор нь зардлуудтай харуулна
  Widget _buildSaraarZadargaa(BuildContext context) {
    final nekhemjlekhuud = _songosonNekhemjlekhuud;
    final khuree = context.isDarkMode
        ? Colors.white.withOpacity(0.08)
        : Colors.black.withOpacity(0.06);

    Widget mur(String ner, double dun, {bool tolgoi = false}) => Padding(
          padding: EdgeInsets.symmetric(vertical: tolgoi ? 0 : 3.h),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  ner,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: tolgoi ? 13.sp : 12.sp,
                    fontWeight: tolgoi ? FontWeight.w600 : FontWeight.w400,
                    color: tolgoi
                        ? context.textPrimaryColor
                        : context.textSecondaryColor,
                  ),
                ),
              ),
              Text(
                '${formatNumber(dun, 2)}₮',
                style: TextStyle(
                  fontSize: tolgoi ? 13.sp : 12.sp,
                  fontWeight: tolgoi ? FontWeight.w600 : FontWeight.w400,
                  color: tolgoi
                      ? context.textPrimaryColor
                      : context.textSecondaryColor,
                ),
              ),
            ],
          ),
        );

    return Container(
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 6.h),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18.r),
        border: Border.all(color: khuree),
      ),
      child: Column(
        children: [
          for (var n = 0; n < nekhemjlekhuud.length; n++) ...[
            if (n > 0) Divider(height: 1, color: khuree),
            Padding(
              padding: EdgeInsets.symmetric(vertical: 10.h),
              child: Column(
                children: [
                  mur('${nekhemjlekhuud[n].formattedPeriod} сар',
                      nekhemjlekhuud[n].effectiveNiitTulbur,
                      tolgoi: true),
                  SizedBox(height: 4.h),
                  ...(_nekhemjlekhiinMurnuud[nekhemjlekhuud[n].id] ??
                          (nekhemjlekhuud[n].medeelel?.zardluud ?? const <Zardal>[])
                              .where((z) => z.isDisplayable && z.displayAmount.abs() > 0.005)
                              .map((z) => MapEntry(z.ner, z.displayAmount))
                              .toList())
                      .map((e) => mur(e.key, e.value)),
                  if (nekhemjlekhuud[n].khungulultDun > 0.005)
                    mur('Хөнгөлөлт', -nekhemjlekhuud[n].khungulultDun),
                  if (nekhemjlekhuud[n].tulsunDun > 0.005)
                    mur('Төлсөн', -nekhemjlekhuud[n].tulsunDun),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildAngilalSelector(BuildContext context) {
    final isDark = context.isDarkMode;
    Widget mur({required String? key, required String ner, required double dun, required IconData icon}) {
      final songogdson = _songosonAngilal == key;
      return Padding(
        padding: EdgeInsets.only(bottom: 8.h),
        child: Material(
          color: songogdson
              ? AppColors.deepGreen.withOpacity(isDark ? 0.22 : 0.08)
              : (isDark ? Colors.white.withOpacity(0.04) : Colors.white),
          borderRadius: BorderRadius.circular(16.r),
          child: InkWell(
            borderRadius: BorderRadius.circular(16.r),
            onTap: () => setState(() => _songosonAngilal = key),
            child: Container(
              padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 12.h),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16.r),
                border: Border.all(
                  color: songogdson
                      ? AppColors.deepGreen
                      : (isDark ? Colors.white.withOpacity(0.08) : Colors.black.withOpacity(0.06)),
                  width: songogdson ? 1.5 : 1,
                ),
              ),
              child: Row(
                children: [
                  Icon(icon, size: 20.sp, color: AppColors.deepGreen),
                  SizedBox(width: 12.w),
                  Expanded(
                    child: Text(
                      ner,
                      style: TextStyle(
                        fontSize: 14.sp,
                        fontWeight: FontWeight.w500,
                        color: context.textPrimaryColor,
                      ),
                    ),
                  ),
                  Text(
                    '${formatNumber(dun, 2)}₮',
                    style: TextStyle(
                      fontSize: 14.sp,
                      fontWeight: FontWeight.w600,
                      color: context.textPrimaryColor,
                    ),
                  ),
                  SizedBox(width: 10.w),
                  Icon(
                    songogdson ? Icons.radio_button_checked_rounded : Icons.radio_button_off_rounded,
                    size: 20.sp,
                    color: songogdson ? AppColors.deepGreen : context.textSecondaryColor,
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Юуг төлөх вэ?',
          style: TextStyle(
            fontSize: 14.sp,
            fontWeight: FontWeight.w600,
            color: context.textPrimaryColor,
          ),
        ),
        SizedBox(height: 4.h),
        Text(
          'СӨХ болон гаражийн төлбөрөө тусад нь төлж болно.',
          style: TextStyle(fontSize: 12.sp, color: context.textSecondaryColor),
        ),
        SizedBox(height: 12.h),
        mur(
          key: null,
          ner: _songosonNekhemjlekhuud.length > 1
              ? 'Сонгосон ${_songosonNekhemjlekhuud.length} нэхэмжлэх'
              : 'Сонгосон нэхэмжлэх',
          dun: _songosonDun,
          icon: Icons.receipt_long_rounded,
        ),
        ..._tulukhAngilluud.map((e) => mur(
              key: e.key,
              ner: _angilliinNer(e.key),
              dun: e.value,
              icon: e.key == 'Зогсоол'
                  ? Icons.garage_rounded
                  : e.key == 'Агуулах'
                      ? Icons.inventory_2_rounded
                      : Icons.apartment_rounded,
            )),
      ],
    );
  }

  Future<void> _createQPayAndShowBankList() async {
    setState(() {
      _isLoadingQPay = true;
      _qrImageOwnOrg = null;
      _qrImageWallet = null;
      _qpayBanks = [];
      _selectedInvoiceIdsForCheck = [];
      _gereeniiDugaarForCheck = null;
    });

    try {
      if (_vatReceiveType == 'COMPANY') {
        final rDText = _vatTinController.text.trim();
        if (rDText.isEmpty) {
          if (mounted) {
            showGlassSnackBar(
              context,
              message: 'Байгууллагын РД оруулна уу',
              icon: Icons.info_outline,
              iconColor: AppColors.deepGreenAccent,
            );
          }
          setState(() => _isLoadingQPay = false);
          return;
        }

        final isNumeric = RegExp(r'^[0-9]+$').hasMatch(rDText);
        if (rDText.length != 7 || !isNumeric) {
          if (mounted) {
            showGlassSnackBar(
              context,
              message: 'Байгууллагын РД алдаатай байна (7 оронтой тоо оруулна уу)',
              icon: Icons.error_outline,
              iconColor: Colors.red,
            );
          }
          setState(() => _isLoadingQPay = false);
          return;
        }
      }

      String? turul;
      List<String> selectedInvoiceIds = [];

      for (var invoice in widget.invoices) {
        if (invoice.isSelected) {
          selectedInvoiceIds.add(invoice.id);
          turul ??= invoice.gereeniiDugaar;
        }
      }

      // Use contract's globalUldegdel (same as HistoryModal) - single source of truth
      // Хэрэглэгчийн харсан, сонгосон дүнгээр л төлүүлнэ
      double totalAmount = _songosonDun;

      _selectedInvoiceIdsForCheck = selectedInvoiceIds;
      _gereeniiDugaarForCheck = turul;

      if (selectedInvoiceIds.isEmpty) {
        throw Exception('Нэхэмжлэх сонгоогүй байна');
      }

      if (turul == null || turul.isEmpty) {
        throw Exception('Гэрээний дугаар олдсонгүй');
      }

      // Get invoice details for Custom QPay
      String? dansniiDugaar;
      String? burtgeliinDugaar;
      String? firstInvoiceId;

      if (selectedInvoiceIds.isNotEmpty) {
        final firstInvoice = widget.invoices.firstWhere(
          (inv) => inv.id == selectedInvoiceIds.first,
          orElse: () => widget.invoices.firstWhere((inv) => inv.isSelected),
        );
        dansniiDugaar = firstInvoice.dansniiDugaar.isNotEmpty
            ? firstInvoice.dansniiDugaar
            : null;
        burtgeliinDugaar = firstInvoice.register.isNotEmpty
            ? firstInvoice.register
            : null;
            
        // Don't send synthetic IDs to the backend, it will cause 404 in webhooks
        if (!firstInvoice.id.startsWith('synthetic-balance')) {
          firstInvoiceId = firstInvoice.id;
        }
      }

      // Check for OWN_ORG and WALLET addresses
      final ownOrgBaiguullagiinId = await StorageService.getBaiguullagiinId();
      final ownOrgBarilgiinId = await StorageService.getBarilgiinId();
      final walletBairId = await StorageService.getWalletBairId();
      final walletSource = await StorageService.getWalletBairSource();

      final hasOwnOrg =
          ownOrgBaiguullagiinId != null && ownOrgBarilgiinId != null;
      final hasWallet = walletBairId != null && (walletSource == 'WALLET_API' || walletSource == 'WALLET_QPAY');

      // Create QPay invoice (Auto-detect source)
      Map<String, dynamic>? finalResponse;

      if (hasOwnOrg || hasWallet) {
        try {
          if (hasWallet && !hasOwnOrg) {
            // Pure Wallet flow
            finalResponse = await ApiService.createWalletQPayPayment(
              billingId: widget.invoices.first.billingId,
              billIds: selectedInvoiceIds,
              vatReceiveType: _vatReceiveType,
              vatCompanyReg: _vatReceiveType == 'COMPANY' ? _vatTinController.text : null,
            );
          } else {
            // Own Org or Hybrid flow (via qpayGargaya which auto-detects)
            final angilal = _songosonAngilal;
            finalResponse = await ApiService.qpayGargaya(
              baiguullagiinId: ownOrgBaiguullagiinId,
              barilgiinId: ownOrgBarilgiinId,
              // Ангиллаар төлөхөд тухайн ангиллын үлдэгдлийг гэрээнд төлнө
              // (нэхэмжлэхгүй) — callback нь төлөлтийг ангиллаар тэмдэглэнэ.
              dun: angilal != null ? (_angilalUldegdel[angilal] ?? 0) : totalAmount,
              turul: turul,
              nekhemjlekhiinId: angilal != null ? null : firstInvoiceId,
              gereeniiId: angilal != null ? widget.gereeniiId : null,
              angilal: angilal,
              dansniiDugaar: dansniiDugaar,
              burtgeliinDugaar: burtgeliinDugaar,
              customerTin: _vatReceiveType == 'COMPANY' ? _vatTinController.text : null,
            );
          }

          if (finalResponse != null && finalResponse['qr_image'] != null) {
            setState(() {
              final source = finalResponse!['source']?.toString();
              if (source == 'WALLET_API' || source == 'WALLET_QPAY') {
                _qrImageWallet = finalResponse!['qr_image']?.toString();
              } else {
                _qrImageOwnOrg = finalResponse!['qr_image']?.toString();
              }
              
              _senderInvoiceNoForSocket = 
                  finalResponse!['walletPaymentId']?.toString() ?? 
                  finalResponse!['sender_invoice_no']?.toString() ??
                  finalResponse!['invoice_id']?.toString();
            });

            if (finalResponse['urls'] != null && finalResponse['urls'] is List) {
              final banks = (finalResponse['urls'] as List)
                  .map((e) => QPayBank.fromJson(e as Map<String, dynamic>))
                  .toList();
              setState(() {
                _qpayBanks = banks;
              });
            }
          }
        } catch (e) {

        }
      }



      if (_qrImageOwnOrg == null && _qrImageWallet == null) {
        if (mounted) {
          showGlassSnackBar(
            context,
            message: 'QR код үүсгэхэд алдаа гарлаа',
            icon: Icons.error,
            iconColor: Colors.red,
          );
        }
        return;
      }

      final hasQPayWalletTile = _qpayBanks.any(
        (b) =>
            b.description.contains('qPay хэтэвч') ||
            b.name.toLowerCase().contains('qpay wallet'),
      );
      if (!hasQPayWalletTile) {
        _qpayBanks = [
          ..._qpayBanks,
          QPayBank(
            name: 'QPay Wallet',
            description: 'qPay хэтэвч',
            logo: '',
            link: '',
          ),
        ];
      }

      if (!mounted) return;

      Navigator.pop(context); // Close payment modal
      await Future.delayed(const Duration(milliseconds: 120));

      if (!mounted) return;

      showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (context) => BankSelectionModal(
          qpayBanks: _qpayBanks,
          isLoadingQPay: false,
          onBankTap: (bank) async {
            // Open selected bank app link (deep link)
            if (bank.link.isEmpty) return;
            final uri = Uri.tryParse(bank.link);
            if (uri == null) return;
            try {
              await launchUrl(uri, mode: LaunchMode.externalApplication);
            } catch (_) {
              // ignore
            }
          },
          onQPayWalletTap: () async {
            // Close bank list then show QR
            Navigator.of(context).pop();
            await Future.delayed(const Duration(milliseconds: 80));
            if (!mounted) return;
            showDialog(
              context: context,
              builder: (context) => QPayQRModal(
                qrImageOwnOrg: _qrImageOwnOrg,
                qrImageWallet: _qrImageWallet,
                urls: _qpayBanks.map((b) => {'name': b.name, 'description': b.description, 'logo': b.logo, 'link': b.link}).toList(),
                walletPaymentId: finalResponse?['walletPaymentId']?.toString(),
                invoiceNumber: _senderInvoiceNoForSocket,
                amount: totalAmount,
                onCheckPaymentAsync: () async {
                  final wId = finalResponse?['walletPaymentId']?.toString();
                  if (wId != null && wId.isNotEmpty) {
                    // New high-fidelity check via backend poll
                    return await ApiService.checkWalletQPayStatus(walletPaymentId: wId);
                  }

                  // Fallback: Legacy check (History list)
                  await widget.onPaymentTap();
                  if (_gereeniiDugaarForCheck == null || _gereeniiDugaarForCheck!.isEmpty || _selectedInvoiceIdsForCheck.isEmpty) {
                    return null;
                  }
                  try {
                    final resp = await ApiService.fetchNekhemjlekhiinTuukh(
                      gereeniiDugaar: _gereeniiDugaarForCheck!,
                      khuudasniiKhemjee: 10,
                    );
                    final list = resp['jagsaalt'] as List<dynamic>? ?? [];
                    final byId = {for (var item in list) item['_id']?.toString(): item};
                    return _selectedInvoiceIdsForCheck.every((id) => byId[id]?['tuluv'] == 'Төлсөн');
                  } catch (_) {
                    return null;
                  }
                },
              ),
            );
          },
        ),
      );
    } catch (e) {
      if (mounted) {
        showGlassSnackBar(
          context,
          message: friendlyError(e, fallback: 'Төлбөрийн нэхэмжлэх үүсгэж чадсангүй. Дахин оролдоно уу.'),
          icon: Icons.error,
          iconColor: Colors.red,
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoadingQPay = false;
        });
      }
    }
  }

  Widget _buildVATSelector(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: EdgeInsets.only(left: 4.w, bottom: 12.h),
          child: Text(
            'И-баримт хүлээн авах',
            style: TextStyle(
              fontSize: 13.sp,
              fontWeight: FontWeight.w600,
              color: context.textPrimaryColor.withOpacity(0.9),
              letterSpacing: 0.2,
            ),
          ),
        ),
        Container(
          padding: EdgeInsets.all(6.w),
          decoration: BoxDecoration(
            color: context.isDarkMode ? Colors.white.withOpacity(0.06) : Colors.black.withOpacity(0.04),
            borderRadius: BorderRadius.circular(20.r),
          ),
          child: Row(
            children: [
              Expanded(
                child: _buildVatOption(
                  context,
                  title: 'Хувь хүн',
                  isSelected: _vatReceiveType == 'CITIZEN',
                  onTap: () => setState(() => _vatReceiveType = 'CITIZEN'),
                ),
              ),
              SizedBox(width: 6.w),
              Expanded(
                child: _buildVatOption(
                  context,
                  title: 'Байгууллага',
                  isSelected: _vatReceiveType == 'COMPANY',
                  onTap: () => setState(() => _vatReceiveType = 'COMPANY'),
                ),
              ),
            ],
          ),
        ),
        if (_vatReceiveType == 'COMPANY') ...[
          SizedBox(height: 20.h),
          TweenAnimationBuilder<double>(
            tween: Tween(begin: 0.0, end: 1.0),
            duration: const Duration(milliseconds: 300),
            builder: (context, value, child) {
              return Opacity(
                opacity: value,
                child: Transform.translate(
                  offset: Offset(0, 10 * (1 - value)),
                  child: child,
                ),
              );
            },
            child: TextField(
              controller: _vatTinController,
              keyboardType: TextInputType.number,
              style: TextStyle(
                fontSize: 14.sp,
                fontWeight: FontWeight.w600,
                color: context.textPrimaryColor,
              ),
              decoration: InputDecoration(
                hintText: 'Байгууллагын РД оруулна уу',
                hintStyle: TextStyle(
                  fontSize: 13.sp,
                  color: context.textSecondaryColor.withOpacity(0.4),
                ),
                prefixIcon: Icon(Icons.business_rounded, 
                    size: 18.sp, color: AppColors.deepGreen.withOpacity(0.6)),
                contentPadding: EdgeInsets.symmetric(
                  horizontal: 20.w,
                  vertical: 16.h,
                ),
                filled: true,
                fillColor: context.isDarkMode
                    ? Colors.white.withOpacity(0.05)
                    : Colors.black.withOpacity(0.02),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(18.r),
                  borderSide: BorderSide.none,
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(18.r),
                  borderSide: BorderSide(
                    color: context.borderColor.withOpacity(0.1),
                    width: 1,
                  ),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(18.r),
                  borderSide: const BorderSide(
                    color: AppColors.deepGreen,
                    width: 1.5,
                  ),
                ),
              ),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildVatOption(
    BuildContext context, {
    required String title,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        onTap();
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOutCubic,
        padding: EdgeInsets.symmetric(vertical: 12.h),
        decoration: BoxDecoration(
          gradient: isSelected
              ? const LinearGradient(
                  colors: [AppColors.deepGreen, Color(0xFF10B981)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                )
              : null,
          borderRadius: BorderRadius.circular(16.r),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: AppColors.deepGreen.withOpacity(0.3),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  )
                ]
              : null,
        ),
        child: Center(
          child: Text(
            title,
            style: TextStyle(
              fontSize: 13.sp,
              fontWeight: isSelected ? FontWeight.w600 : FontWeight.w600,
              color: isSelected ? Colors.white : context.textSecondaryColor,
            ),
          ),
        ),
      ),
    );
  }
}
