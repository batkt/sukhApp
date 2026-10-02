import 'dart:ui' show ImageFilter;
import 'package:flutter/services.dart';
import 'dart:async';
import 'package:sukh_app/main.dart' show navigatorKey;
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart' show CupertinoIcons;
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
import 'package:sukh_app/widgets/update_modal.dart';
import 'package:sukh_app/services/push_service.dart';
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
import 'package:sukh_app/components/Home/draggable_floating_chatbot.dart';
import 'package:sukh_app/utils/error_message.dart';
import 'support_chat_page.dart';

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
    _loadLocalCache();
    _loadNekhemjlekhCron();
    _refreshBillingInfo(); // Consolidated refresh  
    _checkRecentWalletPayments();

    // Push token-ийг серверт бүртгэнэ (нийтлэл, санал асуулга, шинэчлэлтийн мэдэгдэл)
    PushService.serverteBurtgeye();

    // Шинэ хувилбар гарсан бол нүүр хуудсан дээр шинэчлэлтийн модал
    Future.delayed(const Duration(milliseconds: 1500), () {
      if (mounted) showUpdateModalIfAvailable(context);
    });

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

  /// Load cached data from StorageService immediately for instant startup display
  Future<void> _loadLocalCache() async {
    try {
      final userId = await StorageService.getUserId();
      if (userId == null || userId.isEmpty) {
        print('🔧 [CACHE] No logged-in user, skipping local cache load.');
        return;
      }

      // 1. Load isNonOrgUser early
      final baigId = await StorageService.getBaiguullagiinId();
      final isNonOrg = baigId == null ||
          baigId == 'null' ||
          baigId.isEmpty ||
          baigId == '698e7fd3b6dd386b6c56a808';

      // 2. Load cached toots
      final cachedToots = await StorageService.getToots();

      // 3. Load other cached fields (account-scoped by userId)
      final cachedBillingList = await StorageService.getCachedBillingList(userId);
      final cachedGereeData = await StorageService.getCachedGereeResponse(userId);
      final cachedTotals = await StorageService.getCachedTotals(userId);

      if (mounted) {
        setState(() {
          _isNonOrgUser = isNonOrg;
          if (cachedToots.isNotEmpty) {
            _userProfile = {'toots': cachedToots};
            _isInitialBillingLoaded = true;
          }
          if (cachedBillingList.isNotEmpty) {
            _billingList = cachedBillingList;
            _isInitialBillingLoaded = true;
            _isLoadingBillingList = false; // Stop loading spinner since we have cached data
          }
          if (cachedGereeData != null && cachedGereeData.isNotEmpty) {
            _gereeResponse = GereeResponse.fromJson(cachedGereeData);
            _isInitialBillingLoaded = true;
            _progressAnimationController.forward(); // Animate early
          }
          totalNiitTulbur = cachedTotals['total'] ?? 0.0;
          totalNiitAldangi = cachedTotals['aldangi'] ?? 0.0;
        });
        print('🔧 [CACHE] Loaded local cache for user $userId: isNonOrg=$isNonOrg, billingListCount=${cachedBillingList.length}');
      }
    } catch (e) {
      print('🔧 [CACHE] Failed to load local cache: $e');
    }
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

      // Аппыг удаан нээлттэй байлгасан үед гарсан шинэчлэлтийг ч мэдэгдэнэ
      showUpdateModalIfAvailable(context);

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

  /// Нэг л байрны төлбөрийг өөр өөр эх сурвалжаас (өөрийн байгууллага /
  /// түрийвч) таних түлхүүрүүд. Аль нэг түлхүүр давхацвал ижил төлбөр гэж үзнэ.
  Set<String> _billingTanikhTuluhuur(Map<String, dynamic> billing) {
    String tseverle(dynamic utga) => (utga?.toString() ?? '')
        .toLowerCase()
        .replaceAll(RegExp(r'[\s\-,.]'), '');

    final tuluhuur = <String>{};

    for (final talbar in ['gereeniiDugaar', 'billingId', 'customerNo', 'customerCode']) {
      final utga = tseverle(billing[talbar]);
      if (utga.isNotEmpty) tuluhuur.add('dugaar:$utga');
    }

    final gereeId = tseverle(billing['gereeniiId']);
    if (gereeId.isNotEmpty) tuluhuur.add('gereeId:$gereeId');

    final khayag = tseverle(billing['customerAddress'] ?? billing['bairniiNer']);
    final toot = tseverle(billing['tootNum']);
    if (khayag.isNotEmpty && toot.isNotEmpty) {
      tuluhuur.add('khayag:$khayag|$toot');
    }

    return tuluhuur;
  }


  /// Bpay (түрийвч)-ийн төлбөр ОРОН СУУЦНЫХ эсэх. Юнивишн, Скаймедиа,
  /// цахилгаан зэрэг бусад төлбөрийг «Байрны төлбөр»-т нэмэхгүй, нүүрний
  /// картад тусдаа хуудас болгохгүй.
  ///
  /// 1) Хаягаар холбосон төлбөр нь хэрэглэгчийн toots-д WALLET_API-аар
  ///    бичигддэг (billingId / walletCustomerId / walletCustomerCode).
  /// 2) Эс бөгөөс нэрээр (billing_list_page-тэй ижил дүрэм).
  bool _bpayOronSuutsEsekh(Map<String, dynamic> billing, [dynamic profile]) {
    if (billing['source'] != 'WALLET_API') return true;
    if (billing['isHousing'] is bool) return billing['isHousing'] as bool;

    String s(dynamic v) => (v?.toString() ?? '').trim();
    final toots = (profile ?? _userProfile)?['toots'];
    if (toots is List) {
      for (final t in toots) {
        if (t is! Map || s(t['source']) != 'WALLET_API') continue;
        final bId = s(billing['billingId']);
        final cId = s(billing['customerId']);
        final cCode = s(billing['customerCode']);
        if ((bId.isNotEmpty && bId == s(t['billingId'])) ||
            (cId.isNotEmpty && cId == s(t['walletCustomerId'])) ||
            (cCode.isNotEmpty && cCode == s(t['walletCustomerCode']))) {
          return true;
        }
      }
    }

    final ner = '${billing['billingName'] ?? ''} ${billing['billerName'] ?? ''}'
        .toLowerCase();
    const busad = [
      'юнивишн', 'юнивижн', 'univision', 'скаймедиа', 'skymedia', 'скай медиа',
      'цахилгаан', 'electric', 'тог', 'интернэт', 'internet', 'утас', 'mobile',
    ];
    if (busad.any(ner.contains)) return false;
    const oronSuuts = ['орон сууц', 'сөх', 'house', 'apartment', 'оснаак', 'сууц'];
    return oronSuuts.any(ner.contains);
  }

  /// Аль нэг картад хөнгөлөлт эсвэл алданги шошго харагдах эсэх
  bool get _kartShoshgotoi =>
      totalNiitAldangi > 0.5 ||
      _cardBillings.any((b) =>
          _parseNum(b['khungulult'] ?? 0) > 0.5 ||
          _parseNum(b['perItemAldangi'] ?? b['uldegdelAldangi'] ?? 0) > 0.5);

  /// Нүүрний картын хуудсууд: өөрийн байгууллагын гэрээ + Bpay-ийн орон
  /// сууцны төлбөр. Бусад (ТВ, цахилгаан) төлбөр «Төлбөрийн үйлчилгээ»-д.
  List<Map<String, dynamic>> get _cardBillings =>
      _billingList.where((b) => _bpayOronSuutsEsekh(b)).toList();

  Future<void> _loadAllBillingPayments() async {
    await _refreshBillingInfo();
  }

  /// Ачаалж байх үед ирсэн бодит цагийн шинэчлэлтийг алдахгүйн тулд
  bool _refreshQueued = false;

  Future<void> _refreshBillingInfo({bool forceRefresh = false}) async {
    if (!mounted) return;
    if (_isRefreshing) {
      _refreshQueued = true;
      return;
    }
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
        ApiService.getWalletBillingList(forceRefresh: forceRefresh).catchError((e) {
          print('⚠️ [REFRESH] getWalletBillingList failed: $e');
          return <Map<String, dynamic>>[];
        }),
        ApiService.fetchWalletQpayList().catchError((e) {
          print('⚠️ [REFRESH] fetchWalletQpayList failed (non-fatal): $e');
          return <Map<String, dynamic>>[];
        }),
        if (userId != null && !isWalletOnlyOrg) ApiService.fetchGeree(userId).catchError((e) {
          print('⚠️ [REFRESH] fetchGeree failed: $e');
          return <String, dynamic>{'jagsaalt': []};
        }) else Future.value({'jagsaalt': []}),
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
                double khungulultSum = 0.0;
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

                    // Сүүлийн нэхэмжлэхийн хөнгөлөлт — нүүрний картанд харуулна
                    final nekhemjlekhuud = mergedInvoices
                        .where((inv) => inv['isStandaloneAvlaga'] != true)
                        .map((inv) => NekhemjlekhItem.fromJson(inv))
                        .toList()
                      ..sort((a, b) => b.nekhemjlekhiinOgnoo.compareTo(a.nekhemjlekhiinOgnoo));
                    if (nekhemjlekhuud.isNotEmpty) {
                      khungulultSum = nekhemjlekhuud.first.khungulultDun;
                    }

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
                  'khungulult': khungulultSum,
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
                  'khungulult': result['khungulult'] ?? 0.0,
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

      // ── Бусад байгууллагын тоотуудыг нэмнэ ──────────────────────────────
      //
      // Дээрх давталт нь ЗӨВХӨН нэвтэрсэн байгууллагын гэрээг боловсруулдаг:
      // `fetchGeree` серверт очиход `tokenShalgakh` нь холболтыг token дотор
      // бичигдсэн байгууллагаар сонгож, дамжуулсан `baiguullagiinId`-г дарж
      // бичдэг тул клиентээс өөр байгууллагын гэрээ татах боломжгүй. Тиймээс
      // олон СӨХ-д бүртгэлтэй хэрэглэгчийн үлдсэн тоотуудыг сервер талд
      // нэгтгүүлсэн `/orshinSuugch/niitTulbur`-аас авч нэмнэ.
      if (!isWalletOnlyOrg) {
        try {
          final niit = await ApiService.fetchNiitTulburBukhOrg();
          final orgs = niit['baiguullaguud'];
          if (orgs is List) {
            // Дээр аль хэдийн боловсруулсан гэрээг давхар тоолохгүй.
            final seenGeree = finalBillingList
                .map((b) => b['gereeniiId']?.toString() ?? '')
                .where((v) => v.isNotEmpty)
                .toSet();

            for (final org in orgs) {
              final orgMap = Map<String, dynamic>.from(org as Map);
              final orgId = orgMap['baiguullagiinId']?.toString();
              final orgNer = orgMap['ner']?.toString() ?? '';
              final gereenuud = orgMap['gereenuud'];
              if (gereenuud is! List) continue;

              for (final g in gereenuud) {
                final gm = Map<String, dynamic>.from(g as Map);
                final gid = gm['gereeniiId']?.toString() ?? '';
                if (gid.isEmpty || seenGeree.contains(gid)) continue;
                seenGeree.add(gid);

                final uld = _parseNum(gm['uldegdel']);
                ownOrgTotal += uld;

                finalBillingList.add({
                  'billingId': gm['gereeniiDugaar']?.toString(),
                  'billingName': orgNer.isNotEmpty
                      ? orgNer
                      : (gm['bairNer']?.toString() ?? 'Орон сууцны төлбөр'),
                  'bairniiNer': gm['bairNer']?.toString() ?? '',
                  'tootNum': gm['toot']?.toString() ?? '',
                  'perItemTotal': uld,
                  'uldegdel': uld,
                  'uldegdelAldangi': 0.0,
                  'perItemAldangi': 0.0,
                  'isLocalData': false,
                  'source': 'OTHER_ORG',
                  'gereeniiDugaar': gm['gereeniiDugaar']?.toString(),
                  'gereeniiId': gid,
                  'baiguullagiinId': orgId,
                  'barilgiinId': gm['barilgiinId']?.toString(),
                });
              }
            }
          }
        } catch (e) {
          print('⚠️ [NIIT] бусад байгууллагын дүн нэмэгдсэнгүй: $e');
        }
      }

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
        final oronSuuts = _bpayOronSuutsEsekh(updatedBilling, user);
        updatedBilling['isHousing'] = oronSuuts;
        if (oronSuuts) {
          // Картанд хаяг/тоот харуулахын тулд toots-оос нөхнө
          final toots = user?['toots'];
          if (toots is List) {
            for (final t in toots) {
              if (t is Map &&
                  t['source']?.toString() == 'WALLET_API' &&
                  (t['billingId']?.toString() == billingId ||
                      t['walletCustomerId']?.toString() == billing['customerId']?.toString())) {
                updatedBilling['bairniiNer'] ??= t['bairniiNer'];
                updatedBilling['tootNum'] ??= t['toot'] ?? t['walletDoorNo'];
                break;
              }
            }
          }
          updatedBilling['bairniiNer'] ??= billing['customerAddress'];
        }
        
        return updatedBilling;
      });

      final updatedWalletBillings = await Future.wait(walletFutures);

      // 3. Merge and deduplicate if necessary, apply totals
      //
      // Өөрийн байгууллагын гэрээнүүдийн таних түлхүүрүүд. Түрийвчнээс ирсэн
      // ЯГ ижил байрны төлбөрийг хоёр удаа тоохгүйн тулд ашиглана.
      final Set<String> ownOrgTuluhuur = {};
      for (var b in finalBillingList) {
        if (b['source'] != 'OWN_ORG') continue;
        ownOrgTuluhuur.addAll(_billingTanikhTuluhuur(b));
      }

      for (var billing in updatedWalletBillings) {
        final billingTotal = _parseNum(billing['perItemTotal']);
        final billingAldangi = _parseNum(billing['perItemAldangi']);

        // Давхардлыг НЭРЭЭР нь биш, гэрээ/дугаар/хаяг-тоотоор нь шалгана.
        // Урьд нь нэрэнд «орон сууц» орсон бүх түрийвчний төлбөрийг өөрийн
        // байгууллагын дүнтэй давхардсан гэж үзээд нийт дүнгээс хасдаг байсан
        // тул ӨӨР байрны төлбөр нүүр дэлгэцийн нийт дүнд огт нэмэгддэггүй байв.
        final davkhardsan = _billingTanikhTuluhuur(
          billing,
        ).any(ownOrgTuluhuur.contains);

        // Зөвхөн орон сууцны төлбөр «Байрны төлбөр»-т орно
        if (!davkhardsan && billing['isHousing'] == true) {
          total += billingTotal;
          totalAldangi += billingAldangi;
        }
        finalBillingList.add(billing);
      }



      // If total is 0, double-check by fetching bills directly to ensure consistency with detail page
      if (total == 0.0) {
        double recalculatedTotal = 0.0;
        double recalculatedAldangi = 0.0;
        
        await Future.wait(updatedWalletBillings
            .where((b) => b['isHousing'] == true)
            .map((billing) async {
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
        _progressAnimationController.forward(); // Forward animation on fresh data
      }

      // Save to local cache for instant loading next time (scoped by userId to prevent cross-account leakage)
      if (userId != null && userId.isNotEmpty) {
        StorageService.saveCachedBillingList(userId, finalBillingList);
        if (gereeResponse.isNotEmpty) {
          StorageService.saveCachedGereeResponse(userId, gereeResponse);
        }
        StorageService.saveCachedTotals(userId, total, totalAldangi);
      }
    } catch (e) {
      // Refresh error handling
    } finally {
      if (mounted) {
        setState(() {
          _isLoadingBillingList = false;
          _isRefreshing = false;
        });
      } else {
        _isRefreshing = false;
      }
      if (_refreshQueued && mounted) {
        _refreshQueued = false;
        Future.microtask(() => _refreshBillingInfo());
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
      BlogSliderSection.refresh();

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
          message: friendlyError(e, fallback: 'Биллинг устгаж чадсангүй. Дахин оролдоно уу.'),
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
              'Биллерүүдийн жагсаалт олдсонгүй. Түр хүлээгээд дахин оролдоно уу.';
        } else if (errorMessage.contains('500')) {
          ApiService.handleUnauthorized(null, false);
          return;
        } else if (errorMessage.contains('Таны хүчинтэй хугацаа дууссан')) {
          // Already handled and logged out by api_service.dart
          return;
        } else {
          displayMessage = friendlyError(
            e,
            fallback: 'Биллерүүдийн жагсаалт татаж чадсангүй. Дахин оролдоно уу.',
          );
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

          
          final isPaid = await ApiService.checkWalletQPayStatus(
            walletPaymentId: walletPaymentId,
          );

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

  /// bpay-ийн дараагийн төлөлтийн огноо.
  ///
  /// bpay дээр төлөлтийн өдөр нь ҮРГЭЛЖ сарын 20 — энэ бол хуанлийн тогтмол
  /// дүрэм тул хамгийн ойрын 20-оос тоолно.
  ///
  /// Өмнө нь "хамгийн сүүлийн билл дээрх огноо + 1 сар" гэж тооцдог байсан.
  /// Гэвч билл нь тухайн сарынхаа төлбөрийг илэрхийлдэг — дээр нь сар нэмэхэд
  /// тоолуур яг одоо төлөх ёстой ээлжийг алгасч, дараагийн сарынхыг зааж байв:
  /// 9-р сарын 18-нд «2 өдөр» байх ёстой байтал «42 өдөр» гэж гарч байсан
  /// шалтгаан нь энэ.
  ///
  /// Зөвхөн WALLET_API билгүүдэд хамаарна; бусад тохиолдолд null буцааж доорх
  /// (cron / гэрээний) салаалалтуудыг хэвээр нь үлдээнэ.
  DateTime? _bpayNextInvoiceDate() {
    final bpayBillings = _cardBillings
        .where((billing) => billing['source']?.toString() == 'WALLET_API')
        .toList();
    if (bpayBillings.isEmpty) return null;

    const tulukhOdor = 20;
    final today = DateTime.now();
    final todayDateOnly = DateTime(today.year, today.month, today.day);
    final enSaryn20 = DateTime(today.year, today.month, tulukhOdor);

    // 20 хараахан болоогүй бол энэ сарын 20 (18-нд бол 2 өдөр).
    if (!enSaryn20.isBefore(todayDateOnly)) {
      debugPrint('[bpay] next invoice date → $enSaryn20');
      return enSaryn20;
    }

    // 20 өнгөрсөн ч төлөх үлдэгдэл үлдсэн бол хоцорсноор нь харуулна.
    final uldegdelTei = bpayBillings.any((billing) {
      final uldegdel = billing['uldegdel'] != null
          ? _parseNum(billing['uldegdel'])
          : _parseNum(billing['perItemTotal']);
      return uldegdel > 0;
    });
    if (uldegdelTei) {
      debugPrint('[bpay] overdue since $enSaryn20');
      return enSaryn20;
    }

    // Төлбөр хаагдсан бол дараагийн ээлж — ирэх сарын 20.
    final daraaSar = today.month == 12 ? 1 : today.month + 1;
    final daraaJil = today.month == 12 ? today.year + 1 : today.year;
    final daraagiin20 = DateTime(daraaJil, daraaSar, tulukhOdor);
    debugPrint('[bpay] next invoice date → $daraagiin20');
    return daraagiin20;
  }

  Widget _buildRemainingDaysWidget(
    Geree? geree, {
    required VoidCallback onTapBilling,
    required String totalBalance,
    required String totalAldangi,
    /// Сүүлийн нэхэмжлэхэд олгогдсон хөнгөлөлт (эерэг тоо)
    double khungulult = 0,
    String? bairNer,
    String? toot,
    /// Хэрэглэгчийн нийт тоотын тоо. 1-ээс их бол "Байрны төлбөр" мөр нь
    /// тухайн нэг тоотын биш, БҮХ тоотын нийлбэрийг харуулж байгааг
    /// шошгондоо тодотгоно.
    int unitCount = 1,
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

    // A bpay billing knows its own period, so prefer that over the wall clock.
    // Only WALLET_API billings are affected; everything else falls through to
    // the branches below unchanged.
    nextInvoiceDate ??= _bpayNextInvoiceDate();

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
        displayDays = 0;
        rightLabel = 'Өдөр';
        centerLabel = 'Мэдээлэл байхгүй';
        accentColor = AppColors.deepGreen;
        targetProgress = 0.0;
        nextUnitDateText = '---';
      }
    }
    // ── Харагдах утгууд ──
    final numBalance = double.tryParse(
          totalBalance.replaceAll(',', '').replaceAll('₮', '').trim(),
        ) ??
        0.0;
    final numAldangi = double.tryParse(
          totalAldangi.replaceAll(',', '').replaceAll('₮', '').trim(),
        ) ??
        0.0;
    final hetersen = centerLabel == 'өдөр хэтэрсэн';
    final medeelelgui = nextUnitDateText == '---' || nextUnitDateText.isEmpty;

    final String dunShoshgo;
    final String dunTekst;
    if (!hasAnyAddress) {
      dunShoshgo = 'Хаяг бүртгэгдээгүй';
      dunTekst = 'Хаягаа сонгоно уу';
    } else if (numBalance < -0.5) {
      dunShoshgo = 'Илүү төлөлт';
      dunTekst = '${totalBalance.replaceAll('-', '')}₮';
    } else if (numBalance.abs() <= 0.5) {
      dunShoshgo = 'Төлөх дүн';
      dunTekst = 'Төлбөргүй';
    } else {
      dunShoshgo = unitCount > 1 ? 'Нийт төлөх дүн ($unitCount тоот)' : 'Төлөх дүн';
      dunTekst = '$totalBalance₮';
    }

    final ognooTekst = medeelelgui ? '—' : nextUnitDateText.replaceAll('-', '.');
    final hayag = [
      if ((bairNer ?? '').trim().isNotEmpty) bairNer!.trim(),
      if ((toot ?? '').trim().isNotEmpty) '${toot!.trim()} тоот',
    ].join(', ');

    // Сэдвийн (цайвар/бараан) өнгө
    final isDark = context.isDarkMode;
    final fg = isDark ? Colors.white : const Color(0xFF0F2A21);
    final accent = isDark ? _HomeTone.mint : const Color(0xFF0E8F68);
    final danger = isDark ? const Color(0xFFFF9B95) : const Color(0xFFD93F3F);
    final cardBorder = isDark
        ? Colors.white.withOpacity(0.12)
        : AppColors.deepGreen.withOpacity(0.10);
    final panelBg = isDark
        ? Colors.white.withOpacity(0.12)
        : Colors.white.withOpacity(0.72);
    final panelBorder = isDark
        ? Colors.white.withOpacity(0.16)
        : AppColors.deepGreen.withOpacity(0.08);
    final btnBg = isDark ? Colors.white : AppColors.deepGreen;
    final btnFg = isDark ? AppColors.deepGreen : Colors.white;

    // iOS виджет маягийн карт: ногоон градиент + зөөлөн гэрлийн туяа,
    // доод хэсэг нь «шил» (frosted glass) самбар.
    return ClipRRect(
      borderRadius: BorderRadius.circular(30),
      child: Stack(
        children: [
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: isDark
                      ? const [Color(0xFF1A7A5E), Color(0xFF0E5642), _HomeTone.pine]
                      : const [Color(0xFFFFFFFF), Color(0xFFEFF8F3), Color(0xFFDDF1E7)],
                ),
              ),
            ),
          ),
          // Гэрлийн туяа (баруун дээд)
          Positioned(
            top: -90,
            right: -70,
            child: _glow(240, (isDark ? _HomeTone.mint : const Color(0xFF6EE7B7)).withOpacity(isDark ? 0.32 : 0.35)),
          ),
          // Гэрлийн туяа (зүүн доод)
          Positioned(
            bottom: -110,
            left: -60,
            child: _glow(220, const Color(0xFF38BDF8).withOpacity(isDark ? 0.14 : 0.12)),
          ),
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(30),
                border: Border.all(color: cardBorder),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 18, 14, 14),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              // Тогтмол зай баримтална — илүү зай нь картын доор үлдэнэ
              mainAxisAlignment: MainAxisAlignment.start,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (hayag.isNotEmpty)
                            Row(
                              children: [
                                Icon(Icons.home_rounded,
                                    size: 15, color: fg.withOpacity(0.85)),
                                const SizedBox(width: 6),
                                Flexible(
                                  child: Text(
                                    hayag,
                                    style: TextStyle(
                                      color: fg.withOpacity(0.9),
                                      fontSize: 13,
                                      fontWeight: FontWeight.w600,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                          const SizedBox(height: 12),
                          Text(
                            dunShoshgo,
                            style: TextStyle(
                              color: fg.withOpacity(0.6),
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          FittedBox(
                            fit: BoxFit.scaleDown,
                            alignment: Alignment.centerLeft,
                            child: Text(
                              dunTekst,
                              style: TextStyle(
                                color: numBalance < -0.5 ? accent : fg,
                                fontSize: hasAnyAddress ? 32 : 20,
                                fontWeight: FontWeight.w600,
                                letterSpacing: -1,
                                height: 1.15,
                              ),
                            ),
                          ),
                          if (hasAnyAddress && (khungulult > 0.5 || numAldangi > 0.5)) ...[
                            const SizedBox(height: 6),
                            Wrap(
                              spacing: 6,
                              runSpacing: 4,
                              children: [
                                if (khungulult > 0.5)
                                  _cardChip(fg,
                                    Icons.local_offer_rounded,
                                    'Хөнгөлөлт -${_formatNumberWithComma(khungulult)}₮',
                                    accent,
                                  ),
                                if (numAldangi > 0.5)
                                  _cardChip(fg,
                                    Icons.error_outline_rounded,
                                    'Алданги $totalAldangi₮',
                                    danger,
                                  ),
                              ],
                            ),
                          ],
                        ],
                      ),
                    ),
                    const SizedBox(width: 10),
                    // Төлөх хүртэлх хоног — «Мөчлөгийн явц»-ын оронд
                    _PaymentDaysRing(
                      progress: medeelelgui ? 0 : targetProgress,
                      days: medeelelgui ? null : displayDays,
                      caption: medeelelgui
                          ? 'мэдээлэлгүй'
                          : (hetersen ? 'өдөр хэтэрсэн' : 'өдөр үлдсэн'),
                      color: hetersen ? const Color(0xFFE5484D) : accent,
                      foreground: fg,
                      animation: _progressAnimation,
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                // Шилэн самбар: огноо + үйлдэл
                ClipRRect(
                  borderRadius: BorderRadius.circular(20),
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
                    child: Container(
                      padding: const EdgeInsets.fromLTRB(14, 8, 8, 8),
                      decoration: BoxDecoration(
                        color: panelBg,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: panelBorder),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            hetersen ? Icons.schedule_rounded : Icons.event_rounded,
                            size: 18,
                            color: hetersen
                                ? danger
                                : fg.withOpacity(0.85),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  hetersen ? 'Төлөх хугацаа өнгөрсөн' : 'Дараагийн төлөлт',
                                  style: TextStyle(
                                    color: hetersen
                                        ? danger
                                        : fg.withOpacity(0.65),
                                    fontSize: 11,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                Text(
                                  ognooTekst,
                                  style: TextStyle(
                                    color: fg,
                                    fontSize: 15,
                                    fontWeight: FontWeight.w600,
                                    letterSpacing: -0.2,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Material(
                            color: btnBg,
                            borderRadius: BorderRadius.circular(100),
                            child: InkWell(
                              borderRadius: BorderRadius.circular(100),
                              onTap: onTapBilling,
                              child: Padding(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 16, vertical: 9),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(
                                      hasAnyAddress ? 'Төлбөр харах' : 'Хаяг сонгох',
                                      style: TextStyle(
                                        color: btnFg,
                                        fontSize: 13,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                    const SizedBox(width: 2),
                                    Icon(Icons.chevron_right_rounded,
                                        size: 18, color: btnFg),
                                  ],
                                ),
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

  Widget _glow(double size, Color color) {
    return IgnorePointer(
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: RadialGradient(colors: [color, color.withOpacity(0)]),
        ),
      ),
    );
  }

  Widget _cardChip(Color fg, IconData icon, String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: fg.withOpacity(0.10),
        borderRadius: BorderRadius.circular(100),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 11, color: color),
          const SizedBox(width: 4),
          Text(
            text,
            style: TextStyle(
              color: fg,
              fontSize: 11,
              fontWeight: FontWeight.w600,
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
      body: LayoutBuilder(
        builder: (context, constraints) {
          final mediaQuery = MediaQuery.of(context);
          final screenSize = Size(constraints.maxWidth, constraints.maxHeight);
          final topPadding = mediaQuery.padding.top;
          final bottomPadding = mediaQuery.padding.bottom;

          return Stack(
            children: [
              Container(
        color: isDark ? const Color(0xFF0A0E14) : const Color(0xFFF3F5F2),
        child: Column(
          children: [
            HomeHeader(
              userName: (_isNonOrgUser && _userProfile?['hasCustomName'] != true)
                  ? null
                  : _userProfile?['ner']?.toString(),
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
                  BlogSliderSection.refresh();
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
                      Builder(builder: (context) {
                        final isCurrentlyLoading = _isLoadingBillingList || _isRefreshing;
                        // While both cache and network have not loaded at all, show a premium glass loading card
                        if (!_isInitialBillingLoaded || (isCurrentlyLoading && _billingList.isEmpty && (_gereeResponse == null || _gereeResponse!.jagsaalt.isEmpty))) {
                          final isDark = context.isDarkMode;
                          return Container(
                            height: 200.h,
                            width: double.infinity,
                            margin: EdgeInsets.symmetric(vertical: 6.h),
                            decoration: BoxDecoration(
                              color: isDark ? Colors.white.withOpacity(0.03) : Colors.black.withOpacity(0.02),
                              borderRadius: BorderRadius.circular(28.r),
                              border: Border.all(
                                color: isDark ? Colors.white.withOpacity(0.08) : Colors.black.withOpacity(0.05),
                                width: 1,
                              ),
                            ),
                            child: const Center(
                              child: CircularProgressIndicator(
                                color: AppColors.deepGreen,
                              ),
                            ),
                          );
                        }

                        final showCard = _isNonOrgUser || 
                            (_gereeResponse != null && _gereeResponse!.jagsaalt.isNotEmpty) ||
                            _billingList.isNotEmpty;
                        
                        if (!showCard) return const SizedBox.shrink();
                        
                        return Column(
                          children: [
                            SizedBox(
                              // Картын агуулга системийн фонтын хэмжээгээр (Android-д
                              // ихэвчлэн томруулсан байдаг) өсдөг тул өндрийг ч
                              // дагуулж өсгөнө — эс бөгөөс доод мөр тасардаг байв.
                              // Хөнгөлөлт/алданги шошготой карт байвал л өндрийг нэмнэ —
                              // эс бөгөөс картын доор хоосон зай үлддэг байв.
                              height: (_kartShoshgotoi ? 222.0 : 198.0) *
                                  (MediaQuery.textScalerOf(context).scale(10) / 10)
                                      .clamp(1.0, 1.5),
                              child: PageView.builder(
                                controller: _contractPageController,
                                itemCount: (_gereeResponse != null && _gereeResponse!.jagsaalt.isNotEmpty)
                                    ? _gereeResponse!.jagsaalt.length
                                    : (_cardBillings.isNotEmpty ? _cardBillings.length : 1),
                                itemBuilder: (context, index) {
                                  final g = (_gereeResponse != null && _gereeResponse!.jagsaalt.isNotEmpty)
                                      ? (index < _gereeResponse!.jagsaalt.length ? _gereeResponse!.jagsaalt[index] : null)
                                      : null;

                                  // Тоот тус бүрийн картыг тухайн тоотынх нь өөрийн төлбөрийн үлдэгдэлтэй харуулна
                                  double currentTootBalance = 0.0;
                                  double currentTootAldangi = 0.0;
                                  double currentTootKhungulult = 0.0;
                                  bool foundMatch = false;

                                  if (g != null) {
                                    // 1. _cardBillings-ээс энэ гэрээ/тоотод хамаарах бичлэгүүдийг шүүнэ
                                    final matchedBillings = _cardBillings.where((b) {
                                      // Гэрээний ID эсвэл гэрээний дугаараар
                                      final bGid = b['gereeniiId']?.toString();
                                      if (bGid != null && bGid.isNotEmpty && bGid == g.id) return true;

                                      final bGereeNo = b['gereeniiDugaar']?.toString();
                                      if (bGereeNo != null && bGereeNo.isNotEmpty && bGereeNo == g.gereeniiDugaar) return true;

                                      final bBillingId = b['billingId']?.toString();
                                      if (bBillingId != null && bBillingId.isNotEmpty && bBillingId == g.gereeniiDugaar) return true;

                                      // Тоот болон байрны нэр/ID-аар
                                      final bToot = b['tootNum']?.toString().trim();
                                      final gToot = g.toot.toString().trim();
                                      if (bToot != null && bToot.isNotEmpty && bToot == gToot) {
                                        final bBair = b['bairniiNer']?.toString().trim().toLowerCase() ?? '';
                                        final gBair = g.bairNer.trim().toLowerCase();
                                        final bBarilgaId = b['barilgiinId']?.toString();
                                        if (bBarilgaId != null && bBarilgaId.isNotEmpty && bBarilgaId == g.barilgiinId) return true;
                                        if (bBair.isNotEmpty && gBair.isNotEmpty && (bBair == gBair || bBair.contains(gBair) || gBair.contains(bBair))) return true;
                                      }
                                      return false;
                                    }).toList();

                                    if (matchedBillings.isNotEmpty) {
                                      foundMatch = true;
                                      for (var b in matchedBillings) {
                                        currentTootBalance += _parseNum(b['perItemTotal'] ?? b['uldegdel']);
                                        currentTootAldangi += _parseNum(b['perItemAldangi'] ?? b['uldegdelAldangi']);
                                        currentTootKhungulult += _parseNum(b['khungulult'] ?? 0);
                                      }
                                    } else {
                                      // Хэрэв шууд тааралт олоогүй бол индексээр эсвэл гэрээний дүнгээр
                                      if (index < _cardBillings.length && _cardBillings.length == (_gereeResponse?.jagsaalt.length ?? 0)) {
                                        foundMatch = true;
                                        final b = _cardBillings[index];
                                        currentTootBalance = _parseNum(b['perItemTotal'] ?? b['uldegdel']);
                                        currentTootAldangi = _parseNum(b['perItemAldangi'] ?? b['uldegdelAldangi']);
                                        currentTootKhungulult = _parseNum(b['khungulult'] ?? 0);
                                      } else if (g.niitTulbur > 0.0) {
                                        foundMatch = true;
                                        currentTootBalance = g.niitTulbur;
                                      }
                                    }
                                  } else if (_cardBillings.isNotEmpty) {
                                    if (index < _cardBillings.length) {
                                      foundMatch = true;
                                      final b = _cardBillings[index];
                                      currentTootBalance = _parseNum(b['perItemTotal'] ?? b['uldegdel']);
                                      currentTootAldangi = _parseNum(b['perItemAldangi'] ?? b['uldegdelAldangi']);
                                      currentTootKhungulult = _parseNum(b['khungulult'] ?? 0);
                                    }
                                  }

                                  // Хэрэв хэрэглэгч ганц л тооттой бөгөөд дээрхээс дүн олдоогүй бол totalNiitTulbur руу буцна
                                  if (!foundMatch && (_gereeResponse == null || _gereeResponse!.jagsaalt.length <= 1)) {
                                    currentTootBalance = totalNiitTulbur;
                                    currentTootAldangi = totalNiitAldangi;
                                  }

                                  final String unitBalance = _formatNumberWithComma(currentTootBalance);
                                  final String unitAldangi = _formatNumberWithComma(currentTootAldangi);

                                  // Fallback: If no geree, use wallet toots from profile for address display
                                  String? displayBairNer = g?.bairNer;
                                  String? displayToot = g?.toot.toString();
                                  
                                  // Bpay: картын төлбөрийн өөрийн хаягийг түрүүлж авна
                                  if (g == null && index < _cardBillings.length) {
                                    final cb = _cardBillings[index];
                                    final cbNer = cb['bairniiNer']?.toString();
                                    if (cbNer != null && cbNer.isNotEmpty) {
                                      displayBairNer = cbNer;
                                      displayToot = cb['tootNum']?.toString();
                                    }
                                  }
                                  if (g == null && displayBairNer == null && _userProfile != null && _userProfile!['toots'] != null) {
                                    final profileToots = _userProfile!['toots'] as List;
                                    if (profileToots.isNotEmpty) {
                                      final pIndex = index < profileToots.length ? index : 0;
                                      final tMap = profileToots[pIndex] is Map<String, dynamic> 
                                          ? profileToots[pIndex] as Map<String, dynamic>
                                          : Map<String, dynamic>.from(profileToots[pIndex] as Map);
                                      displayBairNer = tMap['bairniiNer']?.toString();
                                      displayToot = tMap['toot']?.toString();
                                    }
                                  }
                                  
                                  // Also try from billingList if still null
                                  if (displayBairNer == null && _cardBillings.isNotEmpty) {
                                    final bIndex = index < _cardBillings.length ? index : 0;
                                    displayBairNer = _cardBillings[bIndex]['bairniiNer']?.toString() ?? 
                                                     _cardBillings[bIndex]['billingName']?.toString();
                                    displayToot ??= _cardBillings[bIndex]['tootNum']?.toString();
                                  }
                                  
                                  // Also try root-level profile fields
                                  if (displayBairNer == null && _userProfile != null) {
                                    displayBairNer = _userProfile!['bairniiNer']?.toString();
                                    displayToot ??= _userProfile!['toot']?.toString();
                                  }

                                  return Padding(
                                    padding: EdgeInsets.symmetric(horizontal: 4.w),
                                    child: _buildRemainingDaysWidget(
                                      g,
                                      onTapBilling: () {
                                        if (_isLoadingBillingList || _isRefreshing) {
                                          showGlassSnackBar(
                                            context,
                                            message: 'Мэдээлэл ачаалж байна, түр хүлээнэ үү.',
                                            icon: Icons.hourglass_empty_rounded,
                                            iconColor: Colors.orange,
                                          );
                                          return;
                                        }
                                        if ((_gereeResponse != null && _gereeResponse!.jagsaalt.isNotEmpty) || _billingList.isNotEmpty) {
                                          _navigateToBillingList();
                                        } else {
                                          context.push('/address_selection');
                                        }
                                      },
                                      totalBalance: unitBalance,
                                      totalAldangi: unitAldangi,
                                      khungulult: currentTootKhungulult,
                                      bairNer: displayBairNer,
                                      toot: displayToot,
                                      // Карт тус бүр өөрийн гэсэн 1 тоотыг төлөөлж байгаа тул 1 гэж дамжуулна
                                      unitCount: 1,
                                    ),
                                  );
                                },
                              ),
                            ),
                            if (((_gereeResponse != null && _gereeResponse!.jagsaalt.isNotEmpty) ? _gereeResponse!.jagsaalt.length : (_cardBillings.isNotEmpty ? _cardBillings.length : 1)) > 1) ...[
                              SizedBox(height: 12.h),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: List.generate((_gereeResponse != null && _gereeResponse!.jagsaalt.isNotEmpty) ? _gereeResponse!.jagsaalt.length : (_cardBillings.isNotEmpty ? _cardBillings.length : 1), (index) {
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
                        );
                      }),

                      SizedBox(height: 22.h),

                      // 3. Нэмэлт боломж Section
                      _buildAdditionalServicesSection(),

                      SizedBox(height: 22.h),

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
                            if (_isLoadingBillingList || _isRefreshing) {
                              showGlassSnackBar(
                                context,
                                message: 'Мэдээлэл ачаалж байна, түр хүлээнэ үү.',
                                icon: Icons.hourglass_empty_rounded,
                                iconColor: Colors.orange,
                              );
                              return;
                            }
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
              // Floating draggable & dismissible chatbot overlay
              DraggableFloatingChatbot(
                screenSize: screenSize,
                topPadding: topPadding,
                bottomPadding: bottomPadding,
              ),
            ],
          );
        },
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
            ? 'Биллингийн мэдээлэл олдсонгүй. Хаягаа шалгаад дахин оролдоно уу.'
            : friendlyError(e, fallback: 'Биллинг холбож чадсангүй. Дахин оролдоно уу.');
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
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  SizedBox(height: 4.h),
                  Text(
                    () {
                      if (totalNiitTulbur < 0) {
                        return 'Илүү төлөлт: ${_formatNumberWithComma(totalNiitTulbur.abs())}₮';
                      }
                      if (totalNiitTulbur == 0) {
                        return 'Төлбөрийн үлдэгдэлгүй';
                      }
                      return '${_formatNumberWithComma(totalNiitTulbur)}₮';
                    }(),
                    style: TextStyle(
                      fontSize: 13.sp,
                      color: totalNiitTulbur > 0 ? const Color(0xFFFF6B6B) : AppColors.deepGreen,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  if (totalNiitTulbur < 0) ...[
                    SizedBox(height: 2.h),
                    Text(
                      'Дараагийн нэхэмжлэхээс автоматаар хасагдана',
                      style: TextStyle(
                        fontSize: 10.5.sp,
                        color: context.textSecondaryColor,
                        fontWeight: FontWeight.w500,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
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

    // Нэг өнгөт (брэнд ногоон) нимгэн шугаман icon — тансаг, тайван харагдана
    final services = [
      {'name': 'Зогсоол', 'label': 'Зогсоол', 'icon': CupertinoIcons.car_detailed},
      {'name': 'камер', 'label': 'Камер', 'icon': CupertinoIcons.videocam},
      {'name': 'лифт', 'label': 'Лифт', 'icon': CupertinoIcons.arrow_up_arrow_down_square},
      {'name': 'зочин', 'label': 'Зочин', 'icon': CupertinoIcons.person_badge_plus},
      {'name': 'дуудлага', 'label': 'Дуудлага', 'icon': CupertinoIcons.wrench},
      {'name': 'цэвэрлэгээ', 'label': 'Цэвэрлэгээ', 'icon': CupertinoIcons.sparkles},
      {'name': 'санал', 'label': 'Асуулга', 'icon': CupertinoIcons.chart_bar_square},
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Section Header
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 4.w),
          child: Text(
            'Үйлчилгээ',
            style: TextStyle(
              fontSize: 17.sp,
              color: context.textPrimaryColor,
              fontWeight: FontWeight.w600,
              letterSpacing: -0.4,
            ),
          ),
        ),

        SizedBox(height: 10.h),

        // Services Grid — iOS-ийн бүлэглэсэн самбар дотор апп-icon маягаар
        Container(
          padding: EdgeInsets.fromLTRB(8.w, 14.h, 8.w, 6.h),
          decoration: BoxDecoration(
            color: isDark ? Colors.white.withOpacity(0.05) : Colors.white,
            borderRadius: BorderRadius.circular(26.r),
            border: Border.all(
              color: isDark
                  ? Colors.white.withOpacity(0.06)
                  : Colors.black.withOpacity(0.04),
            ),
          ),
          child: GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            padding: EdgeInsets.zero,
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 4,
              crossAxisSpacing: 4.w,
              mainAxisSpacing: 8.h,
              childAspectRatio: 0.92,
            ),
            itemCount: services.length,
            itemBuilder: (context, index) {
              final service = services[index];
              return _buildServiceCard(service, isDark);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildServiceCard(Map<String, dynamic> service, bool isDark) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () async {
        if (service['name'] == 'Зогсоол') {
          final baigId = await StorageService.getBaiguullagiinId();
          final isNonOrg = baigId == null ||
              baigId == 'null' ||
              baigId.isEmpty ||
              baigId == '698e7fd3b6dd386b6c56a808';

          if (isNonOrg) {
            if (context.mounted) {
              showGlassSnackBar(
                context,
                message: 'Тухайн СӨХ нь зогсоолын холболт хийгээгүй байна.',
                icon: Icons.info_outline,
                iconColor: Colors.orange,
              );
            }
            return;
          }

          // Show a progress indicator while checking settings
          if (context.mounted) {
            showDialog(
              context: context,
              barrierDismissible: false,
              builder: (dialogCtx) => const Center(
                child: CircularProgressIndicator(color: AppColors.primary),
              ),
            );
          }

          try {
            final response = await ApiService.fetchParkingSettings();
            final List<dynamic> list = response['jagsaalt'] ?? [];
            
            if (context.mounted && Navigator.canPop(context)) {
              Navigator.pop(context); // Dismiss spinner
            }

            if (list.isEmpty || !list.any((s) => (s['khaalga'] as List? ?? []).isNotEmpty)) {
              if (context.mounted) {
                showGlassSnackBar(
                  context,
                  message: 'Тухайн СӨХ нь зогсоолын холболт хийгээгүй байна.',
                  icon: Icons.info_outline,
                  iconColor: Colors.orange,
                );
              }
            } else {
              if (context.mounted) {
                context.push('/parkease');
              }
            }
          } catch (e) {
            if (context.mounted && Navigator.canPop(context)) {
              Navigator.pop(context); // Dismiss spinner
            }
            if (context.mounted) {
              showGlassSnackBar(
                context,
                message: 'Тухайн СӨХ нь зогсоолын холболт хийгээгүй байна.',
                icon: Icons.info_outline,
                iconColor: Colors.orange,
              );
            }
          }
          return;
        }
        if (service['name'] == 'камер') {
          context.push('/camera');
          return;
        }
        if (service['name'] == 'зочин') {
          if (context.mounted) {
            context.push('/zochin-urikh');
          }
          return;
        }
        if (service['name'] == 'лифт') {
          context.push('/lift');
          return;
        }
        if (service['name'] == 'санал') {
          context.push('/sanal_asuulga');
          return;
        }
        if (service['name'] == 'цэвэрлэгээ') {
          context.push('/tseverlegee');
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
      child: _UilchilgeeIcon(
        icon: service['icon'] as IconData? ?? Icons.apps_rounded,
        label: service['label'] as String? ?? '',
        isDark: isDark,
      ),
    );
  }
}

/// Нүүр хуудасны өнгөний токен: ойн ногоон суурь + гаа (mint) өргөлт.
class _HomeTone {
  static const Color pine = Color(0xFF0A3328);
  static const Color mint = Color(0xFF7DF0C6);
}

/// Дараагийн төлөлт хүртэлх хоногийг цагирагаар харуулна.
class _PaymentDaysRing extends StatelessWidget {
  final double progress;
  final int? days;
  final String caption;
  final Color color;
  final Color foreground;
  final Animation<double> animation;

  const _PaymentDaysRing({
    required this.progress,
    required this.days,
    required this.caption,
    required this.color,
    this.foreground = Colors.white,
    required this.animation,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 84,
      height: 84,
      child: AnimatedBuilder(
        animation: animation,
        builder: (context, _) => CustomPaint(
          painter: _RingPainter(
            progress: (progress * animation.value).clamp(0.0, 1.0),
            color: color,
            track: foreground.withOpacity(0.12),
          ),
          child: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  days?.toString() ?? '—',
                  style: TextStyle(
                    color: foreground,
                    fontSize: 24,
                    fontWeight: FontWeight.w600,
                    height: 1.0,
                    letterSpacing: -0.5,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  caption,
                  style: TextStyle(
                    color: foreground.withOpacity(0.7),
                    fontSize: 9.5,
                    fontWeight: FontWeight.w500,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _RingPainter extends CustomPainter {
  final double progress;
  final Color color;
  final Color track;

  _RingPainter({required this.progress, required this.color, required this.track});

  @override
  void paint(Canvas canvas, Size size) {
    const stroke = 6.0;
    final rect = Rect.fromLTWH(
      stroke / 2,
      stroke / 2,
      size.width - stroke,
      size.height - stroke,
    );
    final trackPaint = Paint()
      ..color = track
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke;
    canvas.drawArc(rect, 0, 2 * math.pi, false, trackPaint);
    if (progress > 0) {
      final arc = Paint()
        ..color = color
        ..style = PaintingStyle.stroke
        ..strokeWidth = stroke
        ..strokeCap = StrokeCap.round;
      canvas.drawArc(rect, -math.pi / 2, 2 * math.pi * progress, false, arc);
    }
  }

  @override
  bool shouldRepaint(_RingPainter old) =>
      old.progress != progress || old.color != color || old.track != track;
}

/// Үйлчилгээний icon — нэг өнгөт, дарахад зөөлөн шахагдана.
class _UilchilgeeIcon extends StatefulWidget {
  final IconData icon;
  final String label;
  final bool isDark;

  const _UilchilgeeIcon({
    required this.icon,
    required this.label,
    required this.isDark,
  });

  @override
  State<_UilchilgeeIcon> createState() => _UilchilgeeIconState();
}

class _UilchilgeeIconState extends State<_UilchilgeeIcon> {
  bool _darsan = false;

  void _tuluv(bool v) {
    if (_darsan != v) setState(() => _darsan = v);
  }

  @override
  Widget build(BuildContext context) {
    final dark = widget.isDark;
    final tamga = dark ? _HomeTone.mint : AppColors.deepGreen;

    return Listener(
      onPointerDown: (_) => _tuluv(true),
      onPointerUp: (_) => _tuluv(false),
      onPointerCancel: (_) => _tuluv(false),
      child: AnimatedScale(
        scale: _darsan ? 0.94 : 1,
        duration: const Duration(milliseconds: 120),
        curve: Curves.easeOut,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 120),
              width: 54.w,
              height: 54.w,
              decoration: BoxDecoration(
                color: dark
                    ? Colors.white.withOpacity(_darsan ? 0.11 : 0.06)
                    : (_darsan ? const Color(0xFFE3ECE8) : const Color(0xFFF1F5F3)),
                borderRadius: BorderRadius.circular(16.r),
                border: Border.all(
                  color: dark
                      ? Colors.white.withOpacity(0.07)
                      : AppColors.deepGreen.withOpacity(0.06),
                ),
              ),
              child: Icon(widget.icon, color: tamga, size: 25.sp),
            ),
            SizedBox(height: 8.h),
            Text(
              widget.label,
              style: TextStyle(
                fontSize: 11.5.sp,
                color: context.textPrimaryColor.withOpacity(0.85),
                fontWeight: FontWeight.w500,
                letterSpacing: -0.1,
              ),
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}
