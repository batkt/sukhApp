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
    final allBillers = widget.billers.take(6).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Section title
        Padding(
          padding: EdgeInsets.only(left: 4.w, bottom: 12.h),
          child: Text(
            'Төлбөрийн үйлчилгээ',
            style: TextStyle(
              fontSize: 14.sp,
              fontWeight: FontWeight.w700,
              color: context.textPrimaryColor,
            ),
          ),
        ),
        
        // Modern card container
        Container(
          padding: EdgeInsets.all(16.w),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1A1F26) : Colors.white,
            borderRadius: BorderRadius.circular(20.r),
            border: Border.all(
              color: isDark 
                  ? Colors.white.withOpacity(0.08) 
                  : AppColors.deepGreen.withOpacity(0.1),
              width: 1,
            ),
            boxShadow: [
              BoxShadow(
                color: isDark 
                    ? Colors.black.withOpacity(0.3) 
                    : Colors.black.withOpacity(0.06),
                blurRadius: 20,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              crossAxisSpacing: 12.w,
              mainAxisSpacing: 16.h,
              childAspectRatio: 0.85,
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
