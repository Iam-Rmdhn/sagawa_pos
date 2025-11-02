import '../../domain/entities/cart_item.dart';

// Cart State
abstract class CartState {}

class CartInitial extends CartState {}

class CartLoaded extends CartState {
  final Map<String, CartItem> items;
  final double totalAmount;
  final int itemCount;

  CartLoaded({
    required this.items,
    required this.totalAmount,
    required this.itemCount,
  });

  List<CartItem> get cartItems => items.values.toList();
}
