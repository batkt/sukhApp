import 'package:sukh_app/services/socket_service.dart';

class HomeSocketManager {
  static void Function(Map<String, dynamic>)? _callback;

  static void setupSocketListener({
    required void Function() onNotificationReceived,
    required void Function() onBillingDataChanged,
  }) {
    if (_callback != null) return;
    _callback = (notification) {
      onNotificationReceived();

      final title = notification['title']?.toString().toLowerCase() ?? '';
      final message = notification['message']?.toString().toLowerCase() ?? '';
      final turul = notification['turul']?.toString().toLowerCase() ?? '';
      final guilgee = notification['guilgee'];
      final guilgeeTurul = guilgee is Map
          ? (guilgee['turul']?.toString().toLowerCase() ?? '')
          : '';

      final isBillingRelated =
          (guilgeeTurul == 'avlaga') ||
          title.contains('нэхэмжлэх') ||
          title.contains('авлага') ||
          title.contains('нэмэгдлээ') ||
          message.contains('нэхэмжлэх') ||
          message.contains('авлага') ||
          message.contains('нэмэгдлээ') ||
          message.contains('manualsend') ||
          (turul == 'мэдэгдэл' || turul == 'medegdel' || turul == 'app');

      if (isBillingRelated) {
        Future.delayed(const Duration(milliseconds: 500), onBillingDataChanged);
      }
    };
    SocketService.instance.setNotificationCallback(_callback!);
  }

  static void dispose() {
    if (_callback != null) {
      SocketService.instance.removeNotificationCallback(_callback);
      _callback = null;
    }
  }
}
