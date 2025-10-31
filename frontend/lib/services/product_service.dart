import '../models/product.dart';
import 'api_service.dart';

class ProductService {
  // Get all products
  static Future<List<Product>> getAllProducts() async {
    try {
      final data = await ApiService.get('/products');
      if (data is List) {
        return data.map((json) => Product.fromJson(json)).toList();
      }
      return [];
    } catch (e) {
      throw Exception('Failed to fetch products: $e');
    }
  }

  // Get product by ID
  static Future<Product> getProduct(String id) async {
    try {
      final data = await ApiService.get('/products/$id');
      return Product.fromJson(data);
    } catch (e) {
      throw Exception('Failed to fetch product: $e');
    }
  }

  // Create product
  static Future<Product> createProduct(Product product) async {
    try {
      final data = await ApiService.post('/products', product.toJson());
      return Product.fromJson(data);
    } catch (e) {
      throw Exception('Failed to create product: $e');
    }
  }

  // Update product
  static Future<Product> updateProduct(String id, Product product) async {
    try {
      final data = await ApiService.put('/products/$id', product.toJson());
      return Product.fromJson(data);
    } catch (e) {
      throw Exception('Failed to update product: $e');
    }
  }

  // Delete product
  static Future<void> deleteProduct(String id) async {
    try {
      await ApiService.delete('/products/$id');
    } catch (e) {
      throw Exception('Failed to delete product: $e');
    }
  }
}
