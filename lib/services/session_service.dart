import 'package:shared_preferences/shared_preferences.dart';
import 'package:sukh_app/services/notification_service.dart';
import 'package:sukh_app/services/storage_service.dart';
import 'package:sukh_app/core/auth_config.dart';

class SessionService {
  static const String _loginTimestampKey = 'login_timestamp';
  static const Duration _sessionDuration = Duration(minutes: 15);

  static Future<void> saveLoginTimestamp() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      await prefs.setInt(_loginTimestampKey, timestamp);
    } catch (e) {}
  }

  static Future<DateTime?> getLoginTimestamp() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final timestamp = prefs.getInt(_loginTimestampKey);
      if (timestamp == null) return null;
      return DateTime.fromMillisecondsSinceEpoch(timestamp);
    } catch (e) {
      return null;
    }
  }

  static Future<bool> isSessionValid() async {
    final loginTime = await getLoginTimestamp();
    if (loginTime == null) return false;

    final now = DateTime.now();
    final difference = now.difference(loginTime);

    return difference < _sessionDuration;
  }

  static Future<Duration?> getRemainingSessionTime() async {
    final loginTime = await getLoginTimestamp();
    if (loginTime == null) return null;

    final now = DateTime.now();
    final elapsed = now.difference(loginTime);
    final remaining = _sessionDuration - elapsed;

    return remaining.isNegative ? Duration.zero : remaining;
  }

  static Future<bool> checkAndHandleSession() async {
    final isLoggedIn = await StorageService.isLoggedIn();

    if (!isLoggedIn) {
      return false;
    }

    final isValid = await isSessionValid();

    if (!isValid) {
      // Session expired - show notification and logout
      await NotificationService.showSessionExpiredNotification();
      await logout();
      return false;
    }

    return true;
  }

  /// Logout the user and clear all data
  static Future<void> logout() async {
    await AuthConfig.instance.logout();
    await clearLoginTimestamp();
  }

  /// Clear the login timestamp
  static Future<void> clearLoginTimestamp() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_loginTimestampKey);
    } catch (e) {
      // Silent fail
    }
  }

  /// Update login timestamp (call this on successful login)
  static Future<void> updateLoginTimestamp() async {
    await saveLoginTimestamp();
  }

  static Future<Map<String, dynamic>> getSessionInfo() async {
    final loginTime = await getLoginTimestamp();
    final isValid = await isSessionValid();
    final remaining = await getRemainingSessionTime();

    return {
      'loginTime': loginTime?.toIso8601String(),
      'isValid': isValid,
      'remainingHours': remaining?.inHours,
      'remainingMinutes': remaining?.inMinutes.remainder(60),
    };
  }
}
