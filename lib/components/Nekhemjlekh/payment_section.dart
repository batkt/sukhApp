import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:sukh_app/constants/constants.dart';
import 'package:sukh_app/widgets/optimized_glass.dart';

class PaymentSection extends StatelessWidget {
  final int selectedCount;
  final String totalSelectedAmount;
  final VoidCallback? onPaymentTap;

  const PaymentSection({
    super.key,
    required this.selectedCount,
    required this.totalSelectedAmount,
    this.onPaymentTap,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 16.w),
      child: OptimizedGlass(
        borderRadius: BorderRadius.circular(20.r),
        child: Padding(
          padding: EdgeInsets.all(16.w),
          child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          totalSelectedAmount,
                          style: TextStyle(
                            color: AppColors.secondaryAccent,
                            fontSize: 20.sp,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(width: 12.w),
                  Text(
                    selectedCount > 0
                        ? '$selectedCount нэхэмжлэх сонгосон'
                        : 'Нэхэмжлэх сонгоно уу',
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.7),
                      fontSize: 12.sp,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  SizedBox(width: 12.w),
                  OptimizedGlass(
                    borderRadius: BorderRadius.circular(12.r),
                    opacity: 0.10,
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        onTap: selectedCount > 0 ? onPaymentTap : null,
                        borderRadius: BorderRadius.circular(12.r),
                        child: Container(
                          padding: EdgeInsets.symmetric(
                            horizontal: 24.w,
                            vertical: 12.h,
                          ),
                          decoration: BoxDecoration(
                            color: selectedCount > 0
                                ? AppColors.secondaryAccent
                                : Colors.white.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12.r),
                          ),
                          child: Text(
                            'Төлбөр төлөх',
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 14.sp,
                              color: selectedCount > 0
                                  ? Colors.black
                                  : Colors.white.withOpacity(0.3),
                            ),
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

