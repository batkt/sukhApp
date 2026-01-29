import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:sukh_app/components/Nekhemjlekh/nekhemjlekh_models.dart';
import 'package:sukh_app/constants/constants.dart';
import 'package:sukh_app/utils/responsive_helper.dart';
import 'package:sukh_app/utils/theme_extensions.dart';

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
        margin: EdgeInsets.only(bottom: 10.h),
        child: Container(
          decoration: BoxDecoration(
            color: context.isDarkMode
                ? const Color(0xFF1A1A1A)
                : Colors.white,
            borderRadius: BorderRadius.circular(14.r),
            border: Border.all(
              color: context.isDarkMode
                  ? AppColors.deepGreen.withOpacity(0.2)
                  : AppColors.deepGreen.withOpacity(0.15),
              width: 1,
            ),
            boxShadow: [
              BoxShadow(
                color: context.isDarkMode
                    ? Colors.black.withOpacity(0.2)
                    : Colors.black.withOpacity(0.05),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: onToggleExpand,
              borderRadius: BorderRadius.circular(14.r),
              child: Padding(
                padding: EdgeInsets.all(12.w),
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
                                  small: 12,
                                  medium: 13,
                                  large: 14,
                                  tablet: 15,
                                  veryNarrow: 10,
                                ),
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            // Status tag
                            Container(
                              padding: EdgeInsets.symmetric(
                                horizontal: 8.w,
                                vertical: 4.h,
                              ),
                              decoration: BoxDecoration(
                                color: statusColor.withOpacity(0.15),
                                borderRadius: BorderRadius.circular(10.r),
                                border: Border.all(
                                  color: statusColor.withOpacity(0.4),
                                  width: 1,
                                ),
                              ),
                              child: Text(
                                statusLabel,
                                style: TextStyle(
                                  color: statusColor,
                                  fontSize: context.responsiveFontSize(
                                    small: 11,
                                    medium: 12,
                                    large: 13,
                                    tablet: 14,
                                    veryNarrow: 9,
                                  ),
                                  fontWeight: FontWeight.w600,
                                  letterSpacing: 0.3,
                                ),
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: 10.h),
                        // Main content row
                        Row(
                          children: [
                            // Company logo
                            Container(
                              width: 40.w,
                              height: 40.w,
                              decoration: BoxDecoration(
                                color: AppColors.deepGreen,
                                shape: BoxShape.circle,
                                boxShadow: [
                                  BoxShadow(
                                    color: AppColors.deepGreen.withOpacity(0.3),
                                    blurRadius: 6,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: ClipOval(
                                child: Image.asset(
                                  'lib/assets/img/logo_3.png',
                                  width: 40.w,
                                  height: 40.w,
                                  fit: BoxFit.cover,
                                  errorBuilder: (context, error, stackTrace) {
                                    return Icon(
                                      Icons.receipt_long_rounded,
                                      color: Colors.white,
                                      size: 18.sp,
                                    );
                                  },
                                ),
                              ),
                            ),
                            SizedBox(width: 10.w),
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
                                        small: 15,
                                        medium: 16,
                                        large: 17,
                                        tablet: 18,
                                        veryNarrow: 13,
                                      ),
                                      fontWeight: FontWeight.w600,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  SizedBox(height: 3.h),
                                  Text(
                                    invoice.gereeniiDugaar,
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
                                      small: 16,
                                      medium: 17,
                                      large: 18,
                                      tablet: 20,
                                      veryNarrow: 14,
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
                          padding: EdgeInsets.only(top: 6.h),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                invoice.isExpanded
                                    ? Icons.keyboard_arrow_up
                                    : Icons.keyboard_arrow_down,
                                color: AppColors.deepGreen,
                                size: context.responsiveFontSize(
                                  small: 20,
                                  medium: 21,
                                  large: 22,
                                  tablet: 24,
                                  veryNarrow: 16,
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
    return Container(
      padding: EdgeInsets.all(10.w),
      decoration: BoxDecoration(color: Colors.transparent),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Нэхэмжлэгч and Төлөгч sections
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Нэхэмжлэгч section
              Expanded(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(10.r),
                  child: Container(
                    padding: EdgeInsets.all(10.w),
                    constraints: BoxConstraints(minHeight: 100.h),
                    decoration: BoxDecoration(
                      color: context.isDarkMode
                          ? Colors.white.withOpacity(0.05)
                          : const Color(0xFFF8F8F8),
                      borderRadius: BorderRadius.circular(10.r),
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
                        Row(
                          children: [
                            Icon(
                              Icons.business,
                              color: AppColors.deepGreen,
                              size: context.responsiveFontSize(
                                small: 16,
                                medium: 17,
                                large: 18,
                                tablet: 20,
                                veryNarrow: 14,
                              ),
                            ),
                            SizedBox(width: 4.w),
                            Text(
                              'Нэхэмжлэгч',
                              style: TextStyle(
                                color: AppColors.deepGreen,
                                fontSize: context.responsiveFontSize(
                                  small: 12,
                                  medium: 13,
                                  large: 14,
                                  tablet: 15,
                                  veryNarrow: 10,
                                ),
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: 6.h),
                        _buildInfoText(
                          context,
                          'Байгууллагын нэр:\n${invoice.baiguullagiinNer}',
                        ),
                        if (invoice.khayag.isNotEmpty) ...[
                          SizedBox(height: 4.h),
                          _buildInfoText(context, 'Хаяг: ${invoice.khayag}'),
                        ],
                      ],
                    ),
                  ),
                ),
              ),
              SizedBox(width: 8.w),
              // Төлөгч section
              Expanded(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(10.r),
                  child: Container(
                    padding: EdgeInsets.all(10.w),
                    constraints: BoxConstraints(minHeight: 100.h),
                    decoration: BoxDecoration(
                      color: context.isDarkMode
                          ? Colors.white.withOpacity(0.05)
                          : const Color(0xFFF8F8F8),
                      borderRadius: BorderRadius.circular(10.r),
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
                        Row(
                          children: [
                            Icon(
                              Icons.person,
                              color: AppColors.deepGreen,
                              size: context.responsiveFontSize(
                                small: 16,
                                medium: 17,
                                large: 18,
                                tablet: 20,
                                veryNarrow: 14,
                              ),
                            ),
                            SizedBox(width: 4.w),
                            Text(
                              'Төлөгч',
                              style: TextStyle(
                                color: AppColors.deepGreen,
                                fontSize: context.responsiveFontSize(
                                  small: 12,
                                  medium: 13,
                                  large: 14,
                                  tablet: 15,
                                  veryNarrow: 10,
                                ),
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: 6.h),
                        _buildInfoText(context, 'Нэр: ${invoice.displayName}'),
                        if (invoice.register.isNotEmpty) ...[
                          SizedBox(height: 4.h),
                          _buildInfoText(
                            context,
                            'Регистр: ${invoice.register}',
                          ),
                        ],
                        if (invoice.phoneNumber.isNotEmpty) ...[
                          SizedBox(height: 4.h),
                          _buildInfoText(
                            context,
                            'Утас: ${invoice.phoneNumber}',
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 12.h),
          // Price breakdown
          if (invoice.ekhniiUldegdel != null &&
              invoice.ekhniiUldegdel! != 0) ...[
            _buildPriceRow(
              context,
              'Эхний үлдэгдэл',
              '${invoice.ekhniiUldegdel!.toStringAsFixed(2).replaceAllMapped(RegExp(r'(\d)(?=(\d{3})+(?!\d))'), (match) => '${match[1]},')}₮',
            ),
          ],
          // Avlaga items from guilgeenuud
          if (invoice.medeelel != null &&
              invoice.medeelel!.guilgeenuud != null) ...[
            ...invoice.medeelel!.guilgeenuud!
                .where((guilgee) => guilgee.turul == 'avlaga')
                .map((guilgee) {
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SizedBox(height: 8.h),
                      if (guilgee.tulukhDun != null &&
                          guilgee.tulukhDun! > 0) ...[
                        _buildPriceRow(
                          context,
                          'Авлага',
                          '${guilgee.tulukhDun!.toStringAsFixed(2).replaceAllMapped(RegExp(r'(\d)(?=(\d{3})+(?!\d))'), (match) => '${match[1]},')}₮',
                        ),
                      ],
                      if (guilgee.tailbar != null &&
                          guilgee.tailbar!.isNotEmpty) ...[
                        SizedBox(height: 6.h),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(10.r),
                          child: Container(
                            padding: EdgeInsets.all(10.w),
                            decoration: BoxDecoration(
                              color: context.isDarkMode
                                  ? Colors.white.withOpacity(0.04)
                                  : const Color(0xFFF8F8F8),
                              borderRadius: BorderRadius.circular(10.r),
                              border: Border.all(
                                color: AppColors.deepGreen.withOpacity(0.2),
                                width: 1,
                              ),
                            ),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Icon(
                                  Icons.info_outline,
                                  color: AppColors.deepGreen,
                                  size: context.responsiveFontSize(
                                    small: 16,
                                    medium: 17,
                                    large: 18,
                                    tablet: 20,
                                    veryNarrow: 14,
                                  ),
                                ),
                                SizedBox(width: 6.w),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Авлагын шалтгаан:',
                                        style: TextStyle(
                                          color: AppColors.deepGreen,
                                          fontSize: context.responsiveFontSize(
                                            small: 12,
                                            medium: 13,
                                            large: 14,
                                            tablet: 15,
                                            veryNarrow: 10,
                                          ),
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                      SizedBox(height: 3.h),
                                      Text(
                                        guilgee.tailbar!,
                                        style: TextStyle(
                                          color: context.textPrimaryColor,
                                          fontSize: context.responsiveFontSize(
                                            small: 12,
                                            medium: 13,
                                            large: 14,
                                            tablet: 15,
                                            veryNarrow: 10,
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
          // AshiglaltiinZardal items from zardluud (filter for Тогтмол and Дурын)
          if (invoice.medeelel != null) ...[
            // Debug logging
            Builder(
              builder: (context) {
                print('🔍 DEBUG: invoice.medeelel is not null');
                print(
                  '🔍 DEBUG: zardluud length: ${invoice.medeelel!.zardluud.length}',
                );
                for (var i = 0; i < invoice.medeelel!.zardluud.length; i++) {
                  final zardal = invoice.medeelel!.zardluud[i];
                  print(
                    '🔍 DEBUG: zardluud[$i]: ner="${zardal.ner}", turul="${zardal.turul}", dun=${zardal.dun}, zaaltDefaultDun=${zardal.zaaltDefaultDun}, togtmolUtga=${zardal.togtmolUtga}',
                  );
                  print('🔍 DEBUG: displayAmount=${zardal.displayAmount}');
                }
                final filtered = invoice.medeelel!.zardluud
                    .where(
                      (zardal) =>
                          zardal.turul == 'Тогтмол' || zardal.turul == 'Дурын',
                    )
                    .toList();
                print('🔍 DEBUG: filtered zardluud length: ${filtered.length}');
                return const SizedBox.shrink();
              },
            ),
            if (invoice.medeelel!.zardluud.isNotEmpty) ...[
              // Filter zardluud to show only Тогтмол and Дурын items
              ...invoice.medeelel!.zardluud
                  .where(
                    (zardal) =>
                        zardal.turul == 'Тогтмол' || zardal.turul == 'Дурын',
                  )
                  .map((zardal) {
                    print(
                      '🔍 DEBUG: Displaying zardal: ${zardal.ner}, turul=${zardal.turul}, amount=${zardal.displayAmount}',
                    );
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        SizedBox(height: 8.h),
                        _buildPriceRow(
                          context,
                          zardal.ner,
                          zardal.formattedDisplayAmount,
                        ),
                        if (zardal.turul.isNotEmpty) ...[
                          SizedBox(height: 3.h),
                          Padding(
                            padding: EdgeInsets.only(left: 12.w),
                            child: Text(
                              'Төрөл: ${zardal.turul}',
                              style: TextStyle(
                                color: context.textSecondaryColor,
                                fontSize: context.responsiveFontSize(
                                  small: 11,
                                  medium: 12,
                                  large: 13,
                                  tablet: 14,
                                  veryNarrow: 9,
                                ),
                                fontStyle: FontStyle.italic,
                              ),
                            ),
                          ),
                        ],
                      ],
                    );
                  }),
            ] else ...[
              Builder(
                builder: (context) {
                  print('🔍 DEBUG: zardluud is empty');
                  return const SizedBox.shrink();
                },
              ),
            ],
          ] else ...[
            Builder(
              builder: (context) {
                print('🔍 DEBUG: invoice.medeelel is null');
                return const SizedBox.shrink();
              },
            ),
          ],
          // Tailbar field
          if (invoice.medeelel != null &&
              invoice.medeelel!.tailbar != null &&
              invoice.medeelel!.tailbar!.isNotEmpty) ...[
            SizedBox(height: 12.h),
            ClipRRect(
              borderRadius: BorderRadius.circular(10.r),
              child: Container(
                padding: EdgeInsets.all(10.w),
                decoration: BoxDecoration(
                  color: context.isDarkMode
                      ? Colors.white.withOpacity(0.04)
                      : const Color(0xFFF8F8F8),
                  borderRadius: BorderRadius.circular(10.r),
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
                            small: 16,
                            medium: 17,
                            large: 18,
                            tablet: 20,
                            veryNarrow: 14,
                          ),
                        ),
                        SizedBox(width: 4.w),
                        Text(
                          'Тайлбар',
                          style: TextStyle(
                            color: AppColors.deepGreen,
                            fontSize: context.responsiveFontSize(
                              small: 12,
                              medium: 13,
                              large: 14,
                              tablet: 15,
                              veryNarrow: 10,
                            ),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 6.h),
                    Text(
                      invoice.medeelel!.tailbar!,
                      style: TextStyle(
                        color: context.textPrimaryColor,
                        fontSize: context.responsiveFontSize(
                          small: 12,
                          medium: 13,
                          large: 14,
                          tablet: 15,
                          veryNarrow: 10,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
          SizedBox(height: 12.h),
          // Total amount
          ClipRRect(
            borderRadius: BorderRadius.circular(10.r),
            child: Container(
              padding: EdgeInsets.all(12.w),
              decoration: BoxDecoration(
                color: context.isDarkMode
                    ? Colors.white.withOpacity(0.04)
                    : const Color(0xFFF8F8F8),
                borderRadius: BorderRadius.circular(10.r),
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
                        veryNarrow: 11,
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
                        veryNarrow: 13,
                      ),
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (isHistory && onShowVATReceipt != null) ...[
            SizedBox(height: 10.h),
            ClipRRect(
              borderRadius: BorderRadius.circular(10.r),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: onShowVATReceipt,
                  borderRadius: BorderRadius.circular(10.r),
                  child: Container(
                    width: double.infinity,
                    padding: EdgeInsets.symmetric(vertical: 10.h),
                    decoration: BoxDecoration(
                      color: AppColors.deepGreen,
                      borderRadius: BorderRadius.circular(10.r),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.receipt_long_rounded,
                          size: context.responsiveFontSize(
                            small: 16,
                            medium: 17,
                            large: 18,
                            tablet: 20,
                            veryNarrow: 14,
                          ),
                          color: Colors.white,
                        ),
                        SizedBox(width: 6.w),
                        Text(
                          'Баримт харах',
                          style: TextStyle(
                            fontSize: context.responsiveFontSize(
                              small: 13,
                              medium: 14,
                              large: 15,
                              tablet: 16,
                              veryNarrow: 11,
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
            small: 11,
            medium: 12,
            large: 13,
            tablet: 14,
            veryNarrow: 9,
          ),
          height: 1.3,
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
