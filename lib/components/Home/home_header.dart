import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:sukh_app/constants/constants.dart';
import 'package:sukh_app/widgets/optimized_glass.dart';
import 'package:sukh_app/utils/theme_extensions.dart';
import 'package:sukh_app/utils/responsive_helper.dart';

class HomeHeader extends StatelessWidget {
  final GlobalKey<ScaffoldState> scaffoldKey;
  final double totalNiitTulbur;
  final int unreadNotificationCount;
  final VoidCallback onTotalBalanceTap;
  final VoidCallback onNotificationTap;
  final String Function(double) formatNumberWithComma;

  const HomeHeader({
    super.key,
    required this.scaffoldKey,
    required this.totalNiitTulbur,
    required this.unreadNotificationCount,
    required this.onTotalBalanceTap,
    required this.onNotificationTap,
    required this.formatNumberWithComma,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(16.w, 12.h, 16.w, 8.h),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Menu Button
          SizedBox(
            height: 48.h,
            child: OptimizedGlass(
              borderRadius: BorderRadius.circular(11.r),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: () {
                    scaffoldKey.currentState?.openDrawer();
                  },
                  borderRadius: BorderRadius.circular(11.r),
                  child: Padding(
                    padding: EdgeInsets.all(11.w),
                    child: Icon(
                      Icons.menu_rounded,
                      color: context.textPrimaryColor,
                      size: 22.sp,
                    ),
                  ),
                ),
              ),
            ),
          ),
          // Total Balance Card
          Expanded(
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: 11.w),
              child: SizedBox(
                height: 48.h,
                child: OptimizedGlass(
                  borderRadius: BorderRadius.circular(11.r),
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: onTotalBalanceTap,
                      borderRadius: BorderRadius.circular(11.r),
                      child: Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: 14.w,
                          vertical: 0,
                        ),
                        child: Center(
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.account_balance_wallet_rounded,
                                color: AppColors.deepGreen,
                                size: 22.sp,
                              ),
                              SizedBox(width: 11.w),
                              Flexible(
                                child: Text(
                                  'Нийт үлдэгдэл',
                                  style: TextStyle(
                                    color: context.textSecondaryColor,
                                    fontSize: 11.sp,
                                    fontWeight: FontWeight.w500,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              SizedBox(width: 11.w),
                              Flexible(
                                child: Text(
                                  '${formatNumberWithComma(totalNiitTulbur)}₮',
                                  style: TextStyle(
                                    color: context.textPrimaryColor,
                                    fontSize: 11.sp,
                                    fontWeight: FontWeight.bold,
                                    letterSpacing: -0.3,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
          Row(
            children: [
              // Notification icon
              SizedBox(
                height: 48.h,
                child: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    SizedBox(
                      height: context.responsiveSpacing(
                        small: 52,
                        medium: 54,
                        large: 56,
                        tablet: 60,
                        veryNarrow: 48,
                      ),
                      child: OptimizedGlass(
                        borderRadius: BorderRadius.circular(context.responsiveBorderRadius(
                          small: 12,
                          medium: 13,
                          large: 14,
                          tablet: 16,
                          veryNarrow: 10,
                        )),
                        child: Material(
                          color: Colors.transparent,
                          child: InkWell(
                            onTap: onNotificationTap,
                            borderRadius: BorderRadius.circular(context.responsiveBorderRadius(
                              small: 12,
                              medium: 13,
                              large: 14,
                              tablet: 16,
                              veryNarrow: 10,
                            )),
                            child: Padding(
                              padding: EdgeInsets.all(context.responsiveSpacing(
                                small: 12,
                                medium: 13,
                                large: 14,
                                tablet: 16,
                                veryNarrow: 10,
                              )),
                              child: Icon(
                                Icons.notifications_outlined,
                                color: context.textPrimaryColor,
                                size: context.responsiveFontSize(
                                  small: 26,
                                  medium: 27,
                                  large: 28,
                                  tablet: 30,
                                  veryNarrow: 22,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                    if (unreadNotificationCount > 0)
                      Positioned(
                        right: -2,
                        top: -2,
                        child: Container(
                          padding: EdgeInsets.symmetric(
                            horizontal: unreadNotificationCount > 9 ? 5.w : 4.w,
                            vertical: 2.h,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.red,
                            borderRadius: BorderRadius.circular(12.r),
                            border: Border.all(
                              color: Colors.white,
                              width: 1.5,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.red.withOpacity(0.5),
                                blurRadius: 4,
                                spreadRadius: 0,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          constraints: BoxConstraints(
                            minWidth: 18.w,
                            minHeight: 18.h,
                          ),
                          child: Center(
                            child: Text(
                              unreadNotificationCount > 99
                                  ? '99+'
                                  : '$unreadNotificationCount',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 10.sp,
                                fontWeight: FontWeight.bold,
                                height: 1.0,
                              ),
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
