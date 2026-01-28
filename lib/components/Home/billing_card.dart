import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:sukh_app/constants/constants.dart';
import 'package:sukh_app/utils/theme_extensions.dart';

class BillingCard extends StatelessWidget {
  final Map<String, dynamic> billing;
  final VoidCallback onTap;
  final String Function(String) expandAddressAbbreviations;

  const BillingCard({
    super.key,
    required this.billing,
    required this.onTap,
    required this.expandAddressAbbreviations,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = context.isDarkMode;
    
    // Get customer name
    String customerName = '';
    if (billing['ovog'] != null && billing['ovog'].toString().isNotEmpty) {
      customerName = billing['ovog'].toString();
      if (billing['ner'] != null && billing['ner'].toString().isNotEmpty) {
        customerName += ' ${billing['ner'].toString()}';
      }
    } else if (billing['ner'] != null && billing['ner'].toString().isNotEmpty) {
      customerName = billing['ner'].toString();
    } else if (billing['customerName'] != null &&
        billing['customerName'].toString().isNotEmpty) {
      customerName = billing['customerName'].toString();
    }

    final billingName =
        billing['billingName']?.toString() ??
        (customerName.isNotEmpty ? customerName : 'Биллинг');
    final customerCode =
        billing['customerCode']?.toString() ??
        billing['walletCustomerCode']?.toString() ??
        '';
    final bairniiNer =
        billing['bairniiNer']?.toString() ??
        billing['customerAddress']?.toString() ??
        '';
    final doorNo = billing['walletDoorNo']?.toString() ?? '';

    // New fields from updated API
    final hasPayableBills = billing['hasPayableBills'] == true;
    final payableBillCount =
        (billing['payableBillCount'] as num?)?.toInt() ?? 0;
    final hasNewBills = billing['hasNewBills'] == true;
    final newBillsCount = (billing['newBillsCount'] as num?)?.toInt() ?? 0;
    
    // Check if e-bill is connected (has billingId from Wallet API)
    final isEBillConnected = billing['billingId'] != null || 
        billing['walletBillingId'] != null ||
        (billing['isLocalData'] != true && billing['customerId'] != null);

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: EdgeInsets.only(bottom: 12.h),
        padding: EdgeInsets.all(16.w),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1A1F26) : Colors.white,
          borderRadius: BorderRadius.circular(16.r),
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
              blurRadius: 16,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Row(
          children: [
            // Icon
            Container(
              padding: EdgeInsets.all(12.w),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    AppColors.deepGreen,
                    AppColors.deepGreen.withOpacity(0.8),
                  ],
                ),
                borderRadius: BorderRadius.circular(12.r),
              ),
              child: Icon(
                Icons.home_rounded,
                color: Colors.white,
                size: 24.sp,
              ),
            ),
            SizedBox(width: 14.w),

            // Content
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (customerName.isNotEmpty) ...[
                    Text(
                      customerName,
                      style: TextStyle(
                        color: context.textPrimaryColor,
                        fontSize: 13.sp,
                        fontWeight: FontWeight.w700,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (billingName != customerName && billingName != 'Биллинг') ...[
                      SizedBox(height: 2.h),
                      Text(
                        billingName,
                        style: TextStyle(
                          color: context.textSecondaryColor,
                          fontSize: 11.sp,
                          fontWeight: FontWeight.w500,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ] else ...[
                    Text(
                      billingName,
                      style: TextStyle(
                        color: context.textPrimaryColor,
                        fontSize: 13.sp,
                        fontWeight: FontWeight.w700,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],

                  SizedBox(height: 6.h),

                  if (bairniiNer.isNotEmpty) ...[
                    Row(
                      children: [
                        Icon(
                          Icons.location_on_rounded,
                          color: context.textSecondaryColor,
                          size: 12.sp,
                        ),
                        SizedBox(width: 4.w),
                        Expanded(
                          child: Text(
                            '${expandAddressAbbreviations(bairniiNer)}${doorNo.isNotEmpty ? ", $doorNo" : ""}',
                            style: TextStyle(
                              color: context.textSecondaryColor,
                              fontSize: 10.sp,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ] else if (customerCode.isNotEmpty) ...[
                    Row(
                      children: [
                        Icon(
                          Icons.tag_rounded,
                          color: context.textSecondaryColor,
                          size: 12.sp,
                        ),
                        SizedBox(width: 4.w),
                        Text(
                          customerCode,
                          style: TextStyle(
                            color: context.textSecondaryColor,
                            fontSize: 10.sp,
                          ),
                        ),
                      ],
                    ),
                  ],

                  if ((hasPayableBills && payableBillCount > 0) ||
                      (hasNewBills && newBillsCount > 0) ||
                      isEBillConnected) ...[
                    SizedBox(height: 8.h),
                    Wrap(
                      spacing: 6.w,
                      runSpacing: 4.h,
                      children: [
                        if (isEBillConnected)
                          Container(
                            padding: EdgeInsets.symmetric(
                              horizontal: 8.w,
                              vertical: 4.h,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.deepGreen.withOpacity(0.15),
                              borderRadius: BorderRadius.circular(8.r),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.link_rounded,
                                  color: AppColors.deepGreen,
                                  size: 10.sp,
                                ),
                                SizedBox(width: 4.w),
                                Text(
                                  'Холбогдсон',
                                  style: TextStyle(
                                    color: AppColors.deepGreen,
                                    fontSize: 9.sp,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        if (hasPayableBills && payableBillCount > 0)
                          Container(
                            padding: EdgeInsets.symmetric(
                              horizontal: 8.w,
                              vertical: 4.h,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.orange.withOpacity(0.15),
                              borderRadius: BorderRadius.circular(8.r),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.warning_amber_rounded,
                                  color: Colors.orange,
                                  size: 10.sp,
                                ),
                                SizedBox(width: 4.w),
                                Text(
                                  '$payableBillCount төлөх',
                                  style: TextStyle(
                                    color: Colors.orange,
                                    fontSize: 9.sp,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        if (hasNewBills && newBillsCount > 0)
                          Container(
                            padding: EdgeInsets.symmetric(
                              horizontal: 8.w,
                              vertical: 4.h,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.blue.withOpacity(0.15),
                              borderRadius: BorderRadius.circular(8.r),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.new_releases_rounded,
                                  color: Colors.blue,
                                  size: 10.sp,
                                ),
                                SizedBox(width: 4.w),
                                Text(
                                  '$newBillsCount шинэ',
                                  style: TextStyle(
                                    color: Colors.blue,
                                    fontSize: 9.sp,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
            
            // Arrow
            Icon(
              Icons.chevron_right_rounded,
              color: context.textSecondaryColor,
              size: 24.sp,
            ),
          ],
        ),
      ),
    );
  }
}
