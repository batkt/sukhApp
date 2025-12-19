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
import 'package:sukh_app/models/medegdel_model.dart';
import 'package:sukh_app/widgets/glass_snackbar.dart';
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
    with SingleTickerProviderStateMixin {
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

  // All billing payments for total balance modal

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

    _loadBillers();
    _loadBillingList();
    _loadNotificationCount();
    _setupSocketListener();
    _loadGereeData();
    _loadNekhemjlekhCron(); // Load nekhemjlekh cron data for date calculation
    _loadAllBillingPayments(); // Load total balance on init

    // Trigger animation after a short delay to ensure data is loaded
    Future.delayed(const Duration(milliseconds: 300), () {
      if (mounted && _gereeResponse != null) {
        _progressAnimationController.forward();
      }
    });
  }

  bool _hasLoadedBalance = false;

  void _setupSocketListener() {
    // Set up socket notification callback
    SocketService.instance.setNotificationCallback((notification) {
      print('🔔 HOME: Notification callback triggered');
      print('🔔 HOME: Notification data: $notification');

      if (mounted) {
        // Refresh from API to get accurate count
        // Don't increment locally to avoid double counting
        print('🔔 HOME: Widget is mounted, calling _loadNotificationCount()');
        _loadNotificationCount();
      } else {
        print(
          '⚠️ HOME: Widget not mounted, skipping notification count update',
        );
      }
    });
    print('🔔 HOME: Socket listener callback registered');
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Re-establish socket listener when screen comes back into focus
    // This ensures the callback is active even after modal closes
    _setupSocketListener();
    // Also refresh notification count when page becomes visible
    _loadNotificationCount();
    // Reload total balance when page becomes visible (only once per mount)
    if (!_hasLoadedBalance) {
      _hasLoadedBalance = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          _loadAllBillingPayments();
        }
      });
    }
  }

  @override
  void dispose() {
    _billerPageController.dispose();
    _progressAnimationController.dispose();
    // Don't remove callback on dispose - let it stay active
    // The socket service will handle cleanup on logout
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
      debugPrint(
        '📅 [HOME] Loading nekhemjlekhCron for barilgiinId: $barilgiinId',
      );

      if (barilgiinId != null) {
        final response = await ApiService.fetchNekhemjlekhCron(
          barilgiinId: barilgiinId,
        );

        debugPrint('📅 [HOME] API response: ${response.toString()}');

        if (mounted) {
          setState(() {
            // Handle both shapes:
            // 1) { success, data: { ... } }
            // 2) { success, data: [ { ... }, ... ] }
            final rawData = response['data'];
            debugPrint('📅 [HOME] rawData type: ${rawData.runtimeType}');

            if (rawData is Map<String, dynamic>) {
              // Check if this single record matches our barilgiinId
              final recordBarilgiinId = rawData['barilgiinId']?.toString();
              debugPrint(
                '📅 [HOME] Single record - recordBarilgiinId: $recordBarilgiinId, expected: $barilgiinId',
              );

              if (recordBarilgiinId == barilgiinId) {
                _nekhemjlekhCronData = rawData;
                debugPrint(
                  '✅ [HOME] Matched! Loaded nekhemjlekhCron: barilgiinId=${_nekhemjlekhCronData!['barilgiinId']}, nekhemjlekhUusgekhOgnoo=${_nekhemjlekhCronData!['nekhemjlekhUusgekhOgnoo']}',
                );
              } else {
                _nekhemjlekhCronData = null;
                debugPrint(
                  '❌ [HOME] Single record barilgiinId mismatch: expected $barilgiinId, got $recordBarilgiinId',
                );
              }
            } else if (rawData is List && rawData.isNotEmpty) {
              debugPrint('📅 [HOME] List with ${rawData.length} items');
              // Filter list to find record matching barilgiinId
              final matchingRecords = rawData
                  .where(
                    (item) =>
                        item is Map<String, dynamic> &&
                        item['barilgiinId']?.toString() == barilgiinId,
                  )
                  .toList();

              debugPrint(
                '📅 [HOME] Found ${matchingRecords.length} matching records',
              );

              if (matchingRecords.isNotEmpty) {
                _nekhemjlekhCronData =
                    matchingRecords.first as Map<String, dynamic>;
                debugPrint(
                  '✅ [HOME] Matched! Loaded nekhemjlekhCron: barilgiinId=${_nekhemjlekhCronData!['barilgiinId']}, nekhemjlekhUusgekhOgnoo=${_nekhemjlekhCronData!['nekhemjlekhUusgekhOgnoo']}',
                );
              } else {
                _nekhemjlekhCronData = null;
                debugPrint(
                  '❌ [HOME] No matching record found for barilgiinId: $barilgiinId',
                );
                // Log all barilgiinIds in the list for debugging
                for (var i = 0; i < rawData.length; i++) {
                  final item = rawData[i];
                  if (item is Map<String, dynamic>) {
                    debugPrint(
                      '📅 [HOME] List item $i barilgiinId: ${item['barilgiinId']}',
                    );
                  }
                }
              }
            } else {
              _nekhemjlekhCronData = null;
              debugPrint('❌ [HOME] rawData is null or empty');
            }

            if (_nekhemjlekhCronData != null) {
              debugPrint(
                '✅ [HOME] Final nekhemjlekhCron data: barilgiinId=${_nekhemjlekhCronData!['barilgiinId']}, nekhemjlekhUusgekhOgnoo=${_nekhemjlekhCronData!['nekhemjlekhUusgekhOgnoo']}',
              );
            } else {
              debugPrint(
                '❌ [HOME] nekhemjlekhCron data is null/empty after processing',
              );
            }
          });
        }
      } else {
        debugPrint('❌ [HOME] barilgiinId is null, cannot load nekhemjlekhCron');
      }
    } catch (e) {
      debugPrint('❌ [HOME] Error loading nekhemjlekh cron: $e');
      print('Error loading nekhemjlekh cron: $e');
      // Silent fail - date calculation will fallback to contract date
    }
  }

  Future<void> _loadBillers() async {
    setState(() {
      _isLoadingBillers = true;
    });

    try {
      final billers = await ApiService.getWalletBillers();

      // Filter out excluded billers
      final filteredBillers = billers.where((biller) {
        final billerName =
            (biller['billerName']?.toString() ??
                    biller['name']?.toString() ??
                    '')
                .toLowerCase();

        // Exclude Төрйин банк, Юнивишн, Скаймедиа
        return !billerName.contains('төрйин банк') &&
            !billerName.contains('төрийн банк') &&
            !billerName.contains('toriin bank') &&
            !billerName.contains('toryin bank') &&
            !billerName.contains('юнивишн') &&
            !billerName.contains('юнивижн') &&
            !billerName.contains('univision') &&
            !billerName.contains('univishn') &&
            !billerName.contains('скаймедиа') &&
            !billerName.contains('скай медиа') &&
            !billerName.contains('скай-медиа') &&
            !billerName.contains('skymedia') &&
            !billerName.contains('sky media') &&
            !billerName.contains('sky-media');
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
          _hasLoadedBalance = true;
        });
      }
    } catch (e) {
      // Silent fail - total will remain at current value
    }
  }

  String _formatNumberWithComma(double number) {
    final parts = number.toStringAsFixed(0).split('.');
    final integerPart = parts[0];
    final regex = RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))');
    return integerPart.replaceAllMapped(regex, (match) => '${match[1]},');
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

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 16.w),
      child: Column(
        children: [
          // Simple but unique circular dashboard
          Container(
            width: context.isVeryNarrow ? 180.w : 220.w,
            height: context.isVeryNarrow ? 180.w : 220.w,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: isDark ? Colors.black : Colors.white,
              boxShadow: [
                BoxShadow(
                  color: accentColor.withOpacity(0.2),
                  blurRadius: 20,
                  spreadRadius: 2,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Stack(
              alignment: Alignment.center,
              children: [
                // Circular progress ring with animation
                SizedBox(
                  width: context.isVeryNarrow ? 180.w : 220.w,
                  height: context.isVeryNarrow ? 180.w : 220.w,
                  child: AnimatedBuilder(
                    animation: _progressAnimation,
                    builder: (context, child) {
                      final animatedProgress =
                          targetProgress * _progressAnimation.value;
                      return CustomPaint(
                        painter: _CircularProgressPainter(
                          progress: animatedProgress,
                          color: accentColor,
                          backgroundColor: accentColor.withOpacity(0.1),
                          strokeWidth: 8,
                        ),
                      );
                    },
                  ),
                ),
                // Center content with animation
                AnimatedBuilder(
                  animation: _progressAnimation,
                  builder: (context, child) {
                    return Opacity(
                      opacity: _progressAnimation.value,
                      child: Transform.scale(
                        scale: 0.8 + (0.2 * _progressAnimation.value),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              '$displayDays',
                              style: TextStyle(
                                fontSize: context.isVeryNarrow ? 56.sp : 72.sp,
                                fontWeight: FontWeight.w800,
                                color: accentColor,
                                height: 1.0,
                                letterSpacing: -1,
                              ),
                            ),
                            SizedBox(height: 6.h),
                            Text(
                              centerLabel,
                              style: context
                                  .descriptionStyle(
                                    color: accentColor.withOpacity(0.8),
                                    fontWeight: FontWeight.w600,
                                  )
                                  .copyWith(letterSpacing: 0.3),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
          SizedBox(height: 20.h),
          // Modern calendar card
          Container(
            padding: EdgeInsets.all(context.isVeryNarrow ? 16.w : 22.w),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: isDark
                    ? [
                        Colors.white.withOpacity(0.08),
                        Colors.white.withOpacity(0.03),
                      ]
                    : [
                        Colors.white.withOpacity(0.9),
                        Colors.white.withOpacity(0.7),
                      ],
              ),
              borderRadius: BorderRadius.circular(20.r),
              border: Border.all(
                color: isDark
                    ? Colors.white.withOpacity(0.1)
                    : accentColor.withOpacity(0.2),
                width: 1.5,
              ),
              boxShadow: [
                BoxShadow(
                  color: isDark
                      ? Colors.black.withOpacity(0.3)
                      : accentColor.withOpacity(0.1),
                  blurRadius: 15,
                  offset: const Offset(0, 5),
                ),
              ],
            ),
            child: Row(
              children: [
                Container(
                  padding: EdgeInsets.all(context.isVeryNarrow ? 8.w : 12.w),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        accentColor.withOpacity(0.2),
                        accentColor.withOpacity(0.1),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(14.r),
                  ),
                  child: Icon(
                    Icons.calendar_today_rounded,
                    color: accentColor,
                    size: context.isVeryNarrow ? 20.sp : 24.sp,
                  ),
                ),
                SizedBox(width: 16.w),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Дараагийн төлөлт',
                        style: context
                            .secondaryDescriptionStyle(
                              color: context.textSecondaryColor,
                              fontWeight: FontWeight.w500,
                            )
                            .copyWith(letterSpacing: 0.3),
                      ),
                      SizedBox(height: 8.h),
                      Text(
                        nextUnitDateText,
                        style: context
                            .titleStyle(
                              color: accentColor,
                              fontWeight: FontWeight.w700,
                            )
                            .copyWith(letterSpacing: -0.5),
                      ),
                    ],
                  ),
                ),
              ],
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
    return Scaffold(
      key: _scaffoldKey,
      drawer: const SideMenu(),
      appBar: AppBar(
        backgroundColor: AppColors.getDeepGreen(context.isDarkMode),
        toolbarHeight: context.responsiveSpacing(
          small: 70,
          medium: 75,
          large: 80,
          tablet: 85,
          veryNarrow: 60,
        ),
        leading: IconButton(
          icon: Icon(
            Icons.menu,
            color: Colors.white,
            size: context.responsiveIconSize(
              small: 28,
              medium: 30,
              large: 32,
              tablet: 34,
              veryNarrow: 24,
            ),
          ),
          onPressed: () => _scaffoldKey.currentState?.openDrawer(),
        ),
        title: GestureDetector(
          onTap: _showTotalBalanceModal,
          child: Container(
            padding: EdgeInsets.symmetric(
              horizontal: context.responsiveSpacing(
                small: 16,
                medium: 18,
                large: 20,
                tablet: 22,
                veryNarrow: 10,
              ),
              vertical: context.responsiveSpacing(
                small: 10,
                medium: 12,
                large: 14,
                tablet: 16,
                veryNarrow: 8,
              ),
            ),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(
                context.responsiveBorderRadius(
                  small: 11,
                  medium: 12,
                  large: 13,
                  tablet: 14,
                  veryNarrow: 9,
                ),
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.account_balance_wallet_rounded,
                  color: Colors.white,
                  size: context.responsiveIconSize(
                    small: 26,
                    medium: 28,
                    large: 30,
                    tablet: 32,
                    veryNarrow: 20,
                  ),
                ),
                SizedBox(
                  width: context.responsiveSpacing(
                    small: 10,
                    medium: 12,
                    large: 14,
                    tablet: 16,
                    veryNarrow: 6,
                  ),
                ),
                Flexible(
                  child: Text(
                    'Нийт үлдэгдэл ${_formatNumberWithComma(totalNiitTulbur)}₮',
                    style: context
                        .titleStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                        )
                        .copyWith(
                          fontSize: context.responsiveFontSize(
                            small: 14,
                            medium: 15,
                            large: 16,
                            tablet: 17,
                            veryNarrow: 12,
                          ),
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
            children: [
              IconButton(
                icon: Icon(
                  Icons.notifications_outlined,
                  color: Colors.white,
                  size: context.responsiveIconSize(
                    small: 28,
                    medium: 30,
                    large: 32,
                    tablet: 34,
                    veryNarrow: 24,
                  ),
                ),
                onPressed: () {
                  context.push('/medegdel-list').then((_) {
                    _loadNotificationCount();
                  });
                },
              ),
              if (_unreadNotificationCount > 0)
                Positioned(
                  right: context.responsiveSpacing(
                    small: 8,
                    medium: 10,
                    large: 12,
                    tablet: 14,
                    veryNarrow: 6,
                  ),
                  top: context.responsiveSpacing(
                    small: 8,
                    medium: 10,
                    large: 12,
                    tablet: 14,
                    veryNarrow: 6,
                  ),
                  child: Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: context.responsiveSpacing(
                        small: 6,
                        medium: 7,
                        large: 8,
                        tablet: 9,
                        veryNarrow: 4,
                      ),
                      vertical: context.responsiveSpacing(
                        small: 2,
                        medium: 3,
                        large: 4,
                        tablet: 5,
                        veryNarrow: 1,
                      ),
                    ),
                    decoration: BoxDecoration(
                      color: Colors.red,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: AppColors.deepGreen,
                        width: context.responsiveSpacing(
                          small: 1.5,
                          medium: 2,
                          large: 2,
                          tablet: 2.5,
                          veryNarrow: 1.5,
                        ),
                      ),
                    ),
                    constraints: BoxConstraints(
                      minWidth: context.responsiveSpacing(
                        small: 18,
                        medium: 20,
                        large: 22,
                        tablet: 24,
                        veryNarrow: 14,
                      ),
                      minHeight: context.responsiveSpacing(
                        small: 18,
                        medium: 20,
                        large: 22,
                        tablet: 24,
                        veryNarrow: 14,
                      ),
                    ),
                    child: Center(
                      child: Text(
                        _unreadNotificationCount > 99
                            ? '99+'
                            : '$_unreadNotificationCount',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: context.responsiveFontSize(
                            small: 10,
                            medium: 11,
                            large: 12,
                            tablet: 13,
                            veryNarrow: 9,
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
      body: AppBackground(
        child: SafeArea(
          child: RefreshIndicator(
            onRefresh: () async {
              // Refresh all data
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
              child: Column(
                children: [
                  SizedBox(
                    height: context.responsiveSpacing(
                      small: 20,
                      medium: 24,
                      large: 28,
                      tablet: 32,
                      veryNarrow: 16,
                    ),
                  ),

                  // Billing Connection Section
                  if (_billingList.isEmpty && !_isLoadingBillingList)
                    BillingConnectionSection(
                      isConnecting: _isConnectingBilling,
                      onConnect: _connectBillingByAddress,
                    ),

                  if (_billingList.isEmpty && !_isLoadingBillingList)
                    SizedBox(
                      height: context.responsiveSpacing(
                        small: 11,
                        medium: 13,
                        large: 15,
                        tablet: 17,
                        veryNarrow: 8,
                      ),
                    ),

                  // Billing List Section
                  BillingListSection(
                    key: _billingListSectionKey,
                    isLoading: _isLoadingBillingList,
                    billingList: _billingList,
                    userBillingData: _userBillingData,
                    onBillingTap: _showBillingDetailModal,
                    expandAddressAbbreviations: _expandAddressAbbreviations,
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

                  // Billers Grid
                  if (_isLoadingBillers)
                    SizedBox(
                      height: context.responsiveSpacing(
                        small: 300,
                        medium: 350,
                        large: 400,
                        tablet: 450,
                        veryNarrow: 250,
                      ),
                      child: const Center(
                        child: CircularProgressIndicator(
                          color: AppColors.deepGreen,
                        ),
                      ),
                    )
                  else if (_billers.isEmpty)
                    SizedBox(
                      height: context.responsiveSpacing(
                        small: 300,
                        medium: 350,
                        large: 400,
                        tablet: 450,
                        veryNarrow: 250,
                      ),
                      child: Center(
                        child: Text(
                          'Биллер олдсонгүй',
                          style: TextStyle(
                            color: context.textSecondaryColor,
                            fontSize: context.responsiveFontSize(
                              small: 20,
                              medium: 22,
                              large: 24,
                              tablet: 26,
                            ),
                          ),
                        ),
                      ),
                    )
                  else
                    BillersGrid(
                      billers: _billers,
                      onDevelopmentTap: () => _showDevelopmentModal(context),
                      onBillerTap: () {
                        // Show empty message if billing list is empty
                        if (_billingList.isEmpty && _userBillingData == null) {
                          _billingListSectionKey.currentState
                              ?.showEmptyMessage();
                        }
                      },
                    ),

                  SizedBox(
                    height: context.responsiveSpacing(
                      small: 20,
                      medium: 24,
                      large: 28,
                      tablet: 32,
                      veryNarrow: 16,
                    ),
                  ),

                  // Remaining Days Display
                  if (_gereeResponse != null &&
                      _gereeResponse!.jagsaalt.isNotEmpty)
                    _buildRemainingDaysWidget(_gereeResponse!.jagsaalt.first),

                  SizedBox(
                    height: context.responsiveSpacing(
                      small: 11,
                      medium: 13,
                      large: 15,
                      tablet: 17,
                      veryNarrow: 8,
                    ),
                  ),
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

  void _showTotalBalanceModal() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => TotalBalanceModal(
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
                colors: [context.surfaceColor, context.surfaceElevatedColor],
              ),
              border: Border.all(color: AppColors.deepGreen, width: 2),
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
                  style: context.secondaryDescriptionStyle(
                    color: context.textPrimaryColor,
                    fontWeight: FontWeight.bold,
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
                Text(
                  'Энэ хуудас хөгжүүлэлт хийгдэж байгаа тул одоогоор ашиглах боломжгүй байна. Удахгүй ашиглах боломжтой болно.',
                  textAlign: TextAlign.center,
                  style: context.secondaryDescriptionStyle(
                    color: context.textSecondaryColor,
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
                      style: context.secondaryDescriptionStyle(
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
