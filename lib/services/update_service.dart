import 'package:package_info_plus/package_info_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart' show kIsWeb, defaultTargetPlatform;
import 'package:sukh_app/core/api/api_host.dart';

class AppVersionInfo {
  final String version;
  final String minVersion;
  final bool isForceUpdate;
  final String updateUrl;
  final String message;
  final String buildNumber;

  AppVersionInfo({
    required this.version,
    required this.minVersion,
    required this.isForceUpdate,
    required this.updateUrl,
    required this.message,
    required this.buildNumber,
  });

  factory AppVersionInfo.fromJson(Map<String, dynamic> json) {
    return AppVersionInfo(
      version: json['version']?.toString() ?? '',
      minVersion: json['minVersion']?.toString() ?? '',
      isForceUpdate: json['isForceUpdate'] == true,
      updateUrl: json['updateUrl']?.toString() ?? '',
      message:
          json['message']?.toString() ??
          'Апп-ын шинэ хувилбар гарсан байна. Шинэчлэх үү?',
      buildNumber: json['buildNumber']?.toString() ?? '0',
    );
  }
}

class UpdateService {
  static const String _lastCheckedVersionKey = 'last_checked_app_version';
  static const String _updateDismissedKey = 'update_dismissed_version';
  // ӨМНӨ НЬ prod дээр хатуу байсан — version_service-тэй ижил асуудал.
  static const String baseUrl = ApiHost.api;

  static AppVersionInfo? _latestVersionInfo;
  static AppVersionInfo? get latestVersionInfo => _latestVersionInfo;

  /// iOS bundle id — App Store-оос сүүлийн хувилбарыг автоматаар асуухад
  static const String _iosBundleId = 'com.zevtabs.sukhapp';
  static const String _androidPackage = 'com.home.sukh_app';

  /// Нэг сессэд модалыг нэг л удаа харуулна (resume бүрд дахин гаргахгүй)
  static bool _shownThisSession = false;
  static bool get shownThisSession => _shownThisSession;
  static void markShown() => _shownThisSession = true;

  static String get storeName {
    if (!kIsWeb && Platform.isIOS) return 'App Store';
    if (!kIsWeb && Platform.isAndroid) return 'Play Store';
    return 'дэлгүүр';
  }

  static String get defaultMessage =>
      'Аппын шинэ хувилбар гарлаа. Шинэ боломжууд болон сайжруулалтыг ашиглахын тулд $storeName-оос шинэчилнэ үү.';

  /// App Store дээр бодитоор нийтлэгдсэн хувилбар (iOS). Админ backend дээр
  /// хувилбар шинэчлэхээ мартсан ч App Store-д гарсан даруйд модал гарна.
  static Future<Map<String, String>?> _appStoreVersion() async {
    try {
      final uri = Uri.parse(
        'https://itunes.apple.com/lookup?bundleId=$_iosBundleId&country=mn&_t=${DateTime.now().millisecondsSinceEpoch}',
      );
      final res = await http.get(uri).timeout(const Duration(seconds: 8));
      if (res.statusCode != 200) return null;
      final data = json.decode(res.body);
      final results = data['results'];
      if (results is List && results.isNotEmpty) {
        final r = results.first;
        return {
          'version': r['version']?.toString() ?? '',
          'url': r['trackViewUrl']?.toString() ?? '',
        };
      }
    } catch (e) {
      print('App Store version lookup failed: $e');
    }
    return null;
  }

  static Future<AppVersionInfo?> _backendVersion(String platform) async {
    try {
      final response = await http
          .get(
            Uri.parse('$baseUrl/app-version?platform=$platform'),
            headers: {'Content-Type': 'application/json'},
          )
          .timeout(const Duration(seconds: 8));
      if (response.statusCode != 200) return null;
      final responseJson = json.decode(response.body);
      // Handle wrapped response format: {success: true, data: {...}}
      final Map<String, dynamic> data =
          responseJson['success'] == true && responseJson['data'] != null
              ? responseJson['data']
              : responseJson;
      return AppVersionInfo.fromJson(data);
    } catch (e) {
      print('Error checking app version from API: $e');
      return null;
    }
  }

