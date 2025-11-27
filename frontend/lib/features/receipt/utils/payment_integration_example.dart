import 'package:flutter/material.dart';
import 'package:sagawa_pos_new/data/services/user_service.dart';
import 'package:sagawa_pos_new/features/receipt/domain/models/receipt.dart';
import 'package:sagawa_pos_new/features/receipt/domain/models/receipt_item.dart';
import 'package:sagawa_pos_new/features/receipt/presentation/pages/receipt_print_page.dart';

/// Example: Integration dengan Payment Success Flow
///
/// File ini menunjukkan bagaimana mengintegrasikan receipt feature
/// dengan payment success flow di aplikasi
class PaymentSuccessExample {
  /// Generate unique transaction ID
  static String generateTrxId() {
    final now = DateTime.now();
    return '${now.year}${now.month.toString().padLeft(2, '0')}${now.day.toString().padLeft(2, '0')}'
        '${now.hour.toString().padLeft(2, '0')}${now.minute.toString().padLeft(2, '0')}'
        '${now.second.toString().padLeft(2, '0')}${now.millisecond.toString().padLeft(3, '0')}';
  }

  /// Navigate to receipt page after payment success
  static Future<void> showReceipt(
    BuildContext context, {
    required String orderType, // "Dine In" or "Take Away"
    required String customerName,
    required String cashierName,
    required List<Map<String, dynamic>> cartItems,
    required double subTotal,
    required double taxPercent,
    required double cashAmount,
    required String paymentMethod, // "Cash" or "QRIS"
  }) async {
    try {
      // Get user data from service
      final user = await UserService.getUser();

      // Calculate tax and totals
      final tax = subTotal * (taxPercent / 100);
      final afterTax = subTotal + tax;
      final change = cashAmount - afterTax;

      // Convert cart items to receipt items
      final receiptItems = cartItems.map((item) {
        return ReceiptItem(
          name: item['name'] as String,
          quantity: item['quantity'] as int,
          price: (item['price'] as num).toDouble(),
          subtotal: (item['subtotal'] as num).toDouble(),
        );
      }).toList();

      // Create receipt
      // Debug log
      print('DEBUG: Payment Method received = $paymentMethod');

      final receipt = Receipt(
        storeName: user?.kemitraan ?? 'Warung Mas Aam Nusantara',
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

/// Example Usage in Payment Success Page:
///
/// ```dart
/// // Di dalam payment success handler
/// void _onPaymentSuccess() async {
///   await PaymentSuccessExample.showReceipt(
///     context,
///     orderType: _orderType, // "Dine In" or "Take Away"
///     customerName: _customerNameController.text,
///     cashierName: _cashierNameController.text,
///     cartItems: widget.cartItems,
///     subTotal: _calculateSubTotal(),
///     taxPercent: 10.0,
///     cashAmount: _cashAmount,
///   );
/// }
/// ```
