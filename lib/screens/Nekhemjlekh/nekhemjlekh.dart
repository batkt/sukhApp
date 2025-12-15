import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:ui';
import 'dart:convert';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:sukh_app/widgets/optimized_glass.dart';
import 'package:sukh_app/services/api_service.dart';
import 'package:sukh_app/services/storage_service.dart';
import 'package:sukh_app/services/notification_service.dart';
import 'package:sukh_app/widgets/glass_snackbar.dart';
import 'package:sukh_app/models/geree_model.dart';
import 'package:sukh_app/models/ajiltan_model.dart';
import 'package:sukh_app/constants/constants.dart';
import 'package:sukh_app/components/Nekhemjlekh/nekhemjlekh_models.dart';
import 'package:sukh_app/components/Nekhemjlekh/nekhemjlekh_header.dart';
import 'package:sukh_app/components/Nekhemjlekh/filter_tabs.dart';
import 'package:sukh_app/components/Nekhemjlekh/payment_section.dart';
import 'package:sukh_app/components/Nekhemjlekh/invoice_card.dart';
import 'package:sukh_app/components/Nekhemjlekh/contract_selection_modal.dart';
import 'package:sukh_app/components/Nekhemjlekh/bank_selection_modal.dart';
import 'package:sukh_app/components/Nekhemjlekh/payment_modal.dart';
import 'package:sukh_app/components/Nekhemjlekh/vat_receipt_modal.dart';

class AppBackground extends StatelessWidget {
  final Widget child;
  const AppBackground({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(child: child);
  }
}

class NekhemjlekhPage extends StatefulWidget {
  const NekhemjlekhPage({super.key});

  @override
  State<NekhemjlekhPage> createState() => _NekhemjlekhPageState();
}

class _NekhemjlekhPageState extends State<NekhemjlekhPage> {
  List<NekhemjlekhItem> invoices = [];
  bool isLoading = true;
  String? errorMessage;
  List<QPayBank> qpayBanks = [];
  bool isLoadingQPay = false;
  List<Map<String, dynamic>> availableContracts = [];
  String? selectedGereeniiDugaar;
  String? selectedContractDisplay;
  String selectedFilter = 'All'; // All, Overdue, Paid, Due this month, Pending
  List<String> selectedInvoiceIds = [];
  String? qpayInvoiceId;
  String? qpayQrImage;
  String contactPhone = '';

  @override
  void initState() {
    super.initState();
    _loadNekhemjlekh();
  }

