import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:sukh_app/components/Home/billing_list_section.dart';
import 'package:sukh_app/components/Home/billing_connection_section.dart';
import 'package:sukh_app/widgets/standard_app_bar.dart';
import 'package:sukh_app/utils/theme_extensions.dart';
import 'package:sukh_app/constants/constants.dart';

class BillingListPage extends StatefulWidget {
  final List<Map<String, dynamic>> billingList;
  final Map<String, dynamic>? userBillingData;
  final bool isLoading;
  final double totalBalance;
  final double totalAldangi;
  final Function(Map<String, dynamic>) onBillingTap;
  final String Function(String) expandAddressAbbreviations;
  final Function(Map<String, dynamic>)? onDeleteTap;
  final Function(Map<String, dynamic>, [VoidCallback?])? onEditTap;
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

    if (_localIsLoading) {
      Future.delayed(const Duration(seconds: 3), () {
        if (mounted && _localIsLoading) {
          setState(() => _localIsLoading = false);
        }
      });
    }
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
              padding: EdgeInsets.fromLTRB(16.w, 100.h, 16.w, 32.h),
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
                      onBillingTap: (billing) {
                        if (billing['isLocalData'] == true) {
                          context.push('/nekhemjlekh');
                        } else {
                          widget.onBillingTap(billing);
                        }
                      },
                      expandAddressAbbreviations:
                          widget.expandAddressAbbreviations,
                      onDeleteTap: widget.onDeleteTap,
                      onEditTap: widget.onEditTap != null
                          ? (billing) => widget.onEditTap!(billing, () {
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
