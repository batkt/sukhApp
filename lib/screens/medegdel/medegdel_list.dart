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
                    padding: EdgeInsets.symmetric(horizontal: context.responsiveSpacing(
                      small: 12,
                      medium: 13,
                      large: 14,
                      tablet: 16,
                      veryNarrow: 10,
                    )),
                  ),
                  child: Text(
                    'Бүгдийг уншсан',
                    style: TextStyle(
                      color: AppColors.deepGreen,
                      fontSize: context.responsiveFontSize(
                        small: 10,
                        medium: 11,
                        large: 12,
                        tablet: 14,
                        veryNarrow: 9,
                      ),
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
                            size: context.responsiveFontSize(
                              small: 36,
                              medium: 38,
                              large: 40,
                              tablet: 44,
                              veryNarrow: 30,
                            ),
                          ),
                          SizedBox(height: context.responsiveSpacing(
                            small: 12,
                            medium: 13,
                            large: 14,
                            tablet: 16,
                            veryNarrow: 10,
                          )),
                          Text(
                            _errorMessage!,
                            style: TextStyle(
                              color: context.textPrimaryColor,
                              fontSize: context.responsiveFontSize(
                                small: 12,
                                medium: 13,
                                large: 14,
                                tablet: 16,
                                veryNarrow: 10,
                              ),
                            ),
                            textAlign: TextAlign.center,
                          ),
                          SizedBox(height: context.responsiveSpacing(
                            small: 16,
                            medium: 17,
                            large: 18,
                            tablet: 20,
                            veryNarrow: 12,
                          )),
                          ElevatedButton(
                            onPressed: _loadNotifications,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.deepGreen,
                              foregroundColor: Colors.white,
                              padding: EdgeInsets.symmetric(
                                horizontal: context.responsiveSpacing(
                                  small: 16,
                                  medium: 17,
                                  large: 18,
                                  tablet: 20,
                                  veryNarrow: 12,
                                ),
                                vertical: context.responsiveSpacing(
                                  small: 10,
                                  medium: 11,
                                  large: 12,
                                  tablet: 14,
                                  veryNarrow: 8,
                                ),
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(context.responsiveBorderRadius(
                                  small: 10,
                                  medium: 11,
                                  large: 12,
                                  tablet: 14,
                                  veryNarrow: 8,
                                )),
                              ),
                            ),
                            child: Text(
                              'Дахин оролдох',
                              style: TextStyle(fontSize: context.responsiveFontSize(
                                small: 11,
                                medium: 12,
                                large: 13,
                                tablet: 15,
                                veryNarrow: 10,
                              )),
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
                            size: context.responsiveFontSize(
                              small: 48,
                              medium: 50,
                              large: 52,
                              tablet: 56,
                              veryNarrow: 40,
                            ),
                          ),
                          SizedBox(height: context.responsiveSpacing(
                            small: 12,
                            medium: 13,
                            large: 14,
                            tablet: 16,
                            veryNarrow: 10,
                          )),
                          Text(
                            'Мэдэгдэл байхгүй',
                            style: TextStyle(
                              color: context.textPrimaryColor,
                              fontSize: context.responsiveFontSize(
                                small: 14,
                                medium: 15,
                                large: 16,
                                tablet: 18,
                                veryNarrow: 12,
                              ),
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          SizedBox(height: context.responsiveSpacing(
                            small: 6,
                            medium: 7,
                            large: 8,
                            tablet: 10,
                            veryNarrow: 4,
                          )),
                          Text(
                            'Шинэ мэдэгдэл ирэхэд энд харагдана',
                            style: TextStyle(
                              color: context.textSecondaryColor,
                              fontSize: context.responsiveFontSize(
                                small: 11,
                                medium: 12,
                                large: 13,
                                tablet: 15,
                                veryNarrow: 10,
                              ),
                            ),
                          ),
                        ],
                      ),
                    )
                  : RefreshIndicator(
                      onRefresh: _loadNotifications,
                      color: AppColors.deepGreen,
                      child: ListView.builder(
                        padding: EdgeInsets.all(context.responsiveSpacing(
                          small: 14,
                          medium: 15,
                          large: 16,
                          tablet: 18,
                          veryNarrow: 10,
                        )),
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
      size: context.responsiveFontSize(
        small: 18,
        medium: 19,
        large: 20,
        tablet: 22,
        veryNarrow: 14,
      ),
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
        margin: EdgeInsets.only(bottom: context.responsiveSpacing(
          small: 10,
          medium: 11,
          large: 12,
          tablet: 14,
          veryNarrow: 8,
        )),
        padding: EdgeInsets.all(context.responsiveSpacing(
          small: 12,
          medium: 13,
          large: 14,
          tablet: 16,
          veryNarrow: 10,
        )),
        decoration: BoxDecoration(
          color: context.isDarkMode
              ? const Color(0xFF1A1A1A)
              : Colors.white,
          borderRadius: BorderRadius.circular(context.responsiveBorderRadius(
            small: 14,
            medium: 15,
            large: 16,
            tablet: 18,
            veryNarrow: 10,
          )),
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
              width: context.responsiveSpacing(
                small: 40,
                medium: 42,
                large: 44,
                tablet: 48,
                veryNarrow: 34,
              ),
              height: context.responsiveSpacing(
                small: 40,
                medium: 42,
                large: 44,
                tablet: 48,
                veryNarrow: 34,
              ),
              decoration: BoxDecoration(
                color: AppColors.deepGreen.withOpacity(0.1),
                borderRadius: BorderRadius.circular(context.responsiveBorderRadius(
                  small: 10,
                  medium: 11,
                  large: 12,
                  tablet: 14,
                  veryNarrow: 8,
                )),
              ),
              child: Center(child: _buildNotificationIcon(notification)),
            ),
            SizedBox(width: context.responsiveSpacing(
              small: 10,
              medium: 11,
              large: 12,
              tablet: 14,
              veryNarrow: 8,
            )),
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
                            fontSize: context.responsiveFontSize(
                              small: 14,
                              medium: 15,
                              large: 16,
                              tablet: 18,
                              veryNarrow: 12,
                            ),
                            fontWeight: isRead ? FontWeight.w500 : FontWeight.w600,
                          ),
                        ),
                      ),
                      if (!isRead)
                        Container(
                          width: context.responsiveSpacing(
                            small: 6,
                            medium: 7,
                            large: 8,
                            tablet: 10,
                            veryNarrow: 5,
                          ),
                          height: context.responsiveSpacing(
                            small: 6,
                            medium: 7,
                            large: 8,
                            tablet: 10,
                            veryNarrow: 5,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.deepGreen,
                            shape: BoxShape.circle,
                          ),
                        ),
                    ],
                  ),
                  SizedBox(height: context.responsiveSpacing(
                    small: 4,
                    medium: 5,
                    large: 6,
                    tablet: 8,
                    veryNarrow: 3,
                  )),
                  Text(
                    notification.message,
                    style: TextStyle(
                      color: context.textSecondaryColor,
                      fontSize: context.responsiveFontSize(
                        small: 13,
                        medium: 14,
                        large: 15,
                        tablet: 17,
                        veryNarrow: 11,
                      ),
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  // Show reply indicator if has reply
                  if (hasReply && (isGomdol || isSanal)) ...[
                    SizedBox(height: context.responsiveSpacing(
                      small: 6,
                      medium: 7,
                      large: 8,
                      tablet: 10,
                      veryNarrow: 4,
                    )),
                    Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: context.responsiveSpacing(
                          small: 6,
                          medium: 7,
                          large: 8,
                          tablet: 10,
                          veryNarrow: 4,
                        ),
                        vertical: context.responsiveSpacing(
                          small: 3,
                          medium: 4,
                          large: 5,
                          tablet: 6,
                          veryNarrow: 2,
                        ),
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.success.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(context.responsiveBorderRadius(
                          small: 6,
                          medium: 7,
                          large: 8,
                          tablet: 10,
                          veryNarrow: 4,
                        )),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.reply,
                            color: AppColors.success,
                            size: context.responsiveFontSize(
                              small: 10,
                              medium: 11,
                              large: 12,
                              tablet: 14,
                              veryNarrow: 9,
                            ),
                          ),
                          SizedBox(width: context.responsiveSpacing(
                            small: 4,
                            medium: 5,
                            large: 6,
                            tablet: 8,
                            veryNarrow: 3,
                          )),
                          Text(
                            'Хариу ирсэн',
                            style: TextStyle(
                              color: AppColors.success,
                              fontSize: context.responsiveFontSize(
                                small: 9,
                                medium: 10,
                                large: 11,
                                tablet: 13,
                                veryNarrow: 8,
                              ),
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                  if (isReply) ...[
                    SizedBox(height: context.responsiveSpacing(
                      small: 6,
                      medium: 7,
                      large: 8,
                      tablet: 10,
                      veryNarrow: 4,
                    )),
                    Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: context.responsiveSpacing(
                          small: 6,
                          medium: 7,
                          large: 8,
                          tablet: 10,
                          veryNarrow: 4,
                        ),
                        vertical: context.responsiveSpacing(
                          small: 3,
                          medium: 4,
                          large: 5,
                          tablet: 6,
                          veryNarrow: 2,
                        ),
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.deepGreen.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(context.responsiveBorderRadius(
                          small: 6,
                          medium: 7,
                          large: 8,
                          tablet: 10,
                          veryNarrow: 4,
                        )),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.reply_all,
                            color: AppColors.deepGreen,
                            size: context.responsiveFontSize(
                              small: 10,
                              medium: 11,
                              large: 12,
                              tablet: 14,
                              veryNarrow: 9,
                            ),
                          ),
                          SizedBox(width: context.responsiveSpacing(
                            small: 4,
                            medium: 5,
                            large: 6,
                            tablet: 8,
                            veryNarrow: 3,
                          )),
                          Text(
                            'Хариу',
                            style: TextStyle(
                              color: AppColors.deepGreen,
                              fontSize: context.responsiveFontSize(
                                small: 9,
                                medium: 10,
                                large: 11,
                                tablet: 13,
                                veryNarrow: 8,
                              ),
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                  SizedBox(height: context.responsiveSpacing(
                    small: 8,
                    medium: 9,
                    large: 10,
                    tablet: 12,
                    veryNarrow: 6,
                  )),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        notification.formattedDateTime,
                        style: TextStyle(
                          color: context.textSecondaryColor,
                          fontSize: context.responsiveFontSize(
                            small: 9,
                            medium: 10,
                            large: 11,
                            tablet: 13,
                            veryNarrow: 8,
                          ),
                        ),
                      ),
                      if (!isRead)
                        Text(
                          'Шинэ',
                          style: TextStyle(
                            color: AppColors.deepGreen,
                            fontSize: context.responsiveFontSize(
                              small: 9,
                              medium: 10,
                              large: 11,
                              tablet: 13,
                              veryNarrow: 8,
                            ),
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
