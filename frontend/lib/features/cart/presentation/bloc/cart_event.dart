import '../../../cart/domain/entities/cart_item.dart';

// Cart Events
abstract class CartEvent {}

class AddToCartEvent extends CartEvent {
  final String productId;
  final String name;
  final int quantity;
  final double price;

  AddToCartEvent({
    required this.productId,
    required this.name,
    required this.quantity,
    required this.price,
  });
}

class UpdateCartQuantityEvent extends CartEvent {
  final String productId;
  final int quantity;

  UpdateCartQuantityEvent({required this.productId, required this.quantity});
}

class RemoveFromCartEvent extends CartEvent {
  final String productId;

  RemoveFromCartEvent(this.productId);
}

class ClearCartEvent extends CartEvent {}
