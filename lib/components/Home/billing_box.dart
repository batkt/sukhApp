import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:sukh_app/constants/constants.dart';
import 'package:sukh_app/utils/theme_extensions.dart';
import 'package:sukh_app/widgets/app_logo.dart';

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

    // Parse numeric values to determine display mode
    final double numericBalance = double.tryParse(
          totalBalance.replaceAll(',', '').replaceAll('₮', '').trim(),
        ) ??
        0.0;
    final bool isCredit = numericBalance < 0;
    final bool hasBalance = numericBalance != 0;
    final bool hasAldangi = totalAldangi != '0' && totalAldangi.isNotEmpty;

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
              color: (isDark ? Colors.black : AppColors.deepGreen)
                  .withOpacity(0.06),
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
            Container(
              height: 56.h,
              width: 56.h,
              padding: EdgeInsets.all(10.w),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    AppColors.deepGreen.withOpacity(isDark ? 0.2 : 0.15),
                    AppColors.deepGreen.withOpacity(isDark ? 0.1 : 0.08),
                  ],
                ),
                borderRadius: BorderRadius.circular(16.r),
                border: Border.all(
                  color: isDark
                      ? Colors.white.withOpacity(0.05)
                      : AppColors.deepGreen.withOpacity(0.1),
                  width: 1,
                ),
              ),
              child: ValueListenableBuilder<String>(
                valueListenable: AppLogoNotifier.currentIcon,
                builder: (context, iconName, _) {
                  return Image.asset(
                    AppLogoAssets.getAssetPath(iconName),
                    fit: BoxFit.contain,
                  );
                },
              ),
            ),
            SizedBox(width: 16.w),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Байрны төлбөр',
                    style: TextStyle(
                      fontSize: 15.sp,
                      color: context.textPrimaryColor,
                      letterSpacing: -0.2,
                    ),
                  ),
                  SizedBox(height: 4.h),
                  if (hasBalance) ...[
                    if (isCredit) ...[
                      Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: 8.w,
                          vertical: 3.h,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.green.withOpacity(0.12),
                          borderRadius: BorderRadius.circular(8.r),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.trending_up_rounded,
                              color: Colors.green[600],
                              size: 12.sp,
                            ),
                            SizedBox(width: 4.w),
                            Text(
                              '+${totalBalance.replaceAll('-', '')}₮ Илүү төлөлт',
                              style: TextStyle(
                                fontSize: 11.sp,
                                fontWeight: FontWeight.w700,
                                color: Colors.green[600],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ] else ...[
                      Row(
                        children: [
                          Text(
                            '$totalBalance₮',
                            style: TextStyle(
                              fontSize: 13.sp,
                              fontWeight: FontWeight.w700,
                              color: AppColors.error,
                            ),
                          ),
                          if (hasAldangi) ...[
                            SizedBox(width: 8.w),
                            Text(
                              '· Алданги: $totalAldangi₮',
                              style: TextStyle(
                                fontSize: 11.sp,
                                color: AppColors.error.withOpacity(0.7),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ],
                  ] else ...[
                    Text(
                      'Төлбөрийн дэлгэрэнгүй харах',
                      style: TextStyle(
                        fontSize: 11.sp,
                        color: context.textSecondaryColor.withOpacity(0.6),
                      ),
                    ),
                  ],
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
