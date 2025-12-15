import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:sukh_app/components/Home/billing_card.dart';
import 'package:sukh_app/constants/constants.dart';
import 'package:sukh_app/widgets/optimized_glass.dart';

class BillingListSection extends StatelessWidget {
  final bool isLoading;
  final List<Map<String, dynamic>> billingList;
  final Map<String, dynamic>? userBillingData;
  final Function(Map<String, dynamic>) onBillingTap;
  final String Function(String) expandAddressAbbreviations;

  const BillingListSection({
    super.key,
    required this.isLoading,
    required this.billingList,
    this.userBillingData,
    required this.onBillingTap,
    required this.expandAddressAbbreviations,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 16.w),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (isLoading)
            OptimizedGlass(
              borderRadius: BorderRadius.circular(12.r),
              child: Padding(
                padding: EdgeInsets.all(11.w),
                child: Center(
                  child: CircularProgressIndicator(
                    color: AppColors.goldPrimary,
                    strokeWidth: 2,
                  ),
                ),
              ),
            )
          else if (billingList.isEmpty && userBillingData == null)
            OptimizedGlass(
              borderRadius: BorderRadius.circular(12.w),
              child: Container(
                padding: EdgeInsets.all(11.w),
                child: Row(
                  children: [
                    Icon(
                      Icons.info_outline,
                      color: Colors.white.withOpacity(0.6),
                      size: 20.sp,
                    ),
                    SizedBox(width: 12.w),
                    Expanded(
                      child: Text(
                        'Холбогдсон биллинг байхгүй байна',
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.6),
                          fontSize: 11.sp,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            )
          else ...[
            // Show user billing data if available (from profile)
            if (userBillingData != null)
              BillingCard(
                billing: userBillingData!,
                onTap: () => onBillingTap(userBillingData!),
                expandAddressAbbreviations: expandAddressAbbreviations,
              ),
            // Show connected billings from Wallet API
            ...billingList.map(
              (billing) => BillingCard(
                billing: billing,
                onTap: () => onBillingTap(billing),
                expandAddressAbbreviations: expandAddressAbbreviations,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
