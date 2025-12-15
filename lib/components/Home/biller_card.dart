import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:sukh_app/components/Home/biller_utils.dart';
import 'package:sukh_app/widgets/optimized_glass.dart';

class BillerCard extends StatelessWidget {
  final Map<String, dynamic> biller;
  final bool isSquare;

  const BillerCard({super.key, required this.biller, this.isSquare = true});

  @override
  Widget build(BuildContext context) {
    final rawBillerName =
        biller['billerName']?.toString() ??
        biller['name']?.toString() ??
        'Биллер';
    final billerName = BillerUtils.transformBillerName(rawBillerName);
    final description = biller['description']?.toString() ?? '';
    final billerCode =
        biller['billerCode']?.toString() ?? biller['code']?.toString() ?? '';

    if (isSquare) {
      return Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Box with logo filling it - fixed height, width fills
          SizedBox(
            height: 70.h,
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: () {
                  context.push(
                    '/biller-detail',
                    extra: {
                      'billerCode': billerCode,
                      'billerName': billerName,
                      'description': description,
                    },
                  );
                },
                borderRadius: BorderRadius.circular(6.r),
                child: OptimizedGlass(
                  borderRadius: BorderRadius.circular(6.r),
                  child: Container(
                    width: double.infinity,
                    padding: EdgeInsets.all(8.w),
                    child: Center(
                      child: BillerUtils.buildBillerLogo(
                        rawBillerName,
                        transformedName: billerName,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
          // Title outside box at bottom
          SizedBox(height: 4.h),
          Text(
            billerName,
            style: TextStyle(
              color: Colors.white,
              fontSize: 9.sp,
              fontWeight: FontWeight.w500,
            ),
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      );
    } else {
      // Rectangular card
      return OptimizedGlass(
        borderRadius: BorderRadius.circular(11.r),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () {
              context.push(
                '/biller-detail',
                extra: {
                  'billerCode': billerCode,
                  'billerName': billerName,
                  'description': description,
                },
              );
            },
            borderRadius: BorderRadius.circular(11.r),
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 8.h),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  BillerUtils.buildBillerLogo(
                    rawBillerName,
                    transformedName: billerName,
                  ),
                  SizedBox(width: 12.w),
                  Text(
                    billerName,
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 11.sp,
                      fontWeight: FontWeight.w600,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    }
  }
}
