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
      padding: EdgeInsets.fromLTRB(20.w, 0, 20.w, 16.h),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeOutBack,
        decoration: BoxDecoration(
          color: context.cardBackgroundColor,
          borderRadius: BorderRadius.circular(28.r),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: context.isDarkMode 
                ? [Colors.white.withOpacity(0.08), Colors.white.withOpacity(0.02)]
                : [Colors.black.withOpacity(0.04), Colors.black.withOpacity(0.01)],
          ),
          boxShadow: [
            BoxShadow(
              color: hasSelection 
                  ? AppColors.deepGreen.withOpacity(context.isDarkMode ? 0.25 : 0.15)
                  : Colors.black.withOpacity(0.06),
              blurRadius: hasSelection ? 32 : 24,
              offset: Offset(0, hasSelection ? 12 : 8),
            ),
          ],
          border: Border.all(
            color: hasSelection 
                ? AppColors.deepGreen.withOpacity(0.4) 
                : context.borderColor.withOpacity(0.2),
            width: 1.5,
          ),
        ),
        child: Padding(
          padding: EdgeInsets.all(14.w),
          child: Row(
            children: [
              Container(
                width: 44.w,
                height: 44.w,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [AppColors.deepGreen.withOpacity(0.2), AppColors.deepGreen.withOpacity(0.05)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(14.r),
                  border: Border.all(color: AppColors.deepGreen.withOpacity(0.1), width: 1),
                ),
                child: Icon(
                  Icons.account_balance_wallet_rounded,
                  color: AppColors.deepGreen,
                  size: 22.sp,
                ),
              ),
              SizedBox(width: 14.w),
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
                          fontWeight: FontWeight.w600,
                          letterSpacing: -0.5,
                        ),
                      ),
                    SizedBox(height: 1.h),
                    Text(
                      hasSelection ? '$selectedCount нэхэмжлэх сонгосон' : 'Төлбөр сонгоно уу',
                      style: TextStyle(
                        color: context.textSecondaryColor,
                        fontSize: 10.sp,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0.2,
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(width: 10.w),
              Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: hasSelection ? onPaymentTap : null,
                  borderRadius: BorderRadius.circular(16.r),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 12.h),
                    decoration: BoxDecoration(
                      gradient: hasSelection 
                          ? const LinearGradient(
                              colors: [AppColors.deepGreen, Color(0xFF10B981)],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            )
                          : null,
                      color: hasSelection ? null : context.textSecondaryColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(16.r),
                      boxShadow: hasSelection ? [
                        BoxShadow(
                          color: AppColors.deepGreen.withOpacity(0.4),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        )
                      ] : null,
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                          Text(
                            'ТӨЛӨХ',
                            style: TextStyle(
                              color: hasSelection ? Colors.white : context.textSecondaryColor.withOpacity(0.5),
                              fontSize: 12.sp,
                              fontWeight: FontWeight.w600,
                              letterSpacing: 0.5,
                            ),
                          ),
                        if (hasSelection) ...[
                          SizedBox(width: 6.w),
                          const Icon(Icons.arrow_forward_ios_rounded, color: Colors.white, size: 10),
                        ],
                      ],
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
