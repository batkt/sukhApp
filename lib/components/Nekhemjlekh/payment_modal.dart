import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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
    final screenWidth = MediaQuery.of(context).size.width;
    final isTablet = screenWidth > 600;
    final modalWidth = isTablet ? 500.0 : screenWidth;
    
    return DraggableScrollableSheet(
      initialChildSize: 0.6,
      minChildSize: 0.4,
      maxChildSize: 0.95,
      builder: (_, scrollController) => Container(
        width: modalWidth,
        decoration: BoxDecoration(
          color: context.backgroundColor,
          borderRadius: BorderRadius.vertical(top: Radius.circular(36.r)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.15),
              blurRadius: 40,
              offset: const Offset(0, -10),
            ),
          ],
        ),
        child: Column(
          children: [
            // Handle bar
            Container(
              margin: EdgeInsets.only(top: 14.h),
              width: 44.w,
              height: 5.h,
              decoration: BoxDecoration(
                color: context.isDarkMode
                    ? Colors.white.withOpacity(0.15)
                    : Colors.black.withOpacity(0.1),
                borderRadius: BorderRadius.circular(10.r),
              ),
            ),
            
            // Header
            Padding(
              padding: EdgeInsets.fromLTRB(28.w, 20.h, 28.w, 10.h),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Төлбөрийн мэдээлэл',
                    style: TextStyle(
                      color: context.textPrimaryColor,
                      fontSize: 20.sp,
                      fontWeight: FontWeight.w500,
                      letterSpacing: -0.5,
                    ),
                  ),
                  GestureDetector(
                    onTap: () => Navigator.of(context).pop(),
                    child: Container(
                      padding: EdgeInsets.all(8.w),
                      decoration: BoxDecoration(
                        color: context.isDarkMode ? Colors.white.withOpacity(0.05) : Colors.black.withOpacity(0.05),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.close_rounded,
                        color: context.textSecondaryColor,
                        size: 18.sp,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            
            Expanded(
              child: ListView(
                controller: scrollController,
                padding: EdgeInsets.symmetric(horizontal: 28.w, vertical: 20.h),
                physics: const BouncingScrollPhysics(),
                children: [
                  // Summary Card
                  Container(
                    padding: EdgeInsets.all(24.w),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: context.isDarkMode 
                            ? [AppColors.deepGreen.withOpacity(0.15), AppColors.deepGreen.withOpacity(0.05)]
                            : [AppColors.deepGreen.withOpacity(0.08), AppColors.deepGreen.withOpacity(0.02)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(28.r),
                      border: Border.all(
                        color: AppColors.deepGreen.withOpacity(0.2),
                        width: 1.5,
                      ),
                    ),
                    child: Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Нийт төлөх',
                              style: TextStyle(
                                fontSize: 13.sp,
                                fontWeight: FontWeight.w500,
                                color: context.textSecondaryColor,
                                letterSpacing: 0.5,
                              ),
                            ),
                            Container(
                              padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 6.h),
                              decoration: BoxDecoration(
                                color: AppColors.deepGreen.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(100),
                              ),
                              child: Text(
                                '${widget.selectedCount} нэхэмжлэх',
                                style: TextStyle(
                                  fontSize: 10.sp,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.deepGreen,
                                ),
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: 12.h),
                        Row(
                          children: [
                            Text(
                              widget.totalSelectedAmount,
                              style: TextStyle(
                                fontSize: 28.sp,
                                fontWeight: FontWeight.w600,
                                color: AppColors.deepGreen,
                                letterSpacing: -0.5,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  
                  SizedBox(height: 32.h),
                  _buildVATSelector(context),
                  SizedBox(height: 40.h),
                  
                  // Payment button
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    width: double.infinity,
                    height: 56.h,
                    child: ElevatedButton(
                      onPressed: _isLoadingQPay
                          ? null
                          : () => _createQPayAndShowBankList(),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.transparent,
                        shadowColor: Colors.transparent,
                        padding: EdgeInsets.zero,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20.r),
                        ),
                      ),
                      child: Ink(
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [AppColors.deepGreen, Color(0xFF10B981)],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(20.r),
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.deepGreen.withOpacity(0.35),
                              blurRadius: 15,
                              offset: const Offset(0, 8),
                            ),
                          ],
                        ),
                        child: Container(
                          alignment: Alignment.center,
                          child: _isLoadingQPay
                              ? SizedBox(
                                  height: 20.h,
                                  width: 20.h,
                                  child: const CircularProgressIndicator(
                                    strokeWidth: 2.5,
                                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                  ),
                                )
                              : Text(
                                  'ТӨЛБӨР ТӨЛӨХ',
                                  style: TextStyle(
                                    fontSize: 14.sp,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.white,
                                    letterSpacing: 1.0,
                                  ),
                                ),
                        ),
                      ),
                    ),
                  ),
                  SizedBox(height: 20.h),
                ],
              ),
            ),
          ],
        ),
      ),
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
      if (_vatReceiveType == 'COMPANY') {
        final rDText = _vatTinController.text.trim();
        if (rDText.isEmpty) {
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

        final isNumeric = RegExp(r'^[0-9]+$').hasMatch(rDText);
        if (rDText.length != 7 || !isNumeric) {
          if (mounted) {
            showGlassSnackBar(
              context,
              message: 'Байгууллагын РД алдаатай байна (7 оронтой тоо оруулна уу)',
              icon: Icons.error_outline,
              iconColor: Colors.red,
            );
          }
          setState(() => _isLoadingQPay = false);
          return;
        }
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
            
        // Don't send synthetic IDs to the backend, it will cause 404 in webhooks
        if (!firstInvoice.id.startsWith('synthetic-balance')) {
          firstInvoiceId = firstInvoice.id;
        }
      }

      // Check for OWN_ORG and WALLET addresses
      final ownOrgBaiguullagiinId = await StorageService.getBaiguullagiinId();
      final ownOrgBarilgiinId = await StorageService.getBarilgiinId();
      final walletBairId = await StorageService.getWalletBairId();
      final walletSource = await StorageService.getWalletBairSource();

      final hasOwnOrg =
          ownOrgBaiguullagiinId != null && ownOrgBarilgiinId != null;
      final hasWallet = walletBairId != null && (walletSource == 'WALLET_API' || walletSource == 'WALLET_QPAY');

      // Create QPay invoice (Auto-detect source)
      Map<String, dynamic>? finalResponse;

      if (hasOwnOrg || hasWallet) {
        try {
          if (hasWallet && !hasOwnOrg) {
            // Pure Wallet flow
            finalResponse = await ApiService.createWalletQPayPayment(
              billingId: widget.invoices.first.billingId,
              billIds: selectedInvoiceIds,
              vatReceiveType: _vatReceiveType,
              vatCompanyReg: _vatReceiveType == 'COMPANY' ? _vatTinController.text : null,
            );
          } else {
            // Own Org or Hybrid flow (via qpayGargaya which auto-detects)
            finalResponse = await ApiService.qpayGargaya(
              baiguullagiinId: ownOrgBaiguullagiinId,
              barilgiinId: ownOrgBarilgiinId,
              dun: totalAmount,
              turul: turul,
              nekhemjlekhiinId: firstInvoiceId,
              dansniiDugaar: dansniiDugaar,
              burtgeliinDugaar: burtgeliinDugaar,
              customerTin: _vatReceiveType == 'COMPANY' ? _vatTinController.text : null,
            );
          }

          if (finalResponse != null && finalResponse['qr_image'] != null) {
            setState(() {
              final source = finalResponse!['source']?.toString();
              if (source == 'WALLET_API' || source == 'WALLET_QPAY') {
                _qrImageWallet = finalResponse!['qr_image']?.toString();
              } else {
                _qrImageOwnOrg = finalResponse!['qr_image']?.toString();
              }
              
              _senderInvoiceNoForSocket = 
                  finalResponse!['walletPaymentId']?.toString() ?? 
                  finalResponse!['sender_invoice_no']?.toString() ??
                  finalResponse!['invoice_id']?.toString();
            });

            if (finalResponse['urls'] != null && finalResponse['urls'] is List) {
              final banks = (finalResponse['urls'] as List)
                  .map((e) => QPayBank.fromJson(e as Map<String, dynamic>))
                  .toList();
              setState(() {
                _qpayBanks = banks;
              });
            }
          }
        } catch (e) {

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
                urls: _qpayBanks.map((b) => {'name': b.name, 'description': b.description, 'logo': b.logo, 'link': b.link}).toList(),
                walletPaymentId: finalResponse?['walletPaymentId']?.toString(),
                invoiceNumber: _senderInvoiceNoForSocket,
                amount: totalAmount,
                onCheckPaymentAsync: () async {
                  final wId = finalResponse?['walletPaymentId']?.toString();
                  if (wId != null && wId.isNotEmpty) {
                    // New high-fidelity check via backend poll
                    return await ApiService.checkWalletQPayStatus(walletPaymentId: wId);
                  }

                  // Fallback: Legacy check (History list)
                  await widget.onPaymentTap();
                  if (_gereeniiDugaarForCheck == null || _gereeniiDugaarForCheck!.isEmpty || _selectedInvoiceIdsForCheck.isEmpty) {
                    return null;
                  }
                  try {
                    final resp = await ApiService.fetchNekhemjlekhiinTuukh(
                      gereeniiDugaar: _gereeniiDugaarForCheck!,
                      khuudasniiKhemjee: 10,
                    );
                    final list = resp['jagsaalt'] as List<dynamic>? ?? [];
                    final byId = {for (var item in list) item['_id']?.toString(): item};
                    return _selectedInvoiceIdsForCheck.every((id) => byId[id]?['tuluv'] == 'Төлсөн');
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
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: EdgeInsets.only(left: 4.w, bottom: 12.h),
          child: Text(
            'И-баримт хүлээн авах',
            style: TextStyle(
              fontSize: 13.sp,
              fontWeight: FontWeight.w800,
              color: context.textPrimaryColor.withOpacity(0.9),
              letterSpacing: 0.2,
            ),
          ),
        ),
        Container(
          padding: EdgeInsets.all(6.w),
          decoration: BoxDecoration(
            color: context.isDarkMode ? Colors.white.withOpacity(0.06) : Colors.black.withOpacity(0.04),
            borderRadius: BorderRadius.circular(20.r),
          ),
          child: Row(
            children: [
              Expanded(
                child: _buildVatOption(
                  context,
                  title: 'Хувь хүн',
                  isSelected: _vatReceiveType == 'CITIZEN',
                  onTap: () => setState(() => _vatReceiveType = 'CITIZEN'),
                ),
              ),
              SizedBox(width: 6.w),
              Expanded(
                child: _buildVatOption(
                  context,
                  title: 'Байгууллага',
                  isSelected: _vatReceiveType == 'COMPANY',
                  onTap: () => setState(() => _vatReceiveType = 'COMPANY'),
                ),
              ),
            ],
          ),
        ),
        if (_vatReceiveType == 'COMPANY') ...[
          SizedBox(height: 20.h),
          TweenAnimationBuilder<double>(
            tween: Tween(begin: 0.0, end: 1.0),
            duration: const Duration(milliseconds: 300),
            builder: (context, value, child) {
              return Opacity(
                opacity: value,
                child: Transform.translate(
                  offset: Offset(0, 10 * (1 - value)),
                  child: child,
                ),
              );
            },
            child: TextField(
              controller: _vatTinController,
              keyboardType: TextInputType.number,
              style: TextStyle(
                fontSize: 14.sp,
                fontWeight: FontWeight.w600,
                color: context.textPrimaryColor,
              ),
              decoration: InputDecoration(
                hintText: 'Байгууллагын РД оруулна уу',
                hintStyle: TextStyle(
                  fontSize: 13.sp,
                  color: context.textSecondaryColor.withOpacity(0.4),
                ),
                prefixIcon: Icon(Icons.business_rounded, 
                    size: 18.sp, color: AppColors.deepGreen.withOpacity(0.6)),
                contentPadding: EdgeInsets.symmetric(
                  horizontal: 20.w,
                  vertical: 16.h,
                ),
                filled: true,
                fillColor: context.isDarkMode
                    ? Colors.white.withOpacity(0.05)
                    : Colors.black.withOpacity(0.02),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(18.r),
                  borderSide: BorderSide.none,
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(18.r),
                  borderSide: BorderSide(
                    color: context.borderColor.withOpacity(0.1),
                    width: 1,
                  ),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(18.r),
                  borderSide: const BorderSide(
                    color: AppColors.deepGreen,
                    width: 1.5,
                  ),
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
    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        onTap();
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOutCubic,
        padding: EdgeInsets.symmetric(vertical: 12.h),
        decoration: BoxDecoration(
          gradient: isSelected
              ? const LinearGradient(
                  colors: [AppColors.deepGreen, Color(0xFF10B981)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                )
              : null,
          borderRadius: BorderRadius.circular(16.r),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: AppColors.deepGreen.withOpacity(0.3),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  )
                ]
              : null,
        ),
        child: Center(
          child: Text(
            title,
            style: TextStyle(
              fontSize: 13.sp,
              fontWeight: isSelected ? FontWeight.w900 : FontWeight.w600,
              color: isSelected ? Colors.white : context.textSecondaryColor,
            ),
          ),
        ),
      ),
    );
  }
}
