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
  final PageController _billerPageController = PageController();
  final PageController _contractPageController = PageController();

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

  // Billing List
  List<Map<String, dynamic>> _billingList = [];
  bool _isLoadingBillingList = true;
  bool _isRefreshing = false;

  // User billing data from profile
  Map<String, dynamic>? _userBillingData;
  Map<String, dynamic>? _userProfile;
  bool _isInitialBillingLoaded = false;
  bool _isNonOrgUser = false;

  bool get hasAnyAddress => _billingList.isNotEmpty || 
                         (_userProfile != null && _userProfile!['toots'] != null && (_userProfile!['toots'] as List).isNotEmpty);

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
    _contractPageController.dispose();
    _progressAnimationController.dispose();
    if (_notificationCallback != null) {
      SocketService.instance.removeNotificationCallback(_notificationCallback);
      _notificationCallback = null;
    }
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
        // Use API count directly to avoid double counting
        setState(() {
          _unreadNotificationCount = unreadCount;
        });

      } else {

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
    // Avoid duplicate heavy billing refreshes on widget updates.
    // Billing data already refreshes via initState, lifecycle, pull-to-refresh, and socket events.
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

      // 1. Parallel Initial Fetch for core data
      final userId = await StorageService.getUserId();
      final initialData = await Future.wait([
        ApiService.getUserProfile(forceRefresh: forceRefresh),
        ApiService.getWalletBillingList(forceRefresh: forceRefresh),
        ApiService.fetchWalletQpayList(),
        if (userId != null && !isWalletOnlyOrg) ApiService.fetchGeree(userId) else Future.value({'jagsaalt': []}),
      ]);

      final userProfile = initialData[0] as Map<String, dynamic>;
      final rawBillingList = initialData[1] as List<Map<String, dynamic>>;
      final walletHistory = initialData[2] as List<Map<String, dynamic>>;
      final gereeResponse = initialData[3] as Map<String, dynamic>;

      final user = userProfile['result'];

      if (mounted) {
        setState(() {
          _userProfile = user;
          _gereeResponse = GereeResponse.fromJson(gereeResponse);
          // Identify non-organization users (Bpay signups or users with no linked org)
          final String? baigIdValue = user?['baiguullagiinId']?.toString();
          _isNonOrgUser = baigIdValue == null ||
              baigIdValue == "null" ||
              baigIdValue.isEmpty ||
              baigIdValue == '698e7fd3b6dd386b6c56a808';
        });
      }

      // Load Local Residency Contracts (OWN_ORG)
      if (!isWalletOnlyOrg && gereeResponse['jagsaalt'] != null && gereeResponse['jagsaalt'] is List) {
        try {
          final contracts = gereeResponse['jagsaalt'] as List;


              // Parallel fetch to ensure accuracy for each contract
              final processedResults = await Future.wait(contracts.map((c) async {
                final contract = c is Map<String, dynamic> ? c : Map<String, dynamic>.from(c as Map);
                final dugaar = contract['gereeniiDugaar']?.toString();
                final gereeniiId = contract['_id']?.toString();
                final baiguullagiinId = contract['baiguullagiinId']?.toString();
                
                double invoiceSum = 0.0;
                double aldangiSum = 0.0;
                bool hasData = false;

                if (dugaar != null) {
                  try {
                    // Fetch unified invoices with their ledger items (Ledger-First architecture)
                    final unifiedResponse = await ApiService.fetchInvoicesWithItems(
                      baiguullagiinId: contract['baiguullagiinId']?.toString() ?? '',
                      gereeniiDugaar: contract['gereeniiDugaar']?.toString() ?? '',
                      gereeniiId: contract['_id']?.toString() ?? '',
                    );

                    invoiceSum = (unifiedResponse['totalUldegdel'] ?? 0.0).toDouble();
                    aldangiSum = (unifiedResponse['totalAldangi'] ?? 0.0).toDouble();
                    final mergedInvoices = List<Map<String, dynamic>>.from(unifiedResponse['jagsaalt'] ?? []);
                    hasData = true;

                    // Apply reactive filtering for recently paid bills from the wallet
                    // This uses the walletHistory we fetched ONCE outside the loop
                    final Set<String> recentlyPaidBillIds = {};
                    for (var h in walletHistory.take(15)) {
                      final billIds = h['billIds'] as List?;
                      if (billIds != null) {
                        for(var bid in billIds) recentlyPaidBillIds.add(bid.toString());
                      }
                    }

                    // If any of the invoices were just paid, subtract them from the summary balance
                    // This provides instant feedback before the authoritative ledger updates.
                    for (var inv in mergedInvoices) {
                      final invId = inv['_id']?.toString() ?? inv['id']?.toString();
                      if (invId != null && recentlyPaidBillIds.contains(invId)) {
                        final item = NekhemjlekhItem.fromJson(inv);
                        invoiceSum -= item.effectiveNiitTulbur;

                      }
                    }

                  } catch (e) {

                  }
                }

                // Final fallback if NO invoices/avlagas/ledger were found
                if (!hasData || (!invoiceSum.isFinite && invoiceSum == 0)) {
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
                  'uldegdel': uld, // Authoritative balance from ledger
                  'uldegdelAldangi': ald,
                  'perItemAldangi': ald,
                  'isLocalData': false,
                  'source': 'OWN_ORG',
                  'gereeniiDugaar': contract['gereeniiDugaar']?.toString(),
                  'gereeniiId': contract['_id']?.toString(),
                  'baiguullagiinId': contract['baiguullagiinId']?.toString() ?? currentBaiguullagiinId,
                  'barilgiinId': contract['barilgiinId']?.toString() ?? currentBarilgiinId,
                });
              }
            } catch (e) {
              // Silent fail for individual org fetch
            }
          }

            // Identify bill numbers that have recent successful or pending payments
      // PARALLEL STATUS CHECKS
      final Set<String> recentlyPaidBillNos = {};
      final List<Future<void>> statusChecks = walletHistory.take(5).map((h) async {
        final walletPaymentId = h['walletPaymentId']?.toString() ?? '';
        final zakhialgiinDugaar = h['zakhialgiinDugaar']?.toString() ?? '';
        final checkId = walletPaymentId.isNotEmpty ? walletPaymentId : zakhialgiinDugaar;

        if (checkId.isNotEmpty) {
          try {
            final st = await ApiService.walletQpayWalletCheck(walletPaymentId: checkId);
            if (st['success'] == true && st['data'] != null) {
              final walletData = st['data'];
              final state = walletData['paymentStatus']?.toString().toUpperCase() ?? '';
              
              final hasSuccessfulTrx = (walletData['paymentTransactions'] as List?)?.any((trx) => 
                (trx['trxStatus']?.toString().toUpperCase() == 'SUCCESS') || 
                (trx['trxStatusName']?.toString() == 'Амжилттай')
              ) ?? false;
              
              bool hasSuccessfulTrxInLines = false;
              final lines = walletData['lines'] as List?;
              if (lines != null) {
                for (var line in lines) {
                  final lineTrx = line['billTransactions'] as List?;
                  if (lineTrx != null && lineTrx.any((trx) => 
                    (trx['trxStatus']?.toString().toUpperCase() == 'SUCCESS') || 
                    (trx['trxStatusName']?.toString() == 'Амжилттай'))) {
                    hasSuccessfulTrxInLines = true;
                    break;
                  }
                }
              }

              if (state == 'PAID' || state == 'PENDING' || hasSuccessfulTrx || hasSuccessfulTrxInLines) {
                if (lines != null) {
                  for (var line in lines) {
                    final billNo = line['billNo']?.toString();
                    final billId = line['billId']?.toString();
                    if (billNo != null && billNo.isNotEmpty) recentlyPaidBillNos.add(billNo);
                    if (billId != null && billId.isNotEmpty) recentlyPaidBillNos.add(billId);
                  }
                }
                final topLevelBillNo = walletData['billNo']?.toString();
                final topLevelInvoiceNo = walletData['invoiceNo']?.toString();
                if (topLevelBillNo != null && topLevelBillNo.isNotEmpty) recentlyPaidBillNos.add(topLevelBillNo);
                if (topLevelInvoiceNo != null && topLevelInvoiceNo.isNotEmpty) recentlyPaidBillNos.add(topLevelInvoiceNo);
              }
            }
          } catch(_) {}
        }
      }).toList();

      await Future.wait(statusChecks);
      total = ownOrgTotal;
      totalAldangi = ownOrgAldangi;

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
              // PRIORITY 1: Trust the server's pre-computed amount.
              final serverAmount = billingData['payableBillAmount'] ?? billingData['newBillsAmount'];
              final serverAldangi = billingData['payableBillAldangi'] ?? billingData['newBillsAldangi'] ?? billingData['newBillsLateFee'];
              
              if (serverAmount != null && _parseNum(serverAmount) > 0) {
                billingTotal = _parseNum(serverAmount);
                billingAldangi = serverAldangi != null ? _parseNum(serverAldangi) : 0.0;
              } else {
                // FALLBACK: Manual sum — skip ONLY bills found in recent paid set
                final allBills = (billingData['newBills'] as List? ?? []) + (billingData['bills'] as List? ?? []);
                for (var bill in allBills) {
                  final billId = bill['billId']?.toString();
                  final billNo = bill['billNo']?.toString();
                  if ((billId != null && recentlyPaidBillNos.contains(billId)) ||
                      (billNo != null && recentlyPaidBillNos.contains(billNo))) {
                    continue;
                  }
                  billingTotal += _parseNum(bill['billTotalAmount']);
                  billingAldangi += _parseNum(bill['billLateFee'] ?? bill['billLateFeeAmount'] ?? 0);
                }
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

      // 4. Fallback: If no billings were found but user has 'toots' in profile, add them as placeholders
      if (user?['toots'] != null && user!['toots'] is List) {
        final profileToots = user['toots'] as List;
        for (var toot in profileToots) {
          final t = toot is Map<String, dynamic> ? toot : Map<String, dynamic>.from(toot as Map);
          final billingId = t['billingId']?.toString();
          
          // Check if this billing is already in the list
          bool alreadyExists = finalBillingList.any((b) => 
            b['billingId']?.toString() == billingId || 
            (b['gereeniiDugaar'] != null && b['gereeniiDugaar'] == t['walletCustomerCode'])
          );
          
          if (!alreadyExists) {
            finalBillingList.add({
              'billingId': billingId,
              'billingName': t['bairniiNer']?.toString() ?? 'Орон сууцны төлбөр',
              'customerName': '${t['ovog'] ?? ''} ${t['ner'] ?? ''}'.trim(),
              'bairniiNer': t['bairniiNer']?.toString() ?? '',
              'tootNum': t['toot']?.toString() ?? '',
              'perItemTotal': 0.0, // Will load detail on tap
              'uldegdel': 0.0,
              'perItemAldangi': 0.0,
              'source': t['source'] ?? 'WALLET_API',
              'isPlaceholder': true,
              'baiguullagiinId': t['baiguullagiinId']?.toString() ?? currentBaiguullagiinId,
              'barilgiinId': t['barilgiinId']?.toString() ?? currentBarilgiinId,
            });
          }
        }
      }

      // If total is 0, double-check by fetching bills directly to ensure consistency with detail page
      if (total == 0.0) {
        double recalculatedTotal = 0.0;
        double recalculatedAldangi = 0.0;
        
        await Future.wait(updatedWalletBillings.map((billing) async {
          final billingId = billing['billingId']?.toString();
          if (billingId != null) {
            try {
              final billsResponse = await ApiService.getWalletBillingBills(billingId: billingId);
              List<Map<String, dynamic>> bills = [];
              if (billsResponse['newBills'] is List) {
                bills = List<Map<String, dynamic>>.from(billsResponse['newBills']);
              } else if (billsResponse['bills'] is List) {
                bills = List<Map<String, dynamic>>.from(billsResponse['bills']);
              }
              
              for (var bill in bills) {
                if (bill['isNew'] != false) {
                  recalculatedTotal += _parseNum(bill['billTotalAmount']);
                  recalculatedAldangi += _parseNum(bill['billLateFee'] ?? bill['billLateFeeAmount']);
                }
              }
            } catch (_) {}
          }
        }));

        if (recalculatedTotal > 0.0) {
          total = recalculatedTotal;
          totalAldangi = recalculatedAldangi;
        }
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
        _loadNotificationCount(), // Also refresh notifications
        ApiService.getUserProfile(forceRefresh: true), // Sync user profile from web changes
      ]);

      // Force UI update
      if (mounted) {
        setState(() {});
      }
    } catch (e) {

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
        } else if (errorMessage.contains('500')) {
          ApiService.handleUnauthorized(null, false);
          return;
        } else if (errorMessage.contains('Таны хүчинтэй хугацаа дууссан')) {
          // Already handled and logged out by api_service.dart
          return;
        } else {
          displayMessage = errorMessage;
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
        final statusStr = latest['status']?.toString().toUpperCase();
        final walletPaymentId = latest['walletPaymentId']?.toString();

        if (walletPaymentId != null && statusStr == 'PENDING') {

          
          final statusRes = await ApiService.walletQpayWalletCheck(
            walletPaymentId: walletPaymentId,
          );
          
          bool isPaid = false;
          if (statusRes['success'] == true && statusRes['data'] != null) {
            final walletData = statusRes['data'];
            
            // 1. Check top-level payment status
            final state = walletData['paymentStatus']?.toString().toUpperCase();
            
            // 2. Check for success in top-level transactions list
            final transactions = walletData['paymentTransactions'] as List?;
            bool hasSuccessfulTrx = false;
            if (transactions != null) {
              hasSuccessfulTrx = transactions.any((trx) => 
                (trx['trxStatus']?.toString().toUpperCase() == 'SUCCESS') ||
                (trx['trxStatusName']?.toString() == 'Амжилттай')
              );
            }

            // 3. Deep Check: Search within individual lines for line-level transactions (e.g. Housing)
            if (!hasSuccessfulTrx) {
              final lines = walletData['lines'] as List?;
              if (lines != null) {
                for (var line in lines) {
                  final lineTrx = line['billTransactions'] as List?;
                  if (lineTrx != null && lineTrx.any((trx) => 
                    (trx['trxStatus']?.toString().toUpperCase() == 'SUCCESS') ||
                    (trx['trxStatusName']?.toString() == 'Амжилттай'))) {
                    hasSuccessfulTrx = true;
                    break;
                  }
                }
              }
            }

            if (state == 'PAID' || hasSuccessfulTrx) {
              isPaid = true;
            }
          }

          if (isPaid) {

            _loadAllBillingPayments();
          }
        }
      }
    } catch (e) {

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

  DateTime? _calculateNextInvoiceDateFromContract(String gereeniiOgnoo) {
    try {
      final contractDate = DateTime.parse(gereeniiOgnoo);
      final today = DateTime.now();
      final todayDateOnly = DateTime(today.year, today.month, today.day);
      final dayOfMonth = contractDate.day;

      DateTime nextInvoiceDate;
      if (today.day >= dayOfMonth) {
        final nextMonth = today.month == 12 ? 1 : today.month + 1;
        final nextYear = today.month == 12 ? today.year + 1 : today.year;
        nextInvoiceDate = DateTime(nextYear, nextMonth, dayOfMonth);
      } else {
        nextInvoiceDate = DateTime(today.year, today.month, dayOfMonth);
      }

      return DateTime(
        nextInvoiceDate.year,
        nextInvoiceDate.month,
        nextInvoiceDate.day,
      );
    } catch (e) {
      return null;
    }
  }

  Widget _buildRemainingDaysWidget(
    Geree? geree, {
    required VoidCallback onTapBilling,
    required String totalBalance,
    required String totalAldangi,
    String? bairNer,
    String? toot,
  }) {
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

    // SPECIAL CASE: For non-organization users, due day is 20th of every month
    if (_isNonOrgUser && nextInvoiceDate == null) {
      final today = DateTime.now();
      if (today.day >= 20) {
        final nextMonth = today.month == 12 ? 1 : today.month + 1;
        final nextYear = today.month == 12 ? today.year + 1 : today.year;
        nextInvoiceDate = DateTime(nextYear, nextMonth, 20);
      } else {
        nextInvoiceDate = DateTime(today.year, today.month, 20);
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
      // If we can't predict next payday from cron, use contract start date as fallback.
      if (geree != null) {
        final nextContractInvoiceDate =
            _calculateNextInvoiceDateFromContract(geree.gereeniiOgnoo);
        if (nextContractInvoiceDate != null) {
          final today = DateTime.now();
          final todayDateOnly = DateTime(today.year, today.month, today.day);

          if (nextContractInvoiceDate.isAfter(todayDateOnly) ||
              nextContractInvoiceDate.isAtSameMomentAs(todayDateOnly)) {
            final remainingDays =
                nextContractInvoiceDate.difference(todayDateOnly).inDays;
            displayDays = remainingDays;
            rightLabel = 'Өдөр';
            centerLabel = 'Төлөлт хийхэд';
            accentColor = AppColors.deepGreen;
            nextUnitDateText =
                '${nextContractInvoiceDate.year}-${nextContractInvoiceDate.month.toString().padLeft(2, '0')}-${nextContractInvoiceDate.day.toString().padLeft(2, '0')}';
            final clampedRemaining = remainingDays > 30 ? 30 : remainingDays;
            targetProgress = 1.0 - (clampedRemaining / 30.0);
          } else {
            final daysOverdue =
                todayDateOnly.difference(nextContractInvoiceDate).inDays;
            displayDays = daysOverdue;
            rightLabel = 'Өдөр';
            centerLabel = 'өдөр хэтэрсэн';
            accentColor = const Color(0xFFFF6B6B);
            nextUnitDateText =
                '${nextContractInvoiceDate.year}-${nextContractInvoiceDate.month.toString().padLeft(2, '0')}-${nextContractInvoiceDate.day.toString().padLeft(2, '0')}';
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
      } else {
        // Mock data for user without org
        displayDays = 0;
        rightLabel = 'Өдөр';
        centerLabel = 'Мэдээлэл байхгүй';
        accentColor = const Color(0xFF6C5CE7); // Deep Purple for First Signup
        targetProgress = 0.0;
        nextUnitDateText = '---';
      }
    }

    // Override styling for First Signup users (Bpay signups with no address yet)
    


    if (_userProfile != null) {

    }
                         
    if (_isNonOrgUser && !hasAnyAddress) {
       accentColor = const Color(0xFF6C5CE7); // Premium Purple/Indigo
    }

    final isDark = context.isDarkMode;

    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(horizontal: 18.w, vertical: 6.h),
      decoration: BoxDecoration(
        color: accentColor,
        borderRadius: BorderRadius.circular(28.r),
        boxShadow: [
          BoxShadow(
            color: accentColor.withOpacity(0.3),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (bairNer != null || toot != null) ...[
            Container(
              padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 6.h),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(100),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.home_work_rounded, size: 14.sp, color: Colors.white),
                  SizedBox(width: 6.w),
                  Flexible(
                    child: Text(
                      '${bairNer ?? ""} - ${toot ?? ""} тоот',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 11.sp,
                        fontWeight: FontWeight.w800,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(height: 4.h),
          ],
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
                          Flexible(
                            child: FittedBox(
                              fit: BoxFit.scaleDown,
                              child: Text(
                                '$displayDays',
                                style: TextStyle(
                                  fontSize: 36.sp,
                                  fontWeight: FontWeight.w900,
                                  color: Colors.white,
                                  height: 1.0,
                                  letterSpacing: -1,
                                ),
                              ),
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
                      FittedBox(
                        fit: BoxFit.scaleDown,
                        alignment: Alignment.centerLeft,
                        child: Text(
                          centerLabel,
                          style: TextStyle(
                            fontSize: 12.sp,
                            fontWeight: FontWeight.w800,
                            color: Colors.white.withOpacity(0.8),
                            letterSpacing: 0.5,
                          ),
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
                      SizedBox(height: 4.h),
                      FittedBox(
                        fit: BoxFit.scaleDown,
                        alignment: Alignment.centerLeft,
                        child: Text(
                          nextUnitDateText,
                          style: TextStyle(
                            fontSize: 17.sp,
                            fontWeight: FontWeight.w800,
                            color: Colors.white,
                            letterSpacing: -0.5,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          SizedBox(height: 4.h),
          // Progress bar
          Stack(
            children: [
              Container(
                height: 6.h,
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
                      height: 6.h,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                      ),
                    ),
                  );
                },
              ),
            ],
          ),
          SizedBox(height: 4.h),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Мөчлөгийн явц',
                style: TextStyle(
                  fontSize: 10.sp,
                  color: Colors.white.withOpacity(0.5),
                ),
              ),
              Text(
                '${(targetProgress * 100).toInt()}%',
                style: TextStyle(
                  fontSize: 11.sp,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
              ),
            ],
          ),
          SizedBox(height: 4.h),
          // Inline billing row - compact strip
          GestureDetector(
            onTap: onTapBilling,
            child: Container(
              padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 6.h),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.12),
                borderRadius: BorderRadius.circular(16.r),
                border: Border.all(color: Colors.white.withOpacity(0.2), width: 1),
              ),
              child: Row(
                children: [
                  Icon(
                    _isNonOrgUser && !hasAnyAddress 
                        ? Icons.location_on_outlined 
                        : Icons.account_balance_wallet_outlined, 
                    color: Colors.white, 
                    size: 16.sp
                  ),
                  SizedBox(width: 10.w),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          !hasAnyAddress 
                              ? 'Бүртгэлгүй байна' 
                              : 'Байрны төлбөр',
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.7),
                            fontSize: 11.sp,
                          ),
                        ),
                        FittedBox(
                          fit: BoxFit.scaleDown,
                          alignment: Alignment.centerLeft,
                          child: Text(
                            !hasAnyAddress 
                                ? 'Хаяг сонгох' 
                                : () {
                                    final numBalance = double.tryParse(
                                      totalBalance.replaceAll(',', '').replaceAll('₮', '').trim(),
                                    ) ?? 0.0;
                                    if (numBalance < 0) return '+${totalBalance.replaceAll('-', '')}₮ Илүү төлөлт';
                                    if (numBalance == 0) return 'Төлбөр байхгүй';
                                    return '$totalBalance₮';
                                  }(),
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 13.sp,
                              fontWeight: FontWeight.w700,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Icon(Icons.arrow_forward_ios_rounded, color: Colors.white.withOpacity(0.6), size: 12.sp),
                ],
              ),
            ),
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
                    // _loadGereeData is now handled within _refreshBillingInfo
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

                      // 1. Merged Remaining Days & Billing Box - PageView for multiple contracts
                      if (_isNonOrgUser || 
                          (_gereeResponse != null && _gereeResponse!.jagsaalt.isNotEmpty) ||
                          _billingList.isNotEmpty)
                        Column(
                          children: [
                            SizedBox(
                              // Granular responsive height to support various devices (iPhone, iPad, Surface Duo)
                              height: () {
                                final isSmall = context.screenWidth < 360;
                                final isLargePhone = context.screenWidth >= 400 && !context.isTablet;
                                
                                if (context.isTablet || context.isFoldable) {
                                  return (_isNonOrgUser && !hasAnyAddress) ? 240.h : 310.h;
                                } else if (isLargePhone) {
                                  return (_isNonOrgUser && !hasAnyAddress) ? 190.h : 210.h;
                                } else if (isSmall) {
                                  return (_isNonOrgUser && !hasAnyAddress) ? 180.h : 195.h;
                                } else {
                                  return (_isNonOrgUser && !hasAnyAddress) ? 185.h : 205.h;
                                }
                              }(),
                              child: PageView.builder(
                                controller: _contractPageController,
                                itemCount: (_gereeResponse != null && _gereeResponse!.jagsaalt.isNotEmpty)
                                    ? _gereeResponse!.jagsaalt.length
                                    : 1,
                                itemBuilder: (context, index) {
                                  final g = (_gereeResponse != null && _gereeResponse!.jagsaalt.isNotEmpty)
                                      ? _gereeResponse!.jagsaalt[index]
                                      : null;
                                  
                                  // Find the aggregated balance for this specific unit from finalBillingList
                                  String unitBalance = _formatNumberWithComma(totalNiitTulbur);
                                  String unitAldangi = _formatNumberWithComma(totalNiitAldangi);
                                  
                                  if (g != null) {
                                    final billingItem = _billingList.firstWhere(
                                      (b) => b['gereeniiDugaar'] == g.gereeniiDugaar,
                                      orElse: () => {},
                                    );
                                    if (billingItem.isNotEmpty) {
                                      unitBalance = _formatNumberWithComma(billingItem['uldegdel'] ?? 0.0);
                                      unitAldangi = _formatNumberWithComma(billingItem['uldegdelAldangi'] ?? 0.0);
                                    }
                                  }

                                  return Padding(
                                    padding: EdgeInsets.symmetric(horizontal: 4.w),
                                    child: _buildRemainingDaysWidget(
                                      g,
                                      onTapBilling: (_gereeResponse != null && _gereeResponse!.jagsaalt.isNotEmpty) || _billingList.isNotEmpty
                                          ? _navigateToBillingList
                                          : () => context.push('/address_selection'),
                                      totalBalance: unitBalance,
                                      totalAldangi: unitAldangi,
                                      bairNer: g?.bairNer,
                                      toot: g?.toot.toString(),
                                    ),
                                  );
                                },
                              ),
                            ),
                            if (_gereeResponse != null && _gereeResponse!.jagsaalt.length > 1) ...[
                              SizedBox(height: 12.h),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: List.generate(_gereeResponse!.jagsaalt.length, (index) {
                                  return AnimatedBuilder(
                                    animation: _contractPageController,
                                    builder: (context, child) {
                                      double selectedness = 0.0;
                                      try {
                                        if (_contractPageController.hasClients && _contractPageController.page != null) {
                                          selectedness = (1.0 - (_contractPageController.page! - index).abs()).clamp(0.0, 1.0);
                                        } else if (index == 0) {
                                          selectedness = 1.0;
                                        }
                                      } catch (_) {
                                        if (index == 0) selectedness = 1.0;
                                      }
                                      return Container(
                                        margin: EdgeInsets.symmetric(horizontal: 4.w),
                                        height: 6.h,
                                        width: 6.h + (selectedness * 12.w),
                                        decoration: BoxDecoration(
                                          color: AppColors.deepGreen.withOpacity(0.2 + (selectedness * 0.8)),
                                          borderRadius: BorderRadius.circular(100),
                                        ),
                                      );
                                    },
                                  );
                                }),
                              ),
                            ],
                          ],
                        )
                      else
                        const SizedBox.shrink(),

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

    String expanded = address.trim();

    expanded = expanded.replaceAll(RegExp(r'\bБГД\b'), 'Баянгол дүүрэг');
    expanded = expanded.replaceAll(RegExp(r'\bБЗД\b'), 'Баянзүрх дүүрэг');
    expanded = expanded.replaceAll(RegExp(r'\bСБД\b'), 'Сүхбаатар дүүрэг');
    expanded = expanded.replaceAll(RegExp(r'\bХУД\b'), 'Хан-Уул дүүрэг');
    expanded = expanded.replaceAll(RegExp(r'\bЧД\b'), 'Чингэлтэй дүүрэг');
    expanded = expanded.replaceAll(RegExp(r'\bСХД\b'), 'Сонгинохайрхан дүүрэг');
    expanded = expanded.replaceAll(RegExp(r'\bНЛ\b'), 'Налайх дүүрэг');
    expanded = expanded.replaceAll(RegExp(r'\bНЛД\b'), 'Налайх дүүрэг');
    expanded = expanded.replaceAll(RegExp(r'\bБНД\b'), 'Багануур дүүрэг');
    expanded = expanded.replaceAll(RegExp(r'\bБХД\b'), 'Багахангай дүүрэг');

    // Add comma after district if missing before something like "хороо"
    expanded = expanded.replaceAllMapped(RegExp(r'(дүүрэг)\s+(\d+-р хороо)'), (match) => '${match[1]}, ${match[2]}');
    // Add comma after khoroo if missing before something like "байр"
    expanded = expanded.replaceAllMapped(RegExp(r'(хороо)\s+(\d+-р\s+байр)'), (match) => '${match[1]}, ${match[2]}');

    // If it ends with a number (like door no), add "тоот"
    if (RegExp(r'\d+$').hasMatch(expanded) && !expanded.contains('тоот')) {
      expanded = '$expanded тоот';
    }

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
                    'Байрны төлбөр',
                    style: TextStyle(
                      fontSize: 15.sp,
                      color: context.textPrimaryColor,
                      letterSpacing: -0.2,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  SizedBox(height: 4.h),
                  Text(
                    () {
                      if (totalNiitTulbur < 0) {
                        return '+${_formatNumberWithComma(totalNiitTulbur.abs())}₮ Илүү төлөлт';
                      }
                      if (totalNiitTulbur == 0) {
                        return 'Төлбөрийн үлдэгдэлгүй';
                      }
                      return '${_formatNumberWithComma(totalNiitTulbur)}₮';
                    }(),
                    style: TextStyle(
                      fontSize: 13.sp,
                      color: totalNiitTulbur > 0 ? const Color(0xFFFF6B6B) : AppColors.deepGreen,
                      fontWeight: FontWeight.bold,
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
        'icon': Icons.local_parking_rounded,
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
        if (service['name'] == 'parkease') {
          context.push('/parkease');
          return;
        }
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
