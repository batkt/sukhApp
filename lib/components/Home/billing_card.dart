import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:sukh_app/constants/constants.dart';
import 'package:sukh_app/widgets/optimized_glass.dart';
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

    return RepaintBoundary(
      child: Container(
        margin: EdgeInsets.only(bottom: 12.h),
        child: OptimizedGlass(
          borderRadius: BorderRadius.circular(22.r),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: onTap,
              borderRadius: BorderRadius.circular(22.r),
              child: Padding(
                padding: EdgeInsets.all(11.w),
                child: Row(
                  children: [
                    // Icon (no extra blur layer per card)
                    Container(
                      padding: EdgeInsets.all(11.w),
                      decoration: BoxDecoration(
                        color: context.accentBackgroundColor,
                        borderRadius: BorderRadius.circular(11.r),
                        border: Border.all(
                          color: context.borderColor,
                          width: 1,
                        ),
                      ),
                      child: Icon(
                        Icons.home_rounded,
                        color: AppColors.deepGreen,
                        size: 32.sp, // Increased from 24 to match larger text
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
                                fontSize: 20
                                    .sp, // Increased from 11 for better readability
                                fontWeight: FontWeight.bold,
                                letterSpacing: -0.2,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            if (billingName != customerName &&
                                billingName != 'Биллинг') ...[
                              SizedBox(height: 2.h),
                              Text(
                                billingName,
                                style: TextStyle(
                                  color: context.textSecondaryColor,
                                  fontSize: 18
                                      .sp, // Increased from 11 for better readability
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
                                fontSize: 20
                                    .sp, // Increased from 11 for better readability
                                fontWeight: FontWeight.bold,
                                letterSpacing: -0.2,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],

                          SizedBox(height: 4.h),

                          if (bairniiNer.isNotEmpty) ...[
                            Row(
                              children: [
                                Icon(
                                  Icons.location_on_rounded,
                                  color: context.textSecondaryColor,
                                  size: 20
                                      .sp, // Increased from 12 to match larger text
                                ),
                                SizedBox(width: 4.w),
                                Expanded(
                                  child: Text(
                                    '${expandAddressAbbreviations(bairniiNer)}${doorNo.isNotEmpty ? ", $doorNo" : ""}',
                                    style: TextStyle(
                                      color: context.textSecondaryColor,
                                      fontSize: 18
                                          .sp, // Increased from 11 for better readability
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
                                  size: 20
                                      .sp, // Increased from 12 to match larger text
                                ),
                                SizedBox(width: 4.w),
                                Text(
                                  customerCode,
                                  style: TextStyle(
                                    color: context.textSecondaryColor,
                                    fontSize: 18
                                        .sp, // Increased from 11 for better readability
                                  ),
                                ),
                              ],
                            ),
                          ],

                          if ((hasPayableBills && payableBillCount > 0) ||
                              (hasNewBills && newBillsCount > 0)) ...[
                            SizedBox(height: 6.h),
                            Wrap(
                              spacing: 6.w,
                              runSpacing: 4.h,
                              children: [
                                if (hasPayableBills && payableBillCount > 0)
                                  Container(
                                    padding: EdgeInsets.symmetric(
                                      horizontal: 8.w,
                                      vertical: 4.h,
                                    ),
                                    decoration: BoxDecoration(
                                      color: Colors.orange.withOpacity(0.2),
                                      borderRadius: BorderRadius.circular(11.r),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(
                                          Icons.warning_amber_rounded,
                                          color: Colors.orange,
                                          size: 20
                                              .sp, // Increased from 12 to match larger text
                                        ),
                                        SizedBox(width: 4.w),
                                        Text(
                                          '$payableBillCount төлөх',
                                          style: TextStyle(
                                            color: Colors.orange,
                                            fontSize: 18
                                                .sp, // Increased from 11 for better readability
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
                                      color: Colors.blue.withOpacity(0.2),
                                      borderRadius: BorderRadius.circular(11.r),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(
                                          Icons.new_releases_rounded,
                                          color: Colors.blue,
                                          size: 20
                                              .sp, // Increased from 12 to match larger text
                                        ),
                                        SizedBox(width: 4.w),
                                        Text(
                                          '$newBillsCount шинэ',
                                          style: TextStyle(
                                            color: Colors.blue,
                                            fontSize: 18
                                                .sp, // Increased from 11 for better readability
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
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
