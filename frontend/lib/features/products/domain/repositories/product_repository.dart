import '../entities/product.dart';

abstract class ProductRepository {
  Future<List<Product>> getAllProducts();
  Future<Product> getProductById(String id);
  Future<Product> createProduct(Product product);
  Future<Product> updateProduct(String id, Product product);
  Future<void> deleteProduct(String id);
  Future<List<Product>> getProductsByCategory(String category);
}
