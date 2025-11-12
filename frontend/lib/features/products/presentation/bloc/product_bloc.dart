import 'package:bloc/bloc.dart';
import '../../domain/entities/product.dart';
import '../../domain/repositories/product_repository.dart';
import '../../../../core/utils/logger.dart';
import '../../../../core/data/mock_data.dart';
import '../../../../core/services/local_storage_service.dart';
import 'product_event.dart';
import 'product_state.dart';

class ProductBloc extends Bloc<ProductEvent, ProductState> {
  final ProductRepository repository;
  final bool useMockData;

  List<Product> _allProducts = [];
  String _selectedCategory = 'Semua';
  String _searchQuery = '';

  ProductBloc({required this.repository, this.useMockData = true})
    : super(ProductInitial()) {
    on<LoadProductsEvent>(_onLoadProducts);
    on<FilterProductsByCategoryEvent>(_onFilterByCategory);
    on<SearchProductsEvent>(_onSearchProducts);
    on<ClearSearchEvent>(_onClearSearch);
    on<AddProductEvent>(_onAddProduct);
    on<UpdateProductEvent>(_onUpdateProduct);
    on<DeleteProductEvent>(_onDeleteProduct);
  }

  Future<void> _onLoadProducts(
    LoadProductsEvent event,
    Emitter<ProductState> emit,
  ) async {
    emit(ProductLoading());

    // Simulate network delay
    await Future.delayed(const Duration(milliseconds: 800));

    try {
      AppLogger.info('Loading products...');

      // Try to load from local storage first
      final localProducts = await LocalStorageService.instance.getProducts();

      if (localProducts.isNotEmpty) {
        _allProducts = localProducts;
        AppLogger.info('Using LOCAL STORAGE: ${_allProducts.length} products');
      } else if (useMockData) {
        _allProducts = MockData.mockProducts;
        AppLogger.info('Using MOCK data: ${_allProducts.length} products');
      } else {
        _allProducts = await repository.getAllProducts();
        AppLogger.info('Using REAL API: ${_allProducts.length} products');
      }

      _emitLoadedState(emit);
    } catch (e) {
      AppLogger.error('Failed to load products', error: e);
      emit(ProductError(e.toString()));
    }
  }

  void _onFilterByCategory(
    FilterProductsByCategoryEvent event,
    Emitter<ProductState> emit,
  ) {
    _selectedCategory = event.category;
    _emitLoadedState(emit);
  }

  void _onSearchProducts(
    SearchProductsEvent event,
    Emitter<ProductState> emit,
  ) {
    _searchQuery = event.query;
    _emitLoadedState(emit);
  }

  void _onClearSearch(ClearSearchEvent event, Emitter<ProductState> emit) {
    _searchQuery = '';
    _emitLoadedState(emit);
  }

  void _emitLoadedState(Emitter<ProductState> emit) {
    var filtered = _allProducts.where((p) => p.isActive).toList();

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

    final categories = useMockData
        ? ['Semua', 'Best Seller', ...MockData.categories]
        : [
            'Semua',
            'Best Seller',
            ..._allProducts.map((p) => p.category).toSet().toList(),
          ];

    emit(
      ProductLoaded(
        products: _allProducts,
        filteredProducts: filtered,
        selectedCategory: _selectedCategory,
        searchQuery: _searchQuery,
        categories: categories,
      ),
    );
  }

  Future<void> _onAddProduct(
    AddProductEvent event,
    Emitter<ProductState> emit,
  ) async {
    try {
      AppLogger.info('Adding new product: ${event.product.name}');

      // Add to local storage
      await LocalStorageService.instance.addProduct(event.product);

      // Reload products
      add(LoadProductsEvent());
    } catch (e) {
      AppLogger.error('Failed to add product', error: e);
      emit(ProductError(e.toString()));
    }
  }

  Future<void> _onUpdateProduct(
    UpdateProductEvent event,
    Emitter<ProductState> emit,
  ) async {
    try {
      AppLogger.info('Updating product: ${event.product.name}');

      // Update in local storage
      await LocalStorageService.instance.updateProduct(event.product);

      // Reload products
      add(LoadProductsEvent());
    } catch (e) {
      AppLogger.error('Failed to update product', error: e);
      emit(ProductError(e.toString()));
    }
  }

  Future<void> _onDeleteProduct(
    DeleteProductEvent event,
    Emitter<ProductState> emit,
  ) async {
    try {
      AppLogger.info('Deleting product: ${event.productId}');

      // Delete from local storage
      await LocalStorageService.instance.deleteProduct(event.productId);

      // Reload products
      add(LoadProductsEvent());
    } catch (e) {
      AppLogger.error('Failed to delete product', error: e);
      emit(ProductError(e.toString()));
    }
  }
}
