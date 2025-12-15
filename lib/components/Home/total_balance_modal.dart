import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:sukh_app/constants/constants.dart';
import 'package:sukh_app/widgets/optimized_glass.dart';

class TotalBalanceModal extends StatefulWidget {
  final double totalAmount;
  final List<Map<String, dynamic>> payments;
  final bool isLoading;
  final String Function(double) formatNumberWithComma;
  final VoidCallback onPaymentTap;

  const TotalBalanceModal({
    super.key,
    required this.totalAmount,
    required this.payments,
    required this.isLoading,
    required this.formatNumberWithComma,
    required this.onPaymentTap,
  });

  @override
  State<TotalBalanceModal> createState() => _TotalBalanceModalState();
}

class _TotalBalanceModalState extends State<TotalBalanceModal> {
  final Set<int> _expandedIndices = {};

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.85,
      width: double.infinity,
      child: Stack(
        children: [
          Positioned.fill(
            child: Container(color: Colors.black.withOpacity(0.5)),
          ),
          Positioned.fill(
            child: OptimizedGlass(
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(50.r),
                topRight: Radius.circular(50.r),
              ),
              // No real blur anywhere (avoid GPU-heavy BackdropFilter).
              opacity: 0.10,
              child: Container(
                padding: EdgeInsets.fromLTRB(24.w, 24.h, 24.w, 24.h),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Drag handle
                    Center(
                      child: Container(
                        margin: EdgeInsets.only(top: 8.h, bottom: 8.h),
                        width: 40.w,
                        height: 4.h,
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.3),
                          borderRadius: BorderRadius.circular(2.r),
                        ),
                      ),
                    ),
                    // Header
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            Icon(
                              Icons.account_balance_wallet_rounded,
                              color: AppColors.goldPrimary,
                              size: 24.sp,
                            ),
                            SizedBox(width: 11.w),
                            Text(
                              'Нийт үлдэгдэл',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 11.sp,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                        IconButton(
                          icon: Icon(
                            Icons.close_rounded,
                            color: Colors.white,
                            size: 22.sp,
                          ),
                          onPressed: () => Navigator.of(context).pop(),
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                        ),
                      ],
                    ),
                    SizedBox(height: 11.h),
                    // Total amount
                    Container(
                      padding: EdgeInsets.all(14.w),
                      decoration: BoxDecoration(
                        color: AppColors.goldPrimary.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(11.r),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Нийт дүн',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 11.sp,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          Text(
                            '${widget.formatNumberWithComma(widget.totalAmount)}₮',
                            style: TextStyle(
                              color: AppColors.goldPrimary,
                              fontSize: 11.sp,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                    SizedBox(height: 11.h),
                    // Billing list
                    if (widget.isLoading)
                      Center(
                        child: Padding(
                          padding: EdgeInsets.all(22.h),
                          child: CircularProgressIndicator(
                            color: AppColors.goldPrimary,
                          ),
                        ),
                      )
                    else if (widget.payments.isEmpty)
                      Center(
                        child: Padding(
                          padding: EdgeInsets.all(22.h),
                          child: Text(
                            'Төлбөр байхгүй байна',
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.6),
                              fontSize: 11.sp,
                            ),
                          ),
                        ),
                      )
                    else
                      Expanded(
                        child: ListView.builder(
                          itemCount: widget.payments.length,
                          itemBuilder: (context, index) {
                            final payment = widget.payments[index];
                            final source = payment['source'] as String;
                            final billingName =
                                payment['billingName']?.toString() ?? 'Биллинг';
                            final customerName =
                                payment['customerName']?.toString() ?? '';
                            final amount =
                                (payment['amount'] as num?)?.toDouble() ?? 0.0;
                            final isExpanded = _expandedIndices.contains(index);

                            return Container(
                              margin: EdgeInsets.only(bottom: 11.h),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(11.r),
                                border: Border.all(
                                  color: Colors.white.withOpacity(0.2),
                                  width: 1,
                                ),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Material(
                                    color: Colors.transparent,
                                    child: InkWell(
                                      onTap: () {
                                        setState(() {
                                          if (isExpanded) {
                                            _expandedIndices.remove(index);
                                          } else {
                                            _expandedIndices.add(index);
                                          }
                                        });
                                      },
                                      borderRadius: BorderRadius.circular(11.r),
                                      child: Padding(
                                        padding: EdgeInsets.all(14.w),
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Row(
                                              mainAxisAlignment:
                                                  MainAxisAlignment
                                                      .spaceBetween,
                                              children: [
                                                Expanded(
                                                  child: Column(
                                                    crossAxisAlignment:
                                                        CrossAxisAlignment
                                                            .start,
                                                    children: [
                                                      Text(
                                                        billingName,
                                                        style: TextStyle(
                                                          color: Colors.white,
                                                          fontSize: 11.sp,
                                                          fontWeight:
                                                              FontWeight.bold,
                                                        ),
                                                        maxLines: 1,
                                                        overflow: TextOverflow
                                                            .ellipsis,
                                                      ),
                                                      if (customerName
                                                          .isNotEmpty) ...[
                                                        SizedBox(height: 4.h),
                                                        Text(
                                                          customerName,
                                                          style: TextStyle(
                                                            color: Colors.white
                                                                .withOpacity(
                                                                  0.7,
                                                                ),
                                                            fontSize: 11.sp,
                                                          ),
                                                          maxLines: 1,
                                                          overflow: TextOverflow
                                                              .ellipsis,
                                                        ),
                                                      ],
                                                    ],
                                                  ),
                                                ),
                                                Row(
                                                  children: [
                                                    Container(
                                                      padding:
                                                          EdgeInsets.symmetric(
                                                            horizontal: 8.w,
                                                            vertical: 4.h,
                                                          ),
                                                      decoration: BoxDecoration(
                                                        color:
                                                            source == 'OWN_ORG'
                                                            ? Colors.blue
                                                                  .withOpacity(
                                                                    0.2,
                                                                  )
                                                            : Colors.green
                                                                  .withOpacity(
                                                                    0.2,
                                                                  ),
                                                        borderRadius:
                                                            BorderRadius.circular(
                                                              11.r,
                                                            ),
                                                      ),
                                                      child: Text(
                                                        source == 'OWN_ORG'
                                                            ? 'OWN_ORG'
                                                            : 'WALLET',
                                                        style: TextStyle(
                                                          color:
                                                              source ==
                                                                  'OWN_ORG'
                                                              ? Colors.blue
                                                              : Colors.green,
                                                          fontSize: 11.sp,
                                                          fontWeight:
                                                              FontWeight.w600,
                                                        ),
                                                      ),
                                                    ),
                                                    SizedBox(width: 8.w),
                                                    Icon(
                                                      isExpanded
                                                          ? Icons.expand_less
                                                          : Icons.expand_more,
                                                      color: Colors.white
                                                          .withOpacity(0.6),
                                                      size: 20.sp,
                                                    ),
                                                  ],
                                                ),
                                              ],
                                            ),
                                            SizedBox(height: 11.h),
                                            Row(
                                              mainAxisAlignment:
                                                  MainAxisAlignment
                                                      .spaceBetween,
                                              children: [
                                                Text(
                                                  'Төлөх дүн',
                                                  style: TextStyle(
                                                    color: Colors.white
                                                        .withOpacity(0.6),
                                                    fontSize: 11.sp,
                                                  ),
                                                ),
                                                Text(
                                                  '${widget.formatNumberWithComma(amount)}₮',
                                                  style: TextStyle(
                                                    color:
                                                        AppColors.goldPrimary,
                                                    fontSize: 11.sp,
                                                    fontWeight: FontWeight.bold,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ),
                                  if (isExpanded) ...[
                                    Divider(
                                      color: Colors.white.withOpacity(0.2),
                                      height: 1,
                                    ),
                                    Padding(
                                      padding: EdgeInsets.all(14.w),
                                      child: _buildPaymentDetails(payment),
                                    ),
                                  ],
                                ],
                              ),
                            );
                          },
                        ),
                      ),
                    SizedBox(height: 16.h),
                    // Төлөх button
                    if (widget.totalAmount > 0)
                      SizedBox(
                        width: double.infinity,
                        child: OptimizedGlass(
                          borderRadius: BorderRadius.circular(11.r),
                          child: Material(
                            color: Colors.transparent,
                            child: InkWell(
                              onTap: () {
                                Navigator.of(context).pop();
                                widget.onPaymentTap();
                              },
                              borderRadius: BorderRadius.circular(11.r),
                              child: Container(
                                padding: EdgeInsets.symmetric(
                                  horizontal: 20.w,
                                  vertical: 14.h,
                                ),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      Icons.payment_rounded,
                                      color: Colors.white,
                                      size: 22.sp,
                                    ),
                                    SizedBox(width: 11.w),
                                    Text(
                                      'Төлөх',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 11.sp,
                                        fontWeight: FontWeight.bold,
                                        letterSpacing: 0.5,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPaymentDetails(Map<String, dynamic> payment) {
    final source = payment['source'] as String;

    if (source == 'OWN_ORG') {
      final invoice = payment['invoice'] as Map<String, dynamic>?;
      if (invoice == null) return const SizedBox.shrink();

      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Нэхэмжлэхийн мэдээлэл',
            style: TextStyle(
              color: Colors.white,
              fontSize: 11.sp,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: 11.h),
          _buildDetailRow(
            'Нэхэмжлэхийн огноо',
            invoice['nekhemjlekhiinOgnoo']?.toString() ?? '',
          ),
          SizedBox(height: 8.h),
          _buildDetailRow('Төлөв', invoice['tuluv']?.toString() ?? ''),
          SizedBox(height: 8.h),
          _buildDetailRow(
            'Үндсэн дүн',
            '${widget.formatNumberWithComma((invoice['undsenDun'] as num?)?.toDouble() ?? 0.0)}₮',
          ),
          if (((invoice['hoctolt'] as num?)?.toDouble() ?? 0.0) > 0) ...[
            SizedBox(height: 8.h),
            _buildDetailRow(
              'Хоцролт',
              '${widget.formatNumberWithComma((invoice['hoctolt'] as num?)?.toDouble() ?? 0.0)}₮',
            ),
          ],
        ],
      );
    } else {
      // WALLET_API
      final bills = payment['bills'] as List<Map<String, dynamic>>?;
      if (bills == null || bills.isEmpty) return const SizedBox.shrink();

      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Биллүүд',
            style: TextStyle(
              color: Colors.white,
              fontSize: 11.sp,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: 11.h),
          ...bills.map((bill) {
            final billType = bill['billtype']?.toString() ?? '';
            final billPeriod = bill['billPeriod']?.toString() ?? '';
            final billTotalAmount =
                (bill['billTotalAmount'] as num?)?.toDouble() ?? 0.0;

            return Container(
              margin: EdgeInsets.only(bottom: 8.h),
              padding: EdgeInsets.all(11.w),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.05),
                borderRadius: BorderRadius.circular(11.r),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (billType.isNotEmpty)
                    Text(
                      billType,
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 11.sp,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  if (billPeriod.isNotEmpty) ...[
                    SizedBox(height: 4.h),
                    Text(
                      'Хугацаа: $billPeriod',
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.7),
                        fontSize: 11.sp,
                      ),
                    ),
                  ],
                  SizedBox(height: 4.h),
                  Text(
                    '${widget.formatNumberWithComma(billTotalAmount)}₮',
                    style: TextStyle(
                      color: AppColors.goldPrimary,
                      fontSize: 11.sp,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      );
    }
  }

  Widget _buildDetailRow(String label, String value) {
    if (value.isEmpty) return const SizedBox.shrink();

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            color: Colors.white.withOpacity(0.6),
            fontSize: 11.sp,
          ),
        ),
        Text(
          value,
          style: TextStyle(
            color: Colors.white,
            fontSize: 11.sp,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}
