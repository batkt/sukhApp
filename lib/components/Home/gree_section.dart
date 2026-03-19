import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:sukh_app/models/geree_model.dart';
import 'package:sukh_app/utils/theme_extensions.dart';

class GreeSection extends StatelessWidget {
  final GereeResponse? greeResponse;

  const GreeSection({super.key, required this.greeResponse});

  @override
  Widget build(BuildContext context) {
    if (greeResponse == null || greeResponse!.jagsaalt.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      children: [
        SizedBox(height: 12.h),
        _buildRemainingDaysWidget(context, greeResponse!.jagsaalt.first),
        SizedBox(height: 12.h),
      ],
    );
  }

  Widget _buildRemainingDaysWidget(BuildContext context, Jagsaalt jagsaalt) {
    final daysRemaining = jagsaalt.uldriinOdoo;
    final percentage = daysRemaining / 30.0;

    Color progressColor;
    if (percentage >= 0.7) {
      progressColor = Colors.green;
    } else if (percentage >= 0.4) {
      progressColor = Colors.orange;
    } else {
      progressColor = Colors.red;
    }

    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: context.isDarkMode ? const Color(0xFF1A1F26) : Colors.white,
        borderRadius: BorderRadius.circular(16.r),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.calendar_today_outlined,
                color: context.textSecondaryColor,
                size: 16.sp,
              ),
              SizedBox(width: 8.w),
              Text(
                'Үлдэгдэх хоног',
                style: TextStyle(
                  color: context.textSecondaryColor,
                  fontSize: 13.sp,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          SizedBox(height: 12.h),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '$daysRemaining хоног',
                      style: TextStyle(
                        color: context.textPrimaryColor,
                        fontSize: 24.sp,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    SizedBox(height: 4.h),
                    Container(
                      height: 8.h,
                      decoration: BoxDecoration(
                        color: progressColor.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(4.r),
                      ),
                      child: FractionallySizedBox(
                        alignment: Alignment.centerLeft,
                        widthFactor: percentage.clamp(0.0, 1.0),
                        child: Container(
                          decoration: BoxDecoration(
                            color: progressColor,
                            borderRadius: BorderRadius.circular(4.r),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(width: 12.w),
              Container(
                width: 60.w,
                height: 60.w,
                decoration: BoxDecoration(
                  color: progressColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12.r),
                ),
                child: Icon(
                  Icons.timer_outlined,
                  color: progressColor,
                  size: 24.sp,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
