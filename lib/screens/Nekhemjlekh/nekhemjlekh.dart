import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:ui';
import 'dart:convert';
import 'package:go_router/go_router.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:sukh_app/services/api_service.dart';
import 'package:sukh_app/services/storage_service.dart';
import 'package:sukh_app/services/notification_service.dart';
import 'package:sukh_app/widgets/glass_snackbar.dart';
import 'package:sukh_app/models/geree_model.dart';
import 'package:sukh_app/models/ajiltan_model.dart';

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
      builder: (BuildContext context) {
        return Container(
          decoration: BoxDecoration(
            color: const Color(0xFF0a0e27),
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(30.w),
              topRight: Radius.circular(30.w),
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
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
                    Text(
                      'Гэрээ сонгох',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 24.sp,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    IconButton(
                      icon: Icon(Icons.close, color: Colors.white, size: 24.sp),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
              ),
              // Contract list
              Flexible(
                child: ListView.builder(
                  shrinkWrap: true,
                  padding: EdgeInsets.symmetric(
                    horizontal: 20.w,
                    vertical: 10.h,
                  ),
                  itemCount: availableContracts.length,
                  itemBuilder: (context, index) {
                    final contract = availableContracts[index];
                    final gereeniiDugaar = contract['gereeniiDugaar'] as String;
                    final bairNer = contract['bairNer'] ?? gereeniiDugaar;
                    final isSelected = gereeniiDugaar == selectedGereeniiDugaar;

                    return GestureDetector(
                      onTap: () {
                        setState(() {
                          selectedGereeniiDugaar = gereeniiDugaar;
                        });
                        Navigator.pop(context);
                        _loadNekhemjlekh();
                      },
                      child: Container(
                        margin: EdgeInsets.only(bottom: 12.h),
                        padding: EdgeInsets.all(16.w),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? const Color(0xFFe6ff00).withOpacity(0.2)
                              : Colors.white.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(20.w),
                          border: Border.all(
                            color: isSelected
                                ? const Color(0xFFe6ff00)
                                : Colors.white.withOpacity(0.2),
                            width: isSelected ? 2 : 1,
                          ),
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    bairNer,
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 16.sp,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  SizedBox(height: 4.h),
                                  Text(
                                    'Гэрээ: $gereeniiDugaar',
                                    style: TextStyle(
                                      color: Colors.white.withOpacity(0.7),
                                      fontSize: 14.sp,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            if (isSelected)
                              Icon(
                                Icons.check_circle,
                                color: const Color(0xFFe6ff00),
                                size: 24.sp,
                              ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
              SizedBox(height: 20.h),
            ],
          ),
        );
      },
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

  Color _getStatusColor(String status) {
    switch (status) {
      case 'Төлсөн':
        return const Color(0xFF10B981); // Green
      case 'Төлөөгүй':
        return const Color(0xFFF59E0B); // Orange/Amber
      default:
        return const Color(0xFF6B7280); // Gray
    }
  }

  String _getStatusLabel(String status) {
    switch (status) {
      case 'Төлсөн':
        return 'Төлөгдсөн';
      case 'Төлөөгүй':
        return 'Хүлээгдэж байгаа';
      default:
        return status;
    }
  }

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

  Widget _buildFilterTab(String filterKey, String label) {
    final isSelected = selectedFilter == filterKey;
    final count = _getFilterCount(filterKey);

    return GestureDetector(
      onTap: () {
        setState(() {
          selectedFilter = filterKey;
        });
      },
      child: Container(
        margin: EdgeInsets.only(right: 8.w),
        padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 8.h),
        decoration: BoxDecoration(
          color: isSelected
              ? const Color(0xFFe6ff00).withOpacity(0.2)
              : Colors.white.withOpacity(0.08),
          borderRadius: BorderRadius.circular(20.w),
          border: Border.all(
            color: isSelected
                ? const Color(0xFFe6ff00).withOpacity(0.5)
                : Colors.white.withOpacity(0.2),
            width: isSelected ? 1.5 : 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              label,
              style: TextStyle(
                color: isSelected
                    ? const Color(0xFFe6ff00)
                    : Colors.white.withOpacity(0.9),
                fontSize: 13.sp,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
              ),
            ),
            if (count > 0) ...[
              SizedBox(width: 6.w),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 6.w, vertical: 2.h),
                decoration: BoxDecoration(
                  color: isSelected
                      ? const Color(0xFFe6ff00)
                      : Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(10.w),
                ),
                child: Text(
                  count.toString(),
                  style: TextStyle(
                    color: isSelected ? Colors.black : Colors.white,
                    fontSize: 11.sp,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  void _showBankInfoModal() async {
    print('=== _showBankInfoModal called ===');
    await _createQPayInvoice();

    if (!mounted) return;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Container(
              height: MediaQuery.of(context).size.height * 0.7,
              decoration: BoxDecoration(
                color: const Color(0xFF0a0e27),
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(30.w),
                  topRight: Radius.circular(30.w),
                ),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(30.w),
                  topRight: Radius.circular(30.w),
                ),
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
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
                            Text(
                              'Банк сонгох',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 24.sp,
                                fontWeight: FontWeight.bold,
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
                      // Bank grid
                      Expanded(
                        child: isLoadingQPay
                            ? const Center(
                                child: CircularProgressIndicator(
                                  color: Colors.white,
                                ),
                              )
                            : qpayBanks.isEmpty
                            ? Center(
                                child: Text(
                                  contactPhone.isNotEmpty
                                      ? 'Банкны мэдээлэл олдсонгүй та СӨХ ийн $contactPhone дугаар луу холбогдоно уу!'
                                      : 'Банкны мэдээлэл олдсонгүй',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 16.sp,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                              )
                            : GridView.builder(
                                padding: EdgeInsets.symmetric(
                                  horizontal: 20.w,
                                  vertical: 10.h,
                                ),
                                gridDelegate:
                                    SliverGridDelegateWithFixedCrossAxisCount(
                                      crossAxisCount: 3,
                                      crossAxisSpacing: 12.w,
                                      mainAxisSpacing: 12.h,
                                      childAspectRatio: 0.85,
                                    ),
                                itemCount: qpayBanks.length,
                                itemBuilder: (context, index) {
                                  final bank = qpayBanks[index];
                                  return _buildQPayBankItem(bank);
                                },
                              ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  Future<void> _showVATReceiptModal(String invoiceId) async {
    try {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(
          child: CircularProgressIndicator(color: Color(0xFFe6ff00)),
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
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(24.w),
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                    child: Container(
                      decoration: BoxDecoration(
                        color: const Color(0xFF0a0e27).withOpacity(0.95),
                        borderRadius: BorderRadius.circular(24.w),
                        border: Border.all(
                          color: const Color(0xFFe6ff00).withOpacity(0.3),
                          width: 1.5,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFFe6ff00).withOpacity(0.2),
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
                            color: const Color(0xFFe6ff00).withOpacity(0.2),
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
                                      backgroundColor: const Color(
                                        0xFFe6ff00,
                                      ).withOpacity(0.9),
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
                                    color: const Color(0xFFe6ff00),
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
                                    backgroundColor: const Color(0xFFe6ff00),
                                    foregroundColor: const Color(0xFF0a0e27),
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
        builder: (context) => _buildVATReceiptBottomSheet(receipts[0]),
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

  Widget _buildVATReceiptBottomSheet(VATReceipt receipt) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.85,
      decoration: BoxDecoration(
        color: const Color(0xFF0a0e27),
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(30.w),
          topRight: Radius.circular(30.w),
        ),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(30.w),
          topRight: Radius.circular(30.w),
        ),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
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
                    Text(
                      'НӨАТ-ын баримт',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 24.sp,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    IconButton(
                      icon: Icon(Icons.close, color: Colors.white, size: 24.sp),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
              ),
              // Content
              Expanded(
                child: SingleChildScrollView(
                  padding: EdgeInsets.symmetric(horizontal: 20.w),
                  child: Column(
                    children: [
                      // QR Code
                      if (receipt.qrData.isNotEmpty) ...[
                        Container(
                          padding: EdgeInsets.all(20.w),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(20.w),
                          ),
                          child: QrImageView(
                            data: receipt.qrData,
                            version: QrVersions.auto,
                            size: 250.w,
                            backgroundColor: Colors.white,
                          ),
                        ),
                        SizedBox(height: 20.h),
                      ],
                      // Receipt Info
                      Container(
                        padding: EdgeInsets.all(20.w),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(20.w),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (receipt.lottery != null)
                              _buildReceiptInfoRow(
                                'Сугалааны дугаар:',
                                receipt.lottery!,
                              ),
                            _buildReceiptInfoRow(
                              'Огноо:',
                              receipt.formattedDate,
                            ),
                            _buildReceiptInfoRow(
                              'Регистр:',
                              receipt.merchantTin,
                            ),

                            Divider(color: Colors.white24, height: 24.h),
                            Text(
                              'Бараа, үйлчилгээ:',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 16.sp,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            SizedBox(height: 12.h),

                            ...receipt.receipts
                                .expand((r) => r.items)
                                .map(
                                  (item) => Padding(
                                    padding: EdgeInsets.only(bottom: 12.h),
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          item.name,
                                          style: TextStyle(
                                            color: Colors.white,
                                            fontSize: 14.sp,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                        SizedBox(height: 4.h),
                                        Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.spaceBetween,
                                          children: [
                                            Text(
                                              '${item.qty} ${item.measureUnit} × ${item.unitPrice}₮',
                                              style: TextStyle(
                                                color: Colors.white.withOpacity(
                                                  0.7,
                                                ),
                                                fontSize: 12.sp,
                                              ),
                                            ),
                                            Text(
                                              '${item.totalAmount}₮',
                                              style: TextStyle(
                                                color: Colors.white,
                                                fontSize: 14.sp,
                                                fontWeight: FontWeight.w600,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                            Divider(color: Colors.white24, height: 24.h),
                            _buildReceiptInfoRow(
                              'Нийт дүн:',
                              receipt.formattedAmount,
                              isBold: true,
                            ),
                            _buildReceiptInfoRow(
                              'НӨАТ:',
                              '${receipt.totalVAT.toStringAsFixed(2)}₮',
                            ),
                            if (receipt.totalCityTax > 0)
                              _buildReceiptInfoRow(
                                'Хотын татвар:',
                                '${receipt.totalCityTax.toStringAsFixed(2)}₮',
                              ),
                            Divider(color: Colors.white24, height: 24.h),
                            Text(
                              'Төлбөр:',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 16.sp,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            SizedBox(height: 8.h),
                            ...receipt.payments.map(
                              (payment) => _buildReceiptInfoRow(
                                payment.code,
                                '${payment.paidAmount}₮ (${payment.status})',
                              ),
                            ),
                          ],
                        ),
                      ),
                      SizedBox(height: 20.h),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildReceiptInfoRow(
    String label,
    String value, {
    bool isBold = false,
  }) {
    return Padding(
      padding: EdgeInsets.only(bottom: 8.h),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              color: Colors.white.withOpacity(0.7),
              fontSize: 14.sp,
            ),
          ),
          Text(
            value,
            style: TextStyle(
              color: Colors.white,
              fontSize: 14.sp,
              fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQPayBankItem(QPayBank bank) {
    return GestureDetector(
      onTap: () {
        // Check if it's qPay wallet - show QR code
        if (bank.description.contains('qPay хэтэвч') ||
            bank.name.toLowerCase().contains('qpay wallet')) {
          _showQPayQRCodeModal();
        } else {
          _openBankAppAndShowCheckModal(bank);
        }
      },
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12.w),
          border: Border.all(color: Colors.white.withOpacity(0.2), width: 1),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Bank logo
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
            SizedBox(height: 8.h),
            // Bank name
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 4.w),
              child: Text(
                bank.description,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 11.sp,
                  fontWeight: FontWeight.w500,
                ),
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }

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
            color: const Color(0xFF0a0e27),
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(30.w),
              topRight: Radius.circular(30.w),
            ),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(30.w),
              topRight: Radius.circular(30.w),
            ),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
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
                          backgroundColor: const Color(0xFFe6ff00),
                          foregroundColor: Colors.black,
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
        child: CircularProgressIndicator(color: Color(0xFFe6ff00)),
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
          await showModalBottomSheet(
            context: context,
            isScrollControlled: true,
            backgroundColor: Colors.transparent,
            builder: (context) => _buildVATReceiptBottomSheet(receipts[0]),
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
              color: const Color(0xFF0a0e27),
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
                    backgroundColor: const Color(0xFFe6ff00),
                    foregroundColor: Colors.black,
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
          backgroundColor: const Color(0xFF0a0e27),
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
                style: TextStyle(color: Color(0xFFe6ff00)),
              ),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                _openAppStore(bank);
              },
              child: const Text(
                'Апп татах',
                style: TextStyle(color: Color(0xFFe6ff00)),
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
      builder: (context) => Container(
        decoration: BoxDecoration(
          color: const Color(0xFF0a0e27),
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(16.w),
            topRight: Radius.circular(16.w),
          ),
          border: Border.all(color: Colors.white.withOpacity(0.1)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header
            Container(
              padding: EdgeInsets.all(16.w),
              decoration: BoxDecoration(
                border: Border(
                  bottom: BorderSide(color: Colors.white.withOpacity(0.1)),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Төлбөрийн мэдээлэл',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18.sp,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  IconButton(
                    icon: Icon(Icons.close, color: Colors.white, size: 24.sp),
                    onPressed: () => Navigator.of(context).pop(),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                ],
              ),
            ),
            // Content
            Padding(
              padding: EdgeInsets.all(16.w),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Price information panel
                  Container(
                    padding: EdgeInsets.all(14.w),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.05),
                      borderRadius: BorderRadius.circular(12.w),
                      border: Border.all(color: Colors.white.withOpacity(0.1)),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Төлөх дүн',
                          style: TextStyle(
                            fontSize: 14.sp,
                            color: Colors.white.withOpacity(0.6),
                          ),
                        ),
                        Text(
                          totalSelectedAmount,
                          style: TextStyle(
                            fontSize: 18.sp,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(height: 10.h),
                  // Contract information panel
                  Container(
                    padding: EdgeInsets.all(14.w),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.05),
                      borderRadius: BorderRadius.circular(12.w),
                      border: Border.all(color: Colors.white.withOpacity(0.1)),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Гэрээ',
                          style: TextStyle(
                            fontSize: 14.sp,
                            color: Colors.white.withOpacity(0.6),
                          ),
                        ),
                        Text(
                          '$selectedCount гэрээ',
                          style: TextStyle(
                            fontSize: 16.sp,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(height: 16.h),
                  // Payment button
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () async {
                        Navigator.pop(context);
                        // Add a small delay to ensure modal is closed before showing new one
                        await Future.delayed(const Duration(milliseconds: 100));
                        _showBankInfoModal();
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: Colors.black,
                        padding: EdgeInsets.symmetric(vertical: 14.h),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12.w),
                        ),
                      ),
                      child: Text(
                        'Банкны аппликешнээр төлөх',
                        style: TextStyle(
                          fontSize: 16.sp,
                          fontWeight: FontWeight.w600,
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
              // Header - matching geree page style
              Padding(
                padding: EdgeInsets.all(16.w),
                child: Row(
                  children: [
                    IconButton(
                      icon: Icon(
                        Icons.arrow_back,
                        color: Colors.white,
                        size: 28.sp,
                      ),
                      onPressed: () => context.pop(),
                    ),
                    SizedBox(width: 12.w),
                    Expanded(
                      child: Text(
                        'Нэхэмжлэх',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 24.sp,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    if (availableContracts.length > 1)
                      IconButton(
                        icon: Icon(
                          Icons.swap_horiz,
                          color: Colors.white,
                          size: 24.sp,
                        ),
                        onPressed: _showContractSelectionModal,
                        tooltip: 'Гэрээ солих',
                      ),
                  ],
                ),
              ),
              // Contract info (if multiple contracts)
              if (selectedContractDisplay != null &&
                  availableContracts.length > 1)
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16.w),
                  child: GestureDetector(
                    onTap: _showContractSelectionModal,
                    child: Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: 12.w,
                        vertical: 8.h,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.05),
                        borderRadius: BorderRadius.circular(8.w),
                        border: Border.all(
                          color: const Color(0xFFe6ff00).withOpacity(0.3),
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.business,
                            color: const Color(0xFFe6ff00),
                            size: 16.sp,
                          ),
                          SizedBox(width: 8.w),
                          Flexible(
                            child: Text(
                              selectedContractDisplay!,
                              style: TextStyle(
                                color: Colors.white.withOpacity(0.9),
                                fontSize: 13.sp,
                                fontWeight: FontWeight.w500,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          SizedBox(width: 4.w),
                          Icon(
                            Icons.keyboard_arrow_down,
                            color: const Color(0xFFe6ff00),
                            size: 16.sp,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              if (selectedContractDisplay != null &&
                  availableContracts.length > 1)
                SizedBox(height: 12.h),
              Expanded(
                child: isLoading
                    ? const Center(
                        child: CircularProgressIndicator(color: Colors.white),
                      )
                    : errorMessage != null
                    ? Center(
                        child: Padding(
                          padding: EdgeInsets.all(16.w),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                errorMessage!,
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 16.sp,
                                ),
                                textAlign: TextAlign.center,
                              ),
                              SizedBox(height: 16.h),
                              ElevatedButton(
                                onPressed: _loadNekhemjlekh,
                                style: ElevatedButton.styleFrom(
                                  padding: EdgeInsets.symmetric(
                                    horizontal: 20.w,
                                    vertical: 12.h,
                                  ),
                                ),
                                child: Text(
                                  'Дахин оролдох',
                                  style: TextStyle(fontSize: 14.sp),
                                ),
                              ),
                            ],
                          ),
                        ),
                      )
                    : Column(
                        children: [
                          // Filter Tabs
                          Container(
                            height: 50.h,
                            margin: EdgeInsets.symmetric(
                              horizontal: 16.w,
                              vertical: 8.h,
                            ),
                            child: ListView(
                              scrollDirection: Axis.horizontal,
                              children: [
                                _buildFilterTab('All', 'Бүгд'),
                                _buildFilterTab('Paid', 'Төлсөн'),
                              ],
                            ),
                          ),
                          // Sticky payment section at top (hidden in history mode)
                          if (selectedFilter != 'Paid')
                            Padding(
                              padding: EdgeInsets.symmetric(horizontal: 16.w),
                              child: Container(
                                padding: EdgeInsets.all(16.w),
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.08),
                                  borderRadius: BorderRadius.circular(20.w),
                                  border: Border.all(
                                    color: const Color(
                                      0xFFe6ff00,
                                    ).withOpacity(0.3),
                                    width: 1.5,
                                  ),
                                ),
                                child: ClipRRect(
                                  child: Container(
                                    child: Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                      children: [
                                        Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              selectedCount > 0
                                                  ? '$selectedCount нэхэмжлэх сонгосон'
                                                  : 'Нэхэмжлэх сонгоно уу',
                                              style: TextStyle(
                                                color: Colors.white.withOpacity(
                                                  0.7,
                                                ),
                                                fontSize: 12.sp,
                                                fontWeight: FontWeight.w500,
                                              ),
                                            ),
                                            SizedBox(height: 4.h),
                                            Text(
                                              totalSelectedAmount,
                                              style: TextStyle(
                                                color: const Color(0xFFe6ff00),
                                                fontSize: 20.sp,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                          ],
                                        ),
                                        ElevatedButton(
                                          onPressed: selectedCount > 0
                                              ? _showPaymentModal
                                              : null,
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor: const Color(
                                              0xFFe6ff00,
                                            ),
                                            foregroundColor: Colors.black,
                                            disabledBackgroundColor: Colors
                                                .white
                                                .withOpacity(0.1),
                                            disabledForegroundColor: Colors
                                                .white
                                                .withOpacity(0.3),
                                            padding: EdgeInsets.symmetric(
                                              horizontal: 24.w,
                                              vertical: 12.h,
                                            ),
                                            shape: RoundedRectangleBorder(
                                              borderRadius:
                                                  BorderRadius.circular(12.w),
                                            ),
                                          ),
                                          child: Text(
                                            'Төлбөр төлөх',
                                            style: TextStyle(
                                              fontWeight: FontWeight.w600,
                                              fontSize: 14.sp,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          SizedBox(height: 8.h),
                          // Scrollable invoice list
                          Expanded(
                            child: () {
                              final filteredInvoices = _getFilteredInvoices();

                              if (filteredInvoices.isEmpty) {
                                return Center(
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Container(
                                        padding: EdgeInsets.all(24.w),
                                        decoration: BoxDecoration(
                                          color: Colors.white.withOpacity(0.1),
                                          shape: BoxShape.circle,
                                        ),
                                        child: Icon(
                                          selectedFilter == 'Paid'
                                              ? Icons.history
                                              : Icons.receipt_long,
                                          size: 48.sp,
                                          color: Colors.white.withOpacity(0.5),
                                        ),
                                      ),
                                      SizedBox(height: 24.h),
                                      Text(
                                        selectedFilter == 'Paid'
                                            ? 'Төлөгдсөн нэхэмжлэл байхгүй'
                                            : 'Одоогоор нэхэмжлэл байхгүй',
                                        style: TextStyle(
                                          color: Colors.white.withOpacity(0.8),
                                          fontSize: 18.sp,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                      SizedBox(height: 8.h),
                                      Text(
                                        selectedFilter == 'Paid'
                                            ? 'Төлөгдсөн нэхэмжлэлийн түүх энд харагдана'
                                            : 'Шинэ нэхэмжлэл үүсэхэд энд харагдана',
                                        style: TextStyle(
                                          color: Colors.white.withOpacity(0.5),
                                          fontSize: 14.sp,
                                        ),
                                        textAlign: TextAlign.center,
                                      ),
                                    ],
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
                                        child: GestureDetector(
                                          onTap: toggleSelectAll,
                                          child: Row(
                                            children: [
                                              Container(
                                                width: isVerySmallScreen
                                                    ? 16
                                                    : (isSmallScreen ? 18 : 20),
                                                height: isVerySmallScreen
                                                    ? 16
                                                    : (isSmallScreen ? 18 : 20),
                                                decoration: BoxDecoration(
                                                  color: allSelected
                                                      ? Colors.white
                                                      : Colors.transparent,
                                                  border: Border.all(
                                                    color: Colors.white,
                                                    width: 2,
                                                  ),
                                                  borderRadius:
                                                      BorderRadius.circular(4),
                                                ),
                                                child: allSelected
                                                    ? Icon(
                                                        Icons.check,
                                                        color: Colors.black,
                                                        size: isVerySmallScreen
                                                            ? 10
                                                            : (isSmallScreen
                                                                  ? 12
                                                                  : 14),
                                                      )
                                                    : null,
                                              ),
                                              SizedBox(
                                                width: isVerySmallScreen
                                                    ? 8
                                                    : (isSmallScreen ? 10 : 12),
                                              ),
                                              Text(
                                                'Бүгдийг сонгох',
                                                style: TextStyle(
                                                  color: Colors.white,
                                                  fontSize: isVerySmallScreen
                                                      ? 13
                                                      : (isSmallScreen
                                                            ? 14
                                                            : 16),
                                                ),
                                              ),
                                            ],
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
                                        child: _buildInvoiceCard(
                                          invoice,
                                          isHistory: selectedFilter == 'Paid',
                                          isSmallScreen: isSmallScreen,
                                          isVerySmallScreen: isVerySmallScreen,
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

  Widget _buildInvoiceCard(
    NekhemjlekhItem invoice, {
    bool isHistory = false,
    bool isSmallScreen = false,
    bool isVerySmallScreen = false,
  }) {
    // Get status color and label
    final statusColor = _getStatusColor(invoice.tuluv);
    final statusLabel = _getStatusLabel(invoice.tuluv);

    // Logo for invoice card

    return Container(
      margin: EdgeInsets.only(bottom: 16.h),
      decoration: BoxDecoration(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(20.w),
        border: Border.all(
          color: const Color(0xFFe6ff00).withOpacity(0.3),
          width: 2,
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            setState(() {
              invoice.isExpanded = !invoice.isExpanded;
            });
          },
          borderRadius: BorderRadius.circular(20.w),
          splashColor: const Color(0xFFe6ff00).withOpacity(0.1),
          highlightColor: const Color(0xFFe6ff00).withOpacity(0.05),
          hoverColor: const Color(0xFFe6ff00).withOpacity(0.08),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Main card content
              Padding(
                padding: EdgeInsets.all(16.w),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Date row
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          invoice.formattedDate,
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.7),
                            fontSize: 12.sp,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        // Status tag - Premium design
                        Container(
                          padding: EdgeInsets.symmetric(
                            horizontal: 12.w,
                            vertical: 6.h,
                          ),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                statusColor.withOpacity(0.15),
                                statusColor.withOpacity(0.08),
                              ],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            borderRadius: BorderRadius.circular(16.w),
                            border: Border.all(
                              color: statusColor.withOpacity(0.4),
                              width: 1.5,
                            ),
                          ),
                          child: Text(
                            statusLabel,
                            style: TextStyle(
                              color: statusColor,
                              fontSize: 12.sp,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 12.h),
                    // Main content row
                    Row(
                      children: [
                        // Company logo
                        Container(
                          width: 48.w,
                          height: 48.w,
                          decoration: BoxDecoration(
                            color: Colors.transparent,
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: const Color(0xFFe6ff00).withOpacity(0.3),
                              width: 2,
                            ),
                          ),
                          child: ClipOval(
                            child: Image.asset(
                              'lib/assets/img/logo_3.png',
                              width: 48.w,
                              height: 48.w,
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) {
                                return Icon(
                                  Icons.receipt_long_rounded,
                                  color: Colors.white,
                                  size: 24.sp,
                                );
                              },
                            ),
                          ),
                        ),
                        SizedBox(width: 12.w),
                        // Client info
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                invoice.displayName,
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 16.sp,
                                  fontWeight: FontWeight.w600,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              SizedBox(height: 4.h),
                              Text(
                                invoice.gereeniiDugaar,
                                style: TextStyle(
                                  color: Colors.white.withOpacity(0.7),
                                  fontSize: 13.sp,
                                ),
                              ),
                            ],
                          ),
                        ),
                        // Amount
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              invoice.formattedAmount,
                              style: TextStyle(
                                color: const Color(0xFFe6ff00),
                                fontSize: 16.sp,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            if (!isHistory) SizedBox(height: 8.h),
                            // Premium Checkbox for selection (only in non-history mode)
                            if (!isHistory)
                              Material(
                                color: Colors.transparent,
                                child: InkWell(
                                  onTap: () {
                                    HapticFeedback.lightImpact();
                                    setState(() {
                                      invoice.isSelected = !invoice.isSelected;
                                    });
                                  },
                                  borderRadius: BorderRadius.circular(6.w),
                                  splashColor: const Color(
                                    0xFFe6ff00,
                                  ).withOpacity(0.3),
                                  highlightColor: const Color(
                                    0xFFe6ff00,
                                  ).withOpacity(0.1),
                                  child: AnimatedContainer(
                                    duration: const Duration(milliseconds: 300),
                                    curve: Curves.easeInOutCubic,
                                    width: 26.w,
                                    height: 26.w,
                                    decoration: BoxDecoration(
                                      gradient: invoice.isSelected
                                          ? LinearGradient(
                                              colors: [
                                                const Color(0xFFe6ff00),
                                                const Color(
                                                  0xFFe6ff00,
                                                ).withOpacity(0.8),
                                              ],
                                              begin: Alignment.topLeft,
                                              end: Alignment.bottomRight,
                                            )
                                          : null,
                                      color: invoice.isSelected
                                          ? null
                                          : Colors.transparent,
                                      border: Border.all(
                                        color: invoice.isSelected
                                            ? const Color(0xFFe6ff00)
                                            : Colors.white.withOpacity(0.5),
                                        width: invoice.isSelected ? 2.5 : 2,
                                      ),
                                      borderRadius: BorderRadius.circular(6.w),
                                      boxShadow: invoice.isSelected
                                          ? [
                                              BoxShadow(
                                                color: const Color(
                                                  0xFFe6ff00,
                                                ).withOpacity(0.5),
                                                blurRadius: 16,
                                                spreadRadius: 0,
                                                offset: const Offset(0, 6),
                                              ),
                                              BoxShadow(
                                                color: const Color(
                                                  0xFFe6ff00,
                                                ).withOpacity(0.3),
                                                blurRadius: 10,
                                                spreadRadius: 3,
                                              ),
                                            ]
                                          : [
                                              BoxShadow(
                                                color: Colors.black.withOpacity(
                                                  0.15,
                                                ),
                                                blurRadius: 6,
                                                spreadRadius: 0,
                                                offset: const Offset(0, 2),
                                              ),
                                            ],
                                    ),
                                    child: Center(
                                      child: AnimatedScale(
                                        scale: invoice.isSelected ? 1.0 : 0.0,
                                        duration: const Duration(
                                          milliseconds: 250,
                                        ),
                                        curve: Curves.elasticOut,
                                        child: invoice.isSelected
                                            ? Icon(
                                                Icons.check_rounded,
                                                color: Colors.white,
                                                size: 18.sp,
                                                weight: 3,
                                              )
                                            : const SizedBox.shrink(),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ],
                    ),
                    // Expand/Collapse indicator
                    Padding(
                      padding: EdgeInsets.only(top: 8.h),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            invoice.isExpanded
                                ? Icons.keyboard_arrow_up
                                : Icons.keyboard_arrow_down,
                            color: const Color(0xFFe6ff00),
                            size: 20.sp,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              // Expanded details section (inside same card)
              if (invoice.isExpanded) ...[
                Container(
                  padding: EdgeInsets.all(16.w),
                  decoration: BoxDecoration(color: Colors.transparent),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Нэхэмжлэгч and Төлөгч sections with gold accents
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Нэхэмжлэгч section
                          Expanded(
                            child: Container(
                              padding: EdgeInsets.all(12.w),
                              constraints: BoxConstraints(minHeight: 120.h),
                              decoration: BoxDecoration(
                                color: Colors.transparent,
                                borderRadius: BorderRadius.circular(12.w),
                                border: Border.all(
                                  color: const Color(
                                    0xFFe6ff00,
                                  ).withOpacity(0.3),
                                  width: 1.5,
                                ),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Row(
                                    children: [
                                      Icon(
                                        Icons.business,
                                        color: const Color(0xFFe6ff00),
                                        size: 16.sp,
                                      ),
                                      SizedBox(width: 6.w),
                                      Text(
                                        'Нэхэмжлэгч',
                                        style: TextStyle(
                                          color: const Color(0xFFe6ff00),
                                          fontSize: 13.sp,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ],
                                  ),
                                  SizedBox(height: 8.h),
                                  _buildInfoText(
                                    context,
                                    'Байгууллагын нэр:\n${invoice.baiguullagiinNer}',
                                  ),
                                  if (invoice.khayag.isNotEmpty) ...[
                                    SizedBox(height: 6.h),
                                    _buildInfoText(
                                      context,
                                      'Хаяг: ${invoice.khayag}',
                                    ),
                                  ],
                                ],
                              ),
                            ),
                          ),
                          SizedBox(width: 12.w),
                          // Төлөгч section
                          Expanded(
                            child: Container(
                              padding: EdgeInsets.all(12.w),
                              constraints: BoxConstraints(minHeight: 120.h),
                              decoration: BoxDecoration(
                                color: Colors.transparent,
                                borderRadius: BorderRadius.circular(12.w),
                                border: Border.all(
                                  color: const Color(
                                    0xFFe6ff00,
                                  ).withOpacity(0.3),
                                  width: 1.5,
                                ),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Row(
                                    children: [
                                      Icon(
                                        Icons.person,
                                        color: const Color(0xFFe6ff00),
                                        size: 16.sp,
                                      ),
                                      SizedBox(width: 6.w),
                                      Text(
                                        'Төлөгч',
                                        style: TextStyle(
                                          color: const Color(0xFFe6ff00),
                                          fontSize: 13.sp,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ],
                                  ),
                                  SizedBox(height: 8.h),
                                  _buildInfoText(
                                    context,
                                    'Нэр: ${invoice.displayName}',
                                  ),
                                  if (invoice.register.isNotEmpty) ...[
                                    SizedBox(height: 6.h),
                                    _buildInfoText(
                                      context,
                                      'Регистр: ${invoice.register}',
                                    ),
                                  ],
                                  if (invoice.phoneNumber.isNotEmpty) ...[
                                    SizedBox(height: 6.h),
                                    _buildInfoText(
                                      context,
                                      'Утас: ${invoice.phoneNumber}',
                                    ),
                                  ],
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 20.h),
                      // Price breakdown
                      if (invoice.ekhniiUldegdel != null &&
                          invoice.ekhniiUldegdel! != 0) ...[
                        _buildPriceRow(
                          context,
                          'Эхний үлдэгдэл',
                          '${invoice.ekhniiUldegdel!.toStringAsFixed(2).replaceAllMapped(RegExp(r'(\d)(?=(\d{3})+(?!\d))'), (match) => '${match[1]},')}₮',
                        ),
                      ],
                      if (invoice.medeelel != null &&
                          invoice.medeelel!.zardluud.isNotEmpty) ...[
                        SizedBox(height: 8.h),
                        ...invoice.medeelel!.zardluud.map(
                          (zardal) => _buildPriceRow(
                            context,
                            zardal.ner,
                            zardal.formattedTariff,
                          ),
                        ),
                      ],
                      // Tailbar field
                      if (invoice.medeelel != null &&
                          invoice.medeelel!.tailbar != null &&
                          invoice.medeelel!.tailbar!.isNotEmpty) ...[
                        SizedBox(height: 16.h),
                        Container(
                          padding: EdgeInsets.all(12.w),
                          decoration: BoxDecoration(
                            color: Colors.transparent,
                            borderRadius: BorderRadius.circular(12.w),
                            border: Border.all(
                              color: const Color(0xFFe6ff00).withOpacity(0.3),
                              width: 1.5,
                            ),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Icon(
                                    Icons.note_outlined,
                                    color: const Color(0xFFe6ff00),
                                    size: 16.sp,
                                  ),
                                  SizedBox(width: 6.w),
                                  Text(
                                    'Тайлбар',
                                    style: TextStyle(
                                      color: const Color(0xFFe6ff00),
                                      fontSize: 13.sp,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                              SizedBox(height: 8.h),
                              Text(
                                invoice.medeelel!.tailbar!,
                                style: TextStyle(
                                  color: Colors.white.withOpacity(0.9),
                                  fontSize: 13.sp,
                                  height: 1.4,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                      SizedBox(height: 16.h),
                      // Total amount with gold accent
                      Container(
                        padding: EdgeInsets.all(16.w),
                        decoration: BoxDecoration(
                          color: Colors.transparent,
                          borderRadius: BorderRadius.circular(12.w),
                          border: Border.all(
                            color: const Color(0xFFe6ff00).withOpacity(0.4),
                            width: 1.5,
                          ),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Нийт дүн:',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 18.sp,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              invoice.formattedAmount,
                              style: TextStyle(
                                color: const Color(0xFFe6ff00),
                                fontSize: 20.sp,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (isHistory) ...[
                        SizedBox(height: 12.h),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton.icon(
                            onPressed: () => _showVATReceiptModal(invoice.id),
                            icon: Icon(Icons.receipt_long, size: 18.sp),
                            label: Text(
                              'Баримт харах',
                              style: TextStyle(fontSize: 14.sp),
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFFe6ff00),
                              foregroundColor: const Color(0xFF0a0e27),
                              padding: EdgeInsets.symmetric(vertical: 12.h),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12.w),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

Widget _buildInfoText(BuildContext context, String text) {
  final screenHeight = MediaQuery.of(context).size.height;
  final screenWidth = MediaQuery.of(context).size.width;
  final isSmallScreen = screenHeight < 900 || screenWidth < 400;
  final isVerySmallScreen = screenHeight < 700 || screenWidth < 380;

  return Padding(
    padding: EdgeInsets.only(
      bottom: isVerySmallScreen ? 6 : (isSmallScreen ? 7 : 8),
    ),
    child: Text(
      text,
      style: TextStyle(
        color: Colors.white.withOpacity(0.9),
        fontSize: isVerySmallScreen ? 11 : (isSmallScreen ? 12 : 13),
        height: 1.4,
      ),
    ),
  );
}

Widget _buildPriceRow(BuildContext context, String label, String amount) {
  final screenHeight = MediaQuery.of(context).size.height;
  final screenWidth = MediaQuery.of(context).size.width;
  final isSmallScreen = screenHeight < 900 || screenWidth < 400;
  final isVerySmallScreen = screenHeight < 700 || screenWidth < 380;

  return Padding(
    padding: EdgeInsets.symmetric(
      vertical: isVerySmallScreen ? 6 : (isSmallScreen ? 7 : 8),
    ),
    child: Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            color: Colors.white.withOpacity(0.8),
            fontSize: isVerySmallScreen ? 12 : (isSmallScreen ? 13 : 14),
          ),
        ),
        Text(
          amount,
          style: TextStyle(
            color: const Color(0xFFe6ff00),
            fontSize: isVerySmallScreen ? 12 : (isSmallScreen ? 13 : 14),
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    ),
  );
}

// Nekhemjlekh data models
class NekhemjlekhItem {
  final String id;
  final String baiguullagiinNer;
  final String ovog;
  final String ner;
  final String register;
  final String khayag;
  final String gereeniiDugaar;
  final String nekhemjlekhiinOgnoo;
  final double niitTulbur;
  final List<String> utas;
  final String dansniiDugaar;
  final String tuluv;
  final NekhemjlekhMedeelel? medeelel;
  final double? ekhniiUldegdel;
  bool isSelected;
  bool isExpanded;

  NekhemjlekhItem({
    required this.id,
    required this.baiguullagiinNer,
    required this.ovog,
    required this.ner,
    required this.register,
    required this.khayag,
    required this.gereeniiDugaar,
    required this.nekhemjlekhiinOgnoo,
    required this.niitTulbur,
    required this.utas,
    required this.dansniiDugaar,
    required this.tuluv,
    this.medeelel,
    this.ekhniiUldegdel,
    this.isSelected = false,
    this.isExpanded = false,
  });

  factory NekhemjlekhItem.fromJson(Map<String, dynamic> json) {
    return NekhemjlekhItem(
      id: json['_id']?.toString() ?? '',
      baiguullagiinNer: json['baiguullagiinNer']?.toString() ?? '',
      ovog: json['ovog']?.toString() ?? '',
      ner: json['ner']?.toString() ?? '',
      register: json['register']?.toString() ?? '',
      khayag: json['khayag']?.toString() ?? '',
      gereeniiDugaar: json['gereeniiDugaar']?.toString() ?? '',
      nekhemjlekhiinOgnoo:
          json['nekhemjlekhiinOgnoo']?.toString() ??
          json['ognoo']?.toString() ??
          '',
      niitTulbur: (json['niitTulbur'] ?? 0).toDouble(),
      utas: json['utas'] != null
          ? (json['utas'] as List).map((e) => e.toString()).toList()
          : [],
      dansniiDugaar: json['dansniiDugaar']?.toString() ?? '',
      tuluv: json['tuluv']?.toString() ?? 'Төлөөгүй',
      medeelel: json['medeelel'] != null
          ? NekhemjlekhMedeelel.fromJson(json['medeelel'])
          : null,
      ekhniiUldegdel: json['ekhniiUldegdel'] != null
          ? (json['ekhniiUldegdel'] as num).toDouble()
          : null,
    );
  }

  String get formattedDate {
    try {
      final date = DateTime.parse(nekhemjlekhiinOgnoo);
      return '${date.year}.${date.month.toString().padLeft(2, '0')}.${date.day.toString().padLeft(2, '0')}';
    } catch (e) {
      return nekhemjlekhiinOgnoo;
    }
  }

  String get formattedAmount {
    final formatted = niitTulbur
        .toStringAsFixed(2)
        .replaceAllMapped(
          RegExp(r'(\d)(?=(\d{3})+(?!\d))'),
          (match) => '${match[1]},',
        );
    return '$formatted₮';
  }

  String get displayName =>
      '$ovog $ner'.trim().isNotEmpty ? '$ovog $ner' : baiguullagiinNer;
  String get phoneNumber => utas.isNotEmpty ? utas.first : '';
}

class NekhemjlekhMedeelel {
  final List<Zardal> zardluud;
  final List<Guilgee>? guilgeenuud;
  final String toot;
  final String temdeglel;
  final String? tailbar;

  NekhemjlekhMedeelel({
    required this.zardluud,
    this.guilgeenuud,
    required this.toot,
    required this.temdeglel,
    this.tailbar,
  });

  factory NekhemjlekhMedeelel.fromJson(Map<String, dynamic> json) {
    return NekhemjlekhMedeelel(
      zardluud: json['zardluud'] != null
          ? (json['zardluud'] as List).map((z) => Zardal.fromJson(z)).toList()
          : [],
      guilgeenuud: json['guilgeenuud'] != null
          ? (json['guilgeenuud'] as List)
                .map((g) => Guilgee.fromJson(g))
                .toList()
          : null,
      toot: json['toot']?.toString() ?? '',
      temdeglel: json['temdeglel']?.toString() ?? '',
      tailbar: json['tailbar']?.toString(),
    );
  }
}

class Zardal {
  final String ner;
  final String turul;
  final double tariff;
  final String tariffUsgeer;
  final String zardliinTurul;
  final double dun;

  Zardal({
    required this.ner,
    required this.turul,
    required this.tariff,
    required this.tariffUsgeer,
    required this.zardliinTurul,
    required this.dun,
  });

  factory Zardal.fromJson(Map<String, dynamic> json) {
    return Zardal(
      ner: json['ner']?.toString() ?? '',
      turul: json['turul']?.toString() ?? '',
      tariff: (json['tariff'] ?? 0).toDouble(),
      tariffUsgeer: json['tariffUsgeer']?.toString() ?? '₮',
      zardliinTurul: json['zardliinTurul']?.toString() ?? '',
      dun: (json['dun'] ?? 0).toDouble(),
    );
  }

  String get formattedTariff {
    final formatted = tariff
        .toStringAsFixed(2)
        .replaceAllMapped(
          RegExp(r'(\d)(?=(\d{3})+(?!\d))'),
          (match) => '${match[1]},',
        );
    return '$formatted$tariffUsgeer';
  }
}

class Guilgee {
  final String? ognoo;
  final double? tulukhDun;
  final double? tulsunDun;
  final String? tailbar;
  final String? turul;
  final String? gereeniiId;
  final String? guilgeeKhiisenOgnoo;
  final String? guilgeeKhiisenAjiltniiNer;
  final String? guilgeeKhiisenAjiltniiId;
  final int? avlagaGuilgeeIndex;
  final String? id;

  Guilgee({
    this.ognoo,
    this.tulukhDun,
    this.tulsunDun,
    this.tailbar,
    this.turul,
    this.gereeniiId,
    this.guilgeeKhiisenOgnoo,
    this.guilgeeKhiisenAjiltniiNer,
    this.guilgeeKhiisenAjiltniiId,
    this.avlagaGuilgeeIndex,
    this.id,
  });

  factory Guilgee.fromJson(Map<String, dynamic> json) {
    return Guilgee(
      ognoo: json['ognoo']?.toString(),
      tulukhDun: json['tulukhDun'] != null
          ? (json['tulukhDun'] as num).toDouble()
          : null,
      tulsunDun: json['tulsunDun'] != null
          ? (json['tulsunDun'] as num).toDouble()
          : null,
      tailbar: json['tailbar']?.toString(),
      turul: json['turul']?.toString(),
      gereeniiId: json['gereeniiId']?.toString(),
      guilgeeKhiisenOgnoo: json['guilgeeKhiisenOgnoo']?.toString(),
      guilgeeKhiisenAjiltniiNer: json['guilgeeKhiisenAjiltniiNer']?.toString(),
      guilgeeKhiisenAjiltniiId: json['guilgeeKhiisenAjiltniiId']?.toString(),
      avlagaGuilgeeIndex: json['avlagaGuilgeeIndex'] as int?,
      id: json['_id']?.toString(),
    );
  }
}

class QPayBank {
  final String name;
  final String description;
  final String logo;
  final String link;

  QPayBank({
    required this.name,
    required this.description,
    required this.logo,
    required this.link,
  });

  factory QPayBank.fromJson(Map<String, dynamic> json) {
    return QPayBank(
      name: json['name'] ?? '',
      description: json['description'] ?? '',
      logo: json['logo'] ?? '',
      link: json['link'] ?? '',
    );
  }
}

// VAT Receipt data models
class VATReceipt {
  final String id;
  final String qrData;
  final String? lottery;
  final double totalAmount;
  final double totalVAT;
  final double totalCityTax;
  final String districtCode;
  final String merchantTin;
  final String branchNo;
  final String posNo;
  final String type;
  final String date;
  final List<VATReceiptItem> receipts;
  final List<VATPayment> payments;
  final String nekhemjlekhiinId;
  final String gereeniiDugaar;
  final int utas;
  final String? receiptId;

  VATReceipt({
    required this.id,
    required this.qrData,
    this.lottery,
    required this.totalAmount,
    required this.totalVAT,
    required this.totalCityTax,
    required this.districtCode,
    required this.merchantTin,
    required this.branchNo,
    required this.posNo,
    required this.type,
    required this.date,
    required this.receipts,
    required this.payments,
    required this.nekhemjlekhiinId,
    required this.gereeniiDugaar,
    required this.utas,
    this.receiptId,
  });

  factory VATReceipt.fromJson(Map<String, dynamic> json) {
    return VATReceipt(
      id: json['_id'] ?? json['id'] ?? '',
      qrData: json['qrData'] ?? '',
      lottery: json['lottery'],
      totalAmount: (json['totalAmount'] ?? 0).toDouble(),
      totalVAT: (json['totalVAT'] ?? 0).toDouble(),
      totalCityTax: (json['totalCityTax'] ?? 0).toDouble(),
      districtCode: json['districtCode'] ?? '',
      merchantTin: json['merchantTin'] ?? '',
      branchNo: json['branchNo'] ?? '',
      posNo: json['posNo'] ?? '',
      type: json['type'] ?? '',
      date: json['date'] ?? '',
      receipts: json['receipts'] != null
          ? (json['receipts'] as List)
                .map((r) => VATReceiptItem.fromJson(r))
                .toList()
          : [],
      payments: json['payments'] != null
          ? (json['payments'] as List)
                .map((p) => VATPayment.fromJson(p))
                .toList()
          : [],
      nekhemjlekhiinId: json['nekhemjlekhiinId'] ?? '',
      gereeniiDugaar: json['gereeniiDugaar'] ?? '',
      utas: json['utas'] ?? '',
      receiptId: json['receiptId'],
    );
  }

  String get formattedAmount {
    final formatted = totalAmount
        .toStringAsFixed(2)
        .replaceAllMapped(
          RegExp(r'(\d)(?=(\d{3})+(?!\d))'),
          (match) => '${match[1]},',
        );
    return '$formatted₮';
  }

  String get formattedDate {
    try {
      final dateTime = DateTime.parse(date.replaceAll(' ', 'T'));
      return '${dateTime.year}.${dateTime.month.toString().padLeft(2, '0')}.${dateTime.day.toString().padLeft(2, '0')} ${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
    } catch (e) {
      return date;
    }
  }
}

class VATReceiptItem {
  final double totalAmount;
  final double totalVAT;
  final double totalCityTax;
  final String taxType;
  final String merchantTin;
  final List<VATItem> items;

  VATReceiptItem({
    required this.totalAmount,
    required this.totalVAT,
    required this.totalCityTax,
    required this.taxType,
    required this.merchantTin,
    required this.items,
  });

  factory VATReceiptItem.fromJson(Map<String, dynamic> json) {
    return VATReceiptItem(
      totalAmount: (json['totalAmount'] ?? 0).toDouble(),
      totalVAT: (json['totalVAT'] ?? 0).toDouble(),
      totalCityTax: (json['totalCityTax'] ?? 0).toDouble(),
      taxType: json['taxType'] ?? '',
      merchantTin: json['merchantTin'] ?? '',
      items: json['items'] != null
          ? (json['items'] as List).map((i) => VATItem.fromJson(i)).toList()
          : [],
    );
  }
}

class VATItem {
  final String name;
  final String barCodeType;
  final String classificationCode;
  final String measureUnit;
  final String qty;
  final String unitPrice;
  final String totalCityTax;
  final String totalAmount;

  VATItem({
    required this.name,
    required this.barCodeType,
    required this.classificationCode,
    required this.measureUnit,
    required this.qty,
    required this.unitPrice,
    required this.totalCityTax,
    required this.totalAmount,
  });

  factory VATItem.fromJson(Map<String, dynamic> json) {
    return VATItem(
      name: json['name'] ?? '',
      barCodeType: json['barCodeType'] ?? '',
      classificationCode: json['classificationCode'] ?? '',
      measureUnit: json['measureUnit'] ?? '',
      qty: json['qty']?.toString() ?? '0',
      unitPrice: json['unitPrice']?.toString() ?? '0',
      totalCityTax: json['totalCityTax']?.toString() ?? '0',
      totalAmount: json['totalAmount']?.toString() ?? '0',
    );
  }
}

class VATPayment {
  final String code;
  final String paidAmount;
  final String status;

  VATPayment({
    required this.code,
    required this.paidAmount,
    required this.status,
  });

  factory VATPayment.fromJson(Map<String, dynamic> json) {
    return VATPayment(
      code: json['code'] ?? '',
      paidAmount: json['paidAmount']?.toString() ?? '0',
      status: json['status'] ?? '',
    );
  }
}