  /// Check if app update is available
  /// Returns the AppVersionInfo if update is available, null otherwise
  ///
  /// Эх сурвалж: backend `/app-version` (вэбээс/админаас тохируулдаг,
  /// minVersion ба isForceUpdate) + iOS дээр App Store-ын бодит хувилбар.
  static Future<AppVersionInfo?> checkForUpdate() async {
    try {
      if (kIsWeb) return null;
      final packageInfo = await PackageInfo.fromPlatform();
      final currentVersion = packageInfo.version;
      final currentBuildNumber = packageInfo.buildNumber;

      // Check if we already dismissed this version (only for non-force updates)
      final prefs = await SharedPreferences.getInstance();
      final dismissedVersion = prefs.getString(_updateDismissedKey);

      final platform = Platform.isIOS
          ? 'ios'
          : Platform.isAndroid
              ? 'android'
              : 'unknown';

      final results = await Future.wait([
        _backendVersion(platform),
        Platform.isIOS ? _appStoreVersion() : Future.value(null),
      ]);
      final backend = results[0] as AppVersionInfo?;
      final store = results[1] as Map<String, String>?;

      // iOS: App Store-д бодитоор гарсан хувилбар нь үнэн эх сурвалж —
      // backend дээр зарласан ч дэлгүүрт хараахан гараагүй бол санал болгохгүй.
      String latest = backend?.version ?? '';
      String buildNumber = backend?.buildNumber ?? '0';
      String updateUrl = backend?.updateUrl ?? '';
      if (store != null && (store['version'] ?? '').isNotEmpty) {
        latest = store['version']!;
        buildNumber = '0';
        if (updateUrl.isEmpty) updateUrl = store['url'] ?? '';
      }
      if (latest.isEmpty) return null;

      // minVersion-оос доош бол заавал шинэчлэх
      final minVersion = backend?.minVersion ?? '';
      final belowMin = minVersion.isNotEmpty &&
          _isVersionNewer(minVersion, '0', currentVersion, '0');
      final force = (backend?.isForceUpdate ?? false) || belowMin;

      final message = (backend != null &&
              backend.message.isNotEmpty &&
              backend.message != 'Апп-ын шинэ хувилбар гарсан байна. Шинэчлэх үү?')
          ? backend.message
          : defaultMessage;

      final info = AppVersionInfo(
        version: latest,
        minVersion: minVersion,
        isForceUpdate: force,
        updateUrl: updateUrl,
        message: message,
        buildNumber: buildNumber,
      );
      _latestVersionInfo = info;

      final newer = buildNumber == '0'
          ? _isVersionNewer(latest, '0', currentVersion, '0')
          : _isVersionNewer(
              latest, buildNumber, currentVersion, currentBuildNumber);
      if (!newer && !belowMin) return null;

      // Check if user has already dismissed this specific version
      if (force || dismissedVersion != info.version) return info;
      return null;
    } catch (e) {
      print('Error checking for update: $e');
      return null;
    }
  }

  /// Compare version strings to determine if latest is newer
  static bool _isVersionNewer(
    String latestVersion,
    String latestBuildNumber,
    String currentVersion,
    String currentBuildNumber,
  ) {
    if (latestVersion.isEmpty) return false;

    // Compare version strings (e.g., "2.0.1" vs "2.0.0")
    final latestParts = latestVersion
        .split('.')
        .map((e) => int.tryParse(e) ?? 0)
        .toList();
    final currentParts = currentVersion
        .split('.')
        .map((e) => int.tryParse(e) ?? 0)
        .toList();

    final maxParts = latestParts.length > currentParts.length
        ? latestParts.length
        : currentParts.length;

    for (int i = 0; i < maxParts; i++) {
      final latest = i < latestParts.length ? latestParts[i] : 0;
      final current = i < currentParts.length ? currentParts[i] : 0;

      if (latest > current) return true;
      if (latest < current) return false;
    }

    // If version numbers are equal, compare build numbers
    final lBuild = int.tryParse(latestBuildNumber) ?? 0;
    final cBuild = int.tryParse(currentBuildNumber) ?? 0;

    return lBuild > cBuild;
  }

  /// Mark update as dismissed for current version
  static Future<void> dismissUpdate(String version) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_updateDismissedKey, version);
    } catch (e) {
      print('Error dismissing update: $e');
    }
  }

  /// Android-д Play Store аппыг шууд нээх (market://) холбоос
  static String get androidMarketUrl => 'market://details?id=$_androidPackage';

  /// Get store URL based on platform
  static String getStoreUrl() {
    if (_latestVersionInfo != null &&
        _latestVersionInfo!.updateUrl.isNotEmpty) {
      return _latestVersionInfo!.updateUrl;
    }

    if (kIsWeb) {
      return ApiHost.api;
    }

    if (Platform.isIOS) {
      return 'https://apps.apple.com/mn/app/amar-home/id6738981440';
    } else if (Platform.isAndroid) {
      return 'https://play.google.com/store/apps/details?id=$_androidPackage';
    }
    return '';
  }
}
