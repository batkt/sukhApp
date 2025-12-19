import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:sukh_app/components/Home/billing_card.dart';
import 'package:sukh_app/constants/constants.dart';
import 'package:sukh_app/widgets/optimized_glass.dart';
import 'package:sukh_app/utils/theme_extensions.dart';

class BillingListSection extends StatefulWidget {
  final bool isLoading;
  final List<Map<String, dynamic>> billingList;
  final Map<String, dynamic>? userBillingData;
  final Function(Map<String, dynamic>) onBillingTap;
  final String Function(String) expandAddressAbbreviations;
  final VoidCallback? onShowEmptyMessage;

  const BillingListSection({
    super.key,
    required this.isLoading,
    required this.billingList,
    this.userBillingData,
    required this.onBillingTap,
    required this.expandAddressAbbreviations,
    this.onShowEmptyMessage,
  });

  @override
  State<BillingListSection> createState() => BillingListSectionState();
}

class BillingListSectionState extends State<BillingListSection> {
  bool _hasUserClicked = false;

  void showEmptyMessage() {
    if (mounted && widget.billingList.isEmpty && widget.userBillingData == null) {
      setState(() {
        _hasUserClicked = true;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 16.w),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (widget.isLoading)
            OptimizedGlass(
              borderRadius: BorderRadius.circular(12.r),
              child: Padding(
                padding: EdgeInsets.all(11.w),
                child: Center(
                  child: CircularProgressIndicator(
                    color: AppColors.deepGreen,
                    strokeWidth: 2,
                  ),
                ),
              ),
            )
          else if (widget.billingList.isEmpty && widget.userBillingData == null)
            _hasUserClicked
                ? OptimizedGlass(
                    borderRadius: BorderRadius.circular(12.w),
                    child: Container(
                      padding: EdgeInsets.all(11.w),
                      child: Row(
                        children: [
                          Icon(
                            Icons.info_outline,
                            color: context.textSecondaryColor,
                            size: 20.sp,
                          ),
                          SizedBox(width: 12.w),
                          Expanded(
                            child: Text(
                              'Холбогдсон биллинг байхгүй байна',
                              style: TextStyle(
                                color: context.textSecondaryColor,
                                fontSize: 20.sp, // Increased from 11 for better readability
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  )
                : const SizedBox.shrink()
          else ...[
            // Show user billing data if available (from profile)
            if (widget.userBillingData != null)
              BillingCard(
                billing: widget.userBillingData!,
                onTap: () => widget.onBillingTap(widget.userBillingData!),
                expandAddressAbbreviations: widget.expandAddressAbbreviations,
              ),
            // Show connected billings from Wallet API
            ...widget.billingList.map(
              (billing) => BillingCard(
                billing: billing,
                onTap: () => widget.onBillingTap(billing),
                expandAddressAbbreviations: widget.expandAddressAbbreviations,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
