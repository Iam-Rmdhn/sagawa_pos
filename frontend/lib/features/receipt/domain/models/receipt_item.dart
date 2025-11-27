class ReceiptItem {
  final String name;
  final int quantity;
  final double price;
  final double subtotal;

  ReceiptItem({
    required this.name,
    required this.quantity,
    required this.price,
    required this.subtotal,
  });

  factory ReceiptItem.fromJson(Map<String, dynamic> json) {
    return ReceiptItem(
      name: json['name'] as String,
      quantity: json['quantity'] as int,
      price: (json['price'] as num).toDouble(),
      subtotal: (json['subtotal'] as num).toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'quantity': quantity,
      'price': price,
      'subtotal': subtotal,
    };
  }
}
