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

class _BillingCardState extends State<BillingCard>
    with TickerProviderStateMixin {
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

    _swipeHintAnimation =
        Tween<Offset>(
          begin: const Offset(0.15, 0),
          end: const Offset(-0.15, 0),
        ).animate(
          CurvedAnimation(
            parent: _swipeHintController,
            curve: Curves.easeInOutSine,
          ),
        );
  }

  @override
  void dispose() {
    _blinkController.dispose();
    _swipeHintController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = context.isDarkMode;

    // Get customer name
    String customerName = '';
    if (widget.billing['ovog'] != null &&
        widget.billing['ovog'].toString().isNotEmpty) {
      customerName = widget.billing['ovog'].toString();
      if (widget.billing['ner'] != null &&
          widget.billing['ner'].toString().isNotEmpty) {
        customerName += ' ${widget.billing['ner'].toString()}';
      }
    } else if (widget.billing['ner'] != null &&
        widget.billing['ner'].toString().isNotEmpty) {
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
    final billerName = widget.billing['billerName']?.toString();
    final nickname = widget.billing['nickname']?.toString();

    final hasNewBillsRaw = widget.billing['hasNewBills'] == true;
    final newBillsList = widget.billing['newBills'] is List
        ? widget.billing['newBills'] as List
        : [];
    final hasNewBills = hasNewBillsRaw || newBillsList.isNotEmpty;
    final newBillsCount =
        (widget.billing['newBillsCount'] as num?)?.toInt() ??
        newBillsList.length;

    final isEBillConnected =
        widget.billing['billingId'] != null ||
        widget.billing['walletBillingId'] != null ||
        (widget.billing['isLocalData'] != true &&
            widget.billing['customerId'] != null);

    double cardBalance = _parseNum(widget.billing['perItemTotal']);
    double cardAldangi = _parseNum(widget.billing['perItemAldangi']);

    if (cardBalance == 0 &&
        widget.totalBalance > 0 &&
        (widget.billing['isLocalData'] == true ||
            billingName.contains('Орон сууцны'))) {
      cardBalance = widget.totalBalance;
      cardAldangi = widget.totalAldangi ?? 0.0;
    }

    final shouldShowBalance =
        cardBalance != 0 ||
        isEBillConnected ||
        widget.billing['isLocalData'] == true;
    final hasActions = widget.onEditTap != null || widget.onDeleteTap != null;

    final displayName = (nickname != null && nickname.isNotEmpty)
        ? nickname
        : billingName;
    final showSubtitle = (nickname != null && nickname.isNotEmpty);

    // FIX: Show the bottom pills row if there are new bills OR a non-zero balance
    final bool hasBalance = cardBalance != 0;
    final bool isCredit = cardBalance < 0;
    final showPillsRow = (hasNewBills && newBillsCount > 0) || hasBalance;

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
                  padding: EdgeInsets.symmetric(
                    horizontal: 14.w,
                    vertical: 12.h,
                  ),
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
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.center,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            // Display name
                            Text(
                              displayName,
                              style: TextStyle(
                                color: context.textPrimaryColor,
                                fontSize: 16.sp,
                                fontWeight: FontWeight.w600,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),

                            // Billing name subtitle (only when no nickname)
                            if (!showSubtitle &&
                                billingName.isNotEmpty &&
                                billingName != displayName) ...[
                              SizedBox(height: 4.h),
                              Text(
                                billingName,
                                style: TextStyle(
                                  color: context.textSecondaryColor.withOpacity(
                                    0.6,
                                  ),
                                  fontSize: 13.sp,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],

                            SizedBox(height: 4.h),

                            // Address line
                            Text(
                              () {
                                final expanded = widget.expandAddressAbbreviations(bairniiNer);
                                if (expanded.isEmpty) {
                                  return customerCode.isNotEmpty ? 'Код: $customerCode' : 'Хаяг сонгоно уу';
                                }
                                if (doorNo.isNotEmpty) {
                                  // Avoid duplication (e.g., "8, 8")
                                  final cleanExpanded = expanded.trim();
                                  final cleanDoor = doorNo.trim();
                                  if (cleanExpanded.endsWith(cleanDoor) || 
                                      cleanExpanded.endsWith(' $cleanDoor') || 
                                      cleanExpanded.endsWith(', $cleanDoor') ||
                                      cleanExpanded.endsWith('-$cleanDoor')) {
                                    return cleanExpanded;
                                  }
                                  return '$cleanExpanded, $cleanDoor';
                                }
                                return expanded;
                              }(),
                              style: TextStyle(
                                color: context.textSecondaryColor,
                                fontSize: 13.sp,
                                height: 1.3,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),

                            // Biller name
                            if (billerName != null &&
                                billerName.isNotEmpty) ...[
                              SizedBox(height: 4.h),
                              Text(
                                billerName,
                                style: TextStyle(
                                  color: context.textSecondaryColor.withOpacity(
                                    0.8,
                                  ),
                                  fontSize: 12.sp,
                                  fontWeight: FontWeight.w500,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],

                            if (showPillsRow) ...[
                              SizedBox(height: 8.h),
                              Wrap(
                                spacing: 8.w,
                                runSpacing: 8.h,
                                crossAxisAlignment: WrapCrossAlignment.center,
                                children: [
                                  if (hasNewBills && newBillsCount > 0)
                                    _buildStatusPill(
                                      icon: Icons.notifications_active_rounded,
                                      label: '$newBillsCount шинэ',
                                      color: Colors.blue[600]!,
                                      isPrimary: false,
                                    ),
                                  if (hasBalance)
                                    _buildStatusPill(
                                      icon: isCredit
                                          ? Icons.trending_up_rounded
                                          : Icons.account_balance_wallet_rounded,
                                      label: isCredit
                                          ? '+${_formatNumber(cardBalance.abs())}₮ Илүү төлөлт'
                                          : '${_formatNumber(cardBalance)}₮ Төлөх',
                                      color: isCredit
                                          ? Colors.green[600]!
                                          : AppColors.error,
                                      isPrimary: false,
                                    ),
                                ],
                              ),
                            ],
                          ],
                        ),
                      ),
                      SizedBox(width: 4.w),
                    ],
                  ),
                ),
              ),
            ),

            // ── Action Buttons (Edit / Delete) ──
            if (hasActions) ...[
              SizedBox(width: 8.w),
              Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (widget.onEditTap != null)
                    _buildActionButton(
                      onTap: widget.onEditTap!,
                      icon: Icons.edit_outlined,
                      color: AppColors.deepGreen,
                      isDark: isDark,
                      context: context,
                    ),
                  if (widget.onEditTap != null && widget.onDeleteTap != null)
                    SizedBox(height: 8.h),
                  if (widget.onDeleteTap != null)
                    _buildActionButton(
                      onTap: widget.onDeleteTap!,
                      icon: Icons.delete_outline_rounded,
                      color: Colors.red[400]!,
                      isDark: isDark,
                      context: context,
                    ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildActionButton({
    required VoidCallback onTap,
    required IconData icon,
    required Color color,
    required bool isDark,
    required BuildContext context,
  }) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Container(
        width: 42.w,
        height: 42.h,
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1C2229) : Colors.white,
          shape: BoxShape.circle,
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
        child: Center(
          child: Icon(icon, color: color, size: 18.sp),
        ),
      ),
    );
  }

  Widget _buildStatusPill({
    required IconData icon,
    required String label,
    required Color color,
    bool isPrimary = false,
  }) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 6.h),
      decoration: BoxDecoration(
        color: isPrimary ? color : color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(10.r),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: isPrimary ? Colors.white : color, size: 14.sp),
          SizedBox(width: 6.w),
          Text(
            label,
            style: TextStyle(
              color: isPrimary ? Colors.white : color,
              fontSize: 12.sp,
              fontWeight: FontWeight.w500,
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
