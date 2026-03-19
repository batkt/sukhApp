import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:sukh_app/constants/constants.dart';
import 'package:sukh_app/utils/theme_extensions.dart';
import 'package:sukh_app/services/api_service.dart';
import 'package:sukh_app/services/storage_service.dart';
import 'package:sukh_app/widgets/glass_snackbar.dart';
import 'package:sukh_app/components/Nekhemjlekh/qpay_qr_modal.dart';
import 'package:sukh_app/components/Nekhemjlekh/nekhemjlekh_models.dart';
import 'package:sukh_app/components/Nekhemjlekh/bank_selection_modal.dart';
import 'package:url_launcher/url_launcher.dart';

class PaymentModal extends StatefulWidget {
  final String totalSelectedAmount;
  final int selectedCount;
  final Future<void> Function() onPaymentTap;
  final List<NekhemjlekhItem> invoices;
  /// When all unpaid are selected, use this (globalUldegdel) for payment amount
  final double? contractUldegdel;

  const PaymentModal({
    super.key,
    required this.totalSelectedAmount,
    required this.selectedCount,
    required this.onPaymentTap,
    required this.invoices,
    this.contractUldegdel,
  });

  @override
  State<PaymentModal> createState() => _PaymentModalState();
}

class _PaymentModalState extends State<PaymentModal> {
  bool _isLoadingQPay = false;
  String? _qrImageOwnOrg;
  String? _qrImageWallet;
  List<QPayBank> _qpayBanks = [];
  List<String> _selectedInvoiceIdsForCheck = [];
  String? _gereeniiDugaarForCheck;
  String? _senderInvoiceNoForSocket;
  String _vatReceiveType = 'CITIZEN';
  final TextEditingController _vatTinController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    // For tablets/iPads, limit width and center the modal
    final screenWidth = MediaQuery.of(context).size.width;
    final isTablet = screenWidth > 600;
    final modalWidth = isTablet ? 500.0 : screenWidth;
    