  Future<void> _createQPayInvoice() async {
    setState(() {
      isLoadingQPay = true;
    });

    try {
      final ajiltanResponse = await ApiService.fetchAjiltan();
      if (ajiltanResponse['jagsaalt'] != null &&
          ajiltanResponse['jagsaalt'] is List &&
          (ajiltanResponse['jagsaalt'] as List).isNotEmpty) {
        final firstAjiltan = ajiltanResponse['jagsaalt'][0];
        contactPhone = firstAjiltan['utas'] ?? '';
      }
    } catch (e) {
      print('Error fetching ajiltan contact: $e');
    }

    try {
      final baiguullagiinId = await StorageService.getBaiguullagiinId();
      final barilgiinId = await StorageService.getBarilgiinId();

      if (baiguullagiinId == null || barilgiinId == null) {
        throw Exception('Хэрэглэгчийн мэдээлэл олдсонгүй');
      }

      double totalAmount = 0;
      String? turul;

      selectedInvoiceIds = [];

      for (var invoice in invoices) {
        if (invoice.isSelected) {
          totalAmount += invoice.niitTulbur;
          selectedInvoiceIds.add(invoice.id);

          turul ??= invoice.gereeniiDugaar;
        }
      }

      if (selectedInvoiceIds.isEmpty) {
        throw Exception('Нэхэмжлэх сонгоогүй байна');
      }

      if (turul == null || turul.isEmpty) {
        throw Exception('Гэрээний дугаар олдсонгүй');
      }

      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final orderNumber = 'TEST-$timestamp';

      final response = await ApiService.qpayGargaya(
        baiguullagiinId: baiguullagiinId,
        barilgiinId: barilgiinId,
        dun: totalAmount,
        turul: turul,
        zakhialgiinDugaar: orderNumber,

        nekhemjlekhiinTuukh: selectedInvoiceIds,
      );

      qpayInvoiceId = response['invoice_id']?.toString();

      qpayQrImage = response['qr_image']?.toString();

      if (response['urls'] != null && response['urls'] is List) {
        setState(() {
          qpayBanks = (response['urls'] as List)
              .map((bank) => QPayBank.fromJson(bank))
              .toList();
          isLoadingQPay = false;
        });
      } else {
        throw Exception(
          contactPhone.isNotEmpty
              ? 'Банкны мэдээлэл олдсонгүй та СӨХ ийн $contactPhone дугаар луу холбогдоно уу!'
              : 'Банкны мэдээлэл олдсонгүй',
        );
      }
    } catch (e) {
      setState(() {
        isLoadingQPay = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Алдаа гарлаа: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _loadNekhemjlekh() async {
    try {
      setState(() {
        isLoading = true;
        errorMessage = null;
      });

      final orshinSuugchId = await StorageService.getUserId();

      if (orshinSuugchId == null) {
        throw Exception('Хэрэглэгчийн мэдээлэл олдсонгүй');
      }

      final gereeResponse = await ApiService.fetchGeree(orshinSuugchId);

      if (gereeResponse['jagsaalt'] != null &&
          gereeResponse['jagsaalt'] is List &&
          (gereeResponse['jagsaalt'] as List).isNotEmpty) {
        availableContracts = List<Map<String, dynamic>>.from(
          gereeResponse['jagsaalt'],
        );

        final gereeToUse = selectedGereeniiDugaar != null
            ? availableContracts.firstWhere(
                (c) => c['gereeniiDugaar'] == selectedGereeniiDugaar,
                orElse: () => availableContracts[0],
              )
            : availableContracts[0];

        final gereeniiDugaar = gereeToUse['gereeniiDugaar'] as String?;

        if (gereeniiDugaar == null || gereeniiDugaar.isEmpty) {
          throw Exception('Гэрээний дугаар олдсонгүй');
        }

        selectedGereeniiDugaar = gereeniiDugaar;
        selectedContractDisplay = '${gereeToUse['bairNer'] ?? gereeniiDugaar}';

        final response = await ApiService.fetchNekhemjlekhiinTuukh(
          gereeniiDugaar: gereeniiDugaar,
          khuudasniiDugaar: 1,
          khuudasniiKhemjee: 10,
        );

        if (response['jagsaalt'] != null && response['jagsaalt'] is List) {
          final previouslySelectedIds = invoices
              .where((inv) => inv.isSelected)
              .map((inv) => inv.id)
              .toSet();

          setState(() {
            invoices = (response['jagsaalt'] as List)
                .map((item) => NekhemjlekhItem.fromJson(item))
                .toList();

            for (var invoice in invoices) {
              if (previouslySelectedIds.contains(invoice.id)) {
                invoice.isSelected = true;
              }
            }

            isLoading = false;
          });
        } else {
          setState(() {
            isLoading = false;
            errorMessage = 'Мэдээлэл олдсонгүй';
          });
        }
      } else {
        setState(() {
          isLoading = false;
          errorMessage = 'Гэрээний мэдээлэл олдсонгүй';
        });
      }
    } catch (e) {
      print('Error in _loadNekhemjlekh: $e');
      setState(() {
        isLoading = false;
        errorMessage = 'Алдаа гарлаа: $e';
      });
    }
  }

  void _showContractSelectionModal() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => ContractSelectionModal(
        availableContracts: availableContracts,
        selectedGereeniiDugaar: selectedGereeniiDugaar,
        onContractSelected: (gereeniiDugaar) {
          setState(() {
            selectedGereeniiDugaar = gereeniiDugaar;
          });
          _loadNekhemjlekh();
        },
      ),
    );
  }

  bool get allSelected {
    final unpaidInvoices = invoices
        .where((invoice) => invoice.tuluv == 'Төлөөгүй')
        .toList();
    return unpaidInvoices.isNotEmpty &&
        unpaidInvoices.every((invoice) => invoice.isSelected);
  }

  int get selectedCount =>
      invoices.where((invoice) => invoice.isSelected).length;

  String get totalSelectedAmount {
    double total = 0;
    for (var invoice in invoices) {
      if (invoice.isSelected) {
        total += invoice.niitTulbur;
      }
    }
    return '${total.toStringAsFixed(2).replaceAllMapped(RegExp(r'(\d)(?=(\d{3})+(?!\d))'), (match) => '${match[1]},')}₮';
  }

  void toggleSelectAll() {
    setState(() {
      bool newValue = !allSelected;
      for (var invoice in invoices) {
        // Only select/deselect invoices with status "Төлөөгүй" (Unpaid)
        if (invoice.tuluv == 'Төлөөгүй') {
          invoice.isSelected = newValue;
        }
      }
    });
  }

  List<NekhemjlekhItem> _getFilteredInvoices() {
    List<NekhemjlekhItem> filtered = invoices;

    // Apply filter
    if (selectedFilter == 'Paid') {
      // Show only paid invoices
      filtered = filtered
          .where((invoice) => invoice.tuluv == 'Төлсөн')
          .toList();
    } else {
      // 'All' shows all unpaid invoices
      filtered = filtered
          .where((invoice) => invoice.tuluv != 'Төлсөн')
          .toList();
    }

    return filtered;
  }

  // _getStatusColor and _getStatusLabel moved to components/Nekhemjlekh/invoice_card.dart

  int _getFilterCount(String filterKey) {
    switch (filterKey) {
      case 'All':
        return invoices.where((invoice) => invoice.tuluv != 'Төлсөн').length;
      case 'Paid':
        return invoices.where((invoice) => invoice.tuluv == 'Төлсөн').length;
      default:
        return 0;
    }
  }

  // _buildFilterTab moved to components/Nekhemjlekh/filter_tabs.dart

  void _showBankInfoModal() async {
    print('=== _showBankInfoModal called ===');
    await _createQPayInvoice();

    if (!mounted) return;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => BankSelectionModal(
        qpayBanks: qpayBanks,
        isLoadingQPay: isLoadingQPay,
        contactPhone: contactPhone,
        onBankTap: (bank) {
          // Check if it's qPay wallet - show QR code
          if (bank.description.contains('qPay хэтэвч') ||
              bank.name.toLowerCase().contains('qpay wallet')) {
            _showQPayQRCodeModal();
          } else {
            _openBankAppAndShowCheckModal(bank);
          }
        },
        onQPayWalletTap: _showQPayQRCodeModal,
      ),
    );
  }

  Future<void> _showVATReceiptModal(String invoiceId) async {
    try {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(
          child: CircularProgressIndicator(color: AppColors.secondaryAccent),
        ),
      );

      // Fetch VAT receipts
      final response = await ApiService.fetchEbarimtJagsaaltAvya(
        nekhemjlekhiinId: invoiceId,
      );

      if (!mounted) return;

      // Close loading dialog
      Navigator.of(context).pop();

      final receipts = <VATReceipt>[];
      if (response['jagsaalt'] != null && response['jagsaalt'] is List) {
        for (var item in response['jagsaalt'] as List) {
          // Match nekhemjlekhiinId with invoice _id
          if (item['nekhemjlekhiinId'] == invoiceId) {
            receipts.add(VATReceipt.fromJson(item));
          }
        }
      }

      if (receipts.isEmpty) {
        // Find the invoice to get gereeniiDugaar
        final invoice = invoices.firstWhere(
          (inv) => inv.id == invoiceId,
          orElse: () => invoices.first,
        );

        // Try to get suhUtas from contract first
        String suhUtas = '';
        if (availableContracts.isNotEmpty &&
            invoice.gereeniiDugaar.isNotEmpty) {
          try {
            final contractMap = availableContracts.firstWhere(
              (c) => c['gereeniiDugaar']?.toString() == invoice.gereeniiDugaar,
              orElse: () => availableContracts.first,
            );

            // Convert Map to Geree model object (like in geree.dart)
            final geree = Geree.fromJson(contractMap);

            if (geree.suhUtas.isNotEmpty) {
              suhUtas = geree.suhUtas.first;
            }
          } catch (e) {
            // Silent fail
          }
        }

        if (suhUtas.isEmpty) {
          try {
            final ajiltanResponse = await ApiService.fetchAjiltan();
            if (ajiltanResponse['jagsaalt'] != null &&
                ajiltanResponse['jagsaalt'] is List &&
                (ajiltanResponse['jagsaalt'] as List).isNotEmpty) {
              final ajiltanData = AjiltanResponse.fromJson(ajiltanResponse);
              if (ajiltanData.jagsaalt.isNotEmpty) {
                // Get first phone number from ajiltan
                final firstAjiltan = ajiltanData.jagsaalt.firstWhere(
                  (ajiltan) => ajiltan.utas.isNotEmpty,
                  orElse: () => ajiltanData.jagsaalt.first,
                );
                if (firstAjiltan.utas.isNotEmpty) {
                  suhUtas = firstAjiltan.utas;
                }
              }
            }
          } catch (e) {
            // Silent fail
          }
        }

        if (!mounted) return;

        showDialog(
          context: context,
          barrierColor: Colors.black.withOpacity(0.7),
          builder: (BuildContext context) {
            return Dialog(
              backgroundColor: Colors.transparent,
              elevation: 0,
              insetPadding: EdgeInsets.symmetric(horizontal: 20.w),
              child: TweenAnimationBuilder<double>(
                tween: Tween(begin: 0.0, end: 1.0),
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeOutCubic,
                builder: (context, value, child) {
                  return Transform.scale(
                    scale: 0.8 + (0.2 * value),
                    child: Opacity(opacity: value, child: child),
                  );
                },
                child: OptimizedGlass(
                  borderRadius: BorderRadius.circular(24.w),
                  opacity: 0.10,
                  child: Container(
                      decoration: BoxDecoration(
                        color: AppColors.darkBackground.withOpacity(0.95),
                        borderRadius: BorderRadius.circular(24.w),
                        border: Border.all(
                          color: AppColors.secondaryAccent.withOpacity(0.3),
                          width: 1.5,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.secondaryAccent.withOpacity(0.2),
                            blurRadius: 20,
                            spreadRadius: 2,
                          ),
                          BoxShadow(
                            color: Colors.black.withOpacity(0.5),
                            blurRadius: 30,
                            offset: const Offset(0, 10),
                          ),
                        ],
                      ),
                      padding: EdgeInsets.all(24.w),
                      child: Container(
                        padding: EdgeInsets.all(20.w),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.05),
                          borderRadius: BorderRadius.circular(12.w),
                          border: Border.all(
                            color: AppColors.secondaryAccent.withOpacity(0.2),
                            width: 1,
                          ),
                        ),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            // Close button
                            Row(
                              mainAxisAlignment: MainAxisAlignment.end,
                              children: [
                                IconButton(
                                  icon: const Icon(
                                    Icons.close_rounded,
                                    color: Colors.white70,
                                  ),
                                  onPressed: () => Navigator.of(context).pop(),
                                  padding: EdgeInsets.zero,
                                  constraints: const BoxConstraints(),
                                  iconSize: 20.sp,
                                ),
                              ],
                            ),
                            SizedBox(height: 8.h),
                            // Message
                            Text(
                              "И-Баримтын тохиргоо хийгдээгүй байна.",
                              style: TextStyle(
                                fontSize: 14.sp,
                                fontWeight: FontWeight.w500,
                                color: Colors.white.withOpacity(0.8),
                                height: 1.4,
                              ),
                              textAlign: TextAlign.center,
                            ),
                            SizedBox(height: 16.h),
                            // Phone number label
                            Text(
                              "СӨХ-тэй холбогдох утасны дугаар:",
                              style: TextStyle(
                                fontSize: 12.sp,
                                fontWeight: FontWeight.w500,
                                color: Colors.white.withOpacity(0.6),
                              ),
                              textAlign: TextAlign.center,
                            ),
                            SizedBox(height: 8.h),
                            if (suhUtas.isNotEmpty) ...[
                              // Phone number
                              GestureDetector(
                                onLongPress: () {
                                  Clipboard.setData(
                                    ClipboardData(text: suhUtas),
                                  );
                                  HapticFeedback.lightImpact();
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text(
                                        'Дугаар хуулагдлаа: $suhUtas',
                                        style: TextStyle(color: Colors.white),
                                      ),
                                      backgroundColor: AppColors.secondaryAccent
                                          .withOpacity(0.9),
                                      duration: const Duration(seconds: 2),
                                      behavior: SnackBarBehavior.floating,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                    ),
                                  );
                                },
                                child: Text(
                                  suhUtas,
                                  style: TextStyle(
                                    fontSize: 18.sp,
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.secondaryAccent,
                                    letterSpacing: 1.0,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                              ),
                              SizedBox(height: 16.h),
                              // Call button
                              SizedBox(
                                width: double.infinity,
                                child: ElevatedButton.icon(
                                  onPressed: () async {
                                    HapticFeedback.mediumImpact();
                                    final uri = Uri.parse('tel:$suhUtas');
                                    if (await canLaunchUrl(uri)) {
                                      await launchUrl(uri);
                                    } else {
                                      ScaffoldMessenger.of(
                                        context,
                                      ).showSnackBar(
                                        SnackBar(
                                          content: Text(
                                            'Утас дуудах боломжгүй',
                                            style: TextStyle(
                                              color: Colors.white,
                                            ),
                                          ),
                                          backgroundColor: Colors.red,
                                          behavior: SnackBarBehavior.floating,
                                        ),
                                      );
                                    }
                                  },
                                  icon: Icon(Icons.phone_rounded, size: 18.sp),
                                  label: Text(
                                    'Залгах',
                                    style: TextStyle(
                                      fontSize: 14.sp,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: AppColors.secondaryAccent,
                                    foregroundColor: AppColors.darkBackground,
                                    padding: EdgeInsets.symmetric(
                                      vertical: 12.h,
                                    ),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(10.w),
                                    ),
                                    elevation: 0,
                                  ),
                                ),
                              ),
                            ] else ...[
                              // Empty state
                              Text(
                                '.............',
                                style: TextStyle(
                                  fontSize: 16.sp,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white.withOpacity(0.4),
                                  letterSpacing: 1.0,
                                ),
                                textAlign: TextAlign.center,
                              ),
                              SizedBox(height: 6.h),
                              Text(
                                'Утасны дугаар олдсонгүй',
                                style: TextStyle(
                                  fontSize: 11.sp,
                                  color: Colors.white.withOpacity(0.5),
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),
                ),
              ),
            );
          },
        );
        return;
      }

      showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (context) => VATReceiptModal(receipt: receipts[0]),
      );
    } catch (e) {
      if (!mounted) return;

      // Close loading dialog if still open
      Navigator.of(context).pop();

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Алдаа гарлаа: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  // _buildVATReceiptBottomSheet, _buildReceiptInfoRow, _buildQPayBankItem moved to components

  Future<void> _openBankAppAndShowCheckModal(QPayBank bank) async {
    try {
      final Uri bankUri = Uri.parse(bank.link);

      print('Attempting to launch bank app with URL: ${bank.link}');

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
        // Successfully opened the app
        print('Bank app launched successfully');

        // Wait a moment for the app to open, then show the check modal
        await Future.delayed(const Duration(seconds: 1));

        if (mounted) {
          _showPaymentCheckModal(bank);
        }
      } else {
        // Bank app not installed
        if (mounted) {
          _showBankAppNotInstalledDialog(bank);
        }
      }
    } catch (e) {
      print('Error in _openBankAppAndShowCheckModal: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Алдаа гарлаа: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _showPaymentCheckModal(QPayBank bank) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (BuildContext context) {
        return Container(
          height: MediaQuery.of(context).size.height * 0.5,
          decoration: BoxDecoration(
            color: AppColors.darkBackground,
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(30.w),
              topRight: Radius.circular(30.w),
            ),
          ),
          child: OptimizedGlass(
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(30.w),
              topRight: Radius.circular(30.w),
            ),
            opacity: 0.08,
            child: Column(
              children: [
                  // Handle bar
                  Container(
                    margin: EdgeInsets.only(top: 12.h),
                    width: 40.w,
                    height: 4.h,
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.5),
                      borderRadius: BorderRadius.circular(2.w),
                    ),
                  ),
                  // Header
                  Padding(
                    padding: EdgeInsets.all(20.w),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            'Төлбөр баталгаажуулах',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 24.sp,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        IconButton(
                          icon: Icon(
                            Icons.close,
                            color: Colors.white,
                            size: 24.sp,
                          ),
                          onPressed: () => Navigator.pop(context),
                        ),
                      ],
                    ),
                  ),
                  // Bank logo and info
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: 20.w),
                    child: Container(
                      padding: EdgeInsets.all(20.w),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(20.w),
                        border: Border.all(
                          color: Colors.white.withOpacity(0.2),
                          width: 1,
                        ),
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 60.w,
                            height: 60.w,
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(8.w),
                            ),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(8.w),
                              child: Image.network(
                                bank.logo,
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) {
                                  return Icon(
                                    Icons.account_balance,
                                    color: Colors.grey,
                                    size: 30.sp,
                                  );
                                },
                              ),
                            ),
                          ),
                          SizedBox(width: 16.w),
                          Expanded(
                            child: Text(
                              bank.description,
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 16.sp,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const Spacer(),
                  // Check payment button
                  Padding(
                    padding: EdgeInsets.all(20.w),
                    child: SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () => _checkPaymentStatus(bank),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.secondaryAccent,
                          foregroundColor: AppColors.darkBackground,
                          padding: EdgeInsets.symmetric(vertical: 16.h),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12.w),
                          ),
                        ),
                        child: Text(
                          'Төлбөр шалгах',
                          style: TextStyle(
                            fontSize: 16.sp,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
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

  Future<void> _checkPaymentStatus(QPayBank bank) async {
    // Close the payment check modal first
    Navigator.pop(context);

    // Show loading indicator
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(
        child: CircularProgressIndicator(color: AppColors.secondaryAccent),
      ),
    );

    try {
      // Reload invoice data to get latest status
      await _loadNekhemjlekh();

      // Close loading dialog
      if (mounted) Navigator.of(context).pop();

      // Check if the selected invoice(s) are paid
      final selectedInvoices = invoices
          .where((inv) => selectedInvoiceIds.contains(inv.id))
          .toList();

      if (selectedInvoices.isEmpty) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Сонгосон нэхэмжлэл олдсонгүй'),
              backgroundColor: Colors.red,
            ),
          );
          _showBankInfoModal();
        }
        return;
      }

      // Check if all selected invoices are paid
      final allPaid = selectedInvoices.every((inv) => inv.tuluv == 'Төлсөн');

      if (allPaid) {
        // Payment successful - show success snackbar
        if (mounted) {
          showGlassSnackBar(
            context,
            message: 'Төлбөр амжилттай төлөгдлөө',
            icon: Icons.check_circle_outline,
            iconColor: Colors.green,
            textColor: Colors.white,
            opacity: 0.3,
            blur: 15,
          );

          // Wait a bit then reload invoice data to refresh the list
          await Future.delayed(const Duration(seconds: 2));

          // Reload invoice data to get the latest status from server
          await _loadNekhemjlekh();

          // Show VAT receipts for all paid invoices
          for (var invoice in selectedInvoices) {
            await _showVATReceiptModal(invoice.id);
          }

          // Navigate back to home page to refresh the data
          context.go('/nuur');
        }
      } else {
        // Payment not completed - show error snackbar and return to bank list
        if (mounted) {
          showGlassSnackBar(
            context,
            message: 'Төлбөр төлөгдөөгүй байна',
            icon: Icons.error_outline,
            iconColor: Colors.red,
            textColor: Colors.white,
            opacity: 0.3,
            blur: 15,
          );

          // Wait a bit then show bank list again
          await Future.delayed(const Duration(seconds: 2));
          _showBankInfoModal();
        }
      }
    } catch (e) {
      print('Error checking payment status: $e');

      // Close loading dialog if still open
      if (mounted) Navigator.of(context).pop();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Алдаа гарлаа: $e'),
            backgroundColor: Colors.red,
          ),
        );

        // Show bank list again
        _showBankInfoModal();
      }
    }
  }

  Future<void> _startPaymentStatusCheck() async {
    if (qpayInvoiceId == null) {
      print('No QPay invoice ID to check');
      return;
    }

    // Poll payment status every 2 seconds for up to 60 seconds
    int attempts = 0;
    const maxAttempts = 30;
    const checkInterval = Duration(seconds: 2);

    while (attempts < maxAttempts && mounted) {
      try {
        await Future.delayed(checkInterval);

        final statusResponse = await ApiService.checkPaymentStatus(
          invoiceId: qpayInvoiceId!,
        );

        print('Payment status check: $statusResponse');

        // Check if payment is successful
        if (statusResponse['paid_amount'] != null &&
            statusResponse['paid_amount'] > 0) {
          // Payment successful!
          if (mounted) {
            await _handlePaymentSuccess();
          }
          break;
        }

        attempts++;
      } catch (e) {
        print('Error checking payment status: $e');
        attempts++;
      }
    }
  }

  Future<void> _handlePaymentSuccess() async {
    try {
      // Update invoice status to "Төлсөн" on the server
      if (selectedInvoiceIds.isNotEmpty) {
        await ApiService.updateNekhemjlekhiinTuluv(
          nekhemjlekhiinIds: selectedInvoiceIds,
          tuluv: 'Төлсөн',
        );
      }

      // Show success notification
      await NotificationService.showNotification(
        id: DateTime.now().millisecondsSinceEpoch ~/ 1000,
        title: 'Төлбөр амжилттай төлөгдлөө',
        body: 'Дарж И-баримт аа харна уу!',
      );

      // Show success message
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Төлбөр амжилттай төлөгдлөө'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 3),
          ),
        );
      }

      // Reload invoices to update the list
      await _loadNekhemjlekh();

      // Show VAT receipts for all paid invoices
      if (selectedInvoiceIds.isNotEmpty) {
        await Future.delayed(const Duration(milliseconds: 500));
        if (mounted) {
          _showMultipleVATReceipts(selectedInvoiceIds);
        }
      }
    } catch (e) {
      print('Error updating payment status: $e');
      // Still reload to show updated data from server
      await _loadNekhemjlekh();
    }
  }

  Future<void> _showMultipleVATReceipts(List<String> invoiceIds) async {
    for (String invoiceId in invoiceIds) {
      try {
        final response = await ApiService.fetchEbarimtJagsaaltAvya(
          nekhemjlekhiinId: invoiceId,
        );

        final receipts = <VATReceipt>[];
        if (response['jagsaalt'] != null && response['jagsaalt'] is List) {
          for (var item in response['jagsaalt'] as List) {
            if (item['nekhemjlekhiinId'] == invoiceId) {
              receipts.add(VATReceipt.fromJson(item));
            }
          }
        }

        if (receipts.isNotEmpty && mounted) {
          showModalBottomSheet(
            context: context,
            isScrollControlled: true,
            backgroundColor: Colors.transparent,
            builder: (context) => VATReceiptModal(receipt: receipts[0]),
          );
        }
      } catch (e) {
        print('Error fetching VAT receipt for $invoiceId: $e');
      }
    }
  }

  void _showQPayQRCodeModal() {
    if (qpayQrImage == null || qpayQrImage!.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('QR код олдсонгүй'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          backgroundColor: Colors.transparent,
          child: Container(
            decoration: BoxDecoration(
              color: AppColors.darkBackground,
              borderRadius: BorderRadius.circular(20.w),
              border: Border.all(
                color: Colors.white.withOpacity(0.2),
                width: 1,
              ),
            ),
            padding: EdgeInsets.all(20.w),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'QPay хэтэвч QR код',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 20.sp,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 20.h),
                Container(
                  padding: EdgeInsets.all(16.w),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12.w),
                  ),
                  child: Image.memory(
                    base64Decode(qpayQrImage!),
                    width: 250.w,
                    height: 250.w,
                    fit: BoxFit.contain,
                  ),
                ),
                SizedBox(height: 20.h),
                Text(
                  'QPay апп-аараа QR кодыг уншуулна уу',
                  style: TextStyle(color: Colors.white70, fontSize: 14.sp),
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: 20.h),
                ElevatedButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                    _startPaymentStatusCheck();
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.secondaryAccent,
                    foregroundColor: AppColors.darkBackground,
                    padding: EdgeInsets.symmetric(
                      vertical: 12.h,
                      horizontal: 40.w,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(100.r),
                    ),
                  ),
                  child: Text(
                    'Төлбөр шалгах',
                    style: TextStyle(
                      fontSize: 16.sp,
                      fontWeight: FontWeight.bold,
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

  void _showBankAppNotInstalledDialog(QPayBank bank) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: AppColors.darkBackground,
          title: const Text(
            'Банкны апп олдсонгүй',
            style: TextStyle(color: Colors.white),
          ),
          content: Text(
            '${bank.description} апп суулгагдаагүй эсвэл нээгдэхгүй байна. Та апп татах эсвэл QR кодыг хуулж авах уу?',
            style: const TextStyle(color: Colors.white70),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text(
                'Болих',
                style: TextStyle(color: Colors.white70),
              ),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                _copyQRCodeToClipboard(bank.link);
              },
              child: const Text(
                'QR код хуулах',
                style: TextStyle(color: AppColors.secondaryAccent),
              ),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                _openAppStore(bank);
              },
              child: const Text(
                'Апп татах',
                style: TextStyle(color: AppColors.secondaryAccent),
              ),
            ),
          ],
        );
      },
    );
  }

  void _copyQRCodeToClipboard(String qrData) {
    final qrMatch = RegExp(r'qPay_QRcode=([^&]+)').firstMatch(qrData);
    if (qrMatch != null) {
      final qrCode = Uri.decodeComponent(qrMatch.group(1) ?? '');
      Clipboard.setData(ClipboardData(text: qrCode));
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('QR код хуулагдлаа'),
          backgroundColor: Colors.green,
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('QR код олдсонгүй'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  String _getBankStoreUrl(QPayBank bank, bool isIOS) {
    final bankName = bank.name.toLowerCase();

    if (isIOS) {
      if (bankName.contains('qpay')) {
        return 'https://apps.apple.com/mn/app/qpay/id1441608142';
      } else if (bankName.contains('khan')) {
        return 'https://apps.apple.com/mn/app/khan-bank/id1178998998';
      } else if (bankName.contains('state')) {
        return 'https://apps.apple.com/mn/app/state-bank-mobile-bank/id1439968858';
      } else if (bankName.contains('xac')) {
        return 'https://apps.apple.com/mn/app/xacbank/id1435546747';
      } else if (bankName.contains('tdb') || bankName.contains('trade')) {
        return 'https://apps.apple.com/mn/app/tdb-online/id1341682855';
      } else if (bankName.contains('social') || bankName.contains('golomt')) {
        return 'https://apps.apple.com/mn/app/social-pay/id907732452';
      } else if (bankName.contains('most')) {
        return 'https://apps.apple.com/mn/app/most-money/id1476831658';
      } else if (bankName.contains('national')) {
        return 'https://apps.apple.com/mn/app/nib/id1477940138';
      } else if (bankName.contains('chinggis')) {
        return 'https://apps.apple.com/mn/app/ckb/id1477634968';
      } else if (bankName.contains('capitron')) {
        return 'https://apps.apple.com/mn/app/capitron-bank/id1498290326';
      } else if (bankName.contains('bogd')) {
        return 'https://apps.apple.com/mn/app/bogd-bank/id1533486058';
      } else if (bankName.contains('trans')) {
        return 'https://apps.apple.com/mn/app/tdb/id1522843170';
      } else if (bankName.contains('m bank')) {
        return 'https://apps.apple.com/mn/app/m-bank/id1538651684';
      } else if (bankName.contains('ard')) {
        return 'https://apps.apple.com/mn/app/ard-app/id1546653588';
      } else if (bankName.contains('toki')) {
        return 'https://apps.apple.com/mn/app/toki/id1568099905';
      } else if (bankName.contains('arig')) {
        return 'https://apps.apple.com/mn/app/arig-bank/id1569785167';
      } else if (bankName.contains('monpay')) {
        return 'https://apps.apple.com/mn/app/monpay/id1491424177';
      } else if (bankName.contains('hipay')) {
        return 'https://apps.apple.com/mn/app/hipay/id1451162498';
      } else if (bankName.contains('happy')) {
        return 'https://apps.apple.com/mn/app/happy-pay/id1590968412';
      }

      return 'https://apps.apple.com/mn/search?term=${Uri.encodeComponent(bank.description)}';
    } else {
      if (bankName.contains('qpay')) {
        return 'https://play.google.com/store/apps/details?id=mn.qpay.wallet';
      } else if (bankName.contains('khan')) {
        return 'https://play.google.com/store/apps/details?id=com.khanbank.khaan';
      } else if (bankName.contains('state')) {
        return 'https://play.google.com/store/apps/details?id=mn.statebank.mobile';
      } else if (bankName.contains('xac')) {
        return 'https://play.google.com/store/apps/details?id=mn.xacbank.mobile';
      } else if (bankName.contains('tdb') || bankName.contains('trade')) {
        return 'https://play.google.com/store/apps/details?id=mn.tdb.mobile';
      } else if (bankName.contains('social') || bankName.contains('golomt')) {
        return 'https://play.google.com/store/apps/details?id=com.golomtbank.mobilebank';
      } else if (bankName.contains('most')) {
        return 'https://play.google.com/store/apps/details?id=mn.most.wallet';
      } else if (bankName.contains('national')) {
        return 'https://play.google.com/store/apps/details?id=mn.nibmobilebank';
      } else if (bankName.contains('chinggis')) {
        return 'https://play.google.com/store/apps/details?id=mn.ckb.mobile';
      } else if (bankName.contains('capitron')) {
        return 'https://play.google.com/store/apps/details?id=mn.capitronbank.mobile';
      } else if (bankName.contains('bogd')) {
        return 'https://play.google.com/store/apps/details?id=mn.bogdbank.mobile';
      } else if (bankName.contains('trans')) {
        return 'https://play.google.com/store/apps/details?id=mn.transbank.mobile';
      } else if (bankName.contains('m bank')) {
        return 'https://play.google.com/store/apps/details?id=mn.mbank.mobile';
      } else if (bankName.contains('ard')) {
        return 'https://play.google.com/store/apps/details?id=mn.ard.app';
      } else if (bankName.contains('toki')) {
        return 'https://play.google.com/store/apps/details?id=com.tokipay';
      } else if (bankName.contains('arig')) {
        return 'https://play.google.com/store/apps/details?id=mn.arigbank.mobile';
      } else if (bankName.contains('monpay')) {
        return 'https://play.google.com/store/apps/details?id=mn.monpay.android';
      } else if (bankName.contains('hipay')) {
        return 'https://play.google.com/store/apps/details?id=mn.hipay';
      } else if (bankName.contains('happy')) {
        return 'https://play.google.com/store/apps/details?id=mn.tdbwallet';
      }

      return 'https://play.google.com/store/search?q=${Uri.encodeComponent(bank.description)}&c=apps';
    }
  }

  Future<void> _openAppStore(QPayBank bank) async {
    final isIOS = Theme.of(context).platform == TargetPlatform.iOS;
    final appStoreUrl = _getBankStoreUrl(bank, isIOS);

    try {
      final uri = Uri.parse(appStoreUrl);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Алдаа гарлаа: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _showPaymentModal() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => PaymentModal(
        totalSelectedAmount: totalSelectedAmount,
        selectedCount: selectedCount,
        onPaymentTap: () async {
          Navigator.pop(context);
          await Future.delayed(const Duration(milliseconds: 100));
          _showBankInfoModal();
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    final screenWidth = MediaQuery.of(context).size.width;
    // 720x1600 phone will have width ~360-400 and height ~700-850 (considering status bar)
    final isSmallScreen = screenHeight < 900 || screenWidth < 400;
    final isVerySmallScreen = screenHeight < 700 || screenWidth < 380;

    return Scaffold(
      body: AppBackground(
        child: SafeArea(
          child: Column(
            children: [
              // Header
              NekhemjlekhHeader(
                selectedContractDisplay: selectedContractDisplay,
                availableContractsCount: availableContracts.length,
                onContractSelect: availableContracts.length > 1
                    ? _showContractSelectionModal
                    : null,
              ),
              Expanded(
                child: isLoading
                    ? Center(
                        child: CircularProgressIndicator(
                          valueColor: AlwaysStoppedAnimation<Color>(
                            AppColors.secondaryAccent,
                          ),
                        ),
                      )
                    : errorMessage != null
                    ? Center(
                        child: Padding(
                          padding: EdgeInsets.all(20.w),
                          child: OptimizedGlass(
                            borderRadius: BorderRadius.circular(22.r),
                            opacity: 0.10,
                            child: Padding(
                              padding: EdgeInsets.all(24.w),
                              child: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(
                                        Icons.error_outline_rounded,
                                        color: Colors.red.withOpacity(0.8),
                                        size: 48.sp,
                                      ),
                                      SizedBox(height: 16.h),
                                      Text(
                                        errorMessage!,
                                        style: TextStyle(
                                          color: Colors.white.withOpacity(0.9),
                                          fontSize: 14.sp,
                                        ),
                                        textAlign: TextAlign.center,
                                      ),
                                      SizedBox(height: 24.h),
                                      OptimizedGlass(
                                        borderRadius:
                                            BorderRadius.circular(12.r),
                                        opacity: 0.10,
                                        child: Material(
                                          color: Colors.transparent,
                                          child: InkWell(
                                            onTap: _loadNekhemjlekh,
                                            borderRadius: BorderRadius.circular(
                                              12.r,
                                            ),
                                            child: Container(
                                              padding: EdgeInsets.symmetric(
                                                horizontal: 24.w,
                                                vertical: 12.h,
                                              ),
                                              child: Text(
                                                'Дахин оролдох',
                                                style: TextStyle(
                                                  fontSize: 14.sp,
                                                  color: Colors.white,
                                                  fontWeight: FontWeight.w600,
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
                      )
                    : Column(
                        children: [
                          // Filter Tabs
                          FilterTabs(
                            selectedFilter: selectedFilter,
                            onFilterChanged: (filterKey) {
                              setState(() {
                                selectedFilter = filterKey;
                              });
                            },
                            getFilterCount: _getFilterCount,
                          ),
                          // Sticky payment section at top (hidden in history mode)
                          if (selectedFilter != 'Paid')
                            PaymentSection(
                              selectedCount: selectedCount,
                              totalSelectedAmount: totalSelectedAmount,
                              onPaymentTap: selectedCount > 0
                                  ? _showPaymentModal
                                  : null,
                            ),
                          SizedBox(height: 8.h),
                          // Scrollable invoice list
                          Expanded(
                            child: () {
                              final filteredInvoices = _getFilteredInvoices();

                              if (filteredInvoices.isEmpty) {
                                return Center(
                                  child: Padding(
                                    padding: EdgeInsets.all(20.w),
                                    child: OptimizedGlass(
                                      borderRadius:
                                          BorderRadius.circular(22.r),
                                      opacity: 0.10,
                                      child: Padding(
                                        padding: EdgeInsets.all(24.w),
                                        child: Column(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Container(
                                              padding: EdgeInsets.all(24.w),
                                              decoration: BoxDecoration(
                                                color: Colors.white
                                                    .withOpacity(0.05),
                                                shape: BoxShape.circle,
                                              ),
                                              child: Icon(
                                                selectedFilter == 'Paid'
                                                    ? Icons.history_rounded
                                                    : Icons
                                                        .receipt_long_rounded,
                                                size: 48.sp,
                                                color: Colors.white
                                                    .withOpacity(0.5),
                                              ),
                                            ),
                                            SizedBox(height: 24.h),
                                            Text(
                                              selectedFilter == 'Paid'
                                                  ? 'Төлөгдсөн нэхэмжлэл байхгүй'
                                                  : 'Одоогоор нэхэмжлэл байхгүй',
                                              style: TextStyle(
                                                color: Colors.white
                                                    .withOpacity(0.9),
                                                fontSize: 18.sp,
                                                fontWeight: FontWeight.w600,
                                              ),
                                              textAlign: TextAlign.center,
                                            ),
                                            SizedBox(height: 8.h),
                                            Text(
                                              selectedFilter == 'Paid'
                                                  ? 'Төлөгдсөн нэхэмжлэлийн түүх энд харагдана'
                                                  : 'Шинэ нэхэмжлэл үүсэхэд энд харагдана',
                                              style: TextStyle(
                                                color: Colors.white
                                                    .withOpacity(0.6),
                                                fontSize: 14.sp,
                                              ),
                                              textAlign: TextAlign.center,
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ),
                                );
                              }

                              return SingleChildScrollView(
                                padding: EdgeInsets.symmetric(
                                  horizontal: isVerySmallScreen
                                      ? 12
                                      : (isSmallScreen ? 14 : 16),
                                ),
                                child: Column(
                                  children: [
                                    if (selectedFilter != 'Paid' &&
                                        filteredInvoices.isNotEmpty)
                                      Padding(
                                        padding: EdgeInsets.only(
                                          left: isVerySmallScreen
                                              ? 14
                                              : (isSmallScreen ? 16 : 18),
                                        ),
                                        child: OptimizedGlass(
                                          borderRadius:
                                              BorderRadius.circular(12.r),
                                          opacity: 0.08,
                                          child: Material(
                                            color: Colors.transparent,
                                            child: InkWell(
                                              onTap: toggleSelectAll,
                                              borderRadius:
                                                  BorderRadius.circular(12.r),
                                              child: Padding(
                                                    padding:
                                                        EdgeInsets.symmetric(
                                                          horizontal: 12.w,
                                                          vertical: 8.h,
                                                        ),
                                                    child: Row(
                                                      mainAxisSize:
                                                          MainAxisSize.min,
                                                      children: [
                                                        Container(
                                                          width:
                                                              isVerySmallScreen
                                                              ? 18
                                                              : (isSmallScreen
                                                                    ? 20
                                                                    : 22),
                                                          height:
                                                              isVerySmallScreen
                                                              ? 18
                                                              : (isSmallScreen
                                                                    ? 20
                                                                    : 22),
                                                          decoration: BoxDecoration(
                                                            gradient:
                                                                allSelected
                                                                ? LinearGradient(
                                                                    colors: [
                                                                      AppColors
                                                                          .secondaryAccent,
                                                                      AppColors
                                                                          .secondaryAccent
                                                                          .withOpacity(
                                                                            0.8,
                                                                          ),
                                                                    ],
                                                                  )
                                                                : null,
                                                            color: allSelected
                                                                ? null
                                                                : Colors
                                                                      .transparent,
                                                            border: Border.all(
                                                              color: allSelected
                                                                  ? AppColors
                                                                        .secondaryAccent
                                                                  : Colors.white
                                                                        .withOpacity(
                                                                          0.5,
                                                                        ),
                                                              width: 2,
                                                            ),
                                                            borderRadius:
                                                                BorderRadius.circular(
                                                                  6.r,
                                                                ),
                                                          ),
                                                          child: allSelected
                                                              ? Icon(
                                                                  Icons
                                                                      .check_rounded,
                                                                  color: Colors
                                                                      .white,
                                                                  size:
                                                                      isVerySmallScreen
                                                                      ? 12
                                                                      : (isSmallScreen
                                                                            ? 14
                                                                            : 16),
                                                                )
                                                              : null,
                                                        ),
                                                        SizedBox(
                                                          width:
                                                              isVerySmallScreen
                                                              ? 10
                                                              : (isSmallScreen
                                                                    ? 12
                                                                    : 14),
                                                        ),
                                                        Text(
                                                          'Бүгдийг сонгох',
                                                          style: TextStyle(
                                                            color: Colors.white,
                                                            fontSize:
                                                                isVerySmallScreen
                                                                ? 13
                                                                : (isSmallScreen
                                                                      ? 14
                                                                      : 16),
                                                            fontWeight:
                                                                FontWeight.w500,
                                                          ),
                                                        ),
                                                      ],
                                                    ),
                                              ),
                                            ),
                                          ),
                                        ),
                                      ),
                                    if (selectedFilter != 'Paid' &&
                                        filteredInvoices.isNotEmpty)
                                      SizedBox(
                                        height: isVerySmallScreen
                                            ? 10
                                            : (isSmallScreen ? 12 : 16),
                                      ),
                                    ...filteredInvoices.map(
                                      (invoice) => Padding(
                                        padding: EdgeInsets.only(
                                          bottom: isVerySmallScreen
                                              ? 10
                                              : (isSmallScreen ? 12 : 16),
                                        ),
                                        child: InvoiceCard(
                                          invoice: invoice,
                                          isHistory: selectedFilter == 'Paid',
                                          isSmallScreen: isSmallScreen,
                                          isVerySmallScreen: isVerySmallScreen,
                                          onToggleExpand: () {
                                            setState(() {
                                              invoice.isExpanded =
                                                  !invoice.isExpanded;
                                            });
                                          },
                                          onToggleSelect:
                                              selectedFilter != 'Paid'
                                              ? () {
                                                  setState(() {
                                                    invoice.isSelected =
                                                        !invoice.isSelected;
                                                  });
                                                }
                                              : null,
                                          onShowVATReceipt:
                                              selectedFilter == 'Paid'
                                              ? () => _showVATReceiptModal(
                                                  invoice.id,
                                                )
                                              : null,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            }(),
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

  // _buildInvoiceCard moved to components/Nekhemjlekh/invoice_card.dart
  // Removed old implementation - using InvoiceCard component instead
}
