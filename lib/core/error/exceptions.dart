/// Custom exceptions for API errors
class ServerException implements Exception {
  final String message;
  final int? statusCode;

  ServerException({required this.message, this.statusCode});

  @override
  String toString() => 'ServerException: $message (Status: $statusCode)';
}

class NetworkException implements Exception {
  final String message;

  NetworkException({this.message = 'Интернэт холбогдоогүй байна'});

  @override
  String toString() => 'NetworkException: $message';
}

class UnauthorizedException implements Exception {
  final String message;

  UnauthorizedException({this.message = 'Нэвтрэх эрх хүчингүй байна'});

  @override
  String toString() => 'UnauthorizedException: $message';
}

class ValidationException implements Exception {
  final String message;
  final Map<String, dynamic>? errors;

  ValidationException({required this.message, this.errors});

  @override
  String toString() => 'ValidationException: $message';
}

class CacheException implements Exception {
  final String message;

  CacheException({this.message = 'Кэш хадгалахад алдаа гарлаа'});

  @override
  String toString() => 'CacheException: $message';
}

class TimeoutException implements Exception {
  final String message;

  TimeoutException({this.message = 'Хүсэлт хэт удаж байна'});

  @override
  String toString() => 'TimeoutException: $message';
}
