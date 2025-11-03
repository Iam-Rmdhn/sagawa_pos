import '../../domain/entities/order.dart';
import '../../../cart/domain/entities/cart_item.dart';

class OrderModel extends Order {
  OrderModel({
    required super.id,
    required super.orderNumber,
    required super.customerId,
    required super.items,
    required super.totalAmount,
    required super.status,
    required super.paymentMethod,
    required super.createdAt,
    required super.updatedAt,
  });

  factory OrderModel.fromJson(Map<String, dynamic> json) {
    return OrderModel(
      id: json['id'],
      orderNumber: json['order_number'],
      customerId: json['customer_id'],
      items:
          (json['items'] as List?)?.map((item) {
            return CartItem(
              productId: item['product_id'],
              name: item['name'],
              quantity: item['quantity'],
              price: (item['price'] as num).toDouble(),
              subtotal: (item['subtotal'] as num).toDouble(),
            );
          }).toList() ??
          [],
      totalAmount: (json['total_amount'] as num).toDouble(),
      status: json['status'],
      paymentMethod: json['payment_method'],
      createdAt: DateTime.parse(json['created_at']),
      updatedAt: DateTime.parse(json['updated_at']),
    );
  }

  factory OrderModel.fromEntity(Order order) {
    return OrderModel(
      id: order.id,
      orderNumber: order.orderNumber,
      customerId: order.customerId,
      items: order.items,
      totalAmount: order.totalAmount,
      status: order.status,
      paymentMethod: order.paymentMethod,
      createdAt: order.createdAt,
      updatedAt: order.updatedAt,
    );
  }
}
