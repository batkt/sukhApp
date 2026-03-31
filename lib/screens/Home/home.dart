import 'dart:async';
import 'package:sukh_app/main.dart' show navigatorKey;
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:sukh_app/constants/constants.dart';
import 'package:sukh_app/services/api_service.dart';
import 'package:sukh_app/services/storage_service.dart';
import 'package:sukh_app/services/socket_service.dart';
import 'package:sukh_app/services/session_service.dart';
import 'package:sukh_app/services/update_service.dart';
import 'package:sukh_app/widgets/selectable_logo_image.dart';
import 'package:sukh_app/widgets/shake_hint_modal.dart';
import 'package:sukh_app/utils/theme_extensions.dart';
import 'package:sukh_app/widgets/common/bg_painter.dart';
import 'package:sukh_app/widgets/glass_snackbar.dart';
import 'package:sukh_app/services/biometric_service.dart';
import 'package:sukh_app/components/Nekhemjlekh/nekhemjlekh_models.dart';
import 'package:sukh_app/utils/nekhemjlekh_merge_util.dart';
import 'package:sukh_app/models/medegdel_model.dart';
import 'package:sukh_app/models/geree_model.dart';
import 'package:sukh_app/screens/Home/billing_detail_page.dart';
import 'package:sukh_app/screens/Home/billing_list_page.dart';
import 'package:sukh_app/components/Home/billing_actions.dart';
import 'package:sukh_app/components/Home/billing_box.dart';
import 'package:sukh_app/components/Home/billers_section.dart';
import 'package:sukh_app/components/Home/home_header.dart';
import 'package:sukh_app/components/Menu/side_menu.dart';
import 'package:sukh_app/components/Home/blog_slider_section.dart';
import 'package:sukh_app/components/Home/billers_grid.dart';
import 'package:sukh_app/utils/format_util.dart';
import 'package:provider/provider.dart';
import 'package:sukh_app/services/theme_service.dart';
import 'package:sukh_app/utils/responsive_helper.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:sukh_app/widgets/app_logo.dart';

class AppBackground extends StatelessWidget {
  final Widget child;
  const AppBackground({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(child: child);
  }
}

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

    final backgroundPaint = Paint()
      ..color = backgroundColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    canvas.drawCircle(center, radius, backgroundPaint);

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
  double totalNiitAldangi = 0.0;
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
  bool _isRefreshing = false;

  // User billing data from profile
  Map<String, dynamic>? _userBillingData;
  bool _isInitialBillingLoaded = false;

  // GlobalKey to access BillingListSection state
  // No longer needed since billing list is on its own page
  // final GlobalKey<BillingListSectionState> _billingListSectionKey = ...

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
    _loadNotificationCount();
    _setupSocketListener();
    _loadGereeData();
    _loadNekhemjlekhCron();
    _refreshBillingInfo(); // Consolidated refresh  
    _checkRecentWalletPayments();

    // Periodic balance refresh (every 30s) - background refresh doesn't need to be too frequent
    _balanceRefreshTimer = Timer.periodic(const Duration(seconds: 30), (_) {
      if (mounted) _refreshBillingInfo(forceRefresh: false);
    });

