import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:sukh_app/constants/constants.dart';
import 'package:sukh_app/services/api_service.dart';
import 'package:sukh_app/utils/theme_extensions.dart';
import 'package:sukh_app/widgets/standard_app_bar.dart';
import 'package:intl/intl.dart';
import 'package:sukh_app/models/payment_history_model.dart';

class PaymentHistoryPage extends StatefulWidget {
  final String billingId;
  final String billingName;
  final String customerName;
  final String customerAddress;

  const PaymentHistoryPage({
    super.key,
    required this.billingId,
    required this.billingName,
    required this.customerName,
    required this.customerAddress,
  });

  @override
  State<PaymentHistoryPage> createState() => _PaymentHistoryPageState();
}

class _PaymentHistoryPageState extends State<PaymentHistoryPage> {
  bool _isLoading = true;
  List<PaymentHistory> _paymentHistory = [];

  @override
  void initState() {
    super.initState();
    _loadPaymentHistory();
  }

  Future<void> _loadPaymentHistory() async {
    try {
      final historyData = await ApiService.getWalletBillingPayments(
        billingId: widget.billingId,
      );
      if (mounted) {
        setState(() {
          if (historyData.isNotEmpty &&
              historyData.first.containsKey('payments')) {
            final payments = historyData.first['payments'] as List;
            _paymentHistory = payments
                .map((e) => PaymentHistory.fromJson(e))
                .toList();
          } else {
            _paymentHistory = historyData
                .map((e) => PaymentHistory.fromJson(e))
                .toList();
          }
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(e.toString())));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = context.isDarkMode;

    return Scaffold(
      appBar: buildStandardAppBar(context, title: 'Төлбөрийн түүх'),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadPaymentHistory,
              child: CustomScrollView(
                slivers: [
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: EdgeInsets.all(16.w),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            widget.billingName,
                            style: TextStyle(
                              fontSize: 18.sp,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          SizedBox(height: 8.h),
                          Text(
                            widget.customerName,
                            style: TextStyle(fontSize: 14.sp),
                          ),
                          SizedBox(height: 4.h),
                          Text(
                            widget.customerAddress,
                            style: TextStyle(
                              fontSize: 12.sp,
                              color: context.textSecondaryColor,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  SliverPadding(
                    padding: EdgeInsets.symmetric(horizontal: 16.w),
                    sliver: SliverList(
                      delegate: SliverChildBuilderDelegate((context, index) {
                        final payment = _paymentHistory[index];
                        final currentMonth = DateFormat(
                          'yyyy-MM',
                        ).format(payment.paymentStatusDate);
                        final paymentDate = DateFormat(
                          'yyyy-MM-dd',
                        ).format(payment.paymentStatusDate);

                        return Container(
                          margin: EdgeInsets.only(bottom: 12.h),
                          padding: EdgeInsets.all(16.w),
                          decoration: BoxDecoration(
                            color: isDark
                                ? const Color(0xFF1C2229)
                                : Colors.white,
                            borderRadius: BorderRadius.circular(16.r),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.04),
                                blurRadius: 10,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: Column(
                            children: [
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    currentMonth,
                                    style: TextStyle(
                                      fontSize: 14.sp,
                                      fontWeight: FontWeight.w600,
                                      color: context.textPrimaryColor,
                                    ),
                                  ),
                                  Column(
                                    crossAxisAlignment: CrossAxisAlignment.end,
                                    children: [
                                      Text(
                                        paymentDate,
                                        style: TextStyle(
                                          fontSize: 12.sp,
                                          fontWeight: FontWeight.w400,
                                          color: context.textSecondaryColor,
                                        ),
                                      ),
                                      SizedBox(height: 4.h),
                                      Container(
                                        padding: EdgeInsets.symmetric(
                                          horizontal: 10.w,
                                          vertical: 4.h,
                                        ),
                                        decoration: BoxDecoration(
                                          color: const Color(0xFF4CAF50),
                                          borderRadius: BorderRadius.circular(
                                            8.r,
                                          ),
                                        ),
                                        child: Text(
                                          "Төлсөн",
                                          style: TextStyle(
                                            fontSize: 11.sp,
                                            fontWeight: FontWeight.w600,
                                            color: Colors.white,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                              SizedBox(height: 16.h),
                              ...payment.bills.map((bill) {
                                return Padding(
                                  padding: EdgeInsets.only(bottom: 12.h),
                                  child: Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Expanded(
                                        child: Text(
                                          bill.billType,
                                          style: TextStyle(
                                            fontSize: 14.sp,
                                            color: context.textPrimaryColor
                                                .withOpacity(0.8),
                                          ),
                                        ),
                                      ),
                                      SizedBox(width: 16.w),
                                      Text(
                                        '${NumberFormat('#,##0.00').format(bill.billTotalAmount)}₮',
                                        style: TextStyle(
                                          fontSize: 14.sp,
                                          fontWeight: FontWeight.w600,
                                          color: context.textPrimaryColor,
                                        ),
                                      ),
                                    ],
                                  ),
                                );
                              }).toList(),
                              Divider(
                                height: 24.h,
                                thickness: 1,
                                color: isDark
                                    ? Colors.white10
                                    : Colors.black.withOpacity(0.05),
                              ),
                              SizedBox(
                                width: double.infinity,
                                child: TextButton(
                                  onPressed: () {
                                    context.push('/ebarimt');
                                  },
                                  style: TextButton.styleFrom(
                                    padding: EdgeInsets.symmetric(
                                      vertical: 8.h,
                                    ),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(8.r),
                                    ),
                                  ),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(
                                        Icons.receipt_long_rounded,
                                        size: 16.sp,
                                        color: AppColors.deepGreen,
                                      ),
                                      SizedBox(width: 8.w),
                                      Text(
                                        'Баримт харах',
                                        style: TextStyle(
                                          fontSize: 13.sp,
                                          fontWeight: FontWeight.w500,
                                          color: AppColors.deepGreen,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        );
                      }, childCount: _paymentHistory.length),
                    ),
                  ),
                  SliverToBoxAdapter(child: SizedBox(height: 32.h)),
                ],
              ),
            ),
    );
  }

  // Grouping method is no longer used for the requested "not unified" design
}
