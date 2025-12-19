import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:sukh_app/components/Home/biller_utils.dart';
import 'package:sukh_app/utils/theme_extensions.dart';
import 'package:sukh_app/utils/responsive_helper.dart';
import 'package:sukh_app/widgets/optimized_glass.dart';

class BillerCard extends StatelessWidget {
  final Map<String, dynamic> biller;
  final bool isSquare;
  final VoidCallback? onTapCallback;

  const BillerCard({
    super.key,
    required this.biller,
    this.isSquare = true,
    this.onTapCallback,
  });

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
                  // Call callback if provided (to show empty message)
                  onTapCallback?.call();
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
                    alignment: Alignment.center,
                    child: BillerUtils.buildBillerLogo(
                      rawBillerName,
                      transformedName: billerName,
                    ),
                  ),
                ),
              ),
            ),
          ),
          // Title outside box at bottom
          SizedBox(
            height: context.responsiveSpacing(
              small: 4,
              medium: 6,
              large: 8,
              tablet: 10,
              veryNarrow: 3,
            ),
          ),
          Center(
            child: Padding(
              padding: EdgeInsets.symmetric(
                horizontal: context.responsiveSpacing(
                  small: 2,
                  medium: 4,
                  large: 6,
                  tablet: 8,
                  veryNarrow: 1,
                ),
              ),
              child: Text(
                billerName,
                style: TextStyle(
                  color: context.textPrimaryColor,
                  fontSize: context.responsiveFontSize(
                    small: 16,
                    medium: 18,
                    large: 20,
                    tablet: 22,
                    veryNarrow: 14,
                  ),
                  fontWeight: FontWeight.w500,
                  height: 1.2,
                ),
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
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
                      color: context.textPrimaryColor,
                      fontSize: 20.sp, // Increased from 11 for better readability
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
