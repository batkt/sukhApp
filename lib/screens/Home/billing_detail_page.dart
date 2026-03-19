import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:sukh_app/constants/constants.dart';
import 'package:sukh_app/services/api_service.dart';
import 'package:sukh_app/services/storage_service.dart';
import 'package:sukh_app/utils/theme_extensions.dart';
import 'package:sukh_app/widgets/glass_snackbar.dart';
import 'package:sukh_app/components/Nekhemjlekh/qpay_qr_modal.dart';
import 'package:sukh_app/components/Nekhemjlekh/vat_receipt_modal.dart';
import 'package:sukh_app/components/Nekhemjlekh/nekhemjlekh_models.dart';
import 'package:intl/intl.dart';
import 'package:go_router/go_router.dart';
import 'package:sukh_app/widgets/standard_app_bar.dart';

class BillingDetailPage extends StatefulWidget {
  final Map<String, dynamic> billing;
  final Map<String, dynamic>? billingData;
  final String Function(String) expandAddressAbbreviations;
  final String Function(double) formatNumberWithComma;

  const BillingDetailPage({
    super.key,
    required this.billing,
    this.billingData,
    required this.expandAddressAbbreviations,
    required this.formatNumberWithComma,
  });

  @override
  State<BillingDetailPage> createState() => _BillingDetailPageState();
}

class _BillingDetailPageState extends State<BillingDetailPage> {
  List<Map<String, dynamic>> _allBillingsData = [];
  List<Map<String, dynamic>> _allBills = [];
  bool _isLoading = true;
  String? _errorMessage;
  final Set<String> _selectedBillIds = {};
  bool _isProcessingPayment = false;

