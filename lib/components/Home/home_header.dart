import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:sukh_app/constants/constants.dart';
import 'package:sukh_app/utils/theme_extensions.dart';

/// Нүүр хуудасны толгой: цэс, мэндчилгээ, сэдэв ба мэдэгдэл.
/// Товчнууд нь тайван (хүрээтэй) — анхаарлыг доорх төлбөрийн карт руу үлдээнэ.
class HomeHeader extends StatelessWidget {
  final int unreadNotificationCount;
  final VoidCallback onMenuTap;
  final VoidCallback onThemeToggle;
  final VoidCallback onNotificationTap;

  /// Хэрэглэгчийн нэр (байхгүй бол зөвхөн мэндчилгээ)
  final String? userName;
  final GlobalKey? notificationKey;

  /// Идэвхтэй барилгын нэр. Хэрэглэгч олон барилгатай үед л дамжуулна.
  final String? barilgaNer;
  final VoidCallback? onBarilgaTap;

  const HomeHeader({
    super.key,
    required this.unreadNotificationCount,
    required this.onMenuTap,
    required this.onThemeToggle,
    required this.onNotificationTap,
    this.userName,
    this.notificationKey,
    this.barilgaNer,
    this.onBarilgaTap,
  });

  static String _mendchilgee() {
    final h = DateTime.now().hour;
    if (h >= 5 && h < 12) return 'Өглөөний мэнд';
    if (h >= 12 && h < 18) return 'Өдрийн мэнд';
    return 'Оройн мэнд';
  }

  @override
  Widget build(BuildContext context) {
    final isDark = context.isDarkMode;
    final ner = userName?.trim() ?? '';

    return SafeArea(
      bottom: false,
      child: Padding(
        padding: EdgeInsets.fromLTRB(16.w, 12.h, 16.w, 10.h),
        child: Row(
          children: [
            _buildIconButton(
              context,
              onTap: onMenuTap,
              icon: Icons.menu_rounded,
              tooltip: 'Цэс',
            ),
            SizedBox(width: 12.w),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    _mendchilgee(),
                    style: TextStyle(
                      fontSize: 12.sp,
                      color: context.textSecondaryColor,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  if (ner.isNotEmpty)
                    Text(
                      ner,
                      style: TextStyle(
                        fontSize: 17.sp,
                        color: context.textPrimaryColor,
                        fontWeight: FontWeight.w600,
                        letterSpacing: -0.3,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  if (barilgaNer != null && onBarilgaTap != null)
                    Padding(
                      padding: EdgeInsets.only(top: 4.h),
                      child: InkWell(
                        onTap: onBarilgaTap,
                        borderRadius: BorderRadius.circular(20),
                        child: Container(
                          padding: EdgeInsets.symmetric(
                            horizontal: 10.w,
                            vertical: 4.h,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.deepGreen.withOpacity(
                              isDark ? 0.25 : 0.08,
                            ),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.apartment_rounded,
                                size: 14.sp,
                                color: isDark
                                    ? Colors.white
                                    : AppColors.deepGreen,
                              ),
                              SizedBox(width: 6.w),
                              Flexible(
                                child: Text(
                                  barilgaNer!,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    fontSize: 12.sp,
                                    fontWeight: FontWeight.w600,
                                    color: isDark
                                        ? Colors.white
                                        : AppColors.deepGreen,
                                  ),
                                ),
                              ),
                              Icon(
                                Icons.keyboard_arrow_down_rounded,
                                size: 16.sp,
                                color: isDark
                                    ? Colors.white
                                    : AppColors.deepGreen,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
            _buildIconButton(
              context,
              onTap: onThemeToggle,
              icon: isDark ? Icons.light_mode_outlined : Icons.dark_mode_outlined,
              tooltip: isDark ? 'Цайвар горим' : 'Бараан горим',
            ),
            SizedBox(width: 8.w),
            Stack(
              key: notificationKey,
              clipBehavior: Clip.none,
              children: [
                _buildIconButton(
                  context,
                  onTap: onNotificationTap,
                  icon: Icons.notifications_none_rounded,
                  tooltip: 'Мэдэгдэл',
                ),
                if (unreadNotificationCount > 0)
                  Positioned(
                    right: -3,
                    top: -3,
                    child: Container(
                      padding: EdgeInsets.symmetric(horizontal: 5.w, vertical: 1.h),
                      constraints: BoxConstraints(minWidth: 17.w, minHeight: 17.w),
                      decoration: BoxDecoration(
                        color: const Color(0xFFE5484D),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: isDark ? AppColors.darkBackground : const Color(0xFFF3F5F2),
                          width: 2,
                        ),
                      ),
                      child: Center(
                        child: Text(
                          unreadNotificationCount > 99 ? '99+' : '$unreadNotificationCount',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 9.sp,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildIconButton(
    BuildContext context, {
    required VoidCallback onTap,
    required IconData icon,
    required String tooltip,
  }) {
    final isDark = context.isDarkMode;
    return Tooltip(
      message: tooltip,
      child: Material(
        color: isDark ? Colors.white.withOpacity(0.06) : Colors.white,
        shape: CircleBorder(
          side: BorderSide(
            color: isDark
                ? Colors.white.withOpacity(0.08)
                : AppColors.deepGreen.withOpacity(0.10),
          ),
        ),
        child: InkWell(
          customBorder: const CircleBorder(),
          onTap: onTap,
          child: Padding(
            padding: EdgeInsets.all(10.w),
            child: Icon(
              icon,
              color: isDark ? Colors.white : AppColors.deepGreen,
              size: 20.sp,
            ),
          ),
        ),
      ),
    );
  }
}
