import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:sukh_app/components/Nekhemjlekh/nekhemjlekh_models.dart';
import 'package:sukh_app/constants/constants.dart';
import 'package:sukh_app/utils/theme_extensions.dart';
import 'package:sukh_app/utils/format_util.dart';

class InvoiceCard extends StatelessWidget {
  final NekhemjlekhItem invoice;
  final bool isHistory;
  final bool isSmallScreen;
  final bool isVerySmallScreen;
  final VoidCallback onToggleExpand;
  final VoidCallback? onToggleSelect;
  final VoidCallback? onShowVATReceipt;

  const InvoiceCard({
    super.key,
    required this.invoice,
    this.isHistory = false,
    this.isSmallScreen = false,
    this.isVerySmallScreen = false,
    required this.onToggleExpand,
    this.onToggleSelect,
    this.onShowVATReceipt,
  });

  IconData _getServiceIcon(String name) {
    final n = name.toLowerCase();
    if (n.contains('сөх') || n.contains('байр') || n.contains('орон сууц') || n.contains('ашиглалт')) {
      return Icons.apartment_rounded;
    } else if (n.contains('цахилгаан') || n.contains('тог') || n.contains('гэрэл')) {
      return Icons.bolt_rounded;
    } else if (n.contains('ус') || n.contains('хүйтэн') || n.contains('халуун') || n.contains('бохир')) {
      return Icons.water_drop_rounded;
    } else if (n.contains('лифт') || n.contains('цахилгаан шат')) {
      return Icons.elevator_rounded;
    } else if (n.contains('зогсоол') || n.contains('гараж') || n.contains('паркинг')) {
      return Icons.local_parking_rounded;
    } else if (n.contains('хог')) {
      return Icons.delete_outline_rounded;
    } else if (n.contains('дулаан') || n.contains('халаалт')) {
      return Icons.thermostat_rounded;
    }
    return Icons.receipt_long_rounded;
  }

  Color _getStatusColor(NekhemjlekhItem inv) {
    if (inv.isPaid) return const Color(0xFF10B981);
    return const Color(0xFFF59E0B);
  }

  String _getStatusLabel(NekhemjlekhItem inv) {
    if (inv.isPaid) return 'Төлөгдсөн';
    return 'Хүлээгдэж байгаа';
  }

