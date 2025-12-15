import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:sukh_app/constants/constants.dart';
import 'package:sukh_app/widgets/optimized_glass.dart';

class NekhemjlekhHeader extends StatelessWidget {
  final String? selectedContractDisplay;
  final int availableContractsCount;
  final VoidCallback? onContractSelect;

  const NekhemjlekhHeader({
    super.key,
    this.selectedContractDisplay,
    this.availableContractsCount = 0,
    this.onContractSelect,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Header with liquid glass styling
        Padding(
          padding: EdgeInsets.fromLTRB(16.w, 12.h, 16.w, 8.h),
          child: Row(
            children: [
              // Back button with liquid glass
              SizedBox(
                height: 48.h,
                child: OptimizedGlass(
                  borderRadius: BorderRadius.circular(11.r),
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: () => context.pop(),
                      borderRadius: BorderRadius.circular(11.r),
                      child: Padding(
                        padding: EdgeInsets.all(11.w),
                        child: Icon(
                          Icons.arrow_back_rounded,
                          color: Colors.white,
                          size: 22.sp,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              SizedBox(width: 12.w),
              // Title with liquid glass card
              Expanded(
                child: SizedBox(
                  height: 48.h,
                  child: OptimizedGlass(
                    borderRadius: BorderRadius.circular(11.r),
                    child: Padding(
                      padding: EdgeInsets.symmetric(horizontal: 14.w),
                      child: Center(
                        child: Row(
                          children: [
                            Icon(
                              Icons.receipt_long_rounded,
                              color: AppColors.secondaryAccent,
                              size: 22.sp,
                            ),
                            SizedBox(width: 11.w),
                            Text(
                              'Нэхэмжлэх',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 18.sp,
                                fontWeight: FontWeight.bold,
                                letterSpacing: -0.3,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              SizedBox(width: 12.w),
              // Contract switcher button with liquid glass (only if multiple contracts)
              if (availableContractsCount > 1)
                SizedBox(
                  height: 48.h,
                  child: OptimizedGlass(
                    borderRadius: BorderRadius.circular(11.r),
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        onTap: onContractSelect,
                        borderRadius: BorderRadius.circular(11.r),
                        child: Padding(
                          padding: EdgeInsets.all(11.w),
                          child: Icon(
                            Icons.swap_horiz_rounded,
                            color: Colors.white,
                            size: 22.sp,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
        // Contract info with liquid glass (if multiple contracts for OWN_ORG, or billing name for WALLET_API)
        if (selectedContractDisplay != null)
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 16.w),
            child: GestureDetector(
              onTap: availableContractsCount > 1 ? onContractSelect : null,
              child: OptimizedGlass(
                borderRadius: BorderRadius.circular(12.r),
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: availableContractsCount > 1 ? onContractSelect : null,
                    borderRadius: BorderRadius.circular(12.r),
                    child: Padding(
                      padding: EdgeInsets.symmetric(
                        horizontal: 12.w,
                        vertical: 8.h,
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.business_rounded,
                            color: AppColors.secondaryAccent,
                            size: 16.sp,
                          ),
                          SizedBox(width: 8.w),
                          Flexible(
                            child: Text(
                              selectedContractDisplay!,
                              style: TextStyle(
                                color: Colors.white.withOpacity(0.9),
                                fontSize: 13.sp,
                                fontWeight: FontWeight.w500,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          if (availableContractsCount > 1) ...[
                            SizedBox(width: 4.w),
                            Icon(
                              Icons.keyboard_arrow_down_rounded,
                              color: AppColors.secondaryAccent,
                              size: 16.sp,
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        if (selectedContractDisplay != null && availableContractsCount > 1)
          SizedBox(height: 12.h),
      ],
    );
  }
}

