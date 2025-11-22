import 'package:sagawa_pos_new/core/network/api_client.dart';
import 'package:sagawa_pos_new/core/network/api_config.dart';
import 'package:sagawa_pos_new/core/network/api_exception.dart';
import 'package:dio/dio.dart';

/// Repository for payment-related API calls
class PaymentRepository {
  final ApiClient _apiClient = ApiClient();

  /// Process payment
  Future<Map<String, dynamic>> processPayment(
    Map<String, dynamic> paymentData,
  ) async {
    try {
      final response = await _apiClient.post(
        ApiConfig.payments,
        data: paymentData,
      );
      return response.data as Map<String, dynamic>;
    } on DioException catch (e) {
      throw e.toApiException();
    }
  }

  /// Get payment by ID
  Future<Map<String, dynamic>> getPaymentById(String id) async {
    try {
      final response = await _apiClient.get('${ApiConfig.payments}/$id');
      return response.data as Map<String, dynamic>;
    } on DioException catch (e) {
      throw e.toApiException();
    }
  }

  /// Get payment by order ID
  Future<Map<String, dynamic>> getPaymentByOrderId(String orderId) async {
    try {
      final response = await _apiClient.get(
        ApiConfig.payments,
        queryParameters: {'order_id': orderId},
      );
      return response.data as Map<String, dynamic>;
    } on DioException catch (e) {
      throw e.toApiException();
    }
  }

  /// Verify QRIS payment
  Future<Map<String, dynamic>> verifyQrisPayment(String paymentId) async {
    try {
      final response = await _apiClient.post(
        '${ApiConfig.payments}/$paymentId/verify-qris',
      );
      return response.data as Map<String, dynamic>;
    } on DioException catch (e) {
      throw e.toApiException();
    }
  }

  /// Get payment history
  Future<List<dynamic>> getPaymentHistory({
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    try {
      final queryParameters = <String, dynamic>{};
      if (startDate != null) {
        queryParameters['start_date'] = startDate.toIso8601String();
      }
      if (endDate != null) {
        queryParameters['end_date'] = endDate.toIso8601String();
      }

      final response = await _apiClient.get(
        ApiConfig.payments,
        queryParameters: queryParameters,
      );
      return response.data as List<dynamic>;
    } on DioException catch (e) {
      throw e.toApiException();
    }
  }

  /// Refund payment
  Future<Map<String, dynamic>> refundPayment(
    String paymentId, {
    String? reason,
  }) async {
    try {
      final response = await _apiClient.post(
        '${ApiConfig.payments}/$paymentId/refund',
        data: reason != null ? {'reason': reason} : null,
      );
      return response.data as Map<String, dynamic>;
    } on DioException catch (e) {
      throw e.toApiException();
    }
  }
}
