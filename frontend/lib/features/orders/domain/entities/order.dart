import '../../../cart/domain/entities/cart_item.dart';

class Order {
  final String id;
  final String orderNumber;
  final String customerId;
  final List<CartItem> items;
  final double totalAmount;
  final String status;
  final String paymentMethod;
  final DateTime createdAt;
  final DateTime updatedAt;

  Order({
    required this.id,
    required this.orderNumber,
    required this.customerId,
    required this.items,
    required this.totalAmount,
    required this.status,
    required this.paymentMethod,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Order.fromJson(Map<String, dynamic> json) {
    return Order(
      id: json['id'],
      orderNumber: json['order_number'],
      customerId: json['customer_id'],
      items:
          (json['items'] as List?)
              ?.map(
                (item) => CartItem(
                  productId: item['product_id'],
                  name: item['name'],
                  quantity: item['quantity'],
                  price: (item['price'] as num).toDouble(),
                  subtotal: (item['subtotal'] as num).toDouble(),
                ),
              )
              .toList() ??
          [],
      totalAmount: (json['total_amount'] as num).toDouble(),
      status: json['status'],
      paymentMethod: json['payment_method'],
      createdAt: DateTime.parse(json['created_at']),
      updatedAt: DateTime.parse(json['updated_at']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'order_number': orderNumber,
      'customer_id': customerId,
      'items': items.map((item) => item.toJson()).toList(),
      'total_amount': totalAmount,
      'status': status,
      'payment_method': paymentMethod,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }
}
