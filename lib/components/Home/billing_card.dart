import 'dart:ui' show FontFeature;
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:sukh_app/constants/constants.dart';
import 'package:sukh_app/utils/theme_extensions.dart';
import 'package:sukh_app/utils/format_util.dart';

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

class _BillingCardState extends State<BillingCard> {

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
    final doorNo = widget.billing['walletDoorNo']?.toString() ?? 
                   widget.billing['tootNum']?.toString() ?? 
                   widget.billing['toot']?.toString() ?? 
                   '';
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

    // Use 'uldegdel' as the absolute source of truth if available (from ledger summary)
    double cardBalance = widget.billing['uldegdel'] != null
        ? _parseNum(widget.billing['uldegdel'])
        : _parseNum(widget.billing['perItemTotal']);

    double cardAldangi = widget.billing['uldegdelAldangi'] != null
        ? _parseNum(widget.billing['uldegdelAldangi'])
        : _parseNum(widget.billing['perItemAldangi']);

    final bool isPlaceholder = widget.billing['isPlaceholder'] == true;

    final String displayName;
    if (isPlaceholder) {
      final orgName = widget.billing['baiguullagiinNer']?.toString() ?? '';
      displayName = orgName.isNotEmpty ? orgName : 'Орон сууцны төлбөр';
    } else {
      displayName = (nickname != null && nickname.isNotEmpty)
          ? nickname
          : billingName;
    }

    // DEBUG LOG


    // Removed fallback that used widget.totalBalance for individual cards
    // to prevent cross-apartment balance leakage.

    final shouldShowBalance =
        cardBalance != 0 ||
        isEBillConnected ||
        widget.billing['isLocalData'] == true;
    final hasActions = !isPlaceholder && (widget.onEditTap != null || widget.onDeleteTap != null);

    final bool hasBalance = cardBalance != 0;
    final bool isCredit = cardBalance < 0;

    final hayag = () {
      final expanded = widget.expandAddressAbbreviations(bairniiNer);
      if (expanded.isEmpty) {
        return customerCode.isNotEmpty ? 'Код: $customerCode' : 'Хаяг сонгоно уу';
      }
      if (doorNo.isNotEmpty) {
        final cleanExpanded = expanded.trim();
        final cleanDoor = doorNo.trim();
        if (cleanExpanded.endsWith(cleanDoor) ||
            cleanExpanded.endsWith(' $cleanDoor') ||
            cleanExpanded.endsWith(', $cleanDoor') ||
            cleanExpanded.endsWith('-$cleanDoor')) {
          return cleanExpanded;
        }
        return '$cleanExpanded, $cleanDoor тоот';
      }
      return expanded.endsWith('тоот') ? expanded : '$expanded тоот';
    }();

    final ner = billingName.toLowerCase();
    final oronSuuts = ner.contains('орон сууц') || ner.contains('сөх') || widget.billing['isLocalData'] == true;
    const mint = Color(0xFF7DF0C6);
    final accent = isDark ? mint : AppColors.deepGreen;
    final tulukhUngu = isDark ? const Color(0xFFFFB86B) : const Color(0xFFC2410C);

    // Төлөвийн мөр (дүнгийн доор)
    final String tuluvText;
    final Color tuluvUngu;
    if (isPlaceholder) {
      tuluvText = 'Холбогдоогүй';
      tuluvUngu = tulukhUngu;
    } else if (isCredit) {
      tuluvText = 'Илүү төлсөн';
      tuluvUngu = accent;
    } else if (hasBalance) {
      tuluvText = 'Төлөх';
      tuluvUngu = tulukhUngu;
    } else {
      tuluvText = 'Төлөгдсөн';
      tuluvUngu = accent;
    }

