import 'package:flutter/material.dart';
import 'package:sagawa_pos_new/core/utils/indonesia_time.dart';
import 'package:sagawa_pos_new/features/receipt/domain/models/receipt.dart';
import 'package:sagawa_pos_new/features/receipt/domain/models/receipt_item.dart';
import 'package:sagawa_pos_new/features/receipt/presentation/pages/receipt_print_page.dart';

/// Example usage of Receipt feature
///
/// Call this function after a successful payment to show receipt page
void navigateToReceipt(
  BuildContext context, {
  required String storeName,
  required String address,
  required String type,
  required String trxId,
  required String cashier,
  required String customerName,
  required List<Map<String, dynamic>> cartItems,
  required double subTotal,
  required double tax,
  required double afterTax,
  required double cash,
  required double change,
}) {
  // Convert cart items to receipt items
  final receiptItems = cartItems.map((item) {
    return ReceiptItem(
      name: item['name'] as String,
      quantity: item['quantity'] as int,
      price: (item['price'] as num).toDouble(),
      subtotal: (item['subtotal'] as num).toDouble(),
    );
  }).toList();

  // Create receipt object
  final receipt = Receipt(
    storeName: storeName,
    address: address,
    type: type,
    trxId: trxId,
    cashier: cashier,
    customerName: customerName,
    items: receiptItems,
    subTotal: subTotal,
    tax: tax,
    afterTax: afterTax,
    cash: cash,
    change: change,
    date: IndonesiaTime.now(),
    logoPath: 'assets/logo/logo_pos.png',
  );

  // Navigate to receipt page
  Navigator.of(
    context,
  ).push(MaterialPageRoute(builder: (_) => ReceiptPrintPage(receipt: receipt)));
}

/// Example: How to use after payment success
///
/// ```dart
/// void onPaymentSuccess() {
///   navigateToReceipt(
///     context,
///     storeName: 'Warung Mas Aam Nusantara',
///     address: 'Jl. Mampang Prapatan XI No.3A 7, RT.7/RW.1, Tegal Parang, Kec. Mampang Prpt., Kota Jakarta Selatan',
///     type: 'Dine In', // or 'Take Away'
///     trxId: '2039402397401724',
///     cashier: 'Udin',
///     customerName: 'Sapri',
///     cartItems: [
///       {
///         'name': 'Ayam goreng',
///         'quantity': 2,
///         'price': 15000.0,
///         'subtotal': 30000.0,
///       },
///       {
///         'name': 'Nasi goreng',
///         'quantity': 1,
///         'price': 15000.0,
///         'subtotal': 15000.0,
///       },
///       {
///         'name': 'Kulit krispy',
///         'quantity': 2,
///         'price': 3000.0,
///         'subtotal': 6000.0,
///       },
///     ],
///     subTotal: 46000.0,
///     tax: 4600.0,
///     afterTax: 50600.0,
///     cash: 55000.0,
///     change: -4400.0,
///   );
/// }
/// ```
