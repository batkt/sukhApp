import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:sukh_app/components/Home/biller_card.dart';
import 'package:sukh_app/constants/constants.dart';
import 'package:sukh_app/utils/theme_extensions.dart';

class BillersGrid extends StatefulWidget {
  final List<Map<String, dynamic>> billers;
  final VoidCallback onDevelopmentTap;
  final VoidCallback? onBillerTap;

  const BillersGrid({
    super.key,
    required this.billers,
    required this.onDevelopmentTap,
    this.onBillerTap,
  });

  @override
  State<BillersGrid> createState() => _BillersGridState();
}

class _BillersGridState extends State<BillersGrid> {
  @override
  Widget build(BuildContext context) {
    final isDark = context.isDarkMode;
    final allBillers = widget.billers.take(7).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Modernized Section Header
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 4.w, vertical:4.h),
          child: Row(
            children: [
              Container(
                width: 4.w,
                height: 16.h,
                decoration: BoxDecoration(
                  color: AppColors.deepGreen,
                  borderRadius: BorderRadius.circular(2.r),
                ),
              ),
              SizedBox(width: 10.w),
              Text(
                'Төлбөрийн үйлчилгээ',
                style: TextStyle(
                  fontSize: 16.sp,
                  color: context.textPrimaryColor,
                  letterSpacing: -0.5,
                ),
              ),
            ],
          ),
        ),
        
        // Open Grid of Service Tiles
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          padding: EdgeInsets.symmetric(vertical: 4.h),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 4,
            crossAxisSpacing: 12.w,
            mainAxisSpacing: 12.h,
            childAspectRatio: 0.8, // Adjust for square icon tile
          ),
          itemCount: allBillers.length,
          itemBuilder: (context, index) {
            return BillerCard(
              biller: allBillers[index],
              onTapCallback: widget.onDevelopmentTap,
            );
          },
        ),
      ],
    );
  }
}
