import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:sukh_app/constants/constants.dart';
import 'package:sukh_app/widgets/optimized_glass.dart';
import 'package:sukh_app/utils/theme_extensions.dart';
import 'package:sukh_app/services/api_service.dart';
import 'package:sukh_app/services/storage_service.dart';
import 'package:sukh_app/components/Nekhemjlekh/bank_selection_modal.dart';
import 'package:sukh_app/components/Nekhemjlekh/qpay_qr_modal.dart';
import 'package:sukh_app/components/Nekhemjlekh/nekhemjlekh_models.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:sukh_app/widgets/glass_snackbar.dart';
import 'package:sukh_app/models/geree_model.dart';

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
  final Set<int> _expandedIndices = {};
  final Set<int> _selectedIndices = {};
  bool _isCreatingQPay = false;
  List<QPayBank> _qpayBanks = [];
  String? _qrImageOwnOrg;
  String? _qrImageWallet;

  // Internal state for payments
  List<Map<String, dynamic>> _payments = [];
  double _totalAmount = 0.0;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadPayments();
  }

  Future<void> _loadPayments() async {
    setState(() {
      _isLoading = true;
    });

    try {
      List<Map<String, dynamic>> allPayments = [];
      double total = 0.0;

      // Load OWN_ORG payments
      try {
        final userId = await StorageService.getUserId();
        if (userId != null) {
          final gereeResponse = await ApiService.fetchGeree(userId);
          if (gereeResponse['jagsaalt'] != null &&
              gereeResponse['jagsaalt'] is List) {
            final List<dynamic> gereeJagsaalt = gereeResponse['jagsaalt'];
            if (gereeJagsaalt.isNotEmpty) {
              final firstContract = gereeJagsaalt[0];
              final geree = Geree.fromJson(firstContract);
              final nekhemjlekhResponse =
                  await ApiService.fetchNekhemjlekhiinTuukh(
                    gereeniiDugaar: geree.gereeniiDugaar,
                  );

              if (nekhemjlekhResponse['jagsaalt'] != null &&
                  nekhemjlekhResponse['jagsaalt'] is List) {
                final List<dynamic> nekhemjlekhJagsaalt =
                    nekhemjlekhResponse['jagsaalt'];
                for (var invoice in nekhemjlekhJagsaalt) {
                  if (invoice['tuluv'] == 'Төлөөгүй') {
                    final niitTulbur = invoice['niitTulbur'];
                    if (niitTulbur != null) {
                      final amount = (niitTulbur is int)
                          ? niitTulbur.toDouble()
                          : (niitTulbur as double);
                      total += amount;
                      allPayments.add({
                        'source': 'OWN_ORG',
                        'billingName': 'Орон сууцны төлбөр',
                        'amount': amount,
                        'invoice': invoice,
                      });
                    }
                  }
                }
              }
            }
          }
        }
      } catch (e) {
        print('Error loading OWN_ORG payments: $e');
      }

      // Load WALLET_API payments
      try {
        final billingList = await ApiService.getWalletBillingList();
        for (var billing in billingList) {
          final billingId = billing['billingId']?.toString();
          if (billingId != null && billingId.isNotEmpty) {
            try {
              final billingData = await ApiService.getWalletBillingBills(
                billingId: billingId,
              );

              // Extract bills from billingData
              List<Map<String, dynamic>> bills = [];
              if (billingData['newBills'] != null &&
                  billingData['newBills'] is List) {
                final newBillsList = billingData['newBills'] as List;
                if (newBillsList.isNotEmpty) {
                  final firstItem = newBillsList[0] as Map<String, dynamic>;
                  if (firstItem.containsKey('billId')) {
                    bills = List<Map<String, dynamic>>.from(newBillsList);
                  } else if (firstItem.containsKey('billingId') &&
                      firstItem['newBills'] != null) {
                    if (firstItem['newBills'] is List) {
                      bills = List<Map<String, dynamic>>.from(
                        firstItem['newBills'],
                      );
                    }
                  }
                }
              } else if (billingData.containsKey('billingId') &&
                  billingData['newBills'] != null) {
                if (billingData['newBills'] is List) {
                  bills = List<Map<String, dynamic>>.from(
                    billingData['newBills'],
                  );
                }
              }

              // Calculate total from payable bills
              double billingTotal = 0.0;
              for (var bill in bills) {
                final billTotalAmount =
                    (bill['billTotalAmount'] as num?)?.toDouble() ?? 0.0;
                billingTotal += billTotalAmount;
              }

              if (billingTotal > 0) {
                total += billingTotal;
                allPayments.add({
                  'source': 'WALLET_API',
                  'billingName':
                      billing['billingName']?.toString() ?? 'Биллинг',
                  'customerName': billing['customerName']?.toString() ?? '',
                  'amount': billingTotal,
                  'bills': bills,
                  'billing': billing,
                });
              }
            } catch (e) {
              print('Error loading billing: $e');
            }
          }
        }
      } catch (e) {
        print('Error loading WALLET_API payments: $e');
      }

      if (mounted) {
        setState(() {
          _payments = allPayments;
          _totalAmount = total;
          _isLoading = false;
          // Select all payments by default
          _selectedIndices.clear();
          _selectedIndices.addAll(List.generate(_payments.length, (i) => i));
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  // Group payments by source
  Map<String, List<Map<String, dynamic>>> _groupPaymentsBySource() {
    final grouped = <String, List<Map<String, dynamic>>>{};
    for (int i = 0; i < _payments.length; i++) {
      final payment = _payments[i];
      final source = payment['source'] as String;
      if (!grouped.containsKey(source)) {
        grouped[source] = [];
      }
      grouped[source]!.add({...payment, 'index': i});
    }
    return grouped;
  }

  // Get total amount for selected payments in a source
  double _getSelectedAmountForSource(String source) {
    final grouped = _groupPaymentsBySource();
    final payments = grouped[source] ?? [];
    double total = 0.0;
    for (var payment in payments) {
      final index = payment['index'] as int;
      if (_selectedIndices.contains(index)) {
        total += (payment['amount'] as num?)?.toDouble() ?? 0.0;
      }
    }
    return total;
  }

  // Check if any payment is selected for a source
  bool _hasSelectedPaymentsForSource(String source) {
    final grouped = _groupPaymentsBySource();
    final payments = grouped[source] ?? [];
    for (var payment in payments) {
      final index = payment['index'] as int;
      if (_selectedIndices.contains(index)) {
        return true;
      }
    }
    return false;
  }

  // Get selected payment indices for a source
  List<int> _getSelectedIndicesForSource(String source) {
    final grouped = _groupPaymentsBySource();
    final payments = grouped[source] ?? [];
    return payments
        .where((p) => _selectedIndices.contains(p['index'] as int))
        .map((p) => p['index'] as int)
        .toList();
  }

  Future<void> _handlePayForSource(String source) async {
    if (!_hasSelectedPaymentsForSource(source)) {
      showGlassSnackBar(
        context,
        message: 'Төлбөр сонгоно уу',
        icon: Icons.warning,
        iconColor: Colors.orange,
      );
      return;
    }

    setState(() {
      _isCreatingQPay = true;
      _qpayBanks = [];
      _qrImageOwnOrg = null;
      _qrImageWallet = null;
    });

    try {
      final selectedIndices = _getSelectedIndicesForSource(source);
      final selectedPayments = selectedIndices
          .map((i) => _payments[i])
          .toList();

      double totalAmount = 0.0;
      String? turul;
      String? firstInvoiceId;
      String? dansniiDugaar;
      String? burtgeliinDugaar;

      // Calculate total and get invoice details
      for (var payment in selectedPayments) {
        totalAmount += (payment['amount'] as num?)?.toDouble() ?? 0.0;

        if (source == 'OWN_ORG') {
          final invoice = payment['invoice'] as Map<String, dynamic>?;
          if (invoice != null) {
            turul ??= invoice['gereeniiDugaar']?.toString();
            firstInvoiceId ??=
                invoice['_id']?.toString() ?? invoice['id']?.toString();
            dansniiDugaar ??= invoice['dansniiDugaar']?.toString();
            burtgeliinDugaar ??= invoice['register']?.toString();
          }
        } else if (source == 'WALLET_API') {
          final bills = payment['bills'] as List<dynamic>?;
          if (bills != null && bills.isNotEmpty) {
            final firstBill = bills.first as Map<String, dynamic>;
            turul ??= firstBill['gereeniiDugaar']?.toString();
          }
        }
      }

      if (totalAmount <= 0) {
        throw Exception('Төлбөрийн дүн 0 байна');
      }

      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final orderNumber = 'BALANCE-$timestamp';

      // Get address IDs
      final ownOrgBaiguullagiinId = await StorageService.getBaiguullagiinId();
      final ownOrgBarilgiinId = await StorageService.getBarilgiinId();
      final walletBairId = await StorageService.getWalletBairId();
      final walletSource = await StorageService.getWalletBairSource();

      final hasOwnOrg =
          ownOrgBaiguullagiinId != null && ownOrgBarilgiinId != null;
      final hasWallet = walletBairId != null && walletSource == 'WALLET_API';

      // Create QPay invoice based on source
      if (source == 'OWN_ORG' && hasOwnOrg) {
        final ownOrgResponse = await ApiService.qpayGargaya(
          baiguullagiinId: ownOrgBaiguullagiinId,
          barilgiinId: ownOrgBarilgiinId,
          dun: totalAmount,
          turul: turul ?? '',
          zakhialgiinDugaar: '$orderNumber-OWN_ORG',
          nekhemjlekhiinId: firstInvoiceId,
          dansniiDugaar: dansniiDugaar,
          burtgeliinDugaar: burtgeliinDugaar,
        );

        _qrImageOwnOrg = ownOrgResponse['qr_image']?.toString();

        if (ownOrgResponse['urls'] != null && ownOrgResponse['urls'] is List) {
          _qpayBanks = (ownOrgResponse['urls'] as List)
              .map((bank) => QPayBank.fromJson(bank))
              .toList();
        }
      } else if (source == 'WALLET_API' && hasWallet) {
        // Get walletUserId from user profile
        String? walletUserId;
        try {
          final userProfile = await ApiService.getUserProfile();
          if (userProfile['result']?['walletCustomerId'] != null) {
            walletUserId = userProfile['result']['walletCustomerId'].toString();
          } else if (userProfile['result']?['utas'] != null) {
            walletUserId = userProfile['result']['utas'].toString();
          }
        } catch (e) {
          print('Error getting walletUserId: $e');
        }

        final walletResponse = await ApiService.qpayGargaya(
          walletUserId: walletUserId,
          walletBairId: walletBairId,
          dun: totalAmount,
          turul: turul ?? '',
          zakhialgiinDugaar: '$orderNumber-WALLET',
        );

        _qrImageWallet =
            walletResponse['qr_image']?.toString() ??
            walletResponse['qrText']?.toString();

        if (walletResponse['urls'] != null && walletResponse['urls'] is List) {
          _qpayBanks = (walletResponse['urls'] as List)
              .map((bank) => QPayBank.fromJson(bank))
              .toList();
        }
      } else {
        throw Exception(
          '${source == 'OWN_ORG' ? 'OWN_ORG' : 'WALLET'} хаяг олдсонгүй',
        );
      }

      if (!mounted) return;

      // Show bank selection modal or QR code
      if (_qrImageOwnOrg == null && _qrImageWallet == null) {
        throw Exception('QPay мэдээлэл олдсонгүй');
      }

      // Always show bank application list BEFORE showing QR.
      // If backend didn't return bank urls, at least show qPay wallet option.
      if (_qpayBanks.isEmpty) {
        _qpayBanks = [
          QPayBank(
            name: 'QPay Wallet',
            description: 'qPay хэтэвч',
            logo: '',
            link: '',
          ),
        ];
      }

      _showBankSelectionModal(source);
    } catch (e) {
      if (mounted) {
        showGlassSnackBar(
          context,
          message: 'Алдаа: $e',
          icon: Icons.error,
          iconColor: Colors.red,
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isCreatingQPay = false;
        });
      }
    }
  }

  void _showBankSelectionModal(String source) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => BankSelectionModal(
        qpayBanks: _qpayBanks,
        isLoadingQPay: false,
        onBankTap: (bank) => _openBankAppAndShowQR(bank, source),
        onQPayWalletTap: _showQRCodeModal,
      ),
    );
  }

  Future<void> _openBankAppAndShowQR(QPayBank bank, String source) async {
    try {
      final Uri bankUri = Uri.parse(bank.link);

      // Close the bank selection modal
      Navigator.of(context).pop();

      // Try to launch the bank app
      bool launched = false;
      try {
        launched = await launchUrl(
          bankUri,
          mode: LaunchMode.externalApplication,
        );
      } catch (e) {
        print('Error launching bank app: $e');
        launched = false;
      }

      if (launched) {
        // Wait a moment for the app to open, then show QR code
        await Future.delayed(const Duration(seconds: 1));

        if (mounted) {
          _showQRCodeModal();
        }
      } else {
        // Bank app not installed - show QR code anyway
        if (mounted) {
          _showQRCodeModal();
        }
      }
    } catch (e) {
      print('Error in _openBankAppAndShowQR: $e');
      if (mounted) {
        _showQRCodeModal();
      }
    }
  }

  void _showQRCodeModal() {
    showDialog(
      context: context,
      builder: (context) => QPayQRModal(
        qrImageOwnOrg: _qrImageOwnOrg,
        qrImageWallet: _qrImageWallet,
        closeOnSuccess: true,
        onCheckPaymentAsync: () async {
          // We don't have an exact invoice status here; refresh and close.
          widget.onPaymentTap();
          Navigator.of(context).pop(); // Close QR modal
          Navigator.of(context).pop(); // Close balance modal
          return true;
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final groupedPayments = _groupPaymentsBySource();
    final ownOrgPayments = groupedPayments['OWN_ORG'] ?? [];
    final walletPayments = groupedPayments['WALLET_API'] ?? [];

    return Container(
      height: MediaQuery.of(context).size.height * 0.85,
      width: double.infinity,
      child: Stack(
        children: [
          Positioned.fill(
            child: Container(color: Colors.black.withOpacity(0.5)),
          ),
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                color: context.isDarkMode
                    ? Colors.transparent
                    : AppColors.lightBackground,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(50.r),
                  topRight: Radius.circular(50.r),
                ),
                border: Border.all(color: context.borderColor, width: 1),
              ),
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
                          color: context.borderColor,
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
                              color: AppColors.deepGreen,
                              size: 24.sp,
                            ),
                            SizedBox(width: 11.w),
                            Text(
                              'Нийт үлдэгдэл',
                              style: TextStyle(
                                color: context.textPrimaryColor,
                                fontSize: 11.sp,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                        IconButton(
                          icon: Icon(
                            Icons.close_rounded,
                            color: context.textPrimaryColor,
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
                        color: AppColors.deepGreen.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(11.r),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Нийт дүн',
                            style: TextStyle(
                              color: context.textPrimaryColor,
                              fontSize: 11.sp,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          Text(
                            '${widget.formatNumberWithComma(_totalAmount)}₮',
                            style: TextStyle(
                              color: AppColors.deepGreen,
                              fontSize: 11.sp,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                    SizedBox(height: 16.h),
                    // Billing list
                    if (_isLoading)
                      Center(
                        child: Padding(
                          padding: EdgeInsets.all(22.h),
                          child: CircularProgressIndicator(
                            color: AppColors.deepGreen,
                          ),
                        ),
                      )
                    else if (_payments.isEmpty)
                      Center(
                        child: Padding(
                          padding: EdgeInsets.all(22.h),
                          child: Text(
                            'Төлбөр байхгүй байна',
                            style: TextStyle(
                              color: context.textSecondaryColor,
                              fontSize: 11.sp,
                            ),
                          ),
                        ),
                      )
                    else
                      Expanded(
                        child: ListView(
                          children: [
                            // OWN_ORG Section
                            if (ownOrgPayments.isNotEmpty) ...[
                              _buildSectionHeader(
                                'OWN_ORG',
                                ownOrgPayments.length,
                              ),
                              SizedBox(height: 8.h),
                              ...ownOrgPayments.map((payment) {
                                final index = payment['index'] as int;
                                return _buildPaymentItem(payment, index);
                              }),
                              SizedBox(height: 16.h),
                              _buildPayButton(
                                'OWN_ORG',
                                _getSelectedAmountForSource('OWN_ORG'),
                                _hasSelectedPaymentsForSource('OWN_ORG'),
                              ),
                              SizedBox(height: 24.h),
                            ],
                            // WALLET_API Section
                            if (walletPayments.isNotEmpty) ...[
                              _buildSectionHeader(
                                'WALLET_API',
                                walletPayments.length,
                              ),
                              SizedBox(height: 8.h),
                              ...walletPayments.map((payment) {
                                final index = payment['index'] as int;
                                return _buildPaymentItem(payment, index);
                              }),
                              SizedBox(height: 16.h),
                              _buildPayButton(
                                'WALLET_API',
                                _getSelectedAmountForSource('WALLET_API'),
                                _hasSelectedPaymentsForSource('WALLET_API'),
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
          // Loading overlay
          if (_isCreatingQPay)
            Positioned.fill(
              child: Container(
                color: Colors.black.withOpacity(0.3),
                child: Center(
                  child: CircularProgressIndicator(color: AppColors.deepGreen),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String source, int count) {
    final isOwnOrg = source == 'OWN_ORG';
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 8.h),
      decoration: BoxDecoration(
        color: isOwnOrg
            ? Colors.blue.withOpacity(0.1)
            : Colors.green.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8.r),
        border: Border.all(
          color: isOwnOrg
              ? Colors.blue.withOpacity(0.3)
              : Colors.green.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Icon(
            isOwnOrg ? Icons.business : Icons.account_balance_wallet,
            color: isOwnOrg ? Colors.blue : Colors.green,
            size: 20.sp,
          ),
          SizedBox(width: 8.w),
          Text(
            isOwnOrg ? 'OWN_ORG' : 'WALLET',
            style: TextStyle(
              color: isOwnOrg ? Colors.blue : Colors.green,
              fontSize: 12.sp,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(width: 8.w),
          Text(
            '($count)',
            style: TextStyle(
              color: context.textSecondaryColor,
              fontSize: 11.sp,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPaymentItem(Map<String, dynamic> payment, int index) {
    final source = payment['source'] as String;
    final billingName = payment['billingName']?.toString() ?? 'Биллинг';
    final customerName = payment['customerName']?.toString() ?? '';
    final amount = (payment['amount'] as num?)?.toDouble() ?? 0.0;
    final isExpanded = _expandedIndices.contains(index);
    final isSelected = _selectedIndices.contains(index);

    return Container(
      margin: EdgeInsets.only(bottom: 11.h),
      decoration: BoxDecoration(
        color: context.cardBackgroundColor,
        borderRadius: BorderRadius.circular(11.r),
        border: Border.all(
          color: isSelected ? AppColors.deepGreen : context.borderColor,
          width: isSelected ? 2 : 1,
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
                child: Row(
                  children: [
                    // Checkbox
                    Checkbox(
                      value: isSelected,
                      onChanged: (value) {
                        setState(() {
                          if (value == true) {
                            _selectedIndices.add(index);
                          } else {
                            _selectedIndices.remove(index);
                          }
                        });
                      },
                      activeColor: AppColors.deepGreen,
                    ),
                    SizedBox(width: 8.w),
                    // Payment info
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            billingName,
                            style: TextStyle(
                              color: context.textPrimaryColor,
                              fontSize: 11.sp,
                              fontWeight: FontWeight.bold,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          if (customerName.isNotEmpty) ...[
                            SizedBox(height: 4.h),
                            Text(
                              customerName,
                              style: TextStyle(
                                color: context.textSecondaryColor,
                                fontSize: 11.sp,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                          SizedBox(height: 8.h),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'Төлөх дүн',
                                style: TextStyle(
                                  color: context.textSecondaryColor,
                                  fontSize: 11.sp,
                                ),
                              ),
                              Text(
                                '${widget.formatNumberWithComma(amount)}₮',
                                style: TextStyle(
                                  color: AppColors.deepGreen,
                                  fontSize: 11.sp,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    SizedBox(width: 8.w),
                    // Source badge and expand icon
                    Row(
                      children: [
                        Container(
                          padding: EdgeInsets.symmetric(
                            horizontal: 8.w,
                            vertical: 4.h,
                          ),
                          decoration: BoxDecoration(
                            color: source == 'OWN_ORG'
                                ? Colors.blue.withOpacity(0.2)
                                : Colors.green.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(11.r),
                          ),
                          child: Text(
                            source == 'OWN_ORG' ? 'OWN_ORG' : 'WALLET',
                            style: TextStyle(
                              color: source == 'OWN_ORG'
                                  ? Colors.blue
                                  : Colors.green,
                              fontSize: 10.sp,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        SizedBox(width: 8.w),
                        Icon(
                          isExpanded ? Icons.expand_less : Icons.expand_more,
                          color: context.textSecondaryColor,
                          size: 20.sp,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
          if (isExpanded) ...[
            Divider(color: context.borderColor, height: 1),
            Padding(
              padding: EdgeInsets.all(14.w),
              child: _buildPaymentDetails(payment),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildPayButton(String source, double amount, bool hasSelection) {
    final isOwnOrg = source == 'OWN_ORG';
    return SizedBox(
      width: double.infinity,
      child: OptimizedGlass(
        borderRadius: BorderRadius.circular(11.r),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: hasSelection && !_isCreatingQPay
                ? () => _handlePayForSource(source)
                : null,
            borderRadius: BorderRadius.circular(11.r),
            child: Container(
              padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 14.h),
              decoration: BoxDecoration(
                color: hasSelection
                    ? (isOwnOrg ? Colors.blue : Colors.green)
                    : Colors.grey.withOpacity(0.3),
                borderRadius: BorderRadius.circular(11.r),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.payment_rounded, color: Colors.white, size: 22.sp),
                  SizedBox(width: 11.w),
                  Text(
                    '${isOwnOrg ? 'OWN_ORG' : 'WALLET'} төлөх (${widget.formatNumberWithComma(amount)}₮)',
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
              color: context.textPrimaryColor,
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
              color: context.textPrimaryColor,
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
                color: context.cardBackgroundColor,
                borderRadius: BorderRadius.circular(11.r),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (billType.isNotEmpty)
                    Text(
                      billType,
                      style: TextStyle(
                        color: context.textPrimaryColor,
                        fontSize: 11.sp,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  if (billPeriod.isNotEmpty) ...[
                    SizedBox(height: 4.h),
                    Text(
                      'Хугацаа: $billPeriod',
                      style: TextStyle(
                        color: context.textSecondaryColor,
                        fontSize: 11.sp,
                      ),
                    ),
                  ],
                  SizedBox(height: 4.h),
                  Text(
                    '${widget.formatNumberWithComma(billTotalAmount)}₮',
                    style: TextStyle(
                      color: AppColors.deepGreen,
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
          style: TextStyle(color: context.textSecondaryColor, fontSize: 11.sp),
        ),
        Text(
          value,
          style: TextStyle(
            color: context.textPrimaryColor,
            fontSize: 11.sp,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}
