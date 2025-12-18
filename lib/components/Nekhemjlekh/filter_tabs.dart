import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:sukh_app/constants/constants.dart';
import 'package:sukh_app/widgets/optimized_glass.dart';
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
      height: 50.h,
      margin: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
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
        margin: EdgeInsets.only(right: 8.w),
        child: OptimizedGlass(
          borderRadius: BorderRadius.circular(20.r),
          opacity: isSelected ? 0.12 : 0.08,
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () => onFilterChanged(filterKey),
              borderRadius: BorderRadius.circular(20.r),
              child: Padding(
                padding: EdgeInsets.symmetric(
                  horizontal: 12.w,
                  vertical: 8.h,
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      label,
                      style: TextStyle(
                        color: isSelected
                            ? AppColors.deepGreen
                            : context.textPrimaryColor,
                        fontSize: 13.sp,
                        fontWeight: isSelected
                            ? FontWeight.w600
                            : FontWeight.w500,
                      ),
                    ),
                    if (count > 0) ...[
                      SizedBox(width: 6.w),
                      OptimizedGlass(
                        borderRadius: BorderRadius.circular(10.r),
                        opacity: isSelected ? 0.14 : 0.10,
                        child: Container(
                          padding: EdgeInsets.symmetric(
                            horizontal: 6.w,
                            vertical: 2.h,
                          ),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? AppColors.deepGreen
                                : context.surfaceColor,
                            borderRadius: BorderRadius.circular(10.r),
                          ),
                          child: Text(
                            count.toString(),
                            style: TextStyle(
                              color: isSelected ? Colors.white : context.textPrimaryColor,
                              fontSize: 11.sp,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
        ),
      );
  }
}
