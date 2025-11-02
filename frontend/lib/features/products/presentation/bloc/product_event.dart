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
