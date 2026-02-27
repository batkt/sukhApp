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
            content: Text(e.toString().replaceAll("", "")),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = context.isDarkMode;

    return Scaffold(
      backgroundColor: context.backgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back_ios_new_rounded,
            color: context.textPrimaryColor,
            size: 20.sp,
          ),
          onPressed: () => context.pop(),
        ),
        title: Text(
          'И-Баримт',
          style: TextStyle(
            color: context.textPrimaryColor,
            fontSize: 18.sp,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.2,
          ),
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Citizen Code Input Section
            Container(
              margin: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
              padding: EdgeInsets.all(20.w),
              decoration: BoxDecoration(
                color: context.cardBackgroundColor,
                borderRadius: BorderRadius.circular(24.r),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(isDark ? 0.2 : 0.04),
                    blurRadius: 24,
                    offset: const Offset(0, 8),
                    spreadRadius: 0,
                  ),
                ],
              ),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: EdgeInsets.all(8.w),
                          decoration: BoxDecoration(
                            color: AppColors.deepGreen.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(10.r),
                          ),
                          child: Icon(
                            Icons.person_search_rounded,
                            color: AppColors.deepGreen,
                            size: 20.sp,
                          ),
                        ),
                        SizedBox(width: 12.w),
                        Text(
                          'Иргэний мэдээлэл',
                          style: TextStyle(
                            color: context.textPrimaryColor,
                            fontSize: 15.sp,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 20.h),
                    TextFormField(
                      controller: _citizenCodeController,
                      keyboardType: TextInputType.text,
                      style: TextStyle(
                        fontSize: 15.sp,
                        color: context.textPrimaryColor,
                        fontWeight: FontWeight.w500,
                      ),
                      decoration: InputDecoration(
                        hintText: 'Регистр, утасны дугаар',
                        hintStyle: TextStyle(
                          color: context.textSecondaryColor.withOpacity(0.7),
                          fontSize: 14.sp,
                        ),
                        prefixIcon: Icon(
                          Icons.badge_outlined,
                          color: context.textSecondaryColor,
                          size: 22.sp,
                        ),
                        filled: true,
                        fillColor: isDark
                            ? Colors.white.withOpacity(0.05)
                            : Colors.grey.withOpacity(0.05),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16.r),
                          borderSide: BorderSide.none,
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16.r),
                          borderSide: BorderSide(
                            color: AppColors.deepGreen,
                            width: 1.5,
                          ),
                        ),
                        contentPadding: EdgeInsets.symmetric(
                          vertical: 16.h,
                          horizontal: 16.w,
                        ),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Хоосон байж болохгүй';
                        }
                        return null;
                      },
                    ),
                    SizedBox(height: 16.h),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _isSearching ? null : _searchConsumerInfo,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.deepGreen,
                          foregroundColor: Colors.white,
                          padding: EdgeInsets.symmetric(vertical: 16.h),
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16.r),
                          ),
                        ),
                        child: _isSearching
                            ? SizedBox(
                                width: 22.sp,
                                height: 22.sp,
                                child: const CircularProgressIndicator(
                                  strokeWidth: 2.5,
                                  color: Colors.white,
                                ),
                              )
                            : Text(
                                'Хадгалах',
                                style: TextStyle(
                                  fontSize: 16.sp,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 0.3,
                                ),
                              ),
                      ),
                    ),
                    // Display consumer/foreigner info
                    if (_consumerInfo != null || _foreignerInfo != null) ...[
                      SizedBox(height: 20.h),
                      _buildInfoCard(),
                    ],
                  ],
                ),
              ),
            ),

            // Ebarimt Receipts List Header
            Padding(
              padding: EdgeInsets.fromLTRB(20.w, 16.h, 20.w, 12.h),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Илгээгдсэн баримтууд',
                    style: TextStyle(
                      color: context.textPrimaryColor,
                      fontSize: 16.sp,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  Container(
                    padding:
                        EdgeInsets.symmetric(horizontal: 10.w, vertical: 4.h),
                    decoration: BoxDecoration(
                      color: AppColors.deepGreen.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12.r),
                    ),
                    child: _isLoadingReceipts
                        ? SizedBox(
                            width: 12.sp,
                            height: 12.sp,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: AppColors.deepGreen,
                            ),
                          )
                        : Text(
                            '${_ebarimtReceipts.length}',
                            style: TextStyle(
                              color: AppColors.deepGreen,
                              fontSize: 13.sp,
                              fontWeight: FontWeight.w700,
                            ),
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
                              Container(
                                padding: EdgeInsets.all(20.w),
                                decoration: BoxDecoration(
                                  color: context.cardBackgroundColor,
                                  shape: BoxShape.circle,
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withOpacity(isDark ? 0.2 : 0.05),
                                      blurRadius: 20,
                                    ),
                                  ],
                                ),
                                child: Icon(
                                  Icons.receipt_long_rounded,
                                  size: 48.sp,
                                  color: context.textSecondaryColor
                                      .withOpacity(0.5),
                                ),
                              ),
                              SizedBox(height: 20.h),
                              Text(
                                'И-Баримт олдсонгүй',
                                style: TextStyle(
                                  color: context.textPrimaryColor,
                                  fontSize: 16.sp,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              SizedBox(height: 8.h),
                              Text(
                                'Танд илгээгдсэн цахим төлбөрийн\nбаримт одоогоор байхгүй байна.',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  color: context.textSecondaryColor,
                                  fontSize: 13.sp,
                                  height: 1.4,
                                ),
                              ),
                            ],
                          ),
                        )
                      : ListView.builder(
                          padding: EdgeInsets.symmetric(
                              horizontal: 16.w, vertical: 8.h),
                          itemCount: _ebarimtReceipts.length,
                          itemBuilder: (context, index) {
                            final receipt = _ebarimtReceipts[index];
                            return _buildReceiptCard(receipt);
                          },
                        ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildReceiptCard(VATReceipt receipt) {
    final isDark = context.isDarkMode;
    return Container(
      margin: EdgeInsets.only(bottom: 12.h),
      decoration: BoxDecoration(
        color: context.cardBackgroundColor,
        borderRadius: BorderRadius.circular(20.r),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDark ? 0.2 : 0.03),
            blurRadius: 15,
            spreadRadius: 0,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(20.r),
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
          child: Padding(
            padding: EdgeInsets.all(16.w),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Container(
                  padding: EdgeInsets.all(12.w),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        AppColors.deepGreen.withOpacity(0.2),
                        AppColors.deepGreen.withOpacity(0.05),
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(16.r),
                    border: Border.all(
                      color: AppColors.deepGreen.withOpacity(0.1),
                    ),
                  ),
                  child: Icon(
                    Icons.receipt_rounded,
                    color: AppColors.deepGreen,
                    size: 26.sp,
                  ),
                ),
                SizedBox(width: 16.w),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Цахим төлбөрийн баримт',
                        style: TextStyle(
                          color: context.textPrimaryColor,
                          fontSize: 14.sp,
                          fontWeight: FontWeight.w700,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      SizedBox(height: 6.h),
                      Row(
                        children: [
                          Icon(
                            Icons.calendar_month_rounded,
                            size: 14.sp,
                            color: context.textSecondaryColor,
                          ),
                          SizedBox(width: 4.w),
                          Text(
                            receipt.formattedDate,
                            style: TextStyle(
                              color: context.textSecondaryColor,
                              fontSize: 12.sp,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                SizedBox(width: 8.w),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      receipt.formattedAmount,
                      style: TextStyle(
                        color: AppColors.deepGreen,
                        fontSize: 15.sp,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    SizedBox(height: 6.h),
                    Container(
                      padding:
                          EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
                      decoration: BoxDecoration(
                        color: AppColors.deepGreen.withOpacity(0.08),
                        borderRadius: BorderRadius.circular(6.r),
                      ),
                      child: Text(
                        'И-Баримт',
                        style: TextStyle(
                          color: AppColors.deepGreen,
                          fontSize: 9.sp,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildInfoCard() {
    final info = _infoType == 'consumer' ? _consumerInfo : _foreignerInfo;
    if (info == null) return const SizedBox.shrink();

    final isDark = context.isDarkMode;

    return Container(
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(
          color: context.borderColor.withOpacity(isDark ? 0.2 : 0.5),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: EdgeInsets.all(6.w),
                decoration: BoxDecoration(
                  color: AppColors.deepGreen,
                  borderRadius: BorderRadius.circular(8.r),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.deepGreen.withOpacity(0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Icon(
                  _infoType == 'consumer'
                      ? Icons.person_rounded
                      : Icons.public_rounded,
                  color: Colors.white,
                  size: 16.sp,
                ),
              ),
              SizedBox(width: 10.w),
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
          SizedBox(height: 16.h),
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
              'Паспорт',
              info['passportNo']?.toString() ?? '-',
            ),
            _buildInfoRow(
              'Харилцагч №',
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
      padding: EdgeInsets.only(bottom: 10.h),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100.w,
            child: Text(
              label,
              style: TextStyle(
                color: context.textSecondaryColor,
                fontSize: 13.sp,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                color: context.textPrimaryColor,
                fontSize: 13.sp,
                fontWeight: FontWeight.w600,
              ),
              textAlign: TextAlign.right,
            ),
          ),
        ],
      ),
    );
  }
}
