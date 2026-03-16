import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:sukh_app/components/Menu/side_menu.dart';
import 'package:sukh_app/components/Home/billing_connection_section.dart';
import 'package:sukh_app/components/Home/billing_list_section.dart';
import 'package:sukh_app/components/Home/billers_grid.dart';
import 'package:sukh_app/components/Home/total_balance_modal.dart';
import 'package:sukh_app/components/Home/billing_detail_modal.dart';
import 'package:sukh_app/services/storage_service.dart';
import 'package:sukh_app/services/api_service.dart';
import 'package:sukh_app/services/socket_service.dart';
import 'package:sukh_app/models/geree_model.dart';
import 'package:sukh_app/components/Nekhemjlekh/nekhemjlekh_models.dart';
import 'package:sukh_app/utils/nekhemjlekh_merge_util.dart';
import 'package:sukh_app/models/medegdel_model.dart';
import 'package:sukh_app/widgets/glass_snackbar.dart';
import 'package:sukh_app/utils/format_util.dart';
import 'package:sukh_app/constants/constants.dart';
import 'package:sukh_app/utils/theme_extensions.dart';
import 'package:sukh_app/utils/responsive_helper.dart';

class AppBackground extends StatelessWidget {
  final Widget child;
  const AppBackground({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(child: child);
  }
}

// Custom painter for circular progress indicator
class _CircularProgressPainter extends CustomPainter {
  final double progress;
  final Color color;
  final Color backgroundColor;
  final double strokeWidth;

  _CircularProgressPainter({
    required this.progress,
    required this.color,
    required this.backgroundColor,
    required this.strokeWidth,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.width - strokeWidth) / 2;

    // Draw background circle
    final backgroundPaint = Paint()
      ..color = backgroundColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    canvas.drawCircle(center, radius, backgroundPaint);

    // Draw progress arc
    final progressPaint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    final sweepAngle = 2 * math.pi * progress;
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -math.pi / 2, // Start from top
      sweepAngle,
      false,
      progressPaint,
    );
  }

  @override
  bool shouldRepaint(_CircularProgressPainter oldDelegate) {
    return oldDelegate.progress != progress ||
        oldDelegate.color != color ||
        oldDelegate.backgroundColor != backgroundColor ||
        oldDelegate.strokeWidth != strokeWidth;
  }
}

class NuurKhuudas extends StatefulWidget {
  const NuurKhuudas({super.key});

  @override
  State<NuurKhuudas> createState() => _BookingScreenState();
}

