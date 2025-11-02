import '../../domain/entities/product.dart';

// Product Events
abstract class ProductEvent {}

class LoadProductsEvent extends ProductEvent {}

class FilterProductsByCategoryEvent extends ProductEvent {
  final String category;

  FilterProductsByCategoryEvent(this.category);
}

class SearchProductsEvent extends ProductEvent {
  final String query;

  SearchProductsEvent(this.query);
}

class ClearSearchEvent extends ProductEvent {}

class AddProductEvent extends ProductEvent {
  final Product product;

  AddProductEvent(this.product);
}

class UpdateProductEvent extends ProductEvent {
  final Product product;

  UpdateProductEvent(this.product);
}

class DeleteProductEvent extends ProductEvent {
  final String productId;

  DeleteProductEvent(this.productId);
}
