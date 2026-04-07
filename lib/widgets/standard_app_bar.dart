import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:sukh_app/constants/constants.dart';
import 'package:sukh_app/utils/theme_extensions.dart';
import 'package:sukh_app/utils/responsive_helper.dart';

/// Standard AppBar for all pages - matches home screen floating style
PreferredSizeWidget buildStandardAppBar(
  BuildContext context, {
  required String title,
  VoidCallback? onBackPressed,
  List<Widget>? actions,
  bool automaticallyImplyLeading = true,
  Color? backButtonColor,
  Color? backButtonIconColor,
  Color? titleColor,
}) {
  return PreferredSize(
    preferredSize: Size.fromHeight(60.h),
    child: SafeArea(
      bottom: false,
      child: Padding(
        padding: EdgeInsets.fromLTRB(16.w, 16.h, 16.w, 8.h),
        child: Stack(
          alignment: Alignment.center,
          children: [
            // Left Action / Back Button
            if (automaticallyImplyLeading)
              Align(
                alignment: Alignment.centerLeft,
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: onBackPressed ??
                      () {
                        if (context.canPop()) {
                          context.pop();
                        } else {
                          context.go('/nuur');
                        }
                      },
                  child: Container(
                    width: 44.w,
                    height: 44.w,
                    decoration: BoxDecoration(
                      color: backButtonColor ?? AppColors.deepGreen,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: (backButtonColor ?? AppColors.deepGreen).withOpacity(0.3),
                          blurRadius: 6,
                          offset: const Offset(0, 3),
                        ),
                      ],
                    ),
                    child: Center(
                      child: Icon(
                        Icons.arrow_back_rounded,
                        color: backButtonIconColor ?? Colors.white,
                        size: 20.sp,
                      ),
                    ),
                  ),
                ),
              ),
            
            // Title
            IgnorePointer(
              child: Text(
                title,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: titleColor ??
                      (context.isDarkMode ? Colors.white : context.textPrimaryColor),
                  fontSize: 16.sp,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.3,
                ),
              ),
            ),
            
            // Right Actions
            if (actions != null && actions.isNotEmpty)
              Align(
                alignment: Alignment.centerRight,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: actions,
                ),
              ),
          ],
        ),
      ),
    ),
  );
}
