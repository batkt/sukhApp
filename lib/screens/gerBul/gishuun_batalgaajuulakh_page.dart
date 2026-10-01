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
import 'package:sukh_app/utils/error_message.dart';
import 'package:sukh_app/widgets/otp_code_input.dart';

/// Гэр бүлийн гишүүн 4 оронтой урилгын кодоо оруулж,
/// өөрийн нэр, нууц үгээ тохируулан бүртгэлээ баталгаажуулах хуудас.
class GishuunBatalgaajuulakhPage extends StatefulWidget {
  final String? initialCode;
  final String? utas;

  const GishuunBatalgaajuulakhPage({
    super.key,
    this.initialCode,
    this.utas,
  });

  @override
  State<GishuunBatalgaajuulakhPage> createState() =>
      _GishuunBatalgaajuulakhPageState();
}

class _GishuunBatalgaajuulakhPageState
    extends State<GishuunBatalgaajuulakhPage> {
  final _formKey = GlobalKey<FormState>();

  // 4 оронтой код — нэг controller (SMS autofill бүх оронг нэг дор бөглөнө)
  final _otpController = TextEditingController();
  final _otpFocusNode = FocusNode();

  // Уригдсан дугаар.
  //
  // Өмнө энд Овог/Нэр байсан боловч тэднийг УРЬСАН хүн
  // урилга үүсгэх үедээ бөглөдөг тул дахин асуух шаардлагагүй.
  // Дугаар нь харин урилгыг нарийвчлахад хэрэгтэй — нэг код олон
  // баазад давхардвал backend дугаараар ялгана.
  final _utasController = TextEditingController();

  final _nuutsUgController = TextEditingController();
  final _davtakhController = TextEditingController();

  bool _nuutsUgKharagdakh = false;
  bool _isLoading = false;

  // 4 оронтой кодоор татсан урилгын мэдээлэл
  bool _isCheckingCode = false;
  Map<String, dynamic>? _urilgaInfo;
  String? _codeError;

  @override
  void initState() {
    super.initState();
    if (widget.initialCode != null && widget.initialCode!.isNotEmpty) {
      final kod = widget.initialCode!.trim();
      _otpController.text = kod.length > 4 ? kod.substring(0, 4) : kod;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (_kod.length == 4) {
          _shalgaya();
        }
      });
    }
  }

  @override
  void dispose() {
    _otpController.dispose();
    _otpFocusNode.dispose();
    _utasController.dispose();
    _nuutsUgController.dispose();
    _davtakhController.dispose();
    super.dispose();
  }

  String get _kod => _otpController.text;

  bool get _bugdBugluusun =>
      _kod.length == 4 &&
      _utasController.text.trim().length >= 8 &&
      _nuutsUgController.text.length >= 4 &&
      _davtakhController.text.length >= 4;

  Future<void> _shalgaya() async {
    if (_kod.length != 4) return;
    setState(() {
      _isCheckingCode = true;
      _codeError = null;
    });

    try {
      final res = await GerBulService.urilgaShalgaya(code: _kod);
      if (!mounted) return;
      setState(() {
        _isCheckingCode = false;
        if (res['success'] == true) {
          final info = res['urilga'] is Map
              ? Map<String, dynamic>.from(res['urilga'])
              : Map<String, dynamic>.from(res);
          _urilgaInfo = info;
          _codeError = null;
        } else {
          _urilgaInfo = null;
          _codeError = res['message']?.toString() ?? 'Урилга олдсонгүй';
        }
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isCheckingCode = false;
        _urilgaInfo = null;
        _codeError = friendlyError(e, fallback: 'Урилгын код шалгаж чадсангүй. Дахин оролдоно уу.');
      });
    }
  }

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

    if (_utasController.text.trim().length < 8) {
      showGlassSnackBar(
        context,
        message: 'Утасны дугаараа бүрэн оруулна уу',
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
      await _khayagKhadgalya(
        result is Map ? Map<String, dynamic>.from(result) : null,
      );

      try {
        await SocketService.instance.connect();
      } catch (_) {}

      if (!mounted) return;
      setState(() => _isLoading = false);

      showGlassSnackBar(
        context,
        message: 'Гэр бүлийн гишүүнээр амжилттай бүртгэгдлээ',
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
      showGlassSnackBar(
        context,
        message: friendlyError(e, fallback: 'Гишүүнчлэл баталгаажуулж чадсангүй. Дахин оролдоно уу.'),
        icon: Icons.error_outline,
        iconColor: Colors.red,
      );
    }
  }

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
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back_ios_new_rounded,
            color: context.textPrimaryColor,
            size: 20.sp,
          ),
          onPressed: () => Navigator.pop(context),
        ),
        // Гарчгийг сумны хажууд тавив — өмнө биеийн дээд талд
        // тусдаа томоор байсан тул дэлгэцийн өндөр дэмий зарцуулдаг байв.
        titleSpacing: 0,
        title: Text(
          'Гишүүн баталгаажуулах',
          style: TextStyle(
            fontSize: 16.sp,
            fontWeight: FontWeight.w600,
            color: context.textPrimaryColor,
            letterSpacing: -0.3,
          ),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.symmetric(horizontal: 20.w),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 500),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    SizedBox(height: 10.h),
                    SizedBox(height: 28.h),

                    // Уригдсан дугаар — өмнө энд OTP байсан.
                    //
                    // Нэг код олон баазад давхардах боломжтой тул backend нь
                    // `utas` өгвөл урилгыг дугаараар нарийвчлан хайдаг.
                    _buildShoshgo('Утасны дугаар *'),
                    TextFormField(
                      controller: _utasController,
                      keyboardType: TextInputType.phone,
                      maxLength: 8,
                      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                      onChanged: (_) => setState(() {}),
                      validator: (utga) {
                        if ((utga ?? '').trim().length < 8) {
                          return 'Утасны дугаараа бүрэн оруулна уу';
                        }
                        return null;
                      },
                      style: TextStyle(
                        fontSize: 14.sp,
                        fontWeight: FontWeight.w600,
                        color: context.textPrimaryColor,
                        letterSpacing: 1.2,
                      ),
                      decoration: _talbariinChimeglel(
                        hint: '99112233',
                        icon: Icons.phone_iphone_rounded,
                        isDark: isDark,
                      ).copyWith(counterText: ''),
                    ),
                    SizedBox(height: 16.h),

                    // Урилгын код — өмнө хуудсын дээд талд байсан.
                    //
                    // Овог/Нэрийг хасав: тэднийг урьсан хүн урилга үүсгэхэдээ
                    // бөглөдөг тул дахин асуух шаардлагагүй.
                    _buildShoshgo('4 оронтой урилгын код'),
                    SizedBox(height: 6.h),
                    // Бүтэн өргөн — дээрх утасны талбартай ижил байх ёстой.
                    // Өмнө 270w-ээр хязгаарлаж төвлүүлсэн тул нарийн харагдаж байсан.
                    OtpCodeInput(
                      controller: _otpController,
                      focusNode: _otpFocusNode,
                      autofocus: false,
                      onChanged: (_) => setState(() {
                        _urilgaInfo = null;
                        _codeError = null;
                      }),
                      onCompleted: (_) => _shalgaya(),
                    ),
                    SizedBox(height: 16.h),

                    if (_isCheckingCode) ...[
                      SizedBox(height: 16.h),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          SizedBox(
                            width: 16.w,
                            height: 16.w,
                            child: const CircularProgressIndicator(
                              strokeWidth: 2,
                              color: AppColors.deepGreen,
                            ),
                          ),
                          SizedBox(width: 8.w),
                          Text(
                            'Урилгын мэдээлэл шалгаж байна...',
                            style: TextStyle(
                              fontSize: 12.sp,
                              color: context.textSecondaryColor,
                            ),
                          ),
                        ],
                      ),
                    ] else if (_urilgaInfo != null) ...[
                      SizedBox(height: 16.h),
                      _buildUrilgaKharuulakhCard(isDark),
                    ] else if (_codeError != null && _kod.length == 4) ...[
                      SizedBox(height: 12.h),
                      Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: 14.w,
                          vertical: 10.h,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.red.withValues(alpha: 0.08),
                          borderRadius: BorderRadius.circular(12.r),
                          border: Border.all(
                            color: Colors.red.withValues(alpha: 0.2),
                          ),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.error_outline_rounded,
                              color: Colors.redAccent,
                              size: 16.sp,
                            ),
                            SizedBox(width: 8.w),
                            Expanded(
                              child: Text(
                                _codeError!,
                                style: TextStyle(
                                  color: Colors.redAccent,
                                  fontSize: 12.sp,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
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
                          return '4 оронтой нууц код оруулна уу';
                        }
                        return null;
                      },
                      style: TextStyle(
                        fontSize: 15.sp,
                        fontWeight: FontWeight.w600,
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
                        fontWeight: FontWeight.w600,
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
                    SizedBox(height: 20.h),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildUrilgaKharuulakhCard(bool isDark) {
    final urisenNer = _urilgaInfo?['urisenNer'] ?? '';
    final urisenUtas = _urilgaInfo?['urisenUtas'] ?? '';
    final khayag = _urilgaInfo?['khayag'] ?? '';
    final kholboo = _urilgaInfo?['kholboo'] ?? '';

    return Container(
      padding: EdgeInsets.all(14.w),
      decoration: BoxDecoration(
        color: AppColors.deepGreen.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(
          color: AppColors.deepGreen.withValues(alpha: 0.25),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: EdgeInsets.all(8.w),
                decoration: BoxDecoration(
                  color: AppColors.deepGreen.withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.mark_email_read_rounded,
                  color: AppColors.deepGreen,
                  size: 18.sp,
                ),
              ),
              SizedBox(width: 10.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Урилга баталгаажлаа',
                      style: TextStyle(
                        fontSize: 13.sp,
                        fontWeight: FontWeight.w600,
                        color: AppColors.deepGreen,
                      ),
                    ),
                    if (kholboo.toString().isNotEmpty)
                      Text(
                        'Таныг "$kholboo"-аар бүртгэх урилга',
                        style: TextStyle(
                          fontSize: 11.5.sp,
                          color: context.textSecondaryColor,
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
          SizedBox(height: 10.h),
          Divider(
            height: 1,
            color: AppColors.deepGreen.withValues(alpha: 0.15),
          ),
          SizedBox(height: 10.h),
          if (urisenNer.toString().isNotEmpty || urisenUtas.toString().isNotEmpty)
            _buildInfoMuri(
              Icons.person_outline_rounded,
              'Урьсан:',
              [urisenNer, urisenUtas].where((s) => s.isNotEmpty).join(' - '),
            ),
          if (khayag.toString().isNotEmpty) ...[
            SizedBox(height: 6.h),
            _buildInfoMuri(
              Icons.home_work_outlined,
              'Хаяг:',
              khayag.toString(),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildInfoMuri(IconData icon, String shoshgo, String utga) {
    return Row(
      children: [
        Icon(icon, size: 15.sp, color: context.textSecondaryColor),
        SizedBox(width: 6.w),
        Text(
          shoshgo,
          style: TextStyle(
            fontSize: 12.sp,
            color: context.textSecondaryColor,
          ),
        ),
        SizedBox(width: 6.w),
        Expanded(
          child: Text(
            utga,
            style: TextStyle(
              fontSize: 12.sp,
              fontWeight: FontWeight.w600,
              color: context.textPrimaryColor,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  Widget _buildShoshgo(String utga) {
    return Padding(
      padding: EdgeInsets.only(left: 4.w, bottom: 8.h),
      child: Text(
        utga,
        style: TextStyle(
          fontSize: 12.sp,
          fontWeight: FontWeight.w600,
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
          ? Colors.white.withValues(alpha: 0.04)
          : Colors.black.withValues(alpha: 0.03),
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
        borderSide: const BorderSide(
          color: AppColors.deepGreen,
          width: 1.5,
        ),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14.r),
        borderSide: const BorderSide(
          color: Colors.redAccent,
          width: 1,
        ),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14.r),
        borderSide: const BorderSide(
          color: Colors.redAccent,
          width: 1.5,
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
                  fontWeight: FontWeight.w600,
                ),
              ),
      ),
    );
  }
}
