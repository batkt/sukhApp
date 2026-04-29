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

    return RepaintBoundary(
      child: Container(
        margin: EdgeInsets.only(
          bottom: context.responsiveSpacing(
            small: 12,
            medium: 14,
            large: 16,
            tablet: 18,
            veryNarrow: 10,
          ),
        ),
        decoration: BoxDecoration(
          color: context.cardBackgroundColor,
          borderRadius: BorderRadius.circular(20.r),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(context.isDarkMode ? 0.3 : 0.04),
              blurRadius: 20,
              offset: const Offset(0, 4),
            ),
          ],
          border: Border.all(
            color: context.isDarkMode
                ? Colors.white.withOpacity(0.05)
                : Colors.black.withOpacity(0.05),
            width: 1,
          ),
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onToggleExpand,
            borderRadius: BorderRadius.circular(20.r),
            child: Column(
              children: [
                Padding(
                  padding: EdgeInsets.all(16.w),
                  child: Column(
                    children: [
                      // Top Row: Date and Selection/Logo
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              if (!isHistory && onToggleSelect != null && !invoice.isPaid) ...[
                                GestureDetector(
                                  onTap: () {
                                    HapticFeedback.lightImpact();
                                    onToggleSelect!();
                                  },
                                  child: AnimatedContainer(
                                    duration: const Duration(milliseconds: 200),
                                    width: 22.w,
                                    height: 22.w,
                                    decoration: BoxDecoration(
                                      color: invoice.isSelected ? AppColors.deepGreen : Colors.transparent,
                                      borderRadius: BorderRadius.circular(6.r),
                                      border: Border.all(
                                        color: invoice.isSelected ? AppColors.deepGreen : context.textSecondaryColor.withOpacity(0.3),
                                        width: 2,
                                      ),
                                    ),
                                    child: invoice.isSelected
                                        ? const Icon(Icons.check, color: Colors.white, size: 14)
                                        : null,
                                  ),
                                ),
                                SizedBox(width: 12.w),
                              ],
                              Container(
                                width: 40.w,
                                height: 40.w,
                                decoration: BoxDecoration(
                                  color: AppColors.deepGreen.withOpacity(0.1),
                                  shape: BoxShape.circle,
                                ),
                                child: ClipOval(
                                  child: SelectableLogoImage(
                                    width: 40.w,
                                    height: 40.w,
                                    fit: BoxFit.cover,
                                  ),
                                ),
                              ),
                              SizedBox(width: 12.w),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    invoice.displayName,
                                    style: TextStyle(
                                      color: context.textPrimaryColor,
                                      fontSize: 15.sp,
                                      fontWeight: FontWeight.w600,
                                      letterSpacing: -0.3,
                                    ),
                                  ),
                                  Text(
                                    invoice.formattedDate,
                                    style: TextStyle(
                                      color: context.textSecondaryColor,
                                      fontSize: 12.sp,
                                      fontWeight: FontWeight.w400,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                          // Status Badge
                          Container(
                            padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 4.h),
                            decoration: BoxDecoration(
                              color: statusColor.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(100),
                            ),
                            child: Text(
                              statusLabel,
                              style: TextStyle(
                                color: statusColor,
                                fontSize: 11.sp,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 16.h),
                      // Bottom Row: Amount and Expand Icon
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Нийт төлөх',
                                style: TextStyle(
                                  color: context.textSecondaryColor,
                                  fontSize: 12.sp,
                                ),
                              ),
                              Text(
                                invoice.formattedAmount,
                                style: TextStyle(
                                  color: context.textPrimaryColor,
                                  fontSize: 18.sp,
                                  fontWeight: FontWeight.w700,
                                  letterSpacing: -0.5,
                                ),
                              ),
                            ],
                          ),
                          Container(
                            padding: EdgeInsets.all(4.w),
                            decoration: BoxDecoration(
                              color: context.isDarkMode ? Colors.white.withOpacity(0.05) : Colors.black.withOpacity(0.03),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              invoice.isExpanded ? Icons.keyboard_arrow_up_rounded : Icons.keyboard_arrow_down_rounded,
                              color: context.textSecondaryColor,
                              size: 20.sp,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                if (invoice.isExpanded) ...[
                  Divider(height: 1, color: context.borderColor.withOpacity(0.5)),
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
          // Use 'dun' or negative 'tulsunDun' for payments, otherwise use charge amount
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
      padding: EdgeInsets.all(16.w),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Detailed Location Info
          Container(
            padding: EdgeInsets.all(12.w),
            decoration: BoxDecoration(
              color: context.isDarkMode ? Colors.white.withOpacity(0.03) : Colors.black.withOpacity(0.02),
              borderRadius: BorderRadius.circular(16.r),
            ),
            child: Column(
              children: [
                Row(
                  children: [
                    Icon(Icons.business_rounded, size: 16.sp, color: AppColors.deepGreen),
                    SizedBox(width: 8.w),
                    Expanded(
                      child: Text(
                        invoice.baiguullagiinNer,
                        style: TextStyle(color: context.textPrimaryColor, fontSize: 13.sp, fontWeight: FontWeight.w600),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 8.h),
                Row(
                  children: [
                    Icon(Icons.location_on_rounded, size: 16.sp, color: context.textSecondaryColor),
                    SizedBox(width: 8.w),
                    Expanded(
                      child: Text(
                        '${invoice.khayag}, ${invoice.orts}-р орц, ${invoice.medeelel?.toot ?? ""} тоот',
                        style: TextStyle(color: context.textSecondaryColor, fontSize: 12.sp),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          SizedBox(height: 24.h),
          Text(
            'ТӨЛБӨРИЙН ДЭЛГЭРЭНГҮЙ',
            style: TextStyle(
              color: context.textSecondaryColor.withOpacity(0.6),
              fontSize: 10.sp,
              fontWeight: FontWeight.w800,
              letterSpacing: 1.5,
            ),
          ),
          SizedBox(height: 12.h),
          // Starting Balance
          if ((invoice.ekhniiUldegdel ?? 0) != 0) ...[
            _buildModernChargeRow(context, 'Эхний үлдэгдэл', invoice.ekhniiUldegdel!, isStartingBalance: true),
            Divider(height: 24.h, thickness: 1, color: context.borderColor.withOpacity(0.3)),
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
                if (idx < guilgeenuud.length - 1 || additionalZardluud.isNotEmpty) Divider(height: 20.h, thickness: 1, color: context.borderColor.withOpacity(0.3)),
              ],
            );
          }),
          // Additional Charges
          ...additionalZardluud.asMap().entries.map((entry) {
            final idx = entry.key;
            final z = entry.value;
            return Column(
              children: [
                if (idx == 0 && guilgeenuud.isNotEmpty) Divider(height: 20.h, thickness: 1, color: context.borderColor.withOpacity(0.3)),
                _buildModernChargeRow(context, z.ner, z.displayAmount),
                if (idx < additionalZardluud.length - 1) Divider(height: 20.h, thickness: 1, color: context.borderColor.withOpacity(0.3)),
              ],
            );
          }),
          SizedBox(height: 24.h),
          // Final Total Section
          Container(
            padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 14.h),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: context.isDarkMode
                    ? [Colors.white.withOpacity(0.08), Colors.white.withOpacity(0.03)]
                    : [Colors.black.withOpacity(0.04), Colors.black.withOpacity(0.01)],
              ),
              borderRadius: BorderRadius.circular(16.r),
              border: Border.all(color: AppColors.deepGreen.withOpacity(0.1)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'НИЙТ ТӨЛБӨР',
                  style: TextStyle(
                    color: context.textPrimaryColor,
                    fontSize: 12.sp,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.5,
                  ),
                ),
                Text(
                  invoice.formattedAmount,
                  style: TextStyle(
                    color: AppColors.deepGreen,
                    fontSize: 18.sp,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
          ),
          if (isHistory && onShowVATReceipt != null) ...[
            SizedBox(height: 16.h),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: onShowVATReceipt,
                icon: const Icon(Icons.receipt_long_rounded, size: 18),
                label: const Text('И-Баримт харах'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.deepGreen,
                  foregroundColor: Colors.white,
                  padding: EdgeInsets.symmetric(vertical: 14.h),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16.r)),
                  elevation: 4,
                  shadowColor: AppColors.deepGreen.withOpacity(0.3),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildModernChargeRow(BuildContext context, String label, double amount, {bool isStartingBalance = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          child: Text(
            label,
            style: TextStyle(
              color: isStartingBalance ? context.textPrimaryColor : context.textSecondaryColor,
              fontSize: 13.sp,
              fontWeight: isStartingBalance ? FontWeight.w600 : FontWeight.w500,
            ),
          ),
        ),
        Text(
          '${formatNumber(amount, 2)}₮',
          style: TextStyle(
            color: context.textPrimaryColor,
            fontSize: 14.sp,
            fontWeight: FontWeight.w700,
            fontFamily: 'Roboto', // Mono-like spacing for numbers if available
          ),
        ),
      ],
    );
  }
}
