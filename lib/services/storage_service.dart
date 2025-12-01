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
  static const String _barilgiinIdKey = 'barilgiinId';
  static const String _userIdKey = 'user_id';
  static const String _userNerKey = 'user_ner';
  static const String _duusakhOgnooKey = 'duusakh_ognoo';
  static const String _taniltsuulgaKharakhEsekhKey =
      'taniltsuulga_kharakh_esekh';
  static const String _savedPhoneKey = 'saved_phone_number';
  static const String _rememberMeKey = 'remember_me';
  static const String _shakeHintShownKey = 'shake_hint_shown';

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

  static Future<bool> saveUserData(Map<String, dynamic> userData) async {
    try {
      final prefs = await SharedPreferences.getInstance();

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

      // Save barilgiinId
      if (userData['result']?['barilgiinId'] != null) {
        await prefs.setString(
          _barilgiinIdKey,
          userData['result']['barilgiinId'],
        );
      }

      // Save duusakhOgnoo
      if (userData['duusakhOgnoo'] != null) {
        await prefs.setString(_duusakhOgnooKey, userData['duusakhOgnoo']);
      }

      // Save taniltsuulgaKharakhEsekh from backend
      if (userData['result']?['taniltsuulgaKharakhEsekh'] != null) {
        await prefs.setBool(
          _taniltsuulgaKharakhEsekhKey,
          userData['result']['taniltsuulgaKharakhEsekh'],
        );
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

  /// Get barilgiinId
  static Future<String?> getBarilgiinId() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getString(_barilgiinIdKey);
    } catch (e) {
      print('Error getting barilgiinId: $e');
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

  /// Check if user has seen onboarding/introduction
  /// Default is true (show onboarding for first-time users)
  static Future<bool> getTaniltsuulgaKharakhEsekh() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getBool(_taniltsuulgaKharakhEsekhKey) ?? true;
    } catch (e) {
      print('Error getting taniltsuulgaKharakhEsekh: $e');
      return true;
    }
  }

  /// Set that user has seen onboarding/introduction
  static Future<bool> setTaniltsuulgaKharakhEsekh(bool value) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return await prefs.setBool(_taniltsuulgaKharakhEsekhKey, value);
    } catch (e) {
      print('Error setting taniltsuulgaKharakhEsekh: $e');
      return false;
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
  /// Note: shake hint shown status is NOT cleared - it persists across logouts
  static Future<bool> clearAuthData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_tokenKey);
      await prefs.remove(_userIdKey);
      await prefs.remove(_userNerKey);
      await prefs.remove(_baiguullagiinIdKey);
      await prefs.remove(_baiguullagiinNerKey);
      await prefs.remove(_barilgiinIdKey);
      await prefs.remove(_duusakhOgnooKey);
      await prefs.remove(_taniltsuulgaKharakhEsekhKey);
      // Note: _shakeHintShownKey is NOT removed - it persists across sessions
      return true;
    } catch (e) {
      print('Error clearing auth data: $e');
      return false;
    }
  }

  /// Save phone number when "Remember me" is checked
  static Future<bool> savePhoneNumber(String phoneNumber) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_savedPhoneKey, phoneNumber);
      await prefs.setBool(_rememberMeKey, true);
      return true;
    } catch (e) {
      print('Error saving phone number: $e');
      return false;
    }
  }

  /// Get saved phone number
  static Future<String?> getSavedPhoneNumber() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final rememberMe = prefs.getBool(_rememberMeKey) ?? false;
      if (rememberMe) {
        return prefs.getString(_savedPhoneKey);
      }
      return null;
    } catch (e) {
      print('Error getting saved phone number: $e');
      return null;
    }
  }

  /// Clear saved phone number
  static Future<bool> clearSavedPhoneNumber() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_savedPhoneKey);
      await prefs.setBool(_rememberMeKey, false);
      return true;
    } catch (e) {
      print('Error clearing saved phone number: $e');
      return false;
    }
  }

  /// Check if remember me is enabled
  static Future<bool> isRememberMeEnabled() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getBool(_rememberMeKey) ?? false;
    } catch (e) {
      print('Error checking remember me: $e');
      return false;
    }
  }

  /// Check if shake hint has been shown
  static Future<bool> hasShakeHintBeenShown() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getBool(_shakeHintShownKey) ?? false;
    } catch (e) {
      return false;
    }
  }

  /// Mark shake hint as shown
  static Future<bool> setShakeHintShown(bool value) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return await prefs.setBool(_shakeHintShownKey, value);
    } catch (e) {
      return false;
    }
  }
}
