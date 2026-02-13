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
        return AppColors.success;
      case 'Төлөөгүй':
        return AppColors.warning;
      default:
        return AppColors.neutralGray;
    }
  }

  String _getStatusLabel(String status) {
    switch (status) {
      case 'Төлсөн':
        return 'Төлөгдсөн';
      case 'Төлөөгүй':
        return 'Хүлээгдэж байгаа';
      default:
        return status;
    }
  }

  @override
  Widget build(BuildContext context) {
    final statusColor = _getStatusColor(invoice.tuluv);
    final statusLabel = _getStatusLabel(invoice.tuluv);

    return RepaintBoundary(
      child: Container(
        margin: EdgeInsets.only(bottom: context.responsiveSpacing(
          small: 10,
          medium: 12,
          large: 14,
          tablet: 16,
          veryNarrow: 8,
        )),
        child: Container(
          decoration: BoxDecoration(
            color: context.isDarkMode
                ? const Color(0xFF1E1E1E)
                : Colors.white,
            borderRadius: BorderRadius.circular(context.responsiveBorderRadius(
              small: 16,
              medium: 18,
              large: 20,
              tablet: 22,
              veryNarrow: 14,
            )),
            border: Border.all(
              color: context.isDarkMode
                  ? Colors.white.withOpacity(0.08)
                  : Colors.black.withOpacity(0.06),
              width: 1,
            ),
            boxShadow: [
              BoxShadow(
                color: context.isDarkMode
                    ? Colors.black.withOpacity(0.3)
                    : Colors.black.withOpacity(0.04),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: onToggleExpand,
              borderRadius: BorderRadius.circular(context.responsiveBorderRadius(
                small: 16,
                medium: 18,
                large: 20,
                tablet: 22,
                veryNarrow: 14,
              )),
              child: Padding(
                padding: EdgeInsets.all(context.responsiveSpacing(
                  small: 14,
                  medium: 16,
                  large: 18,
                  tablet: 20,
                  veryNarrow: 12,
                )),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Main card content
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Date row
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              invoice.formattedDate,
                              style: TextStyle(
                                color: context.textSecondaryColor,
                                fontSize: context.responsiveFontSize(
                                  small: 13,
                                  medium: 14,
                                  large: 15,
                                  tablet: 16,
                                  veryNarrow: 12,
                                ),
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            // Status tag
                            Container(
                              padding: EdgeInsets.symmetric(
                                horizontal: context.responsiveSpacing(
                                  small: 10,
                                  medium: 12,
                                  large: 14,
                                  tablet: 16,
                                  veryNarrow: 8,
                                ),
                                vertical: context.responsiveSpacing(
                                  small: 5,
                                  medium: 6,
                                  large: 7,
                                  tablet: 8,
                                  veryNarrow: 4,
                                ),
                              ),
                              decoration: BoxDecoration(
                                color: statusColor.withOpacity(context.isDarkMode ? 0.2 : 0.1),
                                borderRadius: BorderRadius.circular(context.responsiveBorderRadius(
                                  small: 20,
                                  medium: 22,
                                  large: 24,
                                  tablet: 26,
                                  veryNarrow: 18,
                                )),
                              ),
                              child: Text(
                                statusLabel,
                                style: TextStyle(
                                  color: statusColor,
                                  fontSize: context.responsiveFontSize(
                                    small: 12,
                                    medium: 13,
                                    large: 14,
                                    tablet: 15,
                                    veryNarrow: 11,
                                  ),
                                  fontWeight: FontWeight.w600,
                                  letterSpacing: 0.3,
                                ),
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: context.responsiveSpacing(
                          small: 12,
                          medium: 14,
                          large: 16,
                          tablet: 18,
                          veryNarrow: 10,
                        )),
                        // Main content row
                        Row(
                          children: [
                            // Company logo
                            Container(
                              width: context.responsiveSpacing(
                                small: 44,
                                medium: 48,
                                large: 52,
                                tablet: 56,
                                veryNarrow: 40,
                              ),
                              height: context.responsiveSpacing(
                                small: 44,
                                medium: 48,
                                large: 52,
                                tablet: 56,
                                veryNarrow: 40,
                              ),
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                  colors: [
                                    AppColors.deepGreen,
                                    AppColors.deepGreen.withOpacity(0.8),
                                  ],
                                ),
                                shape: BoxShape.circle,
                              ),
                              child: ClipOval(
                                child: SelectableLogoImage(
                                  width: context.responsiveSpacing(
                                    small: 44,
                                    medium: 48,
                                    large: 52,
                                    tablet: 56,
                                    veryNarrow: 40,
                                  ),
                                  height: context.responsiveSpacing(
                                    small: 44,
                                    medium: 48,
                                    large: 52,
                                    tablet: 56,
                                    veryNarrow: 40,
                                  ),
                                  fit: BoxFit.cover,
                                ),
                              ),
                            ),
                            SizedBox(width: context.responsiveSpacing(
                              small: 12,
                              medium: 14,
                              large: 16,
                              tablet: 18,
                              veryNarrow: 10,
                            )),
                            // Client info
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    invoice.displayName,
                                    style: TextStyle(
                                      color: context.textPrimaryColor,
                                      fontSize: context.responsiveFontSize(
                                        small: 16,
                                        medium: 17,
                                        large: 18,
                                        tablet: 19,
                                        veryNarrow: 14,
                                      ),
                                      fontWeight: FontWeight.w600,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  SizedBox(height: 3.h),
                                  SizedBox(height: 3.h),
                                ],
                              ),
                            ),
                            // Amount
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Text(
                                  invoice.formattedAmount,
                                  style: TextStyle(
                                    color: AppColors.deepGreen,
                                    fontSize: context.responsiveFontSize(
                                      small: 17,
                                      medium: 18,
                                      large: 19,
                                      tablet: 21,
                                      veryNarrow: 15,
                                    ),
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                                if (!isHistory) SizedBox(height: 6.h),
                                // Checkbox for selection (only in non-history mode)
                                if (!isHistory && onToggleSelect != null)
                                  Material(
                                    color: Colors.transparent,
                                    child: InkWell(
                                      onTap: () {
                                        HapticFeedback.lightImpact();
                                        onToggleSelect!();
                                      },
                                      borderRadius: BorderRadius.circular(6.w),
                                      splashColor: AppColors.deepGreen
                                          .withOpacity(0.3),
                                      highlightColor: AppColors.deepGreen
                                          .withOpacity(0.1),
                                      child: AnimatedContainer(
                                        duration: const Duration(
                                          milliseconds: 300,
                                        ),
                                        curve: Curves.easeInOutCubic,
                                        width: 22.w,
                                        height: 22.w,
                                        decoration: BoxDecoration(
                                          gradient: invoice.isSelected
                                              ? LinearGradient(
                                                  colors: [
                                                    AppColors.secondaryAccent,
                                                    AppColors.secondaryAccent
                                                        .withOpacity(0.8),
                                                  ],
                                                  begin: Alignment.topLeft,
                                                  end: Alignment.bottomRight,
                                                )
                                              : null,
                                          color: invoice.isSelected
                                              ? null
                                              : Colors.transparent,
                                          border: Border.all(
                                            color: invoice.isSelected
                                                ? AppColors.deepGreen
                                                : context.borderColor,
                                            width: invoice.isSelected ? 2.5 : 2,
                                          ),
                                          borderRadius: BorderRadius.circular(
                                            6.w,
                                          ),
                                          boxShadow: invoice.isSelected
                                              ? [
                                                  BoxShadow(
                                                    color: AppColors.deepGreen
                                                        .withOpacity(0.2),
                                                    blurRadius: 8,
                                                    spreadRadius: 0,
                                                    offset: const Offset(0, 2),
                                                  ),
                                                ]
                                              : null,
                                        ),
                                        child: Center(
                                          child: AnimatedScale(
                                            scale: invoice.isSelected
                                                ? 1.0
                                                : 0.0,
                                            duration: const Duration(
                                              milliseconds: 250,
                                            ),
                                            curve: Curves.elasticOut,
                                            child: invoice.isSelected
                                                ? Icon(
                                                    Icons.check_rounded,
                                                    color: Colors.white,
                                                    size: context.responsiveFontSize(
                                                      small: 16,
                                                      medium: 17,
                                                      large: 18,
                                                      tablet: 20,
                                                      veryNarrow: 14,
                                                    ),
                                                    weight: 3,
                                                  )
                                                : const SizedBox.shrink(),
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                          ],
                        ),
                        // Expand/Collapse indicator
                        Padding(
                          padding: EdgeInsets.only(top: context.responsiveSpacing(
                            small: 8,
                            medium: 10,
                            large: 12,
                            tablet: 14,
                            veryNarrow: 6,
                          )),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Container(
                                padding: EdgeInsets.symmetric(
                                  horizontal: context.responsiveSpacing(
                                    small: 12,
                                    medium: 14,
                                    large: 16,
                                    tablet: 18,
                                    veryNarrow: 10,
                                  ),
                                  vertical: context.responsiveSpacing(
                                    small: 4,
                                    medium: 5,
                                    large: 6,
                                    tablet: 7,
                                    veryNarrow: 3,
                                  ),
                                ),
                                decoration: BoxDecoration(
                                  color: context.isDarkMode
                                      ? Colors.white.withOpacity(0.06)
                                      : Colors.black.withOpacity(0.04),
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Icon(
                                  invoice.isExpanded
                                      ? Icons.keyboard_arrow_up_rounded
                                      : Icons.keyboard_arrow_down_rounded,
                                  color: context.isDarkMode
                                      ? Colors.white.withOpacity(0.6)
                                      : Colors.black.withOpacity(0.5),
                                  size: context.responsiveFontSize(
                                    small: 18,
                                    medium: 20,
                                    large: 22,
                                    tablet: 24,
                                    veryNarrow: 16,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    // Expanded details section
                    if (invoice.isExpanded) _buildExpandedSection(context),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildExpandedSection(BuildContext context) {
    final toot = invoice.medeelel?.toot ?? '';
    return Container(
      padding: EdgeInsets.all(context.responsiveSpacing(
        small: 8,
        medium: 10,
        large: 12,
        tablet: 14,
        veryNarrow: 6,
      )),
      decoration: BoxDecoration(color: Colors.transparent),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Үйлчилгээний нэхэмжлэх header
          Padding(
            padding: EdgeInsets.only(bottom: context.responsiveSpacing(
              small: 8,
              medium: 10,
              large: 12,
              tablet: 14,
              veryNarrow: 6,
            )),
            child: Text(
              'Үйлчилгээний нэхэмжлэх',
              style: TextStyle(
                color: AppColors.deepGreen,
                fontSize: context.responsiveFontSize(
                  small: 14,
                  medium: 15,
                  large: 16,
                  tablet: 17,
                  veryNarrow: 13,
                ),
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          // Нэхэмжлэгч (left) and Төлөгч (right) sections
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Left: Нэхэмжлэгч - Байгууллагын мэдээлэл
              Expanded(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(context.responsiveBorderRadius(
                    small: 8,
                    medium: 10,
                    large: 12,
                    tablet: 14,
                    veryNarrow: 6,
                  )),
                  child: Container(
                    padding: EdgeInsets.all(context.responsiveSpacing(
                      small: 8,
                      medium: 10,
                      large: 12,
                      tablet: 14,
                      veryNarrow: 6,
                    )),
                    decoration: BoxDecoration(
                      color: context.isDarkMode
                          ? Colors.white.withOpacity(0.05)
                          : const Color(0xFFF8F8F8),
                      borderRadius: BorderRadius.circular(context.responsiveBorderRadius(
                        small: 8,
                        medium: 10,
                        large: 12,
                        tablet: 14,
                        veryNarrow: 6,
                      )),
                      border: Border.all(
                        color: context.isDarkMode
                            ? AppColors.deepGreen.withOpacity(0.15)
                            : AppColors.deepGreen.withOpacity(0.1),
                        width: 1,
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        _buildInfoRow(context, 'Нэхэмжлэгч:', invoice.baiguullagiinNer),
                        _buildInfoRow(context, 'Утас:', invoice.baiguullagiinUtas),
                        _buildInfoRow(context, 'Хаяг:', invoice.baiguullagiinKhayag),
                        _buildInfoRow(context, 'Данс:', invoice.dansniiDugaar),
                      ],
                    ),
                  ),
                ),
              ),
              SizedBox(width: context.responsiveSpacing(
                small: 6,
                medium: 8,
                large: 10,
                tablet: 12,
                veryNarrow: 4,
              )),
              // Right: Төлөгч - Оршин суугчийн мэдээлэл
              Expanded(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(context.responsiveBorderRadius(
                    small: 8,
                    medium: 10,
                    large: 12,
                    tablet: 14,
                    veryNarrow: 6,
                  )),
                  child: Container(
                    padding: EdgeInsets.all(context.responsiveSpacing(
                      small: 8,
                      medium: 10,
                      large: 12,
                      tablet: 14,
                      veryNarrow: 6,
                    )),
                    decoration: BoxDecoration(
                      color: context.isDarkMode
                          ? Colors.white.withOpacity(0.04)
                          : const Color(0xFFF5F5F5),
                      borderRadius: BorderRadius.circular(context.responsiveBorderRadius(
                        small: 8,
                        medium: 10,
                        large: 12,
                        tablet: 14,
                        veryNarrow: 6,
                      )),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        _buildInfoRow(context, 'Төлөгч:', invoice.displayName),
                        _buildInfoRow(context, 'Байр:', invoice.khayag),
                        _buildInfoRow(context, 'Орц:', invoice.orts),
                        _buildInfoRow(context, 'Тоот:', toot),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: context.responsiveSpacing(
            small: 10,
            medium: 12,
            large: 14,
            tablet: 16,
            veryNarrow: 8,
          )),
          // Ekhnii үлдэгдэл from guilgeenuud (floating/merged items NOT in zardluud)
          if (invoice.medeelel?.guilgeenuud != null) ...[
            ...invoice.medeelel!.guilgeenuud!
                .where((guilgee) => guilgee.ekhniiUldegdelEsekh && !guilgee.isLinked)
                .map((guilgee) {
                  final amt = (guilgee.tulukhDun ?? guilgee.undsenDun ?? 0.0) -
                      (guilgee.tulsunDun ?? 0.0);
                  if (amt == 0) return const SizedBox.shrink();
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SizedBox(height: context.responsiveSpacing(
                        small: 6,
                        medium: 8,
                        large: 10,
                        tablet: 12,
                        veryNarrow: 4,
                      )),
                      _buildPriceRow(
                        context,
                        'Эхний үлдэгдэл',
                        '${formatNumber(amt, 2)}₮',
                      ),
                    ],
                  );
                }),
          ],
          // Support dedicated ekhniiUldegdel field ONLY if not found in zardluud/guilgeenuud
          if (invoice.ekhniiUldegdel != null &&
              invoice.ekhniiUldegdel! != 0 &&
              !(invoice.medeelel?.zardluud.any((z) => z.isEkhniiUldegdel) ?? false) &&
              !(invoice.medeelel?.guilgeenuud?.any((g) => g.ekhniiUldegdelEsekh) ?? false)) ...[
            _buildPriceRow(
              context,
              'Эхний үлдэгдэл',
              '${formatNumber(invoice.ekhniiUldegdel!, 2)}₮',
            ),
          ],
          // Avlaga items from guilgeenuud (exclude ekhniiUldegdel - shown above)
          // Match both "avlaga" and "Авлага" (API may return either)
          if (invoice.medeelel != null &&
              invoice.medeelel!.guilgeenuud != null) ...[
            ...invoice.medeelel!.guilgeenuud!
                .where((guilgee) {
                  final t = guilgee.turul?.toLowerCase() ?? '';
                  return (t == 'avlaga' || t == 'авлага') && !guilgee.ekhniiUldegdelEsekh;
                })
                .map((guilgee) {
                  // Use tulukhDun or undsenDun (API may use either for avlaga amount)
                  final amt = (guilgee.tulukhDun ?? guilgee.undsenDun ?? 0.0);
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SizedBox(height: context.responsiveSpacing(
                        small: 6,
                        medium: 8,
                        large: 10,
                        tablet: 12,
                        veryNarrow: 4,
                      )),
                      if (amt > 0) ...[
                        _buildPriceRow(
                          context,
                          'Авлага',
                          '${formatNumber(amt, 2)}₮',
                        ),
                      ],
                      if (guilgee.tailbar != null &&
                          guilgee.tailbar!.isNotEmpty) ...[
                        SizedBox(height: context.responsiveSpacing(
                          small: 4,
                          medium: 6,
                          large: 8,
                          tablet: 10,
                          veryNarrow: 3,
                        )),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(context.responsiveBorderRadius(
                            small: 8,
                            medium: 10,
                            large: 12,
                            tablet: 14,
                            veryNarrow: 6,
                          )),
                          child: Container(
                            padding: EdgeInsets.all(context.responsiveSpacing(
                              small: 8,
                              medium: 10,
                              large: 12,
                              tablet: 14,
                              veryNarrow: 6,
                            )),
                            decoration: BoxDecoration(
                              color: context.isDarkMode
                                  ? Colors.white.withOpacity(0.04)
                                  : const Color(0xFFF5F5F5),
                              borderRadius: BorderRadius.circular(context.responsiveBorderRadius(
                                small: 8,
                                medium: 10,
                                large: 12,
                                tablet: 14,
                                veryNarrow: 6,
                              )),
                            ),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Icon(
                                  Icons.info_outline_rounded,
                                  color: context.isDarkMode
                                      ? Colors.blue.shade300
                                      : Colors.blue.shade600,
                                  size: context.responsiveFontSize(
                                    small: 14,
                                    medium: 16,
                                    large: 18,
                                    tablet: 20,
                                    veryNarrow: 12,
                                  ),
                                ),
                                SizedBox(width: context.responsiveSpacing(
                                  small: 4,
                                  medium: 6,
                                  large: 8,
                                  tablet: 10,
                                  veryNarrow: 3,
                                )),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Авлагын шалтгаан:',
                                        style: TextStyle(
                                          color: context.isDarkMode
                                              ? Colors.blue.shade300
                                              : Colors.blue.shade600,
                                          fontSize: context.responsiveFontSize(
                                            small: 12,
                                            medium: 13,
                                            large: 14,
                                            tablet: 15,
                                            veryNarrow: 11,
                                          ),
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                      SizedBox(height: context.responsiveSpacing(
                                        small: 2,
                                        medium: 3,
                                        large: 4,
                                        tablet: 5,
                                        veryNarrow: 1,
                                      )),
                                      Text(
                                        guilgee.tailbar!,
                                        style: TextStyle(
                                          color: context.textPrimaryColor,
                                          fontSize: context.responsiveFontSize(
                                            small: 12,
                                            medium: 13,
                                            large: 14,
                                            tablet: 15,
                                            veryNarrow: 11,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ],
                  );
                }),
          ],
          // AshiglaltiinZardal items from zardluud (Тогтмол, Дурын, Эхний үлдэгдэл, цахилгаан)
          if (invoice.medeelel != null) ...[
            if (invoice.medeelel!.zardluud.isNotEmpty) ...[
              ...invoice.medeelel!.zardluud
                  .where((zardal) => zardal.isDisplayable)
                  .map((zardal) {
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        SizedBox(height: context.responsiveSpacing(
                          small: 6,
                          medium: 8,
                          large: 10,
                          tablet: 12,
                          veryNarrow: 4,
                        )),
                        _buildPriceRow(
                          context,
                          zardal.ner,
                          zardal.formattedDisplayAmount,
                        ),
                        if (zardal.turul.isNotEmpty) ...[
                          SizedBox(height: context.responsiveSpacing(
                            small: 2,
                            medium: 3,
                            large: 4,
                            tablet: 5,
                            veryNarrow: 1,
                          )),
                          Padding(
                            padding: EdgeInsets.only(left: context.responsiveSpacing(
                              small: 10,
                              medium: 12,
                              large: 14,
                              tablet: 16,
                              veryNarrow: 8,
                            )),
                            child: Text(
                              'Төрөл: ${zardal.turul}',
                              style: TextStyle(
                                color: context.textSecondaryColor,
                                fontSize: context.responsiveFontSize(
                                  small: 11,
                                  medium: 12,
                                  large: 13,
                                  tablet: 14,
                                  veryNarrow: 10,
                                ),
                                fontStyle: FontStyle.italic,
                              ),
                            ),
                          ),
                        ],
                      ],
                    );
                  }),
            ],
          ],
          // Tailbar field
          if (invoice.medeelel != null &&
              invoice.medeelel!.tailbar != null &&
              invoice.medeelel!.tailbar!.isNotEmpty) ...[
            SizedBox(height: context.responsiveSpacing(
              small: 10,
              medium: 12,
              large: 14,
              tablet: 16,
              veryNarrow: 8,
            )),
            ClipRRect(
              borderRadius: BorderRadius.circular(context.responsiveBorderRadius(
                small: 8,
                medium: 10,
                large: 12,
                tablet: 14,
                veryNarrow: 6,
              )),
              child: Container(
                padding: EdgeInsets.all(context.responsiveSpacing(
                  small: 8,
                  medium: 10,
                  large: 12,
                  tablet: 14,
                  veryNarrow: 6,
                )),
                decoration: BoxDecoration(
                  color: context.isDarkMode
                      ? Colors.white.withOpacity(0.04)
                      : const Color(0xFFF8F8F8),
                  borderRadius: BorderRadius.circular(context.responsiveBorderRadius(
                    small: 8,
                    medium: 10,
                    large: 12,
                    tablet: 14,
                    veryNarrow: 6,
                  )),
                  border: Border.all(
                    color: context.isDarkMode
                        ? Colors.white.withOpacity(0.12)
                        : AppColors.deepGreen.withOpacity(0.15),
                    width: 1,
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.note_outlined,
                          color: AppColors.deepGreen,
                          size: context.responsiveFontSize(
                            small: 14,
                            medium: 16,
                            large: 18,
                            tablet: 20,
                            veryNarrow: 12,
                          ),
                        ),
                        SizedBox(width: context.responsiveSpacing(
                          small: 3,
                          medium: 4,
                          large: 5,
                          tablet: 6,
                          veryNarrow: 2,
                        )),
                        Text(
                          'Тайлбар',
                          style: TextStyle(
                            color: AppColors.deepGreen,
                            fontSize: context.responsiveFontSize(
                              small: 12,
                              medium: 13,
                              large: 14,
                              tablet: 15,
                              veryNarrow: 11,
                            ),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: context.responsiveSpacing(
                      small: 4,
                      medium: 5,
                      large: 6,
                      tablet: 8,
                      veryNarrow: 3,
                    )),
                    Text(
                      invoice.medeelel!.tailbar!,
                      style: TextStyle(
                        color: context.textPrimaryColor,
                        fontSize: context.responsiveFontSize(
                          small: 12,
                          medium: 13,
                          large: 14,
                          tablet: 15,
                          veryNarrow: 11,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
          SizedBox(height: context.responsiveSpacing(
            small: 10,
            medium: 12,
            large: 14,
            tablet: 16,
            veryNarrow: 8,
          )),
          // Total amount
          ClipRRect(
            borderRadius: BorderRadius.circular(context.responsiveBorderRadius(
              small: 8,
              medium: 10,
              large: 12,
              tablet: 14,
              veryNarrow: 6,
            )),
            child: Container(
              padding: EdgeInsets.all(context.responsiveSpacing(
                small: 10,
                medium: 12,
                large: 14,
                tablet: 16,
                veryNarrow: 8,
              )),
              decoration: BoxDecoration(
                color: context.isDarkMode
                    ? Colors.white.withOpacity(0.04)
                    : const Color(0xFFF8F8F8),
                borderRadius: BorderRadius.circular(context.responsiveBorderRadius(
                  small: 8,
                  medium: 10,
                  large: 12,
                  tablet: 14,
                  veryNarrow: 6,
                )),
                border: Border.all(
                  color: context.isDarkMode
                      ? Colors.white.withOpacity(0.12)
                      : AppColors.deepGreen.withOpacity(0.15),
                  width: 1,
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Нийт дүн:',
                    style: TextStyle(
                      color: context.textPrimaryColor,
                      fontSize: context.responsiveFontSize(
                        small: 14,
                        medium: 15,
                        large: 16,
                        tablet: 17,
                        veryNarrow: 12,
                      ),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Text(
                    invoice.formattedAmount,
                    style: TextStyle(
                      color: AppColors.deepGreen,
                      fontSize: context.responsiveFontSize(
                        small: 16,
                        medium: 17,
                        large: 18,
                        tablet: 20,
                        veryNarrow: 14,
                      ),
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (isHistory && onShowVATReceipt != null) ...[
            SizedBox(height: context.responsiveSpacing(
              small: 8,
              medium: 10,
              large: 12,
              tablet: 14,
              veryNarrow: 6,
            )),
            ClipRRect(
              borderRadius: BorderRadius.circular(context.responsiveBorderRadius(
                small: 8,
                medium: 10,
                large: 12,
                tablet: 14,
                veryNarrow: 6,
              )),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: onShowVATReceipt,
                  borderRadius: BorderRadius.circular(context.responsiveBorderRadius(
                    small: 8,
                    medium: 10,
                    large: 12,
                    tablet: 14,
                    veryNarrow: 6,
                  )),
                  child: Container(
                    width: double.infinity,
                    padding: EdgeInsets.symmetric(vertical: context.responsiveSpacing(
                      small: 8,
                      medium: 10,
                      large: 12,
                      tablet: 14,
                      veryNarrow: 6,
                    )),
                    decoration: BoxDecoration(
                      color: AppColors.deepGreen,
                      borderRadius: BorderRadius.circular(context.responsiveBorderRadius(
                        small: 8,
                        medium: 10,
                        large: 12,
                        tablet: 14,
                        veryNarrow: 6,
                      )),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.receipt_long_rounded,
                          size: context.responsiveFontSize(
                            small: 14,
                            medium: 16,
                            large: 18,
                            tablet: 20,
                            veryNarrow: 12,
                          ),
                          color: Colors.white,
                        ),
                        SizedBox(width: context.responsiveSpacing(
                          small: 4,
                          medium: 6,
                          large: 8,
                          tablet: 10,
                          veryNarrow: 3,
                        )),
                        Text(
                          'Баримт харах',
                          style: TextStyle(
                            fontSize: context.responsiveFontSize(
                              small: 13,
                              medium: 14,
                              large: 15,
                              tablet: 16,
                              veryNarrow: 12,
                            ),
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildInfoText(BuildContext context, String text) {
    return Padding(
      padding: EdgeInsets.only(
        bottom: isVerySmallScreen ? 4 : (isSmallScreen ? 5 : 6),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: context.textPrimaryColor,
          fontSize: context.responsiveFontSize(
            small: 13,
            medium: 14,
            large: 15,
            tablet: 16,
            veryNarrow: 11,
          ),
          height: 1.3,
        ),
      ),
    );
  }

  Widget _buildInfoRow(BuildContext context, String label, String value) {
    if (value.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: EdgeInsets.only(
        bottom: context.responsiveSpacing(
          small: 3,
          medium: 4,
          large: 5,
          tablet: 6,
          veryNarrow: 2,
        ),
      ),
      child: RichText(
        text: TextSpan(
          style: TextStyle(
            color: context.textPrimaryColor,
            fontSize: context.responsiveFontSize(
              small: 12,
              medium: 13,
              large: 14,
              tablet: 15,
              veryNarrow: 11,
            ),
            height: 1.3,
          ),
          children: [
            TextSpan(
              text: '$label ',
              style: TextStyle(
                color: context.textSecondaryColor,
                fontWeight: FontWeight.w500,
              ),
            ),
            TextSpan(text: value),
          ],
        ),
      ),
    );
  }

  Widget _buildPriceRow(BuildContext context, String label, String amount) {
    return Padding(
      padding: EdgeInsets.symmetric(
        vertical: isVerySmallScreen ? 4 : (isSmallScreen ? 5 : 6),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                color: context.textSecondaryColor,
                fontSize: context.responsiveFontSize(
                  small: 12,
                  medium: 13,
                  large: 14,
                  tablet: 15,
                  veryNarrow: 10,
                ),
              ),
            ),
          ),
          Text(
            amount,
            style: TextStyle(
              color: AppColors.deepGreen,
              fontSize: context.responsiveFontSize(
                small: 13,
                medium: 14,
                large: 15,
                tablet: 16,
                veryNarrow: 11,
              ),
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
