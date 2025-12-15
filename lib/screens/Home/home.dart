import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:sukh_app/components/Menu/side_menu.dart';
import 'package:sukh_app/components/Home/home_header.dart';
import 'package:sukh_app/components/Home/billing_connection_section.dart';
import 'package:sukh_app/components/Home/billing_list_section.dart';
import 'package:sukh_app/components/Home/billers_grid.dart';
import 'package:sukh_app/components/Home/total_balance_modal.dart';
import 'package:sukh_app/components/Home/billing_detail_modal.dart';
import 'package:sukh_app/services/storage_service.dart';
import 'package:sukh_app/services/api_service.dart';
import 'package:sukh_app/services/socket_service.dart';
import 'package:sukh_app/models/geree_model.dart';
import 'package:sukh_app/models/medegdel_model.dart';
import 'package:sukh_app/widgets/glass_snackbar.dart';
import 'package:sukh_app/constants/constants.dart';

class AppBackground extends StatelessWidget {
  final Widget child;
  const AppBackground({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(child: child);
  }
}

class NuurKhuudas extends StatefulWidget {
  const NuurKhuudas({super.key});

  @override
  State<NuurKhuudas> createState() => _BookingScreenState();
}

class _BookingScreenState extends State<NuurKhuudas> {
  DateTime? paymentDate;
  bool isLoadingPaymentData = true;
  Geree? gereeData;
  double totalNiitTulbur = 0.0;
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  // New variables for invoice tracking
  int? nekhemjlekhUusgekhOgnoo;
  DateTime? oldestUnpaidInvoiceDate;
  bool hasUnpaidInvoice = false;

  // Notification count
  int _unreadNotificationCount = 0;

  // Billers
  List<Map<String, dynamic>> _billers = [];
  bool _isLoadingBillers = true;
  final PageController _billerPageController = PageController();

  // Billing List
  List<Map<String, dynamic>> _billingList = [];
  bool _isLoadingBillingList = true;

  // User billing data from profile
  Map<String, dynamic>? _userBillingData;

  // All billing payments for total balance modal
  List<Map<String, dynamic>> _allBillingPayments = [];
  bool _isLoadingAllPayments = false;

  @override
  void initState() {
    super.initState();
    _loadBillers();
    _loadBillingList();
    _loadNotificationCount();
    _setupSocketListener();
    _loadAllBillingPayments();
  }

