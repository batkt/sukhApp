import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:sukh_app/services/api_service.dart';
import 'package:sukh_app/services/socket_service.dart';
import 'package:sukh_app/models/medegdel_model.dart';
import 'package:sukh_app/constants/constants.dart';
import 'package:sukh_app/utils/theme_extensions.dart';
import 'package:sukh_app/screens/medegdel/medegdel_detail.dart';

class NotificationModal extends StatefulWidget {
  const NotificationModal({super.key});

  @override
  State<NotificationModal> createState() => _NotificationModalState();
}

class _NotificationModalState extends State<NotificationModal> {
  List<Medegdel> _notifications = [];
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadNotifications();
    _setupSocketListener();
  }

  void _setupSocketListener() {
    // Listen for real-time notifications via socket
    _notificationCallback = (notification) {
      // Check if it's a reply notification
      final turul = notification['turul']?.toString().toLowerCase() ?? '';
      final isReply = turul == 'хариу' || turul == 'hariu' || turul == 'khariu';

      // Refresh notifications when new one arrives
      if (mounted) {
        print(
          '📬 Modal: Received socket notification (reply: $isReply), refreshing list',
        );
        _loadNotifications();
      }
    };
    SocketService.instance.setNotificationCallback(_notificationCallback!);
  }

  Function(Map<String, dynamic>)? _notificationCallback;

  @override
  void dispose() {
    // Remove only this modal's callback when disposed
    if (_notificationCallback != null) {
      SocketService.instance.removeNotificationCallback(_notificationCallback);
    }
    super.dispose();
  }

  Future<void> _loadNotifications() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final response = await ApiService.fetchMedegdel();
      final medegdelResponse = MedegdelResponse.fromJson(response);

      setState(() {
        _notifications = medegdelResponse.data;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = e.toString();
        _isLoading = false;
      });
    }
  }

  bool _isZardluudNotification(Medegdel notification) {
    final title = notification.title.toLowerCase();
    final message = notification.message.toLowerCase();

    // ONLY redirect for ashiglaltiinZardal (usage charges) notifications
    // Check specifically for "ашиглалтын зардал" or "ashiglaltiinZardal"
    final isAshiglaltiinZardal =
        title.contains('ашиглалтын зардал') ||
        title.contains('ashiglaltiin zardal') ||
        title.contains('ashiglaltiinzardal') ||
        message.contains('ашиглалтын зардал') ||
        message.contains('ashiglaltiin zardal') ||
        message.contains('ashiglaltiinzardal');

    return isAshiglaltiinZardal;
  }

  Future<void> _markAsRead(Medegdel notification) async {
    if (notification.kharsanEsekh) return;

    try {
      await ApiService.markMedegdelAsRead(notification.id);
      setState(() {
        final index = _notifications.indexWhere((n) => n.id == notification.id);
        if (index != -1) {
          _notifications[index] = Medegdel(
            id: notification.id,
            parentId: notification.parentId,
            baiguullagiinId: notification.baiguullagiinId,
            barilgiinId: notification.barilgiinId,
            ognoo: notification.ognoo,
            title: notification.title,
            gereeniiDugaar: notification.gereeniiDugaar,
            message: notification.message,
            orshinSuugchGereeniiDugaar: notification.orshinSuugchGereeniiDugaar,
            orshinSuugchId: notification.orshinSuugchId,
            orshinSuugchNer: notification.orshinSuugchNer,
            orshinSuugchUtas: notification.orshinSuugchUtas,
            kharsanEsekh: true,
            turul: notification.turul,
            createdAt: notification.createdAt,
            updatedAt: notification.updatedAt,
            status: notification.status,
            tailbar: notification.tailbar,
            repliedAt: notification.repliedAt,
          );
        }
      });
    } catch (e) {
      // Silently handle error
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.85,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [AppColors.darkBackground, AppColors.darkSurface],
        ),
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(24.r),
          topRight: Radius.circular(24.r),
        ),
      ),
      child: Column(
        children: [
          // Handle bar
          Container(
            margin: EdgeInsets.only(top: 12.h),
            width: 40.w,
            height: 4.h,
            decoration: BoxDecoration(
              color: context.borderColor,
              borderRadius: BorderRadius.circular(2.r),
            ),
          ),
          // Header
          Padding(
            padding: EdgeInsets.all(16.w),
            child: Row(
              children: [
                Text(
                  'Мэдэгдэл',
                  style: TextStyle(
                    color: context.textPrimaryColor,
                    fontSize: 24.sp,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                TextButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                    context.push('/medegdel-list');
                  },
                  child: Text(
                    'Бүгдийг харах',
                    style: TextStyle(
                      color: AppColors.secondaryAccent,
                      fontSize: 14.sp,
                    ),
                  ),
                ),
              ],
            ),
          ),
          // Content
          Expanded(
            child: _isLoading
                ? Center(
                    child: CircularProgressIndicator(
                      color: context.textPrimaryColor,
                    ),
                  )
                : _errorMessage != null
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.error_outline,
                          color: context.textSecondaryColor,
                          size: 48.sp,
                        ),
                        SizedBox(height: 16.h),
                        Text(
                          _errorMessage!,
                          style: TextStyle(
                            color: context.textPrimaryColor,
                            fontSize: 14.sp,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        SizedBox(height: 24.h),
                        ElevatedButton(
                          onPressed: _loadNotifications,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.secondaryAccent,
                            foregroundColor: AppColors.darkBackground,
                            padding: EdgeInsets.symmetric(
                              horizontal: 24.w,
                              vertical: 12.h,
                            ),
                          ),
                          child: Text(
                            'Дахин оролдох',
                            style: TextStyle(fontSize: 14.sp),
                          ),
                        ),
                      ],
                    ),
                  )
                : _notifications.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.notifications_none,
                          color: context.textSecondaryColor,
                          size: 64.sp,
                        ),
                        SizedBox(height: 16.h),
                        Text(
                          'Мэдэгдэл байхгүй',
                          style: TextStyle(
                            color: context.textPrimaryColor,
                            fontSize: 18.sp,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        SizedBox(height: 8.h),
                        Text(
                          'Шинэ мэдэгдэл ирэхэд энд харагдана',
                          style: TextStyle(
                            color: context.textSecondaryColor,
                            fontSize: 14.sp,
                          ),
                        ),
                      ],
                    ),
                  )
                : RefreshIndicator(
                    onRefresh: _loadNotifications,
                    color: AppColors.secondaryAccent,
                    child: ListView.builder(
                      padding: EdgeInsets.symmetric(horizontal: 16.w),
                      itemCount: _notifications.length,
                      itemBuilder: (context, index) {
                        final notification = _notifications[index];
                        return _buildNotificationCard(notification);
                      },
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildNotificationIcon(Medegdel notification) {
    // Use notification icon for all notifications
    return Icon(Icons.notifications, color: Colors.white, size: 24.sp);
  }

  Widget _buildNotificationCard(Medegdel notification) {
    final isRead = notification.kharsanEsekh;
    return GestureDetector(
      onTap: () async {
        // Check if this is a zardluud (expense/charge) notification
        final isZardluudNotification = _isZardluudNotification(notification);

        if (isZardluudNotification) {
          // Close the notification modal
          Navigator.of(context).pop();
          // Redirect to nekhemjlekh page
          context.push('/nekhemjlekh');
          // Mark as read
          _markAsRead(notification);
          return;
        }

        // Show detail as modal for other notifications
        final result = await showModalBottomSheet(
          context: context,
          isScrollControlled: true,
          backgroundColor: Colors.transparent,
          builder: (BuildContext context) {
            return MedegdelDetailModal(notification: notification);
          },
        );
        // If detail modal marked as read, refresh the list
        if (result == true) {
          _loadNotifications();
        } else {
          // Otherwise just mark as read if not already
          _markAsRead(notification);
        }
      },
      child: Container(
        margin: EdgeInsets.only(bottom: 10.h),
        padding: EdgeInsets.all(12.w),
        decoration: BoxDecoration(
          color: isRead
              ? Colors.white.withOpacity(0.05)
              : AppColors.secondaryAccent.withOpacity(0.15),
          borderRadius: BorderRadius.circular(16.w),
          border: Border.all(
            color: isRead
                ? Colors.white.withOpacity(0.2)
                : AppColors.secondaryAccent.withOpacity(0.5),
            width: isRead ? 1 : 2,
          ),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Notification icon
            Container(
              width: 48.w,
              height: 48.w,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12.w),
              ),
              child: Center(child: _buildNotificationIcon(notification)),
            ),
            SizedBox(width: 12.w),
            // Content
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          notification.title,
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 15.sp,
                            fontWeight: isRead
                                ? FontWeight.w500
                                : FontWeight.bold,
                          ),
                        ),
                      ),
                      if (!isRead)
                        Container(
                          width: 8.w,
                          height: 8.w,
                          decoration: BoxDecoration(
                            color: AppColors.secondaryAccent,
                            shape: BoxShape.circle,
                          ),
                        ),
                    ],
                  ),
                  SizedBox(height: 6.h),
                  Text(
                    notification.message,
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.8),
                      fontSize: 13.sp,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  SizedBox(height: 8.h),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        notification.formattedDateTime,
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.6),
                          fontSize: 11.sp,
                        ),
                      ),
                      if (!isRead)
                        Text(
                          'Шинэ',
                          style: TextStyle(
                            color: AppColors.secondaryAccent,
                            fontSize: 11.sp,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                    ],
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
