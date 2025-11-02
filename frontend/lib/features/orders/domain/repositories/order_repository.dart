import '../entities/order.dart';

abstract class OrderRepository {
  Future<List<Order>> getAllOrders();
  Future<Order> getOrderById(String id);
  Future<Order> createOrder(Order order);
  Future<void> updateOrderStatus(String id, String status);
}
