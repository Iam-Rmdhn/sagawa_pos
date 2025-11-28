import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:sagawa_pos_new/features/home/data/mock/mock_products.dart';
import 'package:sagawa_pos_new/features/home/domain/models/product.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

class HomeState {
  const HomeState({required this.products, required this.cart});

  final List<Product> products;
  final List<Product> cart;

  bool get isEmptyProducts => products.isEmpty;
  int get cartCount => cart.length;
  int get cartTotal => cart.fold(0, (sum, p) => sum + p.price);

  String get cartTotalLabel => 'Rp ${_formatSimple(cartTotal)}';

  HomeState copyWith({List<Product>? products, List<Product>? cart}) =>
      HomeState(products: products ?? this.products, cart: cart ?? this.cart);

  static String _formatSimple(int value) {
    final s = value.toString();
    final buffer = StringBuffer();
    for (int i = 0; i < s.length; i++) {
      buffer.write(s[i]);
      final remaining = s.length - i - 1;
      if (remaining > 0 && remaining % 3 == 0) buffer.write('.');
    }
    return buffer.toString();
  }
}

class HomeCubit extends Cubit<HomeState> {
  HomeCubit() : super(const HomeState(products: [], cart: []));

  Future<void> loadMockProducts() async {
    print('DEBUG HomeCubit: loadMockProducts called');
    final products = await fetchMenuProducts();
    // ignore: avoid_print
    print('DEBUG HomeCubit: Loaded products count: ${products.length}');
    for (final p in products) {
      print(
        'DEBUG HomeCubit: Product ${p.id} - ${p.title} - stock: ${p.stock} - enabled: ${p.isEnabled}',
      );
    }
    emit(state.copyWith(products: List<Product>.from(products)));
    print('DEBUG HomeCubit: State emitted with ${products.length} products');
  }

  void addToCart(Product product) {
    // Check if stock is available
    if (product.stock <= 0) return;

    // Add to cart
    final updated = List<Product>.from(state.cart)..add(product);

    // Reduce stock in products list
    final updatedProducts = state.products.map((p) {
      if (p.id == product.id) {
        return Product(
          id: p.id,
          title: p.title,
          price: p.price,
          imageAsset: p.imageAsset,
          stock: p.stock - 1,
          isEnabled: p.isEnabled,
        );
      }
      return p;
    }).toList();

    emit(state.copyWith(cart: updated, products: updatedProducts));

    // Save updated stock to local storage
    _saveStockToLocalStorage(product.id, product.stock - 1);
  }

  Future<void> _saveStockToLocalStorage(String productId, int newStock) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final stateJson = prefs.getString('menu_state');
      Map<String, dynamic> menuState = {};

      if (stateJson != null) {
        menuState = json.decode(stateJson) as Map<String, dynamic>;
      }

      if (menuState[productId] != null) {
        menuState[productId]['stock'] = newStock;
      } else {
        menuState[productId] = {'stock': newStock, 'isEnabled': true};
      }

      await prefs.setString('menu_state', json.encode(menuState));
      print('DEBUG: Stock saved for $productId: $newStock');
    } catch (e) {
      print('Error saving stock: $e');
    }
  }

  void removeFromCart(String productId) {
    final updated = state.cart.where((p) => p.id != productId).toList();
    emit(state.copyWith(cart: updated));
  }

  void clearCart() {
    emit(state.copyWith(cart: []));
  }
}
