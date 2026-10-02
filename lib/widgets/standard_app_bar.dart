import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:sukh_app/utils/theme_extensions.dart';

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
  final isDark = context.isDarkMode;
  return PreferredSize(
    preferredSize: Size.fromHeight(60.h),
    child: SafeArea(
      bottom: false,
      child: Padding(
        padding: EdgeInsets.fromLTRB(16.w, 12.h, 16.w, 8.h),
        // Гарчиг буцах сумны ЯГ хажууд (өмнө нь дэлгэцийн голд байв)
        child: Row(
          children: [
            if (automaticallyImplyLeading) ...[
              GestureDetector(
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
                  width: 38.w,
                  height: 38.w,
                  decoration: BoxDecoration(
                    color: backButtonColor ?? context.cardBackgroundColor,
                    shape: BoxShape.circle,
                    border: backButtonColor == null
                        ? Border.all(
                            color: isDark
                                ? Colors.white.withOpacity(0.08)
                                : Colors.black.withOpacity(0.06),
                          )
                        : null,
                  ),
                  child: Center(
                    child: Icon(
                      Icons.arrow_back_ios_new_rounded,
                      color: backButtonIconColor ?? context.textPrimaryColor,
                      size: 15.sp,
                    ),
                  ),
                ),
              ),
              SizedBox(width: 12.w),
            ],
            Expanded(
              child: Text(
                title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: titleColor ?? context.textPrimaryColor,
                  fontSize: 18.sp,
                  fontWeight: FontWeight.w600,
                  letterSpacing: -0.4,
                ),
              ),
            ),
            if (actions != null && actions.isNotEmpty)
              Row(mainAxisSize: MainAxisSize.min, children: actions),
          ],
        ),
      ),
    ),
  );
}
