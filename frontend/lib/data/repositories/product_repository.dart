import 'package:sagawa_pos_new/core/network/api_client.dart';
import 'package:sagawa_pos_new/core/network/api_config.dart';
import 'package:sagawa_pos_new/core/network/api_exception.dart';
import 'package:dio/dio.dart';

/// Repository for product-related API calls
class ProductRepository {
  final ApiClient _apiClient = ApiClient();

  /// Get all products
  Future<List<dynamic>> getAllProducts() async {
    try {
      final response = await _apiClient.get(ApiConfig.products);
      return response.data as List<dynamic>;
    } on DioException catch (e) {
      throw e.toApiException();
    }
  }

  /// Get product by ID
  Future<Map<String, dynamic>> getProductById(String id) async {
    try {
      final response = await _apiClient.get('${ApiConfig.products}/$id');
      return response.data as Map<String, dynamic>;
    } on DioException catch (e) {
      throw e.toApiException();
    }
  }

  /// Create new product
  Future<Map<String, dynamic>> createProduct(
    Map<String, dynamic> productData,
  ) async {
    try {
      final response = await _apiClient.post(
        ApiConfig.products,
        data: productData,
      );
      return response.data as Map<String, dynamic>;
    } on DioException catch (e) {
      throw e.toApiException();
    }
  }

  /// Update product
  Future<Map<String, dynamic>> updateProduct(
    String id,
    Map<String, dynamic> productData,
  ) async {
    try {
      final response = await _apiClient.put(
        '${ApiConfig.products}/$id',
        data: productData,
      );
      return response.data as Map<String, dynamic>;
    } on DioException catch (e) {
      throw e.toApiException();
    }
  }

  /// Delete product
  Future<void> deleteProduct(String id) async {
    try {
      await _apiClient.delete('${ApiConfig.products}/$id');
    } on DioException catch (e) {
      throw e.toApiException();
    }
  }

  /// Search products by name or category
  Future<List<dynamic>> searchProducts({String? name, String? category}) async {
    try {
      final queryParameters = <String, dynamic>{};
      if (name != null) queryParameters['name'] = name;
      if (category != null) queryParameters['category'] = category;

      final response = await _apiClient.get(
        ApiConfig.products,
        queryParameters: queryParameters,
      );
      return response.data as List<dynamic>;
    } on DioException catch (e) {
      throw e.toApiException();
    }
  }
}