class _BookingScreenState extends State<NuurKhuudas>
    with SingleTickerProviderStateMixin, WidgetsBindingObserver {
  DateTime? paymentDate;
  bool isLoadingPaymentData = true;
  Geree? gereeData;
  GereeResponse? _gereeResponse;
  bool _isLoadingGeree = false;
  double totalNiitTulbur = 0.0;
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  // New variables for invoice tracking
  int? nekhemjlekhUusgekhOgnoo;
  DateTime? oldestUnpaidInvoiceDate;
  bool hasUnpaidInvoice = false;

  // Nekhemjlekh cron data for date calculation
  Map<String, dynamic>? _nekhemjlekhCronData;

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

  // GlobalKey to access BillingListSection state
  final GlobalKey<BillingListSectionState> _billingListSectionKey =
      GlobalKey<BillingListSectionState>();

  // Periodic refresh for balance (fallback when socket notification is missed)
  Timer? _balanceRefreshTimer;

  // Socket notification callback (single ref so we can remove in dispose and avoid duplicates)
  void Function(Map<String, dynamic>)? _notificationCallback;

  // Animation controller for circular progress
  late AnimationController _progressAnimationController;
  late Animation<double> _progressAnimation;

  @override
  void initState() {
    super.initState();
    // Initialize animation controller
    _progressAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );
    _progressAnimation = CurvedAnimation(
      parent: _progressAnimationController,
      curve: Curves.easeOutCubic,
    );

    WidgetsBinding.instance.addObserver(this);
    _loadBillers();
    _loadBillingList();
    _loadNotificationCount();
    _setupSocketListener();
    _loadGereeData();
    _loadNekhemjlekhCron(); // Load nekhemjlekh cron data for date calculation
    _loadAllBillingPayments(); // Load total balance on init
    _checkRecentWalletPayments(); // Check latest wallet payment status

    // Periodic balance refresh (every 60s) - fallback when socket notification is missed
    _balanceRefreshTimer = Timer.periodic(const Duration(seconds: 60), (_) {
      if (mounted) _loadAllBillingPayments();
    });

    // Trigger animation after a short delay to ensure data is loaded
    Future.delayed(const Duration(milliseconds: 300), () {
      if (mounted && _gereeResponse != null) {
        _progressAnimationController.forward();
      }
    });
  }

  DateTime? _lastBalanceRefresh;

  void _setupSocketListener() {
    if (_notificationCallback != null)
      return; // Already registered (single callback)
    _notificationCallback = (notification) {
      if (mounted) {
        _loadNotificationCount();
        final title = notification['title']?.toString() ?? '';
        final message = notification['message']?.toString() ?? '';
        final turul = notification['turul']?.toString().toLowerCase() ?? '';
        final guilgee = notification['guilgee'];
        final guilgeeTurul = guilgee is Map
            ? (guilgee['turul']?.toString().toLowerCase() ?? '')
            : '';
        final isInvoiceOrAvlaga =
            (guilgeeTurul == 'avlaga') ||
            title.toLowerCase().contains('нэхэмжлэх') ||
            title.toLowerCase().contains('авлага') ||
            title.toLowerCase().contains('нэмэгдлээ') ||
            message.toLowerCase().contains('нэхэмжлэх') ||
            message.toLowerCase().contains('авлага') ||
            message.toLowerCase().contains('нэмэгдлээ') ||
            message.toLowerCase().contains('manualsend') ||
            (turul == 'мэдэгдэл' || turul == 'medegdel' || turul == 'app');
        if (isInvoiceOrAvlaga) {
          Future.delayed(const Duration(milliseconds: 500), () {
            if (mounted) _loadAllBillingPayments();
          });
        }
      }
    };
    SocketService.instance.setNotificationCallback(_notificationCallback!);
    print('🔔 HOME: Socket listener callback registered');
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _loadNotificationCount();
    // Refresh balance when dependencies change (e.g. returning from nekhemjlekh)
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final now = DateTime.now();
      if (_lastBalanceRefresh == null ||
          now.difference(_lastBalanceRefresh!).inSeconds >= 2) {
        _lastBalanceRefresh = now;
        _loadAllBillingPayments();
      }
    });
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    if (state == AppLifecycleState.resumed && mounted) {
      _loadAllBillingPayments();
      _balanceRefreshTimer?.cancel();
      _balanceRefreshTimer = Timer.periodic(const Duration(seconds: 60), (_) {
        if (mounted) _loadAllBillingPayments();
      });
    } else if (state == AppLifecycleState.paused) {
      _balanceRefreshTimer?.cancel();
      _balanceRefreshTimer = null;
    }
  }

  @override
  void dispose() {
    _balanceRefreshTimer?.cancel();
    _balanceRefreshTimer = null;
    WidgetsBinding.instance.removeObserver(this);
    _billerPageController.dispose();
    _progressAnimationController.dispose();
    if (_notificationCallback != null) {
      SocketService.instance.removeNotificationCallback(_notificationCallback);
      _notificationCallback = null;
    }
    super.dispose();
  }

  Future<void> _loadNotificationCount() async {
    print('🔔 HOME: _loadNotificationCount() called');
    try {
      // Check if user is logged in first
      final isLoggedIn = await StorageService.isLoggedIn();
      if (!isLoggedIn) {
        print('🔔 HOME: User not logged in, skipping notification count');
        return;
      }

      print('🔔 HOME: Fetching notifications from API...');
      final response = await ApiService.fetchMedegdel();
      final medegdelResponse = MedegdelResponse.fromJson(response);
      final unreadCount = medegdelResponse.data
          .where((n) => !n.kharsanEsekh)
          .length;
      print('🔔 HOME: Unread notification count from API: $unreadCount');
      print('🔔 HOME: Current badge count: $_unreadNotificationCount');

      if (mounted) {
        // Use API count directly to avoid double counting
        setState(() {
          _unreadNotificationCount = unreadCount;
        });
        print('🔔 HOME: ✅ Notification badge updated to $unreadCount');
      } else {
        print('⚠️ HOME: Widget not mounted, cannot update badge');
      }
    } catch (e) {
      print('❌ HOME: Error loading notification count: $e');
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

  Future<void> _deleteBilling(Map<String, dynamic> billing) async {
    final billingId = billing['billingId']?.toString() ??
        billing['walletBillingId']?.toString();

    if (billingId == null) {
      if (billing['isLocalData'] == true) {
        showGlassSnackBar(
          context,
          message: 'Энэ биллинг API-тай холбогдоогүй байна.',
          icon: Icons.info_outline,
          iconColor: Colors.orange,
        );
      }
      return;
    }

    final bool? confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Биллинг устгах',
            style: TextStyle(color: context.textPrimaryColor)),
        content: Text('Та энэ биллингийг устгахдаа итгэлтэй байна уу?',
            style: TextStyle(color: context.textSecondaryColor)),
        backgroundColor: context.backgroundColor,
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text('Үгүй', style: TextStyle(color: AppColors.deepGreen)),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Тийм', style: TextStyle(color: Colors.redAccent)),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    try {
      await ApiService.removeWalletBilling(billingId: billingId);
      if (mounted) {
        showGlassSnackBar(
          context,
          message: 'Биллинг амжилттай устгагдлаа',
          icon: Icons.check_circle,
          iconColor: Colors.green,
        );
        _loadBillingList();
        _loadAllBillingPayments();
      }
    } catch (e) {
      if (mounted) {
        showGlassSnackBar(
          context,
          message: e.toString().replaceAll("Exception: ", ""),
          icon: Icons.error,
          iconColor: Colors.red,
        );
      }
    }
  }

  Future<void> _loadGereeData() async {
    setState(() {
      _isLoadingGeree = true;
    });

    try {
      final userId = await StorageService.getUserId();
      if (userId != null) {
        final response = await ApiService.fetchGeree(userId);
        if (mounted) {
          setState(() {
            _gereeResponse = GereeResponse.fromJson(response);
            _isLoadingGeree = false;
          });
          // Trigger animation when data loads
          _progressAnimationController.reset();
          _progressAnimationController.forward();
        }
      } else {
        if (mounted) {
          setState(() {
            _isLoadingGeree = false;
          });
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoadingGeree = false;
        });
      }
    }
  }

  Future<void> _loadNekhemjlekhCron() async {
    try {
      final barilgiinId = await StorageService.getBarilgiinId();

      if (barilgiinId != null) {
        final response = await ApiService.fetchNekhemjlekhCron(
          barilgiinId: barilgiinId,
        );

        if (mounted) {
          setState(() {
            // Handle both shapes:
            // 1) { success, data: { ... } }
            // 2) { success, data: [ { ... }, ... ] }
            final rawData = response['data'];

            if (rawData is Map<String, dynamic>) {
              // Check if this single record matches our barilgiinId
              final recordBarilgiinId = rawData['barilgiinId']?.toString();

              if (recordBarilgiinId == barilgiinId) {
                _nekhemjlekhCronData = rawData;
              } else {
                _nekhemjlekhCronData = null;
              }
            } else if (rawData is List) {
              if (rawData.isEmpty) {
                // Empty list is a valid response - just means no data
                _nekhemjlekhCronData = null;
              } else {
                // Filter list to find record matching barilgiinId
                final matchingRecords = rawData
                    .where(
                      (item) =>
                          item is Map<String, dynamic> &&
                          item['barilgiinId']?.toString() == barilgiinId,
                    )
                    .toList();

                if (matchingRecords.isNotEmpty) {
                  _nekhemjlekhCronData =
                      matchingRecords.first as Map<String, dynamic>;
                } else {
                  _nekhemjlekhCronData = null;
                }
              }
            } else {
              _nekhemjlekhCronData = null;
            }
          });
        }
      }
    } catch (e) {
      // Silent fail - date calculation will fallback to contract date
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
          textColor: context.textPrimaryColor,
        );
      }
    }
  }

  Future<void> _loadAllBillingPayments() async {
    try {
      double total = 0.0;
      _lastBalanceRefresh = DateTime.now();

      // If this is the wallet-only organization, skip OWN_ORG (nekhemjlekh) total
      final currentBaiguullagiinId = await StorageService.getBaiguullagiinId();
      final isWalletOnlyOrg =
          currentBaiguullagiinId == '698e7fd3b6dd386b6c56a808';

      if (!isWalletOnlyOrg) {
        // Load OWN_ORG payments - use merged invoices (nekhemjlekhiinTuukh + gereeniiTulukhAvlaga)
        // Same logic as nekhemjlekh screen so home header matches "Төлбөр төлөх" amount
        try {
          final userId = await StorageService.getUserId();
          if (userId != null) {
            final gereeResponse = await ApiService.fetchGeree(userId);
            if (gereeResponse['jagsaalt'] != null &&
                gereeResponse['jagsaalt'] is List) {
              final List<dynamic> gereeJagsaalt = gereeResponse['jagsaalt'];
              for (var c in gereeJagsaalt) {
                final contract = c is Map<String, dynamic>
                    ? c
                    : Map<String, dynamic>.from(c as Map);
                final gereeniiDugaar = contract['gereeniiDugaar']?.toString();
                if (gereeniiDugaar == null || gereeniiDugaar.isEmpty) continue;

                final baiguullagiinId = contract['baiguullagiinId']?.toString();
                final gereeniiId = contract['_id']?.toString();

                try {
                  final results = await Future.wait([
                    ApiService.fetchNekhemjlekhiinTuukh(
                      gereeniiDugaar: gereeniiDugaar,
                      khuudasniiDugaar: 1,
                      khuudasniiKhemjee: 200,
                    ),
                    baiguullagiinId != null
                        ? ApiService.fetchGereeniiTulukhAvlaga(
                            baiguullagiinId: baiguullagiinId,
                            gereeniiId: gereeniiId,
                          )
                        : Future.value({'jagsaalt': []}),
                  ]);

                  final response = results[0] as Map<String, dynamic>;
                  final tulukhAvlagaResponse =
                      results[1] as Map<String, dynamic>;

                  if (response['jagsaalt'] != null &&
                      response['jagsaalt'] is List) {
                    final rawInvoices = response['jagsaalt'] as List;
                    final tulukhAvlagaList =
                        tulukhAvlagaResponse['jagsaalt'] is List
                        ? (tulukhAvlagaResponse['jagsaalt'] as List)
                              .cast<Map<String, dynamic>>()
                        : <Map<String, dynamic>>[];

                    final mergedInvoices = mergeTulukhAvlagaIntoInvoices(
                      rawInvoices,
                      tulukhAvlagaList,
                      gereeniiId,
                      gereeniiDugaar,
                      userId,
                    );

                    // Sum uldegdel from the contract directly as requested by the user
                    // because it is the absolute source of truth for OWN_ORG.
                    final contractUldegdel = contract['uldegdel'] ?? contract['globalUldegdel'];
                    if (contractUldegdel != null) {
                      final amt = (contractUldegdel is num)
                          ? contractUldegdel.toDouble()
                          : (double.tryParse(contractUldegdel.toString()) ?? 0.0);
                      if (amt > 0) total += amt;
                    }
                  }
                } catch (_) {
                  // Fallback to contract uldegdel if invoice fetch fails
                  final contractUldegdel =
                      contract['uldegdel'] ?? contract['globalUldegdel'];
                  if (contractUldegdel != null) {
                    final amt = (contractUldegdel is num)
                        ? contractUldegdel.toDouble()
                        : (double.tryParse(contractUldegdel.toString()) ?? 0.0);
                    if (amt > 0) total += amt;
                  }
                }
              }
            }
          }
        } catch (e) {
          // Error loading OWN_ORG payments
        }
      }
      double internalTotal = total;

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

                // Deduplication: Avoid adding property fees from Wallet API if we already have them from OWN_ORG
                final billingName = billing['billingName']?.toString() ?? '';
                if (internalTotal > 0 && (billingName.contains('Орон сууцны') || billingName.contains('Property'))) {
                   // Skip this billing item to avoid double counting
                } else if (billingTotal > 0) {
                   total += billingTotal;
                }

              // Automatically trigger check for recent PAID payments to sync Ebarimt info
              if (billingData['payments'] != null && billingData['payments'] is List) {
                final payments = billingData['payments'] as List;
                if (payments.isNotEmpty) {
                  final latestPayment = payments[0];
                  final paymentId = latestPayment['paymentId']?.toString();
                  final status = latestPayment['paymentStatus']?.toString().toUpperCase();
                  if (paymentId != null && status == 'PAID') {
                    print('🔄 [HOME] Auto-syncing status for recent PAID payment: $paymentId');
                    // We call it silently without awaiting to not block UI
                    ApiService.walletQpayCheckStatus(walletPaymentId: paymentId).catchError((e) {
                      print('❌ [HOME] Auto-sync check failed for $paymentId: $e');
                    });
                  }
                }
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
          totalNiitTulbur = total;
        });
      }
    } catch (e) {
      // Silent fail - total will remain at current value
    }
  }

  Future<void> _checkRecentWalletPayments() async {
    try {
      // Fetch wallet history instead of using localStorage
      final history = await ApiService.fetchWalletQpayList();
      if (history.isNotEmpty) {
        // Find latest pending or recently paid payment
        final latest = history.first;
        final status = latest['status']?.toString().toUpperCase();
        final walletPaymentId = latest['walletPaymentId']?.toString();

        if (walletPaymentId != null && status == 'PENDING') {
          print('🔎 [HOME] Checking latest pending wallet payment: $walletPaymentId');
          final checkRes = await ApiService.walletQpayCheckStatus(
            walletPaymentId: walletPaymentId,
          );
          if (checkRes['status']?.toString().toUpperCase() == 'PAID') {
            print('✅ [HOME] Latest payment became PAID. Refreshing balance.');
            _loadAllBillingPayments();
          }
        }
      }
    } catch (e) {
      print('Error auto-checking wallet payments: $e');
    }
  }

  String _formatNumberWithComma(double number) {
    return formatNumber(number, 2);
  }

  int _calculateDaysPassed(String gereeniiOgnoo) {
    try {
      // Calculate days from user/contract created date (gereeniiOgnoo)
      // Do NOT use nekhemjlekhCron / previous month invoice date here.
      final contractDate = DateTime.parse(gereeniiOgnoo);
      final today = DateTime.now();
      final difference = today.difference(contractDate);
      return difference.inDays;
    } catch (e) {
      return 0;
    }
  }

  String _getNextUnitDate(String gereeniiOgnoo) {
    try {
      // Use nekhemjlekhUusgekhOgnoo if available
      if (_nekhemjlekhCronData != null &&
          _nekhemjlekhCronData!['nekhemjlekhUusgekhOgnoo'] != null) {
        final nekhemjlekhUusgekhOgnoo =
            _nekhemjlekhCronData!['nekhemjlekhUusgekhOgnoo'] as int;
        final today = DateTime.now();

        // Calculate next invoice date based on nekhemjlekhUusgekhOgnoo
        DateTime nextInvoiceDate;
        if (today.day >= nekhemjlekhUusgekhOgnoo) {
          // Next invoice will be next month
          final nextMonth = today.month == 12 ? 1 : today.month + 1;
          final nextYear = today.month == 12 ? today.year + 1 : today.year;
          nextInvoiceDate = DateTime(
            nextYear,
            nextMonth,
            nekhemjlekhUusgekhOgnoo,
          );
        } else {
          // Next invoice will be this month
          nextInvoiceDate = DateTime(
            today.year,
            today.month,
            nekhemjlekhUusgekhOgnoo,
          );
        }

        return '${nextInvoiceDate.year}-${nextInvoiceDate.month.toString().padLeft(2, '0')}-${nextInvoiceDate.day.toString().padLeft(2, '0')}';
      } else {
        // Fallback to contract date calculation
        final contractDate = DateTime.parse(gereeniiOgnoo);
        // Calculate next unit date (assuming monthly units, add 1 month)
        final nextUnit = DateTime(
          contractDate.year,
          contractDate.month + 1,
          contractDate.day,
        );
        return '${nextUnit.year}-${nextUnit.month.toString().padLeft(2, '0')}-${nextUnit.day.toString().padLeft(2, '0')}';
      }
    } catch (e) {
      return '';
    }
  }

  Widget _buildRemainingDaysWidget(Geree geree) {
    // Determine next invoice date from nekhemjlekhCron (if available)
    DateTime? nextInvoiceDate;
    if (_nekhemjlekhCronData != null &&
        _nekhemjlekhCronData!['nekhemjlekhUusgekhOgnoo'] != null) {
      // Handle different number types from JSON (int, double, string)
      final nekhemjlekhUusgekhOgnooValue =
          _nekhemjlekhCronData!['nekhemjlekhUusgekhOgnoo'];
      final nekhemjlekhUusgekhOgnoo = nekhemjlekhUusgekhOgnooValue is int
          ? nekhemjlekhUusgekhOgnooValue
          : (nekhemjlekhUusgekhOgnooValue is num
                ? nekhemjlekhUusgekhOgnooValue.toInt()
                : int.tryParse(nekhemjlekhUusgekhOgnooValue.toString()) ?? 0);
      final today = DateTime.now();

      debugPrint(
        '📅 [HOME] Date calculation: today=${today.year}-${today.month}-${today.day}, nekhemjlekhUusgekhOgnoo=$nekhemjlekhUusgekhOgnoo (type: ${nekhemjlekhUusgekhOgnooValue.runtimeType}), barilgiinId=${_nekhemjlekhCronData!['barilgiinId']}',
      );

      if (nekhemjlekhUusgekhOgnoo == 0 ||
          nekhemjlekhUusgekhOgnoo < 1 ||
          nekhemjlekhUusgekhOgnoo > 31) {
        debugPrint(
          '⚠️ [HOME] Invalid nekhemjlekhUusgekhOgnoo value ($nekhemjlekhUusgekhOgnoo), falling back to contract date',
        );
        // Don't set nextInvoiceDate, will fall back to contract date
      } else if (today.day >= nekhemjlekhUusgekhOgnoo) {
        // Next invoice will be next month
        final nextMonth = today.month == 12 ? 1 : today.month + 1;
        final nextYear = today.month == 12 ? today.year + 1 : today.year;
        nextInvoiceDate = DateTime(
          nextYear,
          nextMonth,
          nekhemjlekhUusgekhOgnoo,
        );
        debugPrint(
          '📅 [HOME] Next invoice date (next month): ${nextInvoiceDate.year}-${nextInvoiceDate.month}-${nextInvoiceDate.day}',
        );
      } else {
        // Next invoice will be this month
        nextInvoiceDate = DateTime(
          today.year,
          today.month,
          nekhemjlekhUusgekhOgnoo,
        );
        debugPrint(
          '📅 [HOME] Next invoice date (this month): ${nextInvoiceDate.year}-${nextInvoiceDate.month}-${nextInvoiceDate.day}',
        );
      }
    } else {
      debugPrint(
        '📅 [HOME] No nekhemjlekhCron data available for date calculation',
      );
    }

    final today = DateTime.now();
    final todayDateOnly = DateTime(today.year, today.month, today.day);

    int displayDays;
    String centerLabel;
    Color accentColor;
    double targetProgress;

    String nextUnitDateText = '';

    if (nextInvoiceDate != null) {
      final nextInvoiceDateOnly = DateTime(
        nextInvoiceDate.year,
        nextInvoiceDate.month,
        nextInvoiceDate.day,
      );

      // Check if the invoice date is today or in the future
      if (nextInvoiceDateOnly.isAfter(todayDateOnly) ||
          nextInvoiceDateOnly.isAtSameMomentAs(todayDateOnly)) {
        // Future invoice date (or today) → show remaining days in green
        final remainingDays = nextInvoiceDateOnly
            .difference(todayDateOnly)
            .inDays;
        displayDays = remainingDays;
        centerLabel = 'өдөр дутуу';
        accentColor = AppColors.deepGreen;
        nextUnitDateText =
            '${nextInvoiceDate.year}-${nextInvoiceDate.month.toString().padLeft(2, '0')}-${nextInvoiceDate.day.toString().padLeft(2, '0')}';

        debugPrint(
          '📅 [HOME] Showing future date: $nextUnitDateText, remaining days: $remainingDays',
        );

        // Progress: more filled as we get closer to the due date (assume 30-day cycle)
        final clampedRemaining = remainingDays > 30 ? 30 : remainingDays;
        targetProgress = 1.0 - (clampedRemaining / 30.0);
      } else {
        // Invoice date has passed, show as overdue
        final daysOverdue = todayDateOnly
            .difference(nextInvoiceDateOnly)
            .inDays;
        displayDays = daysOverdue;
        centerLabel = 'өдөр хэтэрсэн';
        accentColor = const Color(0xFFFF6B6B);
        nextUnitDateText =
            '${nextInvoiceDate.year}-${nextInvoiceDate.month.toString().padLeft(2, '0')}-${nextInvoiceDate.day.toString().padLeft(2, '0')}';
        targetProgress = 1.0;

        debugPrint(
          '📅 [HOME] Showing overdue date: $nextUnitDateText, days overdue: $daysOverdue',
        );
      }
    } else {
      // Fallback: show days passed since user/contract created date
      final daysPassed = _calculateDaysPassed(geree.gereeniiOgnoo);
      displayDays = daysPassed;
      centerLabel = 'өдөр өнгөрсөн';
      // Use salmon-pink color when showing passed days
      accentColor = const Color(0xFFFF6B6B);
      // Progress based on days passed in current 30-day cycle
      targetProgress = (daysPassed % 30) / 30.0;
      // For fallback, keep old next unit date behavior
      nextUnitDateText = _getNextUnitDate(geree.gereeniiOgnoo);
    }

    final isDark = context.isDarkMode;

    // Calculate circle size based on screen width
    final screenWidth = MediaQuery.of(context).size.width;
    final circleSize = (screenWidth * 0.45).clamp(140.0, 200.0);

    return Column(
      children: [
        // Clean circular dashboard
        Container(
          width: circleSize,
          height: circleSize,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: isDark ? const Color(0xFF1A1F26) : Colors.white,
            boxShadow: [
              BoxShadow(
                color: accentColor.withOpacity(0.15),
                blurRadius: 16,
                spreadRadius: 0,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Stack(
            alignment: Alignment.center,
            children: [
              // Progress ring
              SizedBox(
                width: circleSize,
                height: circleSize,
                child: AnimatedBuilder(
                  animation: _progressAnimation,
                  builder: (context, child) {
                    return CustomPaint(
                      painter: _CircularProgressPainter(
                        progress: targetProgress * _progressAnimation.value,
                        color: accentColor,
                        backgroundColor: accentColor.withOpacity(0.1),
                        strokeWidth: 6,
                      ),
                    );
                  },
                ),
              ),
              // Center content
              AnimatedBuilder(
                animation: _progressAnimation,
                builder: (context, child) {
                  return Opacity(
                    opacity: _progressAnimation.value,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          '$displayDays',
                          style: TextStyle(
                            fontSize: (circleSize * 0.25).clamp(28.0, 42.0),
                            fontWeight: FontWeight.w800,
                            color: accentColor,
                            height: 1.0,
                          ),
                        ),
                        SizedBox(height: 4.h),
                        Text(
                          centerLabel,
                          style: TextStyle(
                            fontSize: 10.sp,
                            fontWeight: FontWeight.w600,
                            color: accentColor.withOpacity(0.8),
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ],
          ),
        ),
        SizedBox(height: 16.h),

        // Next payment card
        Container(
          padding: EdgeInsets.all(16.w),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1A1F26) : Colors.white,
            borderRadius: BorderRadius.circular(16.r),
            boxShadow: [
              BoxShadow(
                color: (isDark ? Colors.black : Colors.grey).withOpacity(0.1),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                padding: EdgeInsets.all(10.w),
                decoration: BoxDecoration(
                  color: accentColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12.r),
                ),
                child: Icon(
                  Icons.calendar_today_rounded,
                  color: accentColor,
                  size: 20.sp,
                ),
              ),
              SizedBox(width: 12.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Дараагийн төлөлт',
                      style: TextStyle(
                        fontSize: 10.sp,
                        color: context.textSecondaryColor,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    SizedBox(height: 4.h),
                    Text(
                      nextUnitDateText,
                      style: TextStyle(
                        fontSize: 13.sp,
                        color: accentColor,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
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
    final isDark = context.isDarkMode;

    return Scaffold(
      key: _scaffoldKey,
      drawer: const SideMenu(),
      appBar: AppBar(
        backgroundColor: AppColors.getDeepGreen(isDark),
        toolbarHeight: 60.h,
        leading: IconButton(
          icon: Icon(Icons.menu, color: Colors.white, size: 22.sp),
          onPressed: () => _scaffoldKey.currentState?.openDrawer(),
        ),
        title: GestureDetector(
          onTap: _showTotalBalanceModal,
          child: Container(
            padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 8.h),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.15),
              borderRadius: BorderRadius.circular(12.r),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.account_balance_wallet_rounded,
                  color: Colors.white,
                  size: 18.sp,
                ),
                SizedBox(width: 8.w),
                Flexible(
                  child: Text(
                    '${_formatNumberWithComma(totalNiitTulbur)}₮',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 12.sp,
                      fontWeight: FontWeight.w600,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
        ),
        centerTitle: true,
        elevation: 0,
        actions: [
          Stack(
            clipBehavior: Clip.none,
            alignment: Alignment.center,
            children: [
              IconButton(
                icon: Icon(
                  Icons.notifications_outlined,
                  color: Colors.white,
                  size: 24,
                ),
                onPressed: () {
                  context
                      .push('/medegdel-list')
                      .then((_) => _loadNotificationCount());
                },
              ),
              if (_unreadNotificationCount > 0)
                Positioned(
                  right: 2,
                  top: 4,
                  child: Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: _unreadNotificationCount > 9 ? 5.w : 4.w,
                      vertical: 2.h,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.red,
                      borderRadius: BorderRadius.circular(12.r),
                      border: Border.all(color: Colors.white, width: 1.5),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.red.withOpacity(0.5),
                          blurRadius: 4,
                          spreadRadius: 0,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    constraints: BoxConstraints(
                      minWidth: 18.w,
                      minHeight: 18.h,
                    ),
                    child: Center(
                      child: Text(
                        _unreadNotificationCount > 99
                            ? '99+'
                            : '$_unreadNotificationCount',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 10.sp,
                          height: 1.0,
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
      body: Container(
        color: isDark ? const Color(0xFF0A0E14) : const Color(0xFFF5F7FA),
        child: SafeArea(
          child: RefreshIndicator(
            onRefresh: () async {
              await Future.wait([
                _loadBillers(),
                _loadBillingList(),
                _loadNotificationCount(),
                _loadAllBillingPayments(),
                _loadGereeData(),
                _loadNekhemjlekhCron(),
              ]);
            },
            color: AppColors.deepGreen,
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: EdgeInsets.symmetric(horizontal: 16.w),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(height: 16.h),

                  // Billing Connection Section - only show when NO e-bill is connected
                  if (_billingList.isEmpty &&
                      _userBillingData == null &&
                      !_isLoadingBillingList)
                    BillingConnectionSection(
                      isConnecting: _isConnectingBilling,
                      onConnect: _connectBillingByAddress,
                    ),

                  if (_billingList.isEmpty &&
                      _userBillingData == null &&
                      !_isLoadingBillingList)
                    SizedBox(height: 12.h),

                  // Billing List Section
                  BillingListSection(
                    key: _billingListSectionKey,
                    isLoading: _isLoadingBillingList,
                    billingList: _billingList,
                    userBillingData: _userBillingData,
                    onBillingTap: _showBillingDetailModal,
                    expandAddressAbbreviations: _expandAddressAbbreviations,
                    onDeleteTap: _deleteBilling,
                  ),

                  SizedBox(height: 16.h),

                  // Billers Grid
                  if (_isLoadingBillers)
                    SizedBox(
                      height: 200.h,
                      child: const Center(
                        child: CircularProgressIndicator(
                          color: AppColors.deepGreen,
                        ),
                      ),
                    )
                  else if (_billers.isEmpty)
                    SizedBox(
                      height: 200.h,
                      child: Center(
                        child: Text(
                          'Биллер олдсонгүй',
                          style: TextStyle(
                            color: context.textSecondaryColor,
                            fontSize: 16.sp,
                          ),
                        ),
                      ),
                    )
                  else
                    BillersGrid(
                      billers: _billers,
                      onDevelopmentTap: () => _showDevelopmentModal(context),
                      onBillerTap: () {
                        if (_billingList.isEmpty && _userBillingData == null) {
                          _billingListSectionKey.currentState
                              ?.showEmptyMessage();
                        }
                      },
                    ),

                  SizedBox(height: 20.h),

                  // Remaining Days Display
                  if (_gereeResponse != null &&
                      _gereeResponse!.jagsaalt.isNotEmpty)
                    _buildRemainingDaysWidget(_gereeResponse!.jagsaalt.first),

                  SizedBox(height: 24.h),
                ],
              ),
            ),
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
        iconColor: AppColors.deepGreenAccent,
        textColor: context.textPrimaryColor,
      );
      return;
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: BoxDecoration(
          color: context.backgroundColor,
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(16),
            topRight: Radius.circular(16),
          ),
          border: Border.all(color: context.borderColor),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header
            Container(
              padding: EdgeInsets.all(11.w),
              decoration: BoxDecoration(
                border: Border(bottom: BorderSide(color: context.borderColor)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Төлбөр төлөх',
                    style: TextStyle(
                      color: context.textPrimaryColor,
                      fontSize:
                          20.sp, // Increased from 11 for better readability
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  IconButton(
                    icon: Icon(
                      Icons.close,
                      color: context.textPrimaryColor,
                      size: 22.sp,
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
              padding: EdgeInsets.all(11.w),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Price information panel
                  Container(
                    padding: EdgeInsets.all(14.w),
                    decoration: BoxDecoration(
                      color: context.cardBackgroundColor,
                      borderRadius: BorderRadius.circular(12.w),
                      border: Border.all(color: context.borderColor),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Төлөх дүн',
                          style: context.secondaryDescriptionStyle(
                            color: context.textSecondaryColor,
                          ),
                        ),
                        Text(
                          '${_formatNumberWithComma(totalNiitTulbur)}₮',
                          style: context.secondaryDescriptionStyle(
                            fontWeight: FontWeight.bold,
                            color: context.textPrimaryColor,
                          ),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(
                    height: context.responsiveSpacing(
                      small: 11,
                      medium: 13,
                      large: 15,
                      tablet: 17,
                      veryNarrow: 8,
                    ),
                  ),
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
                        style: context.secondaryDescriptionStyle(
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

  Future<void> _showTotalBalanceModal() async {
    final baiguullagiinId = await StorageService.getBaiguullagiinId();
    final isWalletOnlyOrg = baiguullagiinId == '698e7fd3b6dd386b6c56a808';

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => TotalBalanceModal(
        formatNumberWithComma: _formatNumberWithComma,
        onPaymentTap: isWalletOnlyOrg
            ? () {}
            : () => context.push('/nekhemjlekh'),
      ),
    );
    
    if (mounted) {
      _loadAllBillingPayments();
    }
  }

  // _buildPaymentDetails and _buildDetailRow moved to TotalBalanceModal component

  void _showDevelopmentModal(BuildContext context) {
    // Do nothing - billers now navigate directly to detail page
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
    if (!mounted) return;

    // Show modal immediately - it will handle loading internally
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => BillingDetailModal(
        billing: billing,
        expandAddressAbbreviations: _expandAddressAbbreviations,
        formatNumberWithComma: _formatNumberWithComma,
      ),
    );
  }

  // All modal and helper methods moved to components
}
