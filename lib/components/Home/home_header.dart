import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:sukh_app/constants/constants.dart';
import 'package:sukh_app/widgets/optimized_glass.dart';

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
                      color: Colors.white,
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
                                color: AppColors.goldPrimary,
                                size: 22.sp,
                              ),
                              SizedBox(width: 11.w),
                              Flexible(
                                child: Text(
                                  'Нийт үлдэгдэл',
                                  style: TextStyle(
                                    color: Colors.white.withOpacity(0.8),
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
                                    color: Colors.white,
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
                                color: Colors.white,
                                size: 22.sp,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                    if (unreadNotificationCount > 0)
                      Positioned(
                        right: -2.w,
                        top: -2.h,
                        child: Container(
                          padding: EdgeInsets.symmetric(
                            horizontal: 6.w,
                            vertical: 2.h,
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
                              color: AppColors.darkBackground,
                              width: 2,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: AppColors.secondaryAccent.withOpacity(
                                  0.5,
                                ),
                                blurRadius: 4.w,
                                spreadRadius: 0,
                              ),
                            ],
                          ),
                          constraints: BoxConstraints(
                            minWidth: 20.w,
                            minHeight: 20.w,
                          ),
                          child: Center(
                            child: Text(
                              unreadNotificationCount > 99
                                  ? '99+'
                                  : '$unreadNotificationCount',
                              style: TextStyle(
                                color: AppColors.darkBackground,
                                fontSize: 11.sp,
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
