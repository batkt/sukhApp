import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:sukh_app/components/Nekhemjlekh/nekhemjlekh_models.dart';
import 'package:sukh_app/constants/constants.dart';
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
        margin: EdgeInsets.only(bottom: 16.h),
        child: Container(
          decoration: BoxDecoration(
            color: context.isDarkMode
                ? Colors.transparent
                : AppColors.lightSurface,
            borderRadius: BorderRadius.circular(20.r),
            border: Border.all(color: context.borderColor, width: 1),
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: onToggleExpand,
              borderRadius: BorderRadius.circular(20.r),
              child: Padding(
                padding: EdgeInsets.all(16.w),
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
                                fontSize: 12.sp,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            // Status tag
                            Container(
                              padding: EdgeInsets.symmetric(
                                horizontal: 12.w,
                                vertical: 6.h,
                              ),
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [
                                    statusColor.withOpacity(0.15),
                                    statusColor.withOpacity(0.08),
                                  ],
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                ),
                                borderRadius: BorderRadius.circular(16.w),
                                border: Border.all(
                                  color: statusColor.withOpacity(0.4),
                                  width: 1.5,
                                ),
                              ),
                              child: Text(
                                statusLabel,
                                style: TextStyle(
                                  color: statusColor,
                                  fontSize: 12.sp,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 0.5,
                                ),
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: 12.h),
                        // Main content row
                        Row(
                          children: [
                            // Company logo
                            Container(
                              width: 48.w,
                              height: 48.w,
                              decoration: BoxDecoration(
                                color: Colors.transparent,
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: AppColors.deepGreen.withOpacity(0.3),
                                  width: 2,
                                ),
                              ),
                              child: ClipOval(
                                child: Image.asset(
                                  'lib/assets/img/logo_3.png',
                                  width: 48.w,
                                  height: 48.w,
                                  fit: BoxFit.cover,
                                  errorBuilder: (context, error, stackTrace) {
                                    return Icon(
                                      Icons.receipt_long_rounded,
                                      color: AppColors.deepGreen,
                                      size: 24.sp,
                                    );
                                  },
                                ),
                              ),
                            ),
                            SizedBox(width: 12.w),
                            // Client info
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    invoice.displayName,
                                    style: TextStyle(
                                      color: context.textPrimaryColor,
                                      fontSize: 16.sp,
                                      fontWeight: FontWeight.w600,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  SizedBox(height: 4.h),
                                  Text(
                                    invoice.gereeniiDugaar,
                                    style: TextStyle(
                                      color: context.textSecondaryColor,
                                      fontSize: 13.sp,
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
                                    fontSize: 16.sp,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                if (!isHistory) SizedBox(height: 8.h),
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
                                        width: 26.w,
                                        height: 26.w,
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
                                                    size: 18.sp,
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
                          padding: EdgeInsets.only(top: 8.h),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                invoice.isExpanded
                                    ? Icons.keyboard_arrow_up
                                    : Icons.keyboard_arrow_down,
                                color: AppColors.deepGreen,
                                size: 20.sp,
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
      padding: EdgeInsets.all(16.w),
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
                  borderRadius: BorderRadius.circular(12.r),
                  child: Container(
                    padding: EdgeInsets.all(12.w),
                    constraints: BoxConstraints(minHeight: 120.h),
                    decoration: BoxDecoration(
                      color: context.isDarkMode
                          ? Colors.white.withOpacity(0.04)
                          : AppColors.lightAccentBackground,
                      borderRadius: BorderRadius.circular(12.r),
                      border: Border.all(color: context.borderColor, width: 1),
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
                              size: 16.sp,
                            ),
                            SizedBox(width: 6.w),
                            Text(
                              'Нэхэмжлэгч',
                              style: context.expandedTitleStyle(
                                color: AppColors.deepGreen,
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: 8.h),
                        _buildInfoText(
                          context,
                          'Байгууллагын нэр:\n${invoice.baiguullagiinNer}',
                        ),
                        if (invoice.khayag.isNotEmpty) ...[
                          SizedBox(height: 6.h),
                          _buildInfoText(context, 'Хаяг: ${invoice.khayag}'),
                        ],
                      ],
                    ),
                  ),
                ),
              ),
              SizedBox(width: 12.w),
              // Төлөгч section
              Expanded(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12.r),
                  child: Container(
                    padding: EdgeInsets.all(12.w),
                    constraints: BoxConstraints(minHeight: 120.h),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.04),
                      borderRadius: BorderRadius.circular(12.r),
                      border: Border.all(
                        color: Colors.white.withOpacity(0.12),
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
                              size: 16.sp,
                            ),
                            SizedBox(width: 6.w),
                            Text(
                              'Төлөгч',
                              style: context.expandedTitleStyle(
                                color: AppColors.deepGreen,
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: 8.h),
                        _buildInfoText(context, 'Нэр: ${invoice.displayName}'),
                        if (invoice.register.isNotEmpty) ...[
                          SizedBox(height: 6.h),
                          _buildInfoText(
                            context,
                            'Регистр: ${invoice.register}',
                          ),
                        ],
                        if (invoice.phoneNumber.isNotEmpty) ...[
                          SizedBox(height: 6.h),
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
          SizedBox(height: 20.h),
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
                        SizedBox(height: 8.h),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(12.r),
                          child: Container(
                            padding: EdgeInsets.all(12.w),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.04),
                              borderRadius: BorderRadius.circular(12.r),
                              border: Border.all(
                                color: AppColors.deepGreen.withOpacity(0.3),
                                width: 1,
                              ),
                            ),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Icon(
                                  Icons.info_outline,
                                  color: AppColors.deepGreen,
                                  size: 16.sp,
                                ),
                                SizedBox(width: 8.w),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Авлагын шалтгаан:',
                                        style: context.expandedTitleStyle(
                                          color: AppColors.deepGreen,
                                        ),
                                      ),
                                      SizedBox(height: 4.h),
                                      Text(
                                        guilgee.tailbar!,
                                        style: context.expandedTextStyle(
                                          color: context.textPrimaryColor,
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
                          SizedBox(height: 4.h),
                          Padding(
                            padding: EdgeInsets.only(left: 16.w),
                            child: Text(
                              'Төрөл: ${zardal.turul}',
                              style: context
                                  .secondaryDescriptionStyle(
                                    color: context.textSecondaryColor,
                                  )
                                  .copyWith(fontStyle: FontStyle.italic),
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
            SizedBox(height: 16.h),
            ClipRRect(
              borderRadius: BorderRadius.circular(12.r),
              child: Container(
                padding: EdgeInsets.all(12.w),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.04),
                  borderRadius: BorderRadius.circular(12.r),
                  border: Border.all(
                    color: Colors.white.withOpacity(0.12),
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
                          size: 16.sp,
                        ),
                        SizedBox(width: 6.w),
                        Text(
                          'Тайлбар',
                          style: context.expandedTitleStyle(
                            color: AppColors.deepGreen,
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 8.h),
                    Text(
                      invoice.medeelel!.tailbar!,
                      style: context.expandedTextStyle(
                        color: context.textPrimaryColor,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
          SizedBox(height: 16.h),
          // Total amount
          ClipRRect(
            borderRadius: BorderRadius.circular(12.r),
            child: Container(
              padding: EdgeInsets.all(16.w),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.04),
                borderRadius: BorderRadius.circular(12.r),
                border: Border.all(
                  color: Colors.white.withOpacity(0.12),
                  width: 1,
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Нийт дүн:',
                    style: context.expandedTitleStyle(
                      color: context.textPrimaryColor,
                    ),
                  ),
                  Text(
                    invoice.formattedAmount,
                    style: context.expandedTitleStyle(
                      color: AppColors.deepGreen,
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (isHistory && onShowVATReceipt != null) ...[
            SizedBox(height: 12.h),
            ClipRRect(
              borderRadius: BorderRadius.circular(12.r),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: onShowVATReceipt,
                  borderRadius: BorderRadius.circular(12.r),
                  child: Container(
                    width: double.infinity,
                    padding: EdgeInsets.symmetric(vertical: 12.h),
                    decoration: BoxDecoration(
                      color: AppColors.deepGreen,
                      borderRadius: BorderRadius.circular(12.r),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.receipt_long_rounded,
                          size: 18.sp,
                          color: Colors.white,
                        ),
                        SizedBox(width: 8.w),
                        Text(
                          'Баримт харах',
                          style: TextStyle(
                            fontSize: 14.sp,
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
        bottom: isVerySmallScreen ? 6 : (isSmallScreen ? 7 : 8),
      ),
      child: Text(
        text,
        style: context.expandedTextStyle(color: context.textPrimaryColor),
      ),
    );
  }

  Widget _buildPriceRow(BuildContext context, String label, String amount) {
    return Padding(
      padding: EdgeInsets.symmetric(
        vertical: isVerySmallScreen ? 6 : (isSmallScreen ? 7 : 8),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: context.expandedTextStyle(color: context.textSecondaryColor),
          ),
          Text(
            amount,
            style: context.expandedTextStyle(
              color: AppColors.deepGreen,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
