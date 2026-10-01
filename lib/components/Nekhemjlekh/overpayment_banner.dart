import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:sukh_app/utils/format_util.dart';
import 'package:sukh_app/utils/theme_extensions.dart';

/// Гэрээний нийт үлдэгдэл сөрөг (илүү төлсөн) үед нэхэмжлэхийн дэлгэц дээр
/// харуулах мэдээлэл. Үлдэгдэл нь вэбтэй ижил ledger-ээс (`uldegdelBodyo`)
/// бодогдсон тул илүү төлөлт нь дараагийн нэхэмжлэхээс FIFO-оор хасагдана.
class OverpaymentBanner extends StatelessWidget {
  /// Илүү төлсөн дүн (эерэг тоо)
  final double amount;

  const OverpaymentBanner({super.key, required this.amount});

  static const Color _color = Color(0xFF10B981);

  @override
  Widget build(BuildContext context) {
    final isDark = context.isDarkMode;
    final width = MediaQuery.of(context).size.width;
    final isSmall = width < 375;
    final isVerySmall = width < 340;

    return Padding(
      padding: EdgeInsets.fromLTRB(
        (isVerySmall ? 12.0 : (isSmall ? 16.0 : 20.0)).w,
        0,
        (isVerySmall ? 12.0 : (isSmall ? 16.0 : 20.0)).w,
        (isVerySmall ? 8.0 : 10.0).h,
      ),
      child: Container(
        padding: EdgeInsets.symmetric(
          horizontal: (isVerySmall ? 10.0 : (isSmall ? 12.0 : 14.0)).w,
          vertical: (isVerySmall ? 9.0 : 11.0).h,
        ),
        decoration: BoxDecoration(
          color: _color.withOpacity(isDark ? 0.14 : 0.08),
          borderRadius: BorderRadius.circular(16.r),
          border: Border.all(
            color: _color.withOpacity(isDark ? 0.35 : 0.25),
            width: 1,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: (isVerySmall ? 30.0 : 34.0).w,
              height: (isVerySmall ? 30.0 : 34.0).w,
              decoration: BoxDecoration(
                color: _color.withOpacity(isDark ? 0.22 : 0.15),
                borderRadius: BorderRadius.circular(10.r),
              ),
              child: Icon(
                Icons.savings_rounded,
                color: _color,
                size: (isVerySmall ? 16.0 : 18.0).sp,
              ),
            ),
            SizedBox(width: (isVerySmall ? 8.0 : 10.0).w),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    children: [
                      Text(
                        'Илүү төлөлт',
                        style: TextStyle(
                          color: context.textPrimaryColor,
                          fontSize: (isVerySmall ? 11.5 : 12.5).sp,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const Spacer(),
                      Text(
                        '${formatNumber(amount, 2)}₮',
                        style: TextStyle(
                          color: _color,
                          fontSize: (isVerySmall ? 13.5 : (isSmall ? 14.5 : 16.0)).sp,
                          fontWeight: FontWeight.w700,
                          letterSpacing: -0.3,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 2.h),
                  Text(
                    'Та төлөх ёстой дүнгээс илүү төлсөн байна. Энэ дүн таны дараагийн нэхэмжлэхээс автоматаар хасагдана.',
                    style: TextStyle(
                      color: context.textSecondaryColor,
                      fontSize: (isVerySmall ? 9.5 : 10.5).sp,
                      fontWeight: FontWeight.w500,
                      height: 1.3,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
