import 'package:flutter/material.dart';
import '../models/product.dart';
import '../models/order.dart';

class CartProvider with ChangeNotifier {
  final Map<String, OrderItem> _items = {};

  Map<String, OrderItem> get items => {..._items};

  int get itemCount => _items.length;

  double get totalAmount {
    var total = 0.0;
    _items.forEach((key, item) {
      total += item.subtotal;
    });
    return total;
  }

  void addItem(Product product, int quantity) {
    if (_items.containsKey(product.id)) {
      // Update existing item
      final existingItem = _items[product.id]!;
      _items[product.id] = OrderItem(
        productId: existingItem.productId,
        name: existingItem.name,
        quantity: existingItem.quantity + quantity,
        price: existingItem.price,
        subtotal: (existingItem.quantity + quantity) * existingItem.price,
      );
    } else {
      // Add new item
      _items[product.id] = OrderItem(
        productId: product.id,
        name: product.name,
        quantity: quantity,
        price: product.price,
        subtotal: quantity * product.price,
      );
    }
    notifyListeners();
  }

  void removeItem(String productId) {
    _items.remove(productId);
    notifyListeners();
  }

  void updateQuantity(String productId, int quantity) {
    if (_items.containsKey(productId)) {
      if (quantity <= 0) {
        removeItem(productId);
      } else {
        final item = _items[productId]!;
        _items[productId] = OrderItem(
          productId: item.productId,
          name: item.name,
          quantity: quantity,
          price: item.price,
          subtotal: quantity * item.price,
        );
        notifyListeners();
      }
    }
  }

  void clear() {
    _items.clear();
    notifyListeners();
  }

  List<OrderItem> getOrderItems() {
    return _items.values.toList();
  }
}
