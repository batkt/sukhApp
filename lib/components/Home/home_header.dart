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
                      height: 48.h,
                      child: OptimizedGlass(
                        borderRadius: BorderRadius.circular(11.r),
                        child: Material(
                          color: Colors.transparent,
                          child: InkWell(
                            onTap: onNotificationTap,
                            borderRadius: BorderRadius.circular(11.r),
                            child: Padding(
                              padding: EdgeInsets.all(11.w),
                              child: Icon(
                                Icons.notifications_outlined,
                                color: context.textPrimaryColor,
                                size: 22.sp,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                    if (unreadNotificationCount > 0)
                      Positioned(
                        right: context.responsiveSpacing(
                          small: -2,
                          medium: -2,
                          large: -2,
                          tablet: -2,
                          veryNarrow: -1.5,
                        ),
                        top: context.responsiveSpacing(
                          small: -2,
                          medium: -2,
                          large: -2,
                          tablet: -2,
                          veryNarrow: -1.5,
                        ),
                        child: Container(
                          padding: EdgeInsets.symmetric(
                            horizontal: context.responsiveSpacing(
                              small: 5,
                              medium: 6,
                              large: 7,
                              tablet: 8,
                              veryNarrow: 4,
                            ),
                            vertical: context.responsiveSpacing(
                              small: 2,
                              medium: 2,
                              large: 3,
                              tablet: 3,
                              veryNarrow: 1.5,
                            ),
                          ),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                AppColors.secondaryAccent,
                                AppColors.secondaryAccent.withOpacity(0.8),
                              ],
                            ),
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: context.backgroundColor,
                              width: context.responsiveSpacing(
                                small: 1.5,
                                medium: 2,
                                large: 2,
                                tablet: 2.5,
                                veryNarrow: 1.5,
                              ),
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: AppColors.secondaryAccent.withOpacity(
                                  0.5,
                                ),
                                blurRadius: context.responsiveSpacing(
                                  small: 3,
                                  medium: 4,
                                  large: 5,
                                  tablet: 6,
                                  veryNarrow: 2.5,
                                ),
                                spreadRadius: 0,
                              ),
                            ],
                          ),
                          constraints: BoxConstraints(
                            minWidth: context.responsiveSpacing(
                              small: 18,
                              medium: 20,
                              large: 22,
                              tablet: 24,
                              veryNarrow: 16,
                            ),
                            minHeight: context.responsiveSpacing(
                              small: 18,
                              medium: 20,
                              large: 22,
                              tablet: 24,
                              veryNarrow: 16,
                            ),
                          ),
                          child: Center(
                            child: Text(
                              unreadNotificationCount > 99
                                  ? '99+'
                                  : '$unreadNotificationCount',
                              style: TextStyle(
                                color: context.backgroundColor,
                                fontSize: context.responsiveFontSize(
                                  small: 10,
                                  medium: 11,
                                  large: 12,
                                  tablet: 13,
                                  veryNarrow: 9,
                                ),
                                fontWeight: FontWeight.bold,
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