  void _setupSocketListener() {
    // Set up socket notification callback
    SocketService.instance.setNotificationCallback((notification) {
      // Refresh notification count when new notification arrives
      if (mounted) {
        _loadNotificationCount();
      }
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Re-establish socket listener when screen comes back into focus
    // This ensures the callback is active even after modal closes
    _setupSocketListener();
  }

  @override
  void dispose() {
    _billerPageController.dispose();
    // Don't remove callback on dispose - let it stay active
    // The socket service will handle cleanup on logout
    super.dispose();
  }

  Future<void> _loadNotificationCount() async {
    try {
      // Check if user is logged in first
      final isLoggedIn = await StorageService.isLoggedIn();
      if (!isLoggedIn) {
        return;
      }

      final response = await ApiService.fetchMedegdel();
      final medegdelResponse = MedegdelResponse.fromJson(response);
      final unreadCount = medegdelResponse.data
          .where((n) => !n.kharsanEsekh)
          .length;
      if (mounted) {
        setState(() {
          _unreadNotificationCount = unreadCount;
        });
      }
    } catch (e) {
      // Silently fail - notifications are optional
      // Reset count on error
      if (mounted) {
        setState(() {
          _unreadNotificationCount = 0;
        });
      }
    }
  }

  @override
  void didUpdateWidget(NuurKhuudas oldWidget) {
    super.didUpdateWidget(oldWidget);
    _loadBillers();
    _loadBillingList();
  }

  Future<void> _loadBillingList() async {
    setState(() {
      _isLoadingBillingList = true;
    });

    try {
      // Load connected billings from Wallet API
      final billingList = await ApiService.getWalletBillingList();

      // Also load user profile to get billing data saved locally
      Map<String, dynamic>? userBillingData;
      try {
        final userProfile = await ApiService.getUserProfile();
        if (userProfile['success'] == true && userProfile['result'] != null) {
          final userData = userProfile['result'];
          // Check if user has billing data saved locally
          // Show billing data if user has:
          // 1. walletCustomerId or walletCustomerCode (billing customer info), OR
          // 2. walletBairId and walletDoorNo (address info), OR
          // 3. bairniiNer (building name) - indicates address was saved
          final hasCustomerInfo =
              userData['walletCustomerId'] != null ||
              userData['walletCustomerCode'] != null;
          final hasAddressInfo =
              userData['walletBairId'] != null &&
              userData['walletDoorNo'] != null;
          final hasBuildingName =
              userData['bairniiNer'] != null &&
              userData['bairniiNer'].toString().isNotEmpty;

          if (hasCustomerInfo || hasAddressInfo || hasBuildingName) {
            // Combine ovog and ner for full name
            String fullName = '';
            if (userData['ovog'] != null &&
                userData['ovog'].toString().isNotEmpty) {
              fullName = userData['ovog'].toString();
              if (userData['ner'] != null &&
                  userData['ner'].toString().isNotEmpty) {
                fullName += ' ${userData['ner'].toString()}';
              }
            } else if (userData['ner'] != null &&
                userData['ner'].toString().isNotEmpty) {
              fullName = userData['ner'].toString();
            }

            userBillingData = {
              'customerId': userData['walletCustomerId']?.toString(),
              'customerCode': userData['walletCustomerCode']?.toString(),
              'customerName': fullName,
              'ner': userData['ner']?.toString(),
              'ovog': userData['ovog']?.toString(),
              'billingName': 'Орон сууцны төлбөр',
              'bairniiNer': userData['bairniiNer']?.toString() ?? '',
              'customerAddress':
                  userData['bairniiNer']?.toString() ??
                  '', // Use bairniiNer as customerAddress
              'walletBairId': userData['walletBairId']?.toString(),
              'walletDoorNo': userData['walletDoorNo']?.toString(),
              'duureg': userData['duureg']?.toString(),
              'horoo': userData['horoo']?.toString(),
              'isLocalData': true, // Flag to indicate this is from user profile
            };
          }
        }
      } catch (e) {
        // Error loading user profile
      }

      // Check if userBillingData already exists in billingList to avoid duplicates
      if (userBillingData != null && billingList.isNotEmpty) {
        final userCustomerId = userBillingData['customerId']?.toString();
        final userCustomerCode = userBillingData['customerCode']?.toString();

        // Check if any billing in the list matches the user profile data
        final isDuplicate = billingList.any((billing) {
          final billingCustomerId = billing['customerId']?.toString();
          final billingCustomerCode = billing['customerCode']?.toString();

          // Match by customerId or customerCode
          if (userCustomerId != null && billingCustomerId == userCustomerId) {
            return true;
          }
          if (userCustomerCode != null &&
              billingCustomerCode == userCustomerCode) {
            return true;
          }

          // Also check if billingName matches "Орон сууцны төлбөр" and has same address
          final billingName = billing['billingName']?.toString() ?? '';
          if (billingName == 'Орон сууцны төлбөр' &&
              userBillingData != null &&
              userBillingData['billingName'] == 'Орон сууцны төлбөр') {
            final userBairId = userBillingData['walletBairId']?.toString();
            final billingBairId =
                billing['walletBairId']?.toString() ??
                billing['bairId']?.toString();
            if (userBairId != null && billingBairId == userBairId) {
              return true;
            }
          }

          return false;
        });

        if (isDuplicate) {
          userBillingData = null; // Don't show duplicate
        }
      }

      if (mounted) {
        setState(() {
          _billingList = billingList;
          _userBillingData = userBillingData;
          _isLoadingBillingList = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoadingBillingList = false;
        });
      }
    }
  }

  Future<void> _loadBillers() async {
    setState(() {
      _isLoadingBillers = true;
    });

    try {
      final billers = await ApiService.getWalletBillers();
      if (mounted) {
        setState(() {
          _billers = billers;
          _isLoadingBillers = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoadingBillers = false;
        });

        final errorMessage = e.toString();
        String displayMessage;

        if (errorMessage.contains('404')) {
          displayMessage =
              'Биллерүүд авах endpoint олдсонгүй. Backend дээр /wallet/billers route-ийг шалгана уу.';
        } else if (errorMessage.contains('401')) {
          displayMessage = 'Нэвтрэх шаардлагатай';
        } else {
          displayMessage = 'Биллерүүд авахад алдаа гарлаа: $e';
        }

        showGlassSnackBar(
          context,
          message: displayMessage,
          icon: Icons.error_outline,
          iconColor: Colors.red,
          textColor: Colors.white,
        );
      }
    }
  }

  Future<void> _loadAllBillingPayments() async {
    setState(() {
      _isLoadingAllPayments = true;
    });

    try {
      List<Map<String, dynamic>> allPayments = [];
      double total = 0.0;

      // Load OWN_ORG payments
      try {
        final userId = await StorageService.getUserId();
        if (userId != null) {
          final gereeResponse = await ApiService.fetchGeree(userId);
          if (gereeResponse['jagsaalt'] != null &&
              gereeResponse['jagsaalt'] is List) {
            final List<dynamic> gereeJagsaalt = gereeResponse['jagsaalt'];
            if (gereeJagsaalt.isNotEmpty) {
              final firstContract = gereeJagsaalt[0];
              final geree = Geree.fromJson(firstContract);
              final nekhemjlekhResponse =
                  await ApiService.fetchNekhemjlekhiinTuukh(
                    gereeniiDugaar: geree.gereeniiDugaar,
                  );

              if (nekhemjlekhResponse['jagsaalt'] != null &&
                  nekhemjlekhResponse['jagsaalt'] is List) {
                final List<dynamic> nekhemjlekhJagsaalt =
                    nekhemjlekhResponse['jagsaalt'];
                for (var invoice in nekhemjlekhJagsaalt) {
                  if (invoice['tuluv'] == 'Төлөөгүй') {
                    final niitTulbur = invoice['niitTulbur'];
                    if (niitTulbur != null) {
                      final amount = (niitTulbur is int)
                          ? niitTulbur.toDouble()
                          : (niitTulbur as double);
                      total += amount;
                      allPayments.add({
                        'source': 'OWN_ORG',
                        'billingName': 'Орон сууцны төлбөр',
                        'amount': amount,
                        'invoice': invoice,
                      });
                    }
                  }
                }
              }
            }
          }
        }
      } catch (e) {
        // Error loading OWN_ORG payments
      }

      // Load WALLET_API payments
      try {
        final billingList = await ApiService.getWalletBillingList();
        for (var billing in billingList) {
          final billingId = billing['billingId']?.toString();
          if (billingId != null && billingId.isNotEmpty) {
            try {
              final billingData = await ApiService.getWalletBillingBills(
                billingId: billingId,
              );

              // Extract bills from billingData
              List<Map<String, dynamic>> bills = [];
              if (billingData['newBills'] != null &&
                  billingData['newBills'] is List) {
                final newBillsList = billingData['newBills'] as List;
                if (newBillsList.isNotEmpty) {
                  final firstItem = newBillsList[0] as Map<String, dynamic>;
                  if (firstItem.containsKey('billId')) {
                    bills = List<Map<String, dynamic>>.from(newBillsList);
                  } else if (firstItem.containsKey('billingId') &&
                      firstItem['newBills'] != null) {
                    if (firstItem['newBills'] is List) {
                      bills = List<Map<String, dynamic>>.from(
                        firstItem['newBills'],
                      );
                    }
                  }
                }
              } else if (billingData.containsKey('billingId') &&
                  billingData['newBills'] != null) {
                if (billingData['newBills'] is List) {
                  bills = List<Map<String, dynamic>>.from(
                    billingData['newBills'],
                  );
                }
              }

              // Calculate total from payable bills
              double billingTotal = 0.0;
              for (var bill in bills) {
                final billTotalAmount =
                    (bill['billTotalAmount'] as num?)?.toDouble() ?? 0.0;
                billingTotal += billTotalAmount;
              }

              if (billingTotal > 0) {
                total += billingTotal;
                allPayments.add({
                  'source': 'WALLET_API',
                  'billingName':
                      billing['billingName']?.toString() ?? 'Биллинг',
                  'customerName': billing['customerName']?.toString() ?? '',
                  'amount': billingTotal,
                  'bills': bills,
                  'billing': billing,
                });
              }
            } catch (e) {
              // Error loading billing
            }
          }
        }
      } catch (e) {
        // Error loading WALLET_API payments
      }

      if (mounted) {
        setState(() {
          _allBillingPayments = allPayments;
          totalNiitTulbur = total;
          _isLoadingAllPayments = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoadingAllPayments = false;
        });
      }
    }
  }

  String _formatNumberWithComma(double number) {
    final parts = number.toStringAsFixed(0).split('.');
    final integerPart = parts[0];
    final regex = RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))');
    return integerPart.replaceAllMapped(regex, (match) => '${match[1]},');
  }

