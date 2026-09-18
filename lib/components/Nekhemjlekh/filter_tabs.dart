import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:sukh_app/constants/constants.dart';
import 'package:sukh_app/utils/theme_extensions.dart';

class FilterTabs extends StatelessWidget {
  final String selectedFilter;
  final Function(String) onFilterChanged;
  final int Function(String) getFilterCount;

  const FilterTabs({
    super.key,
    required this.selectedFilter,
    required this.onFilterChanged,
    required this.getFilterCount,
  });

  @override
  Widget build(BuildContext context) {
    final isSmall = MediaQuery.of(context).size.width < 375;
    final isVerySmall = MediaQuery.of(context).size.width < 340;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        _buildFilterTab(context, 'Unpaid', 'Төлөх', isSmall, isVerySmall),
        SizedBox(width: (isVerySmall ? 4.0 : 8.0).w),
        _buildFilterTab(context, 'Paid', 'Төлөгдсөн', isSmall, isVerySmall),
      ],
    );
  }

  Widget _buildFilterTab(
    BuildContext context,
    String filterKey,
    String label,
    bool isSmall,
    bool isVerySmall,
  ) {
    final isSelected = selectedFilter == filterKey;
    final count = getFilterCount(filterKey);
    final isDark = context.isDarkMode;

    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        onFilterChanged(filterKey);
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOutCubic,
        padding: EdgeInsets.symmetric(
          horizontal: (isVerySmall ? 8.0 : (isSmall ? 10.0 : 12.0)).w,
          vertical: (isVerySmall ? 6.0 : (isSmall ? 7.0 : 8.0)).h,
        ),
        decoration: BoxDecoration(
          color: isSelected
              ? (isDark ? Colors.white.withOpacity(0.08) : Colors.white)
              : (isDark ? Colors.white.withOpacity(0.03) : const Color(0xFFF8FAFC)),
          borderRadius: BorderRadius.circular(100),
          border: Border.all(
            color: isSelected
                ? AppColors.deepGreen.withOpacity(0.35)
                : context.borderColor.withOpacity(0.12),
            width: isSelected ? 1.2 : 1.0,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: AppColors.deepGreen.withOpacity(0.08),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  )
                ]
              : null,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              label,
              style: TextStyle(
                color: isSelected
                    ? (isDark ? Colors.white : const Color(0xFF0F172A))
                    : context.textSecondaryColor,
                fontSize: (isVerySmall ? 10.5 : (isSmall ? 11.5 : 12.5)).sp,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                letterSpacing: -0.2,
              ),
            ),
            if (count > 0) ...[
              SizedBox(width: (isVerySmall ? 4.0 : 6.0).w),
              Container(
                padding: EdgeInsets.symmetric(
                  horizontal: (isVerySmall ? 5.0 : 6.5).w,
                  vertical: 1.5.h,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFF10B981).withOpacity(0.12),
                  borderRadius: BorderRadius.circular(100),
                ),
                child: Text(
                  count.toString(),
                  style: TextStyle(
                    color: const Color(0xFF10B981),
                    fontSize: (isVerySmall ? 9.0 : 10.0).sp,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
            SizedBox(width: (isVerySmall ? 2.0 : 4.0).w),
            Icon(
              Icons.chevron_right_rounded,
              size: (isVerySmall ? 13.0 : 15.0).sp,
              color: isSelected
                  ? context.textPrimaryColor
                  : context.textSecondaryColor.withOpacity(0.7),
            ),
          ],
        ),
      ),
    );
  }
}
