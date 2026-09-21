import 'dart:async';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

import 'package:sukh_app/tokhirgoo/firebase_tokhirgoo.dart';
import 'package:sukh_app/services/notification_service.dart';
import 'package:sukh_app/router/app_router.dart';
import 'package:sukh_app/utils/logger.dart';

/// Апп ХААГДСАН эсвэл арын дэвсгэрт байхад ирсэн push.
///
/// Top-level функц байх ШААРДЛАГАТАЙ (isolate-д тусад нь ажиллана) тул
/// класс дотор байрлуулж болохгүй. Энд UI-д хүрэхгүй - Android өөрөө
/// notification-ийг системийн тавиур дээр гаргана.
@pragma('vm:entry-point')
Future<void> pushArynDevsgerBarigch(RemoteMessage message) async {
  // Тусдаа isolate тул Firebase-г дахин ажиллуулна
  try {
    if (Firebase.apps.isEmpty) {
      await Firebase.initializeApp(options: FirebaseTokhirgoo.options);
    }
  } catch (_) {}
  AppLogger.log('[PUSH] Арын дэвсгэр: ${message.messageId}');
}

/// FCM push мэдэгдэл — түгжээний дэлгэц, мэдэгдлийн тавиур дээр гарна.
///
/// Socket-ийн мэдэгдэл (SocketService) нь зөвхөн апп ОНГОЙ байхад ажилладаг.
/// Push нь апп хаалттай/арын дэвсгэрт байхад ч хүрдэг тул хоёулаа хэрэгтэй.
class PushService {
  static bool _asaasan = false;
  static String? _token;

  /// Хамгийн сүүлд авсан FCM token. Тохируулаагүй бол null.
  static String? get token => _token;

  /// Апп нэвтрэхэд серверт илгээх token-ыг авах.
  /// Тохируулаагүй эсвэл эрх аваагүй бол null - нэвтрэлт ердийнхөөрөө явна.
  static Future<String?> tokenAvya() async {
    if (!_asaasan) await asaaya();
    return _token;
  }

  /// Push-ийг ажиллуулах. Тохиргоо дутуу бол ЮУ Ч ХИЙХГҮЙ буцна -
  /// апп унахгүй, socket-ийн мэдэгдэл хэвийн ажиллана.
  static Future<void> asaaya() async {
    if (_asaasan) return;

    if (!FirebaseTokhirgoo.tokhirgootoiEsekh) {
      AppLogger.log(
        '[PUSH] Firebase тохируулаагүй - push унтраалттай '
        '(lib/tokhirgoo/firebase_tokhirgoo.dart)',
      );
      _asaasan = true;
      return;
    }

    try {
      if (Firebase.apps.isEmpty) {
        await Firebase.initializeApp(options: FirebaseTokhirgoo.options);
      }

      // Апп хаалттай/арын дэвсгэрт байхад ирэх push-ийн баригч. Firebase
      // асаасны ДАРАА бүртгэх ШААРДЛАГАТАЙ - iOS дээр FirebaseApp тохируулахаас
      // өмнө messaging-д хүрвэл native exception өгч апп цагаан дэлгэцээр гацна.
      FirebaseMessaging.onBackgroundMessage(pushArynDevsgerBarigch);

      // Каналыг НЭЭХЭД үүсгэнэ. Manifest дахь default_notification_channel_id
      // яг үүн рүү заадаг - канал байхгүй бол Android мэдэгдлийг чимээгүй
      // (low importance) каналаар гаргаж, түгжээний дэлгэц дээр харагдахгүй.
      try {
        await FlutterLocalNotificationsPlugin()
            .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin
            >()
            ?.createNotificationChannel(pushKanal);
      } catch (err) {
        AppLogger.log('[PUSH] Канал үүсгэхэд алдаа: $err');
      }

      final messaging = FirebaseMessaging.instance;

      // Android 13+ ба iOS дээр хэрэглэгчээс зөвшөөрөл асууна
      final zovshoorol = await messaging.requestPermission(
        alert: true,
        badge: true,
        sound: true,
      );

      if (zovshoorol.authorizationStatus == AuthorizationStatus.denied) {
        AppLogger.log('[PUSH] Хэрэглэгч мэдэгдлийн эрхийг татгалзсан');
        _asaasan = true;
        return;
      }

      // iOS дээр APNs token бэлэн болтол FCM token null байж болно
      _token = await messaging.getToken();
      AppLogger.log(
        '[PUSH] Token ${_token == null ? "авсангүй" : "авлаа"} '
        '(${_token?.substring(0, 12) ?? "-"}...)',
      );

      // Token сунгагдвал серверт дахин бүртгүүлэх шаардлагатай
      messaging.onTokenRefresh.listen((shine) {
        _token = shine;
        AppLogger.log('[PUSH] Token шинэчлэгдлээ');
      });

      // Апп ОНГОЙ байхад push ирвэл Android өөрөө banner гаргахгүй тул
      // өөрсдөө local notification болгож харуулна.
      FirebaseMessaging.onMessage.listen(_urdTalUyed);

      // Апп ард ажиллаж байхад мэдэгдэл дээр дарвал
      FirebaseMessaging.onMessageOpenedApp.listen(_medegdelDeerDarlaa);

      // Апп БҮРЭН хаалттай байхад мэдэгдлээр нээгдсэн бол эхний мессежийг
      // энд авна. Router бэлэн болтол хүлээж байж чиглүүлнэ.
      final ekhnii = await messaging.getInitialMessage();
      if (ekhnii != null) {
        Future.delayed(const Duration(milliseconds: 800), () {
          _medegdelDeerDarlaa(ekhnii);
        });
      }

      _asaasan = true;
    } catch (err) {
      AppLogger.log('[PUSH] Асаахад алдаа: $err');
      _asaasan = true;
    }
  }

