import 'package:flutter/material.dart';
import 'package:sagawa_pos/core/utils/indonesia_time.dart';
import 'package:sagawa_pos/data/services/user_service.dart';
import 'package:sagawa_pos/data/services/transaction_service.dart';
import 'package:sagawa_pos/features/receipt/domain/models/receipt.dart';
import 'package:sagawa_pos/features/receipt/domain/models/receipt_item.dart';
import 'package:sagawa_pos/features/receipt/presentation/pages/receipt_print_page.dart';
import 'package:sagawa_pos/features/order_history/domain/models/order_history.dart';
import 'package:sagawa_pos/features/order_history/data/repositories/order_history_repository.dart';

class PaymentSuccessExample {
  /// Generate unique transaction ID
  static String generateTrxId() {
    final now = IndonesiaTime.now();
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
    String? note,
    // Voucher fields
    String? voucherCode,
    double? voucherAmount,
    double? additionalPayment,
    String? additionalPaymentMethod,
    // Discount fields
    int? discountPercent,
    double? discountAmount,
  }) async {
    try {
      final user = await UserService.getUser();

      final tax = subTotal * (taxPercent / 100);
      final afterTax = subTotal + tax;

      // Calculate total after discount if applicable
      final discountValue = discountAmount ?? 0.0;
      final finalTotal = afterTax - discountValue;

      // Calculate change based on final total
      final change = cashAmount - finalTotal;

      final receiptItems = cartItems.map((item) {
        return ReceiptItem(
          name: item['name'] as String,
          quantity: item['quantity'] as int,
          price: (item['price'] as num).toDouble(),
          subtotal: (item['subtotal'] as num).toDouble(),
        );
      }).toList();

      final trxId = generateTrxId();

      final receipt = Receipt(
        storeName: user?.kemitraan ?? 'Warung Mas Gaw Nusantara',
        address:
            user?.outlet ??
            'Jl. Mampang Prapatan XI No.3A 7, RT.7/RW.1, Tegal Parang, Kec. Mampang Prpt., Kota Jakarta Selatan',
        type: orderType,
        trxId: trxId,
        cashier: cashierName,
        customerName: customerName,
        items: receiptItems,
        subTotal: subTotal,
        tax: tax,
        afterTax: discountPercent != null ? finalTotal : afterTax,
        cash: cashAmount,
        change: change > 0 ? change : 0,
        date: IndonesiaTime.now(),
        logoPath: 'assets/logo/logo_pos.png',
        paymentMethod: paymentMethod,
        voucherCode: voucherCode,
        voucherAmount: voucherAmount,
        additionalPayment: additionalPayment,
        additionalPaymentMethod: additionalPaymentMethod,
        discountPercent: discountPercent,
        discountAmount: discountAmount,
        notes: note,
      );

      // Debug log
      print('DEBUG: Receipt.paymentMethod = ${receipt.paymentMethod}');

      // Save transaction to backend database
      try {
        final transactionService = TransactionService();
        final transactionItems = cartItems.map((item) {
          return TransactionItemData(
            menuName: item['name'] as String,
            qty: item['quantity'] as int,
            price: (item['price'] as num).toDouble(),
            subtotal: (item['subtotal'] as num).toDouble(),
          );
        }).toList();

        // Calculate payment values based on payment method
        final isDiscount100 = discountPercent == 100;
        final isVoucherPayment = voucherCode != null && voucherAmount != null;

        double finalNominal = 0.0;
        double finalQris = 0.0;
        double finalChanges = 0.0;
        double finalTotal = afterTax;

        if (isDiscount100) {
          // Discount 100%: all payment values should be 0
          finalNominal = 0.0;
          finalQris = 0.0;
          finalChanges = 0.0;
          finalTotal = 0.0;
        } else if (isVoucherPayment) {
          // Voucher payment: only count the additional payment (cash/qris after voucher)
          // Voucher acts as a discount, so only the additional payment is real revenue
          if (additionalPayment != null && additionalPayment > 0) {
            if (additionalPaymentMethod == 'Cash') {
              // Voucher + Cash: nominal = additional cash, total = shortfall after voucher
              final voucherShortfall = afterTax - voucherAmount;
              finalNominal = additionalPayment;
              finalQris = 0.0;
              finalChanges = additionalPayment - voucherShortfall;
              finalTotal =
                  voucherShortfall; // Only the amount customer actually paid
            } else {
              // Voucher + QRIS: qris = shortfall amount, total = shortfall after voucher
              final voucherShortfall = afterTax - voucherAmount;
              finalNominal = 0.0;
              finalQris = voucherShortfall; // QRIS pays exact shortfall
              finalChanges = 0.0;
              finalTotal =
                  voucherShortfall; // Only the amount customer actually paid
            }
          } else {
            // Pure voucher (covers entire amount): no revenue from customer
            finalNominal = 0.0;
            finalQris = 0.0;
            finalChanges = 0.0;
            finalTotal = 0.0; // Voucher covers everything, no cash revenue
          }
        } else if (paymentMethod == 'Cash') {
          finalNominal = cashAmount;
          finalQris = 0.0;
          finalChanges = change > 0 ? change : 0.0;
          finalTotal = afterTax;
        } else if (paymentMethod == 'QRIS') {
          finalNominal = 0.0;
          finalQris = afterTax;
          finalChanges = 0.0;
          finalTotal = afterTax;
        } else if (paymentMethod.toLowerCase().contains('discount')) {
          // Discount payment (not 100%)
          if (paymentMethod.toLowerCase().contains('qris')) {
            finalNominal = 0.0;
            finalQris = finalTotal;
            finalChanges = 0.0;
          } else {
            finalNominal = cashAmount;
            finalQris = 0.0;
            finalChanges = change > 0 ? change : 0.0;
          }
        }

        print(
          '[Payment] Method: $paymentMethod, Voucher: $isVoucherPayment, Additional: $additionalPayment',
        );
        print(
          '[Payment] Final values - nominal: $finalNominal, qris: $finalQris, changes: $finalChanges, total: $finalTotal',
        );

        final transactionData = TransactionData(
          trxId: trxId,
          outletId: user?.id ?? '', // ID outlet dari akun login
          outletName: user?.outlet ?? '', // Nama outlet
          items: transactionItems,
          cashier: cashierName,
          customer: customerName,
          note: note,
          type: orderType == 'Dine In' ? 'dine_in' : 'take_away',
          method: paymentMethod.toLowerCase(),
          nominal: finalNominal,
          subtotal: subTotal,
          tax: tax,
          total: finalTotal,
          qris: finalQris,
          changes: finalChanges,
          discountPercent: discountPercent,
          discountAmount: discountAmount,
          // Voucher fields
          voucherCode: voucherCode,
          voucherAmount: voucherAmount,
          additionalPayment: additionalPayment,
          additionalPaymentMethod: additionalPaymentMethod,
        );

        await transactionService.saveTransaction(transactionData);
        print('DEBUG: Transaction saved to backend successfully');
      } catch (e) {
        print('ERROR: Failed to save transaction to backend: $e');
        // Continue even if backend save fails - don't block receipt printing
      }

      // Save to order history (local)
      try {
        final orderHistory = OrderHistory(
          id: generateTrxId(), // Generate unique ID for order history
          trxId: receipt.trxId,
          outletId: user?.id ?? '', // ID outlet dari akun login
          outletName: user?.outlet ?? '', // Nama outlet
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
