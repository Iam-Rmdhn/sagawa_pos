import 'package:sagawa_pos_new/core/network/api_client.dart';
import 'package:sagawa_pos_new/core/network/api_config.dart';
import 'package:sagawa_pos_new/core/network/api_exception.dart';
import 'package:dio/dio.dart';

/// Repository for customer-related API calls
class CustomerRepository {
  final ApiClient _apiClient = ApiClient();

  /// Get all customers
  Future<List<dynamic>> getAllCustomers() async {
    try {
      final response = await _apiClient.get(ApiConfig.customers);
      return response.data as List<dynamic>;
    } on DioException catch (e) {
      throw e.toApiException();
    }
  }

  /// Get customer by ID
  Future<Map<String, dynamic>> getCustomerById(String id) async {
    try {
      final response = await _apiClient.get('${ApiConfig.customers}/$id');
      return response.data as Map<String, dynamic>;
    } on DioException catch (e) {
      throw e.toApiException();
    }
  }

  /// Create new customer
  Future<Map<String, dynamic>> createCustomer(
    Map<String, dynamic> customerData,
  ) async {
    try {
      final response = await _apiClient.post(
        ApiConfig.customers,
        data: customerData,
      );
      return response.data as Map<String, dynamic>;
    } on DioException catch (e) {
      throw e.toApiException();
    }
  }

  /// Update customer
  Future<Map<String, dynamic>> updateCustomer(
    String id,
    Map<String, dynamic> customerData,
  ) async {
    try {
      final response = await _apiClient.put(
        '${ApiConfig.customers}/$id',
        data: customerData,
      );
      return response.data as Map<String, dynamic>;
    } on DioException catch (e) {
      throw e.toApiException();
    }
  }

  /// Delete customer
  Future<void> deleteCustomer(String id) async {
    try {
      await _apiClient.delete('${ApiConfig.customers}/$id');
    } on DioException catch (e) {
      throw e.toApiException();
    }
  }

  /// Search customers by name or phone
  Future<List<dynamic>> searchCustomers({String? name, String? phone}) async {
    try {
      final queryParameters = <String, dynamic>{};
      if (name != null) queryParameters['name'] = name;
      if (phone != null) queryParameters['phone'] = phone;

      final response = await _apiClient.get(
        ApiConfig.customers,
        queryParameters: queryParameters,
      );
      return response.data as List<dynamic>;
    } on DioException catch (e) {
      throw e.toApiException();
    }
  }
}
