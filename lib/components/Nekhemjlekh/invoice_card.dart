import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:sukh_app/components/Nekhemjlekh/nekhemjlekh_models.dart';
import 'package:sukh_app/constants/constants.dart';
import 'package:sukh_app/utils/responsive_helper.dart';
import 'package:sukh_app/utils/theme_extensions.dart';
import 'package:sukh_app/widgets/selectable_logo_image.dart';
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

  Color _getStatusColor(String status) {
    switch (status) {
      case 'Төлсөн':
        return const Color(0xFF10B981); // Emerald 500
      case 'Төлөөгүй':
      case 'Хэсэгчлэн':
        return const Color(0xFFF59E0B); // Amber 500
      default:
        return const Color(0xFF6B7280); // Gray 500
    }
  }

  String _getStatusLabel(String status) {
    switch (status) {
      case 'Төлсөн':
        return 'Төлөгдсөн';
      case 'Төлөөгүй':
        return 'Хүлээгдэж байгаа';
      case 'Хэсэгчлэн':
        return 'Хэсэгчлэн төлсөн';
      default:
        return status;
    }
  }

  @override
  Widget build(BuildContext context) {
    final effectiveTuluv = invoice.isPaid ? 'Төлсөн' : invoice.tuluv;
    final statusColor = _getStatusColor(effectiveTuluv);
    final statusLabel = _getStatusLabel(effectiveTuluv);
    final isSelected = invoice.isSelected;

    return RepaintBoundary(
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
        margin: EdgeInsets.only(
          bottom: context.responsiveSpacing(
            small: 16,
            medium: 18,
            large: 20,
            tablet: 22,
            veryNarrow: 12,
          ),
        ),
        decoration: BoxDecoration(
          color: context.cardBackgroundColor,
          borderRadius: BorderRadius.circular(28.r),
          gradient: isSelected 
              ? LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: context.isDarkMode 
                      ? [AppColors.deepGreen.withOpacity(0.15), context.cardBackgroundColor]
                      : [AppColors.deepGreen.withOpacity(0.08), context.cardBackgroundColor],
                )
              : null,
          boxShadow: [
            BoxShadow(
              color: isSelected 
                  ? AppColors.deepGreen.withOpacity(context.isDarkMode ? 0.2 : 0.1)
                  : Colors.black.withOpacity(context.isDarkMode ? 0.3 : 0.04),
              blurRadius: isSelected ? 24 : 20,
              offset: Offset(0, isSelected ? 8 : 4),
            ),
          ],
          border: Border.all(
            color: isSelected 
                ? AppColors.deepGreen.withOpacity(0.5)
                : context.isDarkMode
                    ? Colors.white.withOpacity(0.05)
                    : Colors.black.withOpacity(0.05),
            width: isSelected ? 1.5 : 1,
          ),
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onToggleExpand,
            borderRadius: BorderRadius.circular(28.r),
            child: Column(
              children: [
                Padding(
                  padding: EdgeInsets.all(20.w),
                  child: Column(
                    children: [
                      // Top Row: Date and Selection/Logo
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Row(
                              children: [
                                if (!isHistory && onToggleSelect != null && !invoice.isPaid) ...[
                                  GestureDetector(
                                    onTap: () {
                                      HapticFeedback.lightImpact();
                                      onToggleSelect!();
                                    },
                                    child: AnimatedContainer(
                                      duration: const Duration(milliseconds: 200),
                                      width: 24.w,
                                      height: 24.w,
                                      decoration: BoxDecoration(
                                        color: invoice.isSelected ? AppColors.deepGreen : Colors.transparent,
                                        borderRadius: BorderRadius.circular(8.r),
                                        border: Border.all(
                                          color: invoice.isSelected ? AppColors.deepGreen : context.textSecondaryColor.withOpacity(0.3),
                                          width: 2,
                                        ),
                                        boxShadow: invoice.isSelected ? [
                                          BoxShadow(
                                            color: AppColors.deepGreen.withOpacity(0.3),
                                            blurRadius: 8,
                                            offset: const Offset(0, 2),
                                          )
                                        ] : null,
                                      ),
                                      child: invoice.isSelected
                                          ? const Icon(Icons.check, color: Colors.white, size: 16)
                                          : null,
                                    ),
                                  ),
                                  SizedBox(width: 14.w),
                                ],
                                Container(
                                  width: 44.w,
                                  height: 44.w,
                                  decoration: BoxDecoration(
                                    gradient: LinearGradient(
                                      colors: [AppColors.deepGreen.withOpacity(0.2), AppColors.deepGreen.withOpacity(0.05)],
                                      begin: Alignment.topLeft,
                                      end: Alignment.bottomRight,
                                    ),
                                    shape: BoxShape.circle,
                                    border: Border.all(color: AppColors.deepGreen.withOpacity(0.1), width: 1),
                                  ),
                                  child: Center(
                                    child: Icon(Icons.receipt_long_rounded, color: AppColors.deepGreen, size: 22.sp),
                                  ),
                                ),
                                SizedBox(width: 14.w),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        invoice.displayName,
                                        style: TextStyle(
                                          color: context.textPrimaryColor,
                                          fontSize: 16.sp,
                                          fontWeight: FontWeight.w800,
                                          letterSpacing: -0.5,
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      SizedBox(height: 2.h),
                                      Text(
                                        invoice.formattedDate,
                                        style: TextStyle(
                                          color: context.textSecondaryColor,
                                          fontSize: 12.sp,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                          // Status Badge
                          Container(
                            padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 6.h),
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [statusColor.withOpacity(0.15), statusColor.withOpacity(0.05)],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                              borderRadius: BorderRadius.circular(100),
                              border: Border.all(color: statusColor.withOpacity(0.2), width: 0.5),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Container(
                                  width: 6.w,
                                  height: 6.w,
                                  decoration: BoxDecoration(color: statusColor, shape: BoxShape.circle),
                                ),
                                SizedBox(width: 6.w),
                                Text(
                                  statusLabel,
                                  style: TextStyle(
                                    color: statusColor,
                                    fontSize: 10.sp,
                                    fontWeight: FontWeight.w700,
                                    letterSpacing: 0.3,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      
                      if (invoice.bairNer.isNotEmpty || invoice.toot.isNotEmpty) ...[
                        SizedBox(height: 16.h),
                        Container(
                          padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 8.h),
                          decoration: BoxDecoration(
                            color: context.isDarkMode ? Colors.white.withOpacity(0.03) : Colors.black.withOpacity(0.02),
                            borderRadius: BorderRadius.circular(14.r),
                            border: Border.all(color: context.borderColor.withOpacity(0.2), width: 0.5),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.home_work_rounded, size: 14.sp, color: context.textSecondaryColor),
                              SizedBox(width: 8.w),
                              Text(
                                '${invoice.bairNer} - ${invoice.toot} тоот',
                                style: TextStyle(
                                  color: context.textPrimaryColor,
                                  fontSize: 11.sp,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],

                      SizedBox(height: 20.h),
                      
                      // Bottom Row: Amount and Expand Icon
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                invoice.isPaid ? 'Төлсөн дүн' : 'Нийт төлөх',
                                style: TextStyle(
                                  color: context.textSecondaryColor,
                                  fontSize: 11.sp,
                                  fontWeight: FontWeight.w600,
                                  letterSpacing: 0.5,
                                ),
                              ),
                              SizedBox(height: 4.h),
                              Text(
                                invoice.isPaid 
                                    ? '${formatNumber(invoice.displayNiitTulbur.abs(), 2)}₮' 
                                    : invoice.formattedAmount,
                                style: TextStyle(
                                  color: invoice.isPaid ? AppColors.deepGreen : context.textPrimaryColor,
                                  fontSize: 22.sp,
                                  fontWeight: FontWeight.w600,
                                  letterSpacing: -0.5,
                                ),
                              ),
                            ],
                          ),
                          Container(
                            padding: EdgeInsets.all(8.w),
                            decoration: BoxDecoration(
                              color: isSelected 
                                  ? AppColors.deepGreen.withOpacity(0.1)
                                  : context.isDarkMode ? Colors.white.withOpacity(0.05) : Colors.black.withOpacity(0.03),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              invoice.isExpanded ? Icons.keyboard_arrow_up_rounded : Icons.keyboard_arrow_down_rounded,
                              color: isSelected ? AppColors.deepGreen : context.textSecondaryColor,
                              size: 22.sp,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                if (invoice.isExpanded) ...[
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: 20.w),
                    child: Divider(height: 1, color: context.borderColor.withOpacity(0.3)),
                  ),
                  _buildExpandedSection(context),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildExpandedSection(BuildContext context) {
    final guilgeenuud = invoice.medeelel?.guilgeenuud?.where((g) {
          final baseAmt = (g.turul == 'tulult' || g.turul == 'buun_tulult')
              ? -(g.tulsunDun ?? 0.0)
              : (g.tulukhDun ?? g.undsenDun ?? g.dun ?? 0.0);
          return baseAmt != 0 &&
              !g.ekhniiUldegdelEsekh &&
              g.turul?.toLowerCase() != 'system_sync';
        }).toList() ??
        [];

    final additionalZardluud = invoice.medeelel?.zardluud.where((z) => z.isDisplayable && !z.isEkhniiUldegdel).toList() ?? [];

    return Padding(
      padding: EdgeInsets.all(20.w),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Detailed Location Info
          Container(
            padding: EdgeInsets.all(16.w),
            decoration: BoxDecoration(
              color: context.isDarkMode ? Colors.white.withOpacity(0.03) : Colors.black.withOpacity(0.02),
              borderRadius: BorderRadius.circular(20.r),
              border: Border.all(color: context.borderColor.withOpacity(0.1), width: 1),
            ),
            child: Column(
              children: [
                Row(
                  children: [
                    Icon(Icons.business_rounded, size: 18.sp, color: AppColors.deepGreen),
                    SizedBox(width: 10.w),
                    Expanded(
                      child: Text(
                        invoice.baiguullagiinNer,
                        style: TextStyle(color: context.textPrimaryColor, fontSize: 14.sp, fontWeight: FontWeight.w700),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 10.h),
                Row(
                  children: [
                    Icon(Icons.location_on_rounded, size: 18.sp, color: context.textSecondaryColor),
                    SizedBox(width: 10.w),
                    Expanded(
                      child: Text(
                        '${invoice.khayag}, ${invoice.orts}-р орц, ${invoice.medeelel?.toot ?? ""} тоот',
                        style: TextStyle(color: context.textSecondaryColor, fontSize: 13.sp, fontWeight: FontWeight.w500),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          SizedBox(height: 28.h),
          Row(
            children: [
              Container(
                width: 3.w,
                height: 12.h,
                decoration: BoxDecoration(color: AppColors.deepGreen, borderRadius: BorderRadius.circular(2)),
              ),
              SizedBox(width: 8.w),
              Text(
                'ТӨЛБӨРИЙН ДЭЛГЭРЭНГҮЙ',
                style: TextStyle(
                  color: context.textPrimaryColor,
                  fontSize: 11.sp,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 1.2,
                ),
              ),
            ],
          ),
          SizedBox(height: 16.h),
          // Starting Balance
          if ((invoice.ekhniiUldegdel ?? 0) != 0) ...[
            _buildModernChargeRow(context, 'Эхний үлдэгдэл', invoice.ekhniiUldegdel!, isStartingBalance: true),
            SizedBox(height: 12.h),
            Divider(height: 1, thickness: 1, color: context.borderColor.withOpacity(0.2)),
            SizedBox(height: 12.h),
          ],
          // Ledger Items
          ...guilgeenuud.asMap().entries.map((entry) {
            final idx = entry.key;
            final g = entry.value;
            final isPayment = (g.turul == 'tulult' || g.turul == 'buun_tulult');
            final label = isPayment
                ? 'Төлөлт'
                : (g.tailbar?.isNotEmpty ?? false)
                    ? g.tailbar!
                    : (g.zardliinNer?.isNotEmpty ?? false)
                        ? g.zardliinNer!
                        : 'Үйлчилгээний төлбөр';
            final amt = isPayment
                ? -(g.tulsunDun ?? 0.0)
                : (g.tulukhDun ?? g.undsenDun ?? g.dun ?? 0.0);
            return Column(
              children: [
                _buildModernChargeRow(context, label, amt),
                if (idx < guilgeenuud.length - 1 || additionalZardluud.isNotEmpty) 
                  Padding(
                    padding: EdgeInsets.symmetric(vertical: 12.h),
                    child: Divider(height: 1, thickness: 1, color: context.borderColor.withOpacity(0.1)),
                  ),
              ],
            );
          }),
          // Additional Charges
          ...additionalZardluud.asMap().entries.map((entry) {
            final idx = entry.key;
            final z = entry.value;
            return Column(
              children: [
                if (idx == 0 && guilgeenuud.isNotEmpty) 
                  Padding(
                    padding: EdgeInsets.symmetric(vertical: 12.h),
                    child: Divider(height: 1, thickness: 1, color: context.borderColor.withOpacity(0.1)),
                  ),
                _buildModernChargeRow(context, z.ner, z.displayAmount),
                if (idx < additionalZardluud.length - 1) 
                  Padding(
                    padding: EdgeInsets.symmetric(vertical: 12.h),
                    child: Divider(height: 1, thickness: 1, color: context.borderColor.withOpacity(0.1)),
                  ),
              ],
            );
          }),
          SizedBox(height: 32.h),
          // Final Total Section
          Container(
            padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 18.h),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: context.isDarkMode
                    ? [AppColors.deepGreen.withOpacity(0.2), AppColors.deepGreen.withOpacity(0.05)]
                    : [AppColors.deepGreen.withOpacity(0.1), AppColors.deepGreen.withOpacity(0.02)],
              ),
              borderRadius: BorderRadius.circular(20.r),
              border: Border.all(color: AppColors.deepGreen.withOpacity(0.3), width: 1),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'НИЙТ ТӨЛБӨР',
                  style: TextStyle(
                    color: context.textPrimaryColor,
                    fontSize: 13.sp,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.5,
                  ),
                ),
                Text(
                  '${formatNumber(invoice.displayNiitTulbur.abs(), 2)}₮',
                  style: TextStyle(
                    color: AppColors.deepGreen,
                    fontSize: 20.sp,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          if (isHistory && onShowVATReceipt != null) ...[
            SizedBox(height: 20.h),
            SizedBox(
              width: double.infinity,
              height: 56.h,
              child: ElevatedButton.icon(
                onPressed: onShowVATReceipt,
                icon: const Icon(Icons.receipt_long_rounded, size: 22, color: Colors.white),
                label: Text(
                  'И-БАРИМТ ХАРАХ',
                  style: TextStyle(color: Colors.white, fontSize: 13.sp, fontWeight: FontWeight.w900, letterSpacing: 1.0),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.deepGreen,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18.r)),
                  elevation: 8,
                  shadowColor: AppColors.deepGreen.withOpacity(0.4),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildModernChargeRow(BuildContext context, String label, double amount, {bool isStartingBalance = false}) {
    final isNegative = amount < 0;
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          child: Text(
            label,
            style: TextStyle(
              color: isStartingBalance ? context.textPrimaryColor : context.textSecondaryColor,
              fontSize: 14.sp,
              fontWeight: isStartingBalance ? FontWeight.w600 : FontWeight.w500,
            ),
          ),
        ),
        Text(
          '${formatNumber(amount.abs(), 2)}₮',
          style: TextStyle(
            color: isNegative ? AppColors.deepGreen : context.textPrimaryColor,
            fontSize: 15.sp,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}
