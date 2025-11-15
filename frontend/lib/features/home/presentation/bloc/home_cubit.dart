import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:sagawa_pos_new/features/home/data/mock/mock_products.dart';
import 'package:sagawa_pos_new/features/home/domain/models/product.dart';

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

  void loadMockProducts() {
    emit(state.copyWith(products: List<Product>.from(mockProducts)));
  }

  void addToCart(Product product) {
    final updated = List<Product>.from(state.cart)..add(product);
    emit(state.copyWith(cart: updated));
  }

  void removeFromCart(String productId) {
    final updated = state.cart.where((p) => p.id != productId).toList();
    emit(state.copyWith(cart: updated));
  }

  void clearCart() {
    emit(state.copyWith(cart: []));
  }
}
