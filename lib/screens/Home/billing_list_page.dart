import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:sukh_app/components/Home/billing_list_section.dart';
import 'package:sukh_app/components/Home/billing_connection_section.dart';
import 'package:sukh_app/utils/theme_extensions.dart';
import 'package:sukh_app/constants/constants.dart';
import 'package:sukh_app/widgets/glass_snackbar.dart';
import 'package:sukh_app/services/api_service.dart';
import 'package:sukh_app/utils/format_util.dart';
import 'package:sukh_app/screens/Home/billing_detail_page.dart';
import 'package:sukh_app/services/socket_service.dart';

class BillingListPage extends StatefulWidget {
  final List<Map<String, dynamic>> billingList;
  final Map<String, dynamic>? userBillingData;
  final bool isLoading;
  final double totalBalance;
  final double totalAldangi;
  final Function(Map<String, dynamic>) onBillingTap;
  final String Function(String) expandAddressAbbreviations;
  final Function(Map<String, dynamic>, {BuildContext? ctx})? onDeleteTap;
  final Function(Map<String, dynamic>, {BuildContext? ctx, VoidCallback? onUpdated})?
      onEditTap;
  final bool isConnecting;
  final VoidCallback onConnect;
  final Future<void> Function() onRefresh;

  const BillingListPage({
    super.key,
    required this.billingList,
    this.userBillingData,
    required this.isLoading,
    required this.totalBalance,
    required this.totalAldangi,
    required this.onBillingTap,
    required this.expandAddressAbbreviations,
    this.onDeleteTap,
    this.onEditTap,
    required this.isConnecting,
    required this.onConnect,
    required this.onRefresh,
  });

  @override
  State<BillingListPage> createState() => _BillingListPageState();
}

class _BillingListPageState extends State<BillingListPage> {
  bool _localIsLoading = false;
  late List<Map<String, dynamic>> _localBillingList;
  Map<String, dynamic>? _localUserBillingData;
  late double _localTotalBalance;
  late double _localTotalAldangi;

  void Function(Map<String, dynamic>)? _notificationCallback;

  String _resolveWalletPaymentState(Map<String, dynamic> walletData) {
    final state = walletData['paymentStatus']?.toString().toUpperCase() ?? '';
    if (state == 'REFUNDED') return 'REFUNDED';
    if (state == 'PAID' || state == 'PENDING') return state;

    final hasSuccessfulTrx =
        (walletData['paymentTransactions'] as List?)?.any((trx) {
          final trxStatus = trx['trxStatus']?.toString().toUpperCase() ?? '';
          return trxStatus == 'SUCCESS' || trx['trxStatusName']?.toString() == 'Амжилттай';
        }) ??
        false;

    bool hasSuccessfulTrxInLines = false;
    final lines = walletData['lines'] as List?;
    if (lines != null) {
      for (final line in lines) {
        final lineTrx = line['billTransactions'] as List?;
        if (lineTrx != null &&
            lineTrx.any((trx) {
              final trxStatus = trx['trxStatus']?.toString().toUpperCase() ?? '';
              return trxStatus == 'SUCCESS' || trx['trxStatusName']?.toString() == 'Амжилттай';
            })) {
          hasSuccessfulTrxInLines = true;
          break;
        }
      }
    }

    if (hasSuccessfulTrx || hasSuccessfulTrxInLines) {
      return 'PAID';
    }
    return state;
  }

  @override
  void initState() {
    super.initState();
    _localBillingList = List.from(widget.billingList);
    _localUserBillingData = widget.userBillingData;
    _localTotalBalance = widget.totalBalance;
    _localTotalAldangi = widget.totalAldangi;

    final hasData = _localBillingList.isNotEmpty || _localUserBillingData != null;
    _localIsLoading = widget.isLoading && !hasData;
    _setupSocketListener();
  }

  void _setupSocketListener() async {
    // Ensure socket is connected
    if (!SocketService.instance.isConnected) {
      await SocketService.instance.connect();
    }

    _notificationCallback = (notification) {
      if (mounted) {
        final type = (notification['type'] ?? notification['turul'])?.toString().toLowerCase() ?? '';
        if (type == 'billing_update') {
          // A billing was added or removed in the backend
          _refresh();
        }
      }
    };
    SocketService.instance.setNotificationCallback(_notificationCallback!);
  }

