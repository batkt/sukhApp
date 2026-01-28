import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:sukh_app/components/Home/billing_card.dart';
import 'package:sukh_app/constants/constants.dart';
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
    final isDark = context.isDarkMode;
    final hasData = widget.billingList.isNotEmpty || widget.userBillingData != null;
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Section title
        if (hasData || widget.isLoading)
          Padding(
            padding: EdgeInsets.only(left: 4.w, bottom: 12.h),
            child: Text(
              'Миний биллинг',
              style: TextStyle(
                fontSize: 14.sp,
                fontWeight: FontWeight.w700,
                color: context.textPrimaryColor,
              ),
            ),
          ),
        
        if (widget.isLoading)
          Container(
            padding: EdgeInsets.all(24.w),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1A1F26) : Colors.white,
              borderRadius: BorderRadius.circular(16.r),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.06),
                  blurRadius: 16,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: Center(
              child: CircularProgressIndicator(
                color: AppColors.deepGreen,
                strokeWidth: 2,
              ),
            ),
          )
        else if (widget.billingList.isEmpty && widget.userBillingData == null)
          _hasUserClicked
              ? Container(
                  padding: EdgeInsets.all(16.w),
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF1A1F26) : Colors.white,
                    borderRadius: BorderRadius.circular(16.r),
                    border: Border.all(
                      color: isDark 
                          ? Colors.white.withOpacity(0.08) 
                          : Colors.grey.withOpacity(0.2),
                      width: 1,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.06),
                        blurRadius: 16,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: EdgeInsets.all(10.w),
                        decoration: BoxDecoration(
                          color: Colors.grey.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(10.r),
                        ),
                        child: Icon(
                          Icons.info_outline,
                          color: context.textSecondaryColor,
                          size: 20.sp,
                        ),
                      ),
                      SizedBox(width: 12.w),
                      Expanded(
                        child: Text(
                          'Холбогдсон биллинг байхгүй байна',
                          style: TextStyle(
                            color: context.textSecondaryColor,
                            fontSize: 11.sp,
                          ),
                        ),
                      ),
                    ],
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
    );
  }
}