    return Padding(
      padding: EdgeInsets.only(bottom: 10.h),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: widget.onTap,
          borderRadius: BorderRadius.circular(20.r),
          child: Ink(
            padding: EdgeInsets.fromLTRB(14.w, 14.h, 6.w, 14.h),
            decoration: BoxDecoration(
              color: context.cardBackgroundColor,
              borderRadius: BorderRadius.circular(20.r),
              border: Border.all(
                color: isPlaceholder
                    ? tulukhUngu.withOpacity(0.35)
                    : (isDark ? Colors.white.withOpacity(0.06) : Colors.black.withOpacity(0.05)),
              ),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Дүрс
                Container(
                  width: 42.w,
                  height: 42.w,
                  decoration: BoxDecoration(
                    color: (isPlaceholder ? tulukhUngu : accent).withOpacity(isDark ? 0.14 : 0.09),
                    borderRadius: BorderRadius.circular(13.r),
                  ),
                  child: Icon(
                    isPlaceholder
                        ? Icons.link_rounded
                        : (oronSuuts ? Icons.apartment_rounded : Icons.bolt_rounded),
                    size: 20.sp,
                    color: isPlaceholder ? tulukhUngu : accent,
                  ),
                ),
                SizedBox(width: 12.w),
                // Нэр, хаяг — бүтнээр нь
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        displayName,
                        softWrap: true,
                        style: TextStyle(
                          color: context.textPrimaryColor,
                          fontSize: 15.sp,
                          fontWeight: FontWeight.w600,
                          letterSpacing: -0.2,
                          height: 1.25,
                        ),
                      ),
                      SizedBox(height: 3.h),
                      Text(
                        isPlaceholder ? 'Хэрэглээний төлбөрөө холбоно уу' : hayag,
                        softWrap: true,
                        style: TextStyle(
                          color: context.textSecondaryColor,
                          fontSize: 12.5.sp,
                          height: 1.3,
                        ),
                      ),
                      if (!isPlaceholder && billerName != null && billerName.isNotEmpty) ...[
                        SizedBox(height: 2.h),
                        Text(
                          billerName,
                          softWrap: true,
                          style: TextStyle(
                            color: context.textSecondaryColor.withOpacity(0.8),
                            fontSize: 11.5.sp,
                          ),
                        ),
                      ],
                      if (!isPlaceholder && hasNewBills && newBillsCount > 0) ...[
                        SizedBox(height: 8.h),
                        Container(
                          padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 3.h),
                          decoration: BoxDecoration(
                            color: accent.withOpacity(isDark ? 0.14 : 0.09),
                            borderRadius: BorderRadius.circular(100),
                          ),
                          child: Text(
                            '$newBillsCount шинэ нэхэмжлэх',
                            style: TextStyle(color: accent, fontSize: 11.sp, fontWeight: FontWeight.w600),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                SizedBox(width: 8.w),
                // Дүн + төлөв
                if (shouldShowBalance || isPlaceholder)
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      if (!isPlaceholder)
                        Text(
                          '${_formatNumber(cardBalance.abs())}₮',
                          style: TextStyle(
                            color: context.textPrimaryColor,
                            fontSize: 15.sp,
                            fontWeight: FontWeight.w600,
                            letterSpacing: -0.3,
                            fontFeatures: const [FontFeature.tabularFigures()],
                          ),
                        ),
                      SizedBox(height: 4.h),
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 6.w,
                            height: 6.w,
                            decoration: BoxDecoration(color: tuluvUngu, shape: BoxShape.circle),
                          ),
                          SizedBox(width: 5.w),
                          Text(
                            tuluvText,
                            style: TextStyle(color: tuluvUngu, fontSize: 11.5.sp, fontWeight: FontWeight.w500),
                          ),
                        ],
                      ),
                      if (cardAldangi > 0.5) ...[
                        SizedBox(height: 3.h),
                        Text(
                          'Алданги ${_formatNumber(cardAldangi)}₮',
                          style: TextStyle(color: context.textSecondaryColor, fontSize: 10.5.sp),
                        ),
                      ],
                    ],
                  ),
                // Засах / устгах — цэс
                if (hasActions)
                  PopupMenuButton<String>(
                    padding: EdgeInsets.zero,
                    iconSize: 20.sp,
                    icon: Icon(Icons.more_vert_rounded, color: context.textSecondaryColor),
                    color: context.cardBackgroundColor,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14.r)),
                    onSelected: (v) {
                      if (v == 'edit') widget.onEditTap?.call();
                      if (v == 'delete') widget.onDeleteTap?.call();
                    },
                    itemBuilder: (_) => [
                      if (widget.onEditTap != null)
                        PopupMenuItem(
                          value: 'edit',
                          child: Row(children: [
                            Icon(Icons.edit_outlined, size: 18.sp, color: accent),
                            SizedBox(width: 10.w),
                            Text('Нэр засах', style: TextStyle(color: context.textPrimaryColor, fontSize: 14.sp)),
                          ]),
                        ),
                      if (widget.onDeleteTap != null)
                        PopupMenuItem(
                          value: 'delete',
                          child: Row(children: [
                            Icon(Icons.delete_outline_rounded, size: 18.sp, color: const Color(0xFFE5484D)),
                            SizedBox(width: 10.w),
                            Text('Устгах', style: TextStyle(color: const Color(0xFFE5484D), fontSize: 14.sp)),
                          ]),
                        ),
                    ],
                  )
                else
                  SizedBox(width: 8.w),
              ],
            ),
          ),
        ),
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
    return formatNumber(number);
  }
}
