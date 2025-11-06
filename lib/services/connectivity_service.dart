import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';
import 'package:sukh_app/widgets/glass_snackbar.dart';

class ConnectivityService {
  static final ConnectivityService _instance = ConnectivityService._internal();
  factory ConnectivityService() => _instance;
  ConnectivityService._internal();

  final Connectivity _connectivity = Connectivity();
  StreamSubscription<List<ConnectivityResult>>? _connectivitySubscription;

  bool _isConnected = true;
  bool get isConnected => _isConnected;

  BuildContext? _context;
  bool _hasShownOfflineMessage = false;

  void initialize(BuildContext context) {
    _context = context;
    _checkInitialConnectivity();
    _startMonitoring();
  }

  Future<void> _checkInitialConnectivity() async {
    try {
      final result = await _connectivity.checkConnectivity();
      _updateConnectionStatus(result);
    } catch (e) {
      print('Error checking initial connectivity: $e');
    }
  }

  void _startMonitoring() {
    _connectivitySubscription = _connectivity.onConnectivityChanged.listen(
      (List<ConnectivityResult> result) {
        _updateConnectionStatus(result);
      },
    );
  }

  void _updateConnectionStatus(List<ConnectivityResult> results) {
    final wasConnected = _isConnected;

    // Check if any of the results indicate a connection
    _isConnected = results.any((result) =>
      result != ConnectivityResult.none
    );

    // Show messages only when status changes
    if (!_isConnected && wasConnected) {
      // Lost connection
      _hasShownOfflineMessage = true;
      _showOfflineMessage();
    } else if (_isConnected && !wasConnected && _hasShownOfflineMessage) {
      // Regained connection
      _hasShownOfflineMessage = false;
      _showOnlineMessage();
    }
  }

  void _showOfflineMessage() {
    if (_context != null && _context!.mounted) {
      showGlassSnackBar(
        _context!,
        message: 'Интернэт холболтоо шалгана уу',
        icon: Icons.wifi_off,
        iconColor: Colors.red,
        textColor: Colors.white,
      );
    }
  }

  void _showOnlineMessage() {
    if (_context != null && _context!.mounted) {
      showGlassSnackBar(
        _context!,
        message: 'Интернэт холболт сэргэсэн',
        icon: Icons.wifi,
        iconColor: Colors.green,
        textColor: Colors.white,
      );
    }
  }

  Future<bool> checkConnection() async {
    try {
      final result = await _connectivity.checkConnectivity();
      return result.any((r) => r != ConnectivityResult.none);
    } catch (e) {
      print('Error checking connection: $e');
      return false;
    }
  }

  void showNoInternetError() {
    if (_context != null && _context!.mounted) {
      showGlassSnackBar(
        _context!,
        message: 'Интернэт холболтоо шалгана уу',
        icon: Icons.wifi_off,
        iconColor: Colors.red,
        textColor: Colors.white,
      );
    }
  }

  void dispose() {
    _connectivitySubscription?.cancel();
    _context = null;
  }
}
