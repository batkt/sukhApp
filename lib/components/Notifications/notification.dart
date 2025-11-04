import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

// Notification Dropdown Widget
class NotificationDropdown extends StatelessWidget {
  const NotificationDropdown({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 320.w,
      constraints: BoxConstraints(maxHeight: 400.h),
      decoration: BoxDecoration(
        color: const Color(0xFF1a1a2e),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: const Color(0xFFe6ff00).withOpacity(0.3),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.3),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Header
          Padding(
            padding: EdgeInsets.all(16.w),
            child: Row(
              children: [
                Text(
                  'Мэдэгдэл',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18.sp,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                TextButton(
                  onPressed: () {
                    Navigator.pop(context);
                  },
                  child: Text(
                    'Бүгдийг унших',
                    style: TextStyle(color: const Color(0xFFe6ff00), fontSize: 12.sp),
                  ),
                ),
              ],
            ),
          ),
          const Divider(color: Colors.white12, height: 1),

          // Notifications List
          Flexible(
            child: ListView(
              shrinkWrap: true,
              padding: EdgeInsets.symmetric(vertical: 8.h),
              children: [
                _buildNotificationItem(
                  context,
                  icon: Icons.payment,
                  title: 'Төлбөр амжилттай',
                  message: 'Таны 25,880₮ төлбөр төлөгдлөө',
                  time: '5 мин',
                  isUnread: true,
                ),
                _buildNotificationItem(
                  context,
                  icon: Icons.calendar_today,
                  title: 'Захиалга баталгаажлаа',
                  message: '12-р сарын захиалга баталгаажлаа',
                  time: '2 цаг',
                  isUnread: true,
                ),
                _buildNotificationItem(
                  context,
                  icon: Icons.notifications_active,
                  title: 'Сэрэмжлүүлэг',
                  message: 'Дараагийн төлбөр 3 хоногийн дараа',
                  time: '5 цаг',
                  isUnread: true,
                ),
              ],
            ),
          ),

          const Divider(color: Colors.white12, height: 1),

          InkWell(
            onTap: () {
              Navigator.pop(context);
            },
            child: Container(
              padding: EdgeInsets.all(12.w),
              child: Center(
                child: Text(
                  'Бүх мэдэгдлийг харах',
                  style: TextStyle(
                    color: const Color(0xFFe6ff00),
                    fontSize: 14.sp,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNotificationItem(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String message,
    required String time,
    required bool isUnread,
  }) {
    return InkWell(
      onTap: () {
        Navigator.pop(context);
        // Handle notification tap
      },
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
        decoration: BoxDecoration(
          color: isUnread
              ? const Color(0xFFe6ff00).withOpacity(0.05)
              : Colors.transparent,
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: EdgeInsets.all(8.w),
              decoration: BoxDecoration(
                color: const Color(0xFFFFFFFF).withOpacity(0.2),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, color: const Color(0xFFe6ff00), size: 20.sp),
            ),
            SizedBox(width: 12.w),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          title,
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 14.sp,
                            fontWeight: FontWeight.w600,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (isUnread)
                        Container(
                          width: 6.w,
                          height: 6.w,
                          decoration: const BoxDecoration(
                            color: Color(0xFFe6ff00),
                            shape: BoxShape.circle,
                          ),
                        ),
                    ],
                  ),
                  SizedBox(height: 4.h),
                  Text(
                    message,
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.6),
                      fontSize: 12.sp,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  SizedBox(height: 4.h),
                  Text(
                    time,
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.4),
                      fontSize: 11.sp,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// Full Notifications Page (keep this for "View All" functionality)
class NotificationsPage extends StatelessWidget {
  const NotificationsPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1a1a2e),
      body: SafeArea(
        child: Column(
          children: [
            // Header
            Padding(
              padding: EdgeInsets.all(16.w),
              child: Row(
                children: [
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.3),
                      shape: BoxShape.circle,
                    ),
                    child: IconButton(
                      icon: Icon(Icons.arrow_back, color: Colors.white, size: 24.sp),
                      onPressed: () {
                        Navigator.pop(context);
                      },
                    ),
                  ),
                  SizedBox(width: 16.w),
                  Text(
                    'Мэдэгдэл',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 24.sp,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const Spacer(),
                  TextButton(
                    onPressed: () {
                      // Mark all as read
                    },
                    child: Text(
                      'Бүгдийг унших',
                      style: TextStyle(color: const Color(0xFFe6ff00), fontSize: 14.sp),
                    ),
                  ),
                ],
              ),
            ),

            // Notifications List
            Expanded(
              child: ListView(
                padding: EdgeInsets.symmetric(horizontal: 16.w),
                children: [
                  _buildNotificationItem(
                    icon: Icons.payment,
                    title: 'Төлбөр амжилттай',
                    message: 'Таны 25,880₮ төлбөр амжилттай төлөгдлөө',
                    time: '5 минутын өмнө',
                    isUnread: true,
                  ),
                  _buildNotificationItem(
                    icon: Icons.calendar_today,
                    title: 'Захиалга баталгаажлаа',
                    message: 'Таны 12-р сарын захиалга баталгаажлаа',
                    time: '2 цагийн өмнө',
                    isUnread: true,
                  ),
                  _buildNotificationItem(
                    icon: Icons.notifications_active,
                    title: 'Сэрэмжлүүлэг',
                    message: 'Таны дараагийн төлбөр 3 хоногийн дараа',
                    time: '5 цагийн өмнө',
                    isUnread: true,
                  ),
                  _buildNotificationItem(
                    icon: Icons.check_circle,
                    title: 'Баталгаажуулалт',
                    message: 'Таны бүртгэл амжилттай баталгаажлаа',
                    time: 'Өчигдөр',
                    isUnread: false,
                  ),
                  _buildNotificationItem(
                    icon: Icons.info,
                    title: 'Системийн мэдээлэл',
                    message: 'Системд шинэчлэлт хийгдсэн байна',
                    time: '2 өдрийн өмнө',
                    isUnread: false,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNotificationItem({
    required IconData icon,
    required String title,
    required String message,
    required String time,
    required bool isUnread,
  }) {
    return Container(
      margin: EdgeInsets.only(bottom: 12.h),
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: isUnread
            ? const Color(0xFFe6ff00).withOpacity(0.1)
            : Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isUnread
              ? const Color(0xFFe6ff00).withOpacity(0.3)
              : Colors.white.withOpacity(0.1),
          width: 1,
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: EdgeInsets.all(12.w),
            decoration: BoxDecoration(
              color: const Color(0xFFe6ff00).withOpacity(0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: const Color(0xFFe6ff00), size: 24.sp),
          ),
          SizedBox(width: 16.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        title,
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 16.sp,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    if (isUnread)
                      Container(
                        width: 8.w,
                        height: 8.w,
                        decoration: const BoxDecoration(
                          color: Color(0xFFe6ff00),
                          shape: BoxShape.circle,
                        ),
                      ),
                  ],
                ),
                SizedBox(height: 4.h),
                Text(
                  message,
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.7),
                    fontSize: 14.sp,
                  ),
                ),
                SizedBox(height: 8.h),
                Text(
                  time,
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.5),
                    fontSize: 12.sp,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
