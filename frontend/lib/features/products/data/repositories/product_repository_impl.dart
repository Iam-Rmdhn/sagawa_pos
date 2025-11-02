import '../../../../core/errors/exceptions.dart';
import '../../../../core/errors/failures.dart';
import '../../domain/entities/product.dart';
import '../../domain/repositories/product_repository.dart';
import '../datasources/product_remote_data_source.dart';
import '../models/product_model.dart';

class ProductRepositoryImpl implements ProductRepository {
  final ProductRemoteDataSource remoteDataSource;

  ProductRepositoryImpl({required this.remoteDataSource});

  @override
  Future<List<Product>> getAllProducts() async {
    try {
      final products = await remoteDataSource.getAllProducts();
      return products;
    } on ServerException catch (e) {
      throw ServerFailure(e.message);
    } on NetworkException catch (e) {
      throw NetworkFailure(e.message);
    }
  }

  @override
  Future<Product> getProductById(String id) async {
    try {
      final product = await remoteDataSource.getProductById(id);
      return product;
    } on ServerException catch (e) {
      throw ServerFailure(e.message);
    } on NetworkException catch (e) {
      throw NetworkFailure(e.message);
    }
  }

  @override
  Future<Product> createProduct(Product product) async {
    try {
      final productModel = ProductModel.fromEntity(product);
      final createdProduct = await remoteDataSource.createProduct(productModel);
      return createdProduct;
    } on ServerException catch (e) {
      throw ServerFailure(e.message);
    } on NetworkException catch (e) {
      throw NetworkFailure(e.message);
    }
  }

  @override
  Future<Product> updateProduct(String id, Product product) async {
    try {
      final productModel = ProductModel.fromEntity(product);
      final updatedProduct = await remoteDataSource.updateProduct(
        id,
        productModel,
      );
      return updatedProduct;
    } on ServerException catch (e) {
      throw ServerFailure(e.message);
    } on NetworkException catch (e) {
      throw NetworkFailure(e.message);
    }
  }

  @override
  Future<void> deleteProduct(String id) async {
    try {
      await remoteDataSource.deleteProduct(id);
    } on ServerException catch (e) {
      throw ServerFailure(e.message);
    } on NetworkException catch (e) {
      throw NetworkFailure(e.message);
    }
  }

  @override
  Future<List<Product>> getProductsByCategory(String category) async {
    try {
      final products = await remoteDataSource.getAllProducts();
      return products.where((product) => product.category == category).toList();
    } on ServerException catch (e) {
      throw ServerFailure(e.message);
    } on NetworkException catch (e) {
      throw NetworkFailure(e.message);
    }
  }
}
