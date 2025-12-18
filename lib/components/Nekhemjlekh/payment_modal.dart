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

  const PaymentModal({
    super.key,
    required this.totalSelectedAmount,
    required this.selectedCount,
    required this.onPaymentTap,
    required this.invoices,
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

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: context.cardBackgroundColor,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(16.w),
          topRight: Radius.circular(16.w),
        ),
        border: Border.all(color: context.borderColor),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Header
          Container(
            padding: EdgeInsets.all(16.w),
            decoration: BoxDecoration(
              border: Border(bottom: BorderSide(color: context.borderColor)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Төлбөрийн мэдээлэл',
                  style: TextStyle(
                    color: context.textPrimaryColor,
                    fontSize: 18.sp,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                IconButton(
                  icon: Icon(
                    Icons.close,
                    color: context.textPrimaryColor,
                    size: 24.sp,
                  ),
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
                    color: context.accentBackgroundColor,
                    borderRadius: BorderRadius.circular(12.w),
                    border: Border.all(color: context.borderColor),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Төлөх дүн',
                        style: TextStyle(
                          fontSize: 14.sp,
                          color: context.textSecondaryColor,
                        ),
                      ),
                      Text(
                        widget.totalSelectedAmount,
                        style: TextStyle(
                          fontSize: 18.sp,
                          fontWeight: FontWeight.bold,
                          color: context.textPrimaryColor,
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
                    color: context.accentBackgroundColor,
                    borderRadius: BorderRadius.circular(12.w),
                    border: Border.all(color: context.borderColor),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Гэрээ',
                        style: TextStyle(
                          fontSize: 14.sp,
                          color: context.textSecondaryColor,
                        ),
                      ),
                      Text(
                        '${widget.selectedCount} гэрээ',
                        style: TextStyle(
                          fontSize: 16.sp,
                          fontWeight: FontWeight.w600,
                          color: context.textPrimaryColor,
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
                    onPressed: _isLoadingQPay
                        ? null
                        : () async {
                            await _createQPayAndShowBankList();
                          },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.deepGreen,
                      foregroundColor: Colors.white,
                      padding: EdgeInsets.symmetric(vertical: 14.h),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12.w),
                      ),
                    ),
                    child: _isLoadingQPay
                        ? SizedBox(
                            height: 20.h,
                            width: 20.w,
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
      double totalAmount = 0;
      String? turul;
      List<String> selectedInvoiceIds = [];

      // Calculate total amount and get invoice IDs
      for (var invoice in widget.invoices) {
        if (invoice.isSelected) {
          totalAmount += invoice.niitTulbur;
          selectedInvoiceIds.add(invoice.id);
          turul ??= invoice.gereeniiDugaar;
        }
      }

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
          );

          if (ownOrgResponse['qr_image'] != null) {
            setState(() {
              _qrImageOwnOrg = ownOrgResponse['qr_image']?.toString();
            });
          }

          // Try to load bank list from OWN_ORG response
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

      // Note: Wallet API QPay requires billingId + billIds, not dun + walletUserId
      // This modal is for OWN_ORG invoices, so we don't create Wallet QPay here
      // Wallet QPay should only be created from billing flow (total_balance_modal.dart)

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

      // Ensure we always show bank list BEFORE QR
      // If backend didn't return bank urls, at least show qPay wallet as an option.
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
}
