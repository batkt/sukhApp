import 'package:shared_preferences/shared_preferences.dart';

/// StorageService - Handles persistent storage for authentication tokens and user data
///
/// This service uses SharedPreferences to store and retrieve authentication
/// tokens and user information securely on the device.
///
/// Usage:
/// ```dart
/// // Save token after login
/// await StorageService.saveToken('your_jwt_token_here');
///
/// // Get saved token
/// String? token = await StorageService.getToken();
///
/// // Check if user is logged in
/// bool isLoggedIn = await StorageService.isLoggedIn();
///
/// // Clear all data on logout
/// await StorageService.clearAll();
/// ```
class StorageService {
  static const String _tokenKey = 'auth_token';
  static const String _baiguullagiinIdKey = 'baiguullagiinId';
  static const String _baiguullagiinNerKey = 'baiguullagiinNer';
  static const String _userIdKey = 'user_id';
  static const String _userNerKey = 'user_ner';
  static const String _duusakhOgnooKey = 'duusakh_ognoo';

  /// Save authentication token
  static Future<bool> saveToken(String token) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return await prefs.setString(_tokenKey, token);
    } catch (e) {
      print('Error saving token: $e');
      return false;
    }
  }

  static Future<String?> getToken() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getString(_tokenKey);
    } catch (e) {
      print('Token алдаа: $e');
      return null;
    }
  }

  static Future<bool> isLoggedIn() async {
    final token = await getToken();
    return token != null && token.isNotEmpty;
  }

  /// Save user data after successful login
  ///
  /// Stores essential user information from the login response
  static Future<bool> saveUserData(Map<String, dynamic> userData) async {
    try {
      final prefs = await SharedPreferences.getInstance();

      // Save user ID
      if (userData['result']?['_id'] != null) {
        await prefs.setString(_userIdKey, userData['result']['_id']);
      }

      // Save user name
      if (userData['result']?['ner'] != null) {
        await prefs.setString(_userNerKey, userData['result']['ner']);
      }

      // Save baiguullagiinId
      if (userData['result']?['baiguullagiinId'] != null) {
        await prefs.setString(
          _baiguullagiinIdKey,
          userData['result']['baiguullagiinId'],
        );
      }

      // Save baiguullagiinNer
      if (userData['result']?['baiguullagiinNer'] != null) {
        await prefs.setString(
          _baiguullagiinNerKey,
          userData['result']['baiguullagiinNer'],
        );
      }

      // Save duusakhOgnoo
      if (userData['duusakhOgnoo'] != null) {
        await prefs.setString(_duusakhOgnooKey, userData['duusakhOgnoo']);
      }

      return true;
    } catch (e) {
      print('Error saving user data: $e');
      return false;
    }
  }

  /// Get user ID
  static Future<String?> getUserId() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getString(_userIdKey);
    } catch (e) {
      print('Error getting user ID: $e');
      return null;
    }
  }

  /// Get user name
  static Future<String?> getUserName() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getString(_userNerKey);
    } catch (e) {
      print('Error getting user name: $e');
      return null;
    }
  }

  /// Get baiguullagiinId
  static Future<String?> getBaiguullagiinId() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getString(_baiguullagiinIdKey);
    } catch (e) {
      print('Error getting baiguullagiinId: $e');
      return null;
    }
  }

  /// Get baiguullagiinNer
  static Future<String?> getBaiguullagiinNer() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getString(_baiguullagiinNerKey);
    } catch (e) {
      print('Error getting baiguullagiinNer: $e');
      return null;
    }
  }

  /// Get duusakhOgnoo (expiration date)
  static Future<String?> getDuusakhOgnoo() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getString(_duusakhOgnooKey);
    } catch (e) {
      print('Error getting duusakhOgnoo: $e');
      return null;
    }
  }

  /// Clear all stored data (use on logout)
  static Future<bool> clearAll() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return await prefs.clear();
    } catch (e) {
      print('Error clearing storage: $e');
      return false;
    }
  }

  /// Clear only authentication data (keep other app data)
  static Future<bool> clearAuthData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_tokenKey);
      await prefs.remove(_userIdKey);
      await prefs.remove(_userNerKey);
      await prefs.remove(_baiguullagiinIdKey);
      await prefs.remove(_baiguullagiinNerKey);
      await prefs.remove(_duusakhOgnooKey);
      return true;
    } catch (e) {
      print('Error clearing auth data: $e');
      return false;
    }
  }
}
