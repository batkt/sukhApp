import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';

/// ═══════════════════════════════════════════════════════════════════════════
///  Firebase (FCM) ТОХИРГОО — amarsukh-56668
/// ═══════════════════════════════════════════════════════════════════════════
///
/// Апп хаагдсан/арын дэвсгэрт байхад мэдэгдэл ирэхийн тулд FCM шаардлагатай.
/// Socket нь зөвхөн апп ОНГОЙ байхад ажилладаг тул түгжээний дэлгэц дээр
/// мэдэгдэл харуулж чадахгүй.
///
/// Сервер тал бэлэн: middleware/serviceAccountKey.json (project amarsukh-56668)
/// -аар admin.messaging() дамжуулан оршин суугчийн firebaseToken руу илгээдэг.
/// Дутуу нь ЗӨВХӨН доорх апп талын утгууд.
///
/// ┌─────────────────────────────────────────────────────────────────────┐
/// │ ХААНААС АВАХ                                                        │
/// │                                                                     │
/// │ Firebase Console -> amarsukh-56668 -> Project settings -> Your apps │
/// │                                                                     │
/// │ Android апп (com.home.sukh_app) бүртгээгүй бол "Add app" -> Android │
/// │ -> package name: com.home.sukh_app                                  │
/// │                                                                     │
/// │ Дараа нь google-services.json ТАТАХ ШААРДЛАГАГҮЙ - тэр файл дахь    │
/// │ дараах 4 утгыг л энд хуулна:                                        │
/// │   apiKey            = client[0].api_key[0].current_key              │
/// │   appId             = client[0].client_info.mobilesdk_app_id        │
/// │   messagingSenderId = project_info.project_number                   │
/// │   storageBucket     = project_info.storage_bucket                   │
/// │                                                                     │
/// │ (google-services.json-г ашиглах бол Gradle plugin нэмэх шаардлагтай │
/// │  болох тул тэр замаар ОРООГҮЙ - утга нь энд кодон дотор байна.)     │
/// └─────────────────────────────────────────────────────────────────────┘
///
/// Утгыг сольтол push мэдэгдэл АВТОМАТААР унтарсан хэвээр байна - апп хэвийн
/// ажиллаж, socket-ийн мэдэгдэл (апп онгой үед) ердийнхөөрөө гарна.
class FirebaseTokhirgoo {
  static const String projectId = "amarsukh-56668";

  // ─────────────────────────────────────────────────────────────────────────
  // ЭНД 4 УТГА ТАВИНА. "<...>" хэлбэртэй хэвээр байвал push унтраалттай.
  // ─────────────────────────────────────────────────────────────────────────
  static const String _apiKey = "AIzaSyDdbp-58Hzn4gP4ZwYwyzhtNjh-XrQsoNI";
  static const String _appId = "1:940397540730:android:c4468dc7223eceef8612c3";
  static const String _messagingSenderId = "940397540730";
  static const String _storageBucket = "amarsukh-56668.firebasestorage.app";

  // iOS-д өөр apiKey/appId байдаг. iOS дээр push хэрэгтэй бол доорхийг
  // бөглөнө, эс тэгвэл iOS дээр push унтраалттай хэвээр байна.
  static const String _iosApiKey = "<IOS API KEY>";
  static const String _iosAppId = "<1:000000000000:ios:0000000000000000>";
  static const String _iosBundleId = "com.home.sukhApp";

  static bool _utgaZuvEsekh(String utga) {
    final u = utga.trim();
    if (u.isEmpty) return false;
    // Placeholder "<...>" хэлбэрийг хүчингүйд тооцно
    if (u.startsWith("<") && u.endsWith(">")) return false;
    return true;
  }

  /// Тухайн платформд push ажиллах боломжтой эсэх
  static bool get tokhirgootoiEsekh {
    if (defaultTargetPlatform == TargetPlatform.iOS) {
      return _utgaZuvEsekh(_iosApiKey) && _utgaZuvEsekh(_iosAppId);
    }
    return _utgaZuvEsekh(_apiKey) &&
        _utgaZuvEsekh(_appId) &&
        _utgaZuvEsekh(_messagingSenderId);
  }

  /// google-services.json-гүйгээр Firebase-г ажиллуулах тохиргоо
  static FirebaseOptions get options {
    if (defaultTargetPlatform == TargetPlatform.iOS) {
      return FirebaseOptions(
        apiKey: _iosApiKey,
        appId: _iosAppId,
        messagingSenderId: _messagingSenderId,
        projectId: projectId,
        storageBucket: _storageBucket,
        iosBundleId: _iosBundleId,
      );
    }
    return FirebaseOptions(
      apiKey: _apiKey,
      appId: _appId,
      messagingSenderId: _messagingSenderId,
      projectId: projectId,
      storageBucket: _storageBucket,
    );
  }
}
