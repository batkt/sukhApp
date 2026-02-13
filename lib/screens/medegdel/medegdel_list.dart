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
    _setupBaiguullagiinMedegdelListener();
  }

  void _setupSocketListener() {
    // Listen for real-time notifications via orshinSuugch (admin reply, etc.)
    _notificationCallback = (notification) {
      final turul = notification['turul']?.toString().toLowerCase() ?? '';
      final isReply = turul == 'хариу' || turul == 'hariu' || turul == 'khariu';
      final isUserReply = turul == 'user_reply';
      final isGomdolSanal = turul == 'gomdol' || turul == 'sanal';
      final isApp = turul == 'app';
      final isMedegdel = turul == 'мэдэгдэл' || turul == 'medegdel';
      final hasStatus = notification['status'] != null;
      final hasTailbar =
          notification['tailbar'] != null &&
          notification['tailbar'].toString().trim().isNotEmpty;

      // Refresh for new notifications, admin replies, user's own reply (so bell list/thread stay in sync), and status updates
      if (mounted &&
          ((isApp || isMedegdel || isReply || isUserReply) && !isGomdolSanal ||
              hasStatus ||
              hasTailbar)) {
        print(
          '[medegdel_list] RECV socket orshinSuugch -> refresh list turul=$turul',
        );
        _loadNotifications();
      }
    };
    SocketService.instance.setNotificationCallback(_notificationCallback!);
  }

  void _setupBaiguullagiinMedegdelListener() {
    // Real-time sanal khuselt list when user reply or admin reply is received on baiguullagiin channel
    SocketService.instance.setBaiguullagiinMedegdelCallback((payload) {
      if (mounted) {
        print(
          '[medegdel_list] RECV socket baiguullagiin medegdel -> refresh list type=${payload['type']}',
        );
        _loadNotifications();
      }
    });
  }

  /// Admin status label for display in notification card
  String _getStatusLabel(String? status) {
    if (status == null || status.isEmpty) return '';
    final s = status.toLowerCase().trim();
    if (s == 'done' || s == 'approved') return 'Баталгаажсан';
    if (s == 'rejected' || s == 'declined' || s == 'cancelled')
      return 'Татгалзсан';
    if (s == 'pending') return 'Хүлээгдэж буй';
    if (s == 'in_progress' || s == 'in progress') return 'Боловсруулж буй';
    return status;
  }

  bool _isDoneStatus(String? status) {
    if (status == null || status.isEmpty) return false;
    final s = status.toLowerCase().trim();
    return s == 'done' || s == 'approved';
  }

  bool _isRejectedStatus(String? status) {
    if (status == null || status.isEmpty) return false;
    final s = status.toLowerCase().trim();
    return s == 'rejected' || s == 'declined' || s == 'cancelled';
  }

  /// Мэдэгдэл (App/Мессеж/Mail) has no status; only sanal/gomdol show status.
  bool _showStatusForTurul(String? turul) {
    if (turul == null || turul.isEmpty) return false;
    final t = turul.toLowerCase().trim();
    if (t == 'app' ||
        t == 'мессеж' ||
        t == 'mail' ||
        t == 'мэдэгдэл' ||
        t == 'medegdel')
      return false;
    return t == 'sanal' || t == 'санал' || t == 'gomdol' || t == 'гомдол';
  }

  @override
  void dispose() {
    SocketService.instance.setBaiguullagiinMedegdelCallback(null);
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
      print('[medegdel_list] SEND fetchMedegdel');
      final response = await ApiService.fetchMedegdel();
      final medegdelResponse = MedegdelResponse.fromJson(response);

      // Sort by last activity (updatedAt) so last replied chat is on top
      final list = medegdelResponse.data;
      list.sort((a, b) {
        final at = a.updatedAt ?? a.createdAt;
        final bt = b.updatedAt ?? b.createdAt;
        if (at == null && bt == null) return 0;
        if (at == null) return 1;
        if (bt == null) return -1;
        return bt.compareTo(at);
      });

      setState(() {
        _notifications = list;
        _isLoading = false;
      });
      print('[medegdel_list] RECV fetchMedegdel count=${list.length}');
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
                IconButton(
                  onPressed: _markAllAsRead,
                  icon: Icon(
                    Icons.check,
                    color: Colors.white,
                    size: context.responsiveFontSize(
                      small: 20,
                      medium: 21,
                      large: 22,
                      tablet: 24,
                      veryNarrow: 18,
                    ),
                  ),
                  tooltip: 'Бүгдийг уншсан',
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
                          SizedBox(
                            height: context.responsiveSpacing(
                              small: 12,
                              medium: 13,
                              large: 14,
                              tablet: 16,
                              veryNarrow: 10,
                            ),
                          ),
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
                          SizedBox(
                            height: context.responsiveSpacing(
                              small: 16,
                              medium: 17,
                              large: 18,
                              tablet: 20,
                              veryNarrow: 12,
                            ),
                          ),
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
                                borderRadius: BorderRadius.circular(
                                  context.responsiveBorderRadius(
                                    small: 10,
                                    medium: 11,
                                    large: 12,
                                    tablet: 14,
                                    veryNarrow: 8,
                                  ),
                                ),
                              ),
                            ),
                            child: Text(
                              'Дахин оролдох',
                              style: TextStyle(
                                fontSize: context.responsiveFontSize(
                                  small: 11,
                                  medium: 12,
                                  large: 13,
                                  tablet: 15,
                                  veryNarrow: 10,
                                ),
                              ),
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
                          SizedBox(
                            height: context.responsiveSpacing(
                              small: 12,
                              medium: 13,
                              large: 14,
                              tablet: 16,
                              veryNarrow: 10,
                            ),
                          ),
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
                          SizedBox(
                            height: context.responsiveSpacing(
                              small: 6,
                              medium: 7,
                              large: 8,
                              tablet: 10,
                              veryNarrow: 4,
                            ),
                          ),
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
                        padding: EdgeInsets.all(
                          context.responsiveSpacing(
                            small: 14,
                            medium: 15,
                            large: 16,
                            tablet: 18,
                            veryNarrow: 10,
                          ),
                        ),
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
        margin: EdgeInsets.only(
          bottom: context.responsiveSpacing(
            small: 10,
            medium: 11,
            large: 12,
            tablet: 14,
            veryNarrow: 8,
          ),
        ),
        padding: EdgeInsets.all(
          context.responsiveSpacing(
            small: 12,
            medium: 13,
            large: 14,
            tablet: 16,
            veryNarrow: 10,
          ),
        ),
        decoration: BoxDecoration(
          color: context.isDarkMode ? const Color(0xFF1A1A1A) : Colors.white,
          borderRadius: BorderRadius.circular(
            context.responsiveBorderRadius(
              small: 14,
              medium: 15,
              large: 16,
              tablet: 18,
              veryNarrow: 10,
            ),
          ),
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
                borderRadius: BorderRadius.circular(
                  context.responsiveBorderRadius(
                    small: 10,
                    medium: 11,
                    large: 12,
                    tablet: 14,
                    veryNarrow: 8,
                  ),
                ),
              ),
              child: Center(child: _buildNotificationIcon(notification)),
            ),
            SizedBox(
              width: context.responsiveSpacing(
                small: 10,
                medium: 11,
                large: 12,
                tablet: 14,
                veryNarrow: 8,
              ),
            ),
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
                            fontWeight: isRead
                                ? FontWeight.w500
                                : FontWeight.w600,
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
                  SizedBox(
                    height: context.responsiveSpacing(
                      small: 4,
                      medium: 5,
                      large: 6,
                      tablet: 8,
                      veryNarrow: 3,
                    ),
                  ),
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
                  // Show admin status only for sanal/gomdol; Мэдэгдэл (App) has no status
                  if (_showStatusForTurul(notification.turul) &&
                      notification.status != null &&
                      notification.status!.trim().isNotEmpty) ...[
                    SizedBox(
                      height: context.responsiveSpacing(
                        small: 6,
                        medium: 7,
                        large: 8,
                        tablet: 10,
                        veryNarrow: 4,
                      ),
                    ),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
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
                            color: _isDoneStatus(notification.status)
                                ? AppColors.success.withOpacity(0.1)
                                : _isRejectedStatus(notification.status)
                                ? AppColors.error.withOpacity(0.1)
                                : AppColors.deepGreen.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(
                              context.responsiveBorderRadius(
                                small: 6,
                                medium: 7,
                                large: 8,
                                tablet: 10,
                                veryNarrow: 4,
                              ),
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.admin_panel_settings,
                                color: _isDoneStatus(notification.status)
                                    ? AppColors.success
                                    : _isRejectedStatus(notification.status)
                                    ? AppColors.error
                                    : AppColors.deepGreen,
                                size: context.responsiveFontSize(
                                  small: 10,
                                  medium: 11,
                                  large: 12,
                                  tablet: 14,
                                  veryNarrow: 9,
                                ),
                              ),
                              SizedBox(
                                width: context.responsiveSpacing(
                                  small: 4,
                                  medium: 5,
                                  large: 6,
                                  tablet: 8,
                                  veryNarrow: 3,
                                ),
                              ),
                              Text(
                                _getStatusLabel(notification.status),
                                style: TextStyle(
                                  color: _isDoneStatus(notification.status)
                                      ? AppColors.success
                                      : _isRejectedStatus(notification.status)
                                      ? AppColors.error
                                      : AppColors.deepGreen,
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
                    ),
                    if (notification.tailbar != null &&
                        notification.tailbar!.trim().isNotEmpty) ...[
                      SizedBox(
                        height: context.responsiveSpacing(
                          small: 4,
                          medium: 5,
                          large: 6,
                          tablet: 8,
                          veryNarrow: 3,
                        ),
                      ),
                      Container(
                        padding: EdgeInsets.all(
                          context.responsiveSpacing(
                            small: 6,
                            medium: 7,
                            large: 8,
                            tablet: 10,
                            veryNarrow: 4,
                          ),
                        ),
                        decoration: BoxDecoration(
                          color: context.isDarkMode
                              ? Colors.white.withOpacity(0.06)
                              : AppColors.deepGreen.withOpacity(0.06),
                          borderRadius: BorderRadius.circular(
                            context.responsiveBorderRadius(
                              small: 6,
                              medium: 7,
                              large: 8,
                              tablet: 10,
                              veryNarrow: 4,
                            ),
                          ),
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Icon(
                              Icons.reply,
                              color: context.textSecondaryColor,
                              size: context.responsiveFontSize(
                                small: 12,
                                medium: 13,
                                large: 14,
                                tablet: 16,
                                veryNarrow: 10,
                              ),
                            ),
                            SizedBox(
                              width: context.responsiveSpacing(
                                small: 6,
                                medium: 7,
                                large: 8,
                                tablet: 10,
                                veryNarrow: 4,
                              ),
                            ),
                            Expanded(
                              child: Text(
                                notification.tailbar!,
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
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                  if (isReply) ...[
                    SizedBox(
                      height: context.responsiveSpacing(
                        small: 6,
                        medium: 7,
                        large: 8,
                        tablet: 10,
                        veryNarrow: 4,
                      ),
                    ),
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
                        borderRadius: BorderRadius.circular(
                          context.responsiveBorderRadius(
                            small: 6,
                            medium: 7,
                            large: 8,
                            tablet: 10,
                            veryNarrow: 4,
                          ),
                        ),
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
                          SizedBox(
                            width: context.responsiveSpacing(
                              small: 4,
                              medium: 5,
                              large: 6,
                              tablet: 8,
                              veryNarrow: 3,
                            ),
                          ),
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
                  SizedBox(
                    height: context.responsiveSpacing(
                      small: 8,
                      medium: 9,
                      large: 10,
                      tablet: 12,
                      veryNarrow: 6,
                    ),
                  ),
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
