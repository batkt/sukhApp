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
  static const String _savedPasswordKey = 'saved_password_biometric';
  static const String _biometricEnabledKey = 'biometric_enabled';
  static const String _tukhainBaaziinKholboltKey = 'tukhain_baaziin_kholbolt';
  static const String _walletBairIdKey = 'wallet_bair_id';
  static const String _walletDoorNoKey = 'wallet_door_no';
  static const String _walletBairSourceKey =
      'wallet_bair_source'; // 'WALLET_API' or 'OWN_ORG'
  static const String _walletBairBaiguullagiinIdKey =
      'wallet_bair_baiguullagiin_id';
  static const String _walletBairBarilgiinIdKey = 'wallet_bair_barilgiin_id';
  static const String _walletBillingIdKey = 'wallet_billing_id';
  static const String _phoneVerifiedKey = 'phone_verified';
  static const String _deviceIdKey = 'device_id';
  static const String _lastVerifiedDeviceIdKey = 'last_verified_device_id';

  static Future<bool> saveToken(String token) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return await prefs.setString(_tokenKey, token);
    } catch (e) {
      return false;
    }
  }

  static Future<String?> getToken() async {
    try {
      final prefs = await SharedPreferences.getInstance();

      return prefs.getString(_tokenKey);
    } catch (e) {
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

      // Backend may return user under `result` or `orshinSuugch` (login OTP flow).
      final dynamic userDynamic =
          userData['result'] ?? userData['orshinSuugch'];
      final Map<String, dynamic>? user = userDynamic is Map<String, dynamic>
          ? userDynamic
          : null;

      if (user?['_id'] != null) {
        await prefs.setString(_userIdKey, user!['_id'].toString());
      }

      // Save user name
      if (user?['ner'] != null) {
        await prefs.setString(_userNerKey, user!['ner'].toString());
      }

      // Save baiguullagiinId
      if (user?['baiguullagiinId'] != null) {
        await prefs.setString(
          _baiguullagiinIdKey,
          user!['baiguullagiinId'].toString(),
        );
      }

      // Save baiguullagiinNer
      if (user?['baiguullagiinNer'] != null) {
        await prefs.setString(
          _baiguullagiinNerKey,
          user!['baiguullagiinNer'].toString(),
        );
      }

      // Save barilgiinId
      if (user?['barilgiinId'] != null) {
        await prefs.setString(_barilgiinIdKey, user!['barilgiinId'].toString());
      }

      // Save tukhainBaaziinKholbolt - check multiple possible locations
      String? tukhainBaaziinKholbolt;

      // Check in result object first
      if (user?['tukhainBaaziinKholbolt'] != null) {
        tukhainBaaziinKholbolt = user!['tukhainBaaziinKholbolt'].toString();
      }
      // Check in root of userData
      else if (userData['tukhainBaaziinKholbolt'] != null) {
        tukhainBaaziinKholbolt = userData['tukhainBaaziinKholbolt'].toString();
      }
      // If not found, will use default below

      // Save the value (or default)
      await prefs.setString(
        _tukhainBaaziinKholboltKey,
        tukhainBaaziinKholbolt ?? 'amarSukh',
      );

      // Save duusakhOgnoo
      if (userData['duusakhOgnoo'] != null) {
        await prefs.setString(_duusakhOgnooKey, userData['duusakhOgnoo']);
      }

      // Save taniltsuulgaKharakhEsekh from backend
      if (user?['taniltsuulgaKharakhEsekh'] != null) {
        await prefs.setBool(
          _taniltsuulgaKharakhEsekhKey,
          user!['taniltsuulgaKharakhEsekh'] == true,
        );
      }

      return true;
    } catch (e) {
      return false;
    }
  }

  /// Get user ID
  static Future<String?> getUserId() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getString(_userIdKey);
    } catch (e) {
      return null;
    }
  }

  /// Get user name
  static Future<String?> getUserName() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getString(_userNerKey);
    } catch (e) {
      return null;
    }
  }

  /// Get baiguullagiinId
  static Future<String?> getBaiguullagiinId() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getString(_baiguullagiinIdKey);
    } catch (e) {
      return null;
    }
  }

  /// Get baiguullagiinNer
  static Future<String?> getBaiguullagiinNer() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getString(_baiguullagiinNerKey);
    } catch (e) {
      return null;
    }
  }

  /// Get barilgiinId
  static Future<String?> getBarilgiinId() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getString(_barilgiinIdKey);
    } catch (e) {
      return null;
    }
  }

  /// Get duusakhOgnoo (expiration date)
  static Future<String?> getDuusakhOgnoo() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getString(_duusakhOgnooKey);
    } catch (e) {
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
      return true;
    }
  }

  /// Set that user has seen onboarding/introduction
  static Future<bool> setTaniltsuulgaKharakhEsekh(bool value) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return await prefs.setBool(_taniltsuulgaKharakhEsekhKey, value);
    } catch (e) {
      return false;
    }
  }

  /// Clear all stored data (use on logout)
  static Future<bool> clearAll() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return await prefs.clear();
    } catch (e) {
      return false;
    }
  }

  /// Clear only authentication data (keep other app data)
  /// Note: shake hint shown status is NOT cleared - it persists across logouts
  /// Note: device ID is NOT cleared - it persists per device
  /// Note: lastVerifiedDeviceId is NOT cleared - it persists so same device doesn't need OTP again
  /// Phone verified flag is cleared on logout, but device verification persists
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
      // Clear wallet address on logout - each user should set their own address
      await prefs.remove(_walletBairIdKey);
      await prefs.remove(_walletDoorNoKey);
      // Clear phone verified flag on logout
      await prefs.remove(_phoneVerifiedKey);
      // NOTE: _lastVerifiedDeviceIdKey is NOT removed - it persists across logouts
      // This allows the same device to skip OTP verification on subsequent logins
      // Only new devices will require OTP verification
      // Note: _shakeHintShownKey, _deviceIdKey, and _lastVerifiedDeviceIdKey are NOT removed - they persist across sessions
      return true;
    } catch (e) {
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
      return false;
    }
  }

  /// Check if remember me is enabled
  static Future<bool> isRememberMeEnabled() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getBool(_rememberMeKey) ?? false;
    } catch (e) {
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

  /// Save password for biometric login (only when biometric is enabled)
  static Future<bool> savePasswordForBiometric(String password) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return await prefs.setString(_savedPasswordKey, password);
    } catch (e) {
      return false;
    }
  }

  /// Get saved password for biometric login
  static Future<String?> getSavedPasswordForBiometric() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getString(_savedPasswordKey);
    } catch (e) {
      return null;
    }
  }

  /// Clear saved password for biometric
  static Future<bool> clearSavedPasswordForBiometric() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_savedPasswordKey);
      await prefs.setBool(_biometricEnabledKey, false);
      return true;
    } catch (e) {
      return false;
    }
  }

  /// Check if biometric login is enabled
  static Future<bool> isBiometricEnabled() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getBool(_biometricEnabledKey) ?? false;
    } catch (e) {
      return false;
    }
  }

  /// Enable/disable biometric login
  static Future<bool> setBiometricEnabled(bool enabled) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return await prefs.setBool(_biometricEnabledKey, enabled);
    } catch (e) {
      return false;
    }
  }

  /// Get tukhainBaaziinKholbolt (database connection identifier)
  static Future<String?> getTukhainBaaziinKholbolt() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getString(_tukhainBaaziinKholboltKey) ?? 'amarSukh';
    } catch (e) {
      return 'amarSukh'; // Default fallback
    }
  }

  /// Save Wallet API address (bairId and doorNo)
  /// Also supports OWN_ORG bair with additional fields
  static Future<bool> saveWalletAddress({
    required String bairId,
    required String doorNo,
    String? source, // 'WALLET_API' or 'OWN_ORG'
    String? baiguullagiinId, // Required for OWN_ORG
    String? barilgiinId, // Required for OWN_ORG (same as bairId for OWN_ORG)
  }) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_walletBairIdKey, bairId);
      await prefs.setString(_walletDoorNoKey, doorNo);

      // Save OWN_ORG specific fields if provided
      if (source != null) {
        await prefs.setString(_walletBairSourceKey, source);
      }
      if (baiguullagiinId != null && baiguullagiinId.isNotEmpty) {
        await prefs.setString(_walletBairBaiguullagiinIdKey, baiguullagiinId);
      }
      if (barilgiinId != null && barilgiinId.isNotEmpty) {
        await prefs.setString(_walletBairBarilgiinIdKey, barilgiinId);
      }

      return true;
    } catch (e) {
      return false;
    }
  }

  /// Get saved Wallet API bairId
  static Future<String?> getWalletBairId() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getString(_walletBairIdKey);
    } catch (e) {
      return null;
    }
  }

  /// Get saved Wallet API doorNo
  static Future<String?> getWalletDoorNo() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getString(_walletDoorNoKey);
    } catch (e) {
      return null;
    }
  }

  /// Get saved bair source ('WALLET_API' or 'OWN_ORG')
  static Future<String?> getWalletBairSource() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getString(_walletBairSourceKey);
    } catch (e) {
      return null;
    }
  }

  /// Get saved OWN_ORG baiguullagiinId
  static Future<String?> getWalletBairBaiguullagiinId() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getString(_walletBairBaiguullagiinIdKey);
    } catch (e) {
      return null;
    }
  }

  /// Get saved OWN_ORG barilgiinId
  static Future<String?> getWalletBairBarilgiinId() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getString(_walletBairBarilgiinIdKey);
    } catch (e) {
      return null;
    }
  }

  /// Save Wallet API billingId
  static Future<bool> saveWalletBillingId(String billingId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return await prefs.setString(_walletBillingIdKey, billingId);
    } catch (e) {
      return false;
    }
  }

  /// Get saved Wallet API billingId
  static Future<String?> getWalletBillingId() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getString(_walletBillingIdKey);
    } catch (e) {
      return null;
    }
  }

  /// Check if user has saved address
  static Future<bool> hasSavedAddress() async {
    final bairId = await getWalletBairId();
    final doorNo = await getWalletDoorNo();
    return bairId != null &&
        bairId.isNotEmpty &&
        doorNo != null &&
        doorNo.isNotEmpty;
  }

  /// Clear saved Wallet API address
  static Future<bool> clearWalletAddress() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_walletBairIdKey);
      await prefs.remove(_walletDoorNoKey);
      await prefs.remove(_walletBairSourceKey);
      await prefs.remove(_walletBairBaiguullagiinIdKey);
      await prefs.remove(_walletBairBarilgiinIdKey);
      await prefs.remove(_walletBillingIdKey);
      return true;
    } catch (e) {
      return false;
    }
  }

  /// Save phone verification status
  static Future<bool> setPhoneVerified(bool verified) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return await prefs.setBool(_phoneVerifiedKey, verified);
    } catch (e) {
      return false;
    }
  }

  /// Get phone verification status
  static Future<bool> getPhoneVerified() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getBool(_phoneVerifiedKey) ?? false;
    } catch (e) {
      return false;
    }
  }

  /// Generate or get device ID (creates one if doesn't exist)
  static Future<String> getOrCreateDeviceId() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      String? deviceId = prefs.getString(_deviceIdKey);

      if (deviceId == null || deviceId.isEmpty) {
        // Generate a unique device ID based on timestamp and random
        deviceId =
            'device_${DateTime.now().millisecondsSinceEpoch}_${Uri.base.hashCode}';
        await prefs.setString(_deviceIdKey, deviceId);
        print('📱 [DEVICE] Generated new device ID: $deviceId');
      }

      return deviceId;
    } catch (e) {
      // Fallback device ID
      return 'device_${DateTime.now().millisecondsSinceEpoch}';
    }
  }

  /// Save device ID
  static Future<bool> saveDeviceId(String deviceId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return await prefs.setString(_deviceIdKey, deviceId);
    } catch (e) {
      return false;
    }
  }

  /// Get device ID
  static Future<String?> getDeviceId() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getString(_deviceIdKey);
    } catch (e) {
      return null;
    }
  }

  /// Save last verified device ID (device where phone was verified)
  static Future<bool> saveLastVerifiedDeviceId(String deviceId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return await prefs.setString(_lastVerifiedDeviceIdKey, deviceId);
    } catch (e) {
      return false;
    }
  }

  /// Get last verified device ID
  static Future<String?> getLastVerifiedDeviceId() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getString(_lastVerifiedDeviceIdKey);
    } catch (e) {
      return null;
    }
  }

  /// Check if current device is the same as last verified device
  static Future<bool> isSameDevice() async {
    try {
      final currentDeviceId = await getOrCreateDeviceId();
      final lastVerifiedDeviceId = await getLastVerifiedDeviceId();

      if (lastVerifiedDeviceId == null || lastVerifiedDeviceId.isEmpty) {
        return false; // No previous verification, so it's a new device
      }

      return currentDeviceId == lastVerifiedDeviceId;
    } catch (e) {
      return false;
    }
  }

  /// Check if phone verification is needed
  /// OTP is required in these cases:
  /// 1. First login after signup (no device verification record exists)
  /// 2. New device (different device ID than last verified device)
  /// OTP is NOT required if:
  /// - Same device as previously verified (trusted device)
  /// Returns true if verification is needed, false if it can be skipped
  static Future<bool> needsPhoneVerification() async {
    try {
      print('📱 [VERIFY] ========== Checking phone verification ==========');

      // Get current device ID (creates one if doesn't exist)
      final currentDeviceId = await getOrCreateDeviceId();
      print('📱 [VERIFY] Current device ID: $currentDeviceId');

      // Get last verified device ID
      final lastVerifiedDeviceId = await getLastVerifiedDeviceId();
      print('📱 [VERIFY] Last verified device ID: $lastVerifiedDeviceId');

      // CRITICAL: For first login after signup (no device verification record) → ALWAYS require verification
      if (lastVerifiedDeviceId == null || lastVerifiedDeviceId.isEmpty) {
        print(
          '📱 [VERIFY] ✅ Phone verification NEEDED: No device verification record (FIRST LOGIN after signup)',
        );
        return true;
      }

      // Check if it's the same device
      final isSameDevice = currentDeviceId == lastVerifiedDeviceId;
      print(
        '📱 [VERIFY] Is same device: $isSameDevice (current: $currentDeviceId, last: $lastVerifiedDeviceId)',
      );

      // If different device → ALWAYS require verification (new device)
      if (!isSameDevice) {
        print('📱 [VERIFY] ✅ Phone verification NEEDED: New device detected');
        return true;
      }

      // Same device → Skip OTP verification (trusted device)
      // We don't check phoneVerified flag because it's cleared on logout
      // But the device ID persists, so we can trust the same device
      print(
        '📱 [VERIFY] ❌ Phone verification NOT needed: Same device (trusted device)',
      );
      return false;
    } catch (e) {
      print('📱 [VERIFY] ❌ Error checking verification status: $e');
      // On error, require verification for safety
      print(
        '📱 [VERIFY] ✅ Phone verification NEEDED: Error occurred, requiring for safety',
      );
      return true;
    }
  }
}
