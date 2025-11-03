import 'package:dio/dio.dart';
import '../../features/products/data/datasources/product_remote_data_source.dart';
import '../../features/products/data/repositories/product_repository_impl.dart';
import '../../features/products/presentation/bloc/product_bloc.dart';
import '../../features/orders/data/datasources/order_remote_data_source.dart';
import '../../features/orders/data/repositories/order_repository_impl.dart';
import '../../features/orders/presentation/providers/order_provider.dart';
import '../../features/cart/presentation/bloc/cart_bloc.dart';
import '../constants/app_constants.dart';

class DependencyInjection {
  static late Dio dio;

  // Product
  static late ProductRemoteDataSourceImpl productRemoteDataSource;
  static late ProductRepositoryImpl productRepository;
  static late ProductBloc productBloc;

  // Order
  static late OrderRemoteDataSourceImpl orderRemoteDataSource;
  static late OrderRepositoryImpl orderRepository;
  static late OrderProvider orderProvider;

  // Cart
  static late CartBloc cartBloc;

  static void init() {
    // Dio Client
    dio = Dio(
      BaseOptions(
        connectTimeout: Duration(milliseconds: AppConstants.connectTimeout),
        receiveTimeout: Duration(milliseconds: AppConstants.receiveTimeout),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      ),
    );

    // Product
    productRemoteDataSource = ProductRemoteDataSourceImpl(dio: dio);
    productRepository = ProductRepositoryImpl(
      remoteDataSource: productRemoteDataSource,
    );
    productBloc = ProductBloc(
      repository: productRepository,
      useMockData: true, // Set false ketika database sudah siap
    );

    // Order
    orderRemoteDataSource = OrderRemoteDataSourceImpl(dio: dio);
    orderRepository = OrderRepositoryImpl(
      remoteDataSource: orderRemoteDataSource,
    );
    orderProvider = OrderProvider(repository: orderRepository);

    // Cart
    cartBloc = CartBloc();
  }

  static void dispose() {
    productBloc.close();
    cartBloc.close();
  }
}
