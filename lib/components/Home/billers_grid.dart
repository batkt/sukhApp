import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:sukh_app/components/Home/biller_card.dart';
import 'package:sukh_app/widgets/optimized_glass.dart';

class BillersGrid extends StatefulWidget {
  final List<Map<String, dynamic>> billers;
  final VoidCallback onDevelopmentTap;

  const BillersGrid({
    super.key,
    required this.billers,
    required this.onDevelopmentTap,
  });

  @override
  State<BillersGrid> createState() => _BillersGridState();
}

class _BillersGridState extends State<BillersGrid> {
  @override
  Widget build(BuildContext context) {
    // Take first 5 billers (3 in first row, 2 in second row)
    final allBillers = widget.billers.take(5).toList();
    final secondRowBillers = allBillers.skip(3).take(2).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Payment Services Grid
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 16.w),
          child: Container(
            margin: EdgeInsets.only(bottom: 12.h),
            child: OptimizedGlass(
              borderRadius: BorderRadius.circular(12.r),
              child: Container(
                padding: EdgeInsets.symmetric(vertical: 6.h),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header
                    Padding(
                      padding: EdgeInsets.only(
                        left: 8.w,
                        top: 6.h,
                        bottom: 6.h,
                      ),
                    ),
                    // Second row: 2 items filling the row
                    if (secondRowBillers.isNotEmpty) ...[
                      SizedBox(height: 4.h),
                      Padding(
                        padding: EdgeInsets.symmetric(horizontal: 8.w),
                        child: Row(
                          children: [
                            Expanded(
                              child: secondRowBillers.length > 0
                                  ? BillerCard(
                                      biller: secondRowBillers[0],
                                      isSquare: true,
                                    )
                                  : const SizedBox.shrink(),
                            ),
                            SizedBox(width: 6.w),
                            Expanded(
                              child: secondRowBillers.length > 1
                                  ? BillerCard(
                                      biller: secondRowBillers[1],
                                      isSquare: true,
                                    )
                                  : const SizedBox.shrink(),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
        ),
        // Зогсоол and Дуудлага - Separate containers
        // Padding(
        //   padding: EdgeInsets.symmetric(horizontal: 16.w),
        //   child: Row(
        //     children: [
        //       Expanded(
        //         child: GestureDetector(
        //           onTap: widget.onDevelopmentTap,
        //           child: OptimizedGlass(
        //             borderRadius: BorderRadius.circular(12.r),
        //             child: Container(
        //               padding: EdgeInsets.symmetric(
        //                 vertical: 12.h,
        //                 horizontal: 12.w,
        //               ),
        //               child: Row(
        //                 mainAxisAlignment: MainAxisAlignment.center,
        //                 children: [
        //                   Icon(
        //                     Icons.local_parking_outlined,
        //                     color: AppColors.secondaryAccent,
        //                     size: 20.sp,
        //                   ),
        //                   SizedBox(width: 8.w),
        //                   Text(
        //                     'Зогсоол',
        //                     style: TextStyle(
        //                       color: Colors.white,
        //                       fontSize: 11.sp,
        //                       fontWeight: FontWeight.w600,
        //                     ),
        //                   ),
        //                 ],
        //               ),
        //             ),
        //           ),
        //         ),
        //       ),
        //       SizedBox(width: 8.w),
        //       Expanded(
        //         child: GestureDetector(
        //           onTap: widget.onDevelopmentTap,
        //           child: OptimizedGlass(
        //             borderRadius: BorderRadius.circular(12.r),
        //             child: Container(
        //               padding: EdgeInsets.symmetric(
        //                 vertical: 12.h,
        //                 horizontal: 12.w,
        //               ),
        //               child: Row(
        //                 mainAxisAlignment: MainAxisAlignment.center,
        //                 children: [
        //                   Icon(
        //                     Icons.phone_outlined,
        //                     color: AppColors.secondaryAccent,
        //                     size: 20.sp,
        //                   ),
        //                   SizedBox(width: 8.w),
        //                   Text(
        //                     'Дуудлага',
        //                     style: TextStyle(
        //                       color: Colors.white,
        //                       fontSize: 11.sp,
        //                       fontWeight: FontWeight.w600,
        //                     ),
        //                   ),
        //                 ],
        //               ),
        //             ),
        //           ),
        //         ),
        //       ),
        //     ],
        //   ),
        // ),
      ],
    );
  }
}
