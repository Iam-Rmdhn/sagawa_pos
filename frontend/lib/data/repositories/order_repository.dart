import 'package:sagawa_pos_new/core/network/api_client.dart';
import 'package:sagawa_pos_new/core/network/api_config.dart';
import 'package:sagawa_pos_new/core/network/api_exception.dart';
import 'package:dio/dio.dart';

/// Repository for order-related API calls
class OrderRepository {
  final ApiClient _apiClient = ApiClient();

  /// Get all orders
  Future<List<dynamic>> getAllOrders() async {
    try {
      final response = await _apiClient.get(ApiConfig.orders);
      return response.data as List<dynamic>;
    } on DioException catch (e) {
      throw e.toApiException();
    }
  }

  /// Get order by ID
  Future<Map<String, dynamic>> getOrderById(String id) async {
    try {
      final response = await _apiClient.get('${ApiConfig.orders}/$id');
      return response.data as Map<String, dynamic>;
    } on DioException catch (e) {
      throw e.toApiException();
    }
  }

  /// Create new order
  Future<Map<String, dynamic>> createOrder(
    Map<String, dynamic> orderData,
  ) async {
    try {
      final response = await _apiClient.post(ApiConfig.orders, data: orderData);
      return response.data as Map<String, dynamic>;
    } on DioException catch (e) {
      throw e.toApiException();
    }
  }

  /// Update order status
  Future<Map<String, dynamic>> updateOrderStatus(
    String id,
    String status,
  ) async {
    try {
      final response = await _apiClient.patch(
        '${ApiConfig.orders}/$id/status',
        data: {'status': status},
      );
      return response.data as Map<String, dynamic>;
    } on DioException catch (e) {
      throw e.toApiException();
    }
  }

  /// Cancel order
  Future<void> cancelOrder(String id) async {
    try {
      await _apiClient.delete('${ApiConfig.orders}/$id');
    } on DioException catch (e) {
      throw e.toApiException();
    }
  }

  /// Get orders by customer ID
  Future<List<dynamic>> getOrdersByCustomer(String customerId) async {
    try {
      final response = await _apiClient.get(
        ApiConfig.orders,
        queryParameters: {'customer_id': customerId},
      );
      return response.data as List<dynamic>;
    } on DioException catch (e) {
      throw e.toApiException();
    }
  }

  /// Get orders by date range
  Future<List<dynamic>> getOrdersByDateRange({
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    try {
      final response = await _apiClient.get(
        ApiConfig.orders,
        queryParameters: {
          'start_date': startDate.toIso8601String(),
          'end_date': endDate.toIso8601String(),
        },
      );
      return response.data as List<dynamic>;
    } on DioException catch (e) {
      throw e.toApiException();
    }
  }
}
