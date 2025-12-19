import 'dart:async';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest_all.dart' as tz_data;

/// NotificationService - Handles local notifications
///
/// This service manages local push notifications for the app,
/// including session expiry notifications.
class NotificationService {
  static final FlutterLocalNotificationsPlugin _notifications =
      FlutterLocalNotificationsPlugin();

  static bool _initialized = false;
  static Completer<void>? _initCompleter;

  /// Initialize the notification service
  static Future<void> initialize() async {
    if (_initialized) return;

    // If initialization is already in progress, wait for it to complete
    if (_initCompleter != null) {
      return _initCompleter!.future;
    }

    _initCompleter = Completer<void>();

    // Initialize timezone data for scheduled notifications
    tz_data.initializeTimeZones();

    const androidSettings = AndroidInitializationSettings(
      '@mipmap/ic_launcher',
    );
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: false,
      requestBadgePermission: false,
      requestSoundPermission: false,
    );

    const initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    try {
      await _notifications.initialize(
        initSettings,
        onDidReceiveNotificationResponse: (NotificationResponse response) {
          // Handle notification tap
          print('Notification tapped: ${response.payload}');
        },
      );

      // Request permissions for Android 13+
      await _requestPermissions();

      _initialized = true;
      _initCompleter!.complete();
    } catch (e) {
      _initCompleter!.completeError(e);
      _initCompleter = null;
      rethrow;
    }
  }

  /// Request notification permissions
  static Future<void> _requestPermissions() async {
    try {
      final androidPlugin = _notifications
          .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin
          >();

      if (androidPlugin != null) {
        // Check if permission is already granted
        final granted = await androidPlugin.areNotificationsEnabled();
        if (granted != true) {
          await androidPlugin.requestNotificationsPermission();
        }
      }

      final iosPlugin = _notifications
          .resolvePlatformSpecificImplementation<
            IOSFlutterLocalNotificationsPlugin
          >();

      if (iosPlugin != null) {
        await iosPlugin.requestPermissions(
          alert: true,
          badge: true,
          sound: true,
        );
      }
    } on Exception catch (e) {
      // If permission request is already in progress, that's okay - just continue
      if (e.toString().contains('permissionRequestInProgress')) {
        return;
      }
      rethrow;
    }
  }

  /// Show session expired notification
  static Future<void> showSessionExpiredNotification() async {
    const androidDetails = AndroidNotificationDetails(
      'session_channel',
      'Нэвтрэлтийн мэдэгдэл',
      channelDescription: 'Таны нэвтрэлтийн хугацаа дууслаа!',
      importance: Importance.high,
      priority: Priority.high,
      showWhen: true,
    );

    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    const notificationDetails = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _notifications.show(
      0,
      'Нэвтрэлтийн хугацаа дууссан',
      'Таны нэвтрэх хугацаа дууссан байна. Дахин нэвтэрнэ үү.',
      notificationDetails,
      payload: 'session_expired',
    );
  }

  /// Show a custom notification
  static Future<void> showNotification({
    required int id,
    required String title,
    required String body,
    String? payload,
  }) async {
    const androidDetails = AndroidNotificationDetails(
      'general_channel',
      'Ерөнхий мэдэгдэл',
      channelDescription: 'Ерөнхий мэдэгдлүүд',
      importance: Importance.defaultImportance,
      priority: Priority.defaultPriority,
    );

    const iosDetails = DarwinNotificationDetails();

    const notificationDetails = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _notifications.show(
      id,
      title,
      body,
      notificationDetails,
      payload: payload,
    );
  }

  /// Cancel all notifications
  static Future<void> cancelAll() async {
    await _notifications.cancelAll();
  }

  /// Cancel a specific notification
  static Future<void> cancel(int id) async {
    await _notifications.cancel(id);
  }

  /// Schedule a session expiry notification
  /// This will fire even when the app is closed
  static Future<void> scheduleSessionExpiryNotification(
    DateTime scheduledDate,
  ) async {
    // Cancel any existing scheduled notification first
    await cancel(0);

    const androidDetails = AndroidNotificationDetails(
      'session_channel',
      'Нэвтрэлтийн мэдэгдэл',
      channelDescription: 'Таны нэвтрэлтийн хугацаа дууслаа!',
      importance: Importance.high,
      priority: Priority.high,
      showWhen: true,
    );

    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    const notificationDetails = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    // Schedule the notification
    await _notifications.zonedSchedule(
      0,
      'Нэвтрэлтийн хугацаа дууссан',
      'Таны нэвтрэх хугацаа дууссан байна. Дахин нэвтэрнэ үү.',
      _convertToTZDateTime(scheduledDate),
      notificationDetails,
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      payload: 'session_expired',
    );
  }

  /// Convert DateTime to TZDateTime for scheduling
  static tz.TZDateTime _convertToTZDateTime(DateTime dateTime) {
    return tz.TZDateTime.from(dateTime, tz.local);
  }
}