    return LayoutBuilder(
      builder: (context, constraints) {
        return Center(
          child: Container(
            width: modalWidth,
            height: constraints.maxHeight * 1,
            decoration: BoxDecoration(
              color: context.isDarkMode
                  ? const Color(0xFF1A1A1A)
                  : Colors.white,
              borderRadius: isTablet
                  ? BorderRadius.circular(16.r)
                  : BorderRadius.only(
                      topLeft: Radius.circular(16.r),
                      topRight: Radius.circular(16.r),
                    ),
              border: Border.all(
                color: context.isDarkMode
                    ? Colors.white.withOpacity(0.1)
                    : Colors.black.withOpacity(0.08),
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
                        ? Colors.white.withOpacity(0.3)
                        : Colors.black.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(2.r),
                  ),
                ),
                // Header
                Container(
                  padding: EdgeInsets.all(14.w),
                  decoration: BoxDecoration(
                    border: Border(
                      bottom: BorderSide(
                        color: context.isDarkMode
                            ? Colors.white.withOpacity(0.1)
                            : Colors.black.withOpacity(0.08),
                      ),
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Төлбөрийн мэдээлэл',
                        style: TextStyle(
                          color: context.textPrimaryColor,
                          fontSize: 14.sp,
                        ),
                      ),
                      IconButton(
                        icon: Icon(
                          Icons.close,
                          color: context.textSecondaryColor,
                          size: 20.sp,
                        ),
                        onPressed: () => Navigator.of(context).pop(),
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                      ),
                    ],
                  ),
                ),
                // Content
                Expanded(
                  child: SingleChildScrollView(
                    padding: EdgeInsets.all(14.w),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Price information panel
                        Container(
                          padding: EdgeInsets.all(12.w),
                          decoration: BoxDecoration(
                            color: context.isDarkMode
                                ? Colors.white.withOpacity(0.05)
                                : const Color(0xFFF8F8F8),
                            borderRadius: BorderRadius.circular(10.r),
                            border: Border.all(
                              color: context.isDarkMode
                                  ? AppColors.deepGreen.withOpacity(0.15)
                                  : AppColors.deepGreen.withOpacity(0.1),
                            ),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'Төлөх дүн',
                                style: TextStyle(
                                  fontSize: 11.sp,
                                  color: context.textSecondaryColor,
                                ),
                              ),
                              Text(
                                widget.totalSelectedAmount,
                                style: TextStyle(
                                  fontSize: 14.sp,
                                  color: AppColors.deepGreen,
                                ),
                              ),
                            ],
                          ),
                        ),
                        SizedBox(height: 8.h),
                        // Contract information panel
                        Container(
                          padding: EdgeInsets.all(12.w),
                          decoration: BoxDecoration(
                            color: context.isDarkMode
                                ? Colors.white.withOpacity(0.05)
                                : const Color(0xFFF8F8F8),
                            borderRadius: BorderRadius.circular(10.r),
                            border: Border.all(
                              color: context.isDarkMode
                                  ? Colors.white.withOpacity(0.1)
                                  : Colors.black.withOpacity(0.08),
                            ),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'Гэрээ',
                                style: TextStyle(
                                  fontSize: 11.sp,
                                  color: context.textSecondaryColor,
                                ),
                              ),
                              Text(
                                '${widget.selectedCount} гэрээ',
                                style: TextStyle(
                                  fontSize: 12.sp,
                                  color: context.textPrimaryColor,
                                ),
                              ),
                            ],
                          ),
                        ),
                        SizedBox(height: 14.h),
                        _buildVATSelector(context),
                        SizedBox(height: 14.h),
                        // Payment button
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: _isLoadingQPay
                                ? null
                                : () async {
                                    await _createQPayAndShowBankList();
                                  },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.deepGreen,
                              foregroundColor: Colors.white,
                              padding: EdgeInsets.symmetric(vertical: 12.h),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10.r),
                              ),
                            ),
                            child: _isLoadingQPay
                                ? SizedBox(
                                    height: 16.h,
                                    width: 16.w,
                                    child: const CircularProgressIndicator(
                                      strokeWidth: 2,
                                      valueColor: AlwaysStoppedAnimation<Color>(
                                        Colors.white,
                                      ),
                                    ),
                                  )
                                : Text(
                                    'Төлбөр төлөх',
                                    style: TextStyle(
                                      fontSize: 12.sp,
                                    ),
                                  ),
                          ),
                        ),
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

  Future<void> _createQPayAndShowBankList() async {
    setState(() {
      _isLoadingQPay = true;
      _qrImageOwnOrg = null;
      _qrImageWallet = null;
      _qpayBanks = [];
      _selectedInvoiceIdsForCheck = [];
      _gereeniiDugaarForCheck = null;
    });

    try {
      if (_vatReceiveType == 'COMPANY' && _vatTinController.text.isEmpty) {
        if (mounted) {
          showGlassSnackBar(
            context,
            message: 'Байгууллагын РД оруулна уу',
            icon: Icons.info_outline,
            iconColor: AppColors.deepGreenAccent,
          );
        }
        setState(() => _isLoadingQPay = false);
        return;
      }

      String? turul;
      List<String> selectedInvoiceIds = [];

      for (var invoice in widget.invoices) {
        if (invoice.isSelected) {
          selectedInvoiceIds.add(invoice.id);
          turul ??= invoice.gereeniiDugaar;
        }
      }

      // Use contract's globalUldegdel (same as HistoryModal) - single source of truth
      double totalAmount = (widget.contractUldegdel != null && widget.contractUldegdel! > 0)
          ? widget.contractUldegdel!
          : 0;

      _selectedInvoiceIdsForCheck = selectedInvoiceIds;
      _gereeniiDugaarForCheck = turul;

      if (selectedInvoiceIds.isEmpty) {
        throw Exception('Нэхэмжлэх сонгоогүй байна');
      }

      if (turul == null || turul.isEmpty) {
        throw Exception('Гэрээний дугаар олдсонгүй');
      }

      // Get invoice details for Custom QPay
      String? dansniiDugaar;
      String? burtgeliinDugaar;
      String? firstInvoiceId;

      if (selectedInvoiceIds.isNotEmpty) {
        final firstInvoice = widget.invoices.firstWhere(
          (inv) => inv.id == selectedInvoiceIds.first,
          orElse: () => widget.invoices.firstWhere((inv) => inv.isSelected),
        );
        dansniiDugaar = firstInvoice.dansniiDugaar.isNotEmpty
            ? firstInvoice.dansniiDugaar
            : null;
        burtgeliinDugaar = firstInvoice.register.isNotEmpty
            ? firstInvoice.register
            : null;
        firstInvoiceId = firstInvoice.id;
      }

      // Check for OWN_ORG and WALLET addresses
      final ownOrgBaiguullagiinId = await StorageService.getBaiguullagiinId();
      final ownOrgBarilgiinId = await StorageService.getBarilgiinId();
      final walletBairId = await StorageService.getWalletBairId();
      final walletSource = await StorageService.getWalletBairSource();

      final hasOwnOrg =
          ownOrgBaiguullagiinId != null && ownOrgBarilgiinId != null;
      final hasWallet = walletBairId != null && walletSource == 'WALLET_API';

      // Create OWN_ORG QPay invoice (Custom QPay)
      if (hasOwnOrg) {
        try {
          final ownOrgResponse = await ApiService.qpayGargaya(
            baiguullagiinId: ownOrgBaiguullagiinId,
            barilgiinId: ownOrgBarilgiinId,
            dun: totalAmount,
            turul: turul,
            nekhemjlekhiinId: firstInvoiceId,
            dansniiDugaar: dansniiDugaar,
            burtgeliinDugaar: burtgeliinDugaar,
            customerTin: _vatReceiveType == 'COMPANY' ? _vatTinController.text : null,
          );

          if (ownOrgResponse['qr_image'] != null) {
            setState(() {
              _qrImageOwnOrg = ownOrgResponse['qr_image']?.toString();
              _senderInvoiceNoForSocket = ownOrgResponse['sender_invoice_no']?.toString();
            });
          }

          if (ownOrgResponse['urls'] != null &&
              ownOrgResponse['urls'] is List) {
            final banks = (ownOrgResponse['urls'] as List)
                .map((e) => QPayBank.fromJson(e as Map<String, dynamic>))
                .toList();
            setState(() {
              _qpayBanks = banks;
            });
          }
        } catch (e) {
          print('Error creating OWN_ORG QPay invoice: $e');
        }
      }

      if (_qrImageOwnOrg == null && _qrImageWallet == null) {
        if (mounted) {
          showGlassSnackBar(
            context,
            message: 'QR код үүсгэхэд алдаа гарлаа',
            icon: Icons.error,
            iconColor: Colors.red,
          );
        }
        return;
      }

      final hasQPayWalletTile = _qpayBanks.any(
        (b) =>
            b.description.contains('qPay хэтэвч') ||
            b.name.toLowerCase().contains('qpay wallet'),
      );
      if (!hasQPayWalletTile) {
        _qpayBanks = [
          ..._qpayBanks,
          QPayBank(
            name: 'QPay Wallet',
            description: 'qPay хэтэвч',
            logo: '',
            link: '',
          ),
        ];
      }

      if (!mounted) return;

      Navigator.pop(context); // Close payment modal
      await Future.delayed(const Duration(milliseconds: 120));

      if (!mounted) return;

      showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (context) => BankSelectionModal(
          qpayBanks: _qpayBanks,
          isLoadingQPay: false,
          onBankTap: (bank) async {
            // Open selected bank app link (deep link)
            if (bank.link.isEmpty) return;
            final uri = Uri.tryParse(bank.link);
            if (uri == null) return;
            try {
              await launchUrl(uri, mode: LaunchMode.externalApplication);
            } catch (_) {
              // ignore
            }
          },
          onQPayWalletTap: () async {
            // Close bank list then show QR
            Navigator.of(context).pop();
            await Future.delayed(const Duration(milliseconds: 80));
            if (!mounted) return;
            showDialog(
              context: context,
              builder: (context) => QPayQRModal(
                qrImageOwnOrg: _qrImageOwnOrg,
                qrImageWallet: _qrImageWallet,
                invoiceNumber: _senderInvoiceNoForSocket,
                onCheckPaymentAsync: () async {
                  // Refresh invoice list first (caller handles it)
                  await widget.onPaymentTap();

                  // Now check whether selected invoices became paid
                  if (_gereeniiDugaarForCheck == null ||
                      _gereeniiDugaarForCheck!.isEmpty ||
                      _selectedInvoiceIdsForCheck.isEmpty) {
                    return null;
                  }

                  try {
                    final resp = await ApiService.fetchNekhemjlekhiinTuukh(
                      gereeniiDugaar: _gereeniiDugaarForCheck!,
                      khuudasniiKhemjee: 200,
                    );

                    final list = resp['jagsaalt'];
                    if (list is! List) return null;

                    final byId = <String, Map<String, dynamic>>{};
                    for (final item in list) {
                      if (item is Map<String, dynamic>) {
                        final id = item['_id']?.toString();
                        if (id != null && id.isNotEmpty) byId[id] = item;
                      }
                    }

                    final allPaid = _selectedInvoiceIdsForCheck.every((id) {
                      final item = byId[id];
                      final status = item?['tuluv']?.toString();
                      return status == 'Төлсөн';
                    });

                    return allPaid;
                  } catch (_) {
                    return null;
                  }
                },
              ),
            );
          },
        ),
      );
    } catch (e) {
      if (mounted) {
        showGlassSnackBar(
          context,
          message: 'Төлбөр үүсгэхэд алдаа гарлаа: $e',
          icon: Icons.error,
          iconColor: Colors.red,
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoadingQPay = false;
        });
      }
    }
  }

  Widget _buildVATSelector(BuildContext context) {
    final isDark = context.isDarkMode;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: EdgeInsets.only(bottom: 8.h),
          child: Text(
            'И-баримт хүлээн авах',
            style: TextStyle(
              fontSize: 11.sp,
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
            SizedBox(width: 8.w),
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
          SizedBox(height: 10.h),
          TextField(
            controller: _vatTinController,
            keyboardType: TextInputType.number,
            style: TextStyle(
              fontSize: 12.sp,
              color: context.textPrimaryColor,
            ),
            decoration: InputDecoration(
              hintText: 'Байгууллагын РД оруулна уу',
              hintStyle: TextStyle(
                fontSize: 11.sp,
                color: context.textSecondaryColor.withOpacity(0.5),
              ),
              contentPadding: EdgeInsets.symmetric(
                horizontal: 10.w,
                vertical: 8.h,
              ),
              filled: true,
              fillColor: isDark
                  ? Colors.white.withOpacity(0.05)
                  : Colors.black.withOpacity(0.03),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8.r),
                borderSide: BorderSide(
                  color: context.borderColor.withOpacity(0.5),
                ),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8.r),
                borderSide: BorderSide(
                  color: context.borderColor.withOpacity(0.3),
                ),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8.r),
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
          borderRadius: BorderRadius.circular(8.r),
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
              fontSize: 11.sp,
              color: isSelected ? AppColors.deepGreen : context.textSecondaryColor,
            ),
          ),
        ),
      ),
    );
  }
}
