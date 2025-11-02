import 'package:dio/dio.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import '../../../../core/errors/exceptions.dart';
import '../../../../core/utils/logger.dart';
import '../models/product_model.dart';

abstract class ProductRemoteDataSource {
  Future<List<ProductModel>> getAllProducts();
  Future<ProductModel> getProductById(String id);
  Future<ProductModel> createProduct(ProductModel product);
  Future<ProductModel> updateProduct(String id, ProductModel product);
  Future<void> deleteProduct(String id);
}

class ProductRemoteDataSourceImpl implements ProductRemoteDataSource {
  final Dio dio;
  final String baseUrl;

  ProductRemoteDataSourceImpl({required this.dio, String? baseUrl})
    : baseUrl =
          baseUrl ??
          dotenv.env['API_BASE_URL'] ??
          'http://localhost:8080/api/v1';

  @override
  Future<List<ProductModel>> getAllProducts() async {
    try {
      AppLogger.info('Fetching all products from $baseUrl/products');

      final response = await dio.get('$baseUrl/products');

      if (response.statusCode == 200) {
        final List<dynamic> data = response.data;
        return data.map((json) => ProductModel.fromJson(json)).toList();
      } else {
        throw ServerException(
          'Failed to load products: ${response.statusCode}',
          response.statusCode ?? 500,
        );
      }
    } on DioException catch (e) {
      AppLogger.error('DioError fetching products', error: e);
      throw NetworkException('Network error: ${e.message}');
    } catch (e) {
      AppLogger.error('Error fetching products', error: e);
      if (e is ServerException) rethrow;
      throw NetworkException('Network error: $e');
    }
  }

  @override
  Future<ProductModel> getProductById(String id) async {
    try {
      final response = await dio.get('$baseUrl/products/$id');

      if (response.statusCode == 200) {
        return ProductModel.fromJson(response.data);
      } else if (response.statusCode == 404) {
        throw ServerException('Product not found', 404);
      } else {
        throw ServerException(
          'Failed to load product: ${response.statusCode}',
          response.statusCode ?? 500,
        );
      }
    } on DioException catch (e) {
      AppLogger.error('DioError fetching product $id', error: e);
      if (e.response?.statusCode == 404) {
        throw ServerException('Product not found', 404);
      }
      throw NetworkException('Network error: ${e.message}');
    } catch (e) {
      AppLogger.error('Error fetching product $id', error: e);
      if (e is ServerException) rethrow;
      throw NetworkException('Network error: $e');
    }
  }

  @override
  Future<ProductModel> createProduct(ProductModel product) async {
    try {
      final response = await dio.post(
        '$baseUrl/products',
        data: product.toJson(),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        return ProductModel.fromJson(response.data);
      } else {
        throw ServerException(
          'Failed to create product: ${response.statusCode}',
          response.statusCode ?? 500,
        );
      }
    } on DioException catch (e) {
      AppLogger.error('DioError creating product', error: e);
      throw NetworkException('Network error: ${e.message}');
    } catch (e) {
      AppLogger.error('Error creating product', error: e);
      if (e is ServerException) rethrow;
      throw NetworkException('Network error: $e');
    }
  }

  @override
  Future<ProductModel> updateProduct(String id, ProductModel product) async {
    try {
      final response = await dio.put(
        '$baseUrl/products/$id',
        data: product.toJson(),
      );

      if (response.statusCode == 200) {
        return ProductModel.fromJson(response.data);
      } else {
        throw ServerException(
          'Failed to update product: ${response.statusCode}',
          response.statusCode ?? 500,
        );
      }
    } on DioException catch (e) {
      AppLogger.error('DioError updating product $id', error: e);
      throw NetworkException('Network error: ${e.message}');
    } catch (e) {
      AppLogger.error('Error updating product $id', error: e);
      if (e is ServerException) rethrow;
      throw NetworkException('Network error: $e');
    }
  }

  @override
  Future<void> deleteProduct(String id) async {
    try {
      final response = await dio.delete('$baseUrl/products/$id');

      if (response.statusCode != 200 && response.statusCode != 204) {
        throw ServerException(
          'Failed to delete product: ${response.statusCode}',
          response.statusCode ?? 500,
        );
      }
    } on DioException catch (e) {
      AppLogger.error('DioError deleting product $id', error: e);
      throw NetworkException('Network error: ${e.message}');
    } catch (e) {
      AppLogger.error('Error deleting product $id', error: e);
      if (e is ServerException) rethrow;
      throw NetworkException('Network error: $e');
    }
  }
}
