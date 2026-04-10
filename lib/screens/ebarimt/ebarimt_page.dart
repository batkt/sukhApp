import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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
import 'package:sukh_app/widgets/standard_app_bar.dart';
import 'package:sukh_app/widgets/glass_snackbar.dart';

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
      final userId = await StorageService.getUserId();
      final response = await ApiService.easyRegisterGetSavedUsers(
        orshinSuugchiinId: userId,
      );
      if (mounted) {
        setState(() {
          _savedUsers = response['jagsaalt'] ?? [];
          _isLoadingSavedUsers = false;
          
          if (_consumerInfo == null && _foreignerInfo == null && _savedUsers.length == 1) {
            final user = _savedUsers[0];
            final identity = (user['regNo']?.toString().isNotEmpty == true 
                ? user['regNo'] 
                : user['loginName']) ?? '';
            if (identity.isNotEmpty) {
              _citizenCodeController.text = identity;
              _searchConsumerInfo();
            }
          }
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoadingSavedUsers = false);
    }
  }

  Future<void> _deleteEasyRegisterUser(dynamic user) async {
    final userId = user['_id']?.toString();
    if (userId == null) return;

    final name = '${user['givenName'] ?? ''} ${user['familyName'] ?? ''}'.trim();

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Устгах', style: TextStyle(fontSize: 16.sp, fontWeight: FontWeight.bold)),
        content: Text('$name хэрэглэгчийг устгах уу?', style: TextStyle(fontSize: 14.sp)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Үгүй')),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Тийм', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      await ApiService.easyRegisterDeleteUser(userId: userId);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('$name амжилттай устгагдлаа'), backgroundColor: Colors.green),
        );
        _loadSavedUsers();
      }
    } catch (e) {
      if (mounted) {
        showGlassSnackBar(
          context,
          message: 'Алдаа: ${e.toString().replaceAll('Exception: ', '')}',
          icon: Icons.error_outline,
        );
      }
    }
  }

  Future<void> _disconnectCurrentUser() async {
    // Clear locally stored ebarimt info
    await StorageService.clearEbarimtInfo();
    
    // Also delete from server if we have the user ID
    final info = _infoType == 'consumer' ? _consumerInfo : _foreignerInfo;
    if (info != null && info['_id'] != null) {
      try {
        await ApiService.easyRegisterDeleteUser(userId: info['_id'].toString());
      } catch (e) {
        print('Server delete failed: $e');
      }
    }

    if (mounted) {
      setState(() {
        _consumerInfo = null;
        _foreignerInfo = null;
        _infoType = null;
        _citizenCodeController.clear();
      });
      _loadSavedUsers(); // Refresh dropdown
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
            final statusRes = await ApiService.walletQpayWalletCheck(walletPaymentId: paymentId);
            
            if (statusRes['success'] == true && statusRes['data'] != null) {
              final walletData = statusRes['data'];
              final state = walletData['paymentStatus']?.toString().toUpperCase();
              
              // Check for success transactions
              final transactions = walletData['paymentTransactions'] as List?;
              bool hasSuccessfulTrx = false;
              if (transactions != null) {
                hasSuccessfulTrx = transactions.any((trx) => 
                  (trx['trxStatus']?.toString().toUpperCase() == 'SUCCESS') ||
                  (trx['trxStatusName']?.toString() == 'Амжилттай')
                );
              }

              if ((state == 'PAID' || hasSuccessfulTrx) && walletData['vatInformation'] != null) {
                return VATReceipt.fromWalletPayment(walletData);
              } else {
                if (mounted) {
                  showGlassSnackBar(
                    context,
                    message: 'Энэ төлбөрт И-Баримт үүсээгүй байна',
                    icon: Icons.info_outline,
                  );
                }
              }
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
          // Deduplicate by ID / DDTD
          final uniqueReceipts = <String, VATReceipt>{};
          for (var receipt in allReceipts) {
            // Use receipt.id or receipt.receiptId or qrData as unique key
            final key = receipt.id.isNotEmpty ? receipt.id : 
                        (receipt.receiptId?.isNotEmpty == true ? receipt.receiptId! : receipt.qrData);
            if (key.isNotEmpty) {
               uniqueReceipts.putIfAbsent(key, () => receipt);
            } else {
               // Fallback if somehow no ID exists
               uniqueReceipts.putIfAbsent(receipt.hashCode.toString(), () => receipt);
            }
          }
          _ebarimtReceipts = uniqueReceipts.values.toList();
          // Sort by date descending
          _ebarimtReceipts.sort((a, b) => b.date.compareTo(a.date));
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

  String _cleanErrorMessage(String error) {
    var msg = error.replaceAll("Exception: ", "").trim();
    if (msg.contains("Оршин суугчийн мэдээлэл олдсонгүй") || 
        msg.contains("СӨХ-өөс мэдээлэлээ шалгуулна уу") ||
        msg.contains("Мэдээлэл авахад алдаа гарлаа") ||
        msg.toLowerCase().contains("invalid json") ||
        msg.toLowerCase().contains("unexpected character")) {
      return "Илэрц олдсонгүй. Мэдээлэлээ зөв оруулсан эсэхээ шалгана уу.";
    }
    return msg;
  }

  Future<void> _searchConsumerInfo() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isSearching = true;
      _consumerInfo = null;
      _foreignerInfo = null;
      _infoType = null;
    });

    final identity = _citizenCodeController.text.trim();
    
    // Organization RD must be exactly 7 digits
    if (_infoType == 'foreigner') {
       final isNumeric = RegExp(r'^[0-9]+$').hasMatch(identity);
       if (identity.length != 7 || !isNumeric) {
         setState(() => _isSearching = false);
         ScaffoldMessenger.of(context).showSnackBar(
           const SnackBar(
             content: Text('Байгууллагын РД алдаатай байна (7 оронтой тоо оруулна уу)'),
             backgroundColor: Colors.red,
           ),
         );
         return;
       }
    }

    try {
      print('🔍 [EBARIMT] Starting search for identity: $identity');
      // Fetch current user ID to link with ITC profile
      final userId = await StorageService.getUserId();

      // Use unified Easy Register search
      final data = await ApiService.easyRegisterUserSearch(
        identity: identity,
        orshinSuugchiinId: userId,
        turul: _infoType,
      );
      print('✅ [EBARIMT] Easy Register data received: $data');

      if (mounted) {
        setState(() {
          // Map backend fields to UI fields if necessary
          final mappedInfo = Map<String, dynamic>.from({
            ...data,
            'name': data['givenName'] ?? data['name'],
            'surname': data['familyName'] ?? data['surname'],
            'register': data['regNo'] ?? data['register'] ?? data['identity'],
            'phone': data['phoneNum'] ?? data['phone'],
          });

          if (_infoType == 'foreigner') {
            _foreignerInfo = mappedInfo;
          } else {
            _consumerInfo = mappedInfo;
          }
          _isSearching = false;
          
          // Persist this connection for the next time page opens
          StorageService.saveEbarimtInfo({
            ...mappedInfo,
            'turul': _infoType,
          });
        });
      }
    } catch (e) {
      print('❌ [EBARIMT] Final error in search: $e');
      if (mounted) {
        setState(() {
          _isSearching = false;
          _consumerInfo = null;
          _foreignerInfo = null;
        });
        
        final cleanMsg = _cleanErrorMessage(e.toString());
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              cleanMsg, 
              style: TextStyle(
                color: Colors.white, 
                fontWeight: FontWeight.w600,
                fontSize: 14.sp
              )
            ),
            backgroundColor: Colors.red.shade800,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16.r)),
            margin: EdgeInsets.all(16.w),
            elevation: 8,
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
      appBar: buildStandardAppBar(context, title: 'И-Баримт'),
      body: SafeArea(
        child: Column(
          children: [
            if (_consumerInfo == null && _foreignerInfo == null)
              Container(
                margin: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
                padding: EdgeInsets.all(20.w),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF1E293B) : Colors.white,
                  borderRadius: BorderRadius.circular(24.r),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(isDark ? 0.4 : 0.06),
                      blurRadius: 20,
                      offset: const Offset(0, 10),
                    ),
                  ],
                  border: Border.all(
                    color: isDark ? Colors.white10 : Colors.black.withOpacity(0.04),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: EdgeInsets.all(10.w),
                          decoration: BoxDecoration(
                            color: AppColors.deepGreen.withOpacity(0.1),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            Icons.person_search_rounded,
                            color: AppColors.deepGreen,
                            size: 20.sp,
                          ),
                        ),
                        SizedBox(width: 12.w),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Иргэний мэдээлэл',
                                style: TextStyle(
                                  fontSize: 16.sp,
                                  fontWeight: FontWeight.w900,
                                  color: isDark ? Colors.white : const Color(0xFF1E293B),
                                ),
                              ),
                              Text(
                                'И-Баримт авах иргэн эсвэл ААН-ийн хайлтыг энд хийнэ үү',
                                style: TextStyle(
                                  fontSize: 11.sp,
                                  color: isDark ? Colors.blueGrey.shade400 : const Color(0xFF64748B),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 24.h),
                    Form(
                      key: _formKey,
                      child: Column(
                        children: [
                          TextFormField(
                            controller: _citizenCodeController,
                            keyboardType: TextInputType.text,
                            style: TextStyle(
                              fontSize: 15.sp,
                              fontWeight: FontWeight.w600,
                              color: isDark ? Colors.white : const Color(0xFF334155),
                            ),
                            decoration: InputDecoration(
                              labelText: _infoType == 'foreigner' ? 'Байгууллагын РД' : 'Иргэний код / Утас',
                              hintText: _infoType == 'foreigner' ? 'Байгууллагын код' : '88... эсвэл Иргэний код',
                              prefixIcon: Icon(Icons.qr_code_scanner_rounded, size: 20.sp, color: AppColors.deepGreen),
                              suffixIcon: (_savedUsers.isEmpty || _consumerInfo != null || _foreignerInfo != null)
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
                                                            '${user['givenName'] ?? ''} ${user['familyName'] ?? ''}'
                                                                .toUpperCase(),
                                                            style: const TextStyle(fontWeight: FontWeight.w600),
                                                          ),
                                                          Text(
                                                            (user['regNo'] ?? user['loginName'] ?? '').toString(),
                                                            style: TextStyle(fontSize: 12.sp, color: Colors.grey),
                                                          ),
                                                        ],
                                                      ),
                                                    ),
                                                    GestureDetector(
                                                      onTap: () {
                                                        Navigator.pop(context);
                                                        _deleteEasyRegisterUser(user);
                                                      },
                                                      child: Padding(
                                                        padding: EdgeInsets.all(4.w),
                                                        child: Icon(
                                                          Icons.delete_outline_rounded,
                                                          size: 18.sp,
                                                          color: Colors.red.withOpacity(0.7),
                                                        ),
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ))
                                          .toList(),
                                    ),
                              filled: true,
                              fillColor: isDark ? Colors.black26 : Colors.grey.shade50,
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(16.r),
                                borderSide: BorderSide.none,
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(16.r),
                                borderSide: BorderSide.none,
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(16.r),
                                borderSide: const BorderSide(color: AppColors.deepGreen, width: 1.5),
                              ),
                              contentPadding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 16.h),
                            ),
                            validator: (val) => val == null || val.isEmpty ? 'Мэдээлэл оруулна уу' : null,
                          ),
                          SizedBox(height: 16.h),
                          
                          // Type selection for more accurate search
                          Row(
                            children: [
                              _buildTypeChip('Иргэн', 'consumer', isDark),
                              SizedBox(width: 8.w),
                              _buildTypeChip('Байгууллага', 'foreigner', isDark),
                            ],
                          ),
                          
                          SizedBox(height: 20.h),
                          SizedBox(
                            width: double.infinity,
                            height: 52.h,
                            child: ElevatedButton(
                              onPressed: _isSearching ? null : _searchConsumerInfo,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.deepGreen,
                                foregroundColor: Colors.white,
                                elevation: 0,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16.r),
                                ),
                              ),
                              child: _isSearching
                                  ? SizedBox(
                                      height: 20.h,
                                      width: 20.h,
                                      child: const CircularProgressIndicator(
                                        color: Colors.white,
                                        strokeWidth: 2,
                                      ),
                                    )
                                  : Text(
                                      'БҮРТГЭГДСЭН БАРИМТ',
                                      style: TextStyle(
                                        fontSize: 14.sp,
                                        fontWeight: FontWeight.w900,
                                        letterSpacing: 1,
                                      ),
                                    ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              )
            else
              Padding(
                padding: EdgeInsets.fromLTRB(16.w, 8.h, 16.w, 8.h),
                child: _buildInfoCard(),
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
                        'ЦАХИМ ТӨЛБӨРИЙН БАРИМТ',
                        textAlign: TextAlign.left,
                        style: TextStyle(
                          color: context.textPrimaryColor,
                          fontSize: 13.sp,
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
                          Expanded(
                            child: Text(
                              receipt.formattedDate,
                              style: TextStyle(
                                color: context.textSecondaryColor,
                                fontSize: 11.sp,
                                fontWeight: FontWeight.w500,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
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
                    Builder(
                      builder: (context) {
                        final isScanned = receipt.status?.toUpperCase() == 'SCANNED' || receipt.status == '3';
                        return Container(
                          padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
                          decoration: BoxDecoration(
                            color: AppColors.deepGreen.withOpacity(0.08),
                            borderRadius: BorderRadius.circular(6.r),
                          ),
                          child: Text(
                            (receipt.id.isNotEmpty || (receipt.receiptId?.isNotEmpty ?? false)) ? 'ИБАРИМТ БҮРТГЭГДСЭН' : 'И-БАРИМТ',
                            style: TextStyle(
                              color: AppColors.deepGreen,
                              fontSize: 9.sp,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        );
                      }
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
                onPressed: () => _disconnectCurrentUser(),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
                tooltip: 'Салгах',
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
              value.toUpperCase(),
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

  Widget _buildTypeChip(String label, String type, bool isDark) {
    final isSelected = _infoType == type;
    return GestureDetector(
      onTap: () => setState(() => _infoType = type),
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
        decoration: BoxDecoration(
          color: isSelected 
              ? AppColors.deepGreen.withOpacity(0.15) 
              : (isDark ? Colors.white.withOpacity(0.05) : Colors.grey.shade100),
          borderRadius: BorderRadius.circular(12.r),
          border: Border.all(
            color: isSelected ? AppColors.deepGreen : Colors.transparent,
            width: 1.2,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12.sp,
            fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
            color: isSelected 
                ? AppColors.deepGreen 
                : (isDark ? Colors.blueGrey.shade300 : Colors.blueGrey.shade600),
          ),
        ),
      ),
    );
  }
}