    // Trigger animation after a short delay to ensure data is loaded
    Future.delayed(const Duration(milliseconds: 300), () {
      if (mounted && _gereeResponse != null) {
        _progressAnimationController.forward();
      }
    });
  }

  DateTime? _lastBalanceRefresh;

  void _setupSocketListener() async {
    if (_notificationCallback != null)
      return; // Already registered (single callback)

    // Ensure socket is connected if we are already logged in
    if (!SocketService.instance.isConnected) {
      await SocketService.instance.connect();
    }

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
        final type = (notification['type'] ?? notification['turul'])?.toString().toLowerCase() ?? '';
        final isInvoiceOrAvlaga =
            (type == 'billing_update') ||
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
    // Refresh balance when dependencies change (e.g. returning from address selection)
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final now = DateTime.now();
      // Added an initial loaded guard so that didChangeDependencies doesn't
      // instantly double-fetch the API on hot-restart initialization.
      if (_isInitialBillingLoaded &&
          (_lastBalanceRefresh == null ||
              now.difference(_lastBalanceRefresh!).inSeconds >= 15)) {
        _lastBalanceRefresh = now;
        _refreshBillingInfo(forceRefresh: false);
      }
    });
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    if (state == AppLifecycleState.resumed && mounted) {
      // Clear profile cache so web-side updates are picked up immediately
      ApiService.clearProfileCache();

      // Immediate refresh when app resumes
      _immediateRefresh();

      // Reset timer to more frequent updates
      _balanceRefreshTimer?.cancel();
      _balanceRefreshTimer = Timer.periodic(const Duration(seconds: 30), (_) {
        if (mounted) {
          _refreshBillingInfo(forceRefresh: false);
        }
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
    _refreshBillingInfo();
  }

  double _parseNum(dynamic val) {
    if (val == null) return 0.0;
    if (val is num) return val.toDouble();
    if (val is String) return double.tryParse(val) ?? 0.0;
    return 0.0;
  }


  Future<void> _loadAllBillingPayments() async {
    await _refreshBillingInfo();
  }

  Future<void> _refreshBillingInfo({bool forceRefresh = false}) async {
    if (!mounted || _isRefreshing) return;
    _isRefreshing = true;

    // Only show full loading state on the very first load
    if (!_isInitialBillingLoaded && _billingList.isEmpty) {
      if (mounted) setState(() => _isLoadingBillingList = true);
    }

    try {
      final currentBaiguullagiinId = await StorageService.getBaiguullagiinId();
      final currentBarilgiinId = await StorageService.getBarilgiinId();
      final isWalletOnlyOrg = currentBaiguullagiinId == '698e7fd3b6dd386b6c56a808';

      double total = 0.0;
      double totalAldangi = 0.0;
      double ownOrgTotal = 0.0;
      double ownOrgAldangi = 0.0;

      List<Map<String, dynamic>> finalBillingList = [];

      // 1. Load Local Residency Contracts (OWN_ORG)
      if (!isWalletOnlyOrg) {
        try {
          final userId = await StorageService.getUserId();
          if (userId != null) {
            final gereeResponse = await ApiService.fetchGeree(userId);
            if (gereeResponse['jagsaalt'] != null && gereeResponse['jagsaalt'] is List) {
              final contracts = gereeResponse['jagsaalt'] as List;
              
              // Parallel fetch to ensure accuracy for each contract
              final processedResults = await Future.wait(contracts.map((c) async {
                final contract = c is Map<String, dynamic> ? c : Map<String, dynamic>.from(c as Map);
                final dugaar = contract['gereeniiDugaar']?.toString();
                
                double invoiceSum = 0.0;
                double aldangiSum = 0.0;
                bool foundInvoices = false;

                if (dugaar != null) {
                  try {
                    final res = await ApiService.fetchNekhemjlekhiinTuukh(
                      gereeniiDugaar: dugaar,
                      khuudasniiDugaar: 1,
                      khuudasniiKhemjee: 200,
                    );
                    if (res['jagsaalt'] != null && res['jagsaalt'] is List) {
                      final items = res['jagsaalt'] as List;
                      for (var item in items) {
                        if (item['tuluv'] != 'Төлсөн') {
                          // IMPORTANT: Prioritize niitTulbur over uldegdel to avoid the polluted 887k global total.
                          double amt = _parseNum(item['niitTulbur'] ?? item['uldegdel'] ?? item['niitTulburOriginal']);
                          double ald = _parseNum(item['aldangi'] ?? 0);
                          invoiceSum += amt;
                          aldangiSum += ald;
                          foundInvoices = true;
                        }
                      }
                    }
                  } catch (e) {
                    print('❌ [ERROR] Accuracy check failed for $dugaar: $e');
                  }
                }

                // Final fallback only if no invoices were found or processed
                if (!foundInvoices) {
                  invoiceSum = _parseNum(contract['uldegdel'] ?? contract['globalUldegdel'] ?? contract['balance']);
                  aldangiSum = _parseNum(contract['aldangi'] ?? 0);
                }

                return {
                  'contract': contract,
                  'total': invoiceSum,
                  'aldangi': aldangiSum,
                };
              }));

              for (var result in processedResults) {
                final contract = result['contract'] as Map<String, dynamic>;
                final uld = result['total'] as double;
                final ald = result['aldangi'] as double;

                ownOrgTotal += uld;
                ownOrgAldangi += ald;

                finalBillingList.add({
                  'billingId': contract['gereeniiDugaar']?.toString(),
                  'billingName': contract['bairNer']?.toString() ?? 'Орон сууцны төлбөр',
                  'customerName': contract['ovogNer']?.toString() ?? '',
                  'bairniiNer': contract['bairNer']?.toString() ?? '',
                  'tootNum': contract['toot']?.toString() ?? '',
                  'perItemTotal': uld,
                  'perItemAldangi': ald,
                  'isLocalData': false,
                  'source': 'OWN_ORG',
                  'gereeniiDugaar': contract['gereeniiDugaar']?.toString(),
                  'gereeniiId': contract['_id']?.toString(),
                  'baiguullagiinId': contract['baiguullagiinId']?.toString() ?? currentBaiguullagiinId,
                  'barilgiinId': contract['barilgiinId']?.toString() ?? currentBarilgiinId,
                });
              }
            }
          }
        } catch (e) {
          print('❌ [ERROR] Failed to fetch OWN_ORG data: $e');
        }
      }

      total = ownOrgTotal;
      totalAldangi = ownOrgAldangi;

      // 2. Fetch data from Wallet API
      final rawBillingList = await ApiService.getWalletBillingList(forceRefresh: forceRefresh);
      
      // Fetch details for each wallet billing concurrently
      final walletFutures = rawBillingList.map((billing) async {
        Map<String, dynamic> updatedBilling = Map<String, dynamic>.from(billing);
        final billingId = billing['billingId']?.toString();
        double billingTotal = 0.0;
        double billingAldangi = 0.0;

        if (billingId != null && billingId.isNotEmpty) {
          try {
            final billingData = await ApiService.getWalletBillingBills(
              billingId: billingId,
              forceRefresh: forceRefresh,
            );
            
            if (billingData.isNotEmpty && billingData['billingId'] != null) {
              final newBills = billingData['newBills'] as List? ?? [];
              for (var bill in newBills) {
                billingTotal += _parseNum(bill['billTotalAmount']);
                billingAldangi += _parseNum(bill['billLateFee'] ?? bill['billLateFeeAmount']);
              }
              updatedBilling['billingDetails'] = billingData;
            }
          } catch (_) {}
        }

        updatedBilling['perItemTotal'] = billingTotal;
        updatedBilling['perItemAldangi'] = billingAldangi;
        updatedBilling['source'] = 'WALLET_API';
        
        return updatedBilling;
      });

      final updatedWalletBillings = await Future.wait(walletFutures);

      // 3. Merge and deduplicate if necessary, apply totals
      for (var billing in updatedWalletBillings) {
        final billingName = billing['billingName']?.toString() ?? '';
        final billingTotal = _parseNum(billing['perItemTotal']);
        final billingAldangi = _parseNum(billing['perItemAldangi']);

        if (ownOrgTotal > 0 && (billingName.contains('Орон сууцны') || billingName.contains('Property'))) {
          // If we already have OWN_ORG for residential, skip adding wallet entry as total already includes it
          // Or we can add it but skip from sums. Here we just add to list for UI visibility.
        } else {
          total += billingTotal;
          totalAldangi += billingAldangi;
        }
        finalBillingList.add(billing);
      }

      if (mounted) {
        setState(() {
          _billingList = finalBillingList;
          totalNiitTulbur = total;
          totalNiitAldangi = totalAldangi;
          _isInitialBillingLoaded = true;
        });
      }
    } catch (e) {
      print('❌ [ERROR] _refreshBillingInfo: $e');
    } finally {
      if (mounted) {
        setState(() {
          _isLoadingBillingList = false;
          _isRefreshing = false;
        });
      }
    }
  }

  // Immediate refresh method for critical operations
  Future<void> _immediateRefresh() async {
    if (!mounted) return;

    try {
      // Force refresh all billing-related data immediately
      await Future.wait([
        _refreshBillingInfo(forceRefresh: true),
        _loadAllBillingPayments(),
        _loadNotificationCount(), // Also refresh notifications
      ]);

      // Force UI update
      if (mounted) {
        setState(() {});
      }
    } catch (e) {
      print('❌ [ERROR] Immediate refresh failed: $e');
    }
  }

  Future<void> _deleteBilling(Map<String, dynamic> billing,
      {BuildContext? ctx}) async {
    final activeContext = ctx ??
        (mounted
            ? context
            : (navigatorKey.currentState?.overlay?.context ??
                navigatorKey.currentContext));
    if (activeContext == null) return;

    final billingId =
        billing['billingId']?.toString() ??
        billing['walletBillingId']?.toString();

    if (billingId == null) {
      if (billing['isLocalData'] == true) {
        showGlassSnackBar(
          activeContext,
          message: 'Энэ биллинг API-тай холбогдоогүй байна.',
          icon: Icons.info_outline,
          iconColor: Colors.orange,
        );
      }
      return;
    }

    final bool? confirm = await showDialog<bool>(
      context: activeContext,
      useRootNavigator: true,
      builder: (ctx) => AlertDialog(
        title: Text(
          'Биллинг устгах',
          style: TextStyle(color: ctx.textPrimaryColor),
        ),
        content: Text(
          'Та энэ биллингийг устгахдаа итгэлтэй байна уу?',
          style: TextStyle(color: ctx.textSecondaryColor),
        ),
        backgroundColor: ctx.backgroundColor,
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text('Үгүй', style: TextStyle(color: AppColors.deepGreen)),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text(
              'Тийм',
              style: TextStyle(color: Colors.redAccent),
            ),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    try {
      await ApiService.removeWalletBilling(billingId: billingId);

      // Immediate refresh after successful deletion
      await _immediateRefresh();

      final finalContext = ctx ??
          (mounted
              ? context
              : (navigatorKey.currentState?.overlay?.context ??
                  navigatorKey.currentContext));
      if (finalContext != null) {
        showGlassSnackBar(
          finalContext,
          message: 'Биллинг амжилттай устгагдлаа',
          icon: Icons.check_circle,
          iconColor: Colors.green,
        );
      }
    } catch (e) {
      final finalContext = ctx ??
          (mounted
              ? context
              : (navigatorKey.currentState?.overlay?.context ??
                  navigatorKey.currentContext));
      if (finalContext != null) {
        showGlassSnackBar(
          finalContext,
          message: e.toString().replaceAll("Exception: ", ""),
          icon: Icons.error,
          iconColor: Colors.red,
        );
      }
    }
  }

  Future<void> _editBilling(Map<String, dynamic> billing,
      {BuildContext? ctx, VoidCallback? onUpdated}) async {
    final activeContext = ctx ??
        (mounted
            ? context
            : (navigatorKey.currentState?.overlay?.context ??
                navigatorKey.currentContext));
    if (activeContext == null) return;

    await HomeBillingManager.editBilling(
      context: activeContext,
      billing: billing,
      expandAddressAbbreviations: _expandAddressAbbreviations,
      billingList: _billingList,
      onUpdated: () {
        if (mounted) setState(() {});
        onUpdated?.call();
      },
    );
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

      // Filter out "Төрийн банк" and "Онлайн биллер"
      final filteredBillers = billers.where((biller) {
        final name = (biller['name'] ?? '').toString().toLowerCase();
        return !name.contains('төрийн банк') && !name.contains('онлайн биллер');
      }).toList();

      if (mounted) {
        setState(() {
          _billers = filteredBillers;
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
          print(
            '🔎 [HOME] Checking latest pending wallet payment: $walletPaymentId',
          );
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
      final nekhemjlekhUusgekhOgnooValue =
          _nekhemjlekhCronData!['nekhemjlekhUusgekhOgnoo'];
      final nekhemjlekhUusgekhOgnoo = nekhemjlekhUusgekhOgnooValue is int
          ? nekhemjlekhUusgekhOgnooValue
          : (nekhemjlekhUusgekhOgnooValue is num
                ? nekhemjlekhUusgekhOgnooValue.toInt()
                : int.tryParse(nekhemjlekhUusgekhOgnooValue.toString()) ?? 0);
      final today = DateTime.now();

      if (nekhemjlekhUusgekhOgnoo != 0 &&
          nekhemjlekhUusgekhOgnoo >= 1 &&
          nekhemjlekhUusgekhOgnoo <= 31) {
        if (today.day >= nekhemjlekhUusgekhOgnoo) {
          final nextMonth = today.month == 12 ? 1 : today.month + 1;
          final nextYear = today.month == 12 ? today.year + 1 : today.year;
          nextInvoiceDate = DateTime(
            nextYear,
            nextMonth,
            nekhemjlekhUusgekhOgnoo,
          );
        } else {
          nextInvoiceDate = DateTime(
            today.year,
            today.month,
            nekhemjlekhUusgekhOgnoo,
          );
        }
      }
    }

    final today = DateTime.now();
    final todayDateOnly = DateTime(today.year, today.month, today.day);

    int displayDays;
    String rightLabel;
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

      if (nextInvoiceDateOnly.isAfter(todayDateOnly) ||
          nextInvoiceDateOnly.isAtSameMomentAs(todayDateOnly)) {
        final remainingDays = nextInvoiceDateOnly
            .difference(todayDateOnly)
            .inDays;
        displayDays = remainingDays;
        rightLabel = 'Өдөр';
        centerLabel = 'Төлөлт хийхэд';
        accentColor = AppColors.deepGreen;
        nextUnitDateText =
            '${nextInvoiceDate.year}-${nextInvoiceDate.month.toString().padLeft(2, '0')}-${nextInvoiceDate.day.toString().padLeft(2, '0')}';
        final clampedRemaining = remainingDays > 30 ? 30 : remainingDays;
        targetProgress = 1.0 - (clampedRemaining / 30.0);
      } else {
        final daysOverdue = todayDateOnly
            .difference(nextInvoiceDateOnly)
            .inDays;
        displayDays = daysOverdue;
        rightLabel = 'Өдөр';
        centerLabel = 'өдөр хэтэрсэн';
        accentColor = const Color(0xFFFF6B6B);
        nextUnitDateText =
            '${nextInvoiceDate.year}-${nextInvoiceDate.month.toString().padLeft(2, '0')}-${nextInvoiceDate.day.toString().padLeft(2, '0')}';
        targetProgress = 1.0;
      }
    } else {
      final daysPassed = _calculateDaysPassed(geree.gereeniiOgnoo);
      displayDays = daysPassed;
      rightLabel = 'Өдөр';
      centerLabel = 'өдөр өнгөрсөн';
      accentColor = const Color(0xFFFF6B6B);
      targetProgress = (daysPassed % 30) / 30.0;
      nextUnitDateText = _getNextUnitDate(geree.gereeniiOgnoo);
    }

    final isDark = context.isDarkMode;

    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(24.w),
      decoration: BoxDecoration(
        color: accentColor,
        borderRadius: BorderRadius.circular(32.r),
        boxShadow: [
          BoxShadow(
            color: accentColor.withOpacity(0.3),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        children: [
          IntrinsicHeight(
            child: Row(
              children: [
                // Left Side: Jumbo Stats
                Expanded(
                  flex: 5,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.baseline,
                        textBaseline: TextBaseline.alphabetic,
                        children: [
                          Text(
                            '$displayDays',
                            style: TextStyle(
                              fontSize: 42.sp,
                              fontWeight: FontWeight.w900,
                              color: Colors.white,
                              height: 1.0,
                              letterSpacing: -1,
                            ),
                          ),
                          SizedBox(width: 8.w),
                          Text(
                            rightLabel,
                            style: TextStyle(
                              fontSize: 12.sp,
                              fontWeight: FontWeight.w800,
                              color: Colors.white.withOpacity(0.8),
                              letterSpacing: 0.5,
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 6.h),
                      Text(
                        centerLabel,
                        style: TextStyle(
                          fontSize: 12.sp,
                          fontWeight: FontWeight.w800,
                          color: Colors.white.withOpacity(0.8),
                          letterSpacing: 0.5,
                        ),
                      ),
                    ],
                  ),
                ),

                // Vertical Divider
                Container(
                  width: 1.5,
                  margin: EdgeInsets.symmetric(horizontal: 16.w, vertical: 4.h),
                  color: Colors.white.withOpacity(0.2),
                ),

                // Right Side: Detailed info
                Expanded(
                  flex: 7,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.calendar_today_rounded,
                            color: Colors.white.withOpacity(0.6),
                            size: 14.sp,
                          ),
                          SizedBox(width: 8.w),
                          Text(
                            'Дараагийн төлөлт',
                            style: TextStyle(
                              fontSize: 11.sp,
                              fontWeight: FontWeight.w600,
                              color: Colors.white.withOpacity(0.7),
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 8.h),
                      Text(
                        nextUnitDateText,
                        style: TextStyle(
                          fontSize: 19.sp,
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                          letterSpacing: -0.5,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          SizedBox(height: 24.h),
          // Thicker, modern progress indicator
          Stack(
            children: [
              Container(
                height: 10.h,
                width: double.infinity,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(20),
                ),
              ),
              AnimatedBuilder(
                animation: _progressAnimation,
                builder: (context, child) {
                  return FractionallySizedBox(
                    widthFactor: targetProgress * _progressAnimation.value,
                    child: Container(
                      height: 10.h,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.1),
                            blurRadius: 4,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ],
          ),
          SizedBox(height: 10.h),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Мөчлөгийн явц',
                style: TextStyle(
                  fontSize: 10.sp,
                  fontWeight: FontWeight.w600,
                  color: Colors.white.withOpacity(0.5),
                ),
              ),
              Text(
                '${(targetProgress * 100).toInt()}%',
                style: TextStyle(
                  fontSize: 12.sp,
                  fontWeight: FontWeight.w800,
                  color: Colors.white,
                ),
              ),
            ],
          ),
        ],
      ),
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
      body: Container(
        color: isDark ? const Color(0xFF0A0E14) : const Color(0xFFF5F7FA),
        child: Column(
          children: [
            HomeHeader(
              unreadNotificationCount: _unreadNotificationCount,
              onMenuTap: () => _scaffoldKey.currentState?.openDrawer(),
              onThemeToggle: () {
                final themeService = Provider.of<ThemeService>(
                  context,
                  listen: false,
                );
                themeService.toggleTheme();
              },
              onNotificationTap: () {
                context
                    .push('/medegdel-list')
                    .then((_) => _loadNotificationCount());
              },
            ),

            Expanded(
              child: RefreshIndicator(
                onRefresh: () async {
                  await Future.wait([
                    _loadBillers(),
                    _refreshBillingInfo(forceRefresh: true),
                    _loadNotificationCount(),
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
                      SizedBox(height: 4.h),

                      // 1. Remaining Days & Next Payment (Moved to Top)
                      if (_gereeResponse != null &&
                          _gereeResponse!.jagsaalt.isNotEmpty)
                        _buildRemainingDaysWidget(
                          _gereeResponse!.jagsaalt.first,
                        ),

                      SizedBox(height: 12.h),

                      // 2. "Төлбөр" Box
                      BillingBox(
                        onTap: _navigateToBillingList,
                        totalBalance: _formatNumberWithComma(totalNiitTulbur),
                        totalAldangi: _formatNumberWithComma(totalNiitAldangi),
                      ),

                      SizedBox(height: 16.h),

                      // 3. Нэмэлт боломж Section
                      _buildAdditionalServicesSection(),

                      SizedBox(height: 16.h),

                      // 4. Billers Grid
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
                          onDevelopmentTap: () =>
                              _showDevelopmentModal(context),
                          onBillerTap: () {
                            if (_billingList.isEmpty &&
                                _userBillingData == null) {
                              _navigateToBillingList();
                            }
                          },
                        ),

                      SizedBox(height: 12.h),

                      // 5. Blog Slider Section
                      const BlogSliderSection(),

                      SizedBox(height: 24.h), // More bottom spacing
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
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
        }
        if (mounted) {
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
      await _refreshBillingInfo(forceRefresh: true);

      if (mounted) {
        setState(() {
          _isConnectingBilling = false;
        });
      }
      if (mounted) {
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
      }
      if (mounted) {
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

  String _expandAddressAbbreviations(String address) {
    if (address.isEmpty) return address;

    String expanded = address;

    expanded = expanded.replaceAll(RegExp(r'\bБГД\b'), 'Баянгол дүүрэг');
    expanded = expanded.replaceAll(RegExp(r'\bБЗД\b'), 'Баянзүрх дүүрэг');
    expanded = expanded.replaceAll(RegExp(r'\bСБД\b'), 'Сүхбаатар дүүрэг');
    expanded = expanded.replaceAll(RegExp(r'\bХД\b'), 'Хан-Уул дүүрэг');
    expanded = expanded.replaceAll(RegExp(r'\bЧД\b'), 'Чингэлтэй дүүрэг');
    expanded = expanded.replaceAll(RegExp(r'\bСД\b'), 'Сонгинохайрхан дүүрэг');

    return expanded;
  }

  void _navigateToBillingList() {
    context.push(
      '/billing-list',
      extra: {
        'billingList': _billingList,
        'userBillingData': _userBillingData,
        'isLoading': _isLoadingBillingList,
        'totalBalance': totalNiitTulbur,
        'totalAldangi': totalNiitAldangi,
        'expandAddressAbbreviations': _expandAddressAbbreviations,
        'onDeleteTap': _deleteBilling,
        'onEditTap': _editBilling,
        'isConnecting': _isConnectingBilling,
        'onConnect': _connectBillingByAddress,
        'onRefresh': () async {
          await _refreshBillingInfo(forceRefresh: true);
        },
      },
    );
  }

  Widget _buildBillingBox() {
    final isDark = context.isDarkMode;

    return GestureDetector(
      onTap: _navigateToBillingList,
      child: Container(
        width: double.infinity,
        padding: EdgeInsets.all(16.w),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1A1F26) : Colors.white,
          borderRadius: BorderRadius.circular(24.r),
          boxShadow: [
            BoxShadow(
              color: (isDark ? Colors.black : AppColors.deepGreen).withOpacity(
                0.06,
              ),
              blurRadius: 20,
              offset: const Offset(0, 8),
            ),
          ],
          border: Border.all(
            color: isDark
                ? Colors.white.withOpacity(0.05)
                : AppColors.deepGreen.withOpacity(0.05),
            width: 1,
          ),
        ),
        child: Row(
          children: [
            // Logo Container with subtle glass effect or gradient
            Container(
              height: 56.h,
              width: 56.h,
              padding: EdgeInsets.all(10.w),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    AppColors.deepGreen.withOpacity(isDark ? 0.2 : 0.08),
                    AppColors.deepGreen.withOpacity(isDark ? 0.1 : 0.03),
                  ],
                ),
                borderRadius: BorderRadius.circular(16.r),
              ),
              child: ValueListenableBuilder<String>(
                valueListenable: AppLogoNotifier.currentIcon,
                builder: (context, iconName, _) {
                  return Image.asset(
                    AppLogoAssets.getAssetPath(iconName),
                    fit: BoxFit.contain,
                  );
                },
              ),
            ),
            SizedBox(width: 16.w),
            // Text Content
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Хэрэглээний төлбөр',
                    style: TextStyle(
                      fontSize: 15.sp,
                      color: context.textPrimaryColor,
                      letterSpacing: -0.2,
                    ),
                  ),
                  SizedBox(height: 2.h),
                  Text(
                    'Төлбөрийн дэлгэрэнгүй харах',
                    style: TextStyle(
                      fontSize: 11.sp,
                      color: context.textSecondaryColor.withOpacity(0.6),
                    ),
                  ),
                ],
              ),
            ),
            // Action Icon
            Container(
              padding: EdgeInsets.all(8.w),
              decoration: BoxDecoration(
                color: isDark
                    ? Colors.white.withOpacity(0.05)
                    : const Color(0xFFF5F7FA),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.arrow_forward_ios_rounded,
                color: isDark
                    ? Colors.white70
                    : AppColors.deepGreen.withOpacity(0.6),
                size: 12.sp,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAdditionalServicesSection() {
    final isDark = context.isDarkMode;

    final services = [
      {
        'name': 'parkease',
        'label': 'ParkEase',
        'imageAsset': 'lib/assets/img/parkease_logo.png',
        'color': const Color(0xFF3B82F6),
      }, // Bright Blue
      {
        'name': 'камер',
        'label': 'Камер',
        'icon': Icons.videocam_rounded,
        'color': const Color(0xFF8B5CF6),
      }, // Bright Purple
      {
        'name': 'лифт',
        'label': 'Лифт',
        'icon': Icons.elevator_rounded,
        'color': const Color(0xFFF97316),
      }, // Bright Orange
      {
        'name': 'дуудлага',
        'label': 'Дуудлага',
        'icon': Icons.build_circle_rounded,
        'color': const Color(0xFFEF4444),
      }, // Bright Red
      {
        'name': 'цэвэрлэгээ',
        'label': 'Цэвэрлэгээ',
        'icon': Icons.cleaning_services_rounded,
        'color': const Color(0xFF10B981),
      }, // Bright Emerald
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Section Header
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 4.h),
          child: Row(
            children: [
              Container(
                width: 4.w,
                height: 16.h,
                decoration: BoxDecoration(
                  color: AppColors.deepGreen,
                  borderRadius: BorderRadius.circular(2.r),
                ),
              ),
              SizedBox(width: 10.w),
              Text(
                'Нэмэлт боломж',
                style: TextStyle(
                  fontSize: 16.sp,
                  color: context.textPrimaryColor,
                  fontWeight: FontWeight.w500,
                  letterSpacing: -0.5,
                ),
              ),
            ],
          ),
        ),

        SizedBox(height: 12.h),

        // Services Grid
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          padding: EdgeInsets.symmetric(vertical: 4.h),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 4,
            crossAxisSpacing: 12.w,
            mainAxisSpacing: 12.h,
            childAspectRatio: 0.8,
          ),
          itemCount: services.length,
          itemBuilder: (context, index) {
            final service = services[index];
            return _buildServiceCard(service, isDark);
          },
        ),
      ],
    );
  }

  Widget _buildServiceCard(Map<String, dynamic> service, bool isDark) {
    final serviceColor = service['color'] as Color? ?? AppColors.deepGreen;

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () {
        // Disabled for now - show "Тун удахгүй" message
        showGlassSnackBar(
          context,
          message: 'Тун удахгүй',
          icon: Icons.info_outline,
          iconColor: Colors.orange,
        );
      },
      child: Container(
        decoration: BoxDecoration(
          color: isDark
              ? Colors.white.withOpacity(0.05)
              : const Color(0xFFF5F7FA),
          borderRadius: BorderRadius.circular(12.r),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Logo/Icon
            Container(
              width: 50.w,
              height: 50.h,
              decoration: BoxDecoration(
                color: serviceColor.withOpacity(isDark ? 0.2 : 0.12),
                borderRadius: BorderRadius.circular(10.r),
              ),
              child: service['imageAsset'] != null
                  ? Padding(
                      padding: EdgeInsets.all(6.w),
                      child: Image.asset(
                        service['imageAsset'] as String,
                        fit: BoxFit.contain,
                      ),
                    )
                  : Icon(
                      service['icon'] as IconData?,
                      color: serviceColor,
                      size: 22.sp,
                    ),
            ),
            SizedBox(height: 8.h),
            Text(
              service['label'] ?? '',
              style: TextStyle(
                fontSize: 11.sp,
                color: isDark ? Colors.white70 : Colors.black87,
                fontWeight: FontWeight.w400,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
