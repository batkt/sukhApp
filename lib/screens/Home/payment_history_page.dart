import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:sukh_app/constants/constants.dart';
import 'package:sukh_app/services/api_service.dart';
import 'package:sukh_app/utils/theme_extensions.dart';
import 'package:sukh_app/widgets/standard_app_bar.dart';
import 'package:sukh_app/components/Nekhemjlekh/vat_receipt_modal.dart';
import 'package:sukh_app/widgets/glass_snackbar.dart';
import 'package:intl/intl.dart';
import 'package:sukh_app/models/payment_history_model.dart';
import 'package:sukh_app/components/Nekhemjlekh/nekhemjlekh_models.dart';
import 'package:sukh_app/services/storage_service.dart';

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
        final baiguullagiinId = await StorageService.getBaiguullagiinId();
        final gereeResponse = await ApiService.fetchGeree(await StorageService.getUserId() ?? '');
        String? gereeniiId;
        if (gereeResponse['jagsaalt'] != null && (gereeResponse['jagsaalt'] as List).isNotEmpty) {
          final myGeree = (gereeResponse['jagsaalt'] as List).firstWhere(
            (g) => g['gereeniiDugaar'] == widget.billingId,
            orElse: () => null,
          );
          if (myGeree != null) gereeniiId = myGeree['_id']?.toString();
        }

        if (baiguullagiinId != null && gereeniiId != null) {
          final ledgerRes = await ApiService.fetchGereeniiHistoryLedger(
            gereeniiId: gereeniiId,
            baiguullagiinId: baiguullagiinId,
          );

          if (ledgerRes['jagsaalt'] != null && ledgerRes['jagsaalt'] is List) {
            final List<dynamic> ledgerRows = ledgerRes['jagsaalt'];
            List<PaymentHistory> flattenedHistory = [];

            for (var item in ledgerRows) {
              final String khelber = item['khelber']?.toString() ?? '';
              
              if (khelber == 'Орлого' || khelber == 'Төлөлт') {
                final amtStr = item['tulugdsun'] ?? item['tulukhDun'] ?? item['amount'] ?? 0.0;
                final amt = (amtStr as num).toDouble();
                if (amt <= 0) continue;
                
                final String tailbar = item['tailbar']?.toString() ?? 'Орлого';
                
                flattenedHistory.add(
                  PaymentHistory(
                    paymentId: item['_id']?.toString() ?? '',
                    invoiceNo: tailbar,
                    paymentAmount: amt,
                    paymentStatus: 'PAID',
                    paymentStatusText: 'Төлсөн',
                    paymentStatusDate: DateTime.tryParse(item['ognoo']?.toString() ?? item['burtgesenOgnoo']?.toString() ?? '') ?? DateTime.now(),
                    bills: [
                      Bill(
                        billerName: widget.billingName,
                        billType: 'Төлбөр',
                        billNo: tailbar,
                        hasVat: false,
                        billTotalAmount: amt,
                        billPeriod: '',
                        billLateFee: 0.0,
                      )
                    ],
                  ),
                );
              }
            }

            flattenedHistory.sort(
              (a, b) => b.paymentStatusDate.compareTo(a.paymentStatusDate),
            );
            history = flattenedHistory;
          }
        }
      } else {
        // Original Wallet API history fetcher — from wallet/billing/bills
        final List<Map<String, dynamic>> rawData =
            await ApiService.getWalletBillingPayments(
              billingId: widget.billingId,
            );

        List<PaymentHistory> flattenedWalletHistory = [];

        // Distinguish between a direct list of payments vs a list of bills containing payments
        for (var item in rawData) {
          if (item.containsKey('payments') && item['payments'] is List) {
            final List<dynamic> payments = item['payments'];
            flattenedWalletHistory.addAll(
              payments.map(
                (e) {
                  final pay = PaymentHistory.fromJson(Map<String, dynamic>.from(e));
                  // Show PENDING as paid optimistically (bank is processing)
                  if (pay.paymentStatus == 'PENDING') {
                    return pay.copyWith(
                      paymentStatus: 'PENDING',
                      paymentStatusText: 'Хүлээгдэж байна',
                    );
                  }
                  return pay;
                }
              ),
            );
          } else {
            try {
              final pay = PaymentHistory.fromJson(item);
              flattenedWalletHistory.add(pay);
            } catch (e) {
              print('⚠️ [History] Skipping invalid Wallet payment item: $e');
            }
          }
        }

        // Deduplicate by composite key (amount + time) to merge identical wallet transactions spanning multiple bills
        final Map<String, PaymentHistory> uniqueWalletAuth = {};
        for (var p in flattenedWalletHistory) {
          // Create a composite key: amount + ISO date (down to minute precision)
          final dateStr = DateFormat("yyyy-MM-ddTHH:mm:ss").format(p.paymentStatusDate);
          final compositeKey = '${p.paymentAmount}_$dateStr';
          
          if (!uniqueWalletAuth.containsKey(compositeKey)) {
            uniqueWalletAuth[compositeKey] = p;
          } else {
            // Transaction already exists, but might have different bills attached. Merge them!
            final existing = uniqueWalletAuth[compositeKey]!;
            final existingBillNos = existing.bills.map((b) => b.billNo).toSet();
            final newBills = List<Bill>.from(existing.bills);
            
            for (var b in p.bills) {
              if (!existingBillNos.contains(b.billNo)) {
                newBills.add(b);
              }
            }
            
            uniqueWalletAuth[compositeKey] = existing.copyWith(bills: newBills);
          }
        }
        flattenedWalletHistory = uniqueWalletAuth.values.toList();

        // Also pull directly from WQ list to catch PENDING payments not yet in billing/bills
        try {
          final wqList = await ApiService.fetchWalletQpayList();
          final existingIds = flattenedWalletHistory.map((p) => p.paymentId).toSet();

          for (var h in wqList.take(10)) {
            final wId = h['walletPaymentId']?.toString() ?? '';
            final zakhNo = h['zakhialgiinDugaar']?.toString() ?? '';
            final checkId = wId.isNotEmpty ? wId : zakhNo;
            if (checkId.isEmpty || existingIds.contains(checkId)) continue;

            try {
              final st = await ApiService.walletQpayWalletCheck(walletPaymentId: checkId);
              if (st['success'] != true || st['data'] == null) continue;

              final walletData = st['data'];
              final state = walletData['paymentStatus']?.toString().toUpperCase() ?? '';
              if (state != 'PAID' && state != 'PENDING') continue;

              // Check if this WQ payment is for our billingId by matching billingName
              final lines = walletData['lines'] as List?;
              // Try to identify if it's for this billing by amount presence
              final amount = (walletData['totalAmount'] ?? walletData['amount'] ?? 0);
              if ((amount as num) <= 0) continue;

              final stateText = state == 'PAID' ? 'Төлөгдсөн' : 'Хүлээгдэж байна';
              final payDate = DateTime.tryParse(h['createdAt']?.toString() ?? '') ??
                  DateTime.tryParse(walletData['createdAt']?.toString() ?? '') ?? DateTime.now();

              // Build bills from lines
              List<Bill> bills = [];
              if (lines != null && lines.isNotEmpty) {
                for (var line in lines) {
                  bills.add(Bill(
                    billerName: line['billerName']?.toString() ?? widget.billingName,
                    billType: line['billtype']?.toString() ?? 'Төлбөр',
                    billNo: line['billNo']?.toString() ?? '',
                    hasVat: line['hasVat'] == true,
                    billTotalAmount: ((line['billTotalAmount'] ?? line['billAmount'] ?? 0) as num).toDouble(),
                    billPeriod: line['billPeriod']?.toString() ?? '',
                    billLateFee: ((line['billLateFee'] ?? 0) as num).toDouble(),
                  ));
                }
              }
              if (bills.isEmpty) {
                bills = [Bill(
                  billerName: widget.billingName,
                  billType: 'Төлбөр',
                  billNo: walletData['invoiceNo']?.toString() ?? checkId,
                  hasVat: false,
                  billTotalAmount: (amount as num).toDouble(),
                  billPeriod: '',
                  billLateFee: 0,
                )];
              }

              flattenedWalletHistory.add(PaymentHistory(
                paymentId: checkId,
                invoiceNo: walletData['invoiceNo']?.toString() ?? zakhNo,
                paymentAmount: (amount as num).toDouble(),
                paymentStatus: state,
                paymentStatusText: stateText,
                paymentStatusDate: payDate,
                bills: bills,
              ));
              existingIds.add(checkId);
            } catch (_) {}
          }
        } catch (_) {}

        // Sort by date descending
        flattenedWalletHistory.sort(
          (a, b) => b.paymentStatusDate.compareTo(a.paymentStatusDate),
        );
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

  Map<String, List<PaymentHistory>> _groupHistoryByMonth() {
    final Map<String, List<PaymentHistory>> groups = {};
    for (var payment in _paymentHistory) {
      final month = DateFormat(
        'yyyy оны MM сар',
        'mn_MN',
      ).format(payment.paymentStatusDate);
      if (!groups.containsKey(month)) {
        groups[month] = [];
      }
      groups[month]!.add(payment);
    }
    return groups;
  }

  double _calculateMonthTotal(List<PaymentHistory> monthPayments) {
    return monthPayments.fold(0.0, (sum, p) => sum + p.paymentAmount);
  }

  Future<void> _showEbarimtModal(String paymentId) async {
    // E-Barimt is only available for WALLET_API payments, not OWN_ORG
    if (widget.source?.toUpperCase() == 'OWN_ORG') {
      showGlassSnackBar(
        context,
        message: 'И-Баримт үүсээгүй байна.',
        icon: Icons.info_outline,
      );
      return;
    }

    try {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(child: CircularProgressIndicator()),
      );

      final response = await ApiService.walletQpayWalletCheck(
        walletPaymentId: paymentId,
      );

      if (mounted) Navigator.pop(context); // Close loading

      if (response['success'] == true && response['data'] != null) {
        final walletData = response['data'];
        if (walletData['vatInformation'] != null) {
          final receipt = VATReceipt.fromWalletPayment(walletData);
          if (mounted) {
            showModalBottomSheet(
              context: context,
              isScrollControlled: true,
              backgroundColor: Colors.transparent,
              builder: (context) => VATReceiptModal(receipt: receipt),
            );
          }
        } else {
          if (mounted) {
            showGlassSnackBar(
              context,
              message: 'Энэ төлбөрт И-Баримт үүсээгүй байна',
              icon: Icons.info_outline,
            );
          }
        }
      } else {
        throw Exception(response['message'] ?? 'Мэдээлэл авахад алдаа гарлаа');
      }
    } catch (e) {
      if (mounted) {
        if (Navigator.canPop(context)) Navigator.pop(context);
        showGlassSnackBar(
          context,
          message: 'Алдаа: ${e.toString().replaceAll('Exception: ', '')}',
          icon: Icons.error_outline,
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = context.isDarkMode;
    final grouped = _groupHistoryByMonth();
    final months = grouped.keys.toList();

    final double grandTotal = _paymentHistory.fold(0.0, (sum, p) => sum + p.paymentAmount);

    return Scaffold(
      backgroundColor: isDark
          ? const Color(0xFF0F172A)
          : const Color(0xFFF1F5F9),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : CustomScrollView(
              physics: const BouncingScrollPhysics(),
              slivers: [
                // ── PREMIUM HEADER REDESIGN ──
                SliverAppBar(
                  expandedHeight: 280.h,
                  pinned: true,
                  stretch: true,
                  backgroundColor: AppColors.deepGreen,
                  elevation: 0,
                  automaticallyImplyLeading: false,
                  flexibleSpace: FlexibleSpaceBar(
                    stretchModes: const [
                      StretchMode.zoomBackground,
                      StretchMode.blurBackground,
                    ],
                    background: Container(
                      color: AppColors.deepGreen,
                      child: Stack(
                        fit: StackFit.expand,
                        children: [
                          // Abstract Background Decoration
                          Positioned(
                            right: -30.w,
                            top: -20.h,
                            child: CircleAvatar(
                              radius: 100.r,
                              backgroundColor: Colors.white.withOpacity(0.03),
                            ),
                          ),
                          
                          Padding(
                            padding: EdgeInsets.fromLTRB(20.w, MediaQuery.of(context).padding.top + 80.h, 20.w, 50.h),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // Stats Row: Usage with Pill Total
                                Row(
                                  crossAxisAlignment: CrossAxisAlignment.center,
                                  children: [
                                    Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          'Нийт төлөлт',
                                          style: TextStyle(
                                            color: Colors.white.withOpacity(0.5),
                                            fontSize: 13.sp,
                                            fontWeight: FontWeight.w600,
                                            letterSpacing: 0.2,
                                          ),
                                        ),
                                        SizedBox(height: 2.h),
                                        Row(
                                          crossAxisAlignment: CrossAxisAlignment.baseline,
                                          textBaseline: TextBaseline.alphabetic,
                                          children: [
                                            Text(
                                              '${_paymentHistory.length}',
                                              style: TextStyle(
                                                color: Colors.white,
                                                fontSize: 48.sp,
                                                fontWeight: FontWeight.w900,
                                                height: 1.1,
                                                letterSpacing: -1.5,
                                              ),
                                            ),
                                            SizedBox(width: 8.w),
                                            Text(
                                              'удаа',
                                              style: TextStyle(
                                                color: Colors.white.withOpacity(0.4),
                                                fontSize: 20.sp,
                                                fontWeight: FontWeight.w600,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                    const Spacer(),
                                    // Total Amount Pill Box
                                    Container(
                                      padding: EdgeInsets.symmetric(horizontal: 18.w, vertical: 14.h),
                                      decoration: BoxDecoration(
                                        color: Colors.white.withOpacity(0.06),
                                        borderRadius: BorderRadius.circular(22.r),
                                        border: Border.all(color: Colors.white.withOpacity(0.08)),
                                      ),
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.end,
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Text(
                                            '${NumberFormat('#,##0').format(grandTotal)} ₮',
                                            style: TextStyle(
                                              color: Colors.white,
                                              fontSize: 20.sp,
                                              fontWeight: FontWeight.w900,
                                              letterSpacing: -0.5,
                                            ),
                                          ),
                                          SizedBox(height: 1.h),
                                          Text(
                                            'Нийт дүн',
                                            style: TextStyle(
                                              color: Colors.white.withOpacity(0.35),
                                              fontSize: 11.sp,
                                              fontWeight: FontWeight.w700,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                                
                                const Spacer(),
                                
                                // Address Bar
                                Container(
                                  padding: EdgeInsets.symmetric(horizontal: 18.w, vertical: 14.h),
                                  decoration: BoxDecoration(
                                    color: Colors.black.withOpacity(0.12),
                                    borderRadius: BorderRadius.circular(22.r),
                                    border: Border.all(color: Colors.white.withOpacity(0.04)),
                                  ),
                                  child: Row(
                                    children: [
                                      Icon(
                                        Icons.location_on_rounded,
                                        color: Colors.white.withOpacity(0.3),
                                        size: 18.sp,
                                      ),
                                      SizedBox(width: 12.w),
                                      Expanded(
                                        child: Text(
                                          widget.customerAddress.isEmpty ? widget.billingName : widget.customerAddress,
                                          style: TextStyle(
                                            color: Colors.white.withOpacity(0.6),
                                            fontSize: 13.sp,
                                            fontWeight: FontWeight.w600,
                                            letterSpacing: 0.1,
                                            height: 1.2,
                                          ),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  bottom: PreferredSize(
                    preferredSize: const Size.fromHeight(20),
                    child: Container(
                      height: 20.h,
                      decoration: BoxDecoration(
                        color: isDark
                            ? const Color(0xFF0F172A)
                            : const Color(0xFFF1F5F9),
                        borderRadius: BorderRadius.only(
                          topLeft: Radius.circular(30.r),
                          topRight: Radius.circular(30.r),
                        ),
                      ),
                    ),
                  ),
                  leading: Padding(
                    padding: EdgeInsets.only(left: 16.w, top: 8.h),
                    child: Center(
                      child: IconButton(
                        icon: Container(
                          width: 42.w,
                          height: 42.w,
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.12),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            Icons.chevron_left_rounded,
                            color: Colors.white,
                            size: 24.sp,
                          ),
                        ),
                        onPressed: () => Navigator.pop(context),
                        padding: EdgeInsets.zero,
                      ),
                    ),
                  ),
                  title: Padding(
                    padding: EdgeInsets.only(top: 8.h),
                    child: Text(
                      'Төлбөрийн түүх',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 18.sp,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
                  centerTitle: true,
                ),

                // ── PAYMENT LIST ──
                if (_paymentHistory.isEmpty)
                  SliverFillRemaining(
                    hasScrollBody: false,
                    child: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.history_rounded,
                            size: 100.sp,
                            color: Colors.grey.withOpacity(0.2),
                          ),
                          SizedBox(height: 24.h),
                          Text(
                            'Төлөлт хийгдээгүй байна',
                            style: TextStyle(
                              color: Colors.grey,
                              fontSize: 14.sp,
                            ),
                          ),
                        ],
                      ),
                    ),
                  )
                else
                  ...months.map((month) {
                    final payments = grouped[month]!;
                    final monthTotal = _calculateMonthTotal(payments);

                    return SliverPadding(
                      padding: EdgeInsets.fromLTRB(20.w, 10.h, 20.w, 20.h),
                      sliver: SliverMainAxisGroup(
                        slivers: [
                          SliverToBoxAdapter(
                            child: Padding(
                              padding: EdgeInsets.only(bottom: 16.h, left: 4.w),
                              child: Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                textBaseline: TextBaseline.alphabetic,
                                crossAxisAlignment: CrossAxisAlignment.baseline,
                                children: [
                                  Text(
                                    month.toUpperCase(),
                                    style: TextStyle(
                                      fontSize: 13.sp,
                                      fontWeight: FontWeight.w800,
                                      color: isDark
                                          ? const Color(0xFF94A3B8)
                                          : const Color(0xFF475569),
                                      letterSpacing: 1.2,
                                    ),
                                  ),
                                  // Text(
                                  //   '${NumberFormat('#,##0').format(monthTotal)} ₮',
                                  //   style: TextStyle(
                                  //     fontSize: 14.sp,
                                  //     fontWeight: FontWeight.w600,
                                  //     color: isDark
                                  //         ? Colors.white70
                                  //         : Colors.black87,
                                  //   ),
                                  // ),
                                ],
                              ),
                            ),
                          ),
                          SliverList(
                            delegate: SliverChildBuilderDelegate(
                              (context, index) => _buildModernHistoryCard(
                                payments[index],
                                isDark,
                              ),
                              childCount: payments.length,
                            ),
                          ),
                        ],
                      ),
                    );
                  }),
                SliverToBoxAdapter(child: SizedBox(height: 50.h)),
              ],
            ),
    );
  }

  Widget _buildModernHistoryCard(PaymentHistory payment, bool isDark) {
    final dayStr = DateFormat('dd').format(payment.paymentStatusDate);
    final weekdayStr = DateFormat(
      'EEE',
      'mn_MN',
    ).format(payment.paymentStatusDate);
    final timeStr = DateFormat('HH:mm').format(payment.paymentStatusDate);

    final accentColor = isDark ? const Color(0xFF10B981) : AppColors.deepGreen;

    final isExpanded = _expandedPaymentIds.contains(payment.paymentId);

    return Container(
      margin: EdgeInsets.only(bottom: 16.h),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(20.r),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDark ? 0.3 : 0.04),
            blurRadius: 15,
            spreadRadius: 2,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            setState(() {
              if (isExpanded) {
                _expandedPaymentIds.remove(payment.paymentId);
              } else {
                _expandedPaymentIds.add(payment.paymentId);
              }
            });
          },
          borderRadius: BorderRadius.circular(20.r),
          child: Column(
            children: [
              Padding(
                padding: EdgeInsets.fromLTRB(16.w, 16.h, 16.w, 12.h),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    // Date Column
                Container(
                  width: 50.w,
                  height: 50.w,
                  decoration: BoxDecoration(
                    color: accentColor.withOpacity(
                      isDark ? 0.2 : 0.08,
                    ),
                    borderRadius: BorderRadius.circular(12.r),
                  ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          DateFormat('MMM', 'mn_MN').format(payment.paymentStatusDate).toUpperCase(),
                          style: TextStyle(
                            fontSize: 10.sp,
                            fontWeight: FontWeight.bold,
                            color: isDark ? Colors.white70 : accentColor.withOpacity(0.6),
                          ),
                        ),
                        Text(
                          dayStr,
                          style: TextStyle(
                            fontSize: 18.sp,
                            fontWeight: FontWeight.w900,
                            color: isDark ? Colors.white : accentColor,
                            height: 1,
                          ),
                        ),
                      ],
                    ),
                ),
                SizedBox(width: 16.w),
                // Info Section
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        payment.bills.length > 1
                            ? '${payment.bills.length} нэхэмжлэх'
                            : payment.bills.first.billType,
                        style: TextStyle(
                          fontSize: 15.sp,
                          fontWeight: FontWeight.w700,
                          color: isDark
                              ? Colors.white
                              : const Color(0xFF334155),
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      SizedBox(height: 4.h),
                      Row(
                        children: [
                          Flexible(
                            child: Text(
                              payment.paymentStatus == 'PENDING'
                                  ? 'Хүлээгдэж байна'
                                  : 'Төлөгдсөн',
                              style: TextStyle(
                                fontSize: 13.sp,
                                fontWeight: FontWeight.w600,
                                color: payment.paymentStatus == 'PENDING'
                                    ? Colors.orange
                                    : (isDark ? accentColor : accentColor),
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                SizedBox(width: 12.w),
                // Amount Section
                Text(
                  '${NumberFormat('#,##0').format(payment.paymentAmount)} ₮',
                  style: TextStyle(
                    fontSize: 16.sp,
                    fontWeight: FontWeight.w900,
                    color: isDark ? Colors.white : const Color(0xFF334155),
                  ),
                ),
                SizedBox(width: 8.w),
                Icon(
                  isExpanded ? Icons.keyboard_arrow_up_rounded : Icons.keyboard_arrow_down_rounded,
                  color: isDark ? Colors.white54 : Colors.grey,
                  size: 20.sp,
                ),
              ],
            ),
          ),

          if (isExpanded) ...[
            Divider(height: 1, color: isDark ? Colors.white10 : Colors.black.withOpacity(0.05)),
            Padding(
              padding: EdgeInsets.all(16.w),
              child: Column(
                children: payment.bills.map((bill) {
                  return Padding(
                    padding: EdgeInsets.only(bottom: 8.h),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            bill.billNo.isNotEmpty ? '${bill.billType} (${bill.billNo})' : bill.billType,
                            style: TextStyle(
                              fontSize: 12.sp,
                              color: isDark ? Colors.white70 : Colors.black87,
                            ),
                          ),
                        ),
                        Text(
                          '${NumberFormat('#,##0').format(bill.billTotalAmount)} ₮',
                          style: TextStyle(
                            fontSize: 13.sp,
                            fontWeight: FontWeight.w600,
                            color: isDark ? Colors.white : Colors.black87,
                          ),
                        ),
                      ],
                    ),
                  );
                }).toList(),
              ),
            ),
          ],

          // Action Button - Always visible and easy to use
          Padding(
            padding: EdgeInsets.fromLTRB(16.w, 0, 16.w, 16.h),
            child: Row(
              children: [
                Expanded(
                  child: InkWell(
                    onTap: () => _showEbarimtModal(payment.paymentId),
                    borderRadius: BorderRadius.circular(12.r),
                    child: Container(
                      height: 42.h,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12.r),
                        color: isDark ? Colors.white.withOpacity(0.08) : accentColor.withOpacity(0.08),
                        border: Border.all(
                          color: isDark ? Colors.white.withOpacity(0.1) : accentColor.withOpacity(0.2),
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.receipt_long_rounded,
                            color: isDark ? Colors.white : accentColor,
                            size: 18.sp,
                          ),
                          SizedBox(width: 10.w),
                          Text(
                            'ЦАХИМ ТӨЛБӨРИЙН БАРИМТ ХАРАХ',
                            style: TextStyle(
                              color: isDark ? Colors.white : accentColor,
                              fontSize: 11.sp,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
            ],
          ),
        ),
      ),
    );
  }
}
