import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:sukh_app/constants/constants.dart';
import 'package:sukh_app/services/theme_service.dart';
import 'package:sukh_app/utils/theme_extensions.dart';

class HomeHeader extends StatelessWidget {
  final int unreadNotificationCount;
  final VoidCallback onMenuTap;
  final VoidCallback onThemeToggle;
  final VoidCallback onNotificationTap;

  const HomeHeader({
    super.key,
    required this.unreadNotificationCount,
    required this.onMenuTap,
    required this.onThemeToggle,
    required this.onNotificationTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = context.isDarkMode;

    return SafeArea(
      bottom: false,
      child: Padding(
        padding: EdgeInsets.fromLTRB(16.w, 16.h, 16.w, 8.h),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            // Menu Button
            GestureDetector(
              onTap: onMenuTap,
              child: Container(
                padding: EdgeInsets.all(8.w),
                decoration: BoxDecoration(
                  color: AppColors.deepGreen,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.deepGreen.withOpacity(0.3),
                      blurRadius: 6,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: Icon(
                  Icons.menu_rounded,
                  color: Colors.white,
                  size: 20.sp,
                ),
              ),
            ),

            // Actions right side
            Row(
              children: [
                // Theme Toggle Button
                GestureDetector(
                  onTap: onThemeToggle,
                  child: Container(
                    padding: EdgeInsets.all(8.w),
                    decoration: BoxDecoration(
                      color: AppColors.deepGreen,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.deepGreen.withOpacity(0.3),
                          blurRadius: 6,
                          offset: const Offset(0, 3),
                        ),
                      ],
                    ),
                    child: Icon(
                      isDark
                          ? Icons.light_mode_rounded
                          : Icons.dark_mode_rounded,
                      color: Colors.white,
                      size: 20.sp,
                    ),
                  ),
                ),
                SizedBox(width: 8.w),
                // Notification Button
                Stack(
                  clipBehavior: Clip.none,
                  children: [
                    GestureDetector(
                      onTap: onNotificationTap,
                      child: Container(
                        padding: EdgeInsets.all(8.w),
                        decoration: BoxDecoration(
                          color: AppColors.deepGreen,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.deepGreen.withOpacity(0.3),
                              blurRadius: 6,
                              offset: const Offset(0, 3),
                            ),
                          ],
                        ),
                        child: Icon(
                          Icons.notifications_outlined,
                          color: Colors.white,
                          size: 20.sp,
                        ),
                      ),
                    ),
                    if (unreadNotificationCount > 0)
                      Positioned(
                        right: -2,
                        top: -2,
                        child: Container(
                          padding: EdgeInsets.all(4),
                          decoration: BoxDecoration(
                            color: Colors.red,
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: Colors.white,
                              width: 1.5,
                            ),
                          ),
                          constraints: BoxConstraints(
                            minWidth: 16.w,
                            minHeight: 16.h,
                          ),
                          child: Center(
                            child: Text(
                              '$unreadNotificationCount',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 8.sp,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
