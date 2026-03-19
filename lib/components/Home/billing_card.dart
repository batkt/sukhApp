import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:sukh_app/constants/constants.dart';
import 'package:sukh_app/utils/theme_extensions.dart';

class BillingCard extends StatefulWidget {
  final Map<String, dynamic> billing;
  final VoidCallback onTap;
  final String Function(String) expandAddressAbbreviations;
  final VoidCallback? onDeleteTap;
  final VoidCallback? onEditTap;

  final double totalBalance;
  final double? totalAldangi;

  const BillingCard({
    super.key,
    required this.billing,
    required this.onTap,
    required this.expandAddressAbbreviations,
    this.onDeleteTap,
    this.onEditTap,
    required this.totalBalance,
    this.totalAldangi,
  });

  @override
  State<BillingCard> createState() => _BillingCardState();
}

class _BillingCardState extends State<BillingCard> with TickerProviderStateMixin {
  late AnimationController _blinkController;
  late Animation<double> _blinkAnimation;

  late AnimationController _swipeHintController;
  late Animation<Offset> _swipeHintAnimation;

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

    _swipeHintController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 5000),
    )..repeat(reverse: false);

    _swipeHintAnimation = Tween<Offset>(begin: const Offset(0.15, 0), end: const Offset(-0.15, 0)).animate(
      CurvedAnimation(parent: _swipeHintController, curve: Curves.easeInOutSine),
    );
  }

  @override
  void dispose() {
    _blinkController.dispose();
    _swipeHintController.dispose();
    super.dispose();
  }

  IconData _getIconForBilling(String name, String? code) {
    final n = name.toLowerCase();
    final c = code?.toLowerCase() ?? '';
    
    if (n.contains('цахилгаан') || c.contains('electric')) return Icons.bolt_rounded;
    if (n.contains('убцтс')) return Icons.bolt_rounded;
    if (n.contains('юнивижн') || n.contains('univision')) return Icons.router_rounded;
    if (n.contains('скаймедиа') || n.contains('skymedia')) return Icons.tv_rounded;
    if (n.contains('мобнет') || n.contains('mobinet')) return Icons.language_rounded;
    if (n.contains('сөх') || n.contains('орон сууц')) return Icons.home_work_rounded;
    if (n.contains('ус') || n.contains('дулаан')) return Icons.water_drop_rounded;
    if (n.contains('банк') || n.contains('төрийн банк')) return Icons.account_balance_rounded;
    
    return Icons.home_work_rounded;
  }

  Color _getIconColorForBilling(String name, String? code) {
    final n = name.toLowerCase();
    final c = code?.toLowerCase() ?? '';
    
    if (n.contains('цахилгаан') || c.contains('electric') || n.contains('убцтс')) return Colors.orange;
    if (n.contains('юнивижн') || n.contains('univision')) return Colors.pink;
    if (n.contains('скаймедиа') || n.contains('skymedia')) return Colors.blue;
    if (n.contains('ус') || n.contains('дулаан')) return Colors.blueAccent;
    if (n.contains('банк')) return Colors.teal;
    
    return AppColors.deepGreen;
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
    final billerCode = widget.billing['billerCode']?.toString();
    final billerName = widget.billing['billerName']?.toString();
    final nickname = widget.billing['nickname']?.toString();

    // New fields from updated API
    final hasNewBillsRaw = widget.billing['hasNewBills'] == true;
    final newBillsList = widget.billing['newBills'] is List ? widget.billing['newBills'] as List : [];
    
    final hasNewBills = hasNewBillsRaw || newBillsList.isNotEmpty;
    final newBillsCount = (widget.billing['newBillsCount'] as num?)?.toInt() ?? newBillsList.length;
    
    final hasPayableBills = widget.billing['hasPayableBills'] == true;
    final payableBillCount = (widget.billing['payableBillCount'] as num?)?.toInt() ?? 0;
    
    // Check if e-bill is connected (has billingId from Wallet API)
    final isEBillConnected = widget.billing['billingId'] != null || 
        widget.billing['walletBillingId'] != null ||
        (widget.billing['isLocalData'] != true && widget.billing['customerId'] != null);

    final String billingId = widget.billing['billingId']?.toString() ??
        widget.billing['walletBillingId']?.toString() ??
        widget.billing['customerId']?.toString() ??
        'billing_${widget.billing.hashCode}';

    final iconData = _getIconForBilling(billingName, billerCode);
    final iconColor = _getIconColorForBilling(billingName, billerCode);

    double cardBalance = _parseNum(widget.billing['perItemTotal']);
    double cardAldangi = _parseNum(widget.billing['perItemAldangi']);

    // Fallback for transition period or legacy data
    if (cardBalance == 0 && widget.totalBalance > 0 && 
        (widget.billing['isLocalData'] == true || billingName.contains('Орон сууцны'))) {
      cardBalance = widget.totalBalance;
      cardAldangi = widget.totalAldangi ?? 0.0;
    }

    final shouldShowBalance = cardBalance != 0 || isEBillConnected || widget.billing['isLocalData'] == true;
    final hasActions = widget.onEditTap != null || widget.onDeleteTap != null;

    // Display name: nickname takes priority
    final displayName = (nickname != null && nickname.isNotEmpty) ? nickname : billingName;
    final showSubtitle = (nickname != null && nickname.isNotEmpty);

    return Padding(
      padding: EdgeInsets.only(bottom: 10.h),
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // ── Main Card ──
            Expanded(
              child: GestureDetector(
                onTap: widget.onTap,
                child: Container(
                  constraints: BoxConstraints(minHeight: 56.h),
                  padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 12.h),
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF1C2229) : Colors.white,
                    borderRadius: BorderRadius.circular(16.r),
                    border: Border.all(
                      color: isDark
                          ? Colors.white.withOpacity(0.06)
                          : const Color(0xFFE8ECF0),
                      width: 1,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: isDark
                            ? Colors.black.withOpacity(0.2)
                            : Colors.black.withOpacity(0.04),
                        blurRadius: 12,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      // Icon
                      Container(
                        width: 42.w,
                        height: 42.w,
                        decoration: BoxDecoration(
                          color: iconColor.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12.r),
                        ),
                        child: Icon(
                          iconData,
                          color: iconColor,
                          size: 20.sp,
                        ),
                      ),
                      SizedBox(width: 12.w),

                      // Text content
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.center,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            // Display name (nickname or billing name)
                            Text(
                              displayName,
                              style: TextStyle(
                                color: context.textPrimaryColor,
                                fontSize: 14.sp,
                                fontWeight: FontWeight.w500,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            // If nickname is set, show original billingName as subtitle
                            if (showSubtitle) ...[
                              SizedBox(height: 2.h),
                              Text(
                                billingName,
                                style: TextStyle(
                                  color: context.textSecondaryColor.withOpacity(0.6),
                                  fontSize: 11.sp,
                                  fontWeight: FontWeight.w400,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                            SizedBox(height: 2.h),
                            // Address line
                            Text(
                              bairniiNer.isNotEmpty 
                                  ? '${widget.expandAddressAbbreviations(bairniiNer)}${doorNo.isNotEmpty ? ", $doorNo" : ""}'
                                  : (customerCode.isNotEmpty ? 'Код: $customerCode' : 'Хаяг сонгоно уу'),
                              style: TextStyle(
                                color: context.textSecondaryColor,
                                fontSize: 11.sp,
                                fontWeight: FontWeight.w400,
                                height: 1.3,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            if (billerName != null && billerName.isNotEmpty) ...[
                              SizedBox(height: 2.h),
                              Text(
                                billerName,
                                style: TextStyle(
                                  color: context.textSecondaryColor.withOpacity(0.8),
                                  fontSize: 10.sp,
                                  fontWeight: FontWeight.w500,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],

                            // Balance + pills row
                            if (shouldShowBalance || (hasNewBills && newBillsCount > 0)) ...[
                              SizedBox(height: 8.h),
                              Row(
                                children: [
                                  if (shouldShowBalance)
                                    Expanded(child: _buildBalanceRow(cardBalance, cardAldangi)),
                                  if (shouldShowBalance && hasNewBills && newBillsCount > 0)
                                    SizedBox(width: 6.w),
                                  if (hasNewBills && newBillsCount > 0)
                                    _buildStatusPill(
                                      icon: Icons.notifications_active_rounded,
                                      label: '$newBillsCount шинэ',
                                      color: Colors.blue[600]!,
                                      isPrimary: false,
                                    ),
                                ],
                              ),
                            ],
                          ],
                        ),
                      ),

                      // Chevron
                      SizedBox(width: 4.w),
                      Icon(
                        Icons.chevron_right_rounded,
                        color: context.textSecondaryColor.withOpacity(0.25),
                        size: 22.sp,
                      ),
                    ],
                  ),
                ),
              ),
            ),

            // ── Action Buttons (Edit / Delete) ──
            if (hasActions) ...[
              SizedBox(width: 6.w),
              Container(
                width: 42.w,
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF1C2229) : Colors.white,
                  borderRadius: BorderRadius.circular(14.r),
                  border: Border.all(
                    color: isDark
                        ? Colors.white.withOpacity(0.06)
                        : const Color(0xFFE8ECF0),
                    width: 1,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: isDark
                          ? Colors.black.withOpacity(0.2)
                          : Colors.black.withOpacity(0.04),
                      blurRadius: 12,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    if (widget.onEditTap != null)
                      Expanded(
                        child: Material(
                          color: Colors.transparent,
                          child: InkWell(
                            onTap: widget.onEditTap,
                            borderRadius: BorderRadius.vertical(
                              top: Radius.circular(14.r),
                              bottom: widget.onDeleteTap == null ? Radius.circular(14.r) : Radius.zero,
                            ),
                            child: Center(
                              child: Icon(Icons.edit_outlined, color: AppColors.deepGreen, size: 18.sp),
                            ),
                          ),
                        ),
                      ),
                    if (widget.onEditTap != null && widget.onDeleteTap != null)
                      Divider(
                        height: 1,
                        thickness: 1,
                        color: isDark ? Colors.white.withOpacity(0.06) : const Color(0xFFE8ECF0),
                      ),
                    if (widget.onDeleteTap != null)
                      Expanded(
                        child: Material(
                          color: Colors.transparent,
                          child: InkWell(
                            onTap: widget.onDeleteTap,
                            borderRadius: BorderRadius.vertical(
                              bottom: Radius.circular(14.r),
                              top: widget.onEditTap == null ? Radius.circular(14.r) : Radius.zero,
                            ),
                            child: Center(
                              child: Icon(Icons.delete_outline_rounded, color: Colors.red[400], size: 18.sp),
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildBalanceRow(double balance, double aldangi) {
    return Row(
      children: [
        _buildStatusPill(
          icon: Icons.account_balance_wallet_rounded,
          label: '${_formatNumber(balance)}₮',
          color: AppColors.deepGreen,
          isPrimary: true,
        ),
        SizedBox(width: 6.w),
        _buildStatusPill(
          icon: Icons.history_rounded,
          label: '${aldangi > 0 ? "+" : ""}${_formatNumber(aldangi)}₮',
          color: Colors.red[400]!,
          isPrimary: false,
        ),
      ],
    );
  }

  Widget _buildStatusPill({
    required IconData icon,
    required String label,
    required Color color,
    bool isPrimary = false,
  }) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
      decoration: BoxDecoration(
        color: isPrimary ? color : color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(8.r),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: isPrimary ? Colors.white : color, size: 11.sp),
          SizedBox(width: 4.w),
          Text(
            label,
            style: TextStyle(
              color: isPrimary ? Colors.white : color,
              fontSize: 10.sp,
              fontWeight: FontWeight.w400,
            ),
          ),
        ],
      ),
    );
  }

  double _parseNum(dynamic val) {
    if (val == null) return 0.0;
    if (val is num) return val.toDouble();
    if (val is String) return double.tryParse(val) ?? 0.0;
    return 0.0;
  }

  String _formatNumber(double number) {
    String str = number.toStringAsFixed(0);
    final RegExp reg = RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))');
    return str.replaceAllMapped(reg, (Match match) => '${match[1]},');
  }
}
