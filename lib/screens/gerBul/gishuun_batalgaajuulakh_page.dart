import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:sukh_app/constants/constants.dart';
import 'package:sukh_app/services/ger_bul_service.dart';
import 'package:sukh_app/services/socket_service.dart';
import 'package:sukh_app/services/storage_service.dart';
import 'package:sukh_app/utils/theme_extensions.dart';
import 'package:sukh_app/widgets/glass_snackbar.dart';

/// Уригдсан хүн SMS-ээр ирсэн кодоо оруулж, нууц кодоо тохируулан
/// гэр бүлийн гишүүнчлэлээ баталгаажуулна. Амжилттай бол шууд нэвтэрнэ.
class GishuunBatalgaajuulakhPage extends StatefulWidget {
  /// Нэвтрэх дэлгэцээс дамжуулсан утасны дугаар (байвал урьдчилж бөглөнө)
  final String? utas;

  const GishuunBatalgaajuulakhPage({super.key, this.utas});

  @override
  State<GishuunBatalgaajuulakhPage> createState() =>
      _GishuunBatalgaajuulakhPageState();
}

class _GishuunBatalgaajuulakhPageState
    extends State<GishuunBatalgaajuulakhPage> {
  final _formKey = GlobalKey<FormState>();
  final _utasController = TextEditingController();
  final _nuutsUgController = TextEditingController();
  final _davtakhController = TextEditingController();

  final List<TextEditingController> _kodControllers = List.generate(
    4,
    (_) => TextEditingController(),
  );
  final List<FocusNode> _kodFocusNodes = List.generate(4, (_) => FocusNode());

  bool _isLoading = false;
  bool _nuutsUgKharagdakh = false;

  @override
  void initState() {
    super.initState();
    if (widget.utas != null && widget.utas!.isNotEmpty) {
      _utasController.text = widget.utas!;
    } else {
      _khadgalsanUtasAvya();
    }
  }

  Future<void> _khadgalsanUtasAvya() async {
    final utas = await StorageService.getSavedPhoneNumber();
    if (utas != null && utas.isNotEmpty && mounted) {
      setState(() => _utasController.text = utas);
    }
  }

  @override
  void dispose() {
    _utasController.dispose();
    _nuutsUgController.dispose();
    _davtakhController.dispose();
    for (final c in _kodControllers) {
      c.dispose();
    }
    for (final f in _kodFocusNodes) {
      f.dispose();
    }
    super.dispose();
  }

  String get _kod => _kodControllers.map((c) => c.text).join();

  bool get _bugdBugluusun =>
      _utasController.text.trim().length == 8 &&
      _kod.length == 4 &&
      _nuutsUgController.text.length >= 4 &&
      _davtakhController.text.length >= 4;

  Future<void> _batalgaajuulya() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    if (_kod.length != 4) {
      showGlassSnackBar(
        context,
        message: '4 оронтой кодоо бүрэн оруулна уу',
        icon: Icons.error_outline,
        iconColor: Colors.red,
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final khariu = await GerBulService.batalgaajuulya(
        utas: _utasController.text.trim(),
        code: _kod,
        nuutsUg: _nuutsUgController.text.trim(),
      );

      final result = khariu['result'];
      await _khayagKhadgalya(result is Map ? Map<String, dynamic>.from(result) : null);

      try {
        await SocketService.instance.connect();
      } catch (_) {}

      if (!mounted) return;
      setState(() => _isLoading = false);

      showGlassSnackBar(
        context,
        message: 'Гэр бүлийн гишүүнээр бүртгэгдлээ',
        icon: Icons.check_circle_outline,
        iconColor: Colors.green,
      );

      await Future.delayed(const Duration(milliseconds: 400));
      if (!mounted) return;

      final taniltsuulga = await StorageService.getTaniltsuulgaKharakhEsekh();
      final khayagtai = await StorageService.hasSavedAddress();
      if (!mounted) return;

      context.go(
        taniltsuulga
            ? '/ekhniikh'
            : (khayagtai ? '/nuur' : '/address_selection'),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);

      // Код буруу бол дахин оруулахад хялбар байлгана
      for (final c in _kodControllers) {
        c.clear();
      }
      _kodFocusNodes.first.requestFocus();

      showGlassSnackBar(
        context,
        message: e.toString(),
        icon: Icons.error_outline,
        iconColor: Colors.red,
        duration: const Duration(seconds: 3),
      );
    }
  }

  /// Гишүүн үндсэн эзэмшигчийн хаягийг өвлөнө. Нэвтрэх дэлгэцийнхтэй
  /// ижил дүрмээр локалд хадгалснаар нүүр хуудас шууд нээгдэнэ.
  Future<void> _khayagKhadgalya(Map<String, dynamic>? user) async {
    if (user == null) {
      await StorageService.clearWalletAddress();
      return;
    }

    String? bairId = user['walletBairId']?.toString();
    String? doorNo = user['walletDoorNo']?.toString();

    final toots = user['toots'];
    if ((bairId == null ||
            bairId.isEmpty ||
            doorNo == null ||
            doorNo.isEmpty) &&
        toots is List) {
      final walletToot = toots.cast<dynamic>().firstWhere(
        (item) =>
            item is Map &&
            item['walletBairId']?.toString().isNotEmpty == true &&
            item['walletDoorNo']?.toString().isNotEmpty == true,
        orElse: () => null,
      );
      if (walletToot is Map) {
        bairId = walletToot['walletBairId']?.toString();
        doorNo = walletToot['walletDoorNo']?.toString();
      }
    }

    if (bairId != null &&
        bairId.isNotEmpty &&
        doorNo != null &&
        doorNo.isNotEmpty) {
      await StorageService.saveWalletAddress(bairId: bairId, doorNo: doorNo);
      return;
    }

    final baiguullagiinId = user['baiguullagiinId']?.toString();
    final barilgiinId = user['barilgiinId']?.toString();

    if (baiguullagiinId != null &&
        baiguullagiinId.isNotEmpty &&
        barilgiinId != null &&
        barilgiinId.isNotEmpty) {
      await StorageService.saveWalletAddress(
        bairId: barilgiinId,
        doorNo: 'OWN_ORG',
        source: 'OWN_ORG',
        baiguullagiinId: baiguullagiinId,
        barilgiinId: barilgiinId,
      );
      return;
    }

    await StorageService.clearWalletAddress();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = context.isDarkMode;

    return Scaffold(
      backgroundColor: context.surfaceColor,
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            padding: EdgeInsets.fromLTRB(24.w, 12.h, 24.w, 40.h),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Align(
                  alignment: Alignment.centerLeft,
                  child: GestureDetector(
                    onTap: () {
                      if (context.canPop()) {
                        context.pop();
                      } else {
                        context.go('/newtrekh');
                      }
                    },
                    child: Container(
                      padding: EdgeInsets.all(8.w),
                      decoration: const BoxDecoration(
                        color: AppColors.deepGreen,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.arrow_back_rounded,
                        color: Colors.white,
                        size: 20.sp,
                      ),
                    ),
                  ),
                ),
                SizedBox(height: 28.h),

                Container(
                  width: 64.w,
                  height: 64.w,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: AppColors.deepGreen.withOpacity(0.08),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.family_restroom_rounded,
                    size: 30.sp,
                    color: AppColors.deepGreen,
                  ),
                ),
                SizedBox(height: 20.h),

                Text(
                  'Гэр бүлийн урилга',
                  style: TextStyle(
                    fontSize: 22.sp,
                    fontWeight: FontWeight.w800,
                    color: context.textPrimaryColor,
                  ),
                ),
                SizedBox(height: 8.h),
                Text(
                  'Танд ирсэн 4 оронтой кодоо оруулаад, нэвтрэх нууц кодоо '
                  'тохируулна уу.',
                  style: TextStyle(
                    fontSize: 13.sp,
                    height: 1.5,
                    color: context.textSecondaryColor,
                  ),
                ),
                SizedBox(height: 28.h),

                _buildShoshgo('Утасны дугаар'),
                TextFormField(
                  controller: _utasController,
                  keyboardType: TextInputType.phone,
                  maxLength: 8,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  onChanged: (_) => setState(() {}),
                  validator: (utga) {
                    final v = (utga ?? '').trim();
                    if (v.length != 8) return '8 оронтой дугаар оруулна уу';
                    return null;
                  },
                  style: TextStyle(
                    fontSize: 15.sp,
                    fontWeight: FontWeight.w700,
                    color: context.textPrimaryColor,
                  ),
                  decoration: _talbariinChimeglel(
                    hint: '99112233',
                    icon: Icons.phone_iphone_rounded,
                    isDark: isDark,
                  ),
                ),
                SizedBox(height: 18.h),

                _buildShoshgo('Баталгаажуулах код'),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: List.generate(
                    4,
                    (index) => _buildKodBox(index, isDark),
                  ),
                ),
                SizedBox(height: 24.h),

                _buildShoshgo('Шинэ нууц код'),
                TextFormField(
                  controller: _nuutsUgController,
                  obscureText: !_nuutsUgKharagdakh,
                  keyboardType: TextInputType.number,
                  maxLength: 4,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  onChanged: (_) => setState(() {}),
                  validator: (utga) {
                    if ((utga ?? '').length < 4) {
                      return '4 оронтой код оруулна уу';
                    }
                    return null;
                  },
                  style: TextStyle(
                    fontSize: 15.sp,
                    fontWeight: FontWeight.w700,
                    color: context.textPrimaryColor,
                    letterSpacing: 4,
                  ),
                  decoration: _talbariinChimeglel(
                    hint: '••••',
                    icon: Icons.lock_outline_rounded,
                    isDark: isDark,
                    suffix: IconButton(
                      icon: Icon(
                        _nuutsUgKharagdakh
                            ? Icons.visibility_off_outlined
                            : Icons.visibility_outlined,
                        size: 18.sp,
                        color: context.inputGrayColor,
                      ),
                      onPressed: () => setState(
                        () => _nuutsUgKharagdakh = !_nuutsUgKharagdakh,
                      ),
                    ),
                  ),
                ),
                SizedBox(height: 14.h),

                _buildShoshgo('Нууц код давтах'),
                TextFormField(
                  controller: _davtakhController,
                  obscureText: !_nuutsUgKharagdakh,
                  keyboardType: TextInputType.number,
                  maxLength: 4,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  onChanged: (_) => setState(() {}),
                  validator: (utga) {
                    if ((utga ?? '') != _nuutsUgController.text) {
                      return 'Нууц код таарахгүй байна';
                    }
                    return null;
                  },
                  style: TextStyle(
                    fontSize: 15.sp,
                    fontWeight: FontWeight.w700,
                    color: context.textPrimaryColor,
                    letterSpacing: 4,
                  ),
                  decoration: _talbariinChimeglel(
                    hint: '••••',
                    icon: Icons.lock_outline_rounded,
                    isDark: isDark,
                  ),
                ),
                SizedBox(height: 28.h),

                _buildUrgeljluulekhTovch(),
                SizedBox(height: 18.h),

                Text(
                  'Код ирээгүй юу? Таныг урьсан хүнээс кодоо дахин илгээхийг '
                  'хүсээрэй. Урилга 24 цагийн дараа хүчингүй болно.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 12.sp,
                    height: 1.5,
                    color: context.textSecondaryColor,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildShoshgo(String utga) {
    return Padding(
      padding: EdgeInsets.only(left: 4.w, bottom: 8.h),
      child: Text(
        utga,
        style: TextStyle(
          fontSize: 12.sp,
          fontWeight: FontWeight.w700,
          color: context.textSecondaryColor,
        ),
      ),
    );
  }

  InputDecoration _talbariinChimeglel({
    required String hint,
    required IconData icon,
    required bool isDark,
    Widget? suffix,
  }) {
    return InputDecoration(
      counterText: '',
      hintText: hint,
      hintStyle: TextStyle(
        fontSize: 15.sp,
        color: context.inputGrayColor,
        fontWeight: FontWeight.w400,
        letterSpacing: 0,
      ),
      prefixIcon: Icon(icon, size: 18.sp, color: context.inputGrayColor),
      suffixIcon: suffix,
      filled: true,
      fillColor: isDark
          ? Colors.white.withOpacity(0.04)
          : Colors.black.withOpacity(0.03),
      contentPadding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 16.h),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14.r),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14.r),
        borderSide: BorderSide.none,
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14.r),
        borderSide: const BorderSide(color: AppColors.deepGreen, width: 1.5),
      ),
    );
  }

  Widget _buildKodBox(int index, bool isDark) {
    return Container(
      width: 62.w,
      height: 68.h,
      decoration: BoxDecoration(
        color: isDark
            ? Colors.white.withOpacity(0.05)
            : Colors.black.withOpacity(0.03),
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(
          color: _kodFocusNodes[index].hasFocus
              ? AppColors.deepGreen
              : (isDark
                    ? Colors.white.withOpacity(0.1)
                    : Colors.black.withOpacity(0.05)),
          width: 1.5,
        ),
      ),
      child: KeyboardListener(
        focusNode: FocusNode(),
        onKeyEvent: (KeyEvent event) {
          if (event is KeyDownEvent &&
              event.logicalKey == LogicalKeyboardKey.backspace) {
            if (_kodControllers[index].text.isEmpty && index > 0) {
              _kodControllers[index - 1].clear();
              _kodFocusNodes[index - 1].requestFocus();
              setState(() {});
            }
          }
        },
        child: TextFormField(
          controller: _kodControllers[index],
          focusNode: _kodFocusNodes[index],
          textAlign: TextAlign.center,
          keyboardType: TextInputType.number,
          autofillHints: const [AutofillHints.oneTimeCode],
          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
          style: TextStyle(
            color: context.textPrimaryColor,
            fontSize: 26.sp,
            fontWeight: FontWeight.bold,
            height: 1.2,
          ),
          decoration: const InputDecoration(
            border: InputBorder.none,
            contentPadding: EdgeInsets.zero,
            counterText: '',
          ),
          onChanged: (value) {
            // SMS-ээс бүтэн код зэрэг наагдсан тохиолдол
            if (value.length > 1) {
              final oronguud = value.replaceAll(RegExp(r'\D'), '');
              for (int i = 0; i < oronguud.length && index + i < 4; i++) {
                _kodControllers[index + i].text = oronguud[i];
              }
              final suuliinIndex = (index + oronguud.length - 1).clamp(0, 3);
              _kodFocusNodes[suuliinIndex].requestFocus();
              setState(() {});
              return;
            }
            if (value.isNotEmpty && index < 3) {
              _kodFocusNodes[index + 1].requestFocus();
            }
            setState(() {});
          },
        ),
      ),
    );
  }

  Widget _buildUrgeljluulekhTovch() {
    final idevkhtei = _bugdBugluusun && !_isLoading;
    return GestureDetector(
      onTap: idevkhtei ? _batalgaajuulya : null,
      child: Container(
        height: 54.h,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: idevkhtei ? AppColors.deepGreen : context.inputGrayColor,
          borderRadius: BorderRadius.circular(16.r),
        ),
        child: _isLoading
            ? SizedBox(
                width: 22.w,
                height: 22.w,
                child: const CircularProgressIndicator(
                  color: Colors.white,
                  strokeWidth: 2,
                ),
              )
            : Text(
                'Баталгаажуулах',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 15.sp,
                  fontWeight: FontWeight.w800,
                ),
              ),
      ),
    );
  }
}
