import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:sukh_app/constants/constants.dart';
import 'package:sukh_app/services/api_service.dart';
import 'package:sukh_app/services/storage_service.dart';
import 'package:sukh_app/components/Nekhemjlekh/nekhemjlekh_models.dart';
import 'package:sukh_app/components/Nekhemjlekh/vat_receipt_modal.dart';
import 'package:sukh_app/models/geree_model.dart';
import 'package:sukh_app/utils/theme_extensions.dart';

class EbarimtPage extends StatefulWidget {
  const EbarimtPage({super.key});

  @override
  State<EbarimtPage> createState() => _EbarimtPageState();
}

class _EbarimtPageState extends State<EbarimtPage> {
  bool _isLoadingReceipts = false;
  List<VATReceipt> _ebarimtReceipts = [];

  @override
  void initState() {
    super.initState();
    _loadEbarimtReceipts();
  }

  Future<void> _loadEbarimtReceipts() async {
    setState(() {
      _isLoadingReceipts = true;
    });

    try {
      final userId = await StorageService.getUserId();
      if (userId == null) {
        setState(() {
          _isLoadingReceipts = false;
        });
        return;
      }

      // Fetch contracts
      final gereeResponse = await ApiService.fetchGeree(userId);
      if (gereeResponse['jagsaalt'] == null ||
          (gereeResponse['jagsaalt'] as List).isEmpty) {
        setState(() {
          _isLoadingReceipts = false;
        });
        return;
      }

      final List<dynamic> gereeJagsaalt = gereeResponse['jagsaalt'];
      final List<VATReceipt> allReceipts = [];

      // Fetch invoices for each contract and get ebarimt receipts
      for (var contractData in gereeJagsaalt) {
        try {
          final geree = Geree.fromJson(contractData);
          final nekhemjlekhResponse = await ApiService.fetchNekhemjlekhiinTuukh(
            gereeniiDugaar: geree.gereeniiDugaar,
          );

          if (nekhemjlekhResponse['jagsaalt'] != null &&
              nekhemjlekhResponse['jagsaalt'] is List) {
            final List<dynamic> nekhemjlekhJagsaalt =
                nekhemjlekhResponse['jagsaalt'];

            // Get ebarimt for each invoice
            for (var invoice in nekhemjlekhJagsaalt) {
              try {
                final invoiceId = invoice['_id']?.toString() ?? '';
                if (invoiceId.isEmpty) continue;

                final ebarimtResponse =
                    await ApiService.fetchEbarimtJagsaaltAvya(
                      nekhemjlekhiinId: invoiceId,
                    );

                if (ebarimtResponse['jagsaalt'] != null &&
                    ebarimtResponse['jagsaalt'] is List) {
                  for (var item in ebarimtResponse['jagsaalt'] as List) {
                    if (item['nekhemjlekhiinId'] == invoiceId) {
                      allReceipts.add(VATReceipt.fromJson(item));
                    }
                  }
                }
              } catch (e) {
                // Skip if error fetching ebarimt for this invoice
                continue;
              }
            }
          }
        } catch (e) {
          // Skip if error fetching invoices for this contract
          continue;
        }
      }

      if (mounted) {
        setState(() {
          _ebarimtReceipts = allReceipts;
          _isLoadingReceipts = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoadingReceipts = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.backgroundColor,
      appBar: AppBar(
        backgroundColor: AppColors.deepGreen,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => context.pop(),
        ),
        title: const Text('И-Баримт', style: TextStyle(color: Colors.white)),
        centerTitle: true,
        elevation: 0,
      ),
      body: Column(
        children: [
          // Ebarimt Receipts List Header
          Container(
            padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
            decoration: BoxDecoration(
              color: context.cardBackgroundColor,
              border: Border(
                bottom: BorderSide(color: context.borderColor, width: 1),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'И-баримтууд (${_ebarimtReceipts.length})',
                  style: TextStyle(
                    color: context.textPrimaryColor,
                    fontSize: 16.sp,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                if (_isLoadingReceipts)
                  SizedBox(
                    width: 20.w,
                    height: 20.w,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: AppColors.deepGreen,
                    ),
                  ),
              ],
            ),
          ),
          // Ebarimt Receipts List
          Expanded(
            child: _isLoadingReceipts
                ? Center(
                    child: CircularProgressIndicator(
                      color: AppColors.deepGreen,
                    ),
                  )
                : _ebarimtReceipts.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.receipt_long_outlined,
                          size: 64.sp,
                          color: context.textSecondaryColor.withOpacity(0.5),
                        ),
                        SizedBox(height: 16.h),
                        Text(
                          'И-баримт олдсонгүй',
                          style: TextStyle(
                            color: context.textSecondaryColor,
                            fontSize: 16.sp,
                          ),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    padding: EdgeInsets.all(16.w),
                    itemCount: _ebarimtReceipts.length,
                    itemBuilder: (context, index) {
                      final receipt = _ebarimtReceipts[index];
                      return _buildReceiptCard(receipt);
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildReceiptCard(VATReceipt receipt) {
    final isDark = context.isDarkMode;
    return Container(
      margin: EdgeInsets.only(bottom: 12.h),
      decoration: BoxDecoration(
        color: context.cardBackgroundColor,
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(
          color: AppColors.deepGreen.withOpacity(isDark ? 0.3 : 0.2),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDark ? 0.3 : 0.05),
            blurRadius: 15,
            spreadRadius: 0,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            showModalBottomSheet(
              context: context,
              isScrollControlled: true,
              backgroundColor: Colors.transparent,
              builder: (context) => VATReceiptModal(receipt: receipt),
            );
          },
          borderRadius: BorderRadius.circular(12.r),
          child: Padding(
            padding: EdgeInsets.all(16.w),
            child: Row(
              children: [
                Container(
                  width: 48.w,
                  height: 48.w,
                  decoration: BoxDecoration(
                    color: AppColors.deepGreen.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8.r),
                  ),
                  child: Icon(
                    Icons.receipt_long,
                    color: AppColors.deepGreen,
                    size: 24.sp,
                  ),
                ),
                SizedBox(width: 12.w),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'И-баримт',
                        style: TextStyle(
                          color: context.textPrimaryColor,
                          fontSize: 15.sp,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(height: 4.h),
                      Text(
                        receipt.formattedDate,
                        style: TextStyle(
                          color: context.textSecondaryColor,
                          fontSize: 12.sp,
                        ),
                      ),
                      SizedBox(height: 4.h),
                      Text(
                        receipt.formattedAmount,
                        style: TextStyle(
                          color: AppColors.deepGreen,
                          fontSize: 14.sp,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(
                  Icons.chevron_right,
                  color: context.textSecondaryColor,
                  size: 24.sp,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
