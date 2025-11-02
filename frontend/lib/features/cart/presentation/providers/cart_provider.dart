import 'package:flutter/foundation.dart';
import '../../domain/entities/cart_item.dart';
import '../../../products/domain/entities/product.dart';
import '../../../../core/utils/logger.dart';

class CartProvider with ChangeNotifier {
  final Map<String, CartItem> _items = {};

  Map<String, CartItem> get items => {..._items};

  int get itemCount => _items.length;

  double get totalAmount {
    var total = 0.0;
    _items.forEach((key, item) {
      total += item.subtotal;
    });
    return total;
  }

  List<CartItem> get cartItems => _items.values.toList();

  void addItem(Product product, int quantity) {
    if (_items.containsKey(product.id)) {
      // Update existing item
      final existingItem = _items[product.id]!;
      _items[product.id] = existingItem.copyWith(
        quantity: existingItem.quantity + quantity,
        subtotal: (existingItem.quantity + quantity) * existingItem.price,
      );
      AppLogger.info(
        'Updated cart item: ${product.name}, quantity: ${existingItem.quantity + quantity}',
      );
    } else {
      // Add new item
      _items[product.id] = CartItem.fromProduct(product, quantity);
      AppLogger.info('Added to cart: ${product.name}, quantity: $quantity');
    }
    notifyListeners();
  }

  void removeItem(String productId) {
    _items.remove(productId);
    AppLogger.info('Removed from cart: $productId');
    notifyListeners();
  }

  void updateQuantity(String productId, int quantity) {
    if (_items.containsKey(productId)) {
      if (quantity <= 0) {
        removeItem(productId);
      } else {
        final item = _items[productId]!;
        _items[productId] = item.copyWith(
          quantity: quantity,
          subtotal: quantity * item.price,
        );
        AppLogger.info(
          'Updated cart quantity: $productId, new quantity: $quantity',
        );
        notifyListeners();
      }
    }
  }

  void clear() {
    _items.clear();
    AppLogger.info('Cart cleared');
    notifyListeners();
  }

  bool hasItem(String productId) {
    return _items.containsKey(productId);
  }

  CartItem? getItem(String productId) {
    return _items[productId];
  }
}
