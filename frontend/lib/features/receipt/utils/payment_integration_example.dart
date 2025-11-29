import 'package:flutter/material.dart';
import 'package:sagawa_pos_new/data/services/user_service.dart';
import 'package:sagawa_pos_new/features/receipt/domain/models/receipt.dart';
import 'package:sagawa_pos_new/features/receipt/domain/models/receipt_item.dart';
import 'package:sagawa_pos_new/features/receipt/presentation/pages/receipt_print_page.dart';
import 'package:sagawa_pos_new/features/order_history/domain/models/order_history.dart';
import 'package:sagawa_pos_new/features/order_history/data/repositories/order_history_repository.dart';

class PaymentSuccessExample {
  /// Generate unique transaction ID
  static String generateTrxId() {
    final now = DateTime.now();
    return '${now.year}${now.month.toString().padLeft(2, '0')}${now.day.toString().padLeft(2, '0')}'
        '${now.hour.toString().padLeft(2, '0')}${now.minute.toString().padLeft(2, '0')}'
        '${now.second.toString().padLeft(2, '0')}${now.millisecond.toString().padLeft(3, '0')}';
  }

  static Future<void> showReceipt(
    BuildContext context, {
    required String orderType,
    required String customerName,
    required String cashierName,
    required List<Map<String, dynamic>> cartItems,
    required double subTotal,
    required double taxPercent,
    required double cashAmount,
    required String paymentMethod,
  }) async {
    try {
      final user = await UserService.getUser();

      final tax = subTotal * (taxPercent / 100);
      final afterTax = subTotal + tax;
      final change = cashAmount - afterTax;

      final receiptItems = cartItems.map((item) {
        return ReceiptItem(
          name: item['name'] as String,
          quantity: item['quantity'] as int,
          price: (item['price'] as num).toDouble(),
          subtotal: (item['subtotal'] as num).toDouble(),
        );
      }).toList();

      final receipt = Receipt(
        storeName: user?.kemitraan ?? 'Warung Mas Gaw Nusantara',
        address:
            user?.outlet ??
            'Jl. Mampang Prapatan XI No.3A 7, RT.7/RW.1, Tegal Parang, Kec. Mampang Prpt., Kota Jakarta Selatan',
        type: orderType,
        trxId: generateTrxId(),
        cashier: cashierName,
        customerName: customerName,
        items: receiptItems,
        subTotal: subTotal,
        tax: tax,
        afterTax: afterTax,
        cash: cashAmount,
        change: change,
        date: DateTime.now(),
        logoPath: 'assets/logo/logo_pos.png',
        paymentMethod: paymentMethod,
      );

      // Debug log
      print('DEBUG: Receipt.paymentMethod = ${receipt.paymentMethod}');

      // Save to order history
      try {
        final orderHistory = OrderHistory(
          id: generateTrxId(), // Generate unique ID for order history
          trxId: receipt.trxId,
          date: receipt.date,
          totalAmount: receipt.afterTax,
          status: 'completed',
          receipt: receipt,
        );

        final repository = OrderHistoryRepository();
        await repository.saveOrder(orderHistory);
        print('DEBUG: Order saved to history successfully');
      } catch (e) {
        print('ERROR: Failed to save order to history: $e');
      }

      // Navigate to receipt page
      if (!context.mounted) return;
      await Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => ReceiptPrintPage(receipt: receipt)),
      );
    } catch (e) {
      // Handle error
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Gagal membuat struk: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
}
