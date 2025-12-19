import 'package:local_auth/local_auth.dart';
import 'package:flutter/services.dart';
import 'package:flutter/material.dart';
import 'dart:io';

/// BiometricService - Handles biometric authentication (Face ID/Fingerprint)
class BiometricService {
  static LocalAuthentication? _auth;

  static LocalAuthentication get _instance {
    _auth ??= LocalAuthentication();
    return _auth!;
  }

  /// Check if biometric authentication is available
  static Future<bool> isAvailable() async {
    try {
      final isAvailable = await _instance.canCheckBiometrics;
      final isDeviceSupported = await _instance.isDeviceSupported();
      return isAvailable && isDeviceSupported;
    } catch (e) {
      return false;
    }
  }

  /// Get available biometric types
  static Future<List<BiometricType>> getAvailableBiometrics() async {
    try {
      return await _instance.getAvailableBiometrics();
    } catch (e) {
      return [];
    }
  }

  /// Authenticate using biometrics
  /// Returns true if authentication is successful
  static Future<bool> authenticate() async {
    try {
      final isAvailable = await BiometricService.isAvailable();
      if (!isAvailable) {
        return false;
      }

      // Determine the biometric type for the message
      final availableBiometrics = await getAvailableBiometrics();
      String localizedReason =
          'Нэвтрэхийн тулд биометрийн баталгаажуулалт хийх';

      // Customize message based on platform and available biometrics
      if (Platform.isIOS) {
        if (availableBiometrics.contains(BiometricType.face)) {
          localizedReason = 'Нэвтрэхийн тулд Face ID ашиглана уу';
        } else if (availableBiometrics.contains(BiometricType.fingerprint)) {
          localizedReason = 'Нэвтрэхийн тулд Touch ID ашиглана уу';
        }
      } else if (Platform.isAndroid) {
        if (availableBiometrics.contains(BiometricType.fingerprint)) {
          localizedReason = 'Нэвтрэхийн тулд хурууны хээ ашиглана уу';
        } else if (availableBiometrics.contains(BiometricType.face)) {
          localizedReason = 'Нэвтрэхийн тулд нүүрний таних ашиглана уу';
        }
      }

      // Use proper authentication - local_auth will automatically use Face ID on iOS and fingerprint on Android
      // The authenticate method will use the best available biometric method
      final didAuthenticate = await _instance.authenticate(
        localizedReason: localizedReason,
      );

      return didAuthenticate;
    } on PlatformException catch (e) {
      print('Biometric authentication error: $e');
      // Handle specific error codes
      if (e.code == 'NotAvailable' || 
          e.code == 'NotEnrolled' || 
          e.code == 'LockedOut' ||
          e.code == 'PermanentlyLockedOut') {
        return false;
      }
      return false;
    } catch (e) {
      print('Biometric authentication error: $e');
      return false;
    }
  }

  /// Get the appropriate icon for the device's biometric type
  static Future<IconData> getBiometricIcon() async {
    try {
      final availableBiometrics = await getAvailableBiometrics();
      
      if (Platform.isIOS) {
        // iOS: Prefer Face ID, fallback to Touch ID (fingerprint)
        if (availableBiometrics.contains(BiometricType.face)) {
          return Icons.face; // Face ID icon
        } else if (availableBiometrics.contains(BiometricType.fingerprint)) {
          return Icons.fingerprint; // Touch ID icon
        }
      } else if (Platform.isAndroid) {
        // Android: Prefer fingerprint, fallback to face
        if (availableBiometrics.contains(BiometricType.fingerprint)) {
          return Icons.fingerprint; // Fingerprint icon
        } else if (availableBiometrics.contains(BiometricType.face)) {
          return Icons.face; // Face recognition icon
        }
      }
      
      // Default fallback
      return Icons.fingerprint;
    } catch (e) {
      return Icons.fingerprint;
    }
  }

  /// Check if device has Face ID (iOS) or Face recognition (Android)
  static Future<bool> hasFaceId() async {
    try {
      final availableBiometrics = await getAvailableBiometrics();
      return availableBiometrics.contains(BiometricType.face);
    } catch (e) {
      return false;
    }
  }

  /// Check if device has fingerprint
  static Future<bool> hasFingerprint() async {
    try {
      final availableBiometrics = await getAvailableBiometrics();
      return availableBiometrics.contains(BiometricType.fingerprint);
    } catch (e) {
      return false;
    }
  }
}
