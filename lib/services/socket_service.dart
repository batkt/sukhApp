import 'package:socket_io_client/socket_io_client.dart' as IO;
import 'package:sukh_app/services/storage_service.dart';
import 'package:sukh_app/services/notification_service.dart';

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
      // Socket.io is at site root (same as web). Do not use /api so nginx can proxy /socket.io.
      const serverUrl = 'https://amarhome.mn';

      // Get user ID
      _userId = await StorageService.getUserId();
      _baiguullagiinId = await StorageService.getBaiguullagiinId();

      if (_userId == null) {
        return;
      }

      // Disconnect existing connection if any
      if (socket != null && socket!.connected) {
        disconnect();
      }

      socket = IO.io(
        serverUrl,
        IO.OptionBuilder()
            .setTransports(['websocket', 'polling'])
            .enableAutoConnect()
            .setTimeout(20000)
            .setPath('/socket.io')
            .build(),
      );

      socket!.connect();

      socket!.onConnect((_) {
        _isConnected = true;

        // Listen for user notifications after connection
        if (_userId != null) {
          _listenForUserNotifications();
        }
        // Re-attach baiguullagiin medegdel listener if callback was set before connect
        if (_baiguullagiinId != null &&
            _baiguullagiinMedegdelCallback != null) {
          final eventName = 'baiguullagiin$_baiguullagiinId';
          socket!.off(eventName, _onBaiguullagiinMedegdel);
          socket!.on(eventName, _onBaiguullagiinMedegdel);
        }
      });

      socket!.onDisconnect((_) {
        _isConnected = false;
      });

      socket!.onError((error) {
        _isConnected = false;
      });

      socket!.onConnectError((error) {
        _isConnected = false;
      });
    } catch (e) {
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
      // Unwrap if server sent multiple args (e.g. [payload])
      if (data is List && data.isNotEmpty) data = data.first;

      // Show system notification (banner / lock screen) for any incoming notification
      try {
        if (data is Map<String, dynamic>) {
          final title = data['title']?.toString().trim() ?? 'Шинэ мэдэгдэл';
          final message = data['message']?.toString().trim() ?? '';
          final turul = data['turul']?.toString().toLowerCase() ?? '';
          final body = message.isNotEmpty ? message : title;
          final showAsBanner = title.isNotEmpty || message.isNotEmpty;
          final isAppType =
              turul == 'app' ||
              turul == 'мэдэгдэл' ||
              turul == 'medegdel' ||
              turul == 'khariu' ||
              turul == 'хариу';
          if (showAsBanner && (isAppType || message.isNotEmpty)) {
            NotificationService.showNotification(
              id: DateTime.now().millisecondsSinceEpoch % 100000,
              title: title.isNotEmpty ? title : 'Шинэ мэдэгдэл',
              body: body,
              payload: data['_id']?.toString(),
            );
          }
        }
      } catch (e) {
        // Silent fail
      }

      // Notify all registered callbacks
      for (int i = 0; i < _notificationCallbacks.length; i++) {
        try {
          final callback = _notificationCallbacks[i];

          // Ensure data is a Map before passing
          Map<String, dynamic> notificationData;
          if (data is Map<String, dynamic>) {
            notificationData = data;
          } else if (data is Map) {
            // Convert to Map<String, dynamic>
            notificationData = Map<String, dynamic>.from(data);
          } else {
            continue;
          }

          callback(notificationData);
        } catch (e) {
          // Silent fail
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
      callback(data);
    });
  }

  /// Listen for auto logout
  void listenForAutoLogout(Function(Map<String, dynamic>) callback) {
    if (_baiguullagiinId == null || socket == null) return;

    final eventName = 'autoLogout$_baiguullagiinId';

    socket!.off(eventName);
    socket!.on(eventName, (data) {
      callback(data);
    });
  }

  Function(Map<String, dynamic>)? _baiguullagiinMedegdelCallback;

  /// Listen for medegdel list updates (user reply / admin reply) on baiguullagiin channel for real-time sanal khuselt list.
  void setBaiguullagiinMedegdelCallback(
    Function(Map<String, dynamic>)? callback,
  ) {
    _baiguullagiinMedegdelCallback = callback;
    if (_baiguullagiinId == null || socket == null) return;
    final eventName = 'baiguullagiin$_baiguullagiinId';
    socket!.off(eventName, _onBaiguullagiinMedegdel);
    if (callback != null) {
      socket!.on(eventName, _onBaiguullagiinMedegdel);
    }
  }

  void _onBaiguullagiinMedegdel(dynamic data) {
    if (_baiguullagiinMedegdelCallback == null) return;
    if (data is! Map && data is! Map<String, dynamic>) return;
    final map = data is Map<String, dynamic>
        ? data
        : Map<String, dynamic>.from(data as Map);
    final type = map['type']?.toString();
    if (type == 'medegdelUserReply' || type == 'medegdelAdminReply') {
      _baiguullagiinMedegdelCallback!(map);
    }
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
        socket!.off('baiguullagiin$_baiguullagiinId', _onBaiguullagiinMedegdel);
      }
      _baiguullagiinMedegdelCallback = null;

      socket!.disconnect();
      socket!.dispose();
      socket = null;
      _isConnected = false;
      _notificationCallbacks.clear();
    }
  }

  /// Reconnect socket
  Future<void> reconnect() async {
    disconnect();
    await Future.delayed(const Duration(seconds: 1));
    await connect();
  }
}
