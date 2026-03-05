import 'package:package_info_plus/package_info_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:io';

class UpdateService {
  static const String _lastCheckedVersionKey = 'last_checked_app_version';
  static const String _updateDismissedKey = 'update_dismissed_version';
  static const String baseUrl = 'https://amarhome.mn/api';

  /// Check if app update is available
  /// Returns true if update is available, false otherwise
  static Future<bool> checkForUpdate() async {
    try {
      final packageInfo = await PackageInfo.fromPlatform();
      final currentVersion = packageInfo.version;
      final currentBuildNumber = packageInfo.buildNumber;

      // Check if we already dismissed this version
      final prefs = await SharedPreferences.getInstance();
      final dismissedVersion = prefs.getString(_updateDismissedKey);
      if (dismissedVersion == currentVersion) {
        return false; // User already dismissed this version
      }

      // Get latest version from API
      try {
        final response = await http.get(
          Uri.parse('$baseUrl/app-version'),
          headers: {'Content-Type': 'application/json'},
        );

        if (response.statusCode == 200) {
          final data = json.decode(response.body);
          final latestVersion = data['version']?.toString() ?? '';
          final latestBuildNumber = data['buildNumber']?.toString() ?? '';

          // Compare versions
          if (_isVersionNewer(latestVersion, latestBuildNumber, currentVersion, currentBuildNumber)) {
            // Save that we checked this version
            await prefs.setString(_lastCheckedVersionKey, currentVersion);
            return true;
          }
        }
      } catch (e) {
        // If API fails, we can still check using a fallback method
        // For now, we'll just return false
        print('Error checking app version from API: $e');
      }

      return false;
    } catch (e) {
      print('Error checking for update: $e');
      return false;
    }
  }

  /// Compare version strings to determine if latest is newer
  static bool _isVersionNewer(
    String latestVersion,
    String latestBuildNumber,
    String currentVersion,
    String currentBuildNumber,
  ) {
    // Compare version strings (e.g., "2.0.1" vs "2.0.0")
    final latestVersionParts = latestVersion.split('.').map((e) => int.tryParse(e) ?? 0).toList();
    final currentVersionParts = currentVersion.split('.').map((e) => int.tryParse(e) ?? 0).toList();

    // Compare major, minor, patch
    for (int i = 0; i < 3; i++) {
      final latest = i < latestVersionParts.length ? latestVersionParts[i] : 0;
      final current = i < currentVersionParts.length ? currentVersionParts[i] : 0;

      if (latest > current) return true;
      if (latest < current) return false;
    }

    // If versions are equal, compare build numbers
    final latestBuild = int.tryParse(latestBuildNumber) ?? 0;
    final currentBuild = int.tryParse(currentBuildNumber) ?? 0;

    return latestBuild > currentBuild;
  }

  /// Mark update as dismissed for current version
  static Future<void> dismissUpdate() async {
    try {
      final packageInfo = await PackageInfo.fromPlatform();
      final currentVersion = packageInfo.version;
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_updateDismissedKey, currentVersion);
    } catch (e) {
      print('Error dismissing update: $e');
    }
  }

  /// Get store URL based on platform
  static String getStoreUrl() {
    if (Platform.isIOS) {
      // Replace with your actual App Store ID
      return 'https://apps.apple.com/app/idYOUR_APP_ID';
    } else if (Platform.isAndroid) {
      // Replace with your actual package name
      return 'https://play.google.com/store/apps/details?id=com.home.sukh_app';
    }
    return '';
  }
}
