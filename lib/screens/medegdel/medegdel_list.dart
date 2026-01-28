import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:sukh_app/services/api_service.dart';
import 'package:sukh_app/services/socket_service.dart';
import 'package:sukh_app/models/medegdel_model.dart';
import 'package:sukh_app/constants/constants.dart';
import 'package:sukh_app/screens/medegdel/medegdel_detail.dart';
import 'package:sukh_app/utils/theme_extensions.dart';
import 'package:sukh_app/utils/responsive_helper.dart';
import 'package:sukh_app/widgets/standard_app_bar.dart';

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
      final isMedegdel = turul == 'мэдэгдэл' || turul == 'medegdel';

      // Refresh for "app" type, "мэдэгдэл" (notification), and reply notifications (khariu)
      // But not for gomdol/sanal (those are handled by gomdol_sanal_progress screen)
      if (mounted && (isApp || isMedegdel || isReply) && !isGomdolSanal) {
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

  Future<void> _markAllAsRead() async {
    final unreadNotifications = _notifications
        .where((n) => !n.kharsanEsekh)
        .toList();

    if (unreadNotifications.isEmpty) {
      return;
    }

    // Mark all unread notifications as read
    for (var notification in unreadNotifications) {
      try {
        await ApiService.markMedegdelAsRead(notification.id);
      } catch (e) {
        // Continue with next notification if one fails
        continue;
      }
    }

    // Refresh the list
    _loadNotifications();
  }

  @override
  Widget build(BuildContext context) {
    final unreadCount = _notifications.where((n) => !n.kharsanEsekh).length;

    return Scaffold(
      backgroundColor: context.backgroundColor,
      appBar: buildStandardAppBar(
        context,
        title: 'Мэдэгдэл',
        actions: unreadCount > 0
            ? [
                TextButton(
                  onPressed: _markAllAsRead,
                  style: TextButton.styleFrom(
                    padding: EdgeInsets.symmetric(horizontal: 12.w),
                  ),
                  child: Text(
                    'Бүгдийг уншсан',
                    style: TextStyle(
                      color: AppColors.deepGreen,
                      fontSize: 10.sp,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ]
            : null,
      ),
      body: SafeArea(
        child: Column(
          children: [
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
                            size: 36.sp,
                          ),
                          SizedBox(height: 12.h),
                          Text(
                            _errorMessage!,
                            style: TextStyle(
                              color: context.textPrimaryColor,
                              fontSize: 12.sp,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          SizedBox(height: 16.h),
                          ElevatedButton(
                            onPressed: _loadNotifications,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.deepGreen,
                              foregroundColor: Colors.white,
                              padding: EdgeInsets.symmetric(
                                horizontal: 16.w,
                                vertical: 10.h,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10.r),
                              ),
                            ),
                            child: Text(
                              'Дахин оролдох',
                              style: TextStyle(fontSize: 11.sp),
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
                            size: 48.sp,
                          ),
                          SizedBox(height: 12.h),
                          Text(
                            'Мэдэгдэл байхгүй',
                            style: TextStyle(
                              color: context.textPrimaryColor,
                              fontSize: 14.sp,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          SizedBox(height: 6.h),
                          Text(
                            'Шинэ мэдэгдэл ирэхэд энд харагдана',
                            style: TextStyle(
                              color: context.textSecondaryColor,
                              fontSize: 11.sp,
                            ),
                          ),
                        ],
                      ),
                    )
                  : RefreshIndicator(
                      onRefresh: _loadNotifications,
                      color: AppColors.deepGreen,
                      child: ListView.builder(
                        padding: EdgeInsets.all(14.w),
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
    );
  }

  Widget _buildNotificationIcon(Medegdel notification) {
    return Icon(
      Icons.notifications_outlined,
      color: AppColors.deepGreen,
      size: 18.sp,
    );
  }

  Widget _buildNotificationCard(Medegdel notification) {
    final isRead = notification.kharsanEsekh;
    final hasReply = notification.hasReply;
    final isReply = notification.isReply;
    final isGomdol = notification.turul.toLowerCase() == 'gomdol';
    final isSanal = notification.turul.toLowerCase() == 'sanal';

    return GestureDetector(
      onTap: () async {
        final isZardluudNotification = _isZardluudNotification(notification);

        if (isZardluudNotification) {
          context.push('/nekhemjlekh');
          _markAsRead(notification);
          return;
        }

        final result = await showModalBottomSheet(
          context: context,
          isScrollControlled: true,
          backgroundColor: Colors.transparent,
          builder: (BuildContext context) {
            return MedegdelDetailModal(notification: notification);
          },
        );
        if (result == true) {
          _loadNotifications();
        } else {
          _markAsRead(notification);
        }
      },
      child: Container(
        margin: EdgeInsets.only(bottom: 10.h),
        padding: EdgeInsets.all(12.w),
        decoration: BoxDecoration(
          color: context.isDarkMode
              ? const Color(0xFF1A1A1A)
              : Colors.white,
          borderRadius: BorderRadius.circular(14.r),
          border: Border.all(
            color: isRead
                ? (context.isDarkMode
                    ? AppColors.deepGreen.withOpacity(0.15)
                    : AppColors.deepGreen.withOpacity(0.1))
                : AppColors.deepGreen.withOpacity(0.3),
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: context.isDarkMode
                  ? Colors.black.withOpacity(0.2)
                  : Colors.black.withOpacity(0.04),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 40.w,
              height: 40.w,
              decoration: BoxDecoration(
                color: AppColors.deepGreen.withOpacity(0.1),
                borderRadius: BorderRadius.circular(10.r),
              ),
              child: Center(child: _buildNotificationIcon(notification)),
            ),
            SizedBox(width: 10.w),
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
                            color: context.textPrimaryColor,
                            fontSize: 12.sp,
                            fontWeight: isRead ? FontWeight.w500 : FontWeight.w600,
                          ),
                        ),
                      ),
                      if (!isRead)
                        Container(
                          width: 6.w,
                          height: 6.w,
                          decoration: BoxDecoration(
                            color: AppColors.deepGreen,
                            shape: BoxShape.circle,
                          ),
                        ),
                    ],
                  ),
                  SizedBox(height: 4.h),
                  Text(
                    notification.message,
                    style: TextStyle(
                      color: context.textSecondaryColor,
                      fontSize: 11.sp,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  // Show reply indicator if has reply
                  if (hasReply && (isGomdol || isSanal)) ...[
                    SizedBox(height: 6.h),
                    Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: 6.w,
                        vertical: 3.h,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.success.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(6.r),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.reply,
                            color: AppColors.success,
                            size: 10.sp,
                          ),
                          SizedBox(width: 4.w),
                          Text(
                            'Хариу ирсэн',
                            style: TextStyle(
                              color: AppColors.success,
                              fontSize: 9.sp,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                  if (isReply) ...[
                    SizedBox(height: 6.h),
                    Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: 6.w,
                        vertical: 3.h,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.deepGreen.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(6.r),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.reply_all,
                            color: AppColors.deepGreen,
                            size: 10.sp,
                          ),
                          SizedBox(width: 4.w),
                          Text(
                            'Хариу',
                            style: TextStyle(
                              color: AppColors.deepGreen,
                              fontSize: 9.sp,
                              fontWeight: FontWeight.w600,
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
                          color: context.textSecondaryColor,
                          fontSize: 9.sp,
                        ),
                      ),
                      if (!isRead)
                        Text(
                          'Шинэ',
                          style: TextStyle(
                            color: AppColors.deepGreen,
                            fontSize: 9.sp,
                            fontWeight: FontWeight.w600,
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
