import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:sukh_app/components/Home/billing_list_section.dart';
import 'package:sukh_app/components/Home/billing_connection_section.dart';
import 'package:sukh_app/widgets/standard_app_bar.dart';
import 'package:sukh_app/utils/theme_extensions.dart';
import 'package:sukh_app/constants/constants.dart';
import 'package:sukh_app/widgets/glass_snackbar.dart';
import 'package:sukh_app/services/api_service.dart';
import 'package:intl/intl.dart';
import 'package:sukh_app/screens/Home/billing_detail_page.dart';

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

  @override
  void initState() {
    super.initState();
    final hasData =
        widget.billingList.isNotEmpty || widget.userBillingData != null;
    _localIsLoading = widget.isLoading && !hasData;
  }

  @override
  void didUpdateWidget(BillingListPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    final dataChanged =
        oldWidget.billingList.length != widget.billingList.length ||
        oldWidget.userBillingData != widget.userBillingData;
    final loadingChanged = oldWidget.isLoading != widget.isLoading;

    if (dataChanged || loadingChanged) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          final hasData =
              widget.billingList.isNotEmpty || widget.userBillingData != null;
          setState(() {
            _localIsLoading = widget.isLoading && !hasData;
          });
        }
      });
    }
  }

  Future<void> _refresh() async {
    setState(() => _localIsLoading = true);
    await widget.onRefresh();
    if (mounted) setState(() => _localIsLoading = false);
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
    if (value == null) return '0.00';
    try {
      final number = double.parse(value.toString());
      final formatter = NumberFormat('#,##0.00', 'en_US');
      return formatter.format(number);
    } catch (e) {
      return '0.00';
    }
  }

  Future<void> _handleBillingTap(Map<String, dynamic> billing) async {
    if (billing['isLocalData'] == true) {
      Map<String, dynamic>? billingDetails = billing['billingDetails'];

      if (billingDetails == null) {
        final billingId = billing['billingId']?.toString();
        if (billingId != null && billingId.isNotEmpty) {
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
      return;
    }

    // Non-wallet usage
    final result = await Navigator.of(context, rootNavigator: true).push(
      MaterialPageRoute(
        builder: (context) => BillingDetailPage(
          billing: billing,
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

    final residential = widget.billingList
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
              widget.userBillingData == null ||
              b['billingId'] != widget.userBillingData!['billingId'],
        )
        .toList();

    final utility = widget.billingList
        .where((b) {
          return !residential.any((r) => r['billingId'] == b['billingId']);
        })
        .where(
          (b) =>
              widget.userBillingData == null ||
              b['billingId'] != widget.userBillingData!['billingId'],
        )
        .toList();

    return Scaffold(
      backgroundColor: isDark
          ? const Color(0xFF0A0E14)
          : const Color(0xFFF5F7FA),
      appBar: buildStandardAppBar(
        context,
        title: 'Таны орон сууцнууд',
        backButtonColor: isDark ? null : Colors.white,
        backButtonIconColor: isDark ? null : AppColors.deepGreen,
        titleColor: isDark ? null : Colors.white,
        actions: [
          GestureDetector(
            onTap: _addNewAddress,
            child: Container(
              width: 34.w,
              height: 34.w,
              decoration: BoxDecoration(
                color: isDark ? AppColors.deepGreen : Colors.white,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: (isDark ? Colors.black : AppColors.deepGreen)
                        .withOpacity(0.15),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Center(
                child: Icon(
                  Icons.add_rounded,
                  color: isDark ? Colors.white : AppColors.deepGreen,
                  size: 22.sp,
                ),
              ),
            ),
          ),
          SizedBox(width: 4.w),
        ],
      ),
      extendBodyBehindAppBar: true,
      body: Stack(
        children: [
          _buildGreenHeader(context, isDark),
          RefreshIndicator(
            onRefresh: _refresh,
            color: AppColors.deepGreen,
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              padding: EdgeInsets.fromLTRB(
                16.w,
                140.h + MediaQuery.of(context).padding.top,
                16.w,
                32.h,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
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
                      userBillingData: widget.userBillingData,
                      onBillingTap: _handleBillingTap,
                      expandAddressAbbreviations:
                          widget.expandAddressAbbreviations,
                      onDeleteTap: widget.onDeleteTap != null
                          ? (billing) =>
                              widget.onDeleteTap!(billing, ctx: context)
                          : null,
                      onEditTap: widget.onEditTap != null
                          ? (billing) => widget.onEditTap!(billing,
                                  ctx: context, onUpdated: () {
                                if (mounted) setState(() {});
                              })
                          : null,
                      totalBalance: widget.totalBalance,
                      totalAldangi: widget.totalAldangi,
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGreenHeader(BuildContext context, bool isDark) {
    if (isDark) return const SizedBox.shrink();

    return Container(
      height: 240.h,
      width: double.infinity,
      decoration: BoxDecoration(
        color: AppColors.deepGreen,
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(40.r),
          bottomRight: Radius.circular(40.r),
        ),
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [AppColors.deepGreen, AppColors.deepGreen.withOpacity(0.85)],
        ),
      ),
    );
  }
}
