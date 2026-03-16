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
  final Function(Map<String, dynamic>)? onDeleteTap;

  final double totalBalance;

  const BillingListSection({
    super.key,
    required this.isLoading,
    required this.billingList,
    this.userBillingData,
    required this.onBillingTap,
    required this.expandAddressAbbreviations,
    this.onShowEmptyMessage,
    this.onDeleteTap,
    required this.totalBalance,
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
            padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 8.h),
            child: Row(
              children: [
                Container(
                  width: 4.w,
                  height: 18.h,
                  decoration: BoxDecoration(
                    color: AppColors.deepGreen,
                    borderRadius: BorderRadius.circular(2.r),
                  ),
                ),
                SizedBox(width: 10.w),
                Text(
                  'Миний биллинг',
                  style: TextStyle(
                    fontSize: 16.sp,
                    fontWeight: FontWeight.w800,
                    color: context.textPrimaryColor,
                    letterSpacing: -0.5,
                  ),
                ),
              ],
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
                  padding: EdgeInsets.all(18.w),
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF1A1F26) : Colors.white,
                    borderRadius: BorderRadius.circular(24.r),
                    border: Border.all(
                      color: isDark 
                          ? Colors.white.withOpacity(0.08) 
                          : AppColors.deepGreen.withOpacity(0.06),
                      width: 1,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: isDark 
                            ? Colors.black.withOpacity(0.3) 
                            : Colors.black.withOpacity(0.04),
                        blurRadius: 20,
                        offset: const Offset(0, 10),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: EdgeInsets.all(12.w),
                        decoration: BoxDecoration(
                          color: AppColors.deepGreen.withOpacity(0.08),
                          borderRadius: BorderRadius.circular(14.r),
                        ),
                        child: Icon(
                          Icons.help_outline_rounded,
                          color: AppColors.deepGreen.withOpacity(0.6),
                          size: 22.sp,
                        ),
                      ),
                      SizedBox(width: 14.w),
                      Expanded(
                        child: Text(
                          'Холбогдсон биллинг одоогоор байхгүй байна',
                          style: TextStyle(
                            color: context.textSecondaryColor,
                            fontSize: 12.sp,
                            fontWeight: FontWeight.w600,
                            height: 1.3,
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
              onDeleteTap: widget.onDeleteTap != null 
                  ? () => widget.onDeleteTap!(widget.userBillingData!)
                  : null,
              totalBalance: widget.totalBalance,
            ),
          // Show connected billings from Wallet API
          ...widget.billingList.map(
            (billing) => BillingCard(
              billing: billing,
              onTap: () => widget.onBillingTap(billing),
              expandAddressAbbreviations: widget.expandAddressAbbreviations,
              onDeleteTap: widget.onDeleteTap != null
                  ? () => widget.onDeleteTap!(billing)
                  : null,
              totalBalance: widget.totalBalance,
            ),
          ),
        ],
      ],
    );
  }
}
