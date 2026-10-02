import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:sukh_app/services/api_service.dart';
import 'package:sukh_app/services/socket_service.dart';
import 'package:sukh_app/models/medegdel_model.dart';
import 'package:sukh_app/constants/constants.dart';
import 'package:sukh_app/screens/medegdel/medegdel_detail.dart';
import 'package:sukh_app/utils/theme_extensions.dart';
import 'package:sukh_app/utils/error_message.dart';

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
        _errorMessage = friendlyError(e, fallback: 'Мэдэгдэл татаж чадсангүй. Дахин оролдоно уу.');
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

  /// Шүүлт: false = бүгд, true = зөвхөн уншаагүй
  bool _zuvkhunUnshaagui = false;

  DateTime? _ognoo(Medegdel n) {
    final raw = n.createdAt.isNotEmpty ? n.createdAt : n.ognoo;
    return DateTime.tryParse(raw)?.toLocal();
  }

  /// Өдрөөр бүлэглэх нэр
  String _bulgiinNer(DateTime? d) {
    if (d == null) return 'Өмнөх';
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final day = DateTime(d.year, d.month, d.day);
    final diff = today.difference(day).inDays;
    if (diff <= 0) return 'Өнөөдөр';
    if (diff == 1) return 'Өчигдөр';
    if (diff < 7) return 'Энэ долоо хоног';
    return 'Өмнөх';
  }

  /// Богино харьцангуй хугацаа: «Дөнгөж сая», «5 мин», «14:20», «09.21»
  String _khugatsaa(DateTime? d) {
    if (d == null) return '';
    final now = DateTime.now();
    final diff = now.difference(d);
    if (diff.inMinutes < 1) return 'Дөнгөж сая';
    if (diff.inMinutes < 60) return '${diff.inMinutes} мин';
    String two(int v) => v.toString().padLeft(2, '0');
    if (now.year == d.year && now.month == d.month && now.day == d.day) {
      return '${two(d.hour)}:${two(d.minute)}';
    }
    if (now.year == d.year) return '${two(d.month)}.${two(d.day)}';
    return '${d.year}.${two(d.month)}.${two(d.day)}';
  }

  /// Төрлөөр нь iOS маягийн өнгөт дүрс
  (IconData, List<Color>) _turliinDurs(Medegdel n) {
    final t = n.turul.toLowerCase().trim();
    if (_isZardluudNotification(n)) {
      return (Icons.receipt_long_rounded, const [Color(0xFF3EDBC8), Color(0xFF0D9488)]);
    }
    if (n.isReply || t == 'хариу' || t == 'khariu' || t == 'hariu') {
      return (Icons.chat_bubble_rounded, const [Color(0xFF5AA9FF), Color(0xFF2563EB)]);
    }
    if (t == 'gomdol' || t == 'гомдол') {
      return (Icons.report_rounded, const [Color(0xFFFF9A62), Color(0xFFEA580C)]);
    }
    if (t == 'sanal' || t == 'санал') {
      return (Icons.lightbulb_rounded, const [Color(0xFFB794F6), Color(0xFF7C3AED)]);
    }
    return (Icons.notifications_rounded, const [Color(0xFF1A7A5E), AppColors.deepGreen]);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = context.isDarkMode;
    final unreadCount = _notifications.where((n) => !n.kharsanEsekh).length;
    final kharagdakh = _zuvkhunUnshaagui
        ? _notifications.where((n) => !n.kharsanEsekh).toList()
        : _notifications;

    // Өдрөөр бүлэглэнэ (жагсаалт аль хэдийн шинээс хуучин руу эрэмбэлэгдсэн)
    final bulguud = <String, List<Medegdel>>{};
    for (final n in kharagdakh) {
      bulguud.putIfAbsent(_bulgiinNer(_ognoo(n)), () => []).add(n);
    }

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0A0E14) : const Color(0xFFF3F5F2),
      body: SafeArea(
        bottom: false,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Толгой ──
            Padding(
              padding: EdgeInsets.fromLTRB(8.w, 6.h, 12.w, 0),
              child: Row(
                children: [
                  IconButton(
                    onPressed: () => context.canPop() ? context.pop() : context.go('/nuur'),
                    icon: Icon(Icons.arrow_back_ios_new_rounded,
                        size: 20.sp, color: context.textPrimaryColor),
                    tooltip: 'Буцах',
                  ),
                  // Гарчиг буцах сумтай нэг мөрөнд
                  Expanded(
                    child: Text(
                      'Мэдэгдэл',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 21.sp,
                        fontWeight: FontWeight.w600,
                        letterSpacing: -0.6,
                        color: context.textPrimaryColor,
                      ),
                    ),
                  ),
                  if (unreadCount > 0)
                    TextButton.icon(
                      onPressed: _markAllAsRead,
                      icon: Icon(Icons.done_all_rounded, size: 18.sp),
                      label: Text('Бүгдийг уншсан',
                          style: TextStyle(fontSize: 13.sp, fontWeight: FontWeight.w600)),
                      style: TextButton.styleFrom(
                        foregroundColor: isDark ? const Color(0xFF8EE3BF) : AppColors.deepGreen,
                      ),
                    ),
                ],
              ),
            ),
            Padding(
              padding: EdgeInsets.fromLTRB(20.w, 0, 20.w, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    unreadCount > 0
                        ? '$unreadCount уншаагүй мэдэгдэл'
                        : 'Бүх мэдэгдлээ уншсан байна',
                    style: TextStyle(fontSize: 13.sp, color: context.textSecondaryColor),
                  ),
                  SizedBox(height: 14.h),
                  Row(
                    children: [
                      _shuultiinChip('Бүгд', !_zuvkhunUnshaagui, () => setState(() => _zuvkhunUnshaagui = false)),
                      SizedBox(width: 8.w),
                      _shuultiinChip(
                        unreadCount > 0 ? 'Уншаагүй · $unreadCount' : 'Уншаагүй',
                        _zuvkhunUnshaagui,
                        () => setState(() => _zuvkhunUnshaagui = true),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            SizedBox(height: 8.h),
            Expanded(
              child: _isLoading && _notifications.isEmpty
                  ? _buildAchaalakh(isDark)
                  : _errorMessage != null && _notifications.isEmpty
                      ? _buildTuluv(
                          icon: Icons.wifi_tethering_error_rounded,
                          garchig: 'Мэдэгдэл ачаалагдсангүй',
                          tailbar: _errorMessage!,
                          uildel: 'Дахин оролдох',
                          onUildel: _loadNotifications,
                        )
                      : kharagdakh.isEmpty
                          ? _buildTuluv(
                              icon: _zuvkhunUnshaagui
                                  ? Icons.mark_email_read_rounded
                                  : Icons.notifications_none_rounded,
                              garchig: _zuvkhunUnshaagui ? 'Уншаагүй мэдэгдэл алга' : 'Мэдэгдэл байхгүй',
                              tailbar: _zuvkhunUnshaagui
                                  ? 'Та бүх мэдэгдлээ уншсан байна.'
                                  : 'СӨХ-оос ирсэн мэдээлэл, хариу энд харагдана.',
                            )
                          : RefreshIndicator(
                              onRefresh: _loadNotifications,
                              color: AppColors.deepGreen,
                              child: ListView(
                                physics: const AlwaysScrollableScrollPhysics(),
                                padding: EdgeInsets.fromLTRB(16.w, 4.h, 16.w, 32.h),
                                children: [
                                  for (final e in bulguud.entries) ...[
                                    Padding(
                                      padding: EdgeInsets.fromLTRB(4.w, 14.h, 4.w, 8.h),
                                      child: Text(
                                        e.key,
                                        style: TextStyle(
                                          fontSize: 13.sp,
                                          fontWeight: FontWeight.w600,
                                          color: context.textSecondaryColor,
                                        ),
                                      ),
                                    ),
                                    Container(
                                      decoration: BoxDecoration(
                                        color: isDark ? Colors.white.withOpacity(0.05) : Colors.white,
                                        borderRadius: BorderRadius.circular(22.r),
                                        border: Border.all(
                                          color: isDark
                                              ? Colors.white.withOpacity(0.06)
                                              : Colors.black.withOpacity(0.04),
                                        ),
                                      ),
                                      child: Column(
                                        children: [
                                          for (int i = 0; i < e.value.length; i++) ...[
                                            if (i > 0)
                                              Padding(
                                                padding: EdgeInsets.only(left: 70.w),
                                                child: Divider(
                                                  height: 1,
                                                  thickness: 0.6,
                                                  color: isDark
                                                      ? Colors.white.withOpacity(0.06)
                                                      : Colors.black.withOpacity(0.06),
                                                ),
                                              ),
                                            _buildNotificationCard(e.value[i]),
                                          ],
                                        ],
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                            ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _shuultiinChip(String label, bool songogdson, VoidCallback onTap) {
    final isDark = context.isDarkMode;
    return Material(
      color: songogdson
          ? AppColors.deepGreen
          : (isDark ? Colors.white.withOpacity(0.07) : Colors.white),
      borderRadius: BorderRadius.circular(100),
      child: InkWell(
        borderRadius: BorderRadius.circular(100),
        onTap: onTap,
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 7.h),
          child: Text(
            label,
            style: TextStyle(
              fontSize: 13.sp,
              fontWeight: FontWeight.w600,
              color: songogdson ? Colors.white : context.textPrimaryColor,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildAchaalakh(bool isDark) {
    final ongo = isDark ? Colors.white.withOpacity(0.06) : Colors.black.withOpacity(0.05);
    Widget mur() => Padding(
          padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 14.h),
          child: Row(
            children: [
              Container(width: 42.w, height: 42.w, decoration: BoxDecoration(color: ongo, borderRadius: BorderRadius.circular(13.r))),
              SizedBox(width: 14.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(height: 12.h, width: 160.w, decoration: BoxDecoration(color: ongo, borderRadius: BorderRadius.circular(6))),
                    SizedBox(height: 8.h),
                    Container(height: 10.h, width: double.infinity, decoration: BoxDecoration(color: ongo, borderRadius: BorderRadius.circular(6))),
                  ],
                ),
              ),
            ],
          ),
        );
    return ListView(
      padding: EdgeInsets.fromLTRB(16.w, 18.h, 16.w, 16.h),
      children: [
        Container(
          decoration: BoxDecoration(
            color: isDark ? Colors.white.withOpacity(0.05) : Colors.white,
            borderRadius: BorderRadius.circular(22.r),
          ),
          child: Column(children: [mur(), mur(), mur(), mur()]),
        ),
      ],
    );
  }

  Widget _buildTuluv({
    required IconData icon,
    required String garchig,
    required String tailbar,
    String? uildel,
    VoidCallback? onUildel,
  }) {
    final isDark = context.isDarkMode;
    return Center(
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 40.w),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 84.w,
              height: 84.w,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.deepGreen.withOpacity(isDark ? 0.2 : 0.08),
              ),
              child: Icon(icon, size: 38.sp, color: isDark ? const Color(0xFF8EE3BF) : AppColors.deepGreen),
            ),
            SizedBox(height: 18.h),
            Text(
              garchig,
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 17.sp, fontWeight: FontWeight.w600, color: context.textPrimaryColor),
            ),
            SizedBox(height: 6.h),
            Text(
              tailbar,
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 13.sp, height: 1.4, color: context.textSecondaryColor),
            ),
            if (uildel != null && onUildel != null) ...[
              SizedBox(height: 18.h),
              FilledButton(
                onPressed: onUildel,
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.deepGreen,
                  shape: const StadiumBorder(),
                  padding: EdgeInsets.symmetric(horizontal: 22.w, vertical: 12.h),
                ),
                child: Text(uildel, style: TextStyle(fontSize: 14.sp, fontWeight: FontWeight.w600)),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildNotificationCard(Medegdel notification) {
    final isDark = context.isDarkMode;
    final isRead = notification.kharsanEsekh;
    final (durs, gradient) = _turliinDurs(notification);
    final title = notification.title.trim();
    final message = notification.message.trim();
    final garchig = title.isNotEmpty ? title : (message.isNotEmpty ? message : 'Мэдэгдэл');
    final aguulga = title.isNotEmpty ? message : '';
    final showStatus = _showStatusForTurul(notification.turul) &&
        notification.status != null &&
        notification.status!.trim().isNotEmpty;
    final statusOngo = _isDoneStatus(notification.status)
        ? AppColors.success
        : _isRejectedStatus(notification.status)
            ? AppColors.error
            : (isDark ? const Color(0xFF8EE3BF) : AppColors.deepGreen);

    return InkWell(
      onTap: () async {
        if (_isZardluudNotification(notification)) {
          context.push('/nekhemjlekh');
          _markAsRead(notification);
          return;
        }
        final result = await showModalBottomSheet(
          context: context,
          isScrollControlled: true,
          backgroundColor: Colors.transparent,
          builder: (BuildContext context) => MedegdelDetailModal(notification: notification),
        );
        if (result == true) {
          _loadNotifications();
        } else {
          _markAsRead(notification);
        }
      },
      child: Padding(
        padding: EdgeInsets.fromLTRB(14.w, 13.h, 14.w, 13.h),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Stack(
              clipBehavior: Clip.none,
              children: [
                Container(
                  width: 42.w,
                  height: 42.w,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: gradient,
                    ),
                    borderRadius: BorderRadius.circular(13.r),
                  ),
                  child: Icon(durs, color: Colors.white, size: 21.sp),
                ),
                if (!isRead)
                  Positioned(
                    right: -2,
                    top: -2,
                    child: Container(
                      width: 12.w,
                      height: 12.w,
                      decoration: BoxDecoration(
                        color: const Color(0xFF2F80ED),
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: isDark ? const Color(0xFF151A21) : Colors.white,
                          width: 2,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
            SizedBox(width: 14.w),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Text(
                          garchig,
                          style: TextStyle(
                            fontSize: 15.sp,
                            fontWeight: isRead ? FontWeight.w500 : FontWeight.w600,
                            color: context.textPrimaryColor,
                            height: 1.3,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      SizedBox(width: 8.w),
                      Text(
                        _khugatsaa(_ognoo(notification)),
                        style: TextStyle(
                          fontSize: 12.sp,
                          color: isRead
                              ? context.textSecondaryColor
                              : (isDark ? const Color(0xFF8EE3BF) : AppColors.deepGreen),
                          fontWeight: isRead ? FontWeight.w400 : FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                  if (aguulga.isNotEmpty) ...[
                    SizedBox(height: 3.h),
                    Text(
                      aguulga,
                      style: TextStyle(
                        fontSize: 13.5.sp,
                        height: 1.4,
                        color: context.textSecondaryColor,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                  if (showStatus || notification.isReply) ...[
                    SizedBox(height: 8.h),
                    Wrap(
                      spacing: 6.w,
                      runSpacing: 6.h,
                      children: [
                        if (showStatus)
                          _jijigChip(
                            Icons.verified_rounded,
                            _getStatusLabel(notification.status),
                            statusOngo,
                          ),
                        if (notification.isReply)
                          _jijigChip(
                            Icons.reply_rounded,
                            'СӨХ хариулсан',
                            const Color(0xFF2F80ED),
                          ),
                      ],
                    ),
                  ],
                  if (showStatus &&
                      notification.tailbar != null &&
                      notification.tailbar!.trim().isNotEmpty) ...[
                    SizedBox(height: 8.h),
                    Container(
                      width: double.infinity,
                      padding: EdgeInsets.all(10.w),
                      decoration: BoxDecoration(
                        color: isDark ? Colors.white.withOpacity(0.05) : const Color(0xFFF3F5F2),
                        borderRadius: BorderRadius.circular(12.r),
                      ),
                      child: Text(
                        notification.tailbar!,
                        style: TextStyle(fontSize: 12.5.sp, height: 1.35, color: context.textPrimaryColor),
                        maxLines: 3,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _jijigChip(IconData icon, String text, Color color) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 3.h),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(100),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12.sp, color: color),
          SizedBox(width: 4.w),
          Text(text, style: TextStyle(fontSize: 11.5.sp, fontWeight: FontWeight.w600, color: color)),
        ],
      ),
    );
  }
}
