import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:top_snackbar_flutter/top_snack_bar.dart';

void showGlassSnackBar(
  BuildContext context, {
  required String message,
  IconData icon = Icons.info,
  Color textColor = Colors.white,
  Color iconColor = Colors.white,
  double opacity = 0.2,
  double blur = 10,
}) {
  showTopSnackBar(
    Overlay.of(context),
    Material(
      color: Colors.transparent,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16.w),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: blur, sigmaY: blur),
          child: Container(
            padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 16.h),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(opacity),
              borderRadius: BorderRadius.circular(16.w),
              border: Border.all(color: Colors.white.withOpacity(0.3)),
            ),
            child: Row(
              children: [
                Icon(icon, color: iconColor, size: 32.sp),
                SizedBox(width: 16.w),
                Expanded(
                  child: Text(
                    message,
                    style: TextStyle(
                      color: textColor,
                      fontSize: 15.sp,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    ),
    dismissType: DismissType.onSwipe,
    dismissDirection: [DismissDirection.up],
  );
}
