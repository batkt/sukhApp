import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:sukh_app/constants/constants.dart';
import 'package:sukh_app/services/api_service.dart';
import 'package:sukh_app/services/storage_service.dart';
import 'package:sukh_app/utils/theme_extensions.dart';
import 'package:sukh_app/utils/responsive_helper.dart';
import 'package:sukh_app/components/Nekhemjlekh/qpay_qr_modal.dart';
import 'package:sukh_app/components/Nekhemjlekh/vat_receipt_modal.dart';
import 'package:sukh_app/components/Nekhemjlekh/nekhemjlekh_models.dart';
import 'package:sukh_app/widgets/glass_snackbar.dart';
import 'package:sukh_app/services/socket_service.dart';

/// Lightweight rebuild of the old total balance modal.
/// Shows total unpaid balance (OWN_ORG + WALLET wallet) and lists billings,
/// with a single button to jump into the normal payment flow.
class TotalBalanceModal extends StatefulWidget {
  final String Function(double) formatNumberWithComma;
  final VoidCallback onPaymentTap;

  const TotalBalanceModal({
    super.key,
    required this.formatNumberWithComma,
    required this.onPaymentTap,
  });

  @override
  State<TotalBalanceModal> createState() => _TotalBalanceModalState();
}

class _TotalBalanceModalState extends State<TotalBalanceModal> {
  bool _isLoading = true;
  double _totalAmount = 0.0;
  List<Map<String, dynamic>> _walletBillings = [];
  final Set<String> _selectedBillingIds = {}; // For OWN_ORG contracts
  final Set<String> _selectedBillIds = {}; // For individual wallet bills
  String _vatReceiveType = 'CITIZEN';
  final TextEditingController _vatCompanyRegController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
    });

    final List<Map<String, dynamic>> walletBillings = [];
    double total = 0.0;

    try {
      // If this is the wallet-only organization, skip OWN_ORG contracts and
      // only show WALLET_API billings here.
      final currentBaiguullagiinId = await StorageService.getBaiguullagiinId();
      final currentBaiguullagiinNer = await StorageService.getBaiguullagiinNer();
      final isWalletOnlyOrg =
          currentBaiguullagiinId == '698e7fd3b6dd386b6c56a808';

      final List<Map<String, dynamic>> ownOrgContracts = [];
      if (!isWalletOnlyOrg) {
        // OWN_ORG contracts total
        try {
          final userId = await StorageService.getUserId();
          if (userId != null) {
            final gereeResponse = await ApiService.fetchGeree(userId);
            if (gereeResponse['jagsaalt'] is List) {
              for (final c in gereeResponse['jagsaalt']) {
                final contract = Map<String, dynamic>.from(c as Map);
                final contractUldegdel =
                    contract['uldegdel'] ?? contract['globalUldegdel'];
                if (contractUldegdel != null) {
                  final amt = (contractUldegdel is num)
                      ? contractUldegdel.toDouble()
                      : double.tryParse(contractUldegdel.toString()) ?? 0.0;
                  if (amt > 0) {
                    ownOrgContracts.add({
                      'isOwnOrg': true,
                      'billingName': (currentBaiguullagiinNer != null && currentBaiguullagiinNer.isNotEmpty)
                          ? currentBaiguullagiinNer
                          : (contract['sohNer'] ?? contract['bairNer'] ?? 'СӨХ-ийн төлбөр'),
                      'customerName': contract['gereeniiDugaar'] ?? '',
                      'calculatedTotal': amt,
                      'contract': contract,
                      'billingId': 'OWN_ORG_${contract['_id']}',
                    });
                  }
                }
              }
            }
          }
        } catch (_) {}
      }

      // Add OWN_ORG contracts to the list first
      walletBillings.addAll(ownOrgContracts);
      final double ownOrgSum = ownOrgContracts.fold(0.0, (sum, item) => sum + (item['calculatedTotal'] as double));

      // WALLET_API billings total (sum of billTotalAmount for each billing),
      // using the same structure handling as _loadAllBillingPayment      // WALLET_API billings total
      try {
        final billingList = await ApiService.getWalletBillingList();
        for (final b in billingList) {
          final billing = Map<String, dynamic>.from(b);
          final billingId = billing['billingId']?.toString();
          if (billingId == null || billingId.isEmpty) continue;

          double billingTotal = 0.0;
          List<Map<String, dynamic>> currentBills = [];
          
          try {
            final billingData = await ApiService.getWalletBillingBills(
              billingId: billingId,
            );

            if (billingData['newBills'] != null && billingData['newBills'] is List) {
              final List newBillsList = billingData['newBills'];
              if (newBillsList.isNotEmpty) {
                final firstItem = newBillsList[0];
                if (firstItem is Map && firstItem.containsKey('billId')) {
                  currentBills = List<Map<String, dynamic>>.from(newBillsList);
                } else if (firstItem is Map && firstItem.containsKey('billingId') && firstItem['newBills'] != null) {
                  currentBills = List<Map<String, dynamic>>.from(firstItem['newBills']);
                }
              }
            } else if (billingData.containsKey('billingId') && billingData['newBills'] != null) {
              currentBills = List<Map<String, dynamic>>.from(billingData['newBills']);
            }

            for (final bill in currentBills) {
              final amt = (bill['billTotalAmount'] as num?)?.toDouble() ?? 0.0;
              billingTotal += amt;
            }
          } catch (_) {}

          final billerName = billing['billerName']?.toString() ?? '';
          final name = billerName.isNotEmpty ? billerName : (billing['billingName']?.toString() ?? '');
          
          bool isDuplicate = false;
          if (ownOrgSum > 0 && (name.contains('Орон сууцны') || name.contains('Property') || name.contains('Үйлчилгээний төлбөр'))) {
            isDuplicate = true;
          }

          if (!isDuplicate) {
            walletBillings.add({
              ...billing,
              'calculatedTotal': billingTotal,
              'bills': currentBills,
            });
          }
        }
      } catch (_) {}

      if (!mounted) return;
      setState(() {
        // By default, select all billings that have a positive total
        _selectedBillingIds.clear();
        _selectedBillIds.clear();
        int totalSelectedBills = 0;

        for (final billing in walletBillings) {
          final id = billing['billingId']?.toString();
          if (id == null || id.isEmpty) continue;

          if (billing['isOwnOrg'] == true) {
            final billingTotal = (billing['calculatedTotal'] as num?)?.toDouble() ?? 0.0;
            if (billingTotal > 0) {
              _selectedBillingIds.add(id);
            }
          } else {
            // Select up to 5 individual bills total
            final bills = billing['bills'] as List<Map<String, dynamic>>? ?? [];
            for (final bill in bills) {
              if (totalSelectedBills < 5) {
                final billId = bill['billId']?.toString();
                if (billId != null) {
                  _selectedBillIds.add(billId);
                  totalSelectedBills++;
                }
              }
            }
          }
        }

        _totalAmount = _calculateSelectedTotal(walletBillings);
        _walletBillings = walletBillings;
        _isLoading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: LayoutBuilder(
        builder: (context, constraints) {
        final isTablet = constraints.maxWidth > 600;
        final modalWidth = isTablet ? 500.0 : constraints.maxWidth;

        return Align(
          alignment: Alignment.bottomCenter,
          child: Container(
            width: modalWidth,
            height: constraints.maxHeight * 0.85,
            decoration: BoxDecoration(
              color: context.isDarkMode
                  ? const Color(0xFF1A1A1A)
                  : Colors.white,
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
                          Icons.account_balance_wallet_rounded,
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
                              'Нийт үлдэгдэл',
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
                            SizedBox(height: 2.h),
                            Text(
                              '${widget.formatNumberWithComma(_totalAmount)}₮',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: context.responsiveFontSize(
                                  small: 12,
                                  medium: 13,
                                  large: 14,
                                  tablet: 15,
                                  veryNarrow: 11,
                                ),
                                fontWeight: FontWeight.w600,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
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
                      : SingleChildScrollView(
                          padding: EdgeInsets.fromLTRB(14.w, 14.w, 14.w, 8.h),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              if (_walletBillings.isEmpty && _totalAmount <= 0)
                                Center(
                                  child: Padding(
                                    padding: EdgeInsets.all(12.w),
                                    child: Text(
                                      'Төлбөр байхгүй байна',
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
                                  ),
                                )
                              else ...[
                                if (_walletBillings.isNotEmpty) ...[
                                  SizedBox(height: 8.h),
                                  ..._walletBillings.map((billing) {
                                    final id = billing['billingId']?.toString();
                                    final isSelected = id != null &&
                                        (billing['isOwnOrg'] == true
                                            ? _selectedBillingIds.contains(id)
                                            : (billing['bills'] as List?)?.any((b) => _selectedBillIds.contains(b['billId']?.toString())) ?? false);
                                    
                                    return _buildWalletBillingItem(
                                      context,
                                      billing,
                                      isSelected,
                                      (value) {
                                        setState(() {
                                          if (id == null) return;
                                          if (billing['isOwnOrg'] == true) {
                                            if (value) {
                                              _selectedBillingIds.add(id);
                                            } else {
                                              _selectedBillingIds.remove(id);
                                            }
                                          } else {
                                            // For Wallet: Select/Deselect all bills in this billing (respecting 5-bill limit)
                                            final bills = billing['bills'] as List<Map<String, dynamic>>? ?? [];
                                            if (value) {
                                              for (final bill in bills) {
                                                if (_selectedBillIds.length < 5) {
                                                  final billId = bill['billId']?.toString();
                                                  if (billId != null) _selectedBillIds.add(billId);
                                                }
                                              }
                                            } else {
                                              for (final bill in bills) {
                                                final billId = bill['billId']?.toString();
                                                if (billId != null) _selectedBillIds.remove(billId);
                                              }
                                            }
                                          }
                                          _totalAmount = _calculateSelectedTotal(_walletBillings);
                                        });
                                      },
                                    );
                                  }),
                                  SizedBox(height: 12.h),
                                ],
                                _buildVATSelector(context),
                                SizedBox(height: 8.h),
                                SizedBox(
                                  width: double.infinity,
                                  child: ElevatedButton(
                                    onPressed: () async {
                                      if (_selectedBillingIds.isEmpty && _selectedBillIds.isEmpty) {
                                        if (mounted) {
                                          showGlassSnackBar(
                                            context,
                                            message: 'Төлөх төлбөрөө сонгоно уу',
                                            icon: Icons.info_outline,
                                            iconColor: AppColors.deepGreenAccent,
                                            textColor: context.textPrimaryColor,
                                          );
                                        }
                                        return;
                                      }

                                      if (_vatReceiveType == 'COMPANY' &&
                                          _vatCompanyRegController.text.isEmpty) {
                                        if (mounted) {
                                          showGlassSnackBar(
                                            context,
                                            message: 'Байгууллагын РД оруулна уу',
                                            icon: Icons.info_outline,
                                            iconColor: AppColors.deepGreenAccent,
                                          );
                                        }
                                        return;
                                      }

                                      // Split selected billings into OWN_ORG and WALLET groups
                                      final selectedOwnOrg = _walletBillings
                                          .where((b) =>
                                              b['isOwnOrg'] == true &&
                                              _selectedBillingIds.contains(
                                                  b['billingId']?.toString()))
                                          .toList();

                                      final selectedWallet = _walletBillings
                                          .where((b) =>
                                              b['isOwnOrg'] != true &&
                                              (b['bills'] as List?)?.any((bill) => _selectedBillIds.contains(bill['billId']?.toString())) == true)
                                          .toList();

                                      // Process OWN_ORG billings first
                                      bool anyPaid = false;
                                      if (selectedOwnOrg.isNotEmpty) {
                                        final paid = await _processOwnOrgPayment(selectedOwnOrg);
                                        if (paid == true) anyPaid = true;
                                      }

                                      // Then process WALLET billings
                                      if (selectedWallet.isNotEmpty && mounted) {
                                        final paid = await _processWalletPayment(selectedWallet);
                                        if (paid == true) anyPaid = true;
                                      }

                                      if (anyPaid && mounted) {
                                        Navigator.of(context).pop();
                                      }
                                    },
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: AppColors.deepGreen,
                                      foregroundColor: Colors.white,
                                      padding: EdgeInsets.symmetric(
                                        vertical: 14.h,
                                      ),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(
                                          12.r,
                                        ),
                                      ),
                                    ),
                                    child: Text(
                                      'Төлбөр төлөх',
                                      style: TextStyle(
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
                                ),
                              ],
                            ],
                          ),
                        ),
                ),
                SizedBox(height: 6.h),
              ],
            ),
          ),
        );
      },
      ),
    );
  }

  double _calculateSelectedTotal(List<Map<String, dynamic>> billings) {
    double sum = 0.0;
    for (final billing in billings) {
      if (billing['isOwnOrg'] == true) {
        final id = billing['billingId']?.toString();
        if (id != null && _selectedBillingIds.contains(id)) {
          sum += (billing['calculatedTotal'] as num?)?.toDouble() ?? 0.0;
        }
      } else {
        final bills = billing['bills'] as List<Map<String, dynamic>>? ?? [];
        for (final bill in bills) {
          final billId = bill['billId']?.toString();
          if (billId != null && _selectedBillIds.contains(billId)) {
            sum += (bill['billTotalAmount'] as num?)?.toDouble() ?? 0.0;
          }
        }
      }
    }
    return sum;
  }

  /// Process OWN_ORG QPay payment (uses qpayGargaya API)
  Future<bool> _processOwnOrgPayment(
      List<Map<String, dynamic>> selectedOwnOrg) async {
    try {
      final selectedBilling = selectedOwnOrg.first;
      final contract =
          selectedBilling['contract'] as Map<String, dynamic>?;

      if (contract == null) {
        throw Exception('Гэрээний мэдээлэл олдсонгүй');
      }

      final ownOrgBaiguullagiinId =
          await StorageService.getBaiguullagiinId();
      final ownOrgBarilgiinId =
          await StorageService.getBarilgiinId();

      if (ownOrgBaiguullagiinId == null || ownOrgBarilgiinId == null) {
        throw Exception('Байгууллагын мэдээлэл олдсонгүй');
      }

      // Calculate total from all selected OWN_ORG
      double totalAmount = 0;
      for (final b in selectedOwnOrg) {
        totalAmount +=
            (b['calculatedTotal'] as num?)?.toDouble() ?? 0;
      }

      final turul =
          contract['gereeniiDugaar']?.toString() ?? '';
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final orderNumber = 'TB-$timestamp';

      // Create OWN_ORG QPay invoice
      final ownOrgResponse = await ApiService.qpayGargaya(
        baiguullagiinId: ownOrgBaiguullagiinId,
        barilgiinId: ownOrgBarilgiinId,
        dun: totalAmount,
        turul: turul,
        zakhialgiinDugaar: '$orderNumber-OWN_ORG',
        customerTin: _vatReceiveType == 'COMPANY'
            ? _vatCompanyRegController.text
            : null,
      );

      final qrImage = ownOrgResponse['qr_image']?.toString();
      final invoiceId = ownOrgResponse['invoice_id']?.toString();
      final urls = ownOrgResponse['urls'] as List<dynamic>?;

      if (!mounted) return false;

      if ((qrImage == null || qrImage.isEmpty) &&
          (urls == null || urls.isEmpty)) {
        if (mounted) {
          showGlassSnackBar(
            context,
            message: 'QPay мэдээлэл олдсонгүй',
            icon: Icons.error_outline,
            iconColor: Colors.red,
          );
        }
        return false;
      }

      // Show QR modal for OWN_ORG QPay
      final paid = await showDialog<bool>(
        context: context,
        builder: (ctx) => QPayQRModal(
          qrImageOwnOrg: qrImage,
          urls: urls,
          amount: totalAmount,
          invoiceNumber: invoiceId,
          closeOnSuccess: true,
          onCheckPaymentAsync: () async {
            if (invoiceId == null || invoiceId.isEmpty) return null;
            try {
              final status = await ApiService.checkPaymentStatus(
                invoiceId: invoiceId,
              );
              final rows = status['rows'] as List?;
              if (rows != null && rows.isNotEmpty) {
                final invoiceStatus = rows[0]['invoice_status']
                    ?.toString()
                    .toUpperCase();
                if (invoiceStatus == 'PAID') return true;
                if (invoiceStatus == 'OPEN') return false;
              }
              return null;
            } catch (_) {
              return null;
            }
          },
        ),
      );

      if (paid == true && mounted) {
        showGlassSnackBar(
          context,
          message: 'Орон сууцны төлбөр амжилттай төлөгдлөө',
          icon: Icons.check_circle,
          iconColor: Colors.green,
        );
        return true;
      }
      return false;
    } catch (e) {
      if (mounted) {
        showGlassSnackBar(
          context,
          message: e.toString().replaceFirst('Exception: ', ''),
          icon: Icons.error_outline,
          iconColor: Colors.red,
        );
      }
      return false;
    }
  }

  /// Process WALLET QPay payment (uses createWalletQPayPayment API)
  Future<bool> _processWalletPayment(
      List<Map<String, dynamic>> selectedWallet) async {
    try {
      // For now, support paying one wallet billing at a time
      final walletBilling = selectedWallet.first;
      final selectedBillingId =
          walletBilling['billingId']?.toString() ?? '';

      if (selectedBillingId.isEmpty) {
        throw Exception('Биллингийн мэдээлэл олдсонгүй');
      }

      // Fetch bills for this billingId to get billIds
      final billingData = await ApiService.getWalletBillingBills(
        billingId: selectedBillingId,
      );

      // Extract bills (handles nested structures)
      List<Map<String, dynamic>> bills = [];
      if (billingData['newBills'] != null &&
          billingData['newBills'] is List) {
        final newBillsList = billingData['newBills'] as List;
        if (newBillsList.isNotEmpty) {
          final firstItem =
              newBillsList[0] as Map<String, dynamic>;
          if (firstItem.containsKey('billId')) {
            bills = List.from(
                newBillsList.cast<Map<String, dynamic>>());
          } else if (firstItem.containsKey('billingId') &&
              firstItem['newBills'] != null) {
            if (firstItem['newBills'] is List) {
              bills = List.from(
                  (firstItem['newBills'] as List)
                      .cast<Map<String, dynamic>>());
            }
          }
        }
      } else if (billingData.containsKey('billingId') &&
          billingData['newBills'] != null) {
        if (billingData['newBills'] is List) {
          bills = List.from((billingData['newBills'] as List)
              .cast<Map<String, dynamic>>());
        }
      }

      // Use exclusively selected bill IDs from this billing
      final billIds = bills
          .map((b) => b['billId']?.toString())
          .whereType<String>()
          .where((bid) => _selectedBillIds.contains(bid))
          .toList();

      if (billIds.isEmpty) {
        if (mounted) {
          showGlassSnackBar(
            context,
            message: 'Төлөх боломжтой төлбөр олдсонгүй',
            icon: Icons.info_outline,
            iconColor: AppColors.deepGreenAccent,
          );
        }
        return false;
      }

      // Create Wallet QPay payment
      final qpayResponse = await ApiService.createWalletQPayPayment(
        billingId: selectedBillingId,
        billIds: billIds,
        vatReceiveType: _vatReceiveType,
        vatCompanyReg: _vatReceiveType == 'COMPANY'
            ? _vatCompanyRegController.text
            : null,
      );

      final success = qpayResponse['success'] == true;
      if (!success) {
        throw Exception(qpayResponse['message']?.toString() ??
            'Төлбөрийн мэдээлэл олдсонгүй');
      }

      final walletPaymentId =
          qpayResponse['walletPaymentId']?.toString();
      final paymentAmount =
          (qpayResponse['paymentAmount'] as num?)?.toDouble() ?? 0.0;
      final qrText = qpayResponse['qr_text']?.toString();
      final qrImage = qpayResponse['qr_image']?.toString();
      final urls = qpayResponse['urls'] as List<dynamic>?;

      if (!mounted) return false;

      if ((qrText == null || qrText.isEmpty) &&
          (qrImage == null || qrImage.isEmpty)) {
        if (mounted) {
          showGlassSnackBar(
            context,
            message: 'QPay QR мэдээлэл олдсонгүй',
            icon: Icons.error_outline,
            iconColor: Colors.red,
          );
        }
        return false;
      }

      // Show QR modal for Wallet QPay
      final paid = await showDialog<bool>(
        context: context,
        builder: (ctx) => QPayQRModal(
          qrText: qrText,
          qrImageWallet: qrImage,
          urls: urls,
          amount: paymentAmount,
          walletPaymentId: walletPaymentId,
          closeOnSuccess: true,
          onCheckPaymentAsync: () async {
            if (walletPaymentId == null || walletPaymentId.isEmpty) {
              return null;
            }
            try {
              final status =
                  await ApiService.walletQpayCheckStatus(
                walletPaymentId: walletPaymentId,
              );
              final state =
                  status['status']?.toString().toUpperCase();
              if (state == 'PAID') return true;
              if (state == 'PENDING') return null;
              return false;
            } catch (_) {
              return null;
            }
          },
        ),
      );

      // If paid successfully, show receipt
      if (paid == true && mounted && walletPaymentId != null) {
        try {
          final paymentData =
              await ApiService.walletQpayGetPayment(
            walletPaymentId: walletPaymentId,
          );
          if (mounted &&
              paymentData.containsKey('vatInformation')) {
            final receipt =
                VATReceipt.fromWalletPayment(paymentData);
            await showModalBottomSheet(
              context: context,
              isScrollControlled: true,
              backgroundColor: Colors.transparent,
              builder: (context) =>
                  VATReceiptModal(receipt: receipt),
            );
          }
        } catch (e) {
          print('Error fetching final payment details: $e');
        }
        return true;
      }
      return false;
    } catch (e) {
      if (mounted) {
        showGlassSnackBar(
          context,
          message:
              e.toString().replaceFirst('Exception: ', ''),
          icon: Icons.error_outline,
          iconColor: Colors.red,
        );
      }
      return false;
    }
  }

  Widget _buildVATSelector(BuildContext context) {
    final isDark = context.isDarkMode;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: EdgeInsets.symmetric(vertical: 8.h),
          child: Text(
            'И-баримт хүлээн авах',
            style: TextStyle(
              fontSize: 12.sp,
              fontWeight: FontWeight.w600,
              color: context.textPrimaryColor.withOpacity(0.8),
            ),
          ),
        ),
        Row(
          children: [
            Expanded(
              child: _buildVatOption(
                context,
                title: 'Хувь хүн',
                isSelected: _vatReceiveType == 'CITIZEN',
                onTap: () {
                  setState(() {
                    _vatReceiveType = 'CITIZEN';
                  });
                },
              ),
            ),
            SizedBox(width: 10.w),
            Expanded(
              child: _buildVatOption(
                context,
                title: 'Байгууллага',
                isSelected: _vatReceiveType == 'COMPANY',
                onTap: () {
                  setState(() {
                    _vatReceiveType = 'COMPANY';
                  });
                },
              ),
            ),
          ],
        ),
        if (_vatReceiveType == 'COMPANY') ...[
          SizedBox(height: 12.h),
          TextField(
            controller: _vatCompanyRegController,
            keyboardType: TextInputType.number,
            style: TextStyle(
              fontSize: 13.sp,
              color: context.textPrimaryColor,
            ),
            decoration: InputDecoration(
              hintText: 'Байгууллагын РД оруулна уу',
              hintStyle: TextStyle(
                fontSize: 12.sp,
                color: context.textSecondaryColor.withOpacity(0.5),
              ),
              contentPadding: EdgeInsets.symmetric(
                horizontal: 12.w,
                vertical: 10.h,
              ),
              filled: true,
              fillColor: isDark
                  ? Colors.white.withOpacity(0.05)
                  : Colors.black.withOpacity(0.03),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10.r),
                borderSide: BorderSide(
                  color: context.borderColor.withOpacity(0.5),
                ),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10.r),
                borderSide: BorderSide(
                  color: context.borderColor.withOpacity(0.3),
                ),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10.r),
                borderSide: const BorderSide(
                  color: AppColors.deepGreen,
                ),
              ),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildVatOption(
    BuildContext context, {
    required String title,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    final isDark = context.isDarkMode;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.symmetric(vertical: 10.h),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.deepGreen.withOpacity(0.1)
              : (isDark ? Colors.white.withOpacity(0.05) : Colors.black.withOpacity(0.03)),
          borderRadius: BorderRadius.circular(10.r),
          border: Border.all(
            color: isSelected
                ? AppColors.deepGreen
                : context.borderColor.withOpacity(0.3),
            width: isSelected ? 1.5 : 1,
          ),
        ),
        child: Center(
          child: Text(
            title,
            style: TextStyle(
              fontSize: 12.sp,
              fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
              color: isSelected ? AppColors.deepGreen : context.textSecondaryColor,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildWalletBillingItem(
    BuildContext context,
    Map<String, dynamic> billing,
    bool isSelected,
    void Function(bool) onSelectionChanged,
  ) {
    final billingName = billing['billerName']?.toString() ??
        billing['billingName']?.toString() ??
        billing['customerName']?.toString() ??
        'Биллинг';
    final customerName = billing['customerName']?.toString() ?? '';
    final total = (billing['calculatedTotal'] as num?)?.toDouble() ?? 0.0;
    final bills = billing['bills'] as List? ?? [];
    final isOwnOrg = billing['isOwnOrg'] == true;

    return Container(
      margin: EdgeInsets.only(bottom: 12.h),
      decoration: BoxDecoration(
        color: context.cardBackgroundColor,
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(
          color: isSelected ? AppColors.deepGreen.withOpacity(0.5) : context.borderColor,
          width: isSelected ? 1.5 : 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          initiallyExpanded: isSelected,
          tilePadding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 4.h),
          leading: Checkbox(
            value: isSelected,
            onChanged: (value) {
              if (value != null) onSelectionChanged(value);
            },
            activeColor: AppColors.deepGreen,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4.r)),
          ),
          title: Text(
            billingName,
            style: TextStyle(
              color: context.textPrimaryColor,
              fontSize: 14.sp,
              fontWeight: FontWeight.bold,
            ),
          ),
          subtitle: customerName.isNotEmpty
              ? Text(
                  customerName,
                  style: TextStyle(
                    color: context.textSecondaryColor,
                    fontSize: 12.sp,
                  ),
                )
              : null,
          trailing: Text(
            '${widget.formatNumberWithComma(total)}₮',
            style: TextStyle(
              color: AppColors.deepGreen,
              fontSize: 14.sp,
              fontWeight: FontWeight.bold,
            ),
          ),
          children: isOwnOrg
              ? []
              : [
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 8.h),
                    decoration: BoxDecoration(
                      color: context.isDarkMode
                          ? Colors.white.withOpacity(0.02)
                          : Colors.black.withOpacity(0.01),
                      borderRadius: BorderRadius.vertical(bottom: Radius.circular(16.r)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Padding(
                          padding: EdgeInsets.only(left: 4.w, bottom: 8.h),
                          child: Text(
                            'Нэхэмжлэхүүд (${_selectedBillIds.length}/5 сонгосон)',
                            style: TextStyle(
                              fontSize: 11.sp,
                              fontWeight: FontWeight.w600,
                              color: context.textSecondaryColor,
                            ),
                          ),
                        ),
                        ...bills.map((b) {
                          final bill = Map<String, dynamic>.from(b);
                          final billId = bill['billId']?.toString();
                          final billAmt = (bill['billTotalAmount'] as num?)?.toDouble() ?? 0.0;
                          final billDate = bill['billMonth']?.toString() ?? '';
                          final isBillSelected = billId != null && _selectedBillIds.contains(billId);
                          final canSelectMore = _selectedBillIds.length < 5;

                          return InkWell(
                            onTap: billId == null
                                ? null
                                : () {
                                    setState(() {
                                      if (isBillSelected) {
                                        _selectedBillIds.remove(billId);
                                      } else if (canSelectMore) {
                                        _selectedBillIds.add(billId);
                                      } else {
                                        showGlassSnackBar(
                                          context,
                                          message: 'Дээд тал нь 5 нэхэмжлэх сонгох боломжтой',
                                          icon: Icons.warning_amber_rounded,
                                          iconColor: Colors.orange,
                                        );
                                      }
                                      _totalAmount = _calculateSelectedTotal(_walletBillings);
                                    });
                                  },
                            child: Padding(
                              padding: EdgeInsets.symmetric(vertical: 6.h),
                              child: Row(
                                children: [
                                  SizedBox(
                                    width: 24.w,
                                    height: 24.h,
                                    child: Checkbox(
                                      value: isBillSelected,
                                      onChanged: (val) {
                                        if (billId == null) return;
                                        setState(() {
                                          if (val == true) {
                                            if (canSelectMore) {
                                              _selectedBillIds.add(billId);
                                            } else {
                                              showGlassSnackBar(
                                                context,
                                                message: 'Дээд тал нь 5 нэхэмжлэх сонгох боломжтой',
                                                icon: Icons.warning_amber_rounded,
                                                iconColor: Colors.orange,
                                              );
                                            }
                                          } else {
                                            _selectedBillIds.remove(billId);
                                          }
                                          _totalAmount = _calculateSelectedTotal(_walletBillings);
                                        });
                                      },
                                      activeColor: AppColors.deepGreen,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(3.r),
                                      ),
                                    ),
                                  ),
                                  SizedBox(width: 8.w),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          _getSpecificBillName(bill, billingName),
                                          style: TextStyle(
                                            fontSize: 12.sp,
                                            color: context.textPrimaryColor,
                                          ),
                                        ),
                                        if (billDate.isNotEmpty)
                                          Text(
                                            billDate,
                                            style: TextStyle(
                                              fontSize: 10.sp,
                                              color: context.textSecondaryColor,
                                            ),
                                          ),
                                      ],
                                    ),
                                  ),
                                  Text(
                                    '${widget.formatNumberWithComma(billAmt)}₮',
                                    style: TextStyle(
                                      fontSize: 12.sp,
                                      fontWeight: FontWeight.w600,
                                      color: context.textPrimaryColor,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        }),
                      ],
                    ),
                  ),
                ],
        ),
      ),
    );
  }

  String _getSpecificBillName(Map<String, dynamic> bill, String fallback) {
    final billtype = bill['billtype']?.toString() ?? '';
    final description = bill['description']?.toString() ?? '';
    final name = bill['name']?.toString() ?? '';

    // List of generic names that we want to replace with the more specific billing/biller name
    final genericNames = [
      'Үйлчилгээний төлбөр',
      'Үйлчилгээний хөлс',
      'төлбөр',
      'service fee',
      'subscription',
      'billing',
      'invoice',
      'нэхэмжлэх',
      'default',
      'Орон сууцны төлбөр',
      'Ороц сууцны төлбөр',
      'Орон сууцны хөлс',
      'Property Fee',
      'Fee',
    ];

    bool isGeneric(String val) {
      if (val.isEmpty) return true;
      final lower = val.toLowerCase();
      for (final g in genericNames) {
        if (lower == g.toLowerCase()) return true;
      }
      return false;
    }

    // 1. Prioritize billtype (e.g., СӨХ-ийн төлбөр, Дулааны төлбөр)
    if (!isGeneric(billtype)) return billtype;

    // 2. Fallback to description
    if (!isGeneric(description)) return description;

    // 3. Fallback to name
    if (!isGeneric(name)) return name;

    return fallback;
  }
}
