import 'dart:async';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:sukh_app/utils/error_message.dart';

void main() {
  group('friendlyError', () {
    test('socket errors become network message', () {
      expect(friendlyError(const SocketException('Failed host lookup')),
          kNetworkErrorMessage);
    });

    test('timeouts become timeout message', () {
      expect(friendlyError(TimeoutException('x')), kTimeoutErrorMessage);
    });

    test('nested wrapped network error keeps Mongolian context', () {
      final e = Exception(
          'Нэхэмжлэхийн түүх татахад алдаа гарлаа: Exception: SocketException: Failed host lookup: api.example.mn');
      expect(friendlyError(e),
          'Нэхэмжлэхийн түүх татахад алдаа гарлаа. $kNetworkErrorMessage');
    });

    test('trailing status code is explained', () {
      final e = Exception('Хот авахад алдаа гарлаа: 500');
      expect(friendlyError(e), 'Хот авахад алдаа гарлаа. $kServerErrorMessage');
    });

    test('Mongolian backend message is kept as is', () {
      expect(friendlyError(Exception('Утасны дугаар бүртгэлгүй байна')),
          'Утасны дугаар бүртгэлгүй байна.');
    });

    test('plain English technical text falls back to generic message', () {
      expect(friendlyError(Exception('Something weird happened')),
          kDefaultErrorMessage);
      expect(
          friendlyError(Exception('Something weird happened'),
              fallback: 'Мэдэгдэл илгээж чадсангүй.'),
          'Мэдэгдэл илгээж чадсангүй.');
    });

    test('jwt expired maps to session expired', () {
      expect(friendlyError(Exception('jwt expired')), kSessionExpiredMessage);
    });

    test('bare status code string', () {
      expect(friendlyError(Exception('404')), httpStatusMessage(404));
    });
  });
}
