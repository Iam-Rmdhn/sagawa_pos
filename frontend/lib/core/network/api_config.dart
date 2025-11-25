/// API Configuration for connecting to Go backend
class ApiConfig {
  ApiConfig._();

  // Base URLs - Change based on environment
  static const String _devBaseUrl = 'http://localhost:8080';
  static const String _prodBaseUrl =
      'https://api.sagawapos.com'; // Ganti dengan domain VPS Anda

  // Current environment - Set to false for production
  static const bool isDevelopment = true;

  // Get current base URL based on environment
  static String get baseUrl => isDevelopment ? _devBaseUrl : _prodBaseUrl;

  // API Endpoints
  static const String apiVersion = '/api/v1';

  // Product endpoints
  static const String products = '$apiVersion/products';
  static String productById(String id) => '$apiVersion/products/$id';

  // Menu (menu_makanan) endpoint
  static const String menu = '$apiVersion/menu';
  static String menuById(String id) => '$apiVersion/menu/$id';

  // Order endpoints
  static const String orders = '$apiVersion/orders';
  static String orderById(String id) => '$apiVersion/orders/$id';

  // Customer endpoints
  static const String customers = '$apiVersion/customers';
  static String customerById(String id) => '$apiVersion/customers/$id';

  // Payment endpoints
  static const String payments = '$apiVersion/payments';
  static String paymentById(String id) => '$apiVersion/payments/$id';

  // Timeouts
  static const Duration connectTimeout = Duration(seconds: 30);
  static const Duration receiveTimeout = Duration(seconds: 30);
  static const Duration sendTimeout = Duration(seconds: 30);

  // Headers
  static Map<String, String> get defaultHeaders => {
    'Content-Type': 'application/json',
    'Accept': 'application/json',
  };

  // Full URL builder
  static String getFullUrl(String endpoint) => '$baseUrl$endpoint';
}
