import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:sukh_app/components/Home/billing_card.dart';
import 'package:sukh_app/constants/constants.dart';
import 'package:sukh_app/utils/theme_extensions.dart';

class BillingListSection extends StatefulWidget {
  final bool isLoading;
  final List<Map<String, dynamic>> residentialBillings;
  final List<Map<String, dynamic>> utilityBillings;
  final Map<String, dynamic>? userBillingData;
  // FIX: Removed BuildContext parameter from onBillingTap.
  // Passing a BuildContext through callbacks and storing/reusing it after
  // navigation causes stale context errors — the card becomes untappable
  // after returning from the detail page.
  final Function(Map<String, dynamic>) onBillingTap;
  final String Function(String) expandAddressAbbreviations;
  final VoidCallback? onShowEmptyMessage;
  final Function(Map<String, dynamic>)? onDeleteTap;
  final Function(Map<String, dynamic>)? onEditTap;

  final double? totalBalance;
  final double? totalAldangi;

  const BillingListSection({
    super.key,
    required this.isLoading,
    required this.residentialBillings,
    required this.utilityBillings,
    this.userBillingData,
    required this.onBillingTap,
    required this.expandAddressAbbreviations,
    this.onShowEmptyMessage,
    this.onDeleteTap,
    this.onEditTap,
    this.totalBalance,
    this.totalAldangi,
  });

  @override
  State<BillingListSection> createState() => BillingListSectionState();
}

class BillingListSectionState extends State<BillingListSection> {
  bool _hasUserClicked = false;

  void showEmptyMessage() {
    if (mounted &&
        widget.residentialBillings.isEmpty &&
        widget.utilityBillings.isEmpty &&
        widget.userBillingData == null) {
      setState(() {
        _hasUserClicked = true;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = context.isDarkMode;
    final hasResidential =
        widget.residentialBillings.isNotEmpty || widget.userBillingData != null;
    final hasUtility = widget.utilityBillings.isNotEmpty;
    final hasAnyData = hasResidential || hasUtility;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (widget.isLoading)
          _buildLoadingState(isDark)
        else if (!hasAnyData)
          _hasUserClicked ? _buildEmptyMessage(isDark) : const SizedBox.shrink()
        else ...[
          if (hasResidential) ...[
            if (widget.userBillingData != null)
              _buildBillingCard(widget.userBillingData!),
            ...widget.residentialBillings.map((b) => _buildBillingCard(b)),
            SizedBox(height: 16.h),
          ],
          if (hasUtility) ...[
            _buildSectionHeader(context, title: 'Хэрэглээний төлбөр'),
            ...widget.utilityBillings.map((b) => _buildBillingCard(b)),
            SizedBox(height: 16.h),
          ],
        ],
      ],
    );
  }

  Widget _buildSectionHeader(BuildContext context, {required String title}) {
    return Padding(
      padding: EdgeInsets.only(left: 4.w, right: 4.w, top: 16.h, bottom: 8.h),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 15.sp,
          color: context.textPrimaryColor,
          letterSpacing: -0.3,
        ),
      ),
    );
  }

  Widget _buildBillingCard(Map<String, dynamic> billing) {
    return BillingCard(
      billing: billing,
      // FIX: No longer passing context here. The callback in NuurKhuudas
      // uses its own mounted context directly instead of a stale one.
      onTap: () => widget.onBillingTap(billing),
      expandAddressAbbreviations: widget.expandAddressAbbreviations,
      onDeleteTap: widget.onDeleteTap != null
          ? () => widget.onDeleteTap!(billing)
          : null,
      onEditTap: widget.onEditTap != null
          ? () => widget.onEditTap!(billing)
          : null,
      totalBalance: widget.totalBalance ?? 0.0,
      totalAldangi: widget.totalAldangi ?? 0.0,
    );
  }

  Widget _buildLoadingState(bool isDark) {
    return Container(
      padding: EdgeInsets.all(24.w),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1A1F26) : Colors.white,
        borderRadius: BorderRadius.circular(16.r),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: const Center(
        child: CircularProgressIndicator(
          color: AppColors.deepGreen,
          strokeWidth: 2,
        ),
      ),
    );
  }

  Widget _buildEmptyMessage(bool isDark) {
    return Container(
      height: 60.h,
      padding: EdgeInsets.symmetric(horizontal: 16.w),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1A1F26) : Colors.white,
        borderRadius: BorderRadius.circular(24.r),
        border: Border.all(
          color: isDark
              ? Colors.white.withOpacity(0.08)
              : AppColors.deepGreen.withOpacity(0.06),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: isDark
                ? Colors.black.withOpacity(0.3)
                : Colors.black.withOpacity(0.04),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.all(8.w),
            decoration: BoxDecoration(
              color: AppColors.deepGreen.withOpacity(0.08),
              borderRadius: BorderRadius.circular(12.r),
            ),
            child: Icon(
              Icons.help_outline_rounded,
              color: AppColors.deepGreen.withOpacity(0.6),
              size: 20.sp,
            ),
          ),
          SizedBox(width: 12.w),
          Expanded(
            child: Text(
              'Холбогдсон төлбөр одоогоор байхгүй байна',
              style: TextStyle(
                color: context.textSecondaryColor,
                fontSize: 13.sp,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
