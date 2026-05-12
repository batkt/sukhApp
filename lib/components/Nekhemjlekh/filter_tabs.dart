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
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        _buildFilterTab(context, 'Unpaid', 'Төлөх'),
        SizedBox(width: 8.w),
        _buildFilterTab(context, 'Paid', 'Төлөгдсөн'),
      ],
    );
  }

  Widget _buildFilterTab(BuildContext context, String filterKey, String label) {
    final isSelected = selectedFilter == filterKey;
    final count = getFilterCount(filterKey);

    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        onFilterChanged(filterKey);
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOutCubic,
        padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 8.h),
        decoration: BoxDecoration(
          gradient: isSelected 
              ? const LinearGradient(
                  colors: [AppColors.deepGreen, Color(0xFF10B981)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                )
              : null,
          color: isSelected 
              ? null 
              : (context.isDarkMode ? Colors.white.withOpacity(0.05) : Colors.black.withOpacity(0.04)),
          borderRadius: BorderRadius.circular(100),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: AppColors.deepGreen.withOpacity(0.3),
                    blurRadius: 10,
                    offset: const Offset(0, 3),
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
                color: isSelected ? Colors.white : context.textSecondaryColor,
                fontSize: 12.sp,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                letterSpacing: -0.2,
              ),
            ),
            if (count > 0) ...[
              SizedBox(width: 6.w),
              AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                padding: EdgeInsets.symmetric(horizontal: 6.w, vertical: 2.h),
                decoration: BoxDecoration(
                  color: isSelected
                      ? Colors.white.withOpacity(0.25)
                      : AppColors.deepGreen.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(100),
                ),
                child: Text(
                  count.toString(),
                  style: TextStyle(
                    color: isSelected ? Colors.white : AppColors.deepGreen,
                    fontSize: 10.sp,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
