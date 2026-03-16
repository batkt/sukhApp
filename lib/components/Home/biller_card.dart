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
        child: Column(
          children: [
            // Premium Tile Container
            Expanded(
              child: Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF1E242C) : Colors.white,
                  borderRadius: BorderRadius.circular(22.r),
                  border: Border.all(
                    color: isDark 
                        ? Colors.white.withOpacity(0.08) 
                        : AppColors.deepGreen.withOpacity(0.08),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: isDark 
                          ? Colors.black.withOpacity(0.2) 
                          : Colors.black.withOpacity(0.04),
                      blurRadius: 15,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(22.r),
                  child: Stack(
                    children: [
                      // Subtle background accent/glow
                      Positioned(
                        right: -10,
                        top: -10,
                        child: Container(
                          width: 40.w,
                          height: 40.w,
                          decoration: BoxDecoration(
                            color: AppColors.deepGreen.withOpacity(0.05),
                            shape: BoxShape.circle,
                          ),
                        ),
                      ),
                      
                      // Logo content
                      Center(
                        child: Padding(
                          padding: EdgeInsets.all(16.w),
                          child: BillerUtils.buildBillerLogo(
                            rawBillerName,
                            transformedName: billerName,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            SizedBox(height: 10.h),
            // Title with improved typography
            Text(
              billerName,
              style: TextStyle(
                color: context.textPrimaryColor,
                fontSize: 11.sp,
                fontWeight: FontWeight.w700,
                height: 1.2,
                letterSpacing: -0.2,
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
                  fontWeight: FontWeight.w600,
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
