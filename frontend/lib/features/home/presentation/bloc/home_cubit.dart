import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:sagawa_pos_new/features/home/data/mock/mock_products.dart';
import 'package:sagawa_pos_new/features/home/domain/models/product.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

class HomeState {
  const HomeState({
    required this.products,
    required this.cart,
    this.originalStocks = const {},
    this.originalOrder = const [],
    this.isLoading = false,
  });

  final List<Product> products;
  final List<Product> cart;
  final Map<String, int> originalStocks; // Store original stock values
  final List<String> originalOrder; // Store original product order by ID
  final bool isLoading;

  bool get isEmptyProducts => products.isEmpty;
  int get cartCount => cart.length;
  int get cartTotal => cart.fold(0, (sum, p) => sum + p.price);

  String get cartTotalLabel => 'Rp ${_formatSimple(cartTotal)}';

  /// Get sorted products: available stock first (in original order), sold out last
  List<Product> get sortedProducts {
    if (originalOrder.isEmpty) return products;

    // Separate products into available and sold out
    final available = <Product>[];
    final soldOut = <Product>[];

    for (final product in products) {
      if (product.stock > 0) {
        available.add(product);
      } else {
        soldOut.add(product);
      }
    }

    // Sort available products by original order
    available.sort((a, b) {
      final indexA = originalOrder.indexOf(a.id);
      final indexB = originalOrder.indexOf(b.id);
      return indexA.compareTo(indexB);
    });

    // Sort sold out products by original order
    soldOut.sort((a, b) {
      final indexA = originalOrder.indexOf(a.id);
      final indexB = originalOrder.indexOf(b.id);
      return indexA.compareTo(indexB);
    });

    // Combine: available first, then sold out
    return [...available, ...soldOut];
  }

  HomeState copyWith({
    List<Product>? products,
    List<Product>? cart,
    Map<String, int>? originalStocks,
    List<String>? originalOrder,
    bool? isLoading,
  }) {
    return HomeState(
      products: products ?? this.products,
      cart: cart ?? this.cart,
      originalStocks: originalStocks ?? this.originalStocks,
      originalOrder: originalOrder ?? this.originalOrder,
      isLoading: isLoading ?? this.isLoading,
    );
  }

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
  HomeCubit()
    : super(
        const HomeState(
          products: [],
          cart: [],
          originalStocks: {},
          originalOrder: [],
          isLoading: true,
        ),
      );

  Future<void> loadMockProducts() async {
    print('DEBUG HomeCubit: loadMockProducts called');
    emit(state.copyWith(isLoading: true));
    final products = await fetchMenuProducts();
    // ignore: avoid_print
    print('DEBUG HomeCubit: Loaded products count: ${products.length}');

    // Store original stock values and original order
    final originalStocks = <String, int>{};
    final originalOrder = <String>[];
    for (final p in products) {
      originalStocks[p.id] = p.stock;
      originalOrder.add(p.id);
      print(
        'DEBUG HomeCubit: Product ${p.id} - ${p.title} - stock: ${p.stock} - enabled: ${p.isEnabled}',
      );
    }

    emit(
      state.copyWith(
        products: List<Product>.from(products),
        originalStocks: originalStocks,
        originalOrder: originalOrder,
        isLoading: false,
      ),
    );
    print('DEBUG HomeCubit: State emitted with ${products.length} products');
  }

