import 'package:dio/dio.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import '../../../../core/errors/exceptions.dart';
import '../../../../core/utils/logger.dart';
import '../models/order_model.dart';

abstract class OrderRemoteDataSource {
  Future<List<OrderModel>> getAllOrders();
  Future<OrderModel> getOrderById(String id);
  Future<OrderModel> createOrder(OrderModel order);
  Future<void> updateOrderStatus(String id, String status);
}

class OrderRemoteDataSourceImpl implements OrderRemoteDataSource {
  final Dio dio;
  final String baseUrl;

  OrderRemoteDataSourceImpl({required this.dio, String? baseUrl})
    : baseUrl =
          baseUrl ??
          dotenv.env['API_BASE_URL'] ??
          'http://localhost:8080/api/v1';

  @override
  Future<List<OrderModel>> getAllOrders() async {
    try {
      AppLogger.info('Fetching all orders from $baseUrl/orders');

      final response = await dio.get('$baseUrl/orders');

      if (response.statusCode == 200) {
        final List<dynamic> data = response.data;
        return data.map((json) => OrderModel.fromJson(json)).toList();
      } else {
        throw ServerException(
          'Failed to load orders: ${response.statusCode}',
          response.statusCode ?? 500,
        );
      }
    } on DioException catch (e) {
      AppLogger.error('DioError fetching orders', error: e);
      throw NetworkException('Network error: ${e.message}');
    } catch (e) {
      AppLogger.error('Error fetching orders', error: e);
      if (e is ServerException) rethrow;
      throw NetworkException('Network error: $e');
    }
  }

  @override
  Future<OrderModel> getOrderById(String id) async {
    try {
      final response = await dio.get('$baseUrl/orders/$id');

      if (response.statusCode == 200) {
        return OrderModel.fromJson(response.data);
      } else if (response.statusCode == 404) {
        throw ServerException('Order not found', 404);
      } else {
        throw ServerException(
          'Failed to load order: ${response.statusCode}',
          response.statusCode ?? 500,
        );
      }
    } on DioException catch (e) {
      AppLogger.error('DioError fetching order $id', error: e);
      if (e.response?.statusCode == 404) {
        throw ServerException('Order not found', 404);
      }
      throw NetworkException('Network error: ${e.message}');
    } catch (e) {
      AppLogger.error('Error fetching order $id', error: e);
      if (e is ServerException) rethrow;
      throw NetworkException('Network error: $e');
    }
  }

  @override
  Future<OrderModel> createOrder(OrderModel order) async {
    try {
      AppLogger.info('Creating order: ${order.toJson()}');

      final response = await dio.post('$baseUrl/orders', data: order.toJson());

      if (response.statusCode == 200 || response.statusCode == 201) {
        return OrderModel.fromJson(response.data);
      } else {
        throw ServerException(
          'Failed to create order: ${response.statusCode}',
          response.statusCode ?? 500,
        );
      }
    } on DioException catch (e) {
      AppLogger.error('DioError creating order', error: e);
      throw NetworkException('Network error: ${e.message}');
    } catch (e) {
      AppLogger.error('Error creating order', error: e);
      if (e is ServerException) rethrow;
      throw NetworkException('Network error: $e');
    }
  }

  @override
  Future<void> updateOrderStatus(String id, String status) async {
    try {
      final response = await dio.patch(
        '$baseUrl/orders/$id/status',
        data: {'status': status},
      );

      if (response.statusCode != 200 && response.statusCode != 204) {
        throw ServerException(
          'Failed to update order status: ${response.statusCode}',
          response.statusCode ?? 500,
        );
      }
    } on DioException catch (e) {
      AppLogger.error('DioError updating order status $id', error: e);
      throw NetworkException('Network error: ${e.message}');
    } catch (e) {
      AppLogger.error('Error updating order status $id', error: e);
      if (e is ServerException) rethrow;
      throw NetworkException('Network error: $e');
    }
  }
}
