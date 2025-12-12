import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:sukh_app/components/Menu/side_menu.dart';
// TODO: Uncomment when notification feature is implemented
// import 'package:sukh_app/components/Notifications/notification.dart';
import 'package:go_router/go_router.dart';
import 'package:sukh_app/services/storage_service.dart';
import 'package:sukh_app/services/api_service.dart';
import 'package:sukh_app/services/socket_service.dart';
import 'package:sukh_app/models/geree_model.dart';
import 'package:sukh_app/models/nekhemjlekh_cron_model.dart';
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
  int _currentBillerPage = 0;

  // Billing List
  List<Map<String, dynamic>> _billingList = [];
  bool _isLoadingBillingList = true;

  // User billing data from profile
  Map<String, dynamic>? _userBillingData;

  @override
  void initState() {
    super.initState();
    _loadBillers();
    _loadBillingList();
    _loadNotificationCount();
    _setupSocketListener();
  }

  void _setupSocketListener() {
    // Set up socket notification callback
    SocketService.instance.setNotificationCallback((notification) {
      // Refresh notification count when new notification arrives
      if (mounted) {
        print('📬 Home: Received socket notification, refreshing count');
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
      // Only log if it's not a 400 error (which might be expected if no notifications exist)
      if (!e.toString().contains('400')) {
        print('Error loading notification count: $e');
      }
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

            print(
              '📋 [BILLING] User billing data from profile: customerId=${userBillingData['customerId']}, customerCode=${userBillingData['customerCode']}, name=$fullName',
            );
          }
        }
      } catch (e) {
        print('User profile авахад алдаа гарлаа: $e');
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
          print(
            '📋 [BILLING] User billing data already exists in Wallet API list, skipping duplicate',
          );
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
        print('Биллингийн жагсаалт авахад алдаа гарлаа: $e');
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

  Future<void> _loadPaymentData() async {
    try {
      final userId = await StorageService.getUserId();
      final baiguullagiinId = await StorageService.getBaiguullagiinId();

      if (userId == null) {
        if (mounted) {
          setState(() {
            isLoadingPaymentData = false;
          });
        }
        return;
      }

      final gereeResponse = await ApiService.fetchGeree(userId).timeout(
        const Duration(seconds: 10),
        onTimeout: () {
          throw Exception('Сервертэй холбогдох хугацаа дууслаа');
        },
      );

      if (gereeResponse['jagsaalt'] != null &&
          gereeResponse['jagsaalt'] is List) {
        final List<dynamic> gereeJagsaalt = gereeResponse['jagsaalt'];

        if (gereeJagsaalt.isNotEmpty) {
          final firstContract = gereeJagsaalt[0];

          final geree = Geree.fromJson(firstContract);

          final nekhemjlekhResponse =
              await ApiService.fetchNekhemjlekhiinTuukh(
                gereeniiDugaar: geree.gereeniiDugaar,
              ).timeout(
                const Duration(seconds: 10),
                onTimeout: () {
                  throw Exception('Сервертэй холбогдох хугацаа дууслаа');
                },
              );

          double total = 0.0;
          DateTime? unpaidInvoiceDate;
          bool foundUnpaid = false;

          if (nekhemjlekhResponse['jagsaalt'] != null &&
              nekhemjlekhResponse['jagsaalt'] is List) {
            final List<dynamic> nekhemjlekhJagsaalt =
                nekhemjlekhResponse['jagsaalt'];

            for (var invoice in nekhemjlekhJagsaalt) {
              final tuluv = invoice['tuluv'];

              if (tuluv == 'Төлөөгүй') {
                foundUnpaid = true;
                final niitTulbur = invoice['niitTulbur'];
                if (niitTulbur != null) {
                  total += (niitTulbur is int)
                      ? niitTulbur.toDouble()
                      : (niitTulbur as double);
                }

                final nekhemjlekhiinOgnoo = invoice['nekhemjlekhiinOgnoo'];
                if (nekhemjlekhiinOgnoo != null) {
                  try {
                    final invoiceDate = DateTime.parse(
                      nekhemjlekhiinOgnoo.toString(),
                    );
                    if (unpaidInvoiceDate == null ||
                        invoiceDate.isBefore(unpaidInvoiceDate)) {
                      unpaidInvoiceDate = invoiceDate;
                    }
                  } catch (e) {
                    print('Error parsing invoice date: $e');
                  }
                }
              }
            }
          }

          int? cronDay;
          if (baiguullagiinId != null) {
            try {
              final cronResponse =
                  await ApiService.fetchNekhemjlekhCron(
                    baiguullagiinId: baiguullagiinId,
                  ).timeout(
                    const Duration(seconds: 10),
                    onTimeout: () {
                      throw Exception('Сервертэй холбогдох хугацаа дууслаа');
                    },
                  );

              if (cronResponse['success'] == true &&
                  cronResponse['data'] != null &&
                  cronResponse['data'] is List &&
                  (cronResponse['data'] as List).isNotEmpty) {
                final cronData = NekhemjlekhCron.fromJson(
                  cronResponse['data'][0],
                );
                cronDay = cronData.nekhemjlekhUusgekhOgnoo;
              }
            } catch (e) {
              print('Error fetching cron data: $e');
            }
          }

          DateTime? parsedDate;
          final gereeniiOgnoo = firstContract['gereeniiOgnoo'];
          if (gereeniiOgnoo != null && gereeniiOgnoo.toString().isNotEmpty) {
            try {
              parsedDate = DateTime.parse(gereeniiOgnoo.toString());
            } catch (e) {
              print('Error parsing date: $e');
            }
          }

          if (mounted) {
            setState(() {
              paymentDate = parsedDate;
              gereeData = geree;
              totalNiitTulbur = total;
              hasUnpaidInvoice = foundUnpaid;
              oldestUnpaidInvoiceDate = unpaidInvoiceDate;
              nekhemjlekhUusgekhOgnoo = cronDay;
              isLoadingPaymentData = false;
            });
          }
        } else {
          if (mounted) {
            setState(() {
              isLoadingPaymentData = false;
            });
          }
        }
      } else {
        if (mounted) {
          setState(() {
            isLoadingPaymentData = false;
          });
        }
      }
    } catch (e) {
      print('Төлбөрийн мэдээлэл татхад алдаа гарлаа: $e');
      if (mounted) {
        setState(() {
          isLoadingPaymentData = false;
        });

        final errorMessage = e.toString().contains('Интернэт холболт')
            ? 'Интернэт холболт тасарсан байна'
            : e.toString().contains('хугацаа дууслаа')
            ? 'Сервертэй холбогдох хугацаа дууслаа'
            : 'Төлбөрийн мэдээлэл татахад алдаа гарлаа';

        showGlassSnackBar(
          context,
          message: errorMessage,
          icon: Icons.error_outline,
          iconColor: Colors.red,
          textColor: Colors.white,
        );
      }
    }
  }

  int _calculateDaysDifference() {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    if (hasUnpaidInvoice && oldestUnpaidInvoiceDate != null) {
      final invoiceDate = DateTime(
        oldestUnpaidInvoiceDate!.year,
        oldestUnpaidInvoiceDate!.month,
        oldestUnpaidInvoiceDate!.day,
      );
      return today.difference(invoiceDate).inDays;
    }

    if (nekhemjlekhUusgekhOgnoo != null) {
      DateTime nextInvoiceDate;

      if (today.day < nekhemjlekhUusgekhOgnoo!) {
        nextInvoiceDate = DateTime(
          today.year,
          today.month,
          nekhemjlekhUusgekhOgnoo!,
        );
      } else {
        int nextMonth = today.month + 1;
        int nextYear = today.year;

        if (nextMonth > 12) {
          nextMonth = 1;
          nextYear++;
        }

        int daysInNextMonth = DateTime(nextYear, nextMonth + 1, 0).day;
        int invoiceDay = nekhemjlekhUusgekhOgnoo!;
        if (invoiceDay > daysInNextMonth) {
          invoiceDay = daysInNextMonth;
        }

        nextInvoiceDate = DateTime(nextYear, nextMonth, invoiceDay);
      }

      return nextInvoiceDate.difference(today).inDays;
    }

    if (paymentDate != null) {
      final payment = DateTime(
        paymentDate!.year,
        paymentDate!.month,
        paymentDate!.day,
      );
      return payment.difference(today).inDays;
    }

    return 0;
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

  Widget _buildInfoRow(String label, String value) {
    return Container(
      padding: EdgeInsets.symmetric(vertical: 10.h, horizontal: 12.w),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.white.withOpacity(0.1), width: 1),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Text(
            label,
            style: TextStyle(
              color: Colors.white.withOpacity(0.6),
              fontSize: 13.sp,
              fontWeight: FontWeight.w500,
            ),
          ),
          Flexible(
            child: Text(
              value,
              style: TextStyle(
                color: Colors.white,
                fontSize: 14.sp,
                fontWeight: FontWeight.w600,
              ),
              textAlign: TextAlign.right,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
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
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(100.r),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.25),
                            blurRadius: 12.w,
                            spreadRadius: 0,
                            offset: Offset(0, 4.h),
                          ),
                        ],
                      ),
                      child: Material(
                        color: Colors.transparent,
                        child: InkWell(
                          onTap: () {
                            _scaffoldKey.currentState?.openDrawer();
                          },
                          borderRadius: BorderRadius.circular(100.r),
                          child: Padding(
                            padding: EdgeInsets.all(10.w),
                            child: Icon(
                              Icons.menu_rounded,
                              color: Colors.white,
                              size: 26.sp,
                            ),
                          ),
                        ),
                      ),
                    ),
                    Row(
                      children: [
                        // Notification icon with badge
                        Stack(
                          clipBehavior: Clip.none,
                          children: [
                            Container(
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(100.r),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.25),
                                    blurRadius: 12.w,
                                    spreadRadius: 0,
                                    offset: Offset(0, 4.h),
                                  ),
                                ],
                              ),
                              child: Material(
                                color: Colors.transparent,
                                child: InkWell(
                                  onTap: () {
                                    // Navigate to notification list screen
                                    context.push('/medegdel-list').then((_) {
                                      // Refresh count when returning from list
                                      _loadNotificationCount();
                                    });
                                  },
                                  borderRadius: BorderRadius.circular(100.r),
                                  child: Padding(
                                    padding: EdgeInsets.all(10.w),
                                    child: Icon(
                                      Icons.notifications_outlined,
                                      color: Colors.white,
                                      size: 24.sp,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            if (_unreadNotificationCount > 0)
                              Positioned(
                                right: -2.w,
                                top: -2.h,
                                child: Container(
                                  padding: EdgeInsets.all(4.w),
                                  decoration: BoxDecoration(
                                    color: AppColors.secondaryAccent,
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                      color: AppColors.darkBackground,
                                      width: 2,
                                    ),
                                  ),
                                  constraints: BoxConstraints(
                                    minWidth: 18.w,
                                    minHeight: 18.w,
                                  ),
                                  child: Center(
                                    child: Text(
                                      _unreadNotificationCount > 99
                                          ? '99+'
                                          : '$_unreadNotificationCount',
                                      style: TextStyle(
                                        color: AppColors.darkBackground,
                                        fontSize: 10.sp,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                          ],
                        ),
                        SizedBox(width: 12.w),
                        Container(
                          decoration: BoxDecoration(
                            color: AppColors.secondaryAccent,
                            borderRadius: BorderRadius.circular(100.r),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.25),
                                blurRadius: 12.w,
                                spreadRadius: 0,
                                offset: Offset(0, 4.h),
                              ),
                            ],
                          ),
                          child: Material(
                            color: Colors.transparent,
                            child: InkWell(
                              onTap: _showPaymentModal,
                              borderRadius: BorderRadius.circular(100.r),
                              child: Padding(
                                padding: EdgeInsets.symmetric(
                                  horizontal: 18.w,
                                  vertical: 15.h,
                                ),
                                child: Text(
                                  'Төлөх',
                                  style: TextStyle(
                                    color: Colors.black,
                                    fontSize: 14.sp,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              Padding(
                padding: EdgeInsets.symmetric(horizontal: 16.w),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Нийт үлдэгдэл',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 15.sp,
                          ),
                        ),
                        SizedBox(height: 2.h),
                        Text(
                          '${_formatNumberWithComma(totalNiitTulbur)}₮',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 24.sp,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              SizedBox(height: 16.h),

              // Steps to Connect Billing Section
              _buildBillingConnectionSteps(),

              SizedBox(height: 16.h),

              // Billing List Section
              _buildBillingListSection(),

              SizedBox(height: 12.h),

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
                                fontSize: 16.sp,
                              ),
                            ),
                          ),
                        )
                      else
                        _buildBillersGrid(),

                      SizedBox(height: 12.h),
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

  Widget _buildPaymentDisplay() {
    final daysDifference = _calculateDaysDifference();
    final isOverdue = hasUnpaidInvoice && daysDifference > 0;
    final displayDays = daysDifference.abs();

    String subtitleText;
    if (isOverdue) {
      subtitleText = 'өдөр хэтэрсэн';
    } else if (hasUnpaidInvoice) {
      subtitleText = 'өдөр үлдсэн';
    } else {
      subtitleText = 'өдрийн дараа';
    }

    return Padding(
      padding: EdgeInsets.symmetric(vertical: 12.h, horizontal: 16.w),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Circular progress indicator with proper padding
          Padding(
            padding: EdgeInsets.all(10.w),
            child: SizedBox(
              width: 200.w,
              height: 200.w,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  // Background circle
                  SizedBox(
                    width: 200.w,
                    height: 200.w,
                    child: CircularProgressIndicator(
                      value: 1.0,
                      strokeWidth: 15.w,
                      backgroundColor: Colors.transparent,
                      valueColor: AlwaysStoppedAnimation<Color>(
                        Colors.white.withOpacity(0.1),
                      ),
                    ),
                  ),
                  // Progress circle
                  SizedBox(
                    width: 200.w,
                    height: 200.w,
                    child: CircularProgressIndicator(
                      value: isOverdue
                          ? 1.0
                          : (displayDays / 30).clamp(0.0, 1.0),
                      strokeWidth: 15.w,
                      backgroundColor: Colors.transparent,
                      valueColor: AlwaysStoppedAnimation<Color>(
                        isOverdue
                            ? const Color(0xFFFF6B6B)
                            : AppColors.secondaryAccent,
                      ),
                    ),
                  ),
                  // Center content
                  Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        displayDays.toString(),
                        style: TextStyle(
                          color: isOverdue
                              ? const Color(0xFFFF6B6B)
                              : AppColors.secondaryAccent,
                          fontSize: 65.sp,
                          fontWeight: FontWeight.bold,
                          height: 1,
                        ),
                      ),
                      SizedBox(height: 6.h),
                      Text(
                        subtitleText,
                        style: TextStyle(
                          color: Colors.white70,
                          fontSize: 14.sp,
                          fontWeight: FontWeight.w500,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),

          SizedBox(height: 12.h),

          // Payment date info
          Container(
            padding: EdgeInsets.symmetric(horizontal: 18.w, vertical: 10.h),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.1),
              borderRadius: BorderRadius.circular(50.r),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.calendar_today,
                  color: isOverdue ? const Color(0xFFFF6B6B) : Colors.white70,
                  size: 16.sp,
                ),
                SizedBox(width: 8.w),
                Text(
                  _getPaymentDateLabel(),
                  style: TextStyle(
                    color: isOverdue ? const Color(0xFFFF6B6B) : Colors.white,
                    fontSize: 12.sp,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _getPaymentDateLabel() {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    // If has unpaid invoice, show the unpaid invoice date
    if (hasUnpaidInvoice && oldestUnpaidInvoiceDate != null) {
      final year = oldestUnpaidInvoiceDate!.year;
      final month = oldestUnpaidInvoiceDate!.month;
      final day = oldestUnpaidInvoiceDate!.day;
      return 'Төлөх ёстой огноо: $year-${month.toString().padLeft(2, '0')}-${day.toString().padLeft(2, '0')}';
    }

    if (nekhemjlekhUusgekhOgnoo != null) {
      DateTime nextInvoiceDate;

      if (today.day < nekhemjlekhUusgekhOgnoo!) {
        nextInvoiceDate = DateTime(
          today.year,
          today.month,
          nekhemjlekhUusgekhOgnoo!,
        );
      } else {
        int nextMonth = today.month + 1;
        int nextYear = today.year;

        if (nextMonth > 12) {
          nextMonth = 1;
          nextYear++;
        }

        int daysInNextMonth = DateTime(nextYear, nextMonth + 1, 0).day;
        int invoiceDay = nekhemjlekhUusgekhOgnoo!;
        if (invoiceDay > daysInNextMonth) {
          invoiceDay = daysInNextMonth;
        }

        nextInvoiceDate = DateTime(nextYear, nextMonth, invoiceDay);
      }

      return 'Дараагийн нэхэмжлэх: ${nextInvoiceDate.year}-${nextInvoiceDate.month.toString().padLeft(2, '0')}-${nextInvoiceDate.day.toString().padLeft(2, '0')}';
    }

    // Fallback to payment date
    if (paymentDate != null) {
      final year = paymentDate!.year;
      final month = paymentDate!.month;
      final day = paymentDate!.day;
      return 'Төлбөрийн огноо: $year-${month.toString().padLeft(2, '0')}-${day.toString().padLeft(2, '0')}';
    }

    return '';
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
                    'Төлбөр төлөх',
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
                          '${_formatNumberWithComma(totalNiitTulbur)}₮',
                          style: TextStyle(
                            fontSize: 18.sp,
                            fontWeight: FontWeight.bold,
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
                      onPressed: () {
                        Navigator.pop(context);
                        context.push('/nekhemjlekh');
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.secondaryAccent,
                        foregroundColor: Colors.black,
                        padding: EdgeInsets.symmetric(vertical: 14.h),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12.w),
                        ),
                      ),
                      child: Text(
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
      ),
    );
  }

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
                SizedBox(height: 24.h),
                Text(
                  'Хөгжүүлэлт явагдаж байна',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 20.sp,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 16.h),
                Text(
                  'Энэ хуудас хөгжүүлэлт хийгдэж байгаа тул одоогоор ашиглах боломжгүй байна. Удахгүй ашиглах боломжтой болно.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 14.sp,
                    height: 1.5,
                  ),
                ),
                SizedBox(height: 24.h),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.of(context).pop();
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.goldPrimary,
                      foregroundColor: AppColors.darkBackground,
                      padding: EdgeInsets.symmetric(vertical: 14.h),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 0,
                    ),
                    child: Text(
                      'Ойлголоо',
                      style: TextStyle(
                        fontSize: 16.sp,
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

  Widget _buildBillingConnectionSteps() {
    // Only show if user has address but no connected billings
    if (_billingList.isNotEmpty || _isLoadingBillingList) {
      return const SizedBox.shrink();
    }

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 16.w),
      child: Container(
        padding: EdgeInsets.all(16.w),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              AppColors.goldPrimary.withOpacity(0.15),
              AppColors.goldPrimary.withOpacity(0.05),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(16.w),
          border: Border.all(
            color: AppColors.goldPrimary.withOpacity(0.3),
            width: 1.5,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: EdgeInsets.all(8.w),
                  decoration: BoxDecoration(
                    color: AppColors.goldPrimary.withOpacity(0.2),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.info_outline,
                    color: AppColors.goldPrimary,
                    size: 20.sp,
                  ),
                ),
                SizedBox(width: 12.w),
                Expanded(
                  child: Text(
                    'Биллинг холбох',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18.sp,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
            SizedBox(height: 16.h),
            Text(
              'Хаягаар биллинг олж холбох',
              style: TextStyle(
                color: Colors.white.withOpacity(0.8),
                fontSize: 14.sp,
              ),
            ),
            SizedBox(height: 16.h),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isConnectingBilling
                    ? null
                    : _connectBillingByAddress,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.goldPrimary,
                  foregroundColor: Colors.black,
                  padding: EdgeInsets.symmetric(vertical: 14.h),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12.w),
                  ),
                ),
                child: _isConnectingBilling
                    ? Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          SizedBox(
                            width: 20.w,
                            height: 20.w,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(
                                Colors.black,
                              ),
                            ),
                          ),
                          SizedBox(width: 12.w),
                          Text(
                            'Холбож байна...',
                            style: TextStyle(
                              fontSize: 16.sp,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      )
                    : Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.link, size: 20.sp),
                          SizedBox(width: 8.w),
                          Text(
                            'Биллинг холбох',
                            style: TextStyle(
                              fontSize: 16.sp,
                              fontWeight: FontWeight.w600,
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
  }

  Widget _buildBillingListSection() {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 16.w),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (_isLoadingBillingList)
            Container(
              padding: EdgeInsets.all(16.w),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.05),
                borderRadius: BorderRadius.circular(12.w),
                border: Border.all(
                  color: Colors.white.withOpacity(0.1),
                  width: 1,
                ),
              ),
              child: Center(
                child: CircularProgressIndicator(
                  color: AppColors.goldPrimary,
                  strokeWidth: 2,
                ),
              ),
            )
          else if (_billingList.isEmpty && _userBillingData == null)
            Container(
              padding: EdgeInsets.all(16.w),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.05),
                borderRadius: BorderRadius.circular(12.w),
                border: Border.all(
                  color: Colors.white.withOpacity(0.1),
                  width: 1,
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.info_outline,
                    color: Colors.white.withOpacity(0.6),
                    size: 20.sp,
                  ),
                  SizedBox(width: 12.w),
                  Expanded(
                    child: Text(
                      'Холбогдсон биллинг байхгүй байна',
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.6),
                        fontSize: 14.sp,
                      ),
                    ),
                  ),
                ],
              ),
            )
          else ...[
            // Show user billing data if available (from profile)
            if (_userBillingData != null) _buildBillingCard(_userBillingData!),
            // Show connected billings from Wallet API
            ..._billingList.map((billing) => _buildBillingCard(billing)),
          ],
        ],
      ),
    );
  }

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

  Widget _buildBillingCard(Map<String, dynamic> billing) {
    // Get customer name - combine ovog and ner if available, or use ner/customerName
    String customerName = '';
    if (billing['ovog'] != null && billing['ovog'].toString().isNotEmpty) {
      customerName = billing['ovog'].toString();
      if (billing['ner'] != null && billing['ner'].toString().isNotEmpty) {
        customerName += ' ${billing['ner'].toString()}';
      }
    } else if (billing['ner'] != null && billing['ner'].toString().isNotEmpty) {
      customerName = billing['ner'].toString();
    } else if (billing['customerName'] != null &&
        billing['customerName'].toString().isNotEmpty) {
      customerName = billing['customerName'].toString();
    }

    final billingName =
        billing['billingName']?.toString() ??
        (customerName.isNotEmpty ? customerName : 'Биллинг');
    final customerCode =
        billing['customerCode']?.toString() ??
        billing['walletCustomerCode']?.toString() ??
        '';
    final billerCode = billing['billerCode']?.toString() ?? '';
    final bairniiNer =
        billing['bairniiNer']?.toString() ??
        billing['customerAddress']?.toString() ??
        '';
    final doorNo = billing['walletDoorNo']?.toString() ?? '';
    final isLocalData = billing['isLocalData'] == true;

    // New fields from updated API
    final hasPayableBills = billing['hasPayableBills'] == true;
    final payableBillCount =
        (billing['payableBillCount'] as num?)?.toInt() ?? 0;
    final payableBillAmount =
        (billing['payableBillAmount'] as num?)?.toDouble() ?? 0.0;
    final hasNewBills = billing['hasNewBills'] == true;
    final newBillsCount = (billing['newBillsCount'] as num?)?.toInt() ?? 0;

    return GestureDetector(
      onTap: () => _showBillingDetailModal(billing),
      child: Container(
        margin: EdgeInsets.only(bottom: 10.h),
        padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              AppColors.goldPrimary.withOpacity(0.15),
              AppColors.goldPrimary.withOpacity(0.08),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(16.r),
          border: Border.all(
            color: AppColors.goldPrimary.withOpacity(0.3),
            width: 1,
          ),
        ),
        child: Row(
          children: [
            // Icon
            Container(
              padding: EdgeInsets.all(10.w),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    AppColors.goldPrimary.withOpacity(0.25),
                    AppColors.goldPrimary.withOpacity(0.1),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(12.r),
              ),
              child: Icon(
                Icons.home_rounded,
                color: AppColors.goldPrimary,
                size: 22.sp,
              ),
            ),
            SizedBox(width: 14.w),
            // Content
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Customer name / Billing name
                  if (customerName.isNotEmpty) ...[
                    Text(
                      customerName,
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 15.sp,
                        fontWeight: FontWeight.bold,
                        letterSpacing: -0.2,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (billingName != customerName &&
                        billingName != 'Биллинг') ...[
                      SizedBox(height: 2.h),
                      Text(
                        billingName,
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.7),
                          fontSize: 12.sp,
                          fontWeight: FontWeight.w500,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ] else ...[
                    Text(
                      billingName,
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 15.sp,
                        fontWeight: FontWeight.bold,
                        letterSpacing: -0.2,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                  SizedBox(height: 4.h),
                  // Address or code
                  if (bairniiNer.isNotEmpty) ...[
                    Row(
                      children: [
                        Icon(
                          Icons.location_on_rounded,
                          color: Colors.white.withOpacity(0.6),
                          size: 12.sp,
                        ),
                        SizedBox(width: 4.w),
                        Expanded(
                          child: Text(
                            '${_expandAddressAbbreviations(bairniiNer)}${doorNo.isNotEmpty ? ", $doorNo" : ""}',
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.7),
                              fontSize: 11.sp,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ] else if (customerCode.isNotEmpty) ...[
                    Row(
                      children: [
                        Icon(
                          Icons.tag_rounded,
                          color: Colors.white.withOpacity(0.6),
                          size: 12.sp,
                        ),
                        SizedBox(width: 4.w),
                        Text(
                          customerCode,
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.7),
                            fontSize: 11.sp,
                          ),
                        ),
                      ],
                    ),
                  ],
                  // Badges
                  if ((hasPayableBills && payableBillCount > 0) ||
                      (hasNewBills && newBillsCount > 0)) ...[
                    SizedBox(height: 6.h),
                    Wrap(
                      spacing: 6.w,
                      runSpacing: 4.h,
                      children: [
                        if (hasPayableBills && payableBillCount > 0)
                          Container(
                            padding: EdgeInsets.symmetric(
                              horizontal: 8.w,
                              vertical: 4.h,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.orange.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(8.r),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.warning_amber_rounded,
                                  color: Colors.orange,
                                  size: 12.sp,
                                ),
                                SizedBox(width: 4.w),
                                Text(
                                  '$payableBillCount төлөх',
                                  style: TextStyle(
                                    color: Colors.orange,
                                    fontSize: 10.sp,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        if (hasNewBills && newBillsCount > 0)
                          Container(
                            padding: EdgeInsets.symmetric(
                              horizontal: 8.w,
                              vertical: 4.h,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.blue.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(8.r),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.new_releases_rounded,
                                  color: Colors.blue,
                                  size: 12.sp,
                                ),
                                SizedBox(width: 4.w),
                                Text(
                                  '$newBillsCount шинэ',
                                  style: TextStyle(
                                    color: Colors.blue,
                                    fontSize: 10.sp,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _showBillingDetailModal(Map<String, dynamic> billing) async {
    final billingId = billing['billingId']?.toString();
    if (billingId == null || billingId.isEmpty) {
      // If no billingId, show user profile data in modal
      _showBillingInfoModal(billing);
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
      print('📄 [MODAL] Billing data received: $billingData');
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
            print(
              '📄 [MODAL] Extracted ${bills.length} bills directly from newBills',
            );
          } else if (firstItem.containsKey('billingId') &&
              firstItem['newBills'] != null) {
            // It's incorrectly wrapped - extract bills from the nested billing object
            if (firstItem['newBills'] is List) {
              bills = List<Map<String, dynamic>>.from(firstItem['newBills']);
              print(
                '📄 [MODAL] Extracted ${bills.length} bills from nested billing object (incorrectly wrapped)',
              );
            }
          }
        }
      } else if (billingData.containsKey('billingId') &&
          billingData['newBills'] != null) {
        // If billingData itself is the billing object (correct structure)
        if (billingData['newBills'] is List) {
          bills = List<Map<String, dynamic>>.from(billingData['newBills']);
          print(
            '📄 [MODAL] Extracted ${bills.length} bills from billing object',
          );
        }
      } else {
        print('📄 [MODAL] newBills is null or missing in billingData');
      }

      // Show modal with billing details
      _showBillingDetailModalWithData(billing, billingData, bills);
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

  void _showBillingInfoModal(Map<String, dynamic> billing) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.7,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [const Color(0xFF1A1A1A), const Color(0xFF0F0F0F)],
          ),
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(24.r),
            topRight: Radius.circular(24.r),
          ),
        ),
        child: Column(
          children: [
            // Modern Header
            Container(
              padding: EdgeInsets.fromLTRB(20.w, 16.h, 12.w, 16.h),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    AppColors.goldPrimary.withOpacity(0.1),
                    Colors.transparent,
                  ],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
                border: Border(
                  bottom: BorderSide(
                    color: Colors.white.withOpacity(0.1),
                    width: 1,
                  ),
                ),
              ),
              child: Row(
                children: [
                  Container(
                    padding: EdgeInsets.all(10.w),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          AppColors.goldPrimary.withOpacity(0.3),
                          AppColors.goldPrimary.withOpacity(0.15),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(12.r),
                    ),
                    child: Icon(
                      Icons.home_rounded,
                      color: AppColors.goldPrimary,
                      size: 24.sp,
                    ),
                  ),
                  SizedBox(width: 12.w),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          billing['billingName']?.toString() ??
                              'Биллингийн мэдээлэл',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 20.sp,
                            fontWeight: FontWeight.bold,
                            letterSpacing: -0.5,
                          ),
                        ),
                        if (billing['customerName']?.toString() != null) ...[
                          SizedBox(height: 4.h),
                          Text(
                            billing['customerName'].toString(),
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.7),
                              fontSize: 14.sp,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  IconButton(
                    icon: Container(
                      padding: EdgeInsets.all(8.w),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.1),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.close_rounded,
                        color: Colors.white,
                        size: 20.sp,
                      ),
                    ),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
            ),
            // Content
            Expanded(
              child: SingleChildScrollView(
                padding: EdgeInsets.all(20.w),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: EdgeInsets.all(18.w),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            Colors.white.withOpacity(0.08),
                            Colors.white.withOpacity(0.03),
                          ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(18.r),
                        border: Border.all(
                          color: Colors.white.withOpacity(0.15),
                          width: 1,
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(
                                Icons.info_outline_rounded,
                                color: AppColors.goldPrimary,
                                size: 20.sp,
                              ),
                              SizedBox(width: 8.w),
                              Text(
                                'Мэдээлэл',
                                style: TextStyle(
                                  color: AppColors.goldPrimary,
                                  fontSize: 16.sp,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                          SizedBox(height: 16.h),
                          _buildModernModalInfoRow(
                            Icons.person_outline_rounded,
                            'Харилцагчийн нэр',
                            billing['customerName']?.toString() ?? '',
                          ),
                          if (billing['customerCode']?.toString() != null) ...[
                            SizedBox(height: 12.h),
                            _buildModernModalInfoRow(
                              Icons.tag_rounded,
                              'Харилцагчийн код',
                              billing['customerCode'].toString(),
                            ),
                          ],
                          if (billing['bairniiNer']?.toString() != null ||
                              billing['customerAddress']?.toString() !=
                                  null) ...[
                            SizedBox(height: 12.h),
                            _buildModernModalInfoRow(
                              Icons.location_on_rounded,
                              'Хаяг',
                              _expandAddressAbbreviations(
                                billing['bairniiNer']?.toString() ??
                                    billing['customerAddress']?.toString() ??
                                    '',
                              ),
                            ),
                          ],
                          if (billing['walletDoorNo']?.toString() != null) ...[
                            SizedBox(height: 12.h),
                            _buildModernModalInfoRow(
                              Icons.door_front_door_rounded,
                              'Орц',
                              billing['walletDoorNo'].toString(),
                            ),
                          ],
                        ],
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
  }

  void _showBillingDetailModalWithData(
    Map<String, dynamic> billing,
    Map<String, dynamic> billingData,
    List<Map<String, dynamic>> bills,
  ) {
    final billingName =
        billingData['billingName']?.toString() ??
        billing['billingName']?.toString() ??
        'Биллингийн мэдээлэл';
    final customerName =
        billingData['customerName']?.toString() ??
        billing['customerName']?.toString() ??
        '';
    final customerAddress =
        billingData['customerAddress']?.toString() ??
        billing['bairniiNer']?.toString() ??
        billing['customerAddress']?.toString() ??
        '';
    final hasNewBills = billingData['hasNewBills'] == true;
    final newBillsCount = (billingData['newBillsCount'] as num?)?.toInt() ?? 0;
    final newBillsAmount =
        (billingData['newBillsAmount'] as num?)?.toDouble() ?? 0.0;
    final hiddenBillCount =
        (billingData['hiddenBillCount'] as num?)?.toInt() ?? 0;
    final paidCount = (billingData['paidCount'] as num?)?.toInt() ?? 0;
    final paidTotal = (billingData['paidTotal'] as num?)?.toDouble() ?? 0.0;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.9,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [const Color(0xFF1A1A1A), const Color(0xFF0F0F0F)],
          ),
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(24.r),
            topRight: Radius.circular(24.r),
          ),
        ),
        child: Column(
          children: [
            // Modern Header
            Container(
              padding: EdgeInsets.fromLTRB(20.w, 16.h, 12.w, 16.h),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    AppColors.goldPrimary.withOpacity(0.1),
                    Colors.transparent,
                  ],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
                border: Border(
                  bottom: BorderSide(
                    color: Colors.white.withOpacity(0.1),
                    width: 1,
                  ),
                ),
              ),
              child: Row(
                children: [
                  Container(
                    padding: EdgeInsets.all(10.w),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          AppColors.goldPrimary.withOpacity(0.3),
                          AppColors.goldPrimary.withOpacity(0.15),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(12.r),
                    ),
                    child: Icon(
                      Icons.home_rounded,
                      color: AppColors.goldPrimary,
                      size: 24.sp,
                    ),
                  ),
                  SizedBox(width: 12.w),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          billingName,
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 20.sp,
                            fontWeight: FontWeight.bold,
                            letterSpacing: -0.5,
                          ),
                        ),
                        if (customerName.isNotEmpty) ...[
                          SizedBox(height: 4.h),
                          Text(
                            customerName,
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.7),
                              fontSize: 14.sp,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  IconButton(
                    icon: Container(
                      padding: EdgeInsets.all(8.w),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.1),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.close_rounded,
                        color: Colors.white,
                        size: 20.sp,
                      ),
                    ),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
            ),
            // Content
            Expanded(
              child: SingleChildScrollView(
                padding: EdgeInsets.all(20.w),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Billing Info Section
                    Container(
                      padding: EdgeInsets.all(18.w),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            Colors.white.withOpacity(0.08),
                            Colors.white.withOpacity(0.03),
                          ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(18.r),
                        border: Border.all(
                          color: Colors.white.withOpacity(0.15),
                          width: 1,
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(
                                Icons.info_outline_rounded,
                                color: AppColors.goldPrimary,
                                size: 20.sp,
                              ),
                              SizedBox(width: 8.w),
                              Text(
                                'Биллингийн мэдээлэл',
                                style: TextStyle(
                                  color: AppColors.goldPrimary,
                                  fontSize: 16.sp,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                          SizedBox(height: 16.h),
                          if (billing['customerCode']?.toString() != null)
                            _buildModernModalInfoRow(
                              Icons.tag_rounded,
                              'Харилцагчийн код',
                              billing['customerCode'].toString(),
                            ),
                          if (customerAddress.isNotEmpty) ...[
                            if (billing['customerCode']?.toString() != null)
                              SizedBox(height: 12.h),
                            _buildModernModalInfoRow(
                              Icons.location_on_rounded,
                              'Хаяг',
                              _expandAddressAbbreviations(customerAddress),
                            ),
                          ],
                          if (billing['walletDoorNo']?.toString() != null) ...[
                            SizedBox(height: 12.h),
                            _buildModernModalInfoRow(
                              Icons.door_front_door_rounded,
                              'Орц',
                              billing['walletDoorNo'].toString(),
                            ),
                          ],
                          if (hasNewBills && newBillsCount > 0) ...[
                            SizedBox(height: 16.h),
                            Container(
                              padding: EdgeInsets.all(14.w),
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [
                                    Colors.blue.withOpacity(0.2),
                                    Colors.blue.withOpacity(0.1),
                                  ],
                                ),
                                borderRadius: BorderRadius.circular(12.r),
                                border: Border.all(
                                  color: Colors.blue.withOpacity(0.4),
                                  width: 1,
                                ),
                              ),
                              child: Row(
                                children: [
                                  Container(
                                    padding: EdgeInsets.all(8.w),
                                    decoration: BoxDecoration(
                                      color: Colors.blue.withOpacity(0.2),
                                      borderRadius: BorderRadius.circular(8.r),
                                    ),
                                    child: Icon(
                                      Icons.new_releases_rounded,
                                      color: Colors.blue,
                                      size: 20.sp,
                                    ),
                                  ),
                                  SizedBox(width: 12.w),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          'Шинэ билл: $newBillsCount',
                                          style: TextStyle(
                                            color: Colors.blue,
                                            fontSize: 15.sp,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                        if (newBillsAmount > 0) ...[
                                          SizedBox(height: 4.h),
                                          Text(
                                            'Дүн: ${_formatNumberWithComma(newBillsAmount)}₮',
                                            style: TextStyle(
                                              color: Colors.blue.withOpacity(
                                                0.8,
                                              ),
                                              fontSize: 13.sp,
                                            ),
                                          ),
                                        ],
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                          if (hiddenBillCount > 0) ...[
                            SizedBox(height: 12.h),
                            Row(
                              children: [
                                Icon(
                                  Icons.visibility_off_rounded,
                                  color: Colors.white.withOpacity(0.6),
                                  size: 16.sp,
                                ),
                                SizedBox(width: 8.w),
                                Text(
                                  'Нуугдсан билл: $hiddenBillCount',
                                  style: TextStyle(
                                    color: Colors.white.withOpacity(0.6),
                                    fontSize: 13.sp,
                                  ),
                                ),
                              ],
                            ),
                          ],
                          if (paidCount > 0) ...[
                            SizedBox(height: 12.h),
                            Row(
                              children: [
                                Icon(
                                  Icons.check_circle_rounded,
                                  color: Colors.green,
                                  size: 16.sp,
                                ),
                                SizedBox(width: 8.w),
                                Text(
                                  'Төлсөн: $paidCount билл, ${_formatNumberWithComma(paidTotal)}₮',
                                  style: TextStyle(
                                    color: Colors.green,
                                    fontSize: 13.sp,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ],
                      ),
                    ),
                    SizedBox(height: 20.h),
                    // Bills Section Header
                    Row(
                      children: [
                        Container(
                          padding: EdgeInsets.all(8.w),
                          decoration: BoxDecoration(
                            color: AppColors.goldPrimary.withOpacity(0.15),
                            borderRadius: BorderRadius.circular(8.r),
                          ),
                          child: Icon(
                            Icons.receipt_long_rounded,
                            color: AppColors.goldPrimary,
                            size: 20.sp,
                          ),
                        ),
                        SizedBox(width: 10.w),
                        Text(
                          'Биллүүд (${bills.length})',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 18.sp,
                            fontWeight: FontWeight.bold,
                            letterSpacing: -0.3,
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 16.h),
                    if (bills.isEmpty)
                      Container(
                        padding: EdgeInsets.all(24.w),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              Colors.white.withOpacity(0.05),
                              Colors.white.withOpacity(0.02),
                            ],
                          ),
                          borderRadius: BorderRadius.circular(16.r),
                          border: Border.all(
                            color: Colors.white.withOpacity(0.1),
                            width: 1,
                          ),
                        ),
                        child: Center(
                          child: Column(
                            children: [
                              Icon(
                                Icons.receipt_long_outlined,
                                color: Colors.white.withOpacity(0.4),
                                size: 48.sp,
                              ),
                              SizedBox(height: 12.h),
                              Text(
                                'Билл байхгүй байна',
                                style: TextStyle(
                                  color: Colors.white.withOpacity(0.6),
                                  fontSize: 15.sp,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ),
                      )
                    else
                      ...bills.map((bill) => _buildBillCard(bill)),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBillCard(Map<String, dynamic> bill) {
    final billNo = bill['billNo']?.toString() ?? '';
    final billType = bill['billtype']?.toString() ?? '';
    final billerName = bill['billerName']?.toString() ?? '';
    final billPeriod = bill['billPeriod']?.toString() ?? '';
    final billTotalAmount =
        (bill['billTotalAmount'] as num?)?.toDouble() ?? 0.0;
    final billAmount = (bill['billAmount'] as num?)?.toDouble() ?? 0.0;
    final billLateFee = (bill['billLateFee'] as num?)?.toDouble() ?? 0.0;
    final isNew = bill['isNew'] == true;
    final hasVat = bill['hasVat'] == true;

    return Container(
      margin: EdgeInsets.only(bottom: 14.h),
      padding: EdgeInsets.all(18.w),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Colors.white.withOpacity(0.08),
            Colors.white.withOpacity(0.03),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(color: Colors.white.withOpacity(0.15), width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: EdgeInsets.all(10.w),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      AppColors.goldPrimary.withOpacity(0.2),
                      AppColors.goldPrimary.withOpacity(0.1),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(10.r),
                ),
                child: Icon(
                  Icons.receipt_rounded,
                  color: AppColors.goldPrimary,
                  size: 22.sp,
                ),
              ),
              SizedBox(width: 12.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            billType,
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 16.sp,
                              fontWeight: FontWeight.bold,
                              letterSpacing: -0.3,
                            ),
                          ),
                        ),
                        if (isNew)
                          Container(
                            padding: EdgeInsets.symmetric(
                              horizontal: 8.w,
                              vertical: 4.h,
                            ),
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [
                                  Colors.blue.withOpacity(0.25),
                                  Colors.blue.withOpacity(0.15),
                                ],
                              ),
                              borderRadius: BorderRadius.circular(8.r),
                              border: Border.all(
                                color: Colors.blue.withOpacity(0.4),
                                width: 1,
                              ),
                            ),
                            child: Text(
                              'Шинэ',
                              style: TextStyle(
                                color: Colors.blue,
                                fontSize: 11.sp,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                      ],
                    ),
                    if (billerName.isNotEmpty) ...[
                      SizedBox(height: 6.h),
                      Row(
                        children: [
                          Icon(
                            Icons.business_rounded,
                            color: Colors.white.withOpacity(0.6),
                            size: 14.sp,
                          ),
                          SizedBox(width: 6.w),
                          Expanded(
                            child: Text(
                              billerName,
                              style: TextStyle(
                                color: Colors.white.withOpacity(0.7),
                                fontSize: 12.sp,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ],
                    if (billNo.isNotEmpty || billPeriod.isNotEmpty) ...[
                      SizedBox(height: 6.h),
                      Wrap(
                        spacing: 12.w,
                        children: [
                          if (billNo.isNotEmpty)
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.numbers_rounded,
                                  color: Colors.white.withOpacity(0.6),
                                  size: 14.sp,
                                ),
                                SizedBox(width: 4.w),
                                Text(
                                  billNo,
                                  style: TextStyle(
                                    color: Colors.white.withOpacity(0.7),
                                    fontSize: 12.sp,
                                  ),
                                ),
                              ],
                            ),
                          if (billPeriod.isNotEmpty)
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.calendar_today_rounded,
                                  color: Colors.white.withOpacity(0.6),
                                  size: 14.sp,
                                ),
                                SizedBox(width: 4.w),
                                Text(
                                  billPeriod,
                                  style: TextStyle(
                                    color: Colors.white.withOpacity(0.7),
                                    fontSize: 12.sp,
                                  ),
                                ),
                              ],
                            ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
          SizedBox(height: 16.h),
          Container(
            padding: EdgeInsets.all(14.w),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Colors.white.withOpacity(0.05),
                  Colors.white.withOpacity(0.02),
                ],
              ),
              borderRadius: BorderRadius.circular(12.r),
              border: Border.all(
                color: Colors.white.withOpacity(0.1),
                width: 1,
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Үндсэн дүн',
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.6),
                        fontSize: 11.sp,
                      ),
                    ),
                    SizedBox(height: 4.h),
                    Text(
                      '${_formatNumberWithComma(billAmount)}₮',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 15.sp,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
                if (billLateFee > 0) ...[
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Text(
                        'Хоцролт',
                        style: TextStyle(
                          color: Colors.orange.withOpacity(0.8),
                          fontSize: 11.sp,
                        ),
                      ),
                      SizedBox(height: 4.h),
                      Text(
                        '${_formatNumberWithComma(billLateFee)}₮',
                        style: TextStyle(
                          color: Colors.orange,
                          fontSize: 15.sp,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ],
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      'Нийт дүн',
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.6),
                        fontSize: 11.sp,
                      ),
                    ),
                    SizedBox(height: 4.h),
                    Text(
                      '${_formatNumberWithComma(billTotalAmount)}₮',
                      style: TextStyle(
                        color: AppColors.goldPrimary,
                        fontSize: 18.sp,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          if (hasVat) ...[
            SizedBox(height: 10.h),
            Row(
              children: [
                Icon(
                  Icons.verified_rounded,
                  color: Colors.green.withOpacity(0.7),
                  size: 14.sp,
                ),
                SizedBox(width: 6.w),
                Text(
                  'НӨАТ-тай',
                  style: TextStyle(
                    color: Colors.green.withOpacity(0.8),
                    fontSize: 12.sp,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildModalInfoRow(String label, String value) {
    return Padding(
      padding: EdgeInsets.only(bottom: 12.h),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120.w,
            child: Text(
              label,
              style: TextStyle(
                color: Colors.white.withOpacity(0.6),
                fontSize: 14.sp,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                color: Colors.white,
                fontSize: 14.sp,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildModernModalInfoRow(IconData icon, String label, String value) {
    if (value.isEmpty) return const SizedBox.shrink();

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: EdgeInsets.all(8.w),
          decoration: BoxDecoration(
            color: AppColors.goldPrimary.withOpacity(0.15),
            borderRadius: BorderRadius.circular(8.r),
          ),
          child: Icon(icon, color: AppColors.goldPrimary, size: 18.sp),
        ),
        SizedBox(width: 12.w),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  color: Colors.white.withOpacity(0.6),
                  fontSize: 12.sp,
                  fontWeight: FontWeight.w500,
                ),
              ),
              SizedBox(height: 4.h),
              Text(
                value,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 15.sp,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildBillersGrid() {
    if (_billers.isEmpty) {
      return const SizedBox.shrink();
    }

    // Calculate number of pages (3 items per page)
    final totalPages = (_billers.length / 3).ceil();

    return Container(
      margin: EdgeInsets.only(bottom: 12.h),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 8.w),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Төлбөрийн үйлчилгээ',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 20.sp,
                    fontWeight: FontWeight.bold,
                    letterSpacing: -0.5,
                  ),
                ),
                if (totalPages > 1)
                  Row(
                    children: [
                      ...List.generate(totalPages, (index) {
                        return Container(
                          margin: EdgeInsets.only(left: 4.w),
                          width: _currentBillerPage == index ? 24.w : 8.w,
                          height: 8.h,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(4.r),
                            color: _currentBillerPage == index
                                ? AppColors.goldPrimary
                                : Colors.white.withOpacity(0.3),
                          ),
                        );
                      }),
                    ],
                  ),
              ],
            ),
          ),
          SizedBox(height: 12.h),
          // Carousel (2x2 grid, 4 items per page)
          SizedBox(
            height: 160.h, // Further reduced height
            child: PageView.builder(
              controller: _billerPageController,
              onPageChanged: (index) {
                setState(() {
                  _currentBillerPage = index;
                });
              },
              itemCount: totalPages,
              itemBuilder: (context, pageIndex) {
                // Get 3 items for this page
                final startIndex = pageIndex * 3;
                final endIndex = (startIndex + 3).clamp(0, _billers.length);
                final pageBillers = _billers.sublist(startIndex, endIndex);

                // Alternate layout: even pages = 2 squares top + 1 rectangle bottom
                // odd pages = 1 rectangle top + 2 squares bottom
                final isEvenPage = pageIndex % 2 == 0;

                return Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16.w),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: isEvenPage
                        ? [
                            // Even pages: 2 squares top, 1 rectangle bottom
                            Expanded(
                              child: Row(
                                children: [
                                  Expanded(
                                    child: Padding(
                                      padding: EdgeInsets.only(
                                        right: 3.w,
                                        bottom: 3.h,
                                      ),
                                      child: pageBillers.length > 0
                                          ? _buildModernBillerCard(
                                              pageBillers[0],
                                            )
                                          : const SizedBox.shrink(),
                                    ),
                                  ),
                                  Expanded(
                                    child: Padding(
                                      padding: EdgeInsets.only(
                                        left: 3.w,
                                        bottom: 3.h,
                                      ),
                                      child: pageBillers.length > 1
                                          ? _buildModernBillerCard(
                                              pageBillers[1],
                                            )
                                          : const SizedBox.shrink(),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            // Bottom rectangle
                            if (pageBillers.length > 2)
                              Expanded(
                                child: Padding(
                                  padding: EdgeInsets.only(top: 3.h),
                                  child: _buildRectangularBillerCard(
                                    pageBillers[2],
                                  ),
                                ),
                              )
                            else
                              const Spacer(),
                          ]
                        : [
                            // Odd pages: 1 rectangle top, 2 squares bottom
                            if (pageBillers.length > 0)
                              Expanded(
                                child: Padding(
                                  padding: EdgeInsets.only(bottom: 3.h),
                                  child: _buildRectangularBillerCard(
                                    pageBillers[0],
                                  ),
                                ),
                              )
                            else
                              const Spacer(),
                            // Bottom 2 squares
                            Expanded(
                              child: Row(
                                children: [
                                  Expanded(
                                    child: Padding(
                                      padding: EdgeInsets.only(
                                        right: 3.w,
                                        top: 3.h,
                                      ),
                                      child: pageBillers.length > 1
                                          ? _buildModernBillerCard(
                                              pageBillers[1],
                                            )
                                          : const SizedBox.shrink(),
                                    ),
                                  ),
                                  Expanded(
                                    child: Padding(
                                      padding: EdgeInsets.only(
                                        left: 3.w,
                                        top: 3.h,
                                      ),
                                      child: pageBillers.length > 2
                                          ? _buildModernBillerCard(
                                              pageBillers[2],
                                            )
                                          : const SizedBox.shrink(),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                  ),
                );
              },
            ),
          ),
          SizedBox(height: 12.h),
          // Services Grid (Зогсоол, Дуудлага үйлчилгээ)
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 16.w),
            child: Row(
              children: [
                // Зогсоол (Parking)
                Expanded(
                  child: GestureDetector(
                    onTap: () {
                      _showDevelopmentModal(context);
                    },
                    child: Container(
                      padding: EdgeInsets.symmetric(
                        vertical: 16.h,
                        horizontal: 12.w,
                      ),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            Colors.white.withOpacity(0.1),
                            Colors.white.withOpacity(0.05),
                          ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(12.w),
                        border: Border.all(
                          color: Colors.white.withOpacity(0.2),
                          width: 1,
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.local_parking_outlined,
                            color: AppColors.secondaryAccent,
                            size: 24.sp,
                          ),
                          SizedBox(width: 12.w),
                          Text(
                            'Зогсоол',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 14.sp,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                SizedBox(width: 12.w),
                // Дуудлага үйлчилгээ (Call service)
                Expanded(
                  child: GestureDetector(
                    onTap: () {
                      _showDevelopmentModal(context);
                    },
                    child: Container(
                      padding: EdgeInsets.symmetric(
                        vertical: 16.h,
                        horizontal: 12.w,
                      ),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            Colors.white.withOpacity(0.1),
                            Colors.white.withOpacity(0.05),
                          ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(12.w),
                        border: Border.all(
                          color: Colors.white.withOpacity(0.2),
                          width: 1,
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.phone_outlined,
                            color: AppColors.secondaryAccent,
                            size: 24.sp,
                          ),
                          SizedBox(width: 12.w),
                          Flexible(
                            child: Text(
                              'Дуудлага',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 14.sp,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
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

  Widget _buildRectangularBillerCard(Map<String, dynamic> biller) {
    final billerName =
        biller['billerName']?.toString() ??
        biller['name']?.toString() ??
        'Биллер';
    final description = biller['description']?.toString() ?? '';
    final billerCode =
        biller['billerCode']?.toString() ?? biller['code']?.toString() ?? '';

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          context.push(
            '/biller-detail',
            extra: {
              'billerCode': billerCode,
              'billerName': billerName,
              'description': description,
            },
          );
        },
        borderRadius: BorderRadius.circular(6.r),
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                Colors.white.withOpacity(0.1),
                Colors.white.withOpacity(0.05),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(6.r),
            border: Border.all(color: Colors.white.withOpacity(0.2), width: 1),
          ),
          padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 8.h),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Icon
              Icon(
                Icons.receipt_long_rounded,
                color: AppColors.secondaryAccent,
                size: 28.sp,
              ),
              SizedBox(width: 12.w),
              // Biller name
              Text(
                billerName,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 11.sp,
                  fontWeight: FontWeight.w600,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildModernBillerCard(Map<String, dynamic> biller) {
    final billerName =
        biller['billerName']?.toString() ??
        biller['name']?.toString() ??
        'Биллер';
    final description = biller['description']?.toString() ?? '';
    final billerCode =
        biller['billerCode']?.toString() ?? biller['code']?.toString() ?? '';

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          context.push(
            '/biller-detail',
            extra: {
              'billerCode': billerCode,
              'billerName': billerName,
              'description': description,
            },
          );
        },
        borderRadius: BorderRadius.circular(6.r),
        child: AspectRatio(
          aspectRatio: 1.0, // Make it square
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Colors.white.withOpacity(0.1),
                  Colors.white.withOpacity(0.05),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(6.r),
              border: Border.all(
                color: Colors.white.withOpacity(0.2),
                width: 1,
              ),
            ),
            padding: EdgeInsets.all(4.w),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // Icon (bigger, at top)
                Icon(
                  Icons.receipt_long_rounded,
                  color: AppColors.secondaryAccent,
                  size: 28.sp,
                ),
                SizedBox(height: 4.h),
                // Biller name (at bottom, same width)
                Expanded(
                  child: Center(
                    child: Text(
                      billerName,
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 11.sp,
                        fontWeight: FontWeight.w600,
                      ),
                      textAlign: TextAlign.center,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBillerCard(Map<String, dynamic> biller) {
    // Keep old method for backward compatibility if needed
    return _buildModernBillerCard(biller);
  }
}