  /// Мэдэгдлийн `type`-аас хамааруулж холбогдох дэлгэц рүү чиглүүлнэ.
  ///
  /// Backend талаас илгээх утгууд (sukhBackv2):
  ///   sanal_asuulga   - routes/sanalAsuulgaRoute.js
  ///   medegdel_reply  - controller/medegdel.js (adminReply)
  ///   niitlel         - controller/blog.js (blogIlgeeye)
  ///   app_update      - controller/appVersionController.js (upsertVersion)
  static void _medegdelDeerDarlaa(RemoteMessage message) {
    try {
      final zam = _zamAvya(message.data);
      if (zam != null) appRouter.push(zam);
    } catch (err) {
      AppLogger.log('[PUSH] Чиглүүлэхэд алдаа: $err');
    }
  }

  /// Мэдэгдлийн өгөгдлөөс апп доторх замыг тодорхойлно
  static String? _zamAvya(Map<String, dynamic> data) {
    final turul = data['type']?.toString();
    switch (turul) {
      case 'sanal_asuulga':
        return '/sanal_asuulga';
      case 'medegdel_reply':
        return '/medegdel-list';
      case 'niitlel':
        return '/blog';
      case 'app_update':
        // Шинэчлэлтийн мэдэгдэл дээр дарахад апп доторх дэлгэц нээхгүй —
        // хэрэглэгч Store руу орох ёстой. Аппыг нээснээр `main.dart`-ын
        // хувилбар шалгах логик өөрөө шинэчлэлтийн цонхыг үзүүлнэ.
        return null;
      default:
        return null;
    }
  }

  static void _urdTalUyed(RemoteMessage message) {
    try {
      final notification = message.notification;
      final title = notification?.title ?? message.data['title']?.toString();
      final body = notification?.body ?? message.data['body']?.toString();

      if ((title == null || title.isEmpty) && (body == null || body.isEmpty)) {
        return;
      }

      NotificationService.showNotification(
        id: DateTime.now().millisecondsSinceEpoch % 100000,
        title: (title == null || title.isEmpty) ? 'Шинэ мэдэгдэл' : title,
        body: body ?? '',
        // Local notification дээр дарахад ч чиглүүлэх боломжтой байхын
        // тулд төрлийг payload-оор дамжуулна.
        payload: _zamAvya(message.data) ?? message.data['_id']?.toString(),
      );
    } catch (err) {
      AppLogger.log('[PUSH] Урд талын мэдэгдэл харуулахад алдаа: $err');
    }
  }

  /// Гарахад token-ыг устгана - өөр хэрэглэгч нэвтрэхэд хуучин
  /// хэрэглэгчийн мэдэгдэл ирэхээс сэргийлнэ.
  static Future<void> tokeniigUstgaya() async {
    if (!FirebaseTokhirgoo.tokhirgootoiEsekh) return;
    try {
      await FirebaseMessaging.instance.deleteToken();
      _token = null;
    } catch (err) {
      AppLogger.log('[PUSH] Token устгахад алдаа: $err');
    }
  }
}

/// Android дээр мэдэгдэл ЧУХАЛ болж түгжээний дэлгэц дээр гарахын тулд
/// max importance-тэй канал шаардлагатай. Push-ийн default канал нь үүнийг
/// AndroidManifest дахь meta-data-аар холбоно.
const AndroidNotificationChannel pushKanal = AndroidNotificationChannel(
  'amarsukh_push',
  'Мэдэгдэл',
  description: 'Зочин, төлбөр, зогсоолын мэдэгдэл',
  importance: Importance.max,
);
