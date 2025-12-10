import 'package:socket_io_client/socket_io_client.dart' as IO;
import 'package:sukh_app/services/storage_service.dart';

class SocketService {
  static SocketService? _instance;
  IO.Socket? socket;
  String? _userId;
  String? _baiguullagiinId;
  bool _isConnected = false;

  SocketService._();

  static SocketService get instance {
    _instance ??= SocketService._();
    return _instance!;
  }

  /// Initialize socket connection
  Future<void> connect() async {
    try {
      // Get server URL from API service
      const serverUrl = 'http://103.50.205.80:8084';

      // Get user ID
      _userId = await StorageService.getUserId();
      _baiguullagiinId = await StorageService.getBaiguullagiinId();

      if (_userId == null) {
        print('⚠️ Cannot connect socket: User not logged in');
        return;
      }

      // Disconnect existing connection if any
      if (socket != null && socket!.connected) {
        disconnect();
      }

      socket = IO.io(
        serverUrl,
        IO.OptionBuilder()
            .setTransports(['websocket'])
            .enableAutoConnect()
            .setTimeout(20000)
            .build(),
      );

      socket!.connect();

      socket!.onConnect((_) {
        _isConnected = true;
        print('✅ Socket connected');
        
        // Listen for user notifications after connection
        if (_userId != null) {
          _listenForUserNotifications();
        }
      });

      socket!.onDisconnect((_) {
        _isConnected = false;
        print('❌ Socket disconnected');
      });

      socket!.onError((error) {
        print('❌ Socket error: $error');
        _isConnected = false;
      });

      socket!.onConnectError((error) {
        print('❌ Socket connection error: $error');
        _isConnected = false;
      });
    } catch (e) {
      print('❌ Error initializing socket: $e');
      _isConnected = false;
    }
  }

  /// Listen for user notifications
  void _listenForUserNotifications() {
    if (_userId == null || socket == null) return;

    final eventName = 'orshinSuugch$_userId';
    
    // Remove existing listener if any
    socket!.off(eventName);
    
    socket!.on(eventName, (data) {
      print('📬 New notification received: $data');
      
      // Notify all registered callbacks
      for (final callback in _notificationCallbacks) {
        try {
          callback(data);
        } catch (e) {
          print('Error in notification callback: $e');
        }
      }
    });
  }

  /// Listen for QPay payment updates
  void listenForQPayUpdates(
    String invoiceNumber,
    Function(Map<String, dynamic>) callback,
  ) {
    if (_baiguullagiinId == null || socket == null) return;

    final eventName = 'qpay/$_baiguullagiinId/$invoiceNumber';
    
    socket!.off(eventName);
    socket!.on(eventName, (data) {
      print('💳 QPay update received: $data');
      callback(data);
    });
  }

  /// Listen for employee updates
  void listenForEmployeeUpdates(
    String employeeId,
    Function(Map<String, dynamic>) callback,
  ) {
    if (socket == null) return;

    final eventName = 'ajiltan$employeeId';
    
    socket!.off(eventName);
    socket!.on(eventName, (data) {
      print('👤 Employee update received: $data');
      callback(data);
    });
  }

  /// Listen for auto logout
  void listenForAutoLogout(Function(Map<String, dynamic>) callback) {
    if (_baiguullagiinId == null || socket == null) return;

    final eventName = 'autoLogout$_baiguullagiinId';
    
    socket!.off(eventName);
    socket!.on(eventName, (data) {
      print('🚪 Auto logout received: $data');
      callback(data);
    });
  }

  /// Callback for notifications - use a list to support multiple callbacks
  final List<Function(Map<String, dynamic>)> _notificationCallbacks = [];

  /// Set callback for user notifications (adds to list, doesn't replace)
  void setNotificationCallback(Function(Map<String, dynamic>) callback) {
    // Remove if already exists to avoid duplicates
    _notificationCallbacks.remove(callback);
    _notificationCallbacks.add(callback);
    
    // If already connected, set up listener
    if (_isConnected && _userId != null) {
      _listenForUserNotifications();
    }
  }

  /// Remove notification callback
  void removeNotificationCallback([Function(Map<String, dynamic>)? callback]) {
    if (callback != null) {
      _notificationCallbacks.remove(callback);
    } else {
      _notificationCallbacks.clear();
    }
    
    // Only remove socket listener if no callbacks remain
    if (_notificationCallbacks.isEmpty && _userId != null && socket != null) {
      socket!.off('orshinSuugch$_userId');
    }
  }

  /// Check if socket is connected
  bool get isConnected => _isConnected && socket?.connected == true;

  /// Disconnect socket
  void disconnect() {
    if (socket != null) {
      // Remove all listeners
      if (_userId != null) {
        socket!.off('orshinSuugch$_userId');
      }
      if (_baiguullagiinId != null) {
        socket!.off('autoLogout$_baiguullagiinId');
      }
      
      socket!.disconnect();
      socket!.dispose();
      socket = null;
      _isConnected = false;
      _notificationCallbacks.clear();
      print('🔌 Socket disconnected and disposed');
    }
  }

  /// Reconnect socket
  Future<void> reconnect() async {
    disconnect();
    await Future.delayed(const Duration(seconds: 1));
    await connect();
  }
}