  bool addToCart(Product product) {
    // Find current product in products list
    final currentProduct = state.products.firstWhere(
      (p) => p.id == product.id,
      orElse: () => product,
    );

    // Check if stock is available
    if (currentProduct.stock <= 0) {
      print('DEBUG: No stock available. Stock: ${currentProduct.stock}');
      return false;
    }

    // Count how many of this product are already in cart
    final countInCart = state.cart.where((p) => p.id == product.id).length;

    // Get original stock (stock saat pertama kali load)
    final originalStock = state.originalStocks[product.id] ?? product.stock;

    // Check if adding one more would exceed original stock
    if (countInCart >= originalStock) {
      print(
        'DEBUG: Cannot add more - stock limit reached. In cart: $countInCart, Original stock: $originalStock',
      );
      return false;
    }

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
          kategori: p.kategori,
          isBestSeller: p.isBestSeller,
        );
      }
      return p;
    }).toList();

    emit(
      state.copyWith(
        cart: updated,
        products: updatedProducts,
        originalStocks: state.originalStocks,
      ),
    );

    // Save updated stock to local storage
    final newStock = currentProduct.stock - 1;
    _saveStockToLocalStorage(product.id, newStock);

    print(
      'DEBUG: Added to cart. In cart now: ${countInCart + 1}/${originalStock}',
    );
    return true;
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
    // Find the first item with this productId in cart
    final itemIndex = state.cart.indexWhere((p) => p.id == productId);

    if (itemIndex == -1) {
      print('DEBUG: Product $productId not found in cart');
      return;
    }

    // Remove one item from cart
    final updated = List<Product>.from(state.cart)..removeAt(itemIndex);

    // Restore stock in products list (add 1 back)
    final updatedProducts = state.products.map((p) {
      if (p.id == productId) {
        final newStock = p.stock + 1;
        print('DEBUG: Restoring stock for $productId: ${p.stock} -> $newStock');

        // Save restored stock to local storage
        _saveStockToLocalStorage(productId, newStock);

        return Product(
          id: p.id,
          title: p.title,
          price: p.price,
          imageAsset: p.imageAsset,
          stock: newStock,
          isEnabled: p.isEnabled,
          kategori: p.kategori,
          isBestSeller: p.isBestSeller,
        );
      }
      return p;
    }).toList();

    emit(
      state.copyWith(
        cart: updated,
        products: updatedProducts,
        originalStocks: state.originalStocks,
      ),
    );
  }

  void removeAllFromCart(String productId) {
    // Count how many of this product are in cart
    final countInCart = state.cart.where((p) => p.id == productId).length;

    if (countInCart == 0) {
      print('DEBUG: Product $productId not found in cart');
      return;
    }

    // Remove all items with this productId from cart
    final updated = state.cart.where((p) => p.id != productId).toList();

    // Restore all stock in products list
    final updatedProducts = state.products.map((p) {
      if (p.id == productId) {
        final newStock = p.stock + countInCart;
        print(
          'DEBUG: Restoring all stock for $productId: ${p.stock} -> $newStock (removed $countInCart items)',
        );

        // Save restored stock to local storage
        _saveStockToLocalStorage(productId, newStock);

        return Product(
          id: p.id,
          title: p.title,
          price: p.price,
          imageAsset: p.imageAsset,
          stock: newStock,
          isEnabled: p.isEnabled,
          kategori: p.kategori,
          isBestSeller: p.isBestSeller,
        );
      }
      return p;
    }).toList();

    emit(
      state.copyWith(
        cart: updated,
        products: updatedProducts,
        originalStocks: state.originalStocks,
      ),
    );
  }

  void clearCart() {
    // Count items per product in cart
    final itemCounts = <String, int>{};
    for (final item in state.cart) {
      itemCounts[item.id] = (itemCounts[item.id] ?? 0) + 1;
    }

    // Restore stock for all products
    final updatedProducts = state.products.map((p) {
      final countInCart = itemCounts[p.id] ?? 0;
      if (countInCart > 0) {
        final newStock = p.stock + countInCart;
        print(
          'DEBUG: Clearing cart - restoring stock for ${p.id}: ${p.stock} -> $newStock',
        );

        // Save restored stock to local storage
        _saveStockToLocalStorage(p.id, newStock);

        return Product(
          id: p.id,
          title: p.title,
          price: p.price,
          imageAsset: p.imageAsset,
          stock: newStock,
          isEnabled: p.isEnabled,
          kategori: p.kategori,
          isBestSeller: p.isBestSeller,
        );
      }
      return p;
    }).toList();

    emit(
      state.copyWith(
        cart: [],
        products: updatedProducts,
        originalStocks: state.originalStocks,
      ),
    );
  }

  /// Clear cart after successful checkout WITHOUT restoring stock
  /// This should be called after payment is successful
  void clearCartAfterCheckout() {
    print('DEBUG: Clearing cart after checkout - keeping reduced stock');

    // Update originalStocks to reflect the new stock values (after purchase)
    final newOriginalStocks = <String, int>{};
    for (final p in state.products) {
      newOriginalStocks[p.id] = p.stock;
      print('DEBUG: Updated original stock for ${p.id}: ${p.stock}');
    }

    emit(state.copyWith(cart: [], originalStocks: newOriginalStocks));
  }
}
