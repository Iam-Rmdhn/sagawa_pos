import 'package:flutter/material.dart';
import 'package:sagawa_pos/core/utils/indonesia_time.dart';
import 'package:sagawa_pos/features/receipt/domain/models/receipt.dart';
import 'package:sagawa_pos/features/receipt/domain/models/receipt_item.dart';
import 'package:sagawa_pos/features/receipt/presentation/pages/receipt_print_page.dart';

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
  final receiptItems = cartItems.map((item) {
    return ReceiptItem(
      name: item['name'] as String,
      quantity: item['quantity'] as int,
      price: (item['price'] as num).toDouble(),
      subtotal: (item['subtotal'] as num).toDouble(),
    );
  }).toList();

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

  Navigator.of(
    context,
  ).push(MaterialPageRoute(builder: (_) => ReceiptPrintPage(receipt: receipt)));
}
