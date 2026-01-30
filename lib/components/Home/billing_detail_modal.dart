import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:sukh_app/constants/constants.dart';
import 'package:sukh_app/services/api_service.dart';
import 'package:sukh_app/utils/responsive_helper.dart';
import 'package:sukh_app/utils/theme_extensions.dart';

class BillingDetailModal extends StatefulWidget {
  final Map<String, dynamic> billing;
  final Map<String, dynamic>? billingData;
  final List<Map<String, dynamic>>? bills;
  final String Function(String) expandAddressAbbreviations;
  final String Function(double) formatNumberWithComma;

  const BillingDetailModal({
    super.key,
    required this.billing,
    this.billingData,
    this.bills,
    required this.expandAddressAbbreviations,
    required this.formatNumberWithComma,
  });

  @override
  State<BillingDetailModal> createState() => _BillingDetailModalState();
}

class _BillingDetailModalState extends State<BillingDetailModal> {
  Map<String, dynamic>? _billingData;
  List<Map<String, dynamic>> _bills = [];
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    // If data is already provided, use it; otherwise fetch
    if (widget.billingData != null && widget.bills != null) {
      _billingData = widget.billingData;
      _bills = widget.bills!;
      _isLoading = false;
    } else {
      _loadBillingData();
    }
  }

  Future<void> _loadBillingData() async {
    final billingId = widget.billing['billingId']?.toString();
    if (billingId == null || billingId.isEmpty) {
      setState(() {
        _billingData = {};
        _bills = [];
        _isLoading = false;
      });
      return;
    }

    try {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });

      // Fetch detailed billing information
      final billingData = await ApiService.getWalletBillingBills(
        billingId: billingId,
      );

      if (!mounted) return;

      // Extract bills from the response
      List<Map<String, dynamic>> bills = [];

      // Check if newBills is directly in billingData (correct structure)
      if (billingData['newBills'] != null && billingData['newBills'] is List) {
        final newBillsList = billingData['newBills'] as List;
        if (newBillsList.isNotEmpty) {
          final firstItem = newBillsList[0] as Map<String, dynamic>;
          // Check if this is a billing object (has billingId) or a bill object (has billId)
          if (firstItem.containsKey('billId')) {
            // It's a list of bills directly - correct structure
            bills = List<Map<String, dynamic>>.from(newBillsList);
          } else if (firstItem.containsKey('billingId') &&
              firstItem['newBills'] != null) {
            // It's incorrectly wrapped - extract bills from the nested billing object
            if (firstItem['newBills'] is List) {
              bills = List<Map<String, dynamic>>.from(firstItem['newBills']);
            }
          }
        }
      } else if (billingData.containsKey('billingId') &&
          billingData['newBills'] != null) {
        // If billingData itself is the billing object (correct structure)
        if (billingData['newBills'] is List) {
          bills = List<Map<String, dynamic>>.from(billingData['newBills']);
        }
      }

      setState(() {
        _billingData = billingData;
        _bills = bills;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _errorMessage = 'Биллингийн мэдээлэл авахад алдаа гарлаа: $e';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final billingData = _billingData ?? {};
    final billing = widget.billing;

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

    return LayoutBuilder(
      builder: (context, constraints) {
        // For tablets/iPads, limit width and center the modal
        final isTablet = constraints.maxWidth > 600;
        final modalWidth = isTablet ? 500.0 : constraints.maxWidth;
        
        return Center(
          child: Container(
            width: modalWidth,
            height: constraints.maxHeight * 0.85,
            decoration: BoxDecoration(
              color: context.isDarkMode ? const Color(0xFF1A1A1A) : Colors.white,
              borderRadius: isTablet
                  ? BorderRadius.circular(20.r)
                  : BorderRadius.only(
                      topLeft: Radius.circular(20.r),
                      topRight: Radius.circular(20.r),
                    ),
              boxShadow: isTablet
                  ? [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.2),
                        blurRadius: 20,
                        spreadRadius: 5,
                      ),
                    ]
                  : null,
            ),
            child: Column(
            children: [
              // Handle bar
              Container(
                margin: EdgeInsets.only(top: 10.h),
                width: 36.w,
                height: 4.h,
                decoration: BoxDecoration(
                  color: context.isDarkMode
                      ? Colors.white.withOpacity(0.2)
                      : Colors.black.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(2.r),
                ),
              ),
              // Header
              Container(
                padding: EdgeInsets.fromLTRB(14.w, 12.h, 10.w, 12.h),
                decoration: BoxDecoration(
                  border: Border(
                    bottom: BorderSide(
                      color: AppColors.deepGreen.withOpacity(0.1),
                      width: 1,
                    ),
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: EdgeInsets.all(10.w),
                      decoration: BoxDecoration(
                        color: AppColors.deepGreen.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(10.r),
                      ),
                      child: Icon(
                        Icons.home_rounded,
                        color: AppColors.deepGreen,
                        size: context.responsiveFontSize(
                          small: 18,
                          medium: 20,
                          large: 22,
                          tablet: 24,
                          veryNarrow: 16,
                        ),
                      ),
                    ),
                    SizedBox(width: 10.w),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            billingName,
                            style: TextStyle(
                              color: context.textPrimaryColor,
                              fontSize: context.responsiveFontSize(
                                small: 14,
                                medium: 15,
                                large: 17,
                                tablet: 18,
                                veryNarrow: 13,
                              ),
                              fontWeight: FontWeight.w600,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          if (customerName.isNotEmpty) ...[
                            SizedBox(height: 2.h),
                            Text(
                              customerName,
                              style: TextStyle(
                                color: context.textSecondaryColor,
                                fontSize: context.responsiveFontSize(
                                  small: 12,
                                  medium: 13,
                                  large: 14,
                                  tablet: 15,
                                  veryNarrow: 11,
                                ),
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ],
                      ),
                    ),
                    IconButton(
                      icon: Icon(
                        Icons.close,
                        color: context.textSecondaryColor,
                        size: context.responsiveFontSize(
                          small: 18,
                          medium: 20,
                          large: 22,
                          tablet: 24,
                          veryNarrow: 16,
                        ),
                      ),
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                  ],
                ),
              ),
              // Content
              Expanded(
                child: _isLoading
                    ? Center(
                        child: CircularProgressIndicator(
                          color: AppColors.deepGreen,
                        ),
                      )
                    : _errorMessage != null
                    ? Center(
                        child: Padding(
                          padding: EdgeInsets.all(14.w),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.error_outline_rounded,
                                color: AppColors.error,
                                size: context.responsiveFontSize(
                                  small: 36,
                                  medium: 40,
                                  large: 44,
                                  tablet: 48,
                                  veryNarrow: 32,
                                ),
                              ),
                              SizedBox(height: 12.h),
                              Text(
                                _errorMessage!,
                                style: TextStyle(
                                  color: context.textPrimaryColor,
                                  fontSize: context.responsiveFontSize(
                                    small: 13,
                                    medium: 14,
                                    large: 15,
                                    tablet: 16,
                                    veryNarrow: 12,
                                  ),
                                ),
                                textAlign: TextAlign.center,
                              ),
                              SizedBox(height: 12.h),
                              ElevatedButton(
                                onPressed: _loadBillingData,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppColors.deepGreen,
                                  foregroundColor: Colors.white,
                                  padding: EdgeInsets.symmetric(
                                    horizontal: 16.w,
                                    vertical: 10.h,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(10.r),
                                  ),
                                ),
                                child: Text(
                                  'Дахин оролдох',
                                  style: TextStyle(
                                    fontSize: context.responsiveFontSize(
                                      small: 13,
                                      medium: 14,
                                      large: 15,
                                      tablet: 16,
                                      veryNarrow: 12,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      )
                    : SingleChildScrollView(
                        padding: EdgeInsets.all(14.w),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Billing Info Section
                            Container(
                              padding: EdgeInsets.all(12.w),
                              decoration: BoxDecoration(
                                color: context.isDarkMode
                                    ? const Color(0xFF252525)
                                    : const Color(0xFFF8F8F8),
                                borderRadius: BorderRadius.circular(12.r),
                                border: Border.all(
                                  color: AppColors.deepGreen.withOpacity(0.15),
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
                                        color: AppColors.deepGreen,
                                        size: context.responsiveFontSize(
                                          small: 14,
                                          medium: 16,
                                          large: 18,
                                          tablet: 20,
                                          veryNarrow: 12,
                                        ),
                                      ),
                                      SizedBox(width: 6.w),
                                      Text(
                                        'Биллингийн мэдээлэл',
                                        style: TextStyle(
                                          color: AppColors.deepGreen,
                                          fontSize: context.responsiveFontSize(
                                            small: 14,
                                            medium: 15,
                                            large: 16,
                                            tablet: 17,
                                            veryNarrow: 13,
                                          ),
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ],
                                  ),
                                  SizedBox(height: 10.h),
                                  if (widget.billing['customerCode']
                                          ?.toString() !=
                                      null)
                                    _buildModernModalInfoRow(
                                      Icons.tag_rounded,
                                      'Харилцагчийн код',
                                      widget.billing['customerCode'].toString(),
                                    ),
                                  if (customerAddress.isNotEmpty) ...[
                                    if (widget.billing['customerCode']
                                            ?.toString() !=
                                        null)
                                      SizedBox(height: 8.h),
                                    _buildModernModalInfoRow(
                                      Icons.location_on_rounded,
                                      'Хаяг',
                                      widget.expandAddressAbbreviations(
                                        customerAddress,
                                      ),
                                    ),
                                  ],
                                  if (widget.billing['walletDoorNo']
                                          ?.toString() !=
                                      null) ...[
                                    SizedBox(height: 8.h),
                                    _buildModernModalInfoRow(
                                      Icons.door_front_door_rounded,
                                      'Орц',
                                      widget.billing['walletDoorNo'].toString(),
                                    ),
                                  ],
                                  if (hasNewBills && newBillsCount > 0) ...[
                                    SizedBox(height: 10.h),
                                    Container(
                                      padding: EdgeInsets.all(10.w),
                                      decoration: BoxDecoration(
                                        color: Colors.blue.withOpacity(0.1),
                                        borderRadius: BorderRadius.circular(10.r),
                                        border: Border.all(
                                          color: Colors.blue.withOpacity(0.2),
                                          width: 1,
                                        ),
                                      ),
                                      child: Row(
                                        children: [
                                          Icon(
                                            Icons.new_releases_rounded,
                                            color: Colors.blue,
                                            size: context.responsiveFontSize(
                                              small: 14,
                                              medium: 16,
                                              large: 18,
                                              tablet: 20,
                                              veryNarrow: 12,
                                            ),
                                          ),
                                          SizedBox(width: 8.w),
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                Text(
                                                  'Шинэ билл: $newBillsCount',
                                                  style: TextStyle(
                                                    color: Colors.blue,
                                                    fontSize: context.responsiveFontSize(
                                                      small: 13,
                                                      medium: 14,
                                                      large: 15,
                                                      tablet: 16,
                                                      veryNarrow: 12,
                                                    ),
                                                    fontWeight: FontWeight.w600,
                                                  ),
                                                ),
                                                if (newBillsAmount > 0) ...[
                                                  SizedBox(height: 2.h),
                                                  Text(
                                                    'Дүн: ${widget.formatNumberWithComma(newBillsAmount)}₮',
                                                    style: TextStyle(
                                                      color: Colors.blue.withOpacity(0.8),
                                                      fontSize: context.responsiveFontSize(
                                                        small: 12,
                                                        medium: 13,
                                                        large: 14,
                                                        tablet: 15,
                                                        veryNarrow: 11,
                                                      ),
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
                                    SizedBox(height: 8.h),
                                    Row(
                                      children: [
                                        Icon(
                                          Icons.visibility_off_rounded,
                                          color: context.textSecondaryColor,
                                          size: context.responsiveFontSize(
                                            small: 12,
                                            medium: 14,
                                            large: 16,
                                            tablet: 18,
                                            veryNarrow: 10,
                                          ),
                                        ),
                                        SizedBox(width: 6.w),
                                        Text(
                                          'Нуугдсан билл: $hiddenBillCount',
                                          style: TextStyle(
                                            color: context.textSecondaryColor,
                                            fontSize: context.responsiveFontSize(
                                              small: 12,
                                              medium: 13,
                                              large: 14,
                                              tablet: 15,
                                              veryNarrow: 11,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                  if (paidCount > 0) ...[
                                    SizedBox(height: 8.h),
                                    Row(
                                      children: [
                                        Icon(
                                          Icons.check_circle_rounded,
                                          color: AppColors.success,
                                          size: context.responsiveFontSize(
                                            small: 12,
                                            medium: 14,
                                            large: 16,
                                            tablet: 18,
                                            veryNarrow: 10,
                                          ),
                                        ),
                                        SizedBox(width: 6.w),
                                        Text(
                                          'Төлсөн: $paidCount билл, ${widget.formatNumberWithComma(paidTotal)}₮',
                                          style: TextStyle(
                                            color: AppColors.success,
                                            fontSize: context.responsiveFontSize(
                                              small: 12,
                                              medium: 13,
                                              large: 14,
                                              tablet: 15,
                                              veryNarrow: 11,
                                            ),
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ],
                              ),
                            ),
                            SizedBox(height: 14.h),
                            // Bills Section Header
                            Row(
                              children: [
                                Container(
                                  padding: EdgeInsets.all(6.w),
                                  decoration: BoxDecoration(
                                    color: AppColors.deepGreen.withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(8.r),
                                  ),
                                  child: Icon(
                                    Icons.receipt_long_rounded,
                                    color: AppColors.deepGreen,
                                    size: context.responsiveFontSize(
                                      small: 14,
                                      medium: 16,
                                      large: 18,
                                      tablet: 20,
                                      veryNarrow: 12,
                                    ),
                                  ),
                                ),
                                SizedBox(width: 8.w),
                                Text(
                                  'Биллүүд (${_bills.length})',
                                  style: TextStyle(
                                    color: context.textPrimaryColor,
                                    fontSize: context.responsiveFontSize(
                                      small: 15,
                                      medium: 16,
                                      large: 17,
                                      tablet: 18,
                                      veryNarrow: 14,
                                    ),
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                            SizedBox(height: 10.h),
                            if (_bills.isEmpty)
                              Container(
                                padding: EdgeInsets.all(20.w),
                                decoration: BoxDecoration(
                                  color: context.isDarkMode
                                      ? const Color(0xFF252525)
                                      : const Color(0xFFF8F8F8),
                                  borderRadius: BorderRadius.circular(12.r),
                                  border: Border.all(
                                    color: AppColors.deepGreen.withOpacity(0.1),
                                    width: 1,
                                  ),
                                ),
                                child: Center(
                                  child: Column(
                                    children: [
                                      Icon(
                                        Icons.receipt_long_outlined,
                                        color: context.textSecondaryColor,
                                        size: context.responsiveFontSize(
                                          small: 36,
                                          medium: 40,
                                          large: 44,
                                          tablet: 48,
                                          veryNarrow: 32,
                                        ),
                                      ),
                                      SizedBox(height: 8.h),
                                      Text(
                                        'Билл байхгүй байна',
                                        style: TextStyle(
                                          color: context.textSecondaryColor,
                                          fontSize: context.responsiveFontSize(
                                            small: 13,
                                            medium: 14,
                                            large: 15,
                                            tablet: 16,
                                            veryNarrow: 12,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              )
                            else
                              ..._bills.map((bill) => _buildBillCard(bill)),
                          ],
                        ),
                      ),
              ),
            ],
          ),
        ),
        );
      },
    );
  }

  Widget _buildModernModalInfoRow(IconData icon, String label, String value) {
    if (value.isEmpty) return const SizedBox.shrink();

    return Builder(
      builder: (context) => Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: EdgeInsets.all(6.w),
            decoration: BoxDecoration(
              color: AppColors.deepGreen.withOpacity(0.1),
              borderRadius: BorderRadius.circular(6.r),
            ),
            child: Icon(
              icon,
              color: AppColors.deepGreen,
              size: context.responsiveFontSize(
                small: 12,
                medium: 14,
                large: 16,
                tablet: 18,
                veryNarrow: 10,
              ),
            ),
          ),
          SizedBox(width: 8.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    color: context.textSecondaryColor,
                    fontSize: context.responsiveFontSize(
                      small: 11,
                      medium: 12,
                      large: 13,
                      tablet: 14,
                      veryNarrow: 10,
                    ),
                  ),
                ),
                SizedBox(height: 2.h),
                Text(
                  value,
                  style: TextStyle(
                    color: context.textPrimaryColor,
                    fontSize: context.responsiveFontSize(
                      small: 13,
                      medium: 14,
                      large: 15,
                      tablet: 16,
                      veryNarrow: 12,
                    ),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
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
      margin: EdgeInsets.only(bottom: 10.h),
      padding: EdgeInsets.all(12.w),
      decoration: BoxDecoration(
        color: context.isDarkMode
            ? const Color(0xFF252525)
            : const Color(0xFFF8F8F8),
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(
          color: AppColors.deepGreen.withOpacity(0.15),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: EdgeInsets.all(8.w),
                decoration: BoxDecoration(
                  color: AppColors.deepGreen.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8.r),
                ),
                child: Icon(
                  Icons.receipt_rounded,
                  color: AppColors.deepGreen,
                  size: context.responsiveFontSize(
                    small: 14,
                    medium: 16,
                    large: 18,
                    tablet: 20,
                    veryNarrow: 12,
                  ),
                ),
              ),
              SizedBox(width: 10.w),
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
                              color: context.textPrimaryColor,
                              fontSize: context.responsiveFontSize(
                                small: 14,
                                medium: 15,
                                large: 16,
                                tablet: 17,
                                veryNarrow: 13,
                              ),
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        if (isNew)
                          Container(
                            padding: EdgeInsets.symmetric(
                              horizontal: 6.w,
                              vertical: 2.h,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.blue.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(6.r),
                            ),
                            child: Text(
                              'Шинэ',
                              style: TextStyle(
                                color: Colors.blue,
                                fontSize: context.responsiveFontSize(
                                  small: 11,
                                  medium: 12,
                                  large: 13,
                                  tablet: 14,
                                  veryNarrow: 10,
                                ),
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                      ],
                    ),
                    if (billerName.isNotEmpty) ...[
                      SizedBox(height: 4.h),
                      Row(
                        children: [
                          Icon(
                            Icons.business_rounded,
                            color: context.textSecondaryColor,
                            size: context.responsiveFontSize(
                              small: 10,
                              medium: 12,
                              large: 14,
                              tablet: 15,
                              veryNarrow: 9,
                            ),
                          ),
                          SizedBox(width: 4.w),
                          Expanded(
                            child: Text(
                              billerName,
                              style: TextStyle(
                                color: context.textSecondaryColor,
                                fontSize: context.responsiveFontSize(
                                  small: 12,
                                  medium: 13,
                                  large: 14,
                                  tablet: 15,
                                  veryNarrow: 11,
                                ),
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ],
                    if (billNo.isNotEmpty || billPeriod.isNotEmpty) ...[
                      SizedBox(height: 4.h),
                      Wrap(
                        spacing: 10.w,
                        children: [
                          if (billNo.isNotEmpty)
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.numbers_rounded,
                                  color: context.textSecondaryColor,
                                  size: context.responsiveFontSize(
                                    small: 10,
                                    medium: 12,
                                    large: 14,
                                    tablet: 15,
                                    veryNarrow: 9,
                                  ),
                                ),
                                SizedBox(width: 3.w),
                                Text(
                                  billNo,
                                  style: TextStyle(
                                    color: context.textSecondaryColor,
                                    fontSize: context.responsiveFontSize(
                                      small: 11,
                                      medium: 12,
                                      large: 13,
                                      tablet: 14,
                                      veryNarrow: 10,
                                    ),
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
                                  color: context.textSecondaryColor,
                                  size: context.responsiveFontSize(
                                    small: 10,
                                    medium: 12,
                                    large: 14,
                                    tablet: 15,
                                    veryNarrow: 9,
                                  ),
                                ),
                                SizedBox(width: 3.w),
                                Text(
                                  billPeriod,
                                  style: TextStyle(
                                    color: context.textSecondaryColor,
                                    fontSize: context.responsiveFontSize(
                                      small: 11,
                                      medium: 12,
                                      large: 13,
                                      tablet: 14,
                                      veryNarrow: 10,
                                    ),
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
          SizedBox(height: 10.h),
          Container(
            padding: EdgeInsets.all(10.w),
            decoration: BoxDecoration(
              color: context.isDarkMode
                  ? Colors.white.withOpacity(0.03)
                  : Colors.white,
              borderRadius: BorderRadius.circular(10.r),
              border: Border.all(
                color: AppColors.deepGreen.withOpacity(0.1),
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
                        color: context.textSecondaryColor,
                        fontSize: context.responsiveFontSize(
                          small: 11,
                          medium: 12,
                          large: 13,
                          tablet: 14,
                          veryNarrow: 10,
                        ),
                      ),
                    ),
                    SizedBox(height: 2.h),
                    Text(
                      '${widget.formatNumberWithComma(billAmount)}₮',
                      style: TextStyle(
                        color: context.textPrimaryColor,
                        fontSize: context.responsiveFontSize(
                          small: 13,
                          medium: 14,
                          large: 15,
                          tablet: 16,
                          veryNarrow: 12,
                        ),
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
                          fontSize: context.responsiveFontSize(
                            small: 11,
                            medium: 12,
                            large: 13,
                            tablet: 14,
                            veryNarrow: 10,
                          ),
                        ),
                      ),
                      SizedBox(height: 2.h),
                      Text(
                        '${widget.formatNumberWithComma(billLateFee)}₮',
                        style: TextStyle(
                          color: Colors.orange,
                          fontSize: context.responsiveFontSize(
                            small: 13,
                            medium: 14,
                            large: 15,
                            tablet: 16,
                            veryNarrow: 12,
                          ),
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
                        color: context.textSecondaryColor,
                        fontSize: context.responsiveFontSize(
                          small: 11,
                          medium: 12,
                          large: 13,
                          tablet: 14,
                          veryNarrow: 10,
                        ),
                      ),
                    ),
                    SizedBox(height: 2.h),
                    Text(
                      '${widget.formatNumberWithComma(billTotalAmount)}₮',
                      style: TextStyle(
                        color: AppColors.deepGreen,
                        fontSize: context.responsiveFontSize(
                          small: 14,
                          medium: 15,
                          large: 17,
                          tablet: 18,
                          veryNarrow: 13,
                        ),
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          if (hasVat) ...[
            SizedBox(height: 8.h),
            Row(
              children: [
                Icon(
                  Icons.verified_rounded,
                  color: AppColors.success,
                  size: context.responsiveFontSize(
                    small: 12,
                    medium: 14,
                    large: 16,
                    tablet: 18,
                    veryNarrow: 10,
                  ),
                ),
                SizedBox(width: 4.w),
                Text(
                  'НӨАТ-тай',
                  style: TextStyle(
                    color: AppColors.success,
                    fontSize: context.responsiveFontSize(
                      small: 11,
                      medium: 12,
                      large: 13,
                      tablet: 14,
                      veryNarrow: 10,
                    ),
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
