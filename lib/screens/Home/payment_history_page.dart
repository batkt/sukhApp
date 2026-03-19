import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:sukh_app/constants/constants.dart';
import 'package:sukh_app/services/api_service.dart';
import 'package:sukh_app/utils/theme_extensions.dart';
import 'package:sukh_app/widgets/standard_app_bar.dart';
import 'package:intl/intl.dart';

class PaymentHistoryPage extends StatefulWidget {
  final String billingId;
  final String billingName;
  final String Function(String) expandAddressAbbreviations;
  final String Function(double) formatNumberWithComma;

  const PaymentHistoryPage({
    super.key,
    required this.billingId,
    required this.billingName,
    required this.expandAddressAbbreviations,
    required this.formatNumberWithComma,
  });

  @override
  State<PaymentHistoryPage> createState() => _PaymentHistoryPageState();
}

class _PaymentHistoryPageState extends State<PaymentHistoryPage> {
  List<Map<String, dynamic>> _paymentHistory = [];
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadPaymentHistory();
  }

  Future<void> _loadPaymentHistory() async {
    try {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });

      final payments = await ApiService.getWalletBillingPayments(
        billingId: widget.billingId,
      );

      if (!mounted) return;

      setState(() {
        _paymentHistory = List<Map<String, dynamic>>.from(payments);
        _isLoading = false;
      });
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _errorMessage = e.toString().replaceFirst('Exception: ', '');
        });
      }
    }
  }

  String _formatDate(String? dateString) {
    if (dateString == null || dateString.isEmpty) return 'Огноо тодорхойгүй';

    try {
      final dateTime = DateTime.parse(dateString);
      return DateFormat('yyyy.MM.dd HH:mm').format(dateTime);
    } catch (e) {
      return dateString;
    }
  }

  String _getPaymentStatus(String? status) {
    switch (status?.toUpperCase()) {
      case 'PAID':
        return 'Төлсөн';
      case 'PENDING':
        return 'Төлөгдөөгүй';
      case 'FAILED':
        return 'Амжилтгүй';
      case 'CANCELLED':
        return 'Цуцлагдсан';
      default:
        return status ?? 'Тодорхойгүй';
    }
  }

  Color _getStatusColor(String? status) {
    switch (status?.toUpperCase()) {
      case 'PAID':
        return AppColors.success;
      case 'PENDING':
        return AppColors.warning;
      case 'FAILED':
        return AppColors.error;
      case 'CANCELLED':
        return AppColors.neutralGray;
      default:
        return AppColors.neutralGray;
    }
  }

  @override
  Widget build(BuildContext context) {
    final primaryColor = context.isDarkMode
        ? AppColors.deepGreenAccent
        : AppColors.deepGreen;
    final backgroundColor = context.backgroundColor;
    final surfaceColor = context.surfaceColor;
    final textPrimary = context.textPrimaryColor;
    final textSecondary = context.textSecondaryColor;

    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: buildStandardAppBar(
        context,
        title: 'ТӨЛБӨРИЙН ТҮҮХ',
        onBackPressed: () => Navigator.of(context).pop(),
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator(color: primaryColor))
          : _errorMessage != null
          ? Center(
              child: Padding(
                padding: EdgeInsets.all(40.w),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      padding: EdgeInsets.all(24.w),
                      decoration: BoxDecoration(
                        color: primaryColor.withOpacity(0.1),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.error_outline_rounded,
                        color: primaryColor,
                        size: 48.sp,
                      ),
                    ),
                    SizedBox(height: 24.h),
                    Text(
                      _errorMessage!,
                      style: TextStyle(color: textPrimary, fontSize: 16.sp),
                      textAlign: TextAlign.center,
                    ),
                    SizedBox(height: 32.h),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _loadPaymentHistory,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: primaryColor,
                          foregroundColor: Colors.white,
                          padding: EdgeInsets.symmetric(vertical: 16.h),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16.r),
                          ),
                          elevation: 0,
                        ),
                        child: Text(
                          'ДАХИН АЧААЛАХ',
                          style: TextStyle(fontSize: 13.sp, letterSpacing: 1.1),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            )
          : _paymentHistory.isEmpty
          ? Center(
              child: Padding(
                padding: EdgeInsets.all(40.w),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      padding: EdgeInsets.all(24.w),
                      decoration: BoxDecoration(
                        color: textSecondary.withOpacity(0.1),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.history,
                        color: textSecondary.withOpacity(0.5),
                        size: 48.sp,
                      ),
                    ),
                    SizedBox(height: 24.h),
                    Text(
                      'Төлбөрийн түүх байхгүй',
                      style: TextStyle(color: textPrimary, fontSize: 16.sp),
                    ),
                    SizedBox(height: 8.h),
                    Text(
                      '${widget.billingName}-д төлсөн төлбөр олдсонгүй',
                      style: TextStyle(
                        color: textSecondary.withOpacity(0.6),
                        fontSize: 12.sp,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            )
          : RefreshIndicator(
              onRefresh: _loadPaymentHistory,
              color: primaryColor,
              child: CustomScrollView(
                slivers: [
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: EdgeInsets.fromLTRB(20.w, 20.h, 20.w, 10.h),
                      child: Container(
                        padding: EdgeInsets.all(20.w),
                        decoration: BoxDecoration(
                          color: surfaceColor,
                          borderRadius: BorderRadius.circular(24.r),
                          border: Border.all(
                            color: textPrimary.withOpacity(0.04),
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.03),
                              blurRadius: 15,
                              offset: const Offset(0, 5),
                            ),
                          ],
                        ),
                        child: Row(
                          children: [
                            Container(
                              padding: EdgeInsets.all(10.w),
                              decoration: BoxDecoration(
                                color: primaryColor.withOpacity(0.05),
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                Icons.receipt_long_outlined,
                                size: 18.sp,
                                color: primaryColor,
                              ),
                            ),
                            SizedBox(width: 16.w),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'БИЛЛЕР',
                                    style: TextStyle(
                                      color: textSecondary.withOpacity(0.4),
                                      fontSize: 9.sp,
                                      letterSpacing: 1.0,
                                    ),
                                  ),
                                  SizedBox(height: 4.h),
                                  Text(
                                    widget.billingName,
                                    style: TextStyle(
                                      color: textPrimary.withOpacity(0.8),
                                      fontSize: 13.sp,
                                      height: 1.3,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  SliverPadding(
                    padding: EdgeInsets.fromLTRB(20.w, 10.h, 20.w, 20.h),
                    sliver: SliverList(
                      delegate: SliverChildBuilderDelegate((context, index) {
                        final payment = _paymentHistory[index];
                        final amount =
                            (payment['amount'] as num?)?.toDouble() ?? 0.0;
                        final status = payment['status']?.toString() ?? '';
                        final createdAt = payment['createdAt']?.toString();
                        final billerName =
                            payment['billerName']?.toString() ??
                            widget.billingName;
                        final billPeriod =
                            payment['billPeriod']?.toString() ?? '';

                        return Padding(
                          padding: EdgeInsets.only(bottom: 12.h),
                          child: Container(
                            padding: EdgeInsets.all(16.w),
                            decoration: BoxDecoration(
                              color: surfaceColor,
                              borderRadius: BorderRadius.circular(20.r),
                              border: Border.all(
                                color: textPrimary.withOpacity(0.03),
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.02),
                                  blurRadius: 10,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Container(
                                      padding: EdgeInsets.symmetric(
                                        horizontal: 8.w,
                                        vertical: 4.h,
                                      ),
                                      decoration: BoxDecoration(
                                        color: _getStatusColor(
                                          status,
                                        ).withOpacity(0.1),
                                        borderRadius: BorderRadius.circular(
                                          8.r,
                                        ),
                                      ),
                                      child: Text(
                                        _getPaymentStatus(status),
                                        style: TextStyle(
                                          color: _getStatusColor(status),
                                          fontSize: 10.sp,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    ),
                                    const Spacer(),
                                    Text(
                                      widget.formatNumberWithComma(amount),
                                      style: TextStyle(
                                        color: primaryColor,
                                        fontSize: 16.sp,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ],
                                ),
                                SizedBox(height: 12.h),
                                if (billPeriod.isNotEmpty) ...[
                                  Text(
                                    billPeriod,
                                    style: TextStyle(
                                      color: textPrimary.withOpacity(0.8),
                                      fontSize: 13.sp,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                  SizedBox(height: 4.h),
                                ],
                                if (billerName.isNotEmpty) ...[
                                  Text(
                                    billerName,
                                    style: TextStyle(
                                      color: textSecondary.withOpacity(0.4),
                                      fontSize: 10.sp,
                                    ),
                                  ),
                                  SizedBox(height: 1.h),
                                ],
                                Text(
                                  _formatDate(createdAt),
                                  style: TextStyle(
                                    color: textSecondary.withOpacity(0.4),
                                    fontSize: 10.sp,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      }, childCount: _paymentHistory.length),
                    ),
                  ),
                  SliverToBoxAdapter(child: SizedBox(height: 100.h)),
                ],
              ),
            ),
    );
  }
}
