import '../../../../core/errors/exceptions.dart';
import '../../../../core/errors/failures.dart';
import '../../domain/entities/order.dart';
import '../../domain/repositories/order_repository.dart';
import '../datasources/order_remote_data_source.dart';
import '../models/order_model.dart';

class OrderRepositoryImpl implements OrderRepository {
  final OrderRemoteDataSource remoteDataSource;

  OrderRepositoryImpl({required this.remoteDataSource});

  @override
  Future<List<Order>> getAllOrders() async {
    try {
      final orders = await remoteDataSource.getAllOrders();
      return orders;
    } on ServerException catch (e) {
      throw ServerFailure(e.message);
    } on NetworkException catch (e) {
      throw NetworkFailure(e.message);
    }
  }

  @override
  Future<Order> getOrderById(String id) async {
    try {
      final order = await remoteDataSource.getOrderById(id);
      return order;
    } on ServerException catch (e) {
      throw ServerFailure(e.message);
    } on NetworkException catch (e) {
      throw NetworkFailure(e.message);
    }
  }

  @override
  Future<Order> createOrder(Order order) async {
    try {
      final orderModel = OrderModel.fromEntity(order);
      final createdOrder = await remoteDataSource.createOrder(orderModel);
      return createdOrder;
    } on ServerException catch (e) {
      throw ServerFailure(e.message);
    } on NetworkException catch (e) {
      throw NetworkFailure(e.message);
    }
  }

  @override
  Future<void> updateOrderStatus(String id, String status) async {
    try {
      await remoteDataSource.updateOrderStatus(id, status);
    } on ServerException catch (e) {
      throw ServerFailure(e.message);
    } on NetworkException catch (e) {
      throw NetworkFailure(e.message);
    }
  }
}
