import 'package:flutter/material.dart';
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

  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        _buildFilterTab(context, 'All', 'Бүгд'),
        SizedBox(width: 6.w),
        _buildFilterTab(context, 'Unpaid', 'Төлөх'),
        SizedBox(width: 6.w),
        _buildFilterTab(context, 'Paid', 'Төлөгдсөн'),
      ],
    );
  }

  Widget _buildFilterTab(BuildContext context, String filterKey, String label) {
    final isSelected = selectedFilter == filterKey;
    final count = getFilterCount(filterKey);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => onFilterChanged(filterKey),
        borderRadius: BorderRadius.circular(10.r),
        child: Container(
          padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 5.h),
          decoration: BoxDecoration(
            color: isSelected ? AppColors.deepGreen : (context.isDarkMode ? Colors.white.withOpacity(0.04) : Colors.black.withOpacity(0.03)),
            borderRadius: BorderRadius.circular(10.r),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                label,
                style: TextStyle(
                  color: isSelected ? Colors.white : context.textPrimaryColor,
                  fontSize: 11.sp,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                ),
              ),
              if (count > 0) ...[
                SizedBox(width: 4.w),
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 1.h),
                  decoration: BoxDecoration(
                    color: isSelected ? Colors.white.withOpacity(0.15) : AppColors.deepGreen.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(6.r),
                  ),
                  child: Text(
                    count.toString(),
                    style: TextStyle(
                      color: isSelected ? Colors.white : AppColors.deepGreen,
                      fontSize: 9.sp,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
