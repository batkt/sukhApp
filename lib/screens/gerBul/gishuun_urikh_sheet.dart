import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:sukh_app/constants/constants.dart';
import 'package:sukh_app/models/ger_buliin_gishuun_model.dart';
import 'package:sukh_app/services/ger_bul_service.dart';
import 'package:sukh_app/utils/theme_extensions.dart';
import 'package:sukh_app/widgets/glass_snackbar.dart';

/// Гэр бүлийн гишүүн урих цонх.
/// Амжилттай илгээвэл `true` буцаана.
Future<bool?> showGishuunUrikhSheet(BuildContext context) {
  return showModalBottomSheet<bool>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => const _GishuunUrikhSheet(),
  );
}

class _GishuunUrikhSheet extends StatefulWidget {
  const _GishuunUrikhSheet();

  @override
  State<_GishuunUrikhSheet> createState() => _GishuunUrikhSheetState();
}

class _GishuunUrikhSheetState extends State<_GishuunUrikhSheet> {
  final _formKey = GlobalKey<FormState>();
  final _utasController = TextEditingController();
  final _ovogController = TextEditingController();
  final _nerController = TextEditingController();

  String _kholboo = GishuuniiKholboo.bugd.first;
  String _erkh = GishuuniiErkh.kharakhTuluk;
  bool _isLoading = false;

  @override
  void dispose() {
    _utasController.dispose();
    _ovogController.dispose();
    _nerController.dispose();
    super.dispose();
  }

