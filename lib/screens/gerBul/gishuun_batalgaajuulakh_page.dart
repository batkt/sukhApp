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

  // 4 оронтой кодын 4 тусдаа controller, focus node
  final List<TextEditingController> _kodControllers =
      List.generate(4, (_) => TextEditingController());
  final List<FocusNode> _kodFocusNodes =
      List.generate(4, (_) => FocusNode());

  // Хэрэглэгч өөрийн нэрээ бөглөх талбарууд
  final _ovogController = TextEditingController();
  final _nerController = TextEditingController();

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
      final chars = widget.initialCode!.trim().split('');
      for (var i = 0; i < 4 && i < chars.length; i++) {
        _kodControllers[i].text = chars[i];
      }
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (_kod.length == 4) {
          _shalgaya();
        }
      });
    }
  }

  @override
  void dispose() {
    for (final c in _kodControllers) {
      c.dispose();
    }
    for (final f in _kodFocusNodes) {
      f.dispose();
    }
    _ovogController.dispose();
    _nerController.dispose();
    _nuutsUgController.dispose();
    _davtakhController.dispose();
    super.dispose();
  }

  String get _kod => _kodControllers.map((c) => c.text).join();

  bool get _bugdBugluusun =>
      _kod.length == 4 &&
      _nerController.text.trim().isNotEmpty &&
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
        _codeError = e.toString().replaceAll('Exception: ', '');
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

    if (_nerController.text.trim().isEmpty) {
      showGlassSnackBar(
        context,
        message: 'Нэрээ оруулна уу',
        icon: Icons.error_outline,
        iconColor: Colors.red,
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final khariu = await GerBulService.batalgaajuulya(
        code: _kod,
        ovog: _ovogController.text.trim(),
        ner: _nerController.text.trim(),
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
        message: e.toString().replaceAll('Exception: ', ''),
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
                    Center(
                      child: Container(
                        width: 72.w,
                        height: 72.w,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              AppColors.deepGreen.withValues(alpha: 0.15),
                              AppColors.deepGreen.withValues(alpha: 0.05),
                            ],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: AppColors.deepGreen.withValues(alpha: 0.3),
                            width: 1.5,
                          ),
                        ),
                        child: Icon(
                          Icons.how_to_reg_rounded,
                          size: 34.sp,
                          color: AppColors.deepGreen,
                        ),
                      ),
                    ),
                    SizedBox(height: 20.h),

                    Text(
                      'Гэр бүлийн гишүүн баталгаажуулах',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 21.sp,
                        fontWeight: FontWeight.w700,
                        color: context.textPrimaryColor,
                        letterSpacing: -0.5,
                      ),
                    ),
                    SizedBox(height: 8.h),
                    Text(
                      'Танд ирсэн 4 оронтой урилгын кодыг оруулж, нэр болон нэвтрэх шинэ нууц кодоо тохируулна уу.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 13.sp,
                        color: context.textSecondaryColor,
                        height: 1.45,
                      ),
                    ),
                    SizedBox(height: 28.h),

                    _buildShoshgo('4 оронтой урилгын код'),
                    SizedBox(height: 6.h),

                    // 4 оронтой код оруулах нүднүүд - тусдаа давхар хүрээгүй
                    Center(
                      child: SizedBox(
                        width: 270.w,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            for (var i = 0; i < 4; i++)
                              _buildKodBox(i, isDark),
                          ],
                        ),
                      ),
                    ),

                    // Урилгын эзнийг шалгасан мэдээллийн хэсэг
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

                    // Хэрэглэгч өөрийн Овог, Нэрийг бөглөх хэсэг
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _buildShoshgo('Овог (заавал биш)'),
                              TextFormField(
                                controller: _ovogController,
                                textCapitalization: TextCapitalization.words,
                                onChanged: (_) => setState(() {}),
                                style: TextStyle(
                                  fontSize: 14.sp,
                                  fontWeight: FontWeight.w600,
                                  color: context.textPrimaryColor,
                                ),
                                decoration: _talbariinChimeglel(
                                  hint: 'Овог',
                                  icon: Icons.badge_outlined,
                                  isDark: isDark,
                                ),
                              ),
                            ],
                          ),
                        ),
                        SizedBox(width: 12.w),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _buildShoshgo('Таны нэр *'),
                              TextFormField(
                                controller: _nerController,
                                textCapitalization: TextCapitalization.words,
                                onChanged: (_) => setState(() {}),
                                validator: (utga) {
                                  if ((utga ?? '').trim().isEmpty) {
                                    return 'Нэрээ оруулна уу';
                                  }
                                  return null;
                                },
                                style: TextStyle(
                                  fontSize: 14.sp,
                                  fontWeight: FontWeight.w600,
                                  color: context.textPrimaryColor,
                                ),
                                decoration: _talbariinChimeglel(
                                  hint: 'Нэр',
                                  icon: Icons.person_outline_rounded,
                                  isDark: isDark,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 16.h),

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
                        fontWeight: FontWeight.w700,
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

  Widget _buildKodBox(int index, bool isDark) {
    final isFocused = _kodFocusNodes[index].hasFocus;
    final hasValue = _kodControllers[index].text.isNotEmpty;

    return SizedBox(
      width: 58.w,
      height: 64.h,
      child: KeyboardListener(
        focusNode: FocusNode(),
        onKeyEvent: (KeyEvent event) {
          if (event is KeyDownEvent &&
              event.logicalKey == LogicalKeyboardKey.backspace) {
            if (_kodControllers[index].text.isEmpty && index > 0) {
              _kodControllers[index - 1].clear();
              _kodFocusNodes[index - 1].requestFocus();
              setState(() {
                _urilgaInfo = null;
                _codeError = null;
              });
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
            fontSize: 24.sp,
            fontWeight: FontWeight.bold,
            height: 1.2,
          ),
          decoration: InputDecoration(
            counterText: '',
            contentPadding: EdgeInsets.symmetric(vertical: 16.h),
            filled: true,
            fillColor: isDark
                ? (isFocused
                    ? AppColors.deepGreen.withValues(alpha: 0.12)
                    : Colors.white.withValues(alpha: 0.05))
                : (isFocused
                    ? AppColors.deepGreen.withValues(alpha: 0.06)
                    : const Color(0xFFF5F7FA)),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16.r),
              borderSide: BorderSide(
                color: isDark
                    ? Colors.white.withValues(alpha: 0.1)
                    : Colors.black.withValues(alpha: 0.08),
                width: 1.2,
              ),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16.r),
              borderSide: BorderSide(
                color: hasValue
                    ? AppColors.deepGreen.withValues(alpha: 0.6)
                    : (isDark
                        ? Colors.white.withValues(alpha: 0.12)
                        : Colors.black.withValues(alpha: 0.08)),
                width: hasValue ? 1.5 : 1.2,
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16.r),
              borderSide: const BorderSide(
                color: AppColors.deepGreen,
                width: 2.0,
              ),
            ),
          ),
          onChanged: (val) {
            if (val.length > 1) {
              val = val.substring(val.length - 1);
              _kodControllers[index].text = val;
              _kodControllers[index].selection =
                  TextSelection.fromPosition(TextPosition(offset: val.length));
            }
            setState(() {
              _urilgaInfo = null;
              _codeError = null;
            });
            if (val.isNotEmpty) {
              if (index < 3) {
                _kodFocusNodes[index + 1].requestFocus();
              } else {
                _kodFocusNodes[index].unfocus();
                _shalgaya();
              }
            }
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
                  fontWeight: FontWeight.w700,
                ),
              ),
      ),
    );
  }
}
