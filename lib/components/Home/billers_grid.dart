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
          padding: EdgeInsets.symmetric(horizontal: 4.w),
          child: Text(
                'Төлбөрийн үйлчилгээ',
                style: TextStyle(
                  fontSize: 17.sp,
                  color: context.textPrimaryColor,
                  fontWeight: FontWeight.w600,
                  letterSpacing: -0.4,
                ),
              ),
        ),
        
        SizedBox(height: 10.h),
        // iOS-ийн бүлэглэсэн самбар
        Container(
          padding: EdgeInsets.fromLTRB(8.w, 14.h, 8.w, 6.h),
          decoration: BoxDecoration(
            color: isDark ? Colors.white.withOpacity(0.05) : Colors.white,
            borderRadius: BorderRadius.circular(26.r),
            border: Border.all(
              color: isDark
                  ? Colors.white.withOpacity(0.06)
                  : Colors.black.withOpacity(0.04),
            ),
          ),
          child: GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            padding: EdgeInsets.zero,
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 4,
              crossAxisSpacing: 4.w,
              mainAxisSpacing: 8.h,
              childAspectRatio: 0.92,
            ),
            itemCount: allBillers.length,
            itemBuilder: (context, index) {
              return BillerCard(
                biller: allBillers[index],
                onTapCallback: widget.onDevelopmentTap,
              );
            },
          ),
        ),
      ],
    );
  }
}
