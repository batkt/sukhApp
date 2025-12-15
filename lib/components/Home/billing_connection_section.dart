import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:sukh_app/constants/constants.dart';
import 'package:sukh_app/widgets/optimized_glass.dart';

class BillingConnectionSection extends StatelessWidget {
  final bool isConnecting;
  final VoidCallback onConnect;

  const BillingConnectionSection({
    super.key,
    required this.isConnecting,
    required this.onConnect,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 11.w),
      child: OptimizedGlass(
        borderRadius: BorderRadius.circular(22.r),
        child: Container(
          padding: EdgeInsets.all(11.w),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: EdgeInsets.all(11.w),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          AppColors.goldPrimary.withOpacity(0.3),
                          AppColors.goldPrimary.withOpacity(0.15),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(11.r),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.goldPrimary.withOpacity(0.2),
                          blurRadius: 8.w,
                          spreadRadius: 0,
                          offset: Offset(0, 2.h),
                        ),
                      ],
                    ),
                    child: Icon(
                      Icons.info_outline,
                      color: AppColors.goldPrimary,
                      size: 11.sp,
                    ),
                  ),
                  SizedBox(width: 11.w),
                  Expanded(
                    child: Text(
                      'Биллинг холбох',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 11.sp,
                        fontWeight: FontWeight.bold,
                        letterSpacing: -0.3,
                      ),
                    ),
                  ),
                ],
              ),
              SizedBox(height: 11.h),
              Text(
                'Хаягаар биллинг олж холбох',
                style: TextStyle(
                  color: Colors.white.withOpacity(0.8),
                  fontSize: 11.sp,
                ),
              ),
              SizedBox(height: 11.h),
              SizedBox(
                width: double.infinity,
                child: OptimizedGlass(
                  borderRadius: BorderRadius.circular(11.r),
                  child: Container(
                    padding: EdgeInsets.symmetric(vertical: 11.h),
                    child: ElevatedButton(
                      onPressed: isConnecting ? null : onConnect,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.transparent,
                        shadowColor: Colors.transparent,
                        foregroundColor: Colors.white,
                        padding: EdgeInsets.zero,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(11.r),
                        ),
                      ),
                      child: isConnecting
                          ? Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                SizedBox(
                                  width: 22.w,
                                  height: 22.w,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2.5,
                                    valueColor: AlwaysStoppedAnimation<Color>(
                                      Colors.black,
                                    ),
                                  ),
                                ),
                                SizedBox(width: 11.w),
                                Text(
                                  'Холбож байна...',
                                  style: TextStyle(
                                    fontSize: 11.sp,
                                    fontWeight: FontWeight.bold,
                                    letterSpacing: 0.3,
                                  ),
                                ),
                              ],
                            )
                          : Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.link_rounded, size: 22.sp),
                                SizedBox(width: 11.w),
                                Text(
                                  'Биллинг холбох',
                                  style: TextStyle(
                                    fontSize: 11.sp,
                                    fontWeight: FontWeight.bold,
                                    letterSpacing: 0.3,
                                  ),
                                ),
                              ],
                            ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
