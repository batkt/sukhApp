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

  bool _isInfoCardExpanded = true;
  List<dynamic> _savedUsers = [];
  bool _isLoadingSavedUsers = false;

  @override
  void initState() {
    super.initState();
    _loadEbarimtReceipts();
    _loadSavedUsers();
    _loadStoredEbarimtInfo();
  }

  Future<void> _loadStoredEbarimtInfo() async {
    final storedInfo = await StorageService.getEbarimtInfo();
    if (storedInfo != null && mounted) {
      setState(() {
        _infoType = storedInfo['turul'] ?? 'consumer';
        if (_infoType == 'consumer') {
          _consumerInfo = storedInfo;
        } else {
          _foreignerInfo = storedInfo;
        }
        // Collapse by default to keep UI clean
        _isInfoCardExpanded = false;
      });
      print('📦 [EBARIMT] Loaded stored user info: ${storedInfo['name']}');
    }
  }

  Future<void> _loadSavedUsers() async {
    setState(() => _isLoadingSavedUsers = true);
    try {
      final response = await ApiService.easyRegisterGetSavedUsers();
      if (mounted) {
        setState(() {
          _savedUsers = response['jagsaalt'] ?? [];
          _isLoadingSavedUsers = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoadingSavedUsers = false);
    }
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

      final List<VATReceipt> allReceipts = [];

      // Fetch contracts
      try {
        final gereeResponse = await ApiService.fetchGeree(userId);
        if (gereeResponse['jagsaalt'] != null &&
            (gereeResponse['jagsaalt'] as List).isNotEmpty) {
          final List<dynamic> gereeJagsaalt = gereeResponse['jagsaalt'];

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
        }
      } catch (e) {
        print('Error fetching contracts for receipts: $e');
      }

      // Load wallet payments history
      try {
        final Set<String> processedPaymentIds = {};
        final List<Map<String, dynamic>> allPotentialPayments = [];

        // 1. Get from global wallet history
        try {
          final walletList = await ApiService.fetchWalletQpayList();
          allPotentialPayments.addAll(walletList);
        } catch (e) {
          print('Error fetching global wallet history: $e');
        }

        // 2. Get from billing-specific payment history
        try {
          final billingList = await ApiService.getWalletBillingList();
          for (var billing in billingList) {
            final billingId = billing['billingId']?.toString();
            if (billingId != null) {
              final billingData = await ApiService.getWalletBillingBills(billingId: billingId);
              if (billingData['payments'] != null && billingData['payments'] is List) {
                final List<Map<String, dynamic>> billingPayments = 
                    List<Map<String, dynamic>>.from(billingData['payments']);
                allPotentialPayments.addAll(billingPayments);
              }
            }
          }
        } catch (e) {
          print('Error fetching billing-specific history: $e');
        }

        // Filter valid PAID payments and deduplicate
        final uniqueWalletPayments = allPotentialPayments.where((item) {
          final id = (item['paymentId'] ?? item['walletPaymentId'])?.toString();
          if (id == null || id.isEmpty || processedPaymentIds.contains(id)) return false;
          processedPaymentIds.add(id);
          
          final status = item['paymentStatus']?.toString().toUpperCase() ?? 
                         item['status']?.toString().toUpperCase() ?? '';
          return status == 'PAID' || status == 'SUCCESS';
        }).toList();

        // Concurrent fetching of VAT info for each unique wallet payment
        final walletReceiptsList = await Future.wait(uniqueWalletPayments.map((item) async {
          try {
            // Optimization: if vatInformation is already in the item, use it
            if (item['vatInformation'] != null) {
               return VATReceipt.fromWalletPayment(item);
            }

            final paymentId = (item['paymentId'] ?? item['walletPaymentId'])?.toString();
            if (paymentId == null) return null;
            
            // Otherwise check status to get vatInformation
            final checkRes = await ApiService.walletQpayCheckStatus(walletPaymentId: paymentId);
            
            if (checkRes['status']?.toString().toUpperCase() == 'PAID' && checkRes['vatInformation'] != null) {
              return VATReceipt.fromWalletPayment(checkRes);
            }
          } catch (e) {
            print('Error fetching wallet receipt for ${item['paymentId'] ?? item['walletPaymentId']}: $e');
          }
          return null;
        }));

        allReceipts.addAll(walletReceiptsList.whereType<VATReceipt>());
      } catch (e) {
        print('Error loading wallet payment history: $e');
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

      // Fetch current user ID to link with ITC profile
      final userId = await StorageService.getUserId();

      // Use unified Easy Register search
      final data = await ApiService.easyRegisterUserSearch(
        identity: identity,
        orshinSuugchiinId: userId,
      );
      print('✅ [EBARIMT] Easy Register data received: $data');

      if (mounted) {
        setState(() {
          // The backend returns infoType or turul
          final turul = data['turul']?.toString().toLowerCase();
          
          // Map backend fields to UI fields if necessary
          final mappedInfo = {
            ...data,
            'name': data['givenName'] ?? data['name'],
            'surname': data['familyName'] ?? data['surname'],
            'register': data['regNo'] ?? data['register'] ?? data['identity'],
            'phone': data['phoneNum'] ?? data['phone'],
          };

          if (turul == 'foreigner') {
            _foreignerInfo = mappedInfo;
            _infoType = 'foreigner';
          } else {
            _consumerInfo = mappedInfo;
            _infoType = 'consumer';
          }
          _isSearching = false;
          
          // Persist this connection for the next time page opens
          StorageService.saveEbarimtInfo({
            ...mappedInfo,
            'turul': _infoType,
          });
        });
        print('✅ [EBARIMT] Search result set. _infoType: $_infoType');
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
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString().replaceAll("Exception: ", "")),
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
                        suffixIcon: _savedUsers.isEmpty
                            ? null
                            : PopupMenuButton<dynamic>(
                                icon: Icon(
                                  Icons.arrow_drop_down_circle_outlined,
                                  color: AppColors.deepGreen,
                                  size: 24.sp,
                                ),
                                onSelected: (user) {
                                  setState(() {
                                    final identity =
                                        (user['regNo']?.toString().isNotEmpty == true
                                                ? user['regNo']
                                                : user['loginName']) ??
                                            '';
                                    _citizenCodeController.text = identity.toString();
                                    
                                    // Auto-trigger search with selection
                                    _searchConsumerInfo();
                                  });
                                },
                                itemBuilder: (context) => _savedUsers
                                    .map((user) => PopupMenuItem<dynamic>(
                                          value: user,
                                          child: Row(
                                            children: [
                                              Icon(
                                                user['turul'] == 'foreigner'
                                                    ? Icons.public_rounded
                                                    : Icons.person_rounded,
                                                size: 18.sp,
                                                color: AppColors.deepGreen,
                                              ),
                                              SizedBox(width: 12.w),
                                              Expanded(
                                                child: Column(
                                                  crossAxisAlignment:
                                                      CrossAxisAlignment.start,
                                                  children: [
                                                    Text(
                                                      '${user['givenName']} ${user['familyName']}',
                                                      style: TextStyle(
                                                        fontSize: 14.sp,
                                                        fontWeight:
                                                            FontWeight.w600,
                                                      ),
                                                    ),
                                                    Text(
                                                      user['regNo'] ??
                                                          user['loginName'] ??
                                                          '',
                                                      style: TextStyle(
                                                        fontSize: 12.sp,
                                                        color: context
                                                            .textSecondaryColor,
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                            ],
                                          ),
                                        ))
                                    .toList(),
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
          InkWell(
            onTap: () => setState(() => _isInfoCardExpanded = !_isInfoCardExpanded),
            borderRadius: BorderRadius.circular(8.r),
            child: Row(
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
                Expanded(
                  child: Text(
                    _infoType == 'consumer'
                        ? 'Иргэний мэдээлэл'
                        : 'Гадаадын иргэний мэдээлэл',
                    style: TextStyle(
                      color: context.textPrimaryColor,
                      fontSize: 14.sp,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                IconButton(
                  icon: Icon(
                    Icons.logout_rounded,
                    color: Colors.red.withOpacity(0.7),
                    size: 18.sp,
                  ),
                  onPressed: () {
                    StorageService.clearEbarimtInfo();
                    setState(() {
                      _consumerInfo = null;
                      _foreignerInfo = null;
                      _infoType = null;
                      _citizenCodeController.clear();
                    });
                  },
                  tooltip: 'Салгах',
                ),
                Icon(
                  _isInfoCardExpanded
                      ? Icons.keyboard_arrow_up_rounded
                      : Icons.keyboard_arrow_down_rounded,
                  color: context.textSecondaryColor,
                  size: 20.sp,
                ),
              ],
            ),
          ),
          if (_isInfoCardExpanded) ...[
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
            ],
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
