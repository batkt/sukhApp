import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:sukh_app/constants/constants.dart';
import 'package:sukh_app/utils/theme_extensions.dart';

/// Улсын дугаарын (1234УБА) үсгийн хэсэгт зориулсан апп доторх монгол
/// кирилл гар.
///
/// ЯАГААД: утасны системийн гарын хэлийг аппаас солих API байхгүй —
/// `TextInputType` нь зөвхөн гарын төрлийг (тоо/текст) сонгодог. Тиймээс 4
/// цифр орсны дараа талбарын `keyboardType`-ийг [TextInputType.none] болгож
/// системийн гарыг нууж, оронд нь энэ гарыг шууд харуулна. Ингэснээр
/// хэрэглэгч англи гар руу үсэрч, хэл солих шаардлагагүй болно.
///
/// Байрлал нь стандарт монгол кирилл гарын дарааллаар.
class MongolPlateKeyboard extends StatelessWidget {
  final TextEditingController controller;

  /// Дугаарын нийт урт (4 цифр + 3 үсэг)
  final int maxLength;

  /// Эхний хэдэн тэмдэгт цифр байх
  final int digitCount;

  /// «Болсон» товч дарахад (ихэвчлэн focus-ийг авна). null бол товч харагдахгүй.
  final VoidCallback? onDone;

  const MongolPlateKeyboard({
    super.key,
    required this.controller,
    this.maxLength = 7,
    this.digitCount = 4,
    this.onDone,
  });

  static const List<List<String>> _murnuud = [
    ['Ф', 'Ц', 'У', 'Ж', 'Э', 'Н', 'Г', 'Ш', 'Ү', 'З', 'К'],
    ['Й', 'Ы', 'Б', 'Ө', 'А', 'Х', 'Р', 'О', 'Л', 'Д', 'П'],
    ['Я', 'Ч', 'Ё', 'С', 'М', 'И', 'Т', 'Ь', 'В', 'Ю'],
    ['Е', 'Щ', 'Ъ'],
  ];

  /// Тухайн талбарт монгол гарыг харуулах эсэх (4 цифр орсны дараа)
  static bool kheregtei(String text, {int digitCount = 4}) =>
      text.length >= digitCount;

  /// Талбарын keyboardType: цифрийн хэсэгт тоон гар, үсгийн хэсэгт
  /// системийн гарыг нууна.
  static TextInputType keyboardTypeFor(String text, {int digitCount = 4}) =>
      text.length < digitCount ? TextInputType.number : TextInputType.none;

  void _useg(String u) {
    final text = controller.text;
    if (text.length >= maxLength) return;
    HapticFeedback.selectionClick();
    final shine = text + u;
    controller.value = TextEditingValue(
      text: shine,
      selection: TextSelection.collapsed(offset: shine.length),
    );
  }

  void _ustga() {
    final text = controller.text;
    if (text.isEmpty) return;
    HapticFeedback.selectionClick();
    final shine = text.substring(0, text.length - 1);
    controller.value = TextEditingValue(
      text: shine,
      selection: TextSelection.collapsed(offset: shine.length),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = context.isDarkMode;
    final text = controller.text;
    final usegToo = (text.length - digitCount).clamp(0, maxLength - digitCount);
    final duussan = text.length >= maxLength;

    return Container(
      margin: EdgeInsets.only(top: 10.h),
      padding: EdgeInsets.fromLTRB(6.w, 8.h, 6.w, 8.h),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E242C) : const Color(0xFFE9EDF2),
        borderRadius: BorderRadius.circular(14.r),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
            padding: EdgeInsets.fromLTRB(6.w, 0, 6.w, 6.h),
            child: Row(
              children: [
                Icon(
                  Icons.keyboard_alt_outlined,
                  size: 13.sp,
                  color: context.textSecondaryColor,
                ),
                SizedBox(width: 5.w),
                Expanded(
                  child: Text(
                    duussan
                        ? 'Дугаар бүрэн орлоо'
                        : 'Монгол үсэг сонгоно уу ($usegToo/${maxLength - digitCount})',
                    style: TextStyle(
                      color: context.textSecondaryColor,
                      fontSize: 11.sp,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ),
          for (final mur in _murnuud.take(3))
            _buildMur(context, mur, duussan, isDark),
          // Сүүлийн мөр: үлдсэн үсэг + устгах + болсон
          Padding(
            padding: EdgeInsets.symmetric(vertical: 3.h),
            child: Row(
              children: [
                for (final u in _murnuud[3])
                  Expanded(child: _buildTovch(context, u, duussan, isDark)),
                Expanded(
                  flex: onDone != null ? 3 : 8,
                  child: _buildUildelTovch(
                    context,
                    isDark: isDark,
                    onTap: _ustga,
                    child: Icon(
                      Icons.backspace_outlined,
                      size: 18.sp,
                      color: context.textPrimaryColor,
                    ),
                  ),
                ),
                if (onDone != null)
                  Expanded(
                    flex: 5,
                    child: _buildUildelTovch(
                      context,
                      isDark: isDark,
                      filled: true,
                      onTap: () {
                        HapticFeedback.lightImpact();
                        onDone?.call();
                      },
                      child: Text(
                        'Болсон',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 13.sp,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMur(
    BuildContext context,
    List<String> mur,
    bool duussan,
    bool isDark,
  ) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 3.h),
      child: Row(
        children: [
          for (final u in mur)
            Expanded(child: _buildTovch(context, u, duussan, isDark)),
          // Мөрүүдийн өргөнийг тэнцүүлнэ (11 / 11 / 10)
          if (mur.length < 11) const Expanded(child: SizedBox()),
        ],
      ),
    );
  }

  Widget _buildTovch(
    BuildContext context,
    String u,
    bool duussan,
    bool isDark,
  ) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 2.w),
      child: Material(
        color: duussan
            ? (isDark
                  ? Colors.white.withOpacity(0.04)
                  : Colors.white.withOpacity(0.5))
            : (isDark ? const Color(0xFF2E3640) : Colors.white),
        borderRadius: BorderRadius.circular(6.r),
        elevation: duussan ? 0 : 0.5,
        child: InkWell(
          borderRadius: BorderRadius.circular(6.r),
          onTap: duussan ? null : () => _useg(u),
          child: SizedBox(
            height: 40.h,
            child: Center(
              child: Text(
                u,
                style: TextStyle(
                  color: duussan
                      ? context.textSecondaryColor.withOpacity(0.5)
                      : context.textPrimaryColor,
                  fontSize: 16.sp,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildUildelTovch(
    BuildContext context, {
    required bool isDark,
    required VoidCallback onTap,
    required Widget child,
    bool filled = false,
  }) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 2.w),
      child: Material(
        color: filled
            ? AppColors.deepGreen
            : (isDark ? const Color(0xFF3A434E) : const Color(0xFFD3D9E0)),
        borderRadius: BorderRadius.circular(6.r),
        child: InkWell(
          borderRadius: BorderRadius.circular(6.r),
          onTap: onTap,
          child: SizedBox(
            height: 40.h,
            child: Center(child: child),
          ),
        ),
      ),
    );
  }
}
