import 'dart:async' show TimeoutException;
import 'dart:io' show SocketException, HttpException, HandshakeException;

import 'package:http/http.dart' show ClientException;

/// Хэрэглэгчид харуулах алдааны мэдэгдлийг нэг жигд болгоно.
///
/// ЯАГААД: api_service-ийн `throw Exception('... алдаа гарлаа: $e')` нь
/// давхар ороогдож «Exception: ... алдаа гарлаа: Exception: SocketException:
/// Failed host lookup ...» гэх мэт техникийн текст хэрэглэгчид харагддаг байв.
/// Энд техникийн хэсгийг нь ойлгомжтой монгол тайлбар болгоно; серверээс ирсэн
/// монгол мэдэгдлийг (backend `aldaa` / `message`) хэвээр нь үлдээнэ.
const String kDefaultErrorMessage =
    'Алдаа гарлаа. Түр хүлээгээд дахин оролдоно уу.';

const String kNetworkErrorMessage =
    'Интернэт холболтгүй байна. Wi-Fi эсвэл мобайл датагаа асаагаад дахин оролдоно уу.';

const String kTimeoutErrorMessage =
    'Сервер хариу өгөхгүй удаж байна. Түр хүлээгээд дахин оролдоно уу.';

const String kServerErrorMessage =
    'Серверт түр саатал гарлаа. Хэсэг хугацааны дараа дахин оролдоно уу.';

const String kSessionExpiredMessage =
    'Нэвтрэх хугацаа дууссан байна. Дахин нэвтэрнэ үү.';

/// HTTP статус кодыг ойлгомжтой тайлбар болгоно.
String httpStatusMessage(int? statusCode) {
  switch (statusCode) {
    case 400:
      return 'Илгээсэн мэдээлэл буруу байна. Мэдээллээ шалгаад дахин оролдоно уу.';
    case 401:
      return kSessionExpiredMessage;
    case 403:
      return 'Танд энэ үйлдлийг хийх эрх байхгүй байна.';
    case 404:
      return 'Хүссэн мэдээлэл олдсонгүй.';
    case 408:
      return kTimeoutErrorMessage;
    case 409:
      return 'Энэ мэдээлэл аль хэдийн бүртгэгдсэн байна.';
    case 413:
      return 'Файлын хэмжээ хэт том байна. Жижиг файл сонгоно уу.';
    case 422:
      return 'Оруулсан мэдээлэл буруу байна. Шалгаад дахин оролдоно уу.';
    case 429:
      return 'Хэт олон хүсэлт илгээлээ. Түр хүлээгээд дахин оролдоно уу.';
    case 500:
    case 502:
    case 503:
    case 504:
      return kServerErrorMessage;
  }
  if (statusCode != null && statusCode >= 500) return kServerErrorMessage;
  return kDefaultErrorMessage;
}

/// Техникийн (англи) алдааны хэсгийг танина. Олдвол харгалзах тайлбарыг буцаана.
String? _technicalMessage(String lower) {
  if (lower.contains('socketexception') ||
      lower.contains('failed host lookup') ||
      lower.contains('network is unreachable') ||
      lower.contains('connection refused') ||
      lower.contains('connection reset') ||
      lower.contains('connection closed') ||
      lower.contains('connection abort') ||
      lower.contains('clientexception') ||
      lower.contains('no address associated') ||
      lower.contains('os error')) {
    return kNetworkErrorMessage;
  }
  if (lower.contains('handshakeexception') ||
      lower.contains('certificate_verify_failed') ||
      lower.contains('certificate')) {
    return 'Сервертэй аюулгүй холболт үүсгэж чадсангүй. Дахин оролдоно уу.';
  }
  if (lower.contains('timeoutexception') ||
      lower.contains('timed out') ||
      lower.contains('timeout')) {
    return kTimeoutErrorMessage;
  }
  if (lower.contains('jwt expired') ||
      lower.contains('jwt malformed') ||
      lower.contains('invalid token') ||
      lower.contains('unauthorized')) {
    return kSessionExpiredMessage;
  }
  if (lower.contains('formatexception') ||
      lower.contains('unexpected character') ||
      lower.contains('is not a subtype of') ||
      lower.contains('nosuchmethoderror') ||
      lower.contains('null check operator') ||
      lower.contains('rangeerror') ||
      lower.contains('typeerror') ||
      lower.contains('cannot read prop') ||
      lower.contains('undefined')) {
    return 'Мэдээлэл боловсруулахад алдаа гарлаа. Дахин оролдоно уу.';
  }
  if (lower.contains('e11000') || lower.contains('duplicate key')) {
    return 'Энэ мэдээлэл аль хэдийн бүртгэгдсэн байна.';
  }
  if (lower.contains('cast to objectid') || lower.contains('casterror')) {
    return 'Хүссэн мэдээлэл олдсонгүй.';
  }
  if (lower.contains('permission denied') ||
      lower.contains('permission_denied')) {
    return 'Шаардлагатай зөвшөөрөл олгогдоогүй байна. Тохиргооноос зөвшөөрөл олгоно уу.';
  }
  return null;
}

