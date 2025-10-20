import 'package:sukh_app/services/api_service.dart';

/// AuthConfig - Global configuration for managing baiguullagiinId
///
/// This class provides a singleton pattern to store and access baiguullagiinId
/// throughout the application. It fetches the ID dynamically from the
/// baiguullagaBairshilaarAvya service based on user's selected location.
///
/// Usage:
/// ```dart
/// // Initialize with location data
/// await AuthConfig.instance.initialize(
///   duureg: 'Баянгол',
///   districtCode: '10201',
///   sohCode: '001',
/// );
///
/// // Get baiguullagiinId anywhere in the app
/// String? id = AuthConfig.instance.baiguullagiinId;
///
/// // Or use the getter method
/// String? id = AuthConfig.instance.getBaiguullagiinId();
/// ```
class AuthConfig {
  static final AuthConfig _instance = AuthConfig._internal();

  /// Get the singleton instance
  static AuthConfig get instance => _instance;

  // Private constructor
  AuthConfig._internal();

  // Store the baiguullagiinId
  String? _baiguullagiinId;

  // Store location data
  String? _duureg;
  String? _districtCode;
  String? _sohCode;

  /// Get the current baiguullagiinId
  String? get baiguullagiinId => _baiguullagiinId;

  /// Get the current duureg
  String? get duureg => _duureg;

  /// Get the current districtCode (horoo/khotkhon)
  String? get districtCode => _districtCode;

  /// Get the current sohCode
  String? get sohCode => _sohCode;

  /// Check if AuthConfig has been initialized
  bool get isInitialized => _baiguullagiinId != null;

  /// Initialize the AuthConfig with location data
  ///
  /// Fetches baiguullagiinId from the API based on the provided location.
  ///
  /// Parameters:
  /// - [duureg]: District name (optional)
  /// - [districtCode]: Khotkhon/Horoo code (optional)
  /// - [sohCode]: SOH code (optional)
  ///
  /// Returns the fetched baiguullagiinId or null if not found
  ///
  /// Throws an Exception if the API call fails
  Future<String?> initialize({
    String? duureg,
    String? districtCode,
    String? sohCode,
  }) async {
    try {
      _duureg = duureg;
      _districtCode = districtCode;
      _sohCode = sohCode;

      _baiguullagiinId = await ApiService.getBaiguullagiinId(
        duureg: duureg,
        districtCode: districtCode,
        sohCode: sohCode,
      );

      return _baiguullagiinId;
    } catch (e) {
      throw Exception('AuthConfig initialization failed: $e');
    }
  }

  /// Update the baiguullagiinId with new location data
  ///
  /// Use this when the user changes their location selection
  Future<String?> updateLocation({
    String? duureg,
    String? districtCode,
    String? sohCode,
  }) async {
    return await initialize(
      duureg: duureg,
      districtCode: districtCode,
      sohCode: sohCode,
    );
  }

  /// Get baiguullagiinId (same as the getter property)
  String? getBaiguullagiinId() {
    return _baiguullagiinId;
  }

  /// Set baiguullagiinId directly (use with caution)
  ///
  /// It's recommended to use initialize() or updateLocation() instead
  void setBaiguullagiinId(String id) {
    _baiguullagiinId = id;
  }

  /// Clear all stored data
  void clear() {
    _baiguullagiinId = null;
    _duureg = null;
    _districtCode = null;
    _sohCode = null;
  }

  Map<String, String?> getLocationData() {
    return {
      'baiguullagiinId': _baiguullagiinId,
      'duureg': _duureg,
      'districtCode': _districtCode,
      'sohCode': _sohCode,
    };
  }
}
