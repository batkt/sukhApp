import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:sukh_app/components/Home/billers_grid.dart';
import 'package:sukh_app/constants/constants.dart';
import 'package:sukh_app/utils/theme_extensions.dart';

class BillersSection extends StatelessWidget {
  final bool isLoadingBillers;
  final List<Map<String, dynamic>> billers;
  final VoidCallback onDevelopmentTap;
  final VoidCallback onBillerTap;

  const BillersSection({
    super.key,
    required this.isLoadingBillers,
    required this.billers,
    required this.onDevelopmentTap,
    required this.onBillerTap,
  });

  @override
  Widget build(BuildContext context) {
    if (isLoadingBillers) {
      return SizedBox(
        height: 200.h,
        child: const Center(
          child: CircularProgressIndicator(color: AppColors.deepGreen),
        ),
      );
    }

    if (billers.isEmpty) {
      return SizedBox(
        height: 200.h,
        child: Center(
          child: Text(
            'Биллер олдсонгүй',
            style: TextStyle(
              color: context.textSecondaryColor,
              fontSize: 16.sp,
            ),
          ),
        ),
      );
    }

    return BillersGrid(
      billers: billers,
      onDevelopmentTap: onDevelopmentTap,
      onBillerTap: onBillerTap,
    );
  }
}
