import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:sukh_app/components/Menu/side_menu.dart';
import 'package:sukh_app/components/Home/billing_connection_section.dart';
import 'package:sukh_app/components/Home/billing_list_section.dart';
import 'package:sukh_app/components/Home/billers_grid.dart';
import 'package:sukh_app/components/Home/blog_slider_section.dart';
import 'package:sukh_app/services/storage_service.dart';
import 'package:sukh_app/services/api_service.dart';
import 'package:sukh_app/services/socket_service.dart';
import 'package:sukh_app/models/geree_model.dart';
import 'package:sukh_app/components/Nekhemjlekh/nekhemjlekh_models.dart';
import 'package:sukh_app/utils/nekhemjlekh_merge_util.dart';
import 'package:sukh_app/models/medegdel_model.dart';
import 'package:sukh_app/screens/Home/billing_detail_page.dart';
import 'package:sukh_app/screens/Home/billing_list_page.dart';
import 'package:sukh_app/components/Home/billing_actions.dart';
import 'package:sukh_app/components/Home/billing_connection_service.dart';
import 'package:sukh_app/components/Home/gree_section.dart';
import 'package:sukh_app/components/Home/billing_box.dart';
import 'package:sukh_app/components/Home/billers_section.dart';
import 'package:sukh_app/components/Home/home_header.dart';
import 'package:sukh_app/widgets/glass_snackbar.dart';
import 'package:sukh_app/utils/format_util.dart';
import 'package:sukh_app/constants/constants.dart';
import 'package:sukh_app/utils/theme_extensions.dart';
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

  // User billing data from profile
  Map<String, dynamic>? _userBillingData;

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
    _loadBillingList();
    _loadNotificationCount();
    _setupSocketListener();
    _loadGereeData();
    _loadNekhemjlekhCron(); // Load nekhemjlekh cron data for date calculation
    _refreshBillingInfo(); // Consolidated refresh
    _checkRecentWalletPayments(); // Check latest wallet payment status

    // Periodic balance refresh (every 60s) - fallback when socket notification is missed
    _balanceRefreshTimer = Timer.periodic(const Duration(seconds: 60), (_) {
      if (mounted) _refreshBillingInfo();
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

  double _parseNum(dynamic val) {
    if (val == null) return 0.0;
    if (val is num) return val.toDouble();
    if (val is String) return double.tryParse(val) ?? 0.0;
    return 0.0;
  }

  Future<void> _loadBillingList() async {
    await _refreshBillingInfo();
  }

  bool _isInitialBillingLoaded = false;

  Future<void> _refreshBillingInfo() async {
    if (!mounted) return;

    // Only show full loading state on the very first load
    if (!_isInitialBillingLoaded) {
      setState(() {
        _isLoadingBillingList = true;
      });
    }

    try {
      // 1. Fetch data from Wallet API
      final rawBillingList = await ApiService.getWalletBillingList();
      double total = 0.0;
      double totalAldangi = 0.0;
      double ownOrgTotal = 0.0;
      double ownOrgAldangi = 0.0;

      // 2. Fetch User Profile
      Map<String, dynamic>? userBillingData;
      try {
        final profileRes = await ApiService.getUserProfile();
        if (profileRes['success'] == true && profileRes['result'] != null) {
          final userData = profileRes['result'];
          if (userData['walletCustomerId'] != null ||
              userData['walletBairId'] != null ||
              (userData['bairniiNer']?.isNotEmpty ?? false)) {
            String fullName = userData['ovog'] != null
                ? '${userData['ovog']} ${userData['ner'] ?? ''}'
                : (userData['ner'] ?? '');
            userBillingData = {
              'customerId': userData['walletCustomerId']?.toString(),
              'customerCode': userData['walletCustomerCode']?.toString(),
              'customerName': fullName,
              'billingName': 'Орон сууцны төлбөр',
              'bairniiNer': userData['bairniiNer']?.toString() ?? '',
              'walletBairId': userData['walletBairId']?.toString(),
              'walletDoorNo': userData['walletDoorNo']?.toString(),
              'isLocalData': true,
            };
          }
        }
      } catch (_) {}

      // 3. Calculate Own Org (Residential) Balance
      final currentBaiguullagiinId = await StorageService.getBaiguullagiinId();
      if (currentBaiguullagiinId != '698e7fd3b6dd386b6c56a808') {
        try {
          final userId = await StorageService.getUserId();
          if (userId != null) {
            final geree = await ApiService.fetchGeree(userId);
            if (geree['jagsaalt'] != null && geree['jagsaalt'] is List) {
              for (var contract in geree['jagsaalt']) {
                double uld = _parseNum(
                  contract['uldegdel'] ??
                      contract['globalUldegdel'] ??
                      contract['balance'] ??
                      contract['uldegdl_dun'] ??
                      contract['tulukh_uldegdel'],
                );
                double ald = _parseNum(
                  contract['aldangi'] ??
                      contract['billLateFeeAmount'] ??
                      contract['aldangi_dun'],
                );
                ownOrgTotal += uld;
                ownOrgAldangi += ald;
              }
            }
          }
        } catch (_) {}
      }
      total = ownOrgTotal;
      totalAldangi = ownOrgAldangi;

      // 4. Calculate Wallet Billing Balances
      List<Map<String, dynamic>> updatedBillingList = [];
      for (var billing in rawBillingList) {
        Map<String, dynamic> item = Map<String, dynamic>.from(billing);
        double itemTotal = 0.0;
        double itemAldandi = 0.0;
        final billingId = billing['billingId']?.toString();

        if (billingId != null && billingId.isNotEmpty) {
          try {
            final billsData = await ApiService.getWalletBillingBills(
              billingId: billingId,
            );
            List<dynamic> bills = (billsData['newBills'] is List)
                ? billsData['newBills']
                : (billsData.containsKey('newBills') &&
                          billsData['newBills'] is Map
                      ? [billsData['newBills']]
                      : []);
            for (var b in bills) {
              itemTotal += _parseNum(b['billTotalAmount']);
              itemAldandi += _parseNum(
                b['billLateFeeAmount'] ?? b['billLateFee'],
              );
            }
          } catch (_) {}
        }
        item['perItemTotal'] = itemTotal;
        item['perItemAldangi'] = itemAldandi;

        final bName = item['billingName']?.toString() ?? '';
        if (ownOrgTotal > 0 &&
            (bName.contains('Орон сууцны') || bName.contains('Property'))) {
        } else {
          total += itemTotal;
          totalAldangi += itemAldandi;
        }
        updatedBillingList.add(item);
      }

      if (userBillingData != null) {
        userBillingData['perItemTotal'] = ownOrgTotal;
        userBillingData['perItemAldangi'] = ownOrgAldangi;

        bool hasDuplicateInWallet = false;
        for (var b in updatedBillingList) {
          final bName = b['billingName']?.toString() ?? '';
          if (bName == 'Орон сууцны төлбөр' ||
              (b['customerId']?.toString() ==
                      userBillingData['customerId']?.toString() &&
                  userBillingData['customerId'] != null)) {
            if (_parseNum(b['perItemTotal']) == 0 && ownOrgTotal > 0) {
              b['perItemTotal'] = ownOrgTotal;
              b['perItemAldangi'] = ownOrgAldangi;
            }
            hasDuplicateInWallet = true;
          }
        }

        if (hasDuplicateInWallet) {
          userBillingData = null;
        }
      }

      if (mounted) {
        setState(() {
          _billingList = updatedBillingList;
          _userBillingData = userBillingData;
          totalNiitTulbur = total;
          totalNiitAldangi = totalAldangi;
          _isLoadingBillingList = false;
          _isInitialBillingLoaded = true;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoadingBillingList = false;
          _isInitialBillingLoaded = true;
        });
      }
    }
  }

  Future<void> _deleteBilling(Map<String, dynamic> billing) async {
    final billingId =
        billing['billingId']?.toString() ??
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
        title: Text(
          'Биллинг устгах',
          style: TextStyle(color: context.textPrimaryColor),
        ),
        content: Text(
          'Та энэ биллингийг устгахдаа итгэлтэй байна уу?',
          style: TextStyle(color: context.textSecondaryColor),
        ),
        backgroundColor: context.backgroundColor,
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text('Үгүй', style: TextStyle(color: AppColors.deepGreen)),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
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

  Future<void> _editBilling(
    Map<String, dynamic> billing, [
    VoidCallback? onUpdated,
  ]) async {
    final billingId =
        billing['billingId']?.toString() ??
        billing['walletBillingId']?.toString();

    if (billingId == null) {
      showGlassSnackBar(
        context,
        message: 'Энэ биллинг засварлах боломжгүй байна.',
        icon: Icons.info_outline,
        iconColor: Colors.orange,
      );
      return;
    }

    final currentNickname = billing['nickname']?.toString() ?? '';
    final controller = TextEditingController(text: currentNickname);

    final result = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        final isDark = context.isDarkMode;
        return Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(ctx).viewInsets.bottom,
          ),
          child: Container(
            margin: EdgeInsets.all(16.w),
            padding: EdgeInsets.all(24.w),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1C2229) : Colors.white,
              borderRadius: BorderRadius.circular(24.r),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.15),
                  blurRadius: 30,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: EdgeInsets.all(10.w),
                      decoration: BoxDecoration(
                        color: AppColors.deepGreen.withOpacity(0.12),
                        borderRadius: BorderRadius.circular(12.r),
                      ),
                      child: Icon(
                        Icons.edit_outlined,
                        color: AppColors.deepGreen,
                        size: 20.sp,
                      ),
                    ),
                    SizedBox(width: 12.w),
                    Expanded(
                      child: Text(
                        'Нэр өгөх',
                        style: TextStyle(
                          color: isDark ? Colors.white : Colors.black87,
                          fontSize: 18.sp,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                    GestureDetector(
                      onTap: () => Navigator.of(ctx).pop(),
                      child: Icon(
                        Icons.close_rounded,
                        color: isDark ? Colors.white54 : Colors.black38,
                        size: 22.sp,
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 8.h),
                Text(
                  billing['billingName']?.toString() ?? 'Биллинг',
                  style: TextStyle(
                    color: isDark ? Colors.white54 : Colors.black45,
                    fontSize: 13.sp,
                    fontWeight: FontWeight.w400,
                  ),
                ),
                SizedBox(height: 20.h),
                TextField(
                  controller: controller,
                  autofocus: true,
                  style: TextStyle(
                    color: isDark ? Colors.white : Colors.black87,
                    fontSize: 15.sp,
                    fontWeight: FontWeight.w400,
                  ),
                  decoration: InputDecoration(
                    hintText: 'Жишээ: Миний байр',
                    hintStyle: TextStyle(
                      color: isDark ? Colors.white30 : Colors.black26,
                      fontSize: 15.sp,
                      fontWeight: FontWeight.w400,
                    ),
                    filled: true,
                    fillColor: isDark
                        ? Colors.white.withOpacity(0.06)
                        : Colors.grey.withOpacity(0.08),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14.r),
                      borderSide: BorderSide.none,
                    ),
                    contentPadding: EdgeInsets.symmetric(
                      horizontal: 16.w,
                      vertical: 14.h,
                    ),
                  ),
                ),
                SizedBox(height: 20.h),
                SizedBox(
                  width: double.infinity,
                  height: 48.h,
                  child: ElevatedButton(
                    onPressed: () =>
                        Navigator.of(ctx).pop(controller.text.trim()),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.deepGreen,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14.r),
                      ),
                    ),
                    child: Text(
                      'Хадгалах',
                      style: TextStyle(
                        fontSize: 15.sp,
                        fontWeight: FontWeight.w500,
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

    if (result == null) return; // dismissed

    try {
      await ApiService.setWalletBillingNickname(
        billingId: billingId,
        nickname: result,
      );
      if (mounted) {
        // Directly mutate the billing map reference so all holders see the change
        billing['nickname'] = result.isEmpty ? null : result;
        // Also update in _billingList for consistency
        setState(() {
          for (int i = 0; i < _billingList.length; i++) {
            final itemBillingId =
                _billingList[i]['billingId']?.toString() ??
                _billingList[i]['walletBillingId']?.toString();
            if (itemBillingId == billingId) {
              _billingList[i]['nickname'] = result.isEmpty ? null : result;
              break;
            }
          }
        });
        // Trigger rebuild on calling page (e.g. BillingListPage)
        onUpdated?.call();
        showGlassSnackBar(
          context,
          message: result.isEmpty
              ? 'Хоч нэр устгагдлаа'
              : 'Хоч нэр хадгалагдлаа',
          icon: Icons.check_circle,
          iconColor: Colors.green,
        );
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
      double totalAldangi = 0.0;
      double ownOrgTotal = 0.0;
      double ownOrgAldangi = 0.0;
      _lastBalanceRefresh = DateTime.now();

      final currentBaiguullagiinId = await StorageService.getBaiguullagiinId();
      final isWalletOnlyOrg =
          currentBaiguullagiinId == '698e7fd3b6dd386b6c56a808';

      if (!isWalletOnlyOrg) {
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

                final contractUldegdel =
                    contract['uldegdel'] ?? contract['globalUldegdel'];
                if (contractUldegdel != null) {
                  final amt = (contractUldegdel is num)
                      ? contractUldegdel.toDouble()
                      : (double.tryParse(contractUldegdel.toString()) ?? 0.0);
                  if (amt > 0) ownOrgTotal += amt;
                }

                final contractAldangiValue = contract['aldangi'] ?? 0.0;
                final aldAmnt = (contractAldangiValue is num)
                    ? contractAldangiValue.toDouble()
                    : (double.tryParse(contractAldangiValue.toString()) ?? 0.0);
                if (aldAmnt > 0) ownOrgAldangi += aldAmnt;
              }
            }
          }
        } catch (_) {}
      }

      total = ownOrgTotal;
      totalAldangi = ownOrgAldangi;

      // Load WALLET_API payments
      List<Map<String, dynamic>> updatedBillingList = [];
      try {
        final rawBillingList = await ApiService.getWalletBillingList();
        for (var billing in rawBillingList) {
          Map<String, dynamic> updatedBilling = Map<String, dynamic>.from(
            billing,
          );
          final billingId = billing['billingId']?.toString();
          double billingTotal = 0.0;
          double billingAldangi = 0.0;

          if (billingId != null && billingId.isNotEmpty) {
            try {
              final billingData = await ApiService.getWalletBillingBills(
                billingId: billingId,
              );
              List<Map<String, dynamic>> bills = [];
              if (billingData['newBills'] != null &&
                  billingData['newBills'] is List) {
                final newBillsList = billingData['newBills'] as List;
                if (newBillsList.isNotEmpty) {
                  final firstItem = newBillsList[0] as Map<String, dynamic>;
                  if (firstItem.containsKey('billId')) {
                    bills = List<Map<String, dynamic>>.from(newBillsList);
                  } else if (firstItem.containsKey('billingId') &&
                      firstItem['newBills'] != null &&
                      firstItem['newBills'] is List) {
                    bills = List<Map<String, dynamic>>.from(
                      firstItem['newBills'],
                    );
                  }
                }
              } else if (billingData.containsKey('billingId') &&
                  billingData['newBills'] != null &&
                  billingData['newBills'] is List) {
                bills = List<Map<String, dynamic>>.from(
                  billingData['newBills'],
                );
              }

              for (var bill in bills) {
                final amt =
                    (bill['billTotalAmount'] as num?)?.toDouble() ?? 0.0;
                final ald =
                    (bill['billLateFeeAmount'] as num?)?.toDouble() ??
                    (bill['billLateFee'] as num?)?.toDouble() ??
                    0.0;
                billingTotal += amt;
                billingAldangi += ald;
              }
            } catch (_) {}
          }

          updatedBilling['perItemTotal'] = billingTotal;
          updatedBilling['perItemAldangi'] = billingAldangi;

          final billingName = billing['billingName']?.toString() ?? '';
          if (ownOrgTotal > 0 &&
              (billingName.contains('Орон сууцны') ||
                  billingName.contains('Property'))) {
            // Deduplication skip
          } else {
            total += billingTotal;
            totalAldangi += billingAldangi;
          }
          updatedBillingList.add(updatedBilling);
        }
      } catch (_) {}

      if (mounted) {
        setState(() {
          totalNiitTulbur = total;
          totalNiitAldangi = totalAldangi;
          _billingList = updatedBillingList;
          if (_userBillingData != null) {
            _userBillingData!['perItemTotal'] = ownOrgTotal;
            _userBillingData!['perItemAldangi'] = ownOrgAldangi;
          }
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
                            color: accentColor,
                            height: 1.0,
                          ),
                        ),
                        SizedBox(height: 4.h),
                        Text(
                          centerLabel,
                          style: TextStyle(
                            fontSize: 10.sp,
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
                      ),
                    ),
                    SizedBox(height: 4.h),
                    Text(
                      nextUnitDateText,
                      style: TextStyle(fontSize: 13.sp, color: accentColor),
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
                      SizedBox(height: 4.h), // Reduced since header has padding
                      // "Төлбөр" Box
                      BillingBox(
                        onTap: _navigateToBillingList,
                        totalBalance: _formatNumberWithComma(totalNiitTulbur),
                        totalAldangi: _formatNumberWithComma(totalNiitAldangi),
                      ),

                      SizedBox(height: 16.h),

                      // Billers Grid
                      BillersSection(
                        isLoadingBillers: _isLoadingBillers,
                        billers: _billers,
                        onDevelopmentTap: () => _showDevelopmentModal(context),
                        onBillerTap: () {
                          if (_billingList.isEmpty &&
                              _userBillingData == null) {
                            _navigateToBillingList();
                          }
                        },
                      ),

                      SizedBox(height: 12.h),

                      // Remaining Days Display
                      GreeSection(greeResponse: _gereeResponse),

                      SizedBox(height: 12.h),

                      // Blog Slider Section
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

  Future<void> _showBillingDetailModal(
    Map<String, dynamic> billing, [
    BuildContext? bContext,
  ]) async {
    if (!mounted) return;

    final navContext = bContext ?? context;
    if (billing['isLocalData'] == true) {
      navContext.push('/nekhemjlekh');
      return;
    }

    final result = await Navigator.push(
      navContext,
      MaterialPageRoute(
        builder: (context) => BillingDetailPage(
          billing: billing,
          expandAddressAbbreviations: _expandAddressAbbreviations,
          formatNumberWithComma: _formatNumberWithComma,
        ),
      ),
    );

    if (result == true && mounted) {
      _loadAllBillingPayments();
      _loadBillingList();
    }
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
        'onBillingTap': (billing, ctx) => _showBillingDetailModal(billing, ctx),
        'expandAddressAbbreviations': _expandAddressAbbreviations,
        'onDeleteTap': _deleteBilling,
        'onEditTap': _editBilling,
        'isConnecting': _isConnectingBilling,
        'onConnect': _connectBillingByAddress,
        'onRefresh': () async {
          await Future.wait([_loadBillingList(), _loadAllBillingPayments()]);
        },
      },
    );
  }
}
