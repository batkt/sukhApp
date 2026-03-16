import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:sukh_app/constants/constants.dart';
import 'package:sukh_app/utils/theme_extensions.dart';

class BillingCard extends StatefulWidget {
  final Map<String, dynamic> billing;
  final VoidCallback onTap;
  final String Function(String) expandAddressAbbreviations;
  final VoidCallback? onDeleteTap;

  final double totalBalance;

  const BillingCard({
    super.key,
    required this.billing,
    required this.onTap,
    required this.expandAddressAbbreviations,
    this.onDeleteTap,
    required this.totalBalance,
  });

  @override
  State<BillingCard> createState() => _BillingCardState();
}

class _BillingCardState extends State<BillingCard> with SingleTickerProviderStateMixin {
  late AnimationController _blinkController;
  late Animation<double> _blinkAnimation;

  @override
  void initState() {
    super.initState();
    _blinkController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);
    
    _blinkAnimation = Tween<double>(begin: 0.2, end: 1.0).animate(
      CurvedAnimation(parent: _blinkController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _blinkController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = context.isDarkMode;
    
    // Get customer name
    String customerName = '';
    if (widget.billing['ovog'] != null && widget.billing['ovog'].toString().isNotEmpty) {
      customerName = widget.billing['ovog'].toString();
      if (widget.billing['ner'] != null && widget.billing['ner'].toString().isNotEmpty) {
        customerName += ' ${widget.billing['ner'].toString()}';
      }
    } else if (widget.billing['ner'] != null && widget.billing['ner'].toString().isNotEmpty) {
      customerName = widget.billing['ner'].toString();
    } else if (widget.billing['customerName'] != null &&
        widget.billing['customerName'].toString().isNotEmpty) {
      customerName = widget.billing['customerName'].toString();
    }

    final billingName =
        widget.billing['billingName']?.toString() ??
        (customerName.isNotEmpty ? customerName : 'Биллинг');
    final customerCode =
        widget.billing['customerCode']?.toString() ??
        widget.billing['walletCustomerCode']?.toString() ??
        '';
    final bairniiNer =
        widget.billing['bairniiNer']?.toString() ??
        widget.billing['customerAddress']?.toString() ??
        '';
    final doorNo = widget.billing['walletDoorNo']?.toString() ?? '';

    // New fields from updated API
    final hasPayableBills = widget.billing['hasPayableBills'] == true;
    final payableBillCount =
        (widget.billing['payableBillCount'] as num?)?.toInt() ?? 0;
    final hasNewBills = widget.billing['hasNewBills'] == true;
    final newBillsCount = (widget.billing['newBillsCount'] as num?)?.toInt() ?? 0;
    
    // Check if e-bill is connected (has billingId from Wallet API)
    final isEBillConnected = widget.billing['billingId'] != null || 
        widget.billing['walletBillingId'] != null ||
        (widget.billing['isLocalData'] != true && widget.billing['customerId'] != null);

    final String billingId = widget.billing['billingId']?.toString() ??
        widget.billing['walletBillingId']?.toString() ??
        widget.billing['customerId']?.toString() ??
        'billing_${widget.billing.hashCode}';

    return Dismissible(
      key: Key(billingId),
      direction: widget.onDeleteTap != null ? DismissDirection.endToStart : DismissDirection.none,
      confirmDismiss: (direction) async {
        if (widget.onDeleteTap != null) {
          widget.onDeleteTap!();
        }
        return false; // Let Home.dart handle the actual removal if confirmed
      },
      background: Container(
        margin: EdgeInsets.only(bottom: 12.h),
        decoration: BoxDecoration(
          color: Colors.redAccent,
          borderRadius: BorderRadius.circular(16.r),
        ),
        alignment: Alignment.centerRight,
        padding: EdgeInsets.symmetric(horizontal: 24.w),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.delete_outline, color: Colors.white, size: 28.sp),
            SizedBox(height: 2.h),
            Text(
              'Устгах',
              style: TextStyle(
                color: Colors.white,
                fontSize: 10.sp,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
      child: GestureDetector(
        onTap: widget.onTap,
        child: Container(
          margin: EdgeInsets.only(bottom: 12.h),
          padding: EdgeInsets.all(16.w),
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
                    ? Colors.black.withOpacity(0.4)
                    : Colors.black.withOpacity(0.04),
                blurRadius: 20,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Row(
            children: [
              // Icon Container with soft gradient
              Container(
                width: 48.w,
                height: 48.w,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      AppColors.deepGreen,
                      AppColors.deepGreen.withOpacity(0.8),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(16.r),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.deepGreen.withOpacity(0.2),
                      blurRadius: 8,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Icon(
                  Icons.home_work_rounded,
                  color: Colors.white,
                  size: 24.sp,
                ),
              ),
              SizedBox(width: 16.w),

              // Content Area
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [

                    // Address or Code Row
                    Row(
                      children: [
                        Icon(
                          Icons.location_on_rounded,
                          color: AppColors.deepGreen,
                          size: 16.sp,
                        ),
                        SizedBox(width: 6.w),
                        Expanded(
                          child: Text(
                            bairniiNer.isNotEmpty 
                                ? '${widget.expandAddressAbbreviations(bairniiNer)}${doorNo.isNotEmpty ? ", $doorNo" : ""}'
                                : (customerCode.isNotEmpty ? customerCode : 'Хаяг тодорхойгүй'),
                            style: TextStyle(
                              color: context.textPrimaryColor,
                              fontSize: 14.sp,
                              fontWeight: FontWeight.w800,
                              letterSpacing: -0.2,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),

                    // Status Badges
                      if (widget.totalBalance > 0 || (hasNewBills && newBillsCount > 0)) ...[
                        SizedBox(height: 10.h),
                        Wrap(
                          spacing: 6.w,
                          runSpacing: 4.h,
                          children: [
                            if (widget.totalBalance > 0)
                              _buildStatusPill(
                                icon: Icons.account_balance_wallet_rounded,
                                label: 'Төлөх дүн: ${_formatNumber(widget.totalBalance)}₮',
                                color: Colors.white,
                              ),
                            if (hasNewBills && newBillsCount > 0)
                              _buildStatusPill(
                                icon: Icons.auto_awesome_rounded,
                                label: '$newBillsCount шинэ',
                                color: Colors.blue[600]!,
                              ),
                          ],
                        ),
                      ],
                  ],
                ),
              ),

              // Interaction Indicator
              FadeTransition(
                opacity: (widget.onDeleteTap != null)
                    ? _blinkAnimation
                    : const AlwaysStoppedAnimation(1.0),
                child: Container(
                  padding: EdgeInsets.all(4.w),
                  decoration: BoxDecoration(
                    color: context.textSecondaryColor.withOpacity(0.05),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.chevron_right_rounded,
                    color: context.textSecondaryColor.withOpacity(0.4),
                    size: 22.sp,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatusPill({
    required IconData icon,
    required String label,
    required Color color,
  }) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 5.h),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(20.r),
        border: Border.all(
          color: color.withOpacity(0.1),
          width: 0.5,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 11.sp),
          SizedBox(width: 5.w),
          Text(
            label,
            style: TextStyle(
              color: color,
              fontSize: 10.sp,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }

  String _formatNumber(double number) {
    // Basic formatting with comma as thousands separator
    String str = number.toStringAsFixed(0);
    final RegExp reg = RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))');
    return str.replaceAllMapped(reg, (Match match) => '${match[1]},');
  }
}

