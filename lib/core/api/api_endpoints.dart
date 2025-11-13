/// Centralized API endpoints configuration
class ApiEndpoints {
  // Base URL
  static const String baseUrl = 'http://103.50.205.80:8084';

  // API Version (if needed in future)
  static const String apiVersion = 'v1';

  // Auth Endpoints
  static const String login = '/auth/login';
  static const String register = '/auth/register';
  static const String passwordReset = '/auth/password-reset';
  static const String verifyOtp = '/auth/verify-otp';
  static const String refreshToken = '/auth/refresh-token';

  // Location Endpoints
  static const String baiguullaga = '/baiguullaga';
  static const String districts = '/locations/districts';
  static String khotkhons(String districtId) =>
      '/locations/khotkhons/$districtId';
  static String sokhs(String khotkhonCode) => '/locations/sokhs/$khotkhonCode';

  static const String userProfile = '/users/profile';
  static const String updateProfile = '/users/profile';
  static const String changePassword = '/users/password';
  static const String uploadAvatar = '/users/upload-avatar';

  static const String bookings = '/bookings';
  static String booking(String id) => '/bookings/$id';
  static String bookingCalendar(int year, int month) =>
      '/bookings/calendar/$year/$month';

  static const String payments = '/payments';
  static const String invoices = '/invoices';
  static String payment(String id) => '/payments/$id';
  static String invoice(String id) => '/invoices/$id';

  static const String notifications = '/notifications';
  static String markNotificationRead(String id) => '/notifications/$id/read';

  static const String feedback = '/feedback';
  static const String callService = '/call-service';
  static const String supportTickets = '/support-tickets';

  static const String vehicles = '/vehicles';
  static String vehicle(String id) => '/vehicles/$id';
}
