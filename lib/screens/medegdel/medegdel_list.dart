import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:sukh_app/services/api_service.dart';
import 'package:sukh_app/services/socket_service.dart';
import 'package:sukh_app/models/medegdel_model.dart';
import 'package:sukh_app/constants/constants.dart';
import 'package:sukh_app/screens/medegdel/medegdel_detail.dart';
import 'package:sukh_app/utils/theme_extensions.dart';
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
                  child: Text(
                    'Бүгдийг уншсан',
                    style: context.titleStyle(
                      color: AppColors.textPrimary,
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
                            color: context.inputGrayColor,
                            size: 48.sp,
                          ),
                          SizedBox(height: 16.h),
                          Text(
                            _errorMessage!,
                            style: TextStyle(
                              color: context.textSecondaryColor,
                              fontSize:
                                  20.sp, // Increased for better readability
                            ),
                            textAlign: TextAlign.center,
                          ),
                          SizedBox(height: 24.h),
                          ElevatedButton(
                            onPressed: _loadNotifications,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.deepGreenAccent,
                              foregroundColor: Colors.white,
                              padding: EdgeInsets.symmetric(
                                horizontal: 24.w,
                                vertical: 12.h,
                              ),
                            ),
                            child: Text(
                              'Дахин оролдох',
                              style: context.descriptionStyle(),
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
                            color: context.inputGrayColor,
                            size: 64.sp,
                          ),
                          SizedBox(height: 16.h),
                          Text(
                            'Мэдэгдэл байхгүй',
                            style: TextStyle(
                              color: context.textSecondaryColor,
                              fontSize:
                                  24.sp, // Increased for better readability
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          SizedBox(height: 8.h),
                          Text(
                            'Шинэ мэдэгдэл ирэхэд энд харагдана',
                            style: TextStyle(
                              color: context.inputGrayColor,
                              fontSize:
                                  20.sp, // Increased for better readability
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
    );
  }

  Widget _buildNotificationIcon(Medegdel notification) {
    // Use notification icon for all notifications
    return Icon(
      Icons.notifications,
      color: context.textPrimaryColor,
      size: 24.sp,
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
        // Check if this is a zardluud (expense/charge) notification
        final isZardluudNotification = _isZardluudNotification(notification);

        if (isZardluudNotification) {
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
        margin: EdgeInsets.only(bottom: 12.h),
        padding: EdgeInsets.all(16.w),
        decoration: BoxDecoration(
          color: isRead
              ? context.cardBackgroundColor
              : context.accentBackgroundColor, // Subtle green tint for unread
          borderRadius: BorderRadius.circular(16.w),
          border: Border.all(
            color: isRead
                ? context.borderColor
                : AppColors.deepGreen.withOpacity(0.3),
            width: 1,
          ),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Notification icon - modern minimal design
            Container(
              width: 48.w,
              height: 48.w,
              decoration: BoxDecoration(
                color: context.accentBackgroundColor,
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
                          style: context.titleStyle(
                            color: context.textPrimaryColor,
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
                            color: AppColors.deepGreenAccent,
                            shape: BoxShape.circle,
                          ),
                        ),
                    ],
                  ),
                  SizedBox(height: 6.h),
                  Text(
                    notification.message,
                    style: context.descriptionStyle(
                      color: context.textSecondaryColor,
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
                              fontSize:
                                  18.sp, // Increased for better readability
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
                              fontSize:
                                  18.sp, // Increased for better readability
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
                        style: context.secondaryDescriptionStyle(
                          color: context.inputGrayColor,
                        ),
                      ),
                      if (!isRead)
                        Text(
                          'Шинэ',
                          style: context.secondaryDescriptionStyle(
                            color: AppColors.deepGreenAccent,
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
