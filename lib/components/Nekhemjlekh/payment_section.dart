import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:sukh_app/constants/constants.dart';
import 'package:sukh_app/utils/theme_extensions.dart';

class PaymentSection extends StatelessWidget {
  final int selectedCount;
  final String totalSelectedAmount;
  final VoidCallback? onPaymentTap;

  const PaymentSection({
    super.key,
    required this.selectedCount,
    required this.totalSelectedAmount,
    this.onPaymentTap,
  });

  @override
  Widget build(BuildContext context) {
    final bool hasSelection = selectedCount > 0;
    final isSmall = MediaQuery.of(context).size.width < 375;
    final isVerySmall = MediaQuery.of(context).size.width < 340;
    final isDark = context.isDarkMode;

    return Padding(
      padding: EdgeInsets.fromLTRB(
        (isVerySmall ? 12.0 : (isSmall ? 16.0 : 20.0)).w,
        0,
        (isVerySmall ? 12.0 : (isSmall ? 16.0 : 20.0)).w,
        (isVerySmall ? 10.0 : 14.0).h,
      ),
      child: Container(
        padding: EdgeInsets.symmetric(
          horizontal: (isVerySmall ? 10.0 : (isSmall ? 12.0 : 14.0)).w,
          vertical: (isVerySmall ? 8.0 : (isSmall ? 9.0 : 10.0)).h,
        ),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF13201C) : const Color(0xFFEAF5F1),
          borderRadius: BorderRadius.circular(20.r),
          border: Border.all(
            color: hasSelection
                ? AppColors.deepGreen.withOpacity(0.3)
                : AppColors.deepGreen.withOpacity(0.12),
            width: 1.0,
          ),
          boxShadow: [
            BoxShadow(
              color: AppColors.deepGreen.withOpacity(hasSelection ? 0.12 : 0.04),
              blurRadius: hasSelection ? 16 : 8,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Row(
          children: [
            // Left icon container
            Container(
              width: (isVerySmall ? 32.0 : (isSmall ? 36.0 : 38.0)).w,
              height: (isVerySmall ? 32.0 : (isSmall ? 36.0 : 38.0)).w,
              decoration: BoxDecoration(
                color: AppColors.deepGreen,
                borderRadius: BorderRadius.circular(10.r),
              ),
              child: Icon(
                Icons.account_balance_wallet_outlined,
                color: Colors.white,
                size: (isVerySmall ? 16.0 : (isSmall ? 18.0 : 20.0)).sp,
              ),
            ),
            SizedBox(width: (isVerySmall ? 8.0 : (isSmall ? 10.0 : 12.0)).w),
            // Amount & Selection status
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    hasSelection ? totalSelectedAmount : '0.00₮',
                    style: TextStyle(
                      color: context.textPrimaryColor,
                      fontSize: (isVerySmall ? 14.5 : (isSmall ? 16.0 : 18.0)).sp,
                      fontWeight: FontWeight.w700,
                      letterSpacing: -0.5,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  SizedBox(height: 1.h),
                  Text(
                    hasSelection
                        ? '$selectedCount төлбөр сонгогдсон'
                        : 'Төлбөр сонгоно уу',
                    style: TextStyle(
                      color: context.textSecondaryColor,
                      fontSize: (isVerySmall ? 9.5 : (isSmall ? 10.5 : 11.5)).sp,
                      fontWeight: FontWeight.w500,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            SizedBox(width: (isVerySmall ? 6.0 : 8.0).w),
            // "Төлөх >" action button
            GestureDetector(
              onTap: hasSelection ? onPaymentTap : null,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: EdgeInsets.symmetric(
                  horizontal: (isVerySmall ? 10.0 : (isSmall ? 12.0 : 15.0)).w,
                  vertical: (isVerySmall ? 7.0 : (isSmall ? 8.5 : 9.5)).h,
                ),
                decoration: BoxDecoration(
                  color: hasSelection
                      ? AppColors.deepGreen
                      : AppColors.deepGreen.withOpacity(0.35),
                  borderRadius: BorderRadius.circular(100),
                  boxShadow: hasSelection
                      ? [
                          BoxShadow(
                            color: AppColors.deepGreen.withOpacity(0.35),
                            blurRadius: 10,
                            offset: const Offset(0, 3),
                          ),
                        ]
                      : null,
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.receipt_outlined,
                      color: Colors.white,
                      size: (isVerySmall ? 13.0 : (isSmall ? 14.0 : 15.5)).sp,
                    ),
                    SizedBox(width: 5.w),
                    Text(
                      'Төлөх',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: (isVerySmall ? 11.0 : (isSmall ? 12.0 : 13.0)).sp,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    SizedBox(width: 2.w),
                    Icon(
                      Icons.chevron_right_rounded,
                      color: Colors.white,
                      size: (isVerySmall ? 14.0 : (isSmall ? 15.0 : 16.5)).sp,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