final RegExp _exceptionPrefix = RegExp(
  r'^(?:[A-Za-z_]*(?:Exception|Error)\s*:\s*)+',
);
final RegExp _trailingStatus = RegExp(r'[:\s(]+(?:status\s*:?\s*)?(\d{3})\)?\s*$',
    caseSensitive: false);
final RegExp _cyrillic = RegExp(r'[А-Яа-яӨөҮүЁё]');

/// Түүхий алдааны текстийг цэвэрлэж, хэрэглэгчид ойлгомжтой болгоно.
String cleanErrorText(String raw, {String? fallback}) {
  var text = raw.trim();
  if (text.isEmpty) return fallback ?? kDefaultErrorMessage;

  // «Exception: Exception: ...» гэх мэт давхар угтварыг арилгана
  text = text.replaceAll(_exceptionPrefix, '').trim();
  text = text.replaceAll(
    RegExp(r':\s*(?:[A-Za-z_]*(?:Exception|Error)\s*:\s*)+'),
    ': ',
  );

  // «<монгол тайлбар>: <техникийн шалтгаан>» хэлбэр — эхний монгол хэсгийг
  // үлдээж, шалтгааныг ойлгомжтой болгоно.
  final colon = text.indexOf(':');
  final head = colon > 0 ? text.substring(0, colon).trim() : text;
  final tail = colon > 0 ? text.substring(colon + 1).trim() : '';
  final lower = text.toLowerCase();

  final technical = _technicalMessage(lower);
  final statusMatch = _trailingStatus.firstMatch(text);
  final status = statusMatch != null ? int.tryParse(statusMatch.group(1)!) : null;
  final onlyStatus = RegExp(r'^\d{3}$').hasMatch(text);

  String? reason;
  if (technical != null) {
    reason = technical;
  } else if (onlyStatus) {
    reason = httpStatusMessage(int.parse(text));
  } else if (status != null && status >= 400 &&
      (tail.isEmpty || RegExp(r'^\d{3}\)?$').hasMatch(tail) ||
          !_cyrillic.hasMatch(tail))) {
    reason = httpStatusMessage(status);
  }

  if (reason == null) {
    // Техникийн зүйлгүй: монгол текст бол хэвээр, англи бол ерөнхий мэдэгдэл
    if (_cyrillic.hasMatch(text)) return _ensurePeriod(text);
    return fallback ?? kDefaultErrorMessage;
  }

  // «Нэхэмжлэх татахад алдаа гарлаа» + «Интернэт холболт ...»
  final headIsContext = colon > 0 &&
      _cyrillic.hasMatch(head) &&
      _technicalMessage(head.toLowerCase()) == null &&
      head != reason;
  if (headIsContext) {
    return '${_ensurePeriod(head)} $reason';
  }
  return reason;
}

/// Ямар ч төрлийн алдааг хэрэглэгчид харуулах текст болгоно.
String friendlyError(Object? error, {String? fallback}) {
  if (error == null) return fallback ?? kDefaultErrorMessage;
  if (error is SocketException || error is ClientException) {
    return kNetworkErrorMessage;
  }
  if (error is HandshakeException) {
    return 'Сервертэй аюулгүй холболт үүсгэж чадсангүй. Дахин оролдоно уу.';
  }
  if (error is TimeoutException) return kTimeoutErrorMessage;
  if (error is HttpException) return kNetworkErrorMessage;
  if (error is FormatException) {
    return 'Серверээс ирсэн мэдээллийг уншиж чадсангүй. Дахин оролдоно уу.';
  }
  // core/error/exceptions.dart-ийн message талбартай алдаанууд
  try {
    final dynamic d = error;
    final msg = d.message;
    if (msg is String && msg.trim().isNotEmpty && error is! Error) {
      return cleanErrorText(msg, fallback: fallback);
    }
  } catch (_) {}
  return cleanErrorText(error.toString(), fallback: fallback);
}

String _ensurePeriod(String s) {
  final t = s.trim();
  if (t.isEmpty) return t;
  final last = t[t.length - 1];
  if ('.!?…'.contains(last)) return t;
  return '$t.';
}
