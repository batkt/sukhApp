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

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 40.h,
      margin: EdgeInsets.symmetric(horizontal: 14.w, vertical: 6.h),
      child: ListView(
        scrollDirection: Axis.horizontal,
        children: [
          _buildFilterTab(context, 'All', 'Бүгд'),
          _buildFilterTab(context, 'Avlaga', 'Авлага'),
          _buildFilterTab(context, 'AshiglaltiinZardal', 'Зардал'),
          _buildFilterTab(context, 'Paid', 'Төлөгдсөн'),
        ],
      ),
    );
  }

  Widget _buildFilterTab(BuildContext context, String filterKey, String label) {
    final isSelected = selectedFilter == filterKey;
    final count = getFilterCount(filterKey);

    return Container(
      margin: EdgeInsets.only(right: 6.w),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => onFilterChanged(filterKey),
          borderRadius: BorderRadius.circular(12.r),
          child: Container(
            padding: EdgeInsets.symmetric(
              horizontal: 10.w,
              vertical: 6.h,
            ),
            decoration: BoxDecoration(
              color: isSelected
                  ? AppColors.deepGreen
                  : (context.isDarkMode
                      ? const Color(0xFF1A1A1A)
                      : Colors.white),
              borderRadius: BorderRadius.circular(12.r),
              border: Border.all(
                color: isSelected
                    ? AppColors.deepGreen
                    : (context.isDarkMode
                        ? AppColors.deepGreen.withOpacity(0.2)
                        : AppColors.deepGreen.withOpacity(0.15)),
                width: 1,
              ),
              boxShadow: isSelected
                  ? [
                      BoxShadow(
                        color: AppColors.deepGreen.withOpacity(0.2),
                        blurRadius: 4,
                        offset: const Offset(0, 2),
                      ),
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
                        ? Colors.white
                        : context.textPrimaryColor,
                    fontSize: 11.sp,
                    fontWeight: isSelected
                        ? FontWeight.w600
                        : FontWeight.w500,
                  ),
                ),
                if (count > 0) ...[
                  SizedBox(width: 5.w),
                  Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: 5.w,
                      vertical: 2.h,
                    ),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? Colors.white.withOpacity(0.2)
                          : AppColors.deepGreen.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(8.r),
                    ),
                    child: Text(
                      count.toString(),
                      style: TextStyle(
                        color: isSelected
                            ? Colors.white
                            : AppColors.deepGreen,
                        fontSize: 9.sp,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
