import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:sukh_app/constants/constants.dart';
import 'package:sukh_app/services/api_service.dart';
import 'package:sukh_app/services/storage_service.dart';
import 'package:sukh_app/screens/Home/payment_history_page.dart';
import 'package:sukh_app/utils/theme_extensions.dart';
import 'package:sukh_app/widgets/glass_snackbar.dart';
import 'package:sukh_app/components/Nekhemjlekh/qpay_qr_modal.dart';
import 'package:sukh_app/components/Nekhemjlekh/vat_receipt_modal.dart';
import 'package:sukh_app/components/Nekhemjlekh/nekhemjlekh_models.dart';
import 'package:intl/intl.dart';
import 'package:go_router/go_router.dart';
import 'package:sukh_app/widgets/standard_app_bar.dart';
import 'package:sukh_app/utils/format_util.dart'
    show formatInvoiceDate, formatBillPeriod;

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

  // Track real-time status of bills from recent wallet transactions
  final Map<String, String> _billStatuses = {};
  final Map<String, String> _billStatusTexts = {};
  final Map<String, Color> _billStatusColors = {};

  @override
  void initState() {
    super.initState();
    _loadAllBillingsData();
  }

  Map<String, dynamic> _extractBillingData(
    Map<String, dynamic> data,
    String? billingId,
  ) {
    if (billingId == null) {
      return {'bills': <Map<String, dynamic>>[], 'billingName': null};
    }

    // Path 1: Direct structure (Data is the billing object)
    final directBills = data['newBills'] ?? data['bills'];
    if (directBills is List && (data['billingId']?.toString() == billingId || data['billingId'] == null)) {

      return {
        'bills': List<Map<String, dynamic>>.from(directBills),
        'billingName': data['billingName'],
      };
    }

    // Path 2: Nested in 'data' field (User's JSON structure)
    if (data['data'] != null) {
      final rawData = data['data'];
      if (rawData is List) {
        final matchedItem = rawData.firstWhere(
          (item) => item is Map && (item['billingId']?.toString() == billingId),
          orElse: () => rawData.isNotEmpty ? rawData[0] : null,
        );
        if (matchedItem is Map) {
          final billsList = matchedItem['newBills'] ?? matchedItem['bills'];
          if (billsList is List) {

            return {
              'bills': List<Map<String, dynamic>>.from(billsList),
              'billingName': matchedItem['billingName'],
            };
          }
        }
      } else if (rawData is Map) {
        final billsList = rawData['newBills'] ?? rawData['bills'];
        if (billsList is List) {

          return {
            'bills': List<Map<String, dynamic>>.from(billsList),
            'billingName': rawData['billingName'],
          };
        }
      }
    }

    // Path 3: Root newBills is a list of billings
    if (data['newBills'] is List) {
      final itemList = data['newBills'] as List;
      if (itemList.isNotEmpty) {
        final first = itemList[0];
        if (first is Map && first.containsKey('billId')) {

          return {
            'bills': List<Map<String, dynamic>>.from(itemList),
            'billingName': data['billingName'],
          };
        }
        
        final matchedItem = itemList.firstWhere(
          (item) => item is Map && item['billingId']?.toString() == billingId,
          orElse: () => itemList[0],
        );
        if (matchedItem is Map) {
          final billsList = matchedItem['newBills'] ?? matchedItem['bills'];
          if (billsList is List) {

            return {
              'bills': List<Map<String, dynamic>>.from(billsList),
              'billingName': matchedItem['billingName'],
            };
          }
        }
      }
    }


    return {'bills': <Map<String, dynamic>>[], 'billingName': null};
  }

  Future<void> _loadAllBillingsData() async {
    try {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
        _allBillingsData = [];
        _allBills = [];
      });

      // If we have billingData passed from parent, use it instead of re-fetching
      if (widget.billingData != null) {


        final billingData = widget.billingData!;
        final billingId = widget.billing['billingId']?.toString();

        final extracted = _extractBillingData(billingData, billingId);
        var bills = extracted['bills'] as List<Map<String, dynamic>>;
        final bName =
            extracted['billingName']?.toString() ??
            billingData['billingName']?.toString() ??
            'Хэрэглээний төлбөр';

        // Add metadata to each bill
        for (var bill in bills) {
          bill['parentBillingId'] = billingId;
          bill['parentBillerName'] = bName;
          _allBills.add(bill);
        }

        if (!mounted) return;

        setState(() {
          _allBillingsData = [widget.billing];
          // Auto-select first 5 bills initially
          int count = 0;
          for (var bill in _allBills) {
            if (count >= 5) break;
            final id = bill['billId']?.toString();
            if (id != null) {
              _selectedBillIds.add(id);
              count++;
            }
          }
        });
        
        // Even if using passed data, check for recent wallet statuses
        await _checkRecentWalletStatuses();
        
        setState(() {
          _isLoading = false;
        });
        return;
      }

      // Original logic - only run if no billingData was passed


      // 1. Get the list of billings to process
      final specificBillingId = widget.billing['billingId']?.toString();
      List<Map<String, dynamic>> targetBillingList = [];

      // Fetch fresh list from API to get latest tuluv/uldegdel
      final fullList = await ApiService.getWalletBillingList(forceRefresh: true);
      
      if (specificBillingId != null && specificBillingId.isNotEmpty) {
        // Find the updated version of this specific billing in the fresh list
        final updatedOne = fullList.firstWhere(
          (b) => b['billingId']?.toString() == specificBillingId,
          orElse: () => widget.billing, // Fallback to current if not found (unlikely)
        );
        targetBillingList = [updatedOne];
      } else {
        targetBillingList = fullList;
      }

      if (targetBillingList.isEmpty) {
        setState(() {
          _isLoading = false;
          _errorMessage = 'Холбогдсон биллинг олдсонгүй';
        });
        return;
      }

      // 2. Fetch bills for each billing provider
      List<Map<String, dynamic>> collectedBills = [];
      for (var billing in targetBillingList) {
        final billingId = billing['billingId']?.toString();
        final source = billing['source']?.toString();
        

        
        if (billingId == null) {

          continue;
        }

        try {
          if (source == 'OWN_ORG') {
            final gereeniiDugaar =
                billing['gereeniiDugaar']?.toString() ?? billingId;
            final baiguullagiinId = billing['baiguullagiinId']?.toString();
            final gereeniiId = billing['gereeniiId']?.toString();

            // Fetch unified invoices with their ledger items (Ledger-First architecture)
            final unifiedResponse = await ApiService.fetchInvoicesWithItems(
              gereeniiDugaar: gereeniiDugaar,
              gereeniiId: gereeniiId ?? '',
              baiguullagiinId: baiguullagiinId ?? '',
            );

            final mergedInvoices = unifiedResponse['jagsaalt'] ?? [];
            final double totalUldegdel = (unifiedResponse['totalUldegdel'] ?? 0.0).toDouble();

            // Ledger balance is the authoritative total


            // Standard OWN_ORG logic: use official merged invoices
            final Set<String> seenIds = {};
            double runningSum = 0.0;

            for (var inv in mergedInvoices) {
              final invId = inv['_id']?.toString() ?? inv['id']?.toString();
              
              // Authoritative check: if we already identified this bill as paid/pending in recent cache, skip!
              if (invId != null && _billStatuses.containsKey(invId)) {
                 continue;
              }
              
              if (invId != null && inv['tuluv'] == 'Төлсөн') {
                _billStatuses[invId] = 'PAID';
                _billStatusTexts[invId] = 'Төлөгдсөн';
                _billStatusColors[invId] = Colors.green;
                continue; // Hide from outstanding list
              }

              final invoiceId = invId ?? '';
              if (invoiceId.isNotEmpty && seenIds.contains(invoiceId)) {
                continue;
              }
              
              final item = NekhemjlekhItem.fromJson(inv);
              final paymentAmt = item.effectiveNiitTulbur;

              
              runningSum += paymentAmt;

              if (invoiceId.isNotEmpty) seenIds.add(invoiceId);

              final rawDate = inv['ognoo']?.toString() ?? inv['nekhemjlekhiinOgnoo']?.toString() ?? '';
              final formattedDate = formatInvoiceDate(rawDate);

              collectedBills.add({
                'billId': invoiceId,
                'billTotalAmount': paymentAmt,
                'billLateFee': 0.0,
                'billPeriod': formattedDate,
                'billtype': 'Орон сууц',
                'billerName': billing['billingName'] ?? 'Орон сууцны төлбөр',
                'customerAddress':
                    billing['customerAddress'] ?? billing['bairniiNer'] ?? '',
                'parentBillingId': billingId,
                'parentBillerName':
                    billing['billingName'] ?? 'Орон сууцны төлбөр',
                'source': 'OWN_ORG',
              });
            }

            // If authoritative balance differs from runningSum, we trust the balance
            if (totalUldegdel >= 0 && (totalUldegdel - runningSum).abs() > 10) {

               billing['uldegdel'] = totalUldegdel;
               billing['perItemTotal'] = totalUldegdel;
            }

          } else {
            // Standard WALLET_API logic
            final billingData = await ApiService.getWalletBillingBills(
              billingId: billingId,
            );

            final extracted = _extractBillingData(billingData, billingId);
            final bills = extracted['bills'] as List<Map<String, dynamic>>;
            final bName = extracted['billingName']?.toString();

            // Add metadata to each bill to know which billing it belongs to
            for (var bill in bills) {
              bill['parentBillingId'] = billingId;
              bill['parentBillerName'] =
                  billing['billerName'] ??
                  bName ??
                  billingData['billingName'] ??
                  'Хэрэглээний төлбөр';
              bill['source'] = 'WALLET_API';
              collectedBills.add(bill);
            }
          }
        } catch (e) {

        }
      }

      if (!mounted) return;

      setState(() {
        _allBillingsData = targetBillingList;
        _allBills = collectedBills;

        // Auto-select first 5 bills initially
        int count = 0;
        for (var bill in _allBills) {
          if (count >= 5) break;
          final id = bill['billId']?.toString();
          if (id != null) {
            _selectedBillIds.add(id);
            count++;
          }
        }
      });
      
      // After loading bills, check for any recent wallet statuses to override display
      await _checkRecentWalletStatuses();
      
      setState(() {
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

  Future<void> _checkRecentWalletStatuses() async {
    try {
      // Collect all billNos currently shown in detail view for quick lookup
      final Set<String> shownBillNos = {};
      final Set<String> shownBillIds = {};
      for (var bill in _allBills) {
        final bNo = bill['billNo']?.toString();
        final bId = bill['billId']?.toString();
        if (bNo != null && bNo.isNotEmpty) shownBillNos.add(bNo);
        if (bId != null && bId.isNotEmpty) shownBillIds.add(bId);
      }
      if (shownBillNos.isEmpty && shownBillIds.isEmpty) return;

      final history = await ApiService.fetchWalletQpayList();
      if (history.isEmpty) return;

      for (var payment in history.take(10)) {
        final walletPaymentId = payment['walletPaymentId']?.toString() ?? '';
        final zakhialgiinDugaar = payment['zakhialgiinDugaar']?.toString() ?? '';
        final checkId = walletPaymentId.isNotEmpty ? walletPaymentId : zakhialgiinDugaar;
        if (checkId.isEmpty) continue;

        try {
          final statusRes = await ApiService.walletQpayWalletCheck(walletPaymentId: checkId);
          if (statusRes['success'] != true || statusRes['data'] == null) continue;

          final walletData = statusRes['data'];
          final state = walletData['paymentStatus']?.toString().toUpperCase() ?? '';

          final hasSuccessfulTrx = (walletData['paymentTransactions'] as List?)?.any((trx) =>
            (trx['trxStatus']?.toString().toUpperCase() == 'SUCCESS') ||
            (trx['trxStatusName']?.toString() == 'Амжилттай')
          ) ?? false;

          bool hasSuccessfulTrxInLines = false;
          final lines = walletData['lines'] as List?;
          if (lines != null) {
            for (var line in lines) {
              final lineTrx = line['billTransactions'] as List?;
              if (lineTrx != null && lineTrx.any((trx) =>
                (trx['trxStatus']?.toString().toUpperCase() == 'SUCCESS') ||
                (trx['trxStatusName']?.toString() == 'Амжилттай'))) {
                hasSuccessfulTrxInLines = true;
                break;
              }
            }
          }

          if (state != 'PAID' && state != 'PENDING' && !hasSuccessfulTrx && !hasSuccessfulTrxInLines) continue;

          // Extract billNos from lines — check if any match shown bills
          final Set<String> paymentBillNos = {};
          if (lines != null) {
            for (var line in lines) {
              final lBillNo = line['billNo']?.toString();
              final lBillId = line['billId']?.toString();
              if (lBillNo != null && lBillNo.isNotEmpty) paymentBillNos.add(lBillNo);
              if (lBillId != null && lBillId.isNotEmpty) paymentBillNos.add(lBillId);
            }
          }

          // Check if this payment covers any bills in our view
          final hasMatch = paymentBillNos.any((no) =>
            shownBillNos.contains(no) || shownBillIds.contains(no));
          if (!hasMatch) continue;

          // Mark matched bills as paid/pending — remove them from the view
          if (mounted) {
            setState(() {
              _allBills.removeWhere((bill) {
                final bNo = bill['billNo']?.toString() ?? '';
                final bId = bill['billId']?.toString() ?? '';
                final match = paymentBillNos.contains(bNo) || paymentBillNos.contains(bId);
                if (match) {

                }
                return match;
              });
              // Also deselect them
              for (var no in paymentBillNos) {
                _selectedBillIds.remove(no);
              }
            });
          }
        } catch (e) {

        }
      }
    } catch (e) {

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

  double? _toSafeDouble(dynamic value) {
    if (value == null) return null;
    if (value is num) return value.toDouble();
    if (value is String) return double.tryParse(value);
    return null;
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

      // 1. Group selected bills by billingId and source
      Map<String, List<Map<String, dynamic>>> selectedBillsByBilling = {};
      for (var bill in _allBills) {
        final id = bill['billId']?.toString();
        final bId = bill['parentBillingId']?.toString();
        if (id != null && _selectedBillIds.contains(id) && bId != null) {
          selectedBillsByBilling.putIfAbsent(bId, () => []).add(bill);
        }
      }

      if (selectedBillsByBilling.isEmpty) return;

      // Currently, we process one provider at a time to keep it simple and match backend
      final firstBillingId = selectedBillsByBilling.keys.first;
      final selectedBills = selectedBillsByBilling[firstBillingId]!;
      final source = selectedBills.first['source']?.toString();
      final selectedBillIds = selectedBills
          .map((b) => b['billId']?.toString() ?? '')
          .toList();
      final totalAmount = selectedBills.fold(
        0.0,
        (sum, b) => sum + (b['billTotalAmount'] ?? 0.0),
      );

      Map<String, dynamic>? qpayResponse;

      String? baiguullagiinId;
      String? barilgiinId;

      if (source == 'OWN_ORG') {
        // Find the original billing entry to get baiguullagiinId/barilgiinId
        final billingEntry = _allBillingsData.firstWhere(
          (b) => b['billingId']?.toString() == firstBillingId,
          orElse: () => widget.billing,
        );
        baiguullagiinId = billingEntry['baiguullagiinId']?.toString();
        barilgiinId =
            billingEntry['barilgiinId']?.toString() ??
            billingEntry['walletBairId']?.toString();

        // Use custom QPay for OWN_ORG
        final gereeniiDugaar =
            billingEntry['gereeniiDugaar']?.toString() ??
            billingEntry['walletContractNo']?.toString() ??
            '';
        qpayResponse = await ApiService.qpayGargaya(
          baiguullagiinId: baiguullagiinId,
          barilgiinId: barilgiinId,
          dun: totalAmount,
          gereeniiId: billingEntry['gereeniiId']?.toString(),
          nekhemjlekhiinIds: selectedBillIds,
          turul: gereeniiDugaar.isNotEmpty
              ? gereeniiDugaar
              : 'Орон сууцны төлбөр',
        );
        if (qpayResponse != null) {
          qpayResponse!['success'] = true;
        }
      } else {
        // Standard Wallet API payout
        qpayResponse = await ApiService.createWalletQPayPayment(
          billingId: firstBillingId,
          billIds: selectedBillIds,
          vatReceiveType: _vatReceiveType,
          vatCompanyReg: _vatReceiveType == 'COMPANY'
              ? _vatCompanyRegController.text
              : null,
        );
      }

      if (!mounted) return;

      if (qpayResponse?['success'] == true) {

        // Register these IDs as PENDING immediately to skip double-payment risks
        for(var bid in selectedBillIds) {
           _billStatuses[bid] = 'PENDING';
           _billStatusTexts[bid] = 'Төлбөр хүлээгдэж байна';
           _billStatusColors[bid] = Colors.orange;
        }
        
        final walletPaymentId = qpayResponse?['walletPaymentId']?.toString();
        final qpayInvoiceId =
            qpayResponse?['invoice_id']?.toString() ??
            qpayResponse?['invoiceId']?.toString() ??
            qpayResponse?['id']?.toString(); // Legacy/v2 field
        final paymentAmount = _toSafeDouble(qpayResponse?['paymentAmount']) ??
            _toSafeDouble(qpayResponse?['amount']) ??
            totalAmount;
        final qrText =
            qpayResponse?['qrText']?.toString() ??
            qpayResponse?['qr_text']?.toString();
        final qrImage = qpayResponse?['qr_image']?.toString();
        final urls = qpayResponse?['urls'] as List<dynamic>?;
        final responseSource = qpayResponse?['source']?.toString() ?? source;

        final paid = await Navigator.of(context).push<bool>(
          MaterialPageRoute(
            builder: (ctx) => QPayQRModal(
              qrText: qrText,
              qrImageWallet: (responseSource == 'WALLET_API' || responseSource == 'WALLET_QPAY') ? qrImage : null,
              qrImageOwnOrg: responseSource == 'OWN_ORG' ? qrImage : null,
              urls: urls,
              amount: paymentAmount,
              walletPaymentId: walletPaymentId,
              invoiceNumber: qpayInvoiceId,

              closeOnSuccess: true,
              onCheckPaymentAsync: () async {

                
                if ((responseSource == 'WALLET_API' || responseSource == 'WALLET_QPAY') && walletPaymentId != null) {

                  try {
                    // Check the full wallet status including transactions
                    final statusRes = await ApiService.walletQpayWalletCheck(
                      walletPaymentId: walletPaymentId,
                    );
                    
                    if (statusRes['success'] == true && statusRes['data'] != null) {
                      final walletData = statusRes['data'];
                      final state = walletData['paymentStatus']?.toString().toUpperCase();
                      
                      // Check for success transactions in paymentTransactions list
                      final transactions = walletData['paymentTransactions'] as List?;
                      bool hasSuccessfulTrx = false;
                      if (transactions != null) {
                        hasSuccessfulTrx = transactions.any((trx) => 
                          (trx['trxStatus']?.toString().toUpperCase() == 'SUCCESS') ||
                          (trx['trxStatusName']?.toString() == 'Амжилттай')
                        );
                      }

                      if (state == 'PAID' || hasSuccessfulTrx) return true;
                      if (state == 'PENDING') return null;
                    }
                    return false;
                  } catch (e) {

                    return null;
                  }
                } else if (source == 'OWN_ORG') {

                  bool confirmed = false;
                  
                  // 1. Direct QPay API check (if ID exists)
                  if (qpayInvoiceId != null) {
                    try {
                      final status = await ApiService.checkPaymentStatus(
                        invoiceId: qpayInvoiceId,
                        baiguullagiinId: baiguullagiinId,
                        tukhainBaaziinKholbolt: barilgiinId,
                      );


                      final state = status['tuluv']?.toString();
                      final payStatus = status['status']?.toString().toUpperCase() ??
                                       status['pay_status']?.toString().toUpperCase();
                      final paidAmount = status['paid_amount'] ?? 
                                        (status['payments'] is List && (status['payments'] as List).isNotEmpty ? status['payments'][0]['amount'] : null);

                      if (state == 'Төлсөн' || payStatus == 'PAID' || (paidAmount != null && num.tryParse(paidAmount.toString()) != null && num.parse(paidAmount.toString()) > 0)) {

                        confirmed = true;
                      }
                    } catch (e) {

                    }
                  }

                  // 2. Fallback: Always refresh the billing list to see if the database is updated (mirrors web history logic)
                  try {

                    await _loadAllBillingsData();
                    final refreshedBilling = _allBillingsData.firstWhere(
                      (b) => b['billingId']?.toString() == firstBillingId,
                      orElse: () => {},
                    );
                    
                    if (refreshedBilling['tuluv'] == 'Төлсөн' || (refreshedBilling['uldegdel'] ?? 1) <= 0) {

                      confirmed = true;
                    }
                  } catch (e) {

                  }

                  if (confirmed) return true;
                }
                return null;
              },
            ),
          ),
        );

        if (paid == true && mounted) {
          // Show success for WALLET payments (receipts)
          if ((responseSource == 'WALLET_API' || responseSource == 'WALLET_QPAY') && walletPaymentId != null) {

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

            }
          }
          Navigator.of(context).pop(true);
        }
      } else {
        throw Exception(
          qpayResponse?['message'] ??
              qpayResponse?['aldaa'] ??
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

    final customerAddressStr =
        firstBill?['customerAddress']?.toString() ??
        widget.billing['customerAddress']?.toString() ??
        widget.billing['bairniiNer']?.toString() ??
        '';

    final customerAddress = widget.expandAddressAbbreviations(
      customerAddressStr,
    );

    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: buildStandardAppBar(
        context,
        title: 'Төлбөрийн дэлгэрэнгүй',
        onBackPressed: () => Navigator.of(context).pop(),
        actions: [
          IconButton(
            onPressed: () {
              final billingId = widget.billing['billingId']?.toString() ?? '';
              final billingName =
                  widget.billing['billingName']?.toString() ??
                  'Хэрэглээний төлбөр';

              if (billingId.isNotEmpty) {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => PaymentHistoryPage(
                      billingId: billingId,
                      billingName: billingName,
                      source: widget.billing['source']?.toString(),
                      customerName:
                          widget.billing['customerName']?.toString() ??
                          widget.billing['ner']?.toString() ??
                          '',
                      customerAddress:
                          widget.billing['customerAddress']?.toString() ??
                          widget.billing['bairniiNer']?.toString() ??
                          '',
                    ),
                  ),
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
          ? Center(
              child: Text(
                'Төлбөрийн мэдээлэл байхгүй байна',
                style: TextStyle(
                  color: context.textSecondaryColor.withOpacity(0.5),
                  fontSize: 14.sp,
                ),
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
                      SliverToBoxAdapter(
                        child: Padding(
                          padding: EdgeInsets.symmetric(horizontal: 20.w),
                          child: _buildPaymentLimitReminder(context),
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
                                        _selectedBillIds.clear();
                                        int count = 0;
                                        for (var bill in _allBills) {
                                          if (count >= 5) break;
                                          final id = bill['billId']?.toString();
                                          if (id != null) {
                                            _selectedBillIds.add(id);
                                            count++;
                                          }
                                        }
                                        if (_allBills.length > 5) {
                                          showGlassSnackBar(
                                            context,
                                            message:
                                                'Эхний 5 нэхэмжлэхийг сонголоо',
                                          );
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
                            final billPeriod = formatBillPeriod(
                                bill['billPeriod']?.toString() ?? '');
                            final billtype = bill['billtype']?.toString() ?? '';
                            final billerName =
                                bill['billerName']?.toString() ??
                                bill['parentBillerName']?.toString() ??
                                '';

                            return Padding(
                              padding: EdgeInsets.only(bottom: 12.h),
                              child: GestureDetector(
                                onTap: () {
                                  if (id == null) return;
                                  
                                  // Prevent selecting already paid or pending bills
                                  if (_billStatuses[id] == 'PAID' || _billStatuses[id] == 'PENDING') {
                                    showGlassSnackBar(
                                      context,
                                      message: _billStatuses[id] == 'PAID' 
                                        ? 'Энэ нэхэмжлэх аль хэдийн төлөгдсөн байна.' 
                                        : 'Энэ нэхэмжлэх төлөгдөж (хүлээгдэж) байна.',
                                      icon: Icons.info_outline,
                                      iconColor: _billStatusColors[id] ?? Colors.orange,
                                    );
                                    return;
                                  }

                                  setState(() {
                                    if (isSelected) {
                                      _selectedBillIds.remove(id);
                                    } else {
                                      if (_selectedBillIds.length < 5) {
                                        _selectedBillIds.add(id);
                                      } else {
                                        showGlassSnackBar(
                                          context,
                                          message:
                                              'Нэг удаад хамгийн ихдээ 5 нэхэмжлэх сонгох боломжтой',
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
                                      if (_billStatuses[id] == 'PAID')
                                        Container(
                                          width: 22.w,
                                          height: 22.w,
                                          decoration: BoxDecoration(
                                            color: Colors.green.withOpacity(0.1),
                                            shape: BoxShape.circle,
                                          ),
                                          child: Icon(
                                            Icons.check_circle,
                                            size: 16.sp,
                                            color: Colors.green,
                                          ),
                                        )
                                      else if (_billStatuses[id] == 'PENDING')
                                        Container(
                                          width: 22.w,
                                          height: 22.w,
                                          decoration: BoxDecoration(
                                            color: Colors.orange.withOpacity(0.1),
                                            shape: BoxShape.circle,
                                          ),
                                          child: Icon(
                                            Icons.hourglass_empty_rounded,
                                            size: 16.sp,
                                            color: Colors.orange,
                                          ),
                                        )
                                      else
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
                                              billtype,
                                              style: TextStyle(
                                                color: textPrimary.withOpacity(
                                                  isSelected ? 0.9 : 0.7,
                                                ),
                                                fontSize: 13.sp,
                                              ),
                                            ),
                                            SizedBox(height: 2.h),
                                            Text(
                                              'Төлбөрийн сар: $billPeriod',
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
            child: ElevatedButton(
              onPressed: _isProcessingPayment ||
                      _selectedBillIds.isEmpty ||
                      _totalSelectedAmount <= 0
                  ? null
                  : _processPayment,
              style: ElevatedButton.styleFrom(
                backgroundColor: primaryColor,
                foregroundColor: Colors.white,
                disabledBackgroundColor: primaryColor.withOpacity(0.3),
                padding: EdgeInsets.symmetric(vertical: 16.h),
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
        ],
      ),
    );
  }

  Widget _buildPaymentLimitReminder(BuildContext context) {
    final isDark = context.isDarkMode;
    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
      decoration: BoxDecoration(
        color: isDark
            ? Colors.white.withOpacity(0.04)
            : AppColors.deepGreen.withOpacity(0.05),
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(
          color: isDark
              ? Colors.white.withOpacity(0.06)
              : AppColors.deepGreen.withOpacity(0.12),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.all(6.w),
            decoration: BoxDecoration(
              color: isDark
                  ? AppColors.deepGreen.withOpacity(0.1)
                  : AppColors.deepGreen.withOpacity(0.15),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.info_outline_rounded,
              color: isDark ? AppColors.deepGreenAccent : AppColors.deepGreen,
              size: 20.sp,
            ),
          ),
          SizedBox(width: 12.w),
          Expanded(
            child: Text(
              'Нийт 5 хүртэл төлбөрийг нэг удаагийн төлөлтөөр төлөх боломжтой.',
              style: TextStyle(
                color: isDark ? Colors.white.withOpacity(0.8) : Colors.black87,
                fontSize: 12.5.sp,
                fontWeight: FontWeight.w500,
                letterSpacing: -0.2,
                height: 1.4,
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
