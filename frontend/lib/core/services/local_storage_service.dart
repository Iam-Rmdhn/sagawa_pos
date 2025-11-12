import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../../features/products/domain/entities/product.dart';

class LocalStorageService {
  static const String _productsKey = 'products_data';

  static LocalStorageService? _instance;
  static SharedPreferences? _prefs;

  LocalStorageService._();

  static LocalStorageService get instance {
    _instance ??= LocalStorageService._();
    return _instance!;
  }

  static Future<void> initialize() async {
    _prefs = await SharedPreferences.getInstance();
  }

  SharedPreferences get prefs {
    if (_prefs == null) {
      throw Exception('LocalStorage not initialized. Call initialize() first.');
    }
    return _prefs!;
  }

  /// Save products to local storage
  Future<void> saveProducts(List<Product> products) async {
    try {
      final jsonList = products.map((p) => p.toJson()).toList();
      final jsonString = jsonEncode(jsonList);
      await prefs.setString(_productsKey, jsonString);
      print('✅ Saved ${products.length} products to local storage');
    } catch (e) {
      print('❌ Error saving products: $e');
      throw Exception('Failed to save products: $e');
    }
  }

  /// Get products from local storage
  List<Product> getProducts() {
    try {
      final jsonString = prefs.getString(_productsKey);
      if (jsonString == null || jsonString.isEmpty) {
        print('ℹ️ No products in local storage');
        return [];
      }

      final List<dynamic> jsonList = jsonDecode(jsonString);
      final products = jsonList.map((json) => Product.fromJson(json)).toList();
      print('✅ Loaded ${products.length} products from local storage');
      return products;
    } catch (e) {
      print('❌ Error loading products: $e');
      return [];
    }
  }

  /// Add a single product
  Future<void> addProduct(Product product) async {
    final products = getProducts();
    products.add(product);
    await saveProducts(products);
    print('✅ Added product: ${product.name}');
  }

  /// Update a product
  Future<void> updateProduct(Product updatedProduct) async {
    final products = getProducts();
    final index = products.indexWhere((p) => p.id == updatedProduct.id);

    if (index != -1) {
      products[index] = updatedProduct;
      await saveProducts(products);
      print('✅ Updated product: ${updatedProduct.name}');
    } else {
      throw Exception('Product not found: ${updatedProduct.id}');
    }
  }

  /// Delete a product
  Future<void> deleteProduct(String productId) async {
    try {
      final products = getProducts();
      final initialCount = products.length;
      products.removeWhere((p) => p.id == productId);

      if (products.length < initialCount) {
        await saveProducts(products);
        print('✅ Deleted product: $productId');
      } else {
        print('⚠️ Product not found: $productId');
      }
    } catch (e) {
      print('❌ Error deleting product: $e');
      throw Exception('Failed to delete product: $e');
    }
  }

  /// Clear all products
  Future<void> clearProducts() async {
    await prefs.remove(_productsKey);
    print('✅ Cleared all products');
  }

  /// Check if products exist
  bool hasProducts() {
    final jsonString = prefs.getString(_productsKey);
    return jsonString != null && jsonString.isNotEmpty;
  }
}
