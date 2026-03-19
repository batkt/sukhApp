import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:sukh_app/constants/constants.dart';
import 'package:sukh_app/utils/theme_extensions.dart';

class BillingBox extends StatelessWidget {
  final VoidCallback onTap;
  final String totalBalance;
  final String totalAldangi;

  const BillingBox({
    super.key,
    required this.onTap,
    required this.totalBalance,
    required this.totalAldangi,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = context.isDarkMode;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: EdgeInsets.all(16.w),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1A1F26) : Colors.white,
          borderRadius: BorderRadius.circular(24.r),
          boxShadow: [
            BoxShadow(
              color: (isDark ? Colors.black : AppColors.deepGreen).withOpacity(0.06),
              blurRadius: 20,
              offset: const Offset(0, 8),
            ),
          ],
          border: Border.all(
            color: isDark
                ? Colors.white.withOpacity(0.05)
                : AppColors.deepGreen.withOpacity(0.05),
            width: 1,
          ),
        ),
        child: Row(
          children: [
            // Logo Container with subtle glass effect or gradient
            Container(
              height: 56.h,
              width: 56.h,
              padding: EdgeInsets.all(10.w),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    AppColors.deepGreen.withOpacity(isDark ? 0.2 : 0.08),
                    AppColors.deepGreen.withOpacity(isDark ? 0.1 : 0.03),
                  ],
                ),
                borderRadius: BorderRadius.circular(16.r),
              ),
              child: Container(
                padding: EdgeInsets.all(8.w),
                decoration: BoxDecoration(
                  color: isDark ? Colors.white.withOpacity(0.1) : Colors.white,
                  borderRadius: BorderRadius.circular(12.r),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 8,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Icon(
                  Icons.account_balance_wallet_outlined,
                  color: AppColors.deepGreen,
                  size: 24.sp,
                ),
              ),
            ),
            SizedBox(width: 16.w),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'ТӨЛБӨР',
                    style: TextStyle(
                      color: context.textSecondaryColor,
                      fontSize: 11.sp,
                      fontWeight: FontWeight.w500,
                      letterSpacing: 0.5,
                    ),
                  ),
                  SizedBox(height: 4.h),
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Нийт үлдэгдэл',
                              style: TextStyle(
                                color: context.textSecondaryColor,
                                fontSize: 11.sp,
                                fontWeight: FontWeight.w400,
                              ),
                            ),
                            SizedBox(height: 2.h),
                            Text(
                              totalBalance,
                              style: TextStyle(
                                color: context.textPrimaryColor,
                                fontSize: 20.sp,
                                fontWeight: FontWeight.w700,
                                letterSpacing: -0.5,
                              ),
                            ),
                          ],
                        ),
                      ),
                      SizedBox(width: 12.w),
                      Container(
                        width: 1,
                        height: 40.h,
                        color: context.textSecondaryColor.withOpacity(0.2),
                      ),
                      SizedBox(width: 12.w),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Альданги',
                              style: TextStyle(
                                color: context.textSecondaryColor,
                                fontSize: 11.sp,
                                fontWeight: FontWeight.w400,
                              ),
                            ),
                            SizedBox(height: 2.h),
                            Text(
                              totalAldangi,
                              style: TextStyle(
                                color: context.textPrimaryColor,
                                fontSize: 20.sp,
                                fontWeight: FontWeight.w700,
                                letterSpacing: -0.5,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            Container(
              padding: EdgeInsets.all(8.w),
              decoration: BoxDecoration(
                color: isDark
                    ? Colors.white.withOpacity(0.05)
                    : const Color(0xFFF5F7FA),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.arrow_forward_ios_rounded,
                color: isDark
                    ? Colors.white70
                    : AppColors.deepGreen.withOpacity(0.6),
                size: 12.sp,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
