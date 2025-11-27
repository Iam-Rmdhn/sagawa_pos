import 'package:sagawa_pos_new/features/receipt/domain/models/receipt_item.dart';

class Receipt {
  final String storeName;
  final String address;
  final String type; // "Dine In" or "Take Away"
  final String trxId;
  final String cashier;
  final String customerName;
  final List<ReceiptItem> items;
  final double subTotal;
  final double tax;
  final double afterTax;
  final double cash;
  final double change;
  final DateTime date;
  final String? logoPath;
  final String paymentMethod; // "Cash" or "QRIS"

  Receipt({
    required this.storeName,
    required this.address,
    required this.type,
    required this.trxId,
    required this.cashier,
    required this.customerName,
    required this.items,
    required this.subTotal,
    required this.tax,
    required this.afterTax,
    required this.cash,
    required this.change,
    required this.date,
    this.logoPath,
    this.paymentMethod = 'Cash', // Default to Cash
  });

  int get totalItems => items.length;

  int get totalQuantity => items.fold(0, (sum, item) => sum + item.quantity);

  /// Get grouped items (menggabungkan item yang sama)
  /// Item dengan nama dan harga yang sama akan digabungkan quantity-nya
  List<ReceiptItem> get groupedItems {
    final Map<String, ReceiptItem> itemMap = {};

    for (var item in items) {
      // Gunakan kombinasi nama dan harga sebagai key
      final key = '${item.name}_${item.price}';

      if (itemMap.containsKey(key)) {
        // Item sudah ada, tambahkan quantity
        final existing = itemMap[key]!;
        itemMap[key] = ReceiptItem(
          name: existing.name,
          quantity: existing.quantity + item.quantity,
          price: existing.price,
          subtotal: existing.subtotal + item.subtotal,
        );
      } else {
        // Item baru, tambahkan ke map
        itemMap[key] = item;
      }
    }

    return itemMap.values.toList();
  }

  factory Receipt.fromJson(Map<String, dynamic> json) {
    return Receipt(
      storeName: json['storeName'] as String,
      address: json['address'] as String,
      type: json['type'] as String,
      trxId: json['trxId'] as String,
      cashier: json['cashier'] as String,
      customerName: json['customerName'] as String,
      items: (json['items'] as List<dynamic>)
          .map((item) => ReceiptItem.fromJson(item as Map<String, dynamic>))
          .toList(),
      subTotal: (json['subTotal'] as num).toDouble(),
      tax: (json['tax'] as num).toDouble(),
      afterTax: (json['afterTax'] as num).toDouble(),
      cash: (json['cash'] as num).toDouble(),
      change: (json['change'] as num).toDouble(),
      date: DateTime.parse(json['date'] as String),
      logoPath: json['logoPath'] as String?,
      paymentMethod: json['paymentMethod'] as String? ?? 'Cash',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'storeName': storeName,
      'address': address,
      'type': type,
      'trxId': trxId,
      'cashier': cashier,
      'customerName': customerName,
      'items': items.map((item) => item.toJson()).toList(),
      'subTotal': subTotal,
      'tax': tax,
      'afterTax': afterTax,
      'cash': cash,
      'change': change,
      'date': date.toIso8601String(),
      'logoPath': logoPath,
      'paymentMethod': paymentMethod,
    };
  }
}
