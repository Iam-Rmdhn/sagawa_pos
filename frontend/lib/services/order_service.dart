import '../models/order.dart';
import 'api_service.dart';

class OrderService {
  // Get all orders
  static Future<List<Order>> getAllOrders() async {
    try {
      final data = await ApiService.get('/orders');
      if (data is List) {
        return data.map((json) => Order.fromJson(json)).toList();
      }
      return [];
    } catch (e) {
      throw Exception('Failed to fetch orders: $e');
    }
  }

  // Get order by ID
  static Future<Order> getOrder(String id) async {
    try {
      final data = await ApiService.get('/orders/$id');
      return Order.fromJson(data);
    } catch (e) {
      throw Exception('Failed to fetch order: $e');
    }
  }

  // Create order
  static Future<Order> createOrder(Order order) async {
    try {
      final data = await ApiService.post('/orders', order.toJson());
      return Order.fromJson(data);
    } catch (e) {
      throw Exception('Failed to create order: $e');
    }
  }

  // Update order status
  static Future<void> updateOrderStatus(String id, String status) async {
    try {
      await ApiService.patch('/orders/$id/status', {'status': status});
    } catch (e) {
      throw Exception('Failed to update order status: $e');
    }
  }
}
