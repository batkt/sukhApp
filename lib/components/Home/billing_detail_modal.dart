import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:sukh_app/constants/constants.dart';

class BillingDetailModal extends StatelessWidget {
  final Map<String, dynamic> billing;
  final Map<String, dynamic> billingData;
  final List<Map<String, dynamic>> bills;
  final String Function(String) expandAddressAbbreviations;
  final String Function(double) formatNumberWithComma;

  const BillingDetailModal({
    super.key,
    required this.billing,
    required this.billingData,
    required this.bills,
    required this.expandAddressAbbreviations,
    required this.formatNumberWithComma,
  });

  @override
  Widget build(BuildContext context) {
    final billingName =
        billingData['billingName']?.toString() ??
        billing['billingName']?.toString() ??
        'Биллингийн мэдээлэл';
    final customerName =
        billingData['customerName']?.toString() ??
        billing['customerName']?.toString() ??
        '';
    final customerAddress =
        billingData['customerAddress']?.toString() ??
        billing['bairniiNer']?.toString() ??
        billing['customerAddress']?.toString() ??
        '';
    final hasNewBills = billingData['hasNewBills'] == true;
    final newBillsCount = (billingData['newBillsCount'] as num?)?.toInt() ?? 0;
    final newBillsAmount =
        (billingData['newBillsAmount'] as num?)?.toDouble() ?? 0.0;
    final hiddenBillCount =
        (billingData['hiddenBillCount'] as num?)?.toInt() ?? 0;
    final paidCount = (billingData['paidCount'] as num?)?.toInt() ?? 0;
    final paidTotal = (billingData['paidTotal'] as num?)?.toDouble() ?? 0.0;

    return Container(
      height: MediaQuery.of(context).size.height * 0.9,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [const Color(0xFF1A1A1A), const Color(0xFF0F0F0F)],
        ),
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(24.r),
          topRight: Radius.circular(24.r),
        ),
      ),
      child: Column(
        children: [
          // Header
          Container(
            padding: EdgeInsets.fromLTRB(20.w, 16.h, 12.w, 16.h),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  AppColors.goldPrimary.withOpacity(0.1),
                  Colors.transparent,
                ],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
              border: Border(
                bottom: BorderSide(
                  color: Colors.white.withOpacity(0.1),
                  width: 1,
                ),
              ),
            ),
            child: Row(
              children: [
                Container(
                  padding: EdgeInsets.all(11.w),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        AppColors.goldPrimary.withOpacity(0.3),
                        AppColors.goldPrimary.withOpacity(0.15),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(11.r),
                  ),
                  child: Icon(
                    Icons.home_rounded,
                    color: AppColors.goldPrimary,
                    size: 24.sp,
                  ),
                ),
                SizedBox(width: 12.w),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        billingName,
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 11.sp,
                          fontWeight: FontWeight.bold,
                          letterSpacing: -0.5,
                        ),
                      ),
                      if (customerName.isNotEmpty) ...[
                        SizedBox(height: 4.h),
                        Text(
                          customerName,
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.7),
                            fontSize: 11.sp,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                IconButton(
                  icon: Container(
                    padding: EdgeInsets.all(8.w),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.close_rounded,
                      color: Colors.white,
                      size: 20.sp,
                    ),
                  ),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),
          ),
          // Content
          Expanded(
            child: SingleChildScrollView(
              padding: EdgeInsets.all(20.w),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Billing Info Section
                  Container(
                    padding: EdgeInsets.all(18.w),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          Colors.white.withOpacity(0.08),
                          Colors.white.withOpacity(0.03),
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(22.r),
                      border: Border.all(
                        color: Colors.white.withOpacity(0.15),
                        width: 1,
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(
                              Icons.info_outline_rounded,
                              color: AppColors.goldPrimary,
                              size: 20.sp,
                            ),
                            SizedBox(width: 11.w),
                            Text(
                              'Биллингийн мэдээлэл',
                              style: TextStyle(
                                color: AppColors.goldPrimary,
                                fontSize: 11.sp,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: 11.h),
                        if (billing['customerCode']?.toString() != null)
                          _buildModernModalInfoRow(
                            Icons.tag_rounded,
                            'Харилцагчийн код',
                            billing['customerCode'].toString(),
                          ),
                        if (customerAddress.isNotEmpty) ...[
                          if (billing['customerCode']?.toString() != null)
                            SizedBox(height: 11.h),
                          _buildModernModalInfoRow(
                            Icons.location_on_rounded,
                            'Хаяг',
                            expandAddressAbbreviations(customerAddress),
                          ),
                        ],
                        if (billing['walletDoorNo']?.toString() != null) ...[
                          SizedBox(height: 11.h),
                          _buildModernModalInfoRow(
                            Icons.door_front_door_rounded,
                            'Орц',
                            billing['walletDoorNo'].toString(),
                          ),
                        ],
                        if (hasNewBills && newBillsCount > 0) ...[
                          SizedBox(height: 11.h),
                          Container(
                            padding: EdgeInsets.all(14.w),
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [
                                  Colors.blue.withOpacity(0.2),
                                  Colors.blue.withOpacity(0.1),
                                ],
                              ),
                              borderRadius: BorderRadius.circular(11.r),
                              border: Border.all(
                                color: Colors.blue.withOpacity(0.4),
                                width: 1,
                              ),
                            ),
                            child: Row(
                              children: [
                                Container(
                                  padding: EdgeInsets.all(8.w),
                                  decoration: BoxDecoration(
                                    color: Colors.blue.withOpacity(0.2),
                                    borderRadius: BorderRadius.circular(11.r),
                                  ),
                                  child: Icon(
                                    Icons.new_releases_rounded,
                                    color: Colors.blue,
                                    size: 20.sp,
                                  ),
                                ),
                                SizedBox(width: 12.w),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Шинэ билл: $newBillsCount',
                                        style: TextStyle(
                                          color: Colors.blue,
                                          fontSize: 11.sp,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      if (newBillsAmount > 0) ...[
                                        SizedBox(height: 4.h),
                                        Text(
                                          'Дүн: ${formatNumberWithComma(newBillsAmount)}₮',
                                          style: TextStyle(
                                            color: Colors.blue.withOpacity(0.8),
                                            fontSize: 11.sp,
                                          ),
                                        ),
                                      ],
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                        if (hiddenBillCount > 0) ...[
                          SizedBox(height: 11.h),
                          Row(
                            children: [
                              Icon(
                                Icons.visibility_off_rounded,
                                color: Colors.white.withOpacity(0.6),
                                size: 16.sp,
                              ),
                              SizedBox(width: 11.w),
                              Text(
                                'Нуугдсан билл: $hiddenBillCount',
                                style: TextStyle(
                                  color: Colors.white.withOpacity(0.6),
                                  fontSize: 11.sp,
                                ),
                              ),
                            ],
                          ),
                        ],
                        if (paidCount > 0) ...[
                          SizedBox(height: 11.h),
                          Row(
                            children: [
                              Icon(
                                Icons.check_circle_rounded,
                                color: Colors.green,
                                size: 16.sp,
                              ),
                              SizedBox(width: 11.w),
                              Text(
                                'Төлсөн: $paidCount билл, ${formatNumberWithComma(paidTotal)}₮',
                                style: TextStyle(
                                  color: Colors.green,
                                  fontSize: 11.sp,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ],
                    ),
                  ),
                  SizedBox(height: 20.h),
                  // Bills Section Header
                  Row(
                    children: [
                      Container(
                        padding: EdgeInsets.all(8.w),
                        decoration: BoxDecoration(
                          color: AppColors.goldPrimary.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(11.r),
                        ),
                        child: Icon(
                          Icons.receipt_long_rounded,
                          color: AppColors.goldPrimary,
                          size: 20.sp,
                        ),
                      ),
                      SizedBox(width: 10.w),
                      Text(
                        'Биллүүд (${bills.length})',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 11.sp,
                          fontWeight: FontWeight.bold,
                          letterSpacing: -0.3,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 11.h),
                  if (bills.isEmpty)
                    Container(
                      padding: EdgeInsets.all(24.w),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            Colors.white.withOpacity(0.05),
                            Colors.white.withOpacity(0.02),
                          ],
                        ),
                        borderRadius: BorderRadius.circular(22.r),
                        border: Border.all(
                          color: Colors.white.withOpacity(0.1),
                          width: 1,
                        ),
                      ),
                      child: Center(
                        child: Column(
                          children: [
                            Icon(
                              Icons.receipt_long_outlined,
                              color: Colors.white.withOpacity(0.4),
                              size: 48.sp,
                            ),
                            SizedBox(height: 11.h),
                            Text(
                              'Билл байхгүй байна',
                              style: TextStyle(
                                color: Colors.white.withOpacity(0.6),
                                fontSize: 11.sp,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                    )
                  else
                    ...bills.map((bill) => _buildBillCard(bill)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildModernModalInfoRow(IconData icon, String label, String value) {
    if (value.isEmpty) return const SizedBox.shrink();

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: EdgeInsets.all(8.w),
          decoration: BoxDecoration(
            color: AppColors.goldPrimary.withOpacity(0.15),
            borderRadius: BorderRadius.circular(11.r),
          ),
          child: Icon(icon, color: AppColors.goldPrimary, size: 18.sp),
        ),
        SizedBox(width: 12.w),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  color: Colors.white.withOpacity(0.6),
                  fontSize: 11.sp,
                  fontWeight: FontWeight.w500,
                ),
              ),
              SizedBox(height: 4.h),
              Text(
                value,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 11.sp,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildBillCard(Map<String, dynamic> bill) {
    final billNo = bill['billNo']?.toString() ?? '';
    final billType = bill['billtype']?.toString() ?? '';
    final billerName = bill['billerName']?.toString() ?? '';
    final billPeriod = bill['billPeriod']?.toString() ?? '';
    final billTotalAmount =
        (bill['billTotalAmount'] as num?)?.toDouble() ?? 0.0;
    final billAmount = (bill['billAmount'] as num?)?.toDouble() ?? 0.0;
    final billLateFee = (bill['billLateFee'] as num?)?.toDouble() ?? 0.0;
    final isNew = bill['isNew'] == true;
    final hasVat = bill['hasVat'] == true;

    return Container(
      margin: EdgeInsets.only(bottom: 14.h),
      padding: EdgeInsets.all(18.w),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Colors.white.withOpacity(0.08),
            Colors.white.withOpacity(0.03),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(22.r),
        border: Border.all(color: Colors.white.withOpacity(0.15), width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: EdgeInsets.all(11.w),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      AppColors.goldPrimary.withOpacity(0.2),
                      AppColors.goldPrimary.withOpacity(0.1),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(11.r),
                ),
                child: Icon(
                  Icons.receipt_rounded,
                  color: AppColors.goldPrimary,
                  size: 22.sp,
                ),
              ),
              SizedBox(width: 12.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            billType,
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 11.sp,
                              fontWeight: FontWeight.bold,
                              letterSpacing: -0.3,
                            ),
                          ),
                        ),
                        if (isNew)
                          Container(
                            padding: EdgeInsets.symmetric(
                              horizontal: 8.w,
                              vertical: 4.h,
                            ),
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [
                                  Colors.blue.withOpacity(0.25),
                                  Colors.blue.withOpacity(0.15),
                                ],
                              ),
                              borderRadius: BorderRadius.circular(11.r),
                              border: Border.all(
                                color: Colors.blue.withOpacity(0.4),
                                width: 1,
                              ),
                            ),
                            child: Text(
                              'Шинэ',
                              style: TextStyle(
                                color: Colors.blue,
                                fontSize: 11.sp,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                      ],
                    ),
                    if (billerName.isNotEmpty) ...[
                      SizedBox(height: 6.h),
                      Row(
                        children: [
                          Icon(
                            Icons.business_rounded,
                            color: Colors.white.withOpacity(0.6),
                            size: 14.sp,
                          ),
                          SizedBox(width: 6.w),
                          Expanded(
                            child: Text(
                              billerName,
                              style: TextStyle(
                                color: Colors.white.withOpacity(0.7),
                                fontSize: 11.sp,
                                fontWeight: FontWeight.w600,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ],
                    if (billNo.isNotEmpty || billPeriod.isNotEmpty) ...[
                      SizedBox(height: 6.h),
                      Wrap(
                        spacing: 12.w,
                        children: [
                          if (billNo.isNotEmpty)
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.numbers_rounded,
                                  color: Colors.white.withOpacity(0.6),
                                  size: 14.sp,
                                ),
                                SizedBox(width: 4.w),
                                Text(
                                  billNo,
                                  style: TextStyle(
                                    color: Colors.white.withOpacity(0.7),
                                    fontSize: 11.sp,
                                  ),
                                ),
                              ],
                            ),
                          if (billPeriod.isNotEmpty)
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.calendar_today_rounded,
                                  color: Colors.white.withOpacity(0.6),
                                  size: 14.sp,
                                ),
                                SizedBox(width: 4.w),
                                Text(
                                  billPeriod,
                                  style: TextStyle(
                                    color: Colors.white.withOpacity(0.7),
                                    fontSize: 11.sp,
                                  ),
                                ),
                              ],
                            ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
          SizedBox(height: 11.h),
          Container(
            padding: EdgeInsets.all(14.w),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Colors.white.withOpacity(0.05),
                  Colors.white.withOpacity(0.02),
                ],
              ),
              borderRadius: BorderRadius.circular(11.r),
              border: Border.all(
                color: Colors.white.withOpacity(0.1),
                width: 1,
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Үндсэн дүн',
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.6),
                        fontSize: 11.sp,
                      ),
                    ),
                    SizedBox(height: 4.h),
                    Text(
                      '${formatNumberWithComma(billAmount)}₮',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 11.sp,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
                if (billLateFee > 0) ...[
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Text(
                        'Хоцролт',
                        style: TextStyle(
                          color: Colors.orange.withOpacity(0.8),
                          fontSize: 11.sp,
                        ),
                      ),
                      SizedBox(height: 4.h),
                      Text(
                        '${formatNumberWithComma(billLateFee)}₮',
                        style: TextStyle(
                          color: Colors.orange,
                          fontSize: 11.sp,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ],
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      'Нийт дүн',
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.6),
                        fontSize: 11.sp,
                      ),
                    ),
                    Text(
                      '${formatNumberWithComma(billTotalAmount)}₮',
                      style: TextStyle(
                        color: AppColors.goldPrimary,
                        fontSize: 11.sp,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          if (hasVat) ...[
            SizedBox(height: 10.h),
            Row(
              children: [
                Icon(
                  Icons.verified_rounded,
                  color: Colors.green.withOpacity(0.7),
                  size: 14.sp,
                ),
                SizedBox(width: 6.w),
                Text(
                  'НӨАТ-тай',
                  style: TextStyle(
                    color: Colors.green.withOpacity(0.8),
                    fontSize: 11.sp,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}



