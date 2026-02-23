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
import 'package:sukh_app/utils/responsive_helper.dart';

class EbarimtPage extends StatefulWidget {
  const EbarimtPage({super.key});

  @override
  State<EbarimtPage> createState() => _EbarimtPageState();
}

class _EbarimtPageState extends State<EbarimtPage> {
  bool _isLoadingReceipts = false;
  List<VATReceipt> _ebarimtReceipts = [];
  final TextEditingController _citizenCodeController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _isSearching = false;
  Map<String, dynamic>? _consumerInfo;
  Map<String, dynamic>? _foreignerInfo;
  String? _infoType; // 'consumer' or 'foreigner'

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
  void dispose() {
    _citizenCodeController.dispose();
    super.dispose();
  }

  Future<void> _searchConsumerInfo() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isSearching = true;
      _consumerInfo = null;
      _foreignerInfo = null;
      _infoType = null;
    });

    try {
      final identity = _citizenCodeController.text.trim();
      print('🔍 [EBARIMT] Starting search for identity: $identity');

      // Try consumer first
      try {
        print('🔍 [EBARIMT] Attempting consumer lookup...');
        final consumerData = await ApiService.getConsumerInfo(
          identity: identity,
        );
        print('✅ [EBARIMT] Consumer data received: $consumerData');
        print('🔍 [EBARIMT] Consumer data keys: ${consumerData.keys.toList()}');
        print('🔍 [EBARIMT] Consumer data isEmpty: ${consumerData.isEmpty}');

        if (mounted) {
          setState(() {
            _consumerInfo = consumerData;
            _foreignerInfo = null;
            _infoType = 'consumer';
            _isSearching = false;
          });
          print(
            '✅ [EBARIMT] Consumer info set in state. _consumerInfo: $_consumerInfo',
          );
        }
        return;
      } catch (e) {
        print('❌ [EBARIMT] Consumer lookup failed: $e');
        // If consumer not found, try foreigner
        if (e.toString().contains('олдсонгүй') ||
            e.toString().contains('404')) {
          print('🔍 [EBARIMT] Consumer not found, trying foreigner lookup...');
          try {
            final foreignerData = await ApiService.getForeignerInfo(
              identity: identity,
            );
            print('✅ [EBARIMT] Foreigner data received: $foreignerData');
            print(
              '🔍 [EBARIMT] Foreigner data keys: ${foreignerData.keys.toList()}',
            );
            print(
              '🔍 [EBARIMT] Foreigner data isEmpty: ${foreignerData.isEmpty}',
            );

            if (mounted) {
              setState(() {
                _foreignerInfo = foreignerData;
                _consumerInfo = null;
                _infoType = 'foreigner';
                _isSearching = false;
              });
              print(
                '✅ [EBARIMT] Foreigner info set in state. _foreignerInfo: $_foreignerInfo',
              );
            }
            return;
          } catch (e2) {
            print('❌ [EBARIMT] Foreigner lookup failed: $e2');
            // If foreigner also not found, try by login name
            try {
              print('🔍 [EBARIMT] Trying foreigner lookup by login name...');
              final foreignerData =
                  await ApiService.getForeignerInfoByLoginName(
                    loginName: identity,
                  );
              print(
                '✅ [EBARIMT] Foreigner data by login name received: $foreignerData',
              );
              print(
                '🔍 [EBARIMT] Foreigner data keys: ${foreignerData.keys.toList()}',
              );
              print(
                '🔍 [EBARIMT] Foreigner data isEmpty: ${foreignerData.isEmpty}',
              );

              if (mounted) {
                setState(() {
                  _foreignerInfo = foreignerData;
                  _consumerInfo = null;
                  _infoType = 'foreigner';
                  _isSearching = false;
                });
                print(
                  '✅ [EBARIMT] Foreigner info (by login) set in state. _foreignerInfo: $_foreignerInfo',
                );
              }
              return;
            } catch (e3) {
              print('❌ [EBARIMT] All lookup methods failed. Last error: $e3');
              // Both failed
              throw e;
            }
          }
        } else {
          rethrow;
        }
      }
    } catch (e) {
      print('❌ [EBARIMT] Final error in search: $e');
      if (mounted) {
        setState(() {
          _isSearching = false;
          _consumerInfo = null;
          _foreignerInfo = null;
          _infoType = null;
        });
        print(
          '🔍 [EBARIMT] State cleared. _consumerInfo: $_consumerInfo, _foreignerInfo: $_foreignerInfo',
        );
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              e.toString().replaceAll("", ""),
            ),
            backgroundColor: Colors.red,
          ),
        );
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
          // Citizen Code Input Section
          Container(
            padding: EdgeInsets.all(16.w),
            decoration: BoxDecoration(
              color: context.cardBackgroundColor,
              border: Border(
                bottom: BorderSide(color: context.borderColor, width: 1),
              ),
            ),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Иргэний мэдээлэл',
                    style: TextStyle(
                      color: context.textPrimaryColor,
                      fontSize: 14.sp,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 12.h),
                  Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller: _citizenCodeController,
                          keyboardType: TextInputType.text,
                          decoration: InputDecoration(
                            hintText: 'Регистр/Паспорт дугаар эсвэл логин нэр',
                            prefixIcon: const Icon(Icons.person_outline),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10.r),
                            ),
                          ),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Кодоо оруулна уу';
                            }
                            return null;
                          },
                        ),
                      ),
                      SizedBox(width: 12.w),
                      ElevatedButton(
                        onPressed: _isSearching ? null : _searchConsumerInfo,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.deepGreen,
                          padding: EdgeInsets.symmetric(
                            horizontal: 20.w,
                            vertical: 16.h,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10.r),
                          ),
                        ),
                        child: _isSearching
                            ? SizedBox(
                                width: 20.w,
                                height: 20.w,
                                child: const CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : const Text(
                                'Хайх',
                                style: TextStyle(color: Colors.white),
                              ),
                      ),
                    ],
                  ),
                  // Display consumer/foreigner info
                  if (_consumerInfo != null || _foreignerInfo != null) ...[
                    SizedBox(height: 16.h),
                    _buildInfoCard(),
                  ],
                ],
              ),
            ),
          ),
          // Ebarimt Receipts List Header
          Container(
            padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Илгээгдсэн и-баримтууд (${_ebarimtReceipts.length})',
                  style: TextStyle(
                    color: context.textPrimaryColor,
                    fontSize: 15.sp,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                if (_isLoadingReceipts)
                  SizedBox(
                    width: 18.w,
                    height: 18.w,
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
                          'Илгээгдсэн и-баримт олдсонгүй',
                          style: TextStyle(
                            color: context.textSecondaryColor,
                            fontSize: 16.sp,
                          ),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    padding: EdgeInsets.symmetric(horizontal: 16.w),
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
      margin: EdgeInsets.only(
        bottom: context.responsiveSpacing(
          small: 12,
          medium: 14,
          large: 16,
          tablet: 18,
          veryNarrow: 8,
        ),
      ),
      decoration: BoxDecoration(
        color: context.cardBackgroundColor,
        borderRadius: BorderRadius.circular(
          context.responsiveBorderRadius(
            small: 16,
            medium: 18,
            large: 20,
            tablet: 22,
            veryNarrow: 12,
          ),
        ),
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
              enableDrag: true,
              isDismissible: true,
              builder: (context) => VATReceiptModal(receipt: receipt),
            );
          },
          borderRadius: BorderRadius.circular(
            context.responsiveBorderRadius(
              small: 12,
              medium: 14,
              large: 16,
              tablet: 18,
              veryNarrow: 10,
            ),
          ),
          child: Padding(
            padding: EdgeInsets.all(16.w),
            child: Row(
              children: [
                Container(
                  width: 48.w,
                  height: 48.w,
                  decoration: BoxDecoration(
                    color: AppColors.deepGreen.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(
                      context.responsiveBorderRadius(
                        small: 8,
                        medium: 10,
                        large: 12,
                        tablet: 14,
                        veryNarrow: 6,
                      ),
                    ),
                  ),
                  child: Icon(
                    Icons.receipt_long,
                    color: AppColors.deepGreen,
                    size: 24.sp,
                  ),
                ),
                SizedBox(
                  width: context.responsiveSpacing(
                    small: 12,
                    medium: 14,
                    large: 16,
                    tablet: 18,
                    veryNarrow: 8,
                  ),
                ),
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
                      SizedBox(
                        height: context.responsiveSpacing(
                          small: 4,
                          medium: 6,
                          large: 8,
                          tablet: 10,
                          veryNarrow: 3,
                        ),
                      ),
                      Text(
                        receipt.formattedDate,
                        style: TextStyle(
                          color: context.textSecondaryColor,
                          fontSize: 12.sp,
                        ),
                      ),
                      SizedBox(
                        height: context.responsiveSpacing(
                          small: 4,
                          medium: 6,
                          large: 8,
                          tablet: 10,
                          veryNarrow: 3,
                        ),
                      ),
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

  Widget _buildInfoCard() {
    print('🔍 [EBARIMT] _buildInfoCard called');
    print('🔍 [EBARIMT] _infoType: $_infoType');
    print('🔍 [EBARIMT] _consumerInfo: $_consumerInfo');
    print('🔍 [EBARIMT] _foreignerInfo: $_foreignerInfo');

    final info = _infoType == 'consumer' ? _consumerInfo : _foreignerInfo;
    print('🔍 [EBARIMT] Selected info: $info');
    print('🔍 [EBARIMT] Info is null: ${info == null}');

    if (info == null) {
      print('❌ [EBARIMT] Info is null, returning empty widget');
      return const SizedBox.shrink();
    }

    print('✅ [EBARIMT] Building info card with data: $info');
    print('🔍 [EBARIMT] Info keys: ${info.keys.toList()}');
    print('🔍 [EBARIMT] Info isEmpty: ${info.isEmpty}');

    return Container(
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: AppColors.deepGreen.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(
          color: AppColors.deepGreen.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                _infoType == 'consumer' ? Icons.person : Icons.public,
                color: AppColors.deepGreen,
                size: 20.sp,
              ),
              SizedBox(width: 8.w),
              Text(
                _infoType == 'consumer'
                    ? 'Иргэний мэдээлэл'
                    : 'Гадаадын иргэний мэдээлэл',
                style: TextStyle(
                  color: context.textPrimaryColor,
                  fontSize: 14.sp,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          SizedBox(height: 12.h),
          if (_infoType == 'consumer') ...[
            _buildInfoRow('Нэр', info['name']?.toString() ?? '-'),
            _buildInfoRow('Овог', info['surname']?.toString() ?? '-'),
            _buildInfoRow(
              'Регистр',
              info['register']?.toString() ??
                  info['customerNo']?.toString() ??
                  '-',
            ),
            _buildInfoRow('Утас', info['phone']?.toString() ?? '-'),
            _buildInfoRow('Имэйл', info['email']?.toString() ?? '-'),
            _buildInfoRow('Төлөв', info['status']?.toString() ?? '-'),
          ] else ...[
            _buildInfoRow('Нэр', info['name']?.toString() ?? '-'),
            _buildInfoRow('Овог', info['surname']?.toString() ?? '-'),
            _buildInfoRow(
              'Паспорт дугаар',
              info['passportNo']?.toString() ?? '-',
            ),
            _buildInfoRow(
              'Харилцагчийн дугаар',
              info['customerNo']?.toString() ?? '-',
            ),
            _buildInfoRow('Утас', info['phone']?.toString() ?? '-'),
            _buildInfoRow('Имэйл', info['email']?.toString() ?? '-'),
            _buildInfoRow('Төлөв', info['status']?.toString() ?? '-'),
          ],
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: EdgeInsets.only(bottom: 8.h),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120.w,
            child: Text(
              '$label:',
              style: TextStyle(
                color: context.textSecondaryColor,
                fontSize: 12.sp,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                color: context.textPrimaryColor,
                fontSize: 12.sp,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