  Future<void> _ilgeeye() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    setState(() => _isLoading = true);
    try {
      await GerBulService.gishuunUriya(
        utas: _utasController.text.trim(),
        ovog: _ovogController.text.trim(),
        ner: _nerController.text.trim(),
        kholboo: _kholboo,
        erkh: _erkh,
      );

      if (!mounted) return;
      Navigator.pop(context, true);
      showGlassSnackBar(
        context,
        message:
            '${_utasController.text.trim()} руу баталгаажуулах код илгээлээ',
        icon: Icons.sms_outlined,
        iconColor: Colors.green,
        duration: const Duration(seconds: 3),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      showGlassSnackBar(
        context,
        message: e.toString(),
        icon: Icons.error_outline,
        iconColor: Colors.red,
        duration: const Duration(seconds: 3),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = context.isDarkMode;

    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: Container(
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF15181C) : Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24.r)),
        ),
        padding: EdgeInsets.fromLTRB(20.w, 12.h, 20.w, 24.h),
        child: SingleChildScrollView(
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Center(
                  child: Container(
                    width: 40.w,
                    height: 4.h,
                    decoration: BoxDecoration(
                      color: context.inputGrayColor.withOpacity(0.4),
                      borderRadius: BorderRadius.circular(4.r),
                    ),
                  ),
                ),
                SizedBox(height: 20.h),

                Text(
                  'Гэр бүлийн гишүүн урих',
                  style: TextStyle(
                    fontSize: 18.sp,
                    fontWeight: FontWeight.w800,
                    color: context.textPrimaryColor,
                  ),
                ),
                SizedBox(height: 6.h),
                Text(
                  'Уригдсан дугаар руу 4 оронтой код очно. Тэр хүн кодоо '
                  'оруулж, нууц кодоо тохируулснаар таны мэдээллийг харна.',
                  style: TextStyle(
                    fontSize: 12.5.sp,
                    height: 1.5,
                    color: context.textSecondaryColor,
                  ),
                ),
                SizedBox(height: 22.h),

                _buildShoshgo('Утасны дугаар'),
                _buildTalbar(
                  controller: _utasController,
                  hint: '99112233',
                  keyboardType: TextInputType.phone,
                  maxLength: 8,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  icon: Icons.phone_iphone_rounded,
                  validator: (utga) {
                    final tseverlesen = (utga ?? '').trim();
                    if (tseverlesen.isEmpty) return 'Утасны дугаар оруулна уу';
                    if (tseverlesen.length != 8) {
                      return '8 оронтой дугаар оруулна уу';
                    }
                    return null;
                  },
                ),
                SizedBox(height: 14.h),

                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          _buildShoshgo('Овог'),
                          _buildTalbar(
                            controller: _ovogController,
                            hint: 'Овог',
                            icon: Icons.badge_outlined,
                          ),
                        ],
                      ),
                    ),
                    SizedBox(width: 12.w),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          _buildShoshgo('Нэр'),
                          _buildTalbar(
                            controller: _nerController,
                            hint: 'Нэр',
                            icon: Icons.person_outline_rounded,
                            validator: (utga) =>
                                (utga ?? '').trim().isEmpty ? 'Нэр оруулна уу' : null,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 14.h),

                _buildShoshgo('Таны юу болох'),
                _buildKholbooSongolt(),
                SizedBox(height: 18.h),

                _buildShoshgo('Эрх'),
                _buildErkhSongolt(),
                SizedBox(height: 24.h),

                _buildIlgeekhTovch(),
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

  Widget _buildTalbar({
    required TextEditingController controller,
    required String hint,
    required IconData icon,
    TextInputType? keyboardType,
    int? maxLength,
    List<TextInputFormatter>? inputFormatters,
    String? Function(String?)? validator,
  }) {
    final isDark = context.isDarkMode;
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      maxLength: maxLength,
      inputFormatters: inputFormatters,
      validator: validator,
      style: TextStyle(
        fontSize: 14.sp,
        color: context.textPrimaryColor,
        fontWeight: FontWeight.w600,
      ),
      decoration: InputDecoration(
        counterText: '',
        hintText: hint,
        hintStyle: TextStyle(
          fontSize: 14.sp,
          color: context.inputGrayColor,
          fontWeight: FontWeight.w400,
        ),
        prefixIcon: Icon(icon, size: 18.sp, color: context.inputGrayColor),
        filled: true,
        fillColor: isDark
            ? Colors.white.withOpacity(0.04)
            : Colors.black.withOpacity(0.03),
        contentPadding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 14.h),
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
      ),
    );
  }

  Widget _buildKholbooSongolt() {
    return Wrap(
      spacing: 8.w,
      runSpacing: 8.h,
      children: GishuuniiKholboo.bugd.map((kholboo) {
        final songogdson = _kholboo == kholboo;
        return GestureDetector(
          onTap: () => setState(() => _kholboo = kholboo),
          child: Container(
            padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 8.h),
            decoration: BoxDecoration(
              color: songogdson
                  ? AppColors.deepGreen
                  : AppColors.deepGreen.withOpacity(0.06),
              borderRadius: BorderRadius.circular(20.r),
              border: Border.all(
                color: songogdson
                    ? AppColors.deepGreen
                    : AppColors.deepGreen.withOpacity(0.15),
              ),
            ),
            child: Text(
              kholboo,
              style: TextStyle(
                fontSize: 12.5.sp,
                fontWeight: FontWeight.w700,
                color: songogdson ? Colors.white : AppColors.deepGreen,
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildErkhSongolt() {
    return Column(
      children: GishuuniiErkh.bugd.map((erkh) {
        final songogdson = _erkh == erkh;
        final isDark = context.isDarkMode;
        return GestureDetector(
          onTap: () => setState(() => _erkh = erkh),
          child: Container(
            margin: EdgeInsets.only(bottom: 8.h),
            padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 12.h),
            decoration: BoxDecoration(
              color: songogdson
                  ? AppColors.deepGreen.withOpacity(0.08)
                  : (isDark
                        ? Colors.white.withOpacity(0.03)
                        : Colors.black.withOpacity(0.02)),
              borderRadius: BorderRadius.circular(14.r),
              border: Border.all(
                color: songogdson
                    ? AppColors.deepGreen
                    : Colors.transparent,
                width: 1.5,
              ),
            ),
            child: Row(
              children: [
                Icon(
                  songogdson
                      ? Icons.radio_button_checked_rounded
                      : Icons.radio_button_unchecked_rounded,
                  size: 20.sp,
                  color: songogdson
                      ? AppColors.deepGreen
                      : context.inputGrayColor,
                ),
                SizedBox(width: 12.w),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        erkh,
                        style: TextStyle(
                          fontSize: 13.5.sp,
                          fontWeight: FontWeight.w700,
                          color: context.textPrimaryColor,
                        ),
                      ),
                      SizedBox(height: 2.h),
                      Text(
                        GishuuniiErkh.tailbar(erkh),
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
          ),
        );
      }).toList(),
    );
  }

  Widget _buildIlgeekhTovch() {
    return GestureDetector(
      onTap: _isLoading ? null : _ilgeeye,
      child: Container(
        height: 52.h,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: _isLoading ? context.inputGrayColor : AppColors.deepGreen,
          borderRadius: BorderRadius.circular(16.r),
        ),
        child: _isLoading
            ? SizedBox(
                width: 20.w,
                height: 20.w,
                child: const CircularProgressIndicator(
                  color: Colors.white,
                  strokeWidth: 2,
                ),
              )
            : Text(
                'Урилга илгээх',
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
