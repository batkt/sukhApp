import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

/// Debug overlay to show screen dimensions and responsive info
/// Only shows in debug mode
class ResponsiveDebugOverlay extends StatelessWidget {
  final Widget child;

  const ResponsiveDebugOverlay({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    if (!kDebugMode) {
      return child;
    }

    final mediaQuery = MediaQuery.of(context);
    final screenWidth = mediaQuery.size.width;
    final screenHeight = mediaQuery.size.height;
    final screenUtil = ScreenUtil();

    final isSmallScreen = screenHeight < 900 || screenWidth < 400;
    final isVerySmallScreen = screenHeight < 700 || screenWidth < 380;

    return Stack(
      children: [
        child,
        Positioned(
          top: 0,
          right: 0,
          child: Container(
            margin: EdgeInsets.all(8.w),
            padding: EdgeInsets.all(8.w),
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.7),
              borderRadius: BorderRadius.circular(8.w),
              border: Border.all(color: const Color(0xFFe6ff00), width: 1),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Screen Info',
                  style: TextStyle(
                    color: const Color(0xFFe6ff00),
                    fontSize: 12.sp,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 4.h),
                _buildInfoRow('Width', '${screenWidth.toInt()}px'),
                _buildInfoRow('Height', '${screenHeight.toInt()}px'),
                SizedBox(height: 4.h),
                _buildInfoRow('SU Width', '${screenUtil.screenWidth.toInt()}'),
                _buildInfoRow(
                  'SU Height',
                  '${screenUtil.screenHeight.toInt()}',
                ),
                _buildInfoRow(
                  'Scale W',
                  screenUtil.scaleWidth.toStringAsFixed(2),
                ),
                _buildInfoRow(
                  'Scale H',
                  screenUtil.scaleHeight.toStringAsFixed(2),
                ),
                SizedBox(height: 4.h),
                _buildInfoRow(
                  'Small',
                  isSmallScreen ? 'YES' : 'NO',
                  color: isSmallScreen ? Colors.orange : Colors.green,
                ),
                _buildInfoRow(
                  'Very Small',
                  isVerySmallScreen ? 'YES' : 'NO',
                  color: isVerySmallScreen ? Colors.red : Colors.green,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildInfoRow(String label, String value, {Color? color}) {
    return Padding(
      padding: EdgeInsets.only(bottom: 2.h),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            '$label: ',
            style: TextStyle(color: Colors.white70, fontSize: 10.sp),
          ),
          Text(
            value,
            style: TextStyle(
              color: color ?? Colors.white,
              fontSize: 10.sp,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}