  @override
  Widget build(BuildContext context) {
    final statusColor = _getStatusColor(invoice);
    final statusLabel = _getStatusLabel(invoice);
    final isSelected = invoice.isSelected;
    final isDark = context.isDarkMode;

    final screenWidth = MediaQuery.of(context).size.width;
    final isSmall = isSmallScreen || screenWidth < 375;
    final isVerySmall = isVerySmallScreen || screenWidth < 340;

    final displayTitle = (invoice.baiguullagiinNer.isNotEmpty &&
            (invoice.baiguullagiinNer.toLowerCase().contains('цахилгаан') ||
             invoice.baiguullagiinNer.toLowerCase().contains('ус') ||
             invoice.baiguullagiinNer.toLowerCase().contains('лифт') ||
             invoice.baiguullagiinNer.toLowerCase().contains('зогсоол')))
        ? invoice.baiguullagiinNer
        : 'СӨХ төлбөр';

    final serviceIcon = _getServiceIcon(displayTitle);

    return RepaintBoundary(
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeInOut,
        margin: EdgeInsets.only(bottom: (isVerySmall ? 8.0 : (isSmall ? 10.0 : 12.0)).h),
        decoration: BoxDecoration(
          color: context.cardBackgroundColor,
          borderRadius: BorderRadius.circular(18.r),
          border: Border.all(
            color: isSelected
                ? AppColors.deepGreen.withOpacity(0.4)
                : (isDark ? Colors.white.withOpacity(0.06) : context.borderColor.withOpacity(0.12)),
            width: isSelected ? 1.5 : 1.0,
          ),
          boxShadow: [
            BoxShadow(
              color: isSelected
                  ? AppColors.deepGreen.withOpacity(isDark ? 0.2 : 0.08)
                  : Colors.black.withOpacity(isDark ? 0.25 : 0.03),
              blurRadius: isSelected ? 16 : 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(18.r),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: onToggleExpand,
              borderRadius: BorderRadius.circular(18.r),
              child: Column(
                children: [
                  // ── ZONE 1: Identity & Status Header ──
                  Padding(
                    padding: EdgeInsets.fromLTRB(
                      (isVerySmall ? 10.0 : (isSmall ? 12.0 : 14.0)).w,
                      (isVerySmall ? 10.0 : 12.0).h,
                      (isVerySmall ? 10.0 : (isSmall ? 12.0 : 14.0)).w,
                      (isVerySmall ? 6.0 : 8.0).h,
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        // 1. Selection Checkbox
                        if (!isHistory && onToggleSelect != null && !invoice.isPaid) ...[
                          GestureDetector(
                            onTap: () {
                              HapticFeedback.lightImpact();
                              onToggleSelect!();
                            },
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 180),
                              width: (isVerySmall ? 19.0 : 21.0).w,
                              height: (isVerySmall ? 19.0 : 21.0).w,
                              decoration: BoxDecoration(
                                color: invoice.isSelected ? AppColors.deepGreen : Colors.transparent,
                                borderRadius: BorderRadius.circular(7.r),
                                border: Border.all(
                                  color: invoice.isSelected
                                      ? AppColors.deepGreen
                                      : (isDark ? Colors.white30 : Colors.grey[400]!),
                                  width: 1.5,
                                ),
                              ),
                              child: invoice.isSelected
                                  ? Icon(Icons.check, color: Colors.white, size: (isVerySmall ? 12.0 : 14.0).sp)
                                  : null,
                            ),
                          ),
                          SizedBox(width: (isVerySmall ? 8.0 : 10.0).w),
                        ],

                        // 2. Service Icon (Duotone Tinted Square)
                        Container(
                          width: (isVerySmall ? 34.0 : (isSmall ? 38.0 : 40.0)).w,
                          height: (isVerySmall ? 34.0 : (isSmall ? 38.0 : 40.0)).w,
                          decoration: BoxDecoration(
                            color: AppColors.deepGreen.withOpacity(isDark ? 0.16 : 0.08),
                            borderRadius: BorderRadius.circular(11.r),
                            border: Border.all(
                              color: AppColors.deepGreen.withOpacity(isDark ? 0.25 : 0.12),
                              width: 0.8,
                            ),
                          ),
                          child: Icon(
                            serviceIcon,
                            color: AppColors.deepGreen,
                            size: (isVerySmall ? 17.0 : (isSmall ? 19.0 : 20.0)).sp,
                          ),
                        ),
                        SizedBox(width: (isVerySmall ? 8.0 : 10.0).w),

                        // 3. Service Title & Apartment/Toot
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                displayTitle,
                                style: TextStyle(
                                  color: context.textPrimaryColor,
                                  fontSize: (isVerySmall ? 12.5 : (isSmall ? 13.5 : 14.5)).sp,
                                  fontWeight: FontWeight.w700,
                                  letterSpacing: -0.3,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              SizedBox(height: 2.5.h),
                              Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Icons.home_outlined,
                                    size: (isVerySmall ? 10.0 : 11.5).sp,
                                    color: context.textSecondaryColor,
                                  ),
                                  SizedBox(width: 3.5.w),
                                  Flexible(
                                    child: Text(
                                      invoice.bairNer.isNotEmpty
                                          ? '${invoice.bairNer} - ${invoice.toot} тоот'
                                          : invoice.toot.isNotEmpty
                                              ? '${invoice.toot} тоот'
                                              : '',
                                      style: TextStyle(
                                        color: context.textSecondaryColor,
                                        fontSize: (isVerySmall ? 9.5 : (isSmall ? 10.0 : 11.0)).sp,
                                        fontWeight: FontWeight.w500,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        SizedBox(width: 8.w),

                        // 4. Status Badge (Top Right Separate Pill Box)
                        _buildStatusBadge(statusColor, statusLabel, isDark, isSmall, isVerySmall),
                      ],
                    ),
                  ),

                  // ── Subtle Divider ──
                  Padding(
                    padding: EdgeInsets.symmetric(
                      horizontal: (isVerySmall ? 10.0 : (isSmall ? 12.0 : 14.0)).w,
                    ),
                    child: Divider(
                      height: 1,
                      thickness: 0.7,
                      color: context.borderColor.withOpacity(isDark ? 0.08 : 0.12),
                    ),
                  ),

                  // ── ZONE 2: Due Date & Amount ──
                  Padding(
                    padding: EdgeInsets.fromLTRB(
                      (isVerySmall ? 10.0 : (isSmall ? 12.0 : 14.0)).w,
                      (isVerySmall ? 7.0 : 8.5).h,
                      (isVerySmall ? 10.0 : (isSmall ? 12.0 : 14.0)).w,
                      (isVerySmall ? 9.0 : 11.0).h,
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        // Due Date
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.calendar_today_outlined,
                              size: (isVerySmall ? 10.0 : 11.0).sp,
                              color: context.textSecondaryColor,
                            ),
                            SizedBox(width: 4.w),
                            Text(
                              invoice.formattedDate,
                              style: TextStyle(
                                color: context.textSecondaryColor,
                                fontSize: (isVerySmall ? 10.0 : (isSmall ? 10.5 : 11.5)).sp,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),

                        // Amount & Expand Button
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              invoice.isPaid
                                  ? '${formatNumber(invoice.displayNiitTulbur.abs(), 2)}₮'
                                  : invoice.formattedAmount,
                              style: TextStyle(
                                color: context.textPrimaryColor,
                                fontSize: (isVerySmall ? 13.5 : (isSmall ? 14.5 : 16.0)).sp,
                                fontWeight: FontWeight.w800,
                                letterSpacing: -0.4,
                              ),
                            ),
                            SizedBox(width: 6.w),
                            AnimatedRotation(
                              turns: invoice.isExpanded ? 0.5 : 0.0,
                              duration: const Duration(milliseconds: 200),
                              child: Container(
                                width: (isVerySmall ? 18.0 : 20.0).w,
                                height: (isVerySmall ? 18.0 : 20.0).w,
                                decoration: BoxDecoration(
                                  color: isDark
                                      ? Colors.white.withOpacity(0.06)
                                      : const Color(0xFFF1F5F9),
                                  shape: BoxShape.circle,
                                ),
                                child: Icon(
                                  Icons.keyboard_arrow_down_rounded,
                                  size: (isVerySmall ? 12.0 : 14.0).sp,
                                  color: context.textSecondaryColor,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  // ── ZONE 3: Expanded Accordion Detail ──
                  if (invoice.isExpanded)
                    Container(
                      decoration: BoxDecoration(
                        color: isDark
                            ? Colors.black.withOpacity(0.22)
                            : const Color(0xFFF8FAFC),
                        borderRadius: BorderRadius.only(
                          bottomLeft: Radius.circular(18.r),
                          bottomRight: Radius.circular(18.r),
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Divider(
                            height: 1,
                            thickness: 1,
                            color: context.borderColor.withOpacity(isDark ? 0.08 : 0.12),
                          ),
                          _buildExpandedSection(context),
                        ],
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

  Widget _buildStatusBadge(
    Color statusColor,
    String statusLabel,
    bool isDark,
    bool isSmall,
    bool isVerySmall,
  ) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: (isVerySmall ? 7.0 : (isSmall ? 8.0 : 9.0)).w,
        vertical: (isVerySmall ? 2.5 : 3.0).h,
      ),
      decoration: BoxDecoration(
        color: isDark
            ? statusColor.withOpacity(0.16)
            : statusColor.withOpacity(0.10),
        borderRadius: BorderRadius.circular(20.r),
        border: Border.all(
          color: statusColor.withOpacity(isDark ? 0.35 : 0.25),
          width: 0.8,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: (isVerySmall ? 4.5 : 5.0).w,
            height: (isVerySmall ? 4.5 : 5.0).w,
            decoration: BoxDecoration(
              color: statusColor,
              shape: BoxShape.circle,
            ),
          ),
          SizedBox(width: (isVerySmall ? 3.5 : 4.5).w),
          Text(
            statusLabel,
            style: TextStyle(
              color: statusColor,
              fontSize: (isVerySmall ? 8.5 : (isSmall ? 9.0 : 9.5)).sp,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.2,
            ),
          ),
        ],
      ),
    );
  }

  (IconData, Color, Color) _getChargeMeta(String name, bool isPayment, bool isStarting) {
    if (isPayment) {
      return (Icons.check_circle_rounded, const Color(0xFF10B981), const Color(0xFFE6F7F0));
    }
    if (isStarting) {
      return (Icons.history_rounded, const Color(0xFF64748B), const Color(0xFFF1F5F9));
    }
    final lower = name.toLowerCase();
    if (lower.contains('цахилгаан') || lower.contains('тог')) {
      return (Icons.bolt_rounded, const Color(0xFFF59E0B), const Color(0xFFFEF3C7));
    }
    if (lower.contains('ус')) {
      return (Icons.water_drop_rounded, const Color(0xFF0284C7), const Color(0xFFE0F2FE));
    }
    if (lower.contains('дулаан') || lower.contains('халаалт')) {
      return (Icons.whatshot_rounded, const Color(0xFFEA580C), const Color(0xFFFFEDD5));
    }
    if (lower.contains('хог')) {
      return (Icons.delete_outline_rounded, const Color(0xFF0D9488), const Color(0xFFCCFBF1));
    }
    if (lower.contains('лифт')) {
      return (Icons.elevator_rounded, const Color(0xFF8B5CF6), const Color(0xFFEDE9FE));
    }
    if (lower.contains('зогсоол') || lower.contains('паркинг')) {
      return (Icons.local_parking_rounded, const Color(0xFF4F46E5), const Color(0xFFEEF2FF));
    }
    if (lower.contains('сөх') || lower.contains('байр') || lower.contains('сууц')) {
      return (Icons.apartment_rounded, AppColors.deepGreen, const Color(0xFFEAF5F1));
    }
    return (Icons.receipt_long_rounded, AppColors.deepGreen, const Color(0xFFEAF5F1));
  }

  Widget _buildExpandedSection(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isSmall = isSmallScreen || screenWidth < 375;
    final isVerySmall = isVerySmallScreen || screenWidth < 340;
    final isDark = context.isDarkMode;

    final guilgeenuud = invoice.medeelel?.guilgeenuud?.where((g) {
          final baseAmt = (g.turul == 'tulult' || g.turul == 'buun_tulult')
              ? -(g.tulsunDun ?? 0.0)
              : (g.tulukhDun ?? g.undsenDun ?? g.dun ?? 0.0);
          return baseAmt != 0 &&
              !g.ekhniiUldegdelEsekh &&
              g.turul?.toLowerCase() != 'system_sync';
        }).toList() ??
        [];

    final additionalZardluud = invoice.medeelel?.zardluud
            .where((z) => z.isDisplayable && !z.isEkhniiUldegdel)
            .toList() ??
        [];

    final hasStartingBalance = (invoice.ekhniiUldegdel ?? 0) != 0;
    final totalItemsCount = guilgeenuud.length +
        additionalZardluud.length +
        (hasStartingBalance ? 1 : 0);

    return Padding(
      padding: EdgeInsets.symmetric(
        horizontal: (isVerySmall ? 10.0 : (isSmall ? 12.0 : 16.0)).w,
        vertical: (isVerySmall ? 10.0 : 14.0).h,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 1. Compact Location & Organization Card
          Container(
            padding: EdgeInsets.symmetric(
              horizontal: (isVerySmall ? 10.0 : 12.0).w,
              vertical: (isVerySmall ? 8.0 : 10.0).h,
            ),
            decoration: BoxDecoration(
              color: isDark ? Colors.white.withOpacity(0.04) : Colors.white,
              borderRadius: BorderRadius.circular(12.r),
              border: Border.all(
                color: isDark ? Colors.white.withOpacity(0.06) : Colors.black.withOpacity(0.05),
                width: 1,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(isDark ? 0.15 : 0.02),
                  blurRadius: 6,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              children: [
                Container(
                  width: (isVerySmall ? 30.0 : 34.0).w,
                  height: (isVerySmall ? 30.0 : 34.0).w,
                  decoration: BoxDecoration(
                    color: AppColors.deepGreen.withOpacity(isDark ? 0.2 : 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.apartment_rounded,
                    size: (isVerySmall ? 15.0 : 17.0).sp,
                    color: AppColors.deepGreen,
                  ),
                ),
                SizedBox(width: (isVerySmall ? 8.0 : 10.0).w),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        invoice.baiguullagiinNer.isNotEmpty ? invoice.baiguullagiinNer : 'СӨХ',
                        style: TextStyle(
                          color: context.textPrimaryColor,
                          fontSize: (isVerySmall ? 11.5 : 12.5).sp,
                          fontWeight: FontWeight.w700,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      SizedBox(height: 2.h),
                      Text(
                        '${invoice.khayag.isNotEmpty ? "${invoice.khayag}, " : ""}${invoice.orts.isNotEmpty ? "${invoice.orts}-р орц, " : ""}${invoice.toot.isNotEmpty ? "${invoice.toot} тоот" : (invoice.medeelel?.toot ?? "")} • ${invoice.formattedDate}',
                        style: TextStyle(
                          color: context.textSecondaryColor,
                          fontSize: (isVerySmall ? 9.5 : 10.5).sp,
                          fontWeight: FontWeight.w500,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                if (invoice.gereeniiDugaar.isNotEmpty) ...[
                  SizedBox(width: 6.w),
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 7.w, vertical: 3.h),
                    decoration: BoxDecoration(
                      color: AppColors.deepGreen.withOpacity(isDark ? 0.2 : 0.08),
                      borderRadius: BorderRadius.circular(6.r),
                    ),
                    child: Text(
                      '№ ${invoice.gereeniiDugaar}',
                      style: TextStyle(
                        color: AppColors.deepGreen,
                        fontSize: (isVerySmall ? 8.5 : 9.5).sp,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
          SizedBox(height: (isVerySmall ? 10.0 : 14.0).h),

          // 2. Section Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    width: 3.w,
                    height: 12.h,
                    decoration: BoxDecoration(
                      color: AppColors.deepGreen,
                      borderRadius: BorderRadius.circular(2.r),
                    ),
                  ),
                  SizedBox(width: 6.w),
                  Text(
                    'ТӨЛБӨРИЙН ЗАДАРГАА',
                    style: TextStyle(
                      color: context.textPrimaryColor,
                      fontSize: (isVerySmall ? 9.5 : (isSmall ? 10.5 : 11.5)).sp,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.8,
                    ),
                  ),
                ],
              ),
              if (totalItemsCount > 0)
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 6.w, vertical: 2.h),
                  decoration: BoxDecoration(
                    color: isDark ? Colors.white.withOpacity(0.06) : Colors.black.withOpacity(0.04),
                    borderRadius: BorderRadius.circular(100),
                  ),
                  child: Text(
                    '$totalItemsCount зүйл',
                    style: TextStyle(
                      color: context.textSecondaryColor,
                      fontSize: (isVerySmall ? 8.5 : 9.5).sp,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
            ],
          ),
          SizedBox(height: (isVerySmall ? 8.0 : 10.0).h),

          // 3. Breakdown Items in a Clean Card Container
          Container(
            padding: EdgeInsets.symmetric(
              horizontal: (isVerySmall ? 10.0 : 12.0).w,
              vertical: (isVerySmall ? 6.0 : 8.0).h,
            ),
            decoration: BoxDecoration(
              color: isDark ? Colors.white.withOpacity(0.03) : Colors.white,
              borderRadius: BorderRadius.circular(14.r),
              border: Border.all(
                color: isDark ? Colors.white.withOpacity(0.05) : Colors.black.withOpacity(0.04),
                width: 1,
              ),
            ),
            child: Column(
              children: [
                if (totalItemsCount == 0)
                  Padding(
                    padding: EdgeInsets.symmetric(vertical: 16.h),
                    child: Center(
                      child: Text(
                        'Дэлгэрэнгүй задаргаа байхгүй байна',
                        style: TextStyle(
                          color: context.textSecondaryColor,
                          fontSize: 11.sp,
                        ),
                      ),
                    ),
                  ),
                // Starting Balance
                if (hasStartingBalance) ...[
                  _buildModernChargeRow(
                    context,
                    'Эхний үлдэгдэл',
                    invoice.ekhniiUldegdel!,
                    isStartingBalance: true,
                    isSmall: isSmall,
                    isVerySmall: isVerySmall,
                  ),
                  if (guilgeenuud.isNotEmpty || additionalZardluud.isNotEmpty)
                    Padding(
                      padding: EdgeInsets.symmetric(vertical: 6.h),
                      child: Divider(
                        height: 1,
                        thickness: 0.8,
                        color: context.borderColor.withOpacity(0.08),
                      ),
                    ),
                ],
                // Ledger Items
                ...guilgeenuud.asMap().entries.map((entry) {
                  final idx = entry.key;
                  final g = entry.value;
                  final isPayment = (g.turul == 'tulult' ||
                      g.turul == 'buun_tulult' ||
                      (g.dun != null && g.dun! < 0));
                  final label = isPayment
                      ? ((g.tailbar?.isNotEmpty ?? false)
                          ? g.tailbar!
                          : (g.zardliinNer?.isNotEmpty ?? false)
                              ? g.zardliinNer!
                              : 'Төлөлт')
                      : ((g.tailbar?.isNotEmpty ?? false)
                          ? g.tailbar!
                          : (g.zardliinNer?.isNotEmpty ?? false)
                              ? g.zardliinNer!
                              : 'Үйлчилгээний төлбөр');
                  final paidAmt = (g.tulsunDun != null && g.tulsunDun! > 0)
                      ? g.tulsunDun!
                      : (g.dun != null && g.dun! < 0 ? g.dun!.abs() : 0.0);
                  final amt = isPayment
                      ? -paidAmt
                      : (g.tulukhDun ?? g.undsenDun ?? g.dun ?? 0.0);
                  final isLast = idx == guilgeenuud.length - 1 && additionalZardluud.isEmpty;

                  return Column(
                    children: [
                      _buildModernChargeRow(
                        context,
                        label,
                        amt,
                        isPayment: isPayment,
                        isSmall: isSmall,
                        isVerySmall: isVerySmall,
                      ),
                      if (!isLast)
                        Padding(
                          padding: EdgeInsets.symmetric(vertical: 6.h),
                          child: Divider(
                            height: 1,
                            thickness: 0.8,
                            color: context.borderColor.withOpacity(0.08),
                          ),
                        ),
                    ],
                  );
                }),
                // Additional Charges
                ...additionalZardluud.asMap().entries.map((entry) {
                  final idx = entry.key;
                  final z = entry.value;
                  final isLast = idx == additionalZardluud.length - 1;

                  return Column(
                    children: [
                      if (idx == 0 && guilgeenuud.isNotEmpty)
                        Padding(
                          padding: EdgeInsets.symmetric(vertical: 6.h),
                          child: Divider(
                            height: 1,
                            thickness: 0.8,
                            color: context.borderColor.withOpacity(0.08),
                          ),
                        ),
                      _buildModernChargeRow(
                        context,
                        z.ner,
                        z.displayAmount,
                        isSmall: isSmall,
                        isVerySmall: isVerySmall,
                      ),
                      if (!isLast)
                        Padding(
                          padding: EdgeInsets.symmetric(vertical: 6.h),
                          child: Divider(
                            height: 1,
                            thickness: 0.8,
                            color: context.borderColor.withOpacity(0.08),
                          ),
                        ),
                    ],
                  );
                }),
              ],
            ),
          ),
          SizedBox(height: (isVerySmall ? 10.0 : 12.0).h),

          // 4. Final Total Card
          Container(
            padding: EdgeInsets.symmetric(
              horizontal: (isVerySmall ? 12.0 : (isSmall ? 14.0 : 16.0)).w,
              vertical: (isVerySmall ? 9.0 : 11.0).h,
            ),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF13201C) : const Color(0xFFEAF5F1),
              borderRadius: BorderRadius.circular(14.r),
              border: Border.all(
                color: AppColors.deepGreen.withOpacity(0.2),
                width: 1,
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      invoice.isPaid ? 'НИЙТ ТӨЛСӨН' : 'НИЙТ ТӨЛӨХ',
                      style: TextStyle(
                        color: AppColors.deepGreen,
                        fontSize: (isVerySmall ? 9.5 : (isSmall ? 10.5 : 11.5)).sp,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.5,
                      ),
                    ),
                    SizedBox(height: 1.h),
                    Text(
                      invoice.isPaid ? 'Төлбөр бүрэн төлөгдсөн' : 'Нэхэмжлэхийн үлдэгдэл',
                      style: TextStyle(
                        color: context.textSecondaryColor,
                        fontSize: (isVerySmall ? 8.5 : 9.5).sp,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
                Text(
                  invoice.isPaid
                      ? '${formatNumber(invoice.displayNiitTulbur.abs(), 2)}₮'
                      : invoice.formattedAmount,
                  style: TextStyle(
                    color: context.textPrimaryColor,
                    fontSize: (isVerySmall ? 14.5 : (isSmall ? 16.0 : 17.5)).sp,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.3,
                  ),
                ),
              ],
            ),
          ),

          // 5. VAT Receipt Button
          if (isHistory && onShowVATReceipt != null) ...[
            SizedBox(height: (isVerySmall ? 8.0 : 10.0).h),
            SizedBox(
              width: double.infinity,
              height: (isVerySmall ? 38.0 : 42.0).h,
              child: ElevatedButton.icon(
                onPressed: onShowVATReceipt,
                icon: Icon(
                  Icons.receipt_long_rounded,
                  size: (isVerySmall ? 15.0 : 17.0).sp,
                  color: Colors.white,
                ),
                label: Text(
                  'И-БАРИМТ ХАРАХ',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: (isVerySmall ? 10.5 : 11.5).sp,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.5,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.deepGreen,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10.r),
                  ),
                  elevation: 0,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildModernChargeRow(
    BuildContext context,
    String label,
    double amount, {
    bool isStartingBalance = false,
    bool isPayment = false,
    bool isSmall = false,
    bool isVerySmall = false,
  }) {
    final isNegative = amount < 0 || isPayment;
    final displayLabel = cleanChargeName(label);
    final (iconData, iconColor, bgTint) =
        _getChargeMeta(label, isPayment, isStartingBalance);
    final isDark = context.isDarkMode;

    return Padding(
      padding: EdgeInsets.symmetric(vertical: 3.h),
      child: Row(
        children: [
          // Icon badge
          Container(
            width: (isVerySmall ? 24.0 : 28.0).w,
            height: (isVerySmall ? 24.0 : 28.0).w,
            decoration: BoxDecoration(
              color: isDark ? iconColor.withOpacity(0.18) : bgTint,
              shape: BoxShape.circle,
            ),
            child: Icon(
              iconData,
              color: iconColor,
              size: (isVerySmall ? 12.0 : 14.0).sp,
            ),
          ),
          SizedBox(width: (isVerySmall ? 8.0 : 10.0).w),
          // Name and optional subtitle
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  displayLabel,
                  style: TextStyle(
                    color: isStartingBalance
                        ? context.textPrimaryColor
                        : (isDark ? Colors.white70 : const Color(0xFF334155)),
                    fontSize: (isVerySmall ? 10.5 : (isSmall ? 11.5 : 12.5)).sp,
                    fontWeight: isStartingBalance ? FontWeight.w600 : FontWeight.w500,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                if (isPayment) ...[
                  SizedBox(height: 1.h),
                  Text(
                    'Төлөлт хийгдсэн',
                    style: TextStyle(
                      color: const Color(0xFF10B981),
                      fontSize: (isVerySmall ? 8.5 : 9.5).sp,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ],
            ),
          ),
          SizedBox(width: 8.w),
          // Amount
          Text(
            '${isNegative ? "-" : ""}${formatNumber(amount.abs(), 2)}₮',
            style: TextStyle(
              color: isNegative
                  ? const Color(0xFF10B981)
                  : context.textPrimaryColor,
              fontSize: (isVerySmall ? 11.5 : (isSmall ? 12.5 : 13.5)).sp,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}
