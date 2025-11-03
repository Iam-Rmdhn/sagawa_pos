import 'package:flutter/foundation.dart';
import '../../../../core/utils/logger.dart';
import '../../domain/entities/order.dart';
import '../../domain/repositories/order_repository.dart';
import '../../../cart/domain/entities/cart_item.dart';

class OrderProvider with ChangeNotifier {
  final OrderRepository repository;

  OrderProvider({required this.repository});

  List<Order> _orders = [];
  List<Order> get orders => _orders;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  bool _isProcessing = false;
  bool get isProcessing => _isProcessing;

  String? _errorMessage;
  String? get errorMessage => _errorMessage;

  Future<void> loadOrders() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      AppLogger.info('Loading orders...');
      _orders = await repository.getAllOrders();
      _isLoading = false;
      notifyListeners();
      AppLogger.info('Orders loaded: ${_orders.length}');
    } catch (e) {
      _errorMessage = e.toString();
      _isLoading = false;
      notifyListeners();
      AppLogger.error('Failed to load orders', error: e);
    }
  }

  Future<void> createOrder({
    required List<CartItem> items,
    required String paymentMethod,
  }) async {
    _isProcessing = true;
    notifyListeners();

    try {
      AppLogger.info('Creating order with ${items.length} items');

      final order = Order(
        id: '',
        orderNumber: '',
        customerId: '00000000-0000-0000-0000-000000000000', // Default customer
        items: items,
        totalAmount: items.fold(0.0, (sum, item) => sum + item.subtotal),
        status: 'pending',
        paymentMethod: paymentMethod,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      final createdOrder = await repository.createOrder(order);
      _orders.insert(0, createdOrder);
      _isProcessing = false;
      notifyListeners();
      AppLogger.info('Order created successfully: ${createdOrder.orderNumber}');
    } catch (e) {
      _isProcessing = false;
      notifyListeners();
      AppLogger.error('Failed to create order', error: e);
      rethrow;
    }
  }

  Future<void> updateOrderStatus(String id, String status) async {
    try {
      AppLogger.info('Updating order status: $id to $status');
      await repository.updateOrderStatus(id, status);

      final index = _orders.indexWhere((o) => o.id == id);
      if (index != -1) {
        // Note: This is a simplified update. In a real app, you might want to fetch the full order again
        notifyListeners();
      }
      AppLogger.info('Order status updated successfully');
    } catch (e) {
      AppLogger.error('Failed to update order status', error: e);
      rethrow;
    }
  }
}