  @override
  void dispose() {
    if (_notificationCallback != null) {
      SocketService.instance.removeNotificationCallback(_notificationCallback);
    }
    super.dispose();
  }

  @override
  void didUpdateWidget(BillingListPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    final dataChanged =
        oldWidget.billingList.length != widget.billingList.length ||
        oldWidget.billingList != widget.billingList ||
        oldWidget.userBillingData != widget.userBillingData ||
        oldWidget.totalBalance != widget.totalBalance ||
        oldWidget.totalAldangi != widget.totalAldangi;
    final loadingChanged = oldWidget.isLoading != widget.isLoading;

    if (dataChanged || loadingChanged) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          final hasData =
              widget.billingList.isNotEmpty || widget.userBillingData != null;
          setState(() {
            _localBillingList = List.from(widget.billingList);
            _localUserBillingData = widget.userBillingData;
            _localTotalBalance = widget.totalBalance;
            _localTotalAldangi = widget.totalAldangi;
            _localIsLoading = widget.isLoading && !hasData;
          });
        }
      });
    }
  }

  Future<void> _refresh() async {
    if (!mounted) return;
    setState(() => _localIsLoading = true);
    
    // Call parent refresh
    await widget.onRefresh();
    
    // Also fetch latest list locally to ensure UI updates even when pushed
    if (mounted) {
      try {
        final newList = await ApiService.getWalletBillingList(forceRefresh: true);
        
        // Calculate new totals from the list if possible, 
        // or just rely on the new list for the display
        double newTotal = 0.0;
        double newAldangi = 0.0;

        // Fetch recent wallet history to filter out already paid/pending bills
        List<Map<String, dynamic>> walletHistory = [];
        try {
          walletHistory = await ApiService.fetchWalletQpayList();
        } catch(_) {}

        // Match by billNo — wallet-check returns billNo in lines[], not billIds
        final Set<String> recentlyPaidBillNos = {};
        final recentItems = walletHistory.take(10).toList();
        final Set<String> refundedBillNos = {};

        // Pass 1: collect refunded bill keys (absolute override)
        for (final h in recentItems) {
          final walletPaymentId = h['walletPaymentId']?.toString() ?? '';
          final zakhialgiinDugaar = h['zakhialgiinDugaar']?.toString() ?? '';
          final checkId = walletPaymentId.isNotEmpty ? walletPaymentId : zakhialgiinDugaar;
          if (checkId.isEmpty) continue;

          try {
            final st = await ApiService.walletQpayWalletCheck(walletPaymentId: checkId);
            if (st['success'] == true && st['data'] != null) {
              final walletData = st['data'];
              final resolvedState = _resolveWalletPaymentState(walletData);
              final lines = walletData['lines'] as List?;
              if (resolvedState == 'REFUNDED' && lines != null) {
                for (final line in lines) {
                  final billNo = line['billNo']?.toString();
                  final billId = line['billId']?.toString();
                  if (billNo != null && billNo.isNotEmpty) refundedBillNos.add(billNo);
                  if (billId != null && billId.isNotEmpty) refundedBillNos.add(billId);
                }
              }
            }
          } catch (_) {}
        }

        // Pass 2: mark active paid/pending unless refunded exists for same bill
        for (final h in recentItems) {
          final walletPaymentId = h['walletPaymentId']?.toString() ?? '';
          final zakhialgiinDugaar = h['zakhialgiinDugaar']?.toString() ?? '';
          final checkId = walletPaymentId.isNotEmpty ? walletPaymentId : zakhialgiinDugaar;
          if (checkId.isEmpty) continue;

          try {
            final st = await ApiService.walletQpayWalletCheck(walletPaymentId: checkId);
            if (st['success'] == true && st['data'] != null) {
              final walletData = st['data'];
              final resolvedState = _resolveWalletPaymentState(walletData);
              final lines = walletData['lines'] as List?;
              if (resolvedState == 'PAID' || resolvedState == 'PENDING') {
                final hasRefundedOverride = (lines ?? []).any((line) {
                  final billNo = line['billNo']?.toString() ?? '';
                  final billId = line['billId']?.toString() ?? '';
                  return refundedBillNos.contains(billNo) || refundedBillNos.contains(billId);
                });
                if (hasRefundedOverride) continue;

                // Extract billNo from lines (primary match key)
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

        // Parallel fetch for details — use server's pre-computed amounts
        final results = await Future.wait(newList.map((b) async {
          final bId = b['billingId']?.toString();
          if (bId != null && bId.isNotEmpty) {
             try {
                final details = await ApiService.getWalletBillingBills(billingId: bId, forceRefresh: true);
                double t = 0.0;
                double a = 0.0;
                List filteredBills = [];

                // PRIORITY 1: Trust the server's pre-computed amount.
                // Server sets newBillsAmount=0 when bills are PENDING/PAID.
                final serverAmount = details['newBillsAmount'];
                final serverAldangi = details['newBillsAldangi'];
                final parsedServerAmount = (serverAmount is num)
                    ? serverAmount.toDouble()
                    : double.tryParse(serverAmount?.toString() ?? '') ?? 0.0;
                if (serverAmount != null && parsedServerAmount > 0) {
                  t = parsedServerAmount;
                  a = (serverAldangi is num) ? serverAldangi.toDouble() : 0.0;
                  // Temporary override: show all bills while backend status sync is unstable.
                  final originalBills = details['newBills'] as List? ?? [];
                  for (var bill in originalBills) {
                    filteredBills.add(bill);
                  }
                } else {
                  // FALLBACK: manual sum — do not hide bills by backend transient flags.
                  final originalBills = details['newBills'] as List? ?? [];
                  for (var bill in originalBills) {
                    filteredBills.add(bill);
                    t += (bill['billTotalAmount'] is num) ? (bill['billTotalAmount'] as num).toDouble() : 0.0;
                    a += (bill['billLateFee'] is num) ? (bill['billLateFee'] as num).toDouble() : 0.0;
                  }
                }

                final updatedDetails = Map<String, dynamic>.from(details);
                updatedDetails['newBills'] = filteredBills;

                // Force synchronization with the authoritative ledger balance for residential bills
                double uldegdel = t;
                double uldegdelAldangi = a;
                final bName = b['billingName']?.toString().toLowerCase() ?? '';
                if (bName.contains('орон сууц') || bName.contains('сөх')) {
                  try {
                    final gereeniiDugaar = b['customerCode']?.toString() ?? '';
                    final baiguullagiinId = b['baiguullagiinId']?.toString() ?? '';
                    if (gereeniiDugaar.isNotEmpty) {
                      final ledger = await ApiService.fetchInvoicesWithItems(
                        baiguullagiinId: baiguullagiinId,
                        gereeniiDugaar: gereeniiDugaar,
                        gereeniiId: '',
                      );
                      uldegdel = (ledger['totalUldegdel'] ?? t).toDouble();
                      uldegdelAldangi = (ledger['totalAldangi'] ?? a).toDouble();
                    }
                  } catch (e) {
                    debugPrint('Error syncing ledger during refresh: $e');
                  }
                }

                return {
                  'total': uldegdel,
                  'aldangi': uldegdelAldangi,
                  'details': updatedDetails,
                  'uldegdel': uldegdel,
                  'uldegdelAldangi': uldegdelAldangi
                };
             } catch(_) { return {'total': 0.0, 'aldangi': 0.0}; }
          }
          return {'total': 0.0, 'aldangi': 0.0};
        }));

        final List<Map<String, dynamic>> enrichedList = [];
        for(int i=0; i<newList.length; i++) {
          final item = Map<String, dynamic>.from(newList[i]);
          item['perItemTotal'] = results[i]['total'];
          item['perItemAldangi'] = results[i]['aldangi'];
          item['billingDetails'] = results[i]['details'];
          item['uldegdel'] = results[i]['uldegdel'];
          item['uldegdelAldangi'] = results[i]['uldegdelAldangi'];
          enrichedList.add(item);
          newTotal += (results[i]['total'] as double);
          newAldangi += (results[i]['aldangi'] as double);
        }

        if (mounted) {
          setState(() {
            _localBillingList = enrichedList;
            _localTotalBalance = newTotal;
            _localTotalAldangi = newAldangi;
            _localIsLoading = false;
          });
        }
      } catch (e) {
        debugPrint('Error fetching billing list in page refresh: $e');
        if (mounted) setState(() => _localIsLoading = false);
      }
    }
  }

  Future<void> _addNewAddress() async {
    // Check if user has email
    try {
      final profileRes = await ApiService.getUserProfile();
      final user = profileRes['result'];
      final email = user?['mail']?.toString() ?? '';

      if (email.isEmpty || email.endsWith('@amarhome.mn')) {
        if (mounted) {
          showGlassSnackBar(
            context,
            message: 'Биллинг холбоход и-мэйл хаяг шаардлагатай',
            icon: Icons.alternate_email_rounded,
          );
          // Navigate to profile to add email
          context.push('/profile?action=edit_email');
        }
        return;
      }
    } catch (e) {
      debugPrint('Error checking profile for email: $e');
      // If error, we still allow but maybe show warning?
      // Better to allow if API is down to not block user, but here we require it.
    }

    final result = await context.push('/utility-add');
    if (result == true) {
      setState(() => _localIsLoading = true);
      await widget.onRefresh();
      // Add a small delay to ensure data is updated
      await Future.delayed(const Duration(milliseconds: 100));
      if (mounted) {
        setState(() => _localIsLoading = false);
      }
    }
  }

  String _formatNumberWithComma(dynamic value) {
    if (value == null) return '0';
    try {
      final number = double.parse(value.toString());
      return formatNumber(number);
    } catch (e) {
      return '0';
    }
  }

  Future<void> _handleBillingTap(Map<String, dynamic> billing) async {
    Map<String, dynamic>? billingDetails = billing['billingDetails'];

    if (billingDetails == null) {
      final billingId = billing['billingId']?.toString();
      if (billingId != null && billingId.isNotEmpty && billing['source'] != 'OWN_ORG') {
        setState(() => _localIsLoading = true);
        try {
          final response = await ApiService.getWalletBillingBills(
            billingId: billingId,
          );
          if (response.isNotEmpty && response['billingId'] != null) {
            billingDetails = response;
            billing['billingDetails'] = billingDetails;
          }
        } catch (e) {
          print('Error fetching billing details in list page: $e');
        } finally {
          if (mounted) setState(() => _localIsLoading = false);
        }
      }
    }

    final result = await Navigator.of(context, rootNavigator: true).push(
      MaterialPageRoute(
        builder: (context) => BillingDetailPage(
          billing: billing,
          billingData: billingDetails,
          expandAddressAbbreviations: widget.expandAddressAbbreviations,
          formatNumberWithComma: _formatNumberWithComma,
        ),
      ),
    );

    if (result == true && mounted) {
      _refresh();
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = context.isDarkMode;

    final residential = _localBillingList
        .where((b) {
          final name = (b['billingName'] ?? '').toString().toLowerCase();
          return name.contains('орон сууц') ||
              name.contains('сөх') ||
              name.contains('house') ||
              name.contains('apartment') ||
              name.contains('оснаак') ||
              b['isLocalData'] == true;
        })
        .where(
          (b) =>
              _localUserBillingData == null ||
              b['billingId'] != _localUserBillingData!['billingId'],
        )
        .toList();

    final utility = _localBillingList
        .where((b) {
          return !residential.any((r) => r['billingId'] == b['billingId']);
        })
        .where(
          (b) =>
              _localUserBillingData == null ||
              b['billingId'] != _localUserBillingData!['billingId'],
        )
        .toList();

    final hayagToo = residential.length + utility.length + (_localUserBillingData != null ? 1 : 0);

    return Scaffold(
      backgroundColor: context.backgroundColor,
      body: RefreshIndicator(
        onRefresh: _refresh,
        color: AppColors.deepGreen,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
          padding: EdgeInsets.fromLTRB(16.w, MediaQuery.of(context).padding.top + 6.h, 16.w, 32.h),
          children: [
            _buildTolgoi(isDark),
            SizedBox(height: 16.h),
            if (hayagToo > 0 && !_localIsLoading) ...[
              _buildNiitKart(isDark, hayagToo),
              SizedBox(height: 18.h),
            ],
            if (widget.billingList.isEmpty &&
                widget.userBillingData == null &&
                !_localIsLoading) ...[
              BillingConnectionSection(
                isConnecting: widget.isConnecting,
                onConnect: _addNewAddress,
              ),
              SizedBox(height: 24.h),
            ] else
              BillingListSection(
                isLoading: _localIsLoading,
                residentialBillings: residential,
                utilityBillings: utility,
                userBillingData: _localUserBillingData,
                onBillingTap: _handleBillingTap,
                expandAddressAbbreviations: widget.expandAddressAbbreviations,
                onDeleteTap: widget.onDeleteTap != null
                    ? (billing) => widget.onDeleteTap!(billing, ctx: context)
                    : null,
                onEditTap: widget.onEditTap != null
                    ? (billing) => widget.onEditTap!(billing, ctx: context, onUpdated: () {
                          if (mounted) setState(() {});
                        })
                    : null,
                totalBalance: _localTotalBalance,
                totalAldangi: _localTotalAldangi,
              ),
          ],
        ),
      ),
    );
  }

  /// Буцах · гарчиг · нэмэх
  Widget _buildTolgoi(bool isDark) {
    final khuree = isDark ? Colors.white.withOpacity(0.08) : Colors.black.withOpacity(0.06);
    return Row(
      children: [
        GestureDetector(
          onTap: () => Navigator.of(context).maybePop(),
          child: Container(
            width: 38.w,
            height: 38.w,
            decoration: BoxDecoration(
              color: context.cardBackgroundColor,
              shape: BoxShape.circle,
              border: Border.all(color: khuree),
            ),
            child: Icon(Icons.arrow_back_ios_new_rounded, size: 15.sp, color: context.textPrimaryColor),
          ),
        ),
        SizedBox(width: 12.w),
        Expanded(
          child: Text(
            'Таны орон сууцнууд',
            style: TextStyle(
              color: context.textPrimaryColor,
              fontSize: 20.sp,
              fontWeight: FontWeight.w600,
              letterSpacing: -0.6,
            ),
          ),
        ),
        GestureDetector(
          onTap: _addNewAddress,
          child: Container(
            height: 38.w,
            padding: EdgeInsets.symmetric(horizontal: 14.w),
            decoration: BoxDecoration(
              color: AppColors.deepGreen,
              borderRadius: BorderRadius.circular(100),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.add_rounded, color: Colors.white, size: 18.sp),
                SizedBox(width: 4.w),
                Text('Нэмэх', style: TextStyle(color: Colors.white, fontSize: 13.sp, fontWeight: FontWeight.w600)),
              ],
            ),
          ),
        ),
      ],
    );
  }

  /// Бүх хаягийн нийт төлөх — нэхэмжлэхийн хуудасны картын хэв маяг
  Widget _buildNiitKart(bool isDark, int hayagToo) {
    const mint = Color(0xFF7DF0C6);
    final niit = _localTotalBalance;
    final iluu = niit < -0.5;
    return ClipRRect(
      borderRadius: BorderRadius.circular(24.r),
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: isDark
                ? const [Color(0xFF123B30), Color(0xFF0A2520)]
                : const [Color(0xFF0F5A44), Color(0xFF0A3D2E)],
          ),
        ),
        child: Stack(
          children: [
            Positioned(
              top: -60.w,
              right: -40.w,
              child: Container(
                width: 170.w,
                height: 170.w,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(colors: [mint.withOpacity(0.25), mint.withOpacity(0)]),
                ),
              ),
            ),
            Padding(
              padding: EdgeInsets.fromLTRB(20.w, 18.h, 20.w, 18.h),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    iluu ? 'Илүү төлөлт' : 'Нийт төлөх',
                    style: TextStyle(color: Colors.white.withOpacity(0.7), fontSize: 12.5.sp, fontWeight: FontWeight.w500),
                  ),
                  SizedBox(height: 4.h),
                  FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: Alignment.centerLeft,
                    child: Text(
                      '${formatNumber(niit.abs())} ₮',
                      style: TextStyle(
                        color: iluu ? mint : Colors.white,
                        fontSize: 28.sp,
                        fontWeight: FontWeight.w300,
                        letterSpacing: -1,
                      ),
                    ),
                  ),
                  SizedBox(height: 12.h),
                  Row(
                    children: [
                      Icon(Icons.home_work_outlined, size: 14.sp, color: Colors.white.withOpacity(0.75)),
                      SizedBox(width: 6.w),
                      Text(
                        '$hayagToo хаяг холбогдсон',
                        style: TextStyle(color: Colors.white.withOpacity(0.85), fontSize: 12.sp),
                      ),
                      if (_localTotalAldangi > 0.5) ...[
                        const Spacer(),
                        Text(
                          'Алданги ${formatNumber(_localTotalAldangi)}₮',
                          style: TextStyle(color: const Color(0xFFFFC46B), fontSize: 12.sp, fontWeight: FontWeight.w500),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

}
