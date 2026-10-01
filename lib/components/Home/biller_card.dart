import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:sukh_app/components/Home/biller_utils.dart';
import 'package:sukh_app/utils/theme_extensions.dart';
import 'package:sukh_app/constants/constants.dart';

class BillerCard extends StatelessWidget {
  final Map<String, dynamic> biller;
  final bool isSquare;
  final VoidCallback? onTapCallback;

  const BillerCard({
    super.key,
    required this.biller,
    this.isSquare = true,
    this.onTapCallback,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = context.isDarkMode;
    final rawBillerName =
        biller['billerName']?.toString() ??
        biller['name']?.toString() ??
        'Биллер';
    final billerName = BillerUtils.transformBillerName(rawBillerName);
    final description = biller['description']?.toString() ?? '';
    final billerCode =
        biller['billerCode']?.toString() ?? biller['code']?.toString() ?? '';

    if (isSquare) {
      return GestureDetector(
        onTap: () {
          onTapCallback?.call();
          context.push(
            '/biller-detail',
            extra: {
              'billerCode': billerCode,
              'billerName': billerName,
              'description': description,
            },
          );
        },
        // iOS апп-icon маяг: цагаан squircle дотор лого, доор нь нэр
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 54.w,
              height: 54.w,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(15.r),
                border: Border.all(color: Colors.black.withOpacity(0.06)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(isDark ? 0.25 : 0.06),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(15.r),
                child: Padding(
                  padding: EdgeInsets.all(6.w),
                  child: BillerUtils.buildBillerLogo(
                    rawBillerName,
                    transformedName: billerName,
                  ),
                ),
              ),
            ),
            SizedBox(height: 7.h),
            Text(
              billerName,
              style: TextStyle(
                color: context.textPrimaryColor,
                fontSize: 11.5.sp,
                fontWeight: FontWeight.w500,
              ),
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      );
    } else {
      // Rectangular card
      return GestureDetector(
        onTap: () {
          context.push(
            '/biller-detail',
            extra: {
              'billerCode': billerCode,
              'billerName': billerName,
              'description': description,
            },
          );
        },
        child: Container(
          padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1A1F26) : Colors.white,
            borderRadius: BorderRadius.circular(14.r),
            border: Border.all(
              color: isDark 
                  ? Colors.white.withOpacity(0.1) 
                  : AppColors.deepGreen.withOpacity(0.12),
              width: 1,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              SizedBox(
                width: 32.w,
                height: 32.w,
                child: BillerUtils.buildBillerLogo(
                  rawBillerName,
                  transformedName: billerName,
                ),
              ),
              SizedBox(width: 12.w),
              Text(
                billerName,
                style: TextStyle(
                  color: context.textPrimaryColor,
                  fontSize: 12.sp,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      );
    }
  }
}
