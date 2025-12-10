import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:sukh_app/services/api_service.dart';
import 'package:sukh_app/services/socket_service.dart';
import 'package:sukh_app/models/medegdel_model.dart';
import 'package:sukh_app/constants/constants.dart';
import 'package:sukh_app/screens/medegdel/medegdel_detail.dart';

class MedegdelListScreen extends StatefulWidget {
  const MedegdelListScreen({super.key});

  @override
  State<MedegdelListScreen> createState() => _MedegdelListScreenState();
}

class _MedegdelListScreenState extends State<MedegdelListScreen> {
  List<Medegdel> _notifications = [];
  bool _isLoading = true;
  String? _errorMessage;

  Function(Map<String, dynamic>)? _notificationCallback;

  @override
  void initState() {
    super.initState();
    _loadNotifications();
    _setupSocketListener();
  }

  void _setupSocketListener() {
    // Listen for real-time notifications via socket
    _notificationCallback = (notification) {
      // Check notification type
      final turul = notification['turul']?.toString().toLowerCase() ?? '';
      final isReply = turul == 'хариу' || turul == 'hariu' || turul == 'khariu';
      final isGomdolSanal = turul == 'gomdol' || turul == 'sanal';
      final isApp = turul == 'app';

      // Refresh for "app" type notifications and reply notifications (khariu)
      // But not for gomdol/sanal (those are handled by gomdol_sanal_progress screen)
      if (mounted && (isApp || isReply) && !isGomdolSanal) {
        _loadNotifications();
      }
    };
    SocketService.instance.setNotificationCallback(_notificationCallback!);
  }

  @override
  void dispose() {
    // Remove socket callback when screen is disposed
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

  Future<void> _markAsRead(Medegdel notification) async {
    if (notification.kharsanEsekh) return;

    try {
      await ApiService.markMedegdelAsRead(notification.id);
      setState(() {
        final index = _notifications.indexWhere((n) => n.id == notification.id);
        if (index != -1) {
          _notifications[index] = Medegdel(
            id: notification.id,
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
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [AppColors.darkBackground, AppColors.darkSurface],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // Header
              Padding(
                padding: EdgeInsets.all(16.w),
                child: Row(
                  children: [
                    IconButton(
                      icon: Icon(
                        Icons.arrow_back,
                        color: AppColors.textPrimary,
                        size: 28.sp,
                      ),
                      onPressed: () => context.pop(),
                    ),
                    SizedBox(width: 12.w),
                    Text(
                      'Мэдэгдэл',
                      style: TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 24.sp,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const Spacer(),
                  ],
                ),
              ),
              // Content
              Expanded(
                child: _isLoading
                    ? Center(
                        child: CircularProgressIndicator(
                          color: AppColors.textPrimary,
                        ),
                      )
                    : _errorMessage != null
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.error_outline,
                              color: AppColors.inputGray,
                              size: 48.sp,
                            ),
                            SizedBox(height: 16.h),
                            Text(
                              _errorMessage!,
                              style: TextStyle(
                                color: AppColors.textSecondary,
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
                              color: AppColors.inputGray,
                              size: 64.sp,
                            ),
                            SizedBox(height: 16.h),
                            Text(
                              'Мэдэгдэл байхгүй',
                              style: TextStyle(
                                color: AppColors.textSecondary,
                                fontSize: 18.sp,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            SizedBox(height: 8.h),
                            Text(
                              'Шинэ мэдэгдэл ирэхэд энд харагдана',
                              style: TextStyle(
                                color: AppColors.inputGray,
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
                          padding: EdgeInsets.all(16.w),
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
        ),
      ),
    );
  }

  Widget _buildNotificationIcon(Medegdel notification) {
    // Use notification icon for all notifications
    return Icon(Icons.notifications, color: AppColors.textPrimary, size: 24.sp);
  }

  Widget _buildNotificationCard(Medegdel notification) {
    final isRead = notification.kharsanEsekh;
    final hasReply = notification.hasReply;
    final isReply = notification.isReply;
    final isGomdol = notification.turul.toLowerCase() == 'gomdol';
    final isSanal = notification.turul.toLowerCase() == 'sanal';

    return GestureDetector(
      onTap: () async {
        // Show detail as modal
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
              ? AppColors.textPrimary.withOpacity(0.05)
              : AppColors.secondaryAccent.withOpacity(0.15),
          borderRadius: BorderRadius.circular(16.w),
          border: Border.all(
            color: isRead
                ? AppColors.textPrimary.withOpacity(0.2)
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
                color: AppColors.textPrimary.withOpacity(0.1),
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
                            color: AppColors.textPrimary,
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
                      color: AppColors.textSecondary,
                      fontSize: 13.sp,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  // Show reply indicator if has reply
                  if (hasReply && (isGomdol || isSanal)) ...[
                    SizedBox(height: 6.h),
                    Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: 8.w,
                        vertical: 4.h,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.success.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(6.w),
                        border: Border.all(
                          color: AppColors.success.withOpacity(0.5),
                          width: 1,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.reply,
                            color: AppColors.success,
                            size: 12.sp,
                          ),
                          SizedBox(width: 4.w),
                          Text(
                            'Хариу ирсэн',
                            style: TextStyle(
                              color: AppColors.success,
                              fontSize: 11.sp,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                  // Show reply type indicator
                  if (isReply) ...[
                    SizedBox(height: 6.h),
                    Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: 8.w,
                        vertical: 4.h,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(6.w),
                        border: Border.all(
                          color: AppColors.primary.withOpacity(0.5),
                          width: 1,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.reply_all,
                            color: AppColors.primary,
                            size: 12.sp,
                          ),
                          SizedBox(width: 4.w),
                          Text(
                            'Хариу',
                            style: TextStyle(
                              color: AppColors.primary,
                              fontSize: 11.sp,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                  SizedBox(height: 8.h),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        notification.formattedDateTime,
                        style: TextStyle(
                          color: AppColors.inputGray,
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
