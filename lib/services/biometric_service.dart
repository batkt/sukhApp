import 'package:local_auth/local_auth.dart';
import 'package:flutter/services.dart';
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

      final didAuthenticate = await _instance.authenticate(
        localizedReason: localizedReason,
      );

      return didAuthenticate;
    } on PlatformException catch (e) {
      print('Biometric authentication error: $e');
      return false;
    } catch (e) {
      print('Biometric authentication error: $e');
      return false;
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