  String formatDate(String dateString) {
    try {
      final date = DateTime.parse(dateString);
      final months = [
        'Jan',
        'Feb',
        'Mar',
        'Apr',
        'May',
        'Jun',
        'Jul',
        'Aug',
        'Sep',
        'Oct',
        'Nov',
        'Dec',
      ];
      return '${date.day} ${months[date.month - 1]}';
    } catch (e) {
      return dateString;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      drawer: const SideMenu(),
      body: AppBackground(
        child: SafeArea(
          child: Column(
            children: [
              // Header Component
              HomeHeader(
                scaffoldKey: _scaffoldKey,
                totalNiitTulbur: totalNiitTulbur,
                unreadNotificationCount: _unreadNotificationCount,
                onTotalBalanceTap: _showTotalBalanceModal,
                onNotificationTap: () {
                  context.push('/medegdel-list').then((_) {
                    _loadNotificationCount();
                  });
                },
                formatNumberWithComma: _formatNumberWithComma,
              ),

              SizedBox(height: 20.h),

              // Billing Connection Section
              if (_billingList.isEmpty && !_isLoadingBillingList)
                BillingConnectionSection(
                  isConnecting: _isConnectingBilling,
                  onConnect: _connectBillingByAddress,
                ),

              if (_billingList.isEmpty && !_isLoadingBillingList)
                SizedBox(height: 11.h),

              // Billing List Section
              BillingListSection(
                isLoading: _isLoadingBillingList,
                billingList: _billingList,
                userBillingData: _userBillingData,
                onBillingTap: _showBillingDetailModal,
                expandAddressAbbreviations: _expandAddressAbbreviations,
              ),

              SizedBox(height: 11.h),

              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    children: [
                      // Billers Grid
                      if (_isLoadingBillers)
                        SizedBox(
                          height: 300.h,
                          child: const Center(
                            child: CircularProgressIndicator(
                              color: AppColors.secondaryAccent,
                            ),
                          ),
                        )
                      else if (_billers.isEmpty)
                        SizedBox(
                          height: 300.h,
                          child: Center(
                            child: Text(
                              'Биллер олдсонгүй',
                              style: TextStyle(
                                color: Colors.white70,
                                fontSize: 11.sp,
                              ),
                            ),
                          ),
                        )
                      else
                        BillersGrid(
                          billers: _billers,
                          onDevelopmentTap: () =>
                              _showDevelopmentModal(context),
                        ),

                      SizedBox(height: 11.h),
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

  void _showPaymentModal() {
    // Check if there's any amount to pay
    if (totalNiitTulbur <= 0) {
      showGlassSnackBar(
        context,
        message: 'Нэхэмжлэл үүсээгүй байна',
        icon: Icons.info_outline,
        iconColor: AppColors.secondaryAccent,
        textColor: Colors.white,
      );
      return;
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: BoxDecoration(
          color: const Color(0xFF0a0e27),
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(16),
            topRight: Radius.circular(16),
          ),
          border: Border.all(color: Colors.white.withOpacity(0.1)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header
            Container(
              padding: EdgeInsets.all(11.w),
              decoration: BoxDecoration(
                border: Border(
                  bottom: BorderSide(color: Colors.white.withOpacity(0.1)),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Төлбөр төлөх',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 11.sp,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  IconButton(
                    icon: Icon(Icons.close, color: Colors.white, size: 22.sp),
                    onPressed: () => Navigator.of(context).pop(),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                ],
              ),
            ),
            // Content
            Padding(
              padding: EdgeInsets.all(11.w),
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
                            fontSize: 11.sp,
                            color: Colors.white.withOpacity(0.6),
                          ),
                        ),
                        Text(
                          '${_formatNumberWithComma(totalNiitTulbur)}₮',
                          style: TextStyle(
                            fontSize: 11.sp,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(height: 11.h),
                  // Payment button
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.pop(context);
                        context.push('/nekhemjlekh');
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.secondaryAccent,
                        foregroundColor: Colors.black,
                        padding: EdgeInsets.symmetric(vertical: 11.h),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12.w),
                        ),
                      ),
                      child: Text(
                        'Төлбөр төлөх',
                        style: TextStyle(
                          fontSize: 11.sp,
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

  void _showTotalBalanceModal() {
    // Refresh payments when modal opens
    _loadAllBillingPayments();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => TotalBalanceModal(
        totalAmount: totalNiitTulbur,
        payments: _allBillingPayments,
        isLoading: _isLoadingAllPayments,
        formatNumberWithComma: _formatNumberWithComma,
        onPaymentTap: _showPaymentModal,
      ),
    );
  }

  // _buildPaymentDetails and _buildDetailRow moved to TotalBalanceModal component

  void _showDevelopmentModal(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (BuildContext context) {
        return Dialog(
          backgroundColor: Colors.transparent,
          child: Container(
            padding: EdgeInsets.all(24.w),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [AppColors.darkSurface, AppColors.darkSurfaceElevated],
              ),
              border: Border.all(color: AppColors.secondaryAccent, width: 2),
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: AppColors.secondaryAccent.withOpacity(0.3),
                  blurRadius: 20,
                  spreadRadius: 5,
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.construction_outlined,
                  color: AppColors.secondaryAccent,
                  size: 64.sp,
                ),
                SizedBox(height: 22.h),
                Text(
                  'Хөгжүүлэлт явагдаж байна',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 11.sp,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 11.h),
                Text(
                  'Энэ хуудас хөгжүүлэлт хийгдэж байгаа тул одоогоор ашиглах боломжгүй байна. Удахгүй ашиглах боломжтой болно.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 11.sp,
                    height: 1.5,
                  ),
                ),
                SizedBox(height: 22.h),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.of(context).pop();
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.goldPrimary,
                      foregroundColor: AppColors.darkBackground,
                      padding: EdgeInsets.symmetric(vertical: 11.h),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 0,
                    ),
                    child: Text(
                      'Ойлголоо',
                      style: TextStyle(
                        fontSize: 11.sp,
                        fontWeight: FontWeight.bold,
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

  bool _isConnectingBilling = false;

  Future<void> _connectBillingByAddress() async {
    setState(() {
      _isConnectingBilling = true;
    });

    try {
      // Get saved address
      final bairId = await StorageService.getWalletBairId();
      final doorNo = await StorageService.getWalletDoorNo();

      if (bairId == null || doorNo == null) {
        if (mounted) {
          setState(() {
            _isConnectingBilling = false;
          });
          showGlassSnackBar(
            context,
            message: 'Хаяг олдсонгүй. Эхлээд хаягаа сонгоно уу.',
            icon: Icons.error,
            iconColor: Colors.red,
          );
        }
        return;
      }

      // Fetch billing by address and automatically connect it
      // The /walletBillingHavakh endpoint automatically connects billing
      await ApiService.fetchWalletBilling(bairId: bairId, doorNo: doorNo);

      // Refresh billing list
      await _loadBillingList();

      if (mounted) {
        setState(() {
          _isConnectingBilling = false;
        });
        showGlassSnackBar(
          context,
          message: 'Биллинг амжилттай холбогдлоо',
          icon: Icons.check_circle,
          iconColor: Colors.green,
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isConnectingBilling = false;
        });
        final errorMessage = e.toString().contains('олдсонгүй')
            ? 'Биллингийн мэдээлэл олдсонгүй'
            : 'Биллинг холбоход алдаа гарлаа: $e';
        showGlassSnackBar(
          context,
          message: errorMessage,
          icon: Icons.error,
          iconColor: Colors.red,
        );
      }
    }
  }

  // _buildBillingConnectionSteps and _buildBillingListSection moved to components

  // Helper function to convert address abbreviations to full names
  String _expandAddressAbbreviations(String address) {
    if (address.isEmpty) return address;

    // Common Mongolian district abbreviations
    String expanded = address;

    // Replace abbreviations with full names
    expanded = expanded.replaceAll(RegExp(r'\bБГД\b'), 'Баянгол дүүрэг');
    expanded = expanded.replaceAll(RegExp(r'\bБЗД\b'), 'Баянзүрх дүүрэг');
    expanded = expanded.replaceAll(RegExp(r'\bСБД\b'), 'Сүхбаатар дүүрэг');
    expanded = expanded.replaceAll(RegExp(r'\bХД\b'), 'Хан-Уул дүүрэг');
    expanded = expanded.replaceAll(RegExp(r'\bЧД\b'), 'Чингэлтэй дүүрэг');
    expanded = expanded.replaceAll(RegExp(r'\bСД\b'), 'Сонгинохайрхан дүүрэг');

    return expanded;
  }

  // _buildBillingCard moved to BillingCard component

  Future<void> _showBillingDetailModal(Map<String, dynamic> billing) async {
    final billingId = billing['billingId']?.toString();
    if (billingId == null || billingId.isEmpty) {
      // If no billingId, show user profile data in modal
      if (!mounted) return;
      showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (context) => BillingDetailModal(
          billing: billing,
          billingData: {},
          bills: [],
          expandAddressAbbreviations: _expandAddressAbbreviations,
          formatNumberWithComma: _formatNumberWithComma,
        ),
      );
      return;
    }

    // Show loading
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => Center(
        child: CircularProgressIndicator(color: AppColors.goldPrimary),
      ),
    );

    try {
      // Fetch detailed billing information
      final billingData = await ApiService.getWalletBillingBills(
        billingId: billingId,
      );

      if (!mounted) return;
      Navigator.of(context).pop(); // Close loading

      // Extract bills from the response
      List<Map<String, dynamic>> bills = [];

      // Check if newBills is directly in billingData (correct structure)
      if (billingData['newBills'] != null && billingData['newBills'] is List) {
        final newBillsList = billingData['newBills'] as List;
        if (newBillsList.isNotEmpty) {
          final firstItem = newBillsList[0] as Map<String, dynamic>;
          // Check if this is a billing object (has billingId) or a bill object (has billId)
          if (firstItem.containsKey('billId')) {
            // It's a list of bills directly - correct structure
            bills = List<Map<String, dynamic>>.from(newBillsList);
          } else if (firstItem.containsKey('billingId') &&
              firstItem['newBills'] != null) {
            // It's incorrectly wrapped - extract bills from the nested billing object
            if (firstItem['newBills'] is List) {
              bills = List<Map<String, dynamic>>.from(firstItem['newBills']);
            }
          }
        }
      } else if (billingData.containsKey('billingId') &&
          billingData['newBills'] != null) {
        // If billingData itself is the billing object (correct structure)
        if (billingData['newBills'] is List) {
          bills = List<Map<String, dynamic>>.from(billingData['newBills']);
        }
      }

      // Show modal with billing details
      if (!mounted) return;
      showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (context) => BillingDetailModal(
          billing: billing,
          billingData: billingData,
          bills: bills,
          expandAddressAbbreviations: _expandAddressAbbreviations,
          formatNumberWithComma: _formatNumberWithComma,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      Navigator.of(context).pop(); // Close loading
      showGlassSnackBar(
        context,
        message: 'Биллингийн мэдээлэл авахад алдаа гарлаа: $e',
        icon: Icons.error,
        iconColor: Colors.red,
      );
    }
  }

  // All modal and helper methods moved to components
}