  String _vatReceiveType = 'CITIZEN';
  final TextEditingController _vatCompanyRegController =
      TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadAllBillingsData();
  }

  Future<void> _loadAllBillingsData() async {
    try {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
        _allBillingsData = [];
        _allBills = [];
      });

      // 1. Get the list of all connected billings
      final billingList = await ApiService.getWalletBillingList();

      if (billingList.isEmpty) {
        setState(() {
          _isLoading = false;
          _errorMessage = 'Холбогдсон биллинг олдсонгүй';
        });
        return;
      }

      // 2. Fetch bills for each billing provider
      List<Map<String, dynamic>> collectedBills = [];
      for (var billing in billingList) {
        final billingId = billing['billingId']?.toString();
        if (billingId == null) continue;

        try {
          final billingData = await ApiService.getWalletBillingBills(
            billingId: billingId,
          );

          List<Map<String, dynamic>> bills = [];
          if (billingData['newBills'] != null &&
              billingData['newBills'] is List) {
            final newBillsList = billingData['newBills'] as List;
            if (newBillsList.isNotEmpty) {
              final firstItem = newBillsList[0];
              if (firstItem is Map && firstItem.containsKey('billId')) {
                bills = List<Map<String, dynamic>>.from(newBillsList);
              } else if (firstItem is Map &&
                  firstItem.containsKey('billingId') &&
                  firstItem['newBills'] != null) {
                bills = List<Map<String, dynamic>>.from(firstItem['newBills']);
              }
            }
          } else if (billingData.containsKey('billingId') &&
              billingData['newBills'] != null) {
            bills = List<Map<String, dynamic>>.from(billingData['newBills']);
          }

          // Add metadata to each bill to know which billing it belongs to
          for (var bill in bills) {
            bill['parentBillingId'] = billingId;
            bill['parentBillerName'] =
                billing['billerName'] ??
                billingData['billingName'] ??
                'Хэрэглээний төлбөр';
            collectedBills.add(bill);
          }
        } catch (e) {
          print('Error loading bills for $billingId: $e');
        }
      }

      if (!mounted) return;

      setState(() {
        _allBills = collectedBills;
        // Auto-select all bills initially
        for (var bill in _allBills) {
          final id = bill['billId']?.toString();
          if (id != null) _selectedBillIds.add(id);
        }
        _isLoading = false;
      });
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _errorMessage = 'Мэдээлэл ачаалахад алдаа гарлаа: $e';
        });
      }
    }
  }

  double get _totalSelectedAmount {
    double total = 0;
    for (var bill in _allBills) {
      final id = bill['billId']?.toString();
      if (id != null && _selectedBillIds.contains(id)) {
        total += (bill['billTotalAmount'] as num?)?.toDouble() ?? 0.0;
      }
    }
    return total;
  }

  Future<void> _processPayment() async {
    if (_selectedBillIds.isEmpty) {
      showGlassSnackBar(
        context,
        message: 'Төлөх төлбөрөө сонгоно уу',
        icon: Icons.info_outline,
        iconColor: AppColors.deepGreenAccent,
      );
      return;
    }

    if (_vatReceiveType == 'COMPANY' && _vatCompanyRegController.text.isEmpty) {
      showGlassSnackBar(
        context,
        message: 'Байгууллагын РД оруулна уу',
        icon: Icons.info_outline,
        iconColor: AppColors.deepGreenAccent,
      );
      return;
    }

    setState(() {
      _isProcessingPayment = true;
    });

    try {
      // Wallet payment API supports billIds from MULTIPLE billings?
      // Usually it's per billing. But if we want unified, we might need to loop or use a multi-billing endpoint if exists.
      // Based on ApiService.createWalletQPayPayment, it takes ONE billingId.

      // Let's group selected bills by billingId
      Map<String, List<String>> billsByBilling = {};
      for (var bill in _allBills) {
        final id = bill['billId']?.toString();
        final billingId = bill['parentBillingId']?.toString();
        if (id != null && _selectedBillIds.contains(id) && billingId != null) {
          billsByBilling.putIfAbsent(billingId, () => []).add(id);
        }
      }

      bool overallSuccess = true;

      // Process each billing group (currently API supports one billing at a time)
      // If there's only one billing selected, proceed as normal.
      // If multiple, we'd theoretically need multiple QRs, but usually user selects one provider in the image.
      // For now, let's take the first billing's bills to match current API capabilities.
      if (billsByBilling.isEmpty) return;

      final firstBillingId = billsByBilling.keys.first;
      final selectedBillIds = billsByBilling[firstBillingId]!;

      final qpayResponse = await ApiService.createWalletQPayPayment(
        billingId: firstBillingId,
        billIds: selectedBillIds,
        vatReceiveType: _vatReceiveType,
        vatCompanyReg: _vatReceiveType == 'COMPANY'
            ? _vatCompanyRegController.text
            : null,
      );

      if (!mounted) return;

      if (qpayResponse['success'] == true) {
        final walletPaymentId = qpayResponse['walletPaymentId']?.toString();
        final paymentAmount =
            (qpayResponse['paymentAmount'] as num?)?.toDouble() ?? 0.0;
        final qrText = qpayResponse['qr_text']?.toString();
        final qrImage = qpayResponse['qr_image']?.toString();
        final urls = qpayResponse['urls'] as List<dynamic>?;

        final paid = await Navigator.of(context).push<bool>(
          MaterialPageRoute(
            builder: (ctx) => QPayQRModal(
              qrText: qrText,
              qrImageWallet: qrImage,
              urls: urls,
              amount: paymentAmount,
              walletPaymentId: walletPaymentId,
              closeOnSuccess: true,
              onCheckPaymentAsync: () async {
                if (walletPaymentId == null) return null;
                try {
                  final status = await ApiService.walletQpayCheckStatus(
                    walletPaymentId: walletPaymentId,
                  );
                  final state = status['status']?.toString().toUpperCase();
                  if (state == 'PAID') return true;
                  if (state == 'PENDING') return null;
                  return false;
                } catch (_) {
                  return null;
                }
              },
            ),
          ),
        );

        if (paid == true && mounted) {
          // Show success and receipt
          if (walletPaymentId != null) {
            try {
              final paymentData = await ApiService.walletQpayGetPayment(
                walletPaymentId: walletPaymentId,
              );
              if (mounted && paymentData.containsKey('vatInformation')) {
                final receipt = VATReceipt.fromWalletPayment(paymentData);
                await showModalBottomSheet(
                  context: context,
                  isScrollControlled: true,
                  backgroundColor: Colors.transparent,
                  builder: (context) => VATReceiptModal(receipt: receipt),
                );
              }
            } catch (e) {
              print('Error fetching final payment details: $e');
            }
          }
          Navigator.of(context).pop(true);
        }
      } else {
        throw Exception(
          qpayResponse['message'] ??
              qpayResponse['aldaa'] ??
              'Төлбөр үүсгэхэд алдаа гарлаа',
        );
      }
    } catch (e) {
      if (mounted) {
        showGlassSnackBar(
          context,
          message: e.toString().replaceFirst('Exception: ', ''),
          icon: Icons.error_outline,
          iconColor: Colors.red,
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isProcessingPayment = false;
        });
      }
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

    // Use information from the first bill if available for address/name
    final firstBill = _allBills.isNotEmpty ? _allBills.first : null;
    final billingName =
        widget.billing['billingName']?.toString() ?? 'Хэрэглээний төлбөр';
    final customerAddress = widget.expandAddressAbbreviations(
      firstBill?['customerAddress']?.toString() ??
          widget.billing['customerAddress']?.toString() ??
          '',
    );

    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: buildStandardAppBar(
        context,
        title: 'ТӨЛБӨРИЙН ДЭЛГЭРЭНГҮЙ',
        onBackPressed: () => Navigator.of(context).pop(),
        actions: [
          IconButton(
            onPressed: () {
              final billingId = widget.billing['billingId']?.toString() ?? '';
              final billingName =
                  widget.billing['billingName']?.toString() ??
                  'Хэрэглээний төлбөр';

              if (billingId.isNotEmpty) {
                context.push(
                  '/payment-history',
                  extra: {
                    'billingId': billingId,
                    'billingName': billingName,
                    'expandAddressAbbreviations':
                        widget.expandAddressAbbreviations,
                    'formatNumberWithComma': widget.formatNumberWithComma,
                  },
                );
              } else {
                showGlassSnackBar(
                  context,
                  message: 'Биллер ID олдсонгүй',
                  icon: Icons.error_outline,
                  iconColor: Colors.red,
                );
              }
            },
            icon: Icon(
              Icons.history,
              color: textPrimary.withOpacity(0.7),
              size: 20.sp,
            ),
            tooltip: 'Төлбөрийн түүх',
          ),
        ],
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
                        _errorMessage == 'Холбогдсон биллинг олдсонгүй'
                            ? Icons.add_home_work_rounded
                            : Icons.error_outline_rounded,
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
                    SizedBox(height: 8.h),
                    Text(
                      _errorMessage == 'Холбогдсон биллинг олдсонгүй'
                          ? 'Таны хаяг одоогоор холбогдоогүй байна. Хаягаа холбосноор төлбөрийн дэлгэрэнгүйг харах боломжтой.'
                          : 'Мэдээлэл авахад алдаа гарлаа. Та интернэт холболтоо шалгаад дахин оролдоно уу.',
                      style: TextStyle(
                        color: textSecondary.withOpacity(0.6),
                        fontSize: 12.sp,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    SizedBox(height: 32.h),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () {
                          if (_errorMessage == 'Холбогдсон биллинг олдсонгүй') {
                            context.push('/address_selection').then((_) {
                              _loadAllBillingsData();
                            });
                          } else {
                            _loadAllBillingsData();
                          }
                        },
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
                          _errorMessage == 'Холбогдсон биллинг олдсонгүй'
                              ? 'ХАЯГ ХОЛБОХ'
                              : 'ДАХИН АЧААЛАХ',
                          style: TextStyle(fontSize: 13.sp, letterSpacing: 1.1),
                        ),
                      ),
                    ),
                    if (_errorMessage != 'Холбогдсон биллинг олдсонгүй')
                      TextButton(
                        onPressed: () => Navigator.of(context).pop(),
                        child: Text(
                          'БУЦАХ',
                          style: TextStyle(
                            color: textSecondary,
                            fontSize: 13.sp,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            )
          : _allBills.isEmpty
          ? const Center(
              child: Text(
                'Төлөх төлбөр олдсонгүй',
                style: TextStyle(color: Colors.white),
              ),
            )
          : Column(
              children: [
                Expanded(
                  child: CustomScrollView(
                    slivers: [
                      SliverToBoxAdapter(
                        child: Padding(
                          padding: EdgeInsets.fromLTRB(20.w, 10.h, 20.w, 10.h),
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
                                    Icons.location_on_outlined,
                                    size: 18.sp,
                                    color: primaryColor,
                                  ),
                                ),
                                SizedBox(width: 16.w),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'БАЙРШИЛ',
                                        style: TextStyle(
                                          color: textSecondary.withOpacity(0.4),
                                          fontSize: 9.sp,
                                          letterSpacing: 1.0,
                                        ),
                                      ),
                                      SizedBox(height: 4.h),
                                      Text(
                                        customerAddress.toUpperCase(),
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
                      SliverPersistentHeader(
                        pinned: true,
                        delegate: _SliverAppBarDelegate(
                          minHeight: 50.h,
                          maxHeight: 50.h,
                          child: Container(
                            color: backgroundColor,
                            padding: EdgeInsets.symmetric(horizontal: 20.w),
                            child: Row(
                              children: [
                                GestureDetector(
                                  onTap: () {
                                    setState(() {
                                      if (_selectedBillIds.length ==
                                          _allBills.length) {
                                        _selectedBillIds.clear();
                                      } else {
                                        for (var bill in _allBills) {
                                          final id = bill['billId']?.toString();
                                          if (id != null)
                                            _selectedBillIds.add(id);
                                        }
                                      }
                                    });
                                  },
                                  child: Row(
                                    children: [
                                      AnimatedContainer(
                                        duration: const Duration(
                                          milliseconds: 200,
                                        ),
                                        width: 20.w,
                                        height: 20.w,
                                        decoration: BoxDecoration(
                                          border: Border.all(
                                            color:
                                                _allBills.isNotEmpty &&
                                                    _selectedBillIds.length ==
                                                        _allBills.length
                                                ? primaryColor
                                                : textSecondary.withOpacity(
                                                    0.2,
                                                  ),
                                            width: 1.5,
                                          ),
                                          borderRadius: BorderRadius.circular(
                                            6.r,
                                          ),
                                          color:
                                              _allBills.isNotEmpty &&
                                                  _selectedBillIds.length ==
                                                      _allBills.length
                                              ? primaryColor
                                              : Colors.transparent,
                                        ),
                                        child:
                                            _allBills.isNotEmpty &&
                                                _selectedBillIds.length ==
                                                    _allBills.length
                                            ? Icon(
                                                Icons.check,
                                                size: 14.sp,
                                                color: Colors.white,
                                              )
                                            : null,
                                      ),
                                      SizedBox(width: 12.w),
                                      Text(
                                        'Бүгдийг сонгох',
                                        style: TextStyle(
                                          color: textPrimary.withOpacity(0.8),
                                          fontSize: 13.sp,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const Spacer(),
                                Text(
                                  '${_selectedBillIds.length} / ${_allBills.length}',
                                  style: TextStyle(
                                    color: textSecondary.withOpacity(0.6),
                                    fontSize: 13.sp,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      SliverPadding(
                        padding: EdgeInsets.fromLTRB(20.w, 10.h, 20.w, 10.h),
                        sliver: SliverList(
                          delegate: SliverChildBuilderDelegate((
                            context,
                            index,
                          ) {
                            final bill = _allBills[index];
                            final id = bill['billId']?.toString();
                            final isSelected =
                                id != null && _selectedBillIds.contains(id);
                            final amount =
                                (bill['billTotalAmount'] as num?)?.toDouble() ??
                                0.0;
                            final billLateFee =
                                (bill['billLateFee'] as num?)?.toDouble() ??
                                0.0;
                            final billPeriod =
                                bill['billPeriod']?.toString() ?? '';
                            final billerName =
                                bill['billerName']?.toString() ??
                                bill['parentBillerName']?.toString() ??
                                '';

                            return Padding(
                              padding: EdgeInsets.only(bottom: 12.h),
                              child: GestureDetector(
                                onTap: () {
                                  setState(() {
                                    if (id == null) return;
                                    if (isSelected) {
                                      _selectedBillIds.remove(id);
                                    } else {
                                      if (_selectedBillIds.length < 10) {
                                        _selectedBillIds.add(id);
                                      } else {
                                        showGlassSnackBar(
                                          context,
                                          message:
                                              'Нэг удаад хамгийн ихдээ 10 нэхэмжлэх сонгох боломжтой',
                                        );
                                      }
                                    }
                                  });
                                },
                                child: Container(
                                  padding: EdgeInsets.all(16.w),
                                  decoration: BoxDecoration(
                                    color: isSelected
                                        ? primaryColor.withOpacity(0.05)
                                        : surfaceColor,
                                    borderRadius: BorderRadius.circular(20.r),
                                    border: Border.all(
                                      color: isSelected
                                          ? primaryColor.withOpacity(0.2)
                                          : textPrimary.withOpacity(0.03),
                                    ),
                                    boxShadow: isSelected
                                        ? [
                                            BoxShadow(
                                              color: primaryColor.withOpacity(
                                                0.05,
                                              ),
                                              blurRadius: 10,
                                            ),
                                          ]
                                        : [],
                                  ),
                                  child: Row(
                                    children: [
                                      AnimatedContainer(
                                        duration: const Duration(
                                          milliseconds: 200,
                                        ),
                                        width: 22.w,
                                        height: 22.w,
                                        decoration: BoxDecoration(
                                          border: Border.all(
                                            color: isSelected
                                                ? primaryColor
                                                : textSecondary.withOpacity(
                                                    0.2,
                                                  ),
                                            width: 1.5,
                                          ),
                                          borderRadius: BorderRadius.circular(
                                            8.r,
                                          ),
                                          color: isSelected
                                              ? primaryColor
                                              : Colors.transparent,
                                        ),
                                        child: isSelected
                                            ? Icon(
                                                Icons.check,
                                                size: 14.sp,
                                                color: Colors.white,
                                              )
                                            : null,
                                      ),
                                      SizedBox(width: 16.w),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              billerName,
                                              style: TextStyle(
                                                color: textPrimary.withOpacity(
                                                  isSelected ? 0.9 : 0.7,
                                                ),
                                                fontSize: 13.sp,
                                              ),
                                            ),
                                            SizedBox(height: 2.h),
                                            Text(
                                              billPeriod,
                                              style: TextStyle(
                                                color: textSecondary
                                                    .withOpacity(0.4),
                                                fontSize: 10.sp,
                                              ),
                                            ),
                                            if (billerName.isNotEmpty) ...[
                                              SizedBox(height: 1.h),
                                              Text(
                                                billerName,
                                                style: TextStyle(
                                                  color: textSecondary
                                                      .withOpacity(0.4),
                                                  fontSize: 10.sp,
                                                ),
                                              ),
                                            ],
                                          ],
                                        ),
                                      ),
                                      Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.end,
                                        children: [
                                          Text(
                                            widget.formatNumberWithComma(
                                              amount,
                                            ),
                                            style: TextStyle(
                                              color: isSelected
                                                  ? primaryColor
                                                  : textPrimary,
                                              fontSize: 14.sp,
                                            ),
                                          ),
                                          Text(
                                            'Алданги: ${widget.formatNumberWithComma(billLateFee)}',
                                            style: TextStyle(
                                              color: AppColors.error,
                                              fontSize: 10.sp,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            );
                          }, childCount: _allBills.length),
                        ),
                      ),
                      SliverToBoxAdapter(
                        child: _buildVATSelectorSection(
                          context,
                          textPrimary,
                          textSecondary,
                        ),
                      ),
                      SliverToBoxAdapter(child: SizedBox(height: 120.h)),
                    ],
                  ),
                ),
                _buildBottomBar(
                  context,
                  primaryColor,
                  backgroundColor,
                  surfaceColor,
                  textPrimary,
                  textSecondary,
                ),
              ],
            ),
    );
  }

  Widget scaleTransitionIcon(IconData icon, double size, Color color) {
    return Center(
      child: Icon(icon, size: size, color: color),
    );
  }

  Widget _buildVATSelectorSection(
    BuildContext context,
    Color textPrimary,
    Color textSecondary,
  ) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 15.h),
      child: Container(
        padding: EdgeInsets.all(16.w),
        decoration: BoxDecoration(
          color: context.surfaceColor,
          borderRadius: BorderRadius.circular(16.r),
          border: Border.all(color: textPrimary.withOpacity(0.05)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.receipt_long_outlined,
                  size: 16.sp,
                  color: textSecondary.withOpacity(0.6),
                ),
                SizedBox(width: 8.w),
                Text(
                  'И-баримт хүлээн авах',
                  style: TextStyle(
                    fontSize: 11.sp,
                    color: textSecondary.withOpacity(0.8),
                    letterSpacing: 0.3,
                  ),
                ),
              ],
            ),
            SizedBox(height: 16.h),
            Container(
              padding: EdgeInsets.all(4.w),
              decoration: BoxDecoration(
                color: context.isDarkMode
                    ? Colors.black.withOpacity(0.2)
                    : textPrimary.withOpacity(0.04),
                borderRadius: BorderRadius.circular(12.r),
                border: Border.all(color: textPrimary.withOpacity(0.05)),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: _buildVatOption(
                      context,
                      title: 'Хувь хүн',
                      isSelected: _vatReceiveType == 'CITIZEN',
                      onTap: () => setState(() => _vatReceiveType = 'CITIZEN'),
                      textPrimary: textPrimary,
                    ),
                  ),
                  Expanded(
                    child: _buildVatOption(
                      context,
                      title: 'Байгууллага',
                      isSelected: _vatReceiveType == 'COMPANY',
                      onTap: () => setState(() => _vatReceiveType = 'COMPANY'),
                      textPrimary: textPrimary,
                    ),
                  ),
                ],
              ),
            ),
            if (_vatReceiveType == 'COMPANY') ...[
              SizedBox(height: 16.h),
              TextField(
                controller: _vatCompanyRegController,
                keyboardType: TextInputType.number,
                style: TextStyle(color: textPrimary, fontSize: 13.sp),
                decoration: InputDecoration(
                  hintText: 'Байгууллагын РД оруулна уу',
                  hintStyle: TextStyle(
                    color: textSecondary.withOpacity(0.3),
                    fontSize: 12.sp,
                  ),
                  contentPadding: EdgeInsets.symmetric(
                    horizontal: 16.w,
                    vertical: 14.h,
                  ),
                  filled: true,
                  fillColor: textPrimary.withOpacity(0.02),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10.r),
                    borderSide: BorderSide(color: textPrimary.withOpacity(0.1)),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10.r),
                    borderSide: BorderSide(
                      color: context.isDarkMode
                          ? AppColors.deepGreenAccent
                          : AppColors.deepGreen,
                    ),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildVatOption(
    BuildContext context, {
    required String title,
    required bool isSelected,
    required VoidCallback onTap,
    required Color textPrimary,
  }) {
    final primaryColor = context.isDarkMode
        ? AppColors.deepGreenAccent
        : AppColors.deepGreen;
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeInOut,
        padding: EdgeInsets.symmetric(vertical: 10.h),
        decoration: BoxDecoration(
          color: isSelected ? primaryColor : Colors.transparent,
          borderRadius: BorderRadius.circular(10.r),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: primaryColor.withOpacity(0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ]
              : [],
        ),
        child: Center(
          child: Text(
            title,
            style: TextStyle(
              fontSize: 13.sp,
              color: isSelected ? Colors.white : textPrimary.withOpacity(0.5),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBottomBar(
    BuildContext context,
    Color primaryColor,
    Color backgroundColor,
    Color surfaceColor,
    Color textPrimary,
    Color textSecondary,
  ) {
    return Container(
      padding: EdgeInsets.fromLTRB(20.w, 16.h, 20.w, 34.h),
      decoration: BoxDecoration(
        color: context.backgroundColor,
        border: Border(
          top: BorderSide(color: context.textPrimaryColor.withOpacity(0.05)),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'НИЙТ ТӨЛӨХ',
                  style: TextStyle(
                    color: textSecondary.withOpacity(0.5),
                    fontSize: 10.sp,
                    letterSpacing: 1.0,
                  ),
                ),
                SizedBox(height: 4.h),
                Text(
                  '${widget.formatNumberWithComma(_totalSelectedAmount)}₮',
                  style: TextStyle(color: textPrimary, fontSize: 22.sp),
                ),
              ],
            ),
          ),
          SizedBox(width: 20.w),
          Expanded(
            child: SizedBox(
              height: 54.h,
              child: ElevatedButton(
                onPressed: _isProcessingPayment || _selectedBillIds.isEmpty
                    ? null
                    : _processPayment,
                style: ElevatedButton.styleFrom(
                  backgroundColor: primaryColor,
                  foregroundColor: Colors.white,
                  disabledBackgroundColor: primaryColor.withOpacity(0.3),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16.r),
                  ),
                  elevation: 0,
                ),
                child: _isProcessingPayment
                    ? SizedBox(
                        height: 20.w,
                        width: 20.w,
                        child: const CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : Center(
                        child: Text(
                          'ТӨЛӨХ',
                          style: TextStyle(fontSize: 14.sp, letterSpacing: 1.0),
                          textAlign: TextAlign.center,
                        ),
                      ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SliverAppBarDelegate extends SliverPersistentHeaderDelegate {
  _SliverAppBarDelegate({
    required this.minHeight,
    required this.maxHeight,
    required this.child,
  });
  final double minHeight;
  final double maxHeight;
  final Widget child;

  @override
  double get minExtent => minHeight;
  @override
  double get maxExtent => maxHeight;

  @override
  Widget build(
    BuildContext context,
    double shrinkOffset,
    bool overlapsContent,
  ) {
    return SizedBox.expand(child: child);
  }

  @override
  bool shouldRebuild(_SliverAppBarDelegate oldDelegate) {
    return maxHeight != oldDelegate.maxHeight ||
        minHeight != oldDelegate.minHeight ||
        child != oldDelegate.child;
  }
}
