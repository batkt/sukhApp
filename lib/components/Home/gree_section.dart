import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:sukh_app/models/geree_model.dart';
import 'package:sukh_app/constants/constants.dart';
import 'package:sukh_app/utils/theme_extensions.dart';

class GreeSection extends StatelessWidget {
  final GereeResponse? greeResponse;
  final Map<String, dynamic>? nekhemjlekhCronData;

  const GreeSection({
    super.key,
    required this.greeResponse,
    this.nekhemjlekhCronData,
  });

  @override
  Widget build(BuildContext context) {
    if (greeResponse == null || greeResponse!.jagsaalt.isEmpty) {
      return const SizedBox.shrink();
    }

    final geree = greeResponse!.jagsaalt.first;
    return _buildRemainingDaysWidget(context, geree);
  }

  Widget _buildRemainingDaysWidget(BuildContext context, Geree geree) {
    DateTime? nextInvoiceDate;

    if (nekhemjlekhCronData != null &&
        nekhemjlekhCronData!['nekhemjlekhUusgekhOgnoo'] != null) {
      final rawVal = nekhemjlekhCronData!['nekhemjlekhUusgekhOgnoo'];
      final day = rawVal is int
          ? rawVal
          : (rawVal is num
              ? rawVal.toInt()
              : int.tryParse(rawVal.toString()) ?? 0);
      final today = DateTime.now();

      if (day >= 1 && day <= 31) {
        if (today.day >= day) {
          final nextMonth = today.month == 12 ? 1 : today.month + 1;
          final nextYear = today.month == 12 ? today.year + 1 : today.year;
          nextInvoiceDate = DateTime(nextYear, nextMonth, day);
        } else {
          nextInvoiceDate = DateTime(today.year, today.month, day);
        }
      }
    }

    final today = DateTime.now();
    final todayDateOnly = DateTime(today.year, today.month, today.day);

    int displayDays;
    String centerLabel;
    Color accentColor;
    String nextUnitDateText;

    if (nextInvoiceDate != null) {
      final nextDateOnly = DateTime(
        nextInvoiceDate.year,
        nextInvoiceDate.month,
        nextInvoiceDate.day,
      );
      if (nextDateOnly.isAfter(todayDateOnly) ||
          nextDateOnly.isAtSameMomentAs(todayDateOnly)) {
        displayDays = nextDateOnly.difference(todayDateOnly).inDays;
        centerLabel = 'өдөр дутуу';
        accentColor = AppColors.deepGreen;
      } else {
        displayDays = todayDateOnly.difference(nextDateOnly).inDays;
        centerLabel = 'өдөр хэтэрсэн';
        accentColor = const Color(0xFFFF6B6B);
      }
      nextUnitDateText =
          '${nextInvoiceDate.year}-${nextInvoiceDate.month.toString().padLeft(2, '0')}-${nextInvoiceDate.day.toString().padLeft(2, '0')}';
    } else {
      // Fallback: days since contract created
      try {
        final contractDate = DateTime.parse(geree.gereeniiOgnoo);
        displayDays = today.difference(contractDate).inDays;
      } catch (_) {
        displayDays = 0;
      }
      centerLabel = 'өдөр өнгөрсөн';
      accentColor = const Color(0xFFFF6B6B);
      nextUnitDateText = '';
    }

    final isDark = context.isDarkMode;

    return Column(
      children: [
        // Remaining days card
        Container(
          width: double.infinity,
          padding: EdgeInsets.all(16.w),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1A1F26) : Colors.white,
            borderRadius: BorderRadius.circular(16.r),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.06),
                blurRadius: 16,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                width: 60.w,
                height: 60.w,
                decoration: BoxDecoration(
                  color: accentColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12.r),
                ),
                child: Center(
                  child: Text(
                    '$displayDays',
                    style: TextStyle(
                      fontSize: 22.sp,
                      color: accentColor,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
              SizedBox(width: 12.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      centerLabel,
                      style: TextStyle(
                        color: accentColor,
                        fontSize: 14.sp,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    if (nextUnitDateText.isNotEmpty) ...[
                      SizedBox(height: 4.h),
                      Row(
                        children: [
                          Icon(
                            Icons.calendar_today_rounded,
                            color: context.textSecondaryColor,
                            size: 12.sp,
                          ),
                          SizedBox(width: 4.w),
                          Text(
                            'Дараагийн: $nextUnitDateText',
                            style: TextStyle(
                              fontSize: 11.sp,
                              color: context.textSecondaryColor,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
