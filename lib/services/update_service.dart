import 'package:package_info_plus/package_info_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:io';

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
      message: json['message']?.toString() ?? 'Апп-ын шинэ хувилбар гарсан байна. Шинэчлэх үү?',
      buildNumber: json['buildNumber']?.toString() ?? '0',
    );
  }
}

class UpdateService {
  static const String _lastCheckedVersionKey = 'last_checked_app_version';
  static const String _updateDismissedKey = 'update_dismissed_version';
  static const String baseUrl = 'https://amarhome.mn/api';

  static AppVersionInfo? _latestVersionInfo;
  static AppVersionInfo? get latestVersionInfo => _latestVersionInfo;

  /// Check if app update is available
  /// Returns the AppVersionInfo if update is available, null otherwise
  static Future<AppVersionInfo?> checkForUpdate() async {
    try {
      final packageInfo = await PackageInfo.fromPlatform();
      final currentVersion = packageInfo.version;
      final currentBuildNumber = packageInfo.buildNumber;

      // Check if we already dismissed this version (only for non-force updates)
      final prefs = await SharedPreferences.getInstance();
      final dismissedVersion = prefs.getString(_updateDismissedKey);

      // Get latest version from API
      try {
        final platform = Platform.isIOS ? 'ios' : 'android';
        final response = await http.get(
          Uri.parse('$baseUrl/app-version?platform=$platform'),
          headers: {'Content-Type': 'application/json'},
        );

        if (response.statusCode == 200) {
          final data = json.decode(response.body);
          final versionInfo = AppVersionInfo.fromJson(data);
          _latestVersionInfo = versionInfo;

          // Check if current version is below minVersion (FORCE UPDATE)
          if (versionInfo.minVersion.isNotEmpty) {
            if (_isVersionNewer(versionInfo.minVersion, '0', currentVersion, currentBuildNumber)) {
              // Current version is below minimum allowed version
              return versionInfo.copyWith(isForceUpdate: true);
            }
          }

          // Compare versions for normal update
          if (_isVersionNewer(versionInfo.version, versionInfo.buildNumber, currentVersion, currentBuildNumber)) {
            // Check if user has already dismissed this specific version
            if (versionInfo.isForceUpdate || dismissedVersion != versionInfo.version) {
              return versionInfo;
            }
          }
        }
      } catch (e) {
        print('Error checking app version from API: $e');
      }

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
    final latestParts = latestVersion.split('.').map((e) => int.tryParse(e) ?? 0).toList();
    final currentParts = currentVersion.split('.').map((e) => int.tryParse(e) ?? 0).toList();

    final maxParts = latestParts.length > currentParts.length ? latestParts.length : currentParts.length;

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

  /// Get store URL based on platform
  static String getStoreUrl() {
    if (_latestVersionInfo != null && _latestVersionInfo!.updateUrl.isNotEmpty) {
      return _latestVersionInfo!.updateUrl;
    }

    if (Platform.isIOS) {
      return 'https://apps.apple.com/mn/app/amar-home/id6738981440';
    } else if (Platform.isAndroid) {
      return 'https://play.google.com/store/apps/details?id=com.home.sukh_app';
    }
    return '';
  }
}

extension on AppVersionInfo {
  AppVersionInfo copyWith({bool? isForceUpdate}) {
    return AppVersionInfo(
      version: version,
      minVersion: minVersion,
      isForceUpdate: isForceUpdate ?? this.isForceUpdate,
      updateUrl: updateUrl,
      message: message,
      buildNumber: buildNumber,
    );
  }
}
