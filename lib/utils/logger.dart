import 'package:flutter/foundation.dart';

class AppLogger {
  static void log(String message) {
    if (kDebugMode) {
      print(message);
    }
  }

  static void error(String message, [dynamic error, StackTrace? stackTrace]) {
    if (kDebugMode) {
      print('❌ ERROR: $message');
      if (error != null) print('Details: $error');
      if (stackTrace != null) print(stackTrace);
    }
  }

  static void info(String message) {
    if (kDebugMode) {
      print('ℹ️ INFO: $message');
    }
  }

  static void api(String method, String url, {dynamic body, dynamic response}) {
    if (kDebugMode) {
      print('🌐 API [$method]: $url');
      if (body != null) print('Request Body: $body');
      if (response != null) print('Response Body: $response');
    }
  }
}
