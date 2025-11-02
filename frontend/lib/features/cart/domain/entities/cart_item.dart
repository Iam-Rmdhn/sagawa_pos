import '../../../products/domain/entities/product.dart';

class CartItem {
  final String productId;
  final String name;
  final int quantity;
  final double price;
  final double subtotal;

  CartItem({
    required this.productId,
    required this.name,
    required this.quantity,
    required this.price,
    required this.subtotal,
  });

  factory CartItem.fromProduct(Product product, int quantity) {
    return CartItem(
      productId: product.id,
      name: product.name,
      quantity: quantity,
      price: product.price,
      subtotal: product.price * quantity,
    );
  }

  CartItem copyWith({
    String? productId,
    String? name,
    int? quantity,
    double? price,
    double? subtotal,
  }) {
    return CartItem(
      productId: productId ?? this.productId,
      name: name ?? this.name,
      quantity: quantity ?? this.quantity,
      price: price ?? this.price,
      subtotal: subtotal ?? this.subtotal,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'product_id': productId,
      'name': name,
      'quantity': quantity,
      'price': price,
      'subtotal': subtotal,
    };
  }
}
