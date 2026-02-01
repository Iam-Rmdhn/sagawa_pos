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

    String? voucherCode,
    double? voucherAmount,
    double? additionalPayment,
    String? additionalPaymentMethod,

    int? discountPercent,
    double? discountAmount,
  }) async {
    try {
      final user = await UserService.getUser();

      final discountValue = (discountAmount ?? 0.0) + (voucherAmount ?? 0.0);
      final subTotalAfterDiscount = subTotal - discountValue;

      final taxBase = subTotalAfterDiscount > 0 ? subTotalAfterDiscount : 0.0;
      final tax = taxBase * (taxPercent / 100);

      final afterTax = taxBase + tax;
      final finalTotal = afterTax;

      double change = 0.0;
      final isVoucherPayment = voucherCode != null && voucherAmount != null;

      if (isVoucherPayment) {
        if (additionalPayment != null && additionalPayment > 0) {
          if (additionalPaymentMethod == 'Cash') {
            final voucherShortfall = afterTax > voucherAmount
                ? (afterTax - voucherAmount)
                : 0.0;
            change = additionalPayment - voucherShortfall;
          } else {
            change = 0.0;
          }
        } else {
          change = 0.0;
        }
      } else if (paymentMethod == 'Cash') {
        change = cashAmount - afterTax;
      } else if (paymentMethod.toLowerCase().contains('discount')) {
        if (paymentMethod.toLowerCase().contains('cash')) {
          change = cashAmount - afterTax;
        } else {
          change = 0.0;
        }
      } else {
        change = 0.0;
      }

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
        afterTax: finalTotal,

        cash: isVoucherPayment ? (additionalPayment ?? 0.0) : cashAmount,
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

      print('DEBUG: Receipt.paymentMethod = ${receipt.paymentMethod}');

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

        final isDiscount100 = discountPercent == 100;
        final isVoucherPayment = voucherCode != null && voucherAmount != null;

        double finalNominal = 0.0;
        double finalQris = 0.0;
        double finalChanges = 0.0;
        double finalTotal = afterTax;

        if (isDiscount100) {
          finalNominal = 0.0;
          finalQris = 0.0;
          finalChanges = 0.0;
          finalTotal = 0.0;
        } else if (isVoucherPayment) {
          if (additionalPayment != null && additionalPayment > 0) {
            if (additionalPaymentMethod == 'Cash') {
              final voucherShortfall = afterTax - voucherAmount;
              finalNominal = additionalPayment;
              finalQris = 0.0;
              finalChanges = additionalPayment - voucherShortfall;
              finalTotal = voucherShortfall;
            } else {
              final voucherShortfall = afterTax - voucherAmount;
              finalNominal = 0.0;
              finalQris = voucherShortfall;
              finalChanges = 0.0;
              finalTotal = voucherShortfall;
            }
          } else {
            finalNominal = 0.0;
            finalQris = 0.0;
            finalChanges = 0.0;
            finalTotal = 0.0;
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
          outletId: user?.id ?? '',
          outletName: user?.outlet ?? '',
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

          voucherCode: voucherCode,
          voucherAmount: voucherAmount,
          additionalPayment: additionalPayment,
          additionalPaymentMethod: additionalPaymentMethod,
        );

        await transactionService.saveTransaction(transactionData);
        print('DEBUG: Transaction saved to backend successfully');
      } catch (e) {
        print('ERROR: Failed to save transaction to backend: $e');
      }

      try {
        final orderHistory = OrderHistory(
          id: generateTrxId(),
          trxId: receipt.trxId,
          outletId: user?.id ?? '',
          outletName: user?.outlet ?? '',
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

      if (!context.mounted) return;
      await Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => ReceiptPrintPage(receipt: receipt)),
      );
    } catch (e) {
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
