// Core Constants
class AppConstants {
  // API
  static const String apiTimeout = '30';
  static const int connectTimeout = 30000;
  static const int receiveTimeout = 30000;

  // App Info
  static const String appName = 'Sagawa POS';
  static const String appVersion = '1.0.0';

  // Storage Keys
  static const String keyToken = 'token';
  static const String keyUser = 'user';
  static const String keyTheme = 'theme';
  static const String keyLanguage = 'language';

  // Pagination
  static const int defaultPageSize = 20;
  static const int maxPageSize = 100;

  // Order Status
  static const String orderStatusPending = 'pending';
  static const String orderStatusCompleted = 'completed';
  static const String orderStatusCancelled = 'cancelled';

  // Payment Methods
  static const List<String> paymentMethods = [
    'Cash',
    'Qris',
  ];
}
