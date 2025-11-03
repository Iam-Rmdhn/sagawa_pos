import '../../domain/entities/product.dart';

// Product State
abstract class ProductState {}

class ProductInitial extends ProductState {}

class ProductLoading extends ProductState {}

class ProductLoaded extends ProductState {
  final List<Product> products;
  final List<Product> filteredProducts;
  final String selectedCategory;
  final String searchQuery;
  final List<String> categories;

  ProductLoaded({
    required this.products,
    required this.filteredProducts,
    required this.selectedCategory,
    required this.searchQuery,
    required this.categories,
  });
}

class ProductError extends ProductState {
  final String message;

  ProductError(this.message);
}
