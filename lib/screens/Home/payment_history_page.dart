import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:sukh_app/constants/constants.dart';
import 'package:sukh_app/services/api_service.dart';
import 'package:sukh_app/utils/theme_extensions.dart';
import 'package:sukh_app/widgets/standard_app_bar.dart';
import 'package:intl/intl.dart';
import 'package:sukh_app/models/payment_history_model.dart';
import 'package:sukh_app/components/Nekhemjlekh/nekhemjlekh_models.dart';

class PaymentHistoryPage extends StatefulWidget {
  final String billingId;
  final String billingName;
  final String customerName;
  final String customerAddress;
  final String? source;

  const PaymentHistoryPage({
    super.key,
    required this.billingId,
    required this.billingName,
    required this.customerName,
    required this.customerAddress,
    this.source,
  });

  @override
  State<PaymentHistoryPage> createState() => _PaymentHistoryPageState();
}

class _PaymentHistoryPageState extends State<PaymentHistoryPage> {
  bool _isLoading = true;
  List<PaymentHistory> _paymentHistory = [];
  final Set<String> _expandedPaymentIds = {};

  @override
  void initState() {
    super.initState();
    _loadPaymentHistory();
  }

  Future<void> _loadPaymentHistory() async {
    try {
      List<PaymentHistory> history = [];

      if (widget.source == 'OWN_ORG') {
        final res = await ApiService.fetchNekhemjlekhiinTuukh(
          gereeniiDugaar: widget.billingId,
          khuudasniiDugaar: 1,
          khuudasniiKhemjee: 200,
        );
        
        if (res['jagsaalt'] != null && res['jagsaalt'] is List) {
          final List<dynamic> list = res['jagsaalt'];
          List<PaymentHistory> flattenedHistory = [];
          
          for (var item in list) {
            final paymentTxList = item['paymentHistory'] as List?;
            
            if (paymentTxList != null && paymentTxList.isNotEmpty) {
              // Iterate through each payment transaction in the invoice
              for (var tx in paymentTxList) {
                final String txType = tx['turul']?.toString().toLowerCase() ?? '';
                // Only include actual payments, not adjustments like 'system_sync'
                if (txType == 'төлөлт' || txType == 'qpay') {
                  double txAmount = (tx['dun'] as num?)?.toDouble() ?? 0.0;
                  if (txAmount < 0) continue; // Skip sync/negative adjustments

                  flattenedHistory.add(PaymentHistory(
                    paymentId: tx['_id']?.toString() ?? '',
                    invoiceNo: item['nekhemjlekhiinDugaar']?.toString() ?? '',
                    paymentAmount: txAmount,
                    paymentStatus: 'PAID',
                    paymentStatusText: 'Төлсөн',
                    paymentStatusDate: DateTime.tryParse(tx['ognoo']?.toString() ?? '') ?? 
                                      DateTime.tryParse(item['ognoo']?.toString() ?? '') ?? 
                                      DateTime.now(),
                    bills: [
                      Bill(
                        billerName: widget.billingName,
                        billType: tx['tailbar']?.toString() ?? 'Орон сууцны төлбөр',
                        billNo: item['nekhemjlekhiinDugaar']?.toString() ?? '',
                        hasVat: true,
                        billTotalAmount: txAmount,
                        billPeriod: tx['ognoo']?.toString().substring(0, 7) ?? '', // YYYY-MM
                        billLateFee: 0.0,
                      )
                    ],
                  ));
                }
              }
            } else {
              // Backward compatibility: If no paymentHistory, show the invoice if it's marked as paid
              final String status = item['tuluv']?.toString() ?? '';
              if (status.contains('Төлсөн')) {
                double displayAmount = (item['tulsunDun'] as num?)?.toDouble() ?? 0.0;
                if (displayAmount <= 0) displayAmount = (item['niitTulburOriginal'] as num?)?.toDouble() ?? 0.0;
                
                flattenedHistory.add(PaymentHistory(
                  paymentId: item['_id']?.toString() ?? '',
                  invoiceNo: item['nekhemjlekhiinDugaar']?.toString() ?? '',
                  paymentAmount: displayAmount,
                  paymentStatus: 'PAID',
                  paymentStatusText: 'Төлсөн',
                  paymentStatusDate: DateTime.tryParse(item['updatedAt']?.toString() ?? '') ?? 
                                    DateTime.tryParse(item['ognoo']?.toString() ?? '') ?? 
                                    DateTime.now(),
                  bills: [
                    Bill(
                      billerName: widget.billingName,
                      billType: 'Орон сууцны төлбөр',
                      billNo: item['nekhemjlekhiinDugaar']?.toString() ?? '',
                      hasVat: true,
                      billTotalAmount: displayAmount,
                      billPeriod: item['ognoo']?.toString().substring(0, 7) ?? '',
                      billLateFee: (item['aldangi'] as num?)?.toDouble() ?? 0.0,
                    )
                  ],
                ));
              }
            }
          }
          
          // Sort by date descending (latest first)
          flattenedHistory.sort((a, b) => b.paymentStatusDate.compareTo(a.paymentStatusDate));
          history = flattenedHistory;
        }
      } else {
        // Original Wallet API history fetcher
        final List<Map<String, dynamic>> rawData = await ApiService.getWalletBillingPayments(
          billingId: widget.billingId,
        );
        
        List<PaymentHistory> flattenedWalletHistory = [];

        // Distinguish between a direct list of payments vs a list of bills containing payments
        for (var item in rawData) {
          if (item.containsKey('payments') && item['payments'] is List) {
            final List<dynamic> payments = item['payments'];
            flattenedWalletHistory.addAll(
              payments.map((e) => PaymentHistory.fromJson(Map<String, dynamic>.from(e)))
            );
          } else {
            // Assume the item itself is a payment object matching the model
            try {
              flattenedWalletHistory.add(PaymentHistory.fromJson(item));
            } catch (e) {
              print('⚠️ [History] Skipping invalid Wallet payment item: $e');
            }
          }
        }
        
        // Sort by date descending
        flattenedWalletHistory.sort((a, b) => b.paymentStatusDate.compareTo(a.paymentStatusDate));
        history = flattenedWalletHistory;
      }

      if (mounted) {
        setState(() {
          _paymentHistory = history;
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
                              // Replaced the original bill mapping with the new conditional logic
                              ...payment.bills.length > 1 ? [
                                Divider(
                                  height: 24.h,
                                  thickness: 1,
                                  color: isDark ? Colors.white10 : Colors.black.withOpacity(0.05),
                                ),
                                InkWell(
                                  onTap: () {
                                    setState(() {
                                      if (_expandedPaymentIds.contains(payment.paymentId)) {
                                        _expandedPaymentIds.remove(payment.paymentId);
                                      } else {
                                        _expandedPaymentIds.add(payment.paymentId);
                                      }
                                    });
                                  },
                                  child: Padding(
                                    padding: EdgeInsets.symmetric(vertical: 4.h),
                                    child: Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        Text(
                                          'Төлбөрийн задаргаа',
                                          style: TextStyle(
                                            fontSize: 13.sp,
                                            fontWeight: FontWeight.w600,
                                            color: context.textPrimaryColor.withOpacity(0.7),
                                          ),
                                        ),
                                        Icon(
                                          _expandedPaymentIds.contains(payment.paymentId)
                                              ? Icons.keyboard_arrow_up
                                              : Icons.keyboard_arrow_down,
                                          size: 20.sp,
                                          color: context.textPrimaryColor.withOpacity(0.7),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                                if (_expandedPaymentIds.contains(payment.paymentId)) ...[
                                  SizedBox(height: 12.h),
                                  ...payment.bills.asMap().entries.map((entry) {
                                    final index = entry.key;
                                    final bill = entry.value;
                                    return Column(
                                      children: [
                                        Padding(
                                          padding: EdgeInsets.symmetric(vertical: 8.h),
                                          child: Row(
                                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Expanded(
                                                child: Text(
                                                  bill.billType,
                                                  style: TextStyle(
                                                    fontSize: 14.sp,
                                                    color: context.textPrimaryColor.withOpacity(0.7),
                                                  ),
                                                ),
                                              ),
                                              SizedBox(width: 8.w),
                                              Text(
                                                '${NumberFormat('#,##0.00').format(bill.billTotalAmount)} ₮',
                                                style: TextStyle(
                                                  fontSize: 14.sp,
                                                  fontWeight: FontWeight.w500,
                                                  color: context.textPrimaryColor,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                        if (index < payment.bills.length - 1)
                                          Divider(
                                            height: 1,
                                            thickness: 0.5,
                                            color: isDark ? Colors.white.withOpacity(0.05) : Colors.black.withOpacity(0.05),
                                          ),
                                      ],
                                    );
                                  }).toList(),
                                ],
                              ] : [
                                SizedBox(height: 16.h),
                                ...payment.bills.map((bill) {
                                  return Padding(
                                    padding: EdgeInsets.only(bottom: 12.h),
                                    child: Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      crossAxisAlignment: CrossAxisAlignment.start,
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
                                          '${NumberFormat('#,##0.00').format(bill.billTotalAmount)} ₮', // Added ₮
                                          style: TextStyle(
                                            fontSize: 14.sp,
                                            fontWeight: FontWeight.w600,
                                            color: context.textPrimaryColor,
                                          ),
                                        ),
                                        SizedBox(width: 8.w),
                                        Text(
                                          '${NumberFormat('#,##0.00').format(bill.billLateFee)}',
                                          style: TextStyle(
                                            fontSize: 14.sp,
                                            fontWeight: FontWeight.w600,
                                            color: AppColors.error,
                                          ),
                                        ),
                                      ],
                                    ),
                                  );
                                }).toList(),
                              ],
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
