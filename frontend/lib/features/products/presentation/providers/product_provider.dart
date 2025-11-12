import 'package:flutter/foundation.dart';
import '../../domain/entities/product.dart';
import '../../domain/repositories/product_repository.dart';
import '../../../../core/utils/logger.dart';
import '../../../../core/data/mock_data.dart';

class ProductProvider with ChangeNotifier {
  final ProductRepository repository;
  final bool useMockData;

  ProductProvider({
    required this.repository,
    this.useMockData = true, // Set true untuk development UI/UX
  });

  List<Product> _products = [];
  List<Product> get products => _products;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  String? _errorMessage;
  String? get errorMessage => _errorMessage;

  String _selectedCategory = 'Semua';
  String get selectedCategory => _selectedCategory;

  String _searchQuery = '';
  String get searchQuery => _searchQuery;

  List<String> get categories {
    if (useMockData) {
      return ['Semua', 'Best Seller', ...MockData.categories];
    }
    final cats = _products.map((p) => p.category).toSet().toList();
    return ['Semua', 'Best Seller', ...cats];
  }

  List<Product> get filteredProducts {
    var filtered = _products.where((p) => p.isActive).toList();

    // Filter by category
    if (_selectedCategory == 'Best Seller') {
      // Filter for best seller products only
      filtered = filtered.where((p) => p.isBestSeller).toList();
    } else if (_selectedCategory != 'Semua') {
      filtered = filtered
          .where((p) => p.category == _selectedCategory)
          .toList();
    }

    // Filter by search query
    if (_searchQuery.isNotEmpty) {
      filtered = filtered.where((p) {
        return p.name.toLowerCase().contains(_searchQuery.toLowerCase()) ||
            p.description.toLowerCase().contains(_searchQuery.toLowerCase());
      }).toList();
    }

    return filtered;
  }

  void setCategory(String category) {
    _selectedCategory = category;
    notifyListeners();
  }

  void setSearchQuery(String query) {
    _searchQuery = query;
    notifyListeners();
  }

  void clearSearch() {
    _searchQuery = '';
    notifyListeners();
  }

  Future<void> loadProducts() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    // Simulate network delay untuk realisticnya UI
    await Future.delayed(const Duration(milliseconds: 800));

    try {
      AppLogger.info('Loading products...');

      if (useMockData) {
        // Gunakan mock data untuk development UI/UX
        _products = MockData.mockProducts;
        AppLogger.info('Using MOCK data: ${_products.length} products');
      } else {
        // Gunakan real API (ketika database sudah siap)
        _products = await repository.getAllProducts();
        AppLogger.info('Using REAL API: ${_products.length} products');
      }

      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _errorMessage = e.toString();
      _isLoading = false;
      notifyListeners();
      AppLogger.error('Failed to load products', error: e);
    }
  }

  Future<void> createProduct(Product product) async {
    try {
      AppLogger.info('Creating product: ${product.name}');
      final createdProduct = await repository.createProduct(product);
      _products.add(createdProduct);
      notifyListeners();
      AppLogger.info('Product created successfully');
    } catch (e) {
      AppLogger.error('Failed to create product', error: e);
      rethrow;
    }
  }

  Future<void> updateProduct(String id, Product product) async {
    try {
      AppLogger.info('Updating product: $id');
      final updatedProduct = await repository.updateProduct(id, product);
      final index = _products.indexWhere((p) => p.id == id);
      if (index != -1) {
        _products[index] = updatedProduct;
        notifyListeners();
      }
      AppLogger.info('Product updated successfully');
    } catch (e) {
      AppLogger.error('Failed to update product', error: e);
      rethrow;
    }
  }

  Future<void> deleteProduct(String id) async {
    try {
      AppLogger.info('Deleting product: $id');
      await repository.deleteProduct(id);
      _products.removeWhere((p) => p.id == id);
      notifyListeners();
      AppLogger.info('Product deleted successfully');
    } catch (e) {
      AppLogger.error('Failed to delete product', error: e);
      rethrow;
    }
  }
}
