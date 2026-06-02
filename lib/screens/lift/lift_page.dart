import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:sukh_app/constants/constants.dart';
import 'package:sukh_app/widgets/standard_app_bar.dart' show buildStandardAppBar;
import 'package:sukh_app/utils/theme_extensions.dart';

class LiftPage extends StatelessWidget {
  const LiftPage({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? AppColors.darkBackground : Colors.white,
      appBar: buildStandardAppBar(
        context,
        title: 'Лифт',
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: isDark
                ? [AppColors.darkBackground, AppColors.darkBackground.withOpacity(0.9)]
                : [Colors.white, const Color(0xFFF5F9F7), const Color(0xFFE8F4F0)],
          ),
        ),
        child: Center(
          child: Padding(
            padding: EdgeInsets.all(30.w),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: EdgeInsets.all(20.w),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF97316).withOpacity(isDark ? 0.2 : 0.12),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.elevator_rounded,
                    size: 64.w,
                    color: const Color(0xFFF97316),
                  ),
                ),
                SizedBox(height: 24.h),
                Text(
                  'Тухайн СӨХ нь лифтний холболт хийгээгүй байна.',
                  style: TextStyle(
                    fontSize: 16.sp,
                    color: isDark ? Colors.white70 : Colors.black87,
                    fontWeight: FontWeight.w600,
                    height: 1.5,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
