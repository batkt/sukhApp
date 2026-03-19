import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:sukh_app/constants/constants.dart';
import 'package:sukh_app/utils/theme_extensions.dart';
import 'package:sukh_app/widgets/standard_app_bar.dart';
import 'package:sukh_app/widgets/common/bg_painter.dart';

// FIX: Changed to StatelessWidget -> StatefulWidget is not needed,
// but we need async onTap handlers that can await push results and
// forward them back to the caller via context.pop(true).
class UtilityAddPage extends StatelessWidget {
  const UtilityAddPage({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = context.isDarkMode;

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: buildStandardAppBar(context, title: 'Төлбөр нэмэх'),
      body: CustomPaint(
        painter: SharedBgPainter(
          isDark: isDark,
          brandColor: AppColors.deepGreen,
        ),
        child: SafeArea(
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: 24.w),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                SizedBox(height: 40.h),
                _buildOptionCard(
                  context,
                  title: 'Хаягаар нэмэх',
                  subtitle: 'Өөрийн оршин суугаа хаягаар биллинг хайж холбох',
                  icon: Icons.location_on_rounded,
                  onTap: () async {
                    // FIX: Await the sub-page result
                    final result = await context.push<bool>(
                      '/address_selection?fromMenu=true',
                    );
                    // Removed context.pop(true) - let billing list page handle refresh on its own
                  },
                ),
                SizedBox(height: 20.h),
                _buildOptionCard(
                  context,
                  title: 'Хэрэглэгчийн кодоор нэмэх',
                  subtitle:
                      'Цахилгаан, СӨХ, Түрээс гэх мэт төлбөрийг кодоор хайх',
                  icon: Icons.qr_code_rounded,
                  onTap: () async {
                    // FIX: Same pattern for the code-input sub-page.
                    final result = await context.push<bool>(
                      '/utility-code-input',
                    );
                    // Removed context.pop(true) - let billing list page handle refresh on its own
                  },
                ),
                const Spacer(),
                Padding(
                  padding: EdgeInsets.only(bottom: 24.h),
                  child: Text(
                    'Та өөрийн бүртгүүлэх гэж буй үйлчилгээний төрлийг сонгоно уу.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: isDark ? Colors.white54 : Colors.black54,
                      fontSize: 12.sp,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildOptionCard(
    BuildContext context, {
    required String title,
    required String subtitle,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    final isDark = context.isDarkMode;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.all(20.w),
        decoration: BoxDecoration(
          color: isDark ? AppColors.darkSurface : Colors.white,
          borderRadius: BorderRadius.circular(24.r),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 15,
              offset: const Offset(0, 8),
            ),
          ],
          border: Border.all(
            color: AppColors.deepGreen.withOpacity(0.1),
            width: 1,
          ),
        ),
        child: Row(
          children: [
            Container(
              padding: EdgeInsets.all(12.w),
              decoration: BoxDecoration(
                color: AppColors.deepGreen.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: AppColors.deepGreen, size: 28.sp),
            ),
            SizedBox(width: 16.w),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 16.sp,
                      fontWeight: FontWeight.bold,
                      color: context.textPrimaryColor,
                    ),
                  ),
                  SizedBox(height: 4.h),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 12.sp,
                      color: context.textSecondaryColor,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.chevron_right_rounded,
              color: context.textSecondaryColor.withOpacity(0.3),
            ),
          ],
        ),
      ),
    );
  }
}
