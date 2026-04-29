import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:sukh_app/constants/constants.dart';
import 'package:sukh_app/utils/theme_extensions.dart';

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
    final bool hasSelection = selectedCount > 0;
    
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        decoration: BoxDecoration(
          color: context.cardBackgroundColor,
          borderRadius: BorderRadius.circular(24.r),
          boxShadow: [
            BoxShadow(
              color: AppColors.deepGreen.withOpacity(hasSelection ? 0.12 : 0.04),
              blurRadius: 24,
              offset: const Offset(0, 8),
            ),
          ],
          border: Border.all(
            color: hasSelection 
                ? AppColors.deepGreen.withOpacity(0.2) 
                : context.borderColor.withOpacity(0.5),
            width: 1,
          ),
        ),
        child: Padding(
          padding: EdgeInsets.all(16.w),
          child: Row(
            children: [
              Container(
                width: 48.w,
                height: 48.w,
                decoration: BoxDecoration(
                  color: AppColors.deepGreen.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(16.r),
                ),
                child: Icon(
                  Icons.account_balance_wallet_rounded,
                  color: AppColors.deepGreen,
                  size: 24.sp,
                ),
              ),
              SizedBox(width: 16.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      hasSelection ? totalSelectedAmount : '0.00₮',
                      style: TextStyle(
                        color: context.textPrimaryColor,
                        fontSize: 18.sp,
                        fontWeight: FontWeight.w700,
                        letterSpacing: -0.5,
                      ),
                    ),
                    Text(
                      hasSelection ? '$selectedCount нэхэмжлэх сонгосон' : 'Нэхэмжлэл сонгоно уу',
                      style: TextStyle(
                        color: context.textSecondaryColor,
                        fontSize: 12.sp,
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(width: 12.w),
              Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: hasSelection ? onPaymentTap : null,
                  borderRadius: BorderRadius.circular(16.r),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 12.h),
                    decoration: BoxDecoration(
                      color: hasSelection ? AppColors.deepGreen : context.textSecondaryColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(16.r),
                      boxShadow: hasSelection ? [
                        BoxShadow(
                          color: AppColors.deepGreen.withOpacity(0.3),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        )
                      ] : null,
                    ),
                    child: Text(
                      'Төлөх',
                      style: TextStyle(
                        color: hasSelection ? Colors.white : context.textSecondaryColor.withOpacity(0.5),
                        fontSize: 14.sp,
                        fontWeight: FontWeight.w700,
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
