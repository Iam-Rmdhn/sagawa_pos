import 'package:flutter_test/flutter_test.dart';
import 'package:sagawa_pos/features/financial_report/domain/models/financial_report.dart';

/// Check if transaction is full discount (100% free)
bool isFullDiscount(TransactionRecord tx) {
  final paymentMethod = tx.paymentMethod.toLowerCase();
  if (paymentMethod.contains('discount')) {
    if (tx.subtotal <= 0) {
      return true;
    }
    if (!paymentMethod.contains('cash') && !paymentMethod.contains('qris')) {
      return true;
    }
  }
  return false;
}

/// Check if transaction is pure voucher (100% covered by voucher)
bool isPureVoucher(TransactionRecord tx) {
  final paymentMethod = tx.paymentMethod.toLowerCase();
  return paymentMethod == 'voucher';
}

/// Get actual revenue for a transaction (accounting for voucher/discount)
/// Revenue is calculated WITHOUT tax (tax is shown separately in PB1 card)
/// For voucher payments: additionalPayment - changes (net payment received)
double getActualTransactionRevenue(TransactionRecord tx) {
  final paymentMethod = tx.paymentMethod.toLowerCase();

  // Full discount (100%) - no revenue
  if (isFullDiscount(tx)) {
    return 0.0;
  }

  // Pure voucher (covers 100%) - no revenue
  if (isPureVoucher(tx)) {
    return 0.0;
  }

  // Voucher + Cash/QRIS: additionalPayment - changes (net amount received)
  if (paymentMethod.contains('voucher')) {
    if (tx.additionalPayment != null && tx.additionalPayment! > 0) {
      final changes = tx.changes ?? 0.0;
      // Net revenue = what customer paid - change given back
      return tx.additionalPayment! - changes;
    }
    // Legacy data fallback: use total if less than full price
    final fullPrice = tx.subtotal + tx.tax;
    if (tx.total < fullPrice && tx.total > 0) {
      return tx.total;
    }
    return 0.0;
  }

  // Regular payment or Discount + Cash/QRIS - use subtotal (WITHOUT tax)
  // Tax is calculated separately in PB1 card
  return tx.subtotal;
}

/// Calculate cash revenue from transactions
/// Revenue is calculated WITHOUT tax
double getCashRevenue(List<TransactionRecord> transactions) {
  double total = 0;
  for (final tx in transactions) {
    final paymentMethod = tx.paymentMethod.toLowerCase();

    // Skip full discount and pure voucher
    if (isFullDiscount(tx) || isPureVoucher(tx)) continue;

    // Cash payment (not QRIS)
    if (!paymentMethod.contains('qris')) {
      if (paymentMethod.contains('voucher') && paymentMethod.contains('cash')) {
        // Voucher + Cash: additionalPayment - changes
        if (tx.additionalPayment != null && tx.additionalPayment! > 0) {
          final changes = tx.changes ?? 0.0;
          total += tx.additionalPayment! - changes;
        } else {
          // Legacy data fallback
          final fullPrice = tx.subtotal + tx.tax;
          if (tx.total < fullPrice && tx.total > 0) {
            total += tx.total;
          }
        }
      } else if (!paymentMethod.contains('voucher')) {
        // Pure Cash or Discount + Cash - use subtotal (WITHOUT tax)
        total += tx.subtotal;
      }
    }
  }
  return total;
}

/// Calculate QRIS revenue from transactions
/// Revenue is calculated WITHOUT tax
double getQrisRevenue(List<TransactionRecord> transactions) {
  double total = 0;
  for (final tx in transactions) {
    final paymentMethod = tx.paymentMethod.toLowerCase();

    // Skip full discount and pure voucher
    if (isFullDiscount(tx) || isPureVoucher(tx)) continue;

    if (paymentMethod.contains('qris')) {
      if (paymentMethod.contains('voucher')) {
        // Voucher + QRIS: additionalPayment - changes
        if (tx.additionalPayment != null && tx.additionalPayment! > 0) {
          final changes = tx.changes ?? 0.0;
          total += tx.additionalPayment! - changes;
        } else {
          // Legacy data fallback
          final fullPrice = tx.subtotal + tx.tax;
          if (tx.total < fullPrice && tx.total > 0) {
            total += tx.total;
          }
        }
      } else {
        // Pure QRIS or Discount + QRIS - use subtotal (WITHOUT tax)
        total += tx.subtotal;
      }
    }
  }
  return total;
}

/// Calculate total revenue from all transactions
/// Revenue is calculated WITHOUT tax
double getTotalRevenue(List<TransactionRecord> transactions) {
  double total = 0;
  for (final tx in transactions) {
    total += getActualTransactionRevenue(tx);
  }
  return total;
}

/// Calculate total tax (PB1)
double getTotalTax(List<TransactionRecord> transactions) {
  double total = 0;
  for (final tx in transactions) {
    // Skip full discount or pure voucher
    if (isFullDiscount(tx) || isPureVoucher(tx)) continue;

    final paymentMethod = tx.paymentMethod.toLowerCase();

    // For voucher + cash/qris, calculate proportional tax
    if (paymentMethod.contains('voucher')) {
      final actualRevenue = getActualTransactionRevenue(tx);
      final fullAmount = tx.subtotal + tx.tax;
      if (fullAmount > 0) {
        final taxPortion = tx.tax * (actualRevenue / fullAmount);
        total += taxPortion;
      }
    } else {
      // Full tax for normal payments
      total += tx.tax;
    }
  }
  return total;
}

void main() {
  group('Revenue Calculation WITHOUT Tax Tests', () {
    test('Regular Cash payment should return subtotal (WITHOUT tax)', () {
      // Pesanan: subtotal 27273, tax 2727, total 30000
      // Revenue seharusnya = subtotal (tanpa tax)
      final tx = TransactionRecord(
        trxId: 'TRX001',
        date: DateTime.now(),
        type: 'Dine In',
        menuItems: 'Ramen x1',
        qty: 1,
        tax: 2727,
        subtotal: 27273,
        total: 30000,
        paymentMethod: 'Cash',
      );

      final revenue = getActualTransactionRevenue(tx);
      expect(revenue, 27273); // subtotal, NOT total
    });

    test('Regular QRIS payment should return subtotal (WITHOUT tax)', () {
      // Pesanan: subtotal 50000, tax 5000, total 55000
      final tx = TransactionRecord(
        trxId: 'TRX002',
        date: DateTime.now(),
        type: 'Take Away',
        menuItems: 'Sushi x2',
        qty: 2,
        tax: 5000,
        subtotal: 50000,
        total: 55000,
        paymentMethod: 'QRIS',
      );

      final revenue = getActualTransactionRevenue(tx);
      expect(revenue, 50000); // subtotal, NOT total
    });
  });

  group('Voucher Payment Tests - additionalPayment minus changes', () {
    test('Voucher + Cash: additionalPayment - changes (exact payment)', () {
      // Total 30000, voucher 20000, customer bayar tepat 10000 cash, no change
      final tx = TransactionRecord(
        trxId: 'TRX003',
        date: DateTime.now(),
        type: 'Dine In',
        menuItems: 'Ramen x1',
        qty: 1,
        tax: 2727,
        subtotal: 27273,
        total: 10000,
        paymentMethod: 'Voucher + Cash',
        voucherAmount: 20000,
        additionalPayment: 10000,
        changes: 0,
      );

      final revenue = getActualTransactionRevenue(tx);
      expect(revenue, 10000); // 10000 - 0 = 10000
    });

    test('Voucher + Cash: additionalPayment - changes (with change)', () {
      // Total 30000, voucher 20000, shortfall 10000
      // Customer bayar 15000 cash, change 5000
      // Net revenue = 15000 - 5000 = 10000
      final tx = TransactionRecord(
        trxId: 'TRX004',
        date: DateTime.now(),
        type: 'Dine In',
        menuItems: 'Ramen x1',
        qty: 1,
        tax: 2727,
        subtotal: 27273,
        total: 10000,
        paymentMethod: 'Voucher + Cash',
        voucherAmount: 20000,
        additionalPayment: 15000, // Customer gave 15000
        changes: 5000, // Change given back
      );

      final revenue = getActualTransactionRevenue(tx);
      expect(revenue, 10000); // 15000 - 5000 = 10000
    });

    test('Voucher + QRIS: additionalPayment (usually no change for QRIS)', () {
      // Total 50000, voucher 30000, customer bayar 20000 QRIS
      final tx = TransactionRecord(
        trxId: 'TRX005',
        date: DateTime.now(),
        type: 'Take Away',
        menuItems: 'Sushi x2',
        qty: 2,
        tax: 4545,
        subtotal: 45455,
        total: 20000,
        paymentMethod: 'Voucher + QRIS',
        voucherAmount: 30000,
        additionalPayment: 20000,
        changes: 0,
      );

      final revenue = getActualTransactionRevenue(tx);
      expect(revenue, 20000); // 20000 - 0 = 20000
    });

    test('Pure Voucher (covers 100%) should return 0', () {
      final tx = TransactionRecord(
        trxId: 'TRX006',
        date: DateTime.now(),
        type: 'Dine In',
        menuItems: 'Gyudon x1',
        qty: 1,
        tax: 1818,
        subtotal: 18182,
        total: 0,
        paymentMethod: 'Voucher',
        voucherAmount: 20000,
        additionalPayment: 0,
        changes: 0,
      );

      final revenue = getActualTransactionRevenue(tx);
      expect(revenue, 0); // No revenue - voucher covers 100%
    });
  });

  group('Discount Payment Tests', () {
    test('Discount 100% should return 0', () {
      final tx = TransactionRecord(
        trxId: 'TRX007',
        date: DateTime.now(),
        type: 'Dine In',
        menuItems: 'Free item',
        qty: 1,
        tax: 0,
        subtotal: 0,
        total: 0,
        paymentMethod: 'Discount 100%',
      );

      final revenue = getActualTransactionRevenue(tx);
      expect(revenue, 0); // No revenue - completely free
    });

    test('Discount + Cash should return subtotal (WITHOUT tax)', () {
      // Original 30000, discount 20% = 24000 after discount
      // Tax is separate, so revenue = subtotal (before tax)
      final tx = TransactionRecord(
        trxId: 'TRX008',
        date: DateTime.now(),
        type: 'Dine In',
        menuItems: 'Ramen x1',
        qty: 1,
        tax: 2182, // Tax on discounted amount
        subtotal: 21818, // Subtotal after discount (before tax)
        total: 24000, // After tax
        paymentMethod: 'Discount + Cash',
      );

      final revenue = getActualTransactionRevenue(tx);
      expect(revenue, 21818); // subtotal, NOT total
    });
  });

  group('Cash Revenue Aggregation Tests', () {
    test(
      'Mixed transactions should calculate cash revenue correctly (WITHOUT tax)',
      () {
        final transactions = [
          // Cash payment: subtotal 27273
          TransactionRecord(
            trxId: 'TRX001',
            date: DateTime.now(),
            type: 'Dine In',
            menuItems: 'Ramen',
            qty: 1,
            tax: 2727,
            subtotal: 27273,
            total: 30000,
            paymentMethod: 'Cash',
          ),
          // QRIS payment: should NOT count as cash
          TransactionRecord(
            trxId: 'TRX002',
            date: DateTime.now(),
            type: 'Take Away',
            menuItems: 'Sushi',
            qty: 1,
            tax: 4545,
            subtotal: 45455,
            total: 50000,
            paymentMethod: 'QRIS',
          ),
          // Voucher + Cash: 15000 paid, 5000 change = 10000 net
          TransactionRecord(
            trxId: 'TRX003',
            date: DateTime.now(),
            type: 'Dine In',
            menuItems: 'Gyudon',
            qty: 1,
            tax: 2727,
            subtotal: 27273,
            total: 10000,
            paymentMethod: 'Voucher + Cash',
            additionalPayment: 15000,
            changes: 5000,
          ),
          // Pure Voucher: 0 (no cash revenue)
          TransactionRecord(
            trxId: 'TRX004',
            date: DateTime.now(),
            type: 'Dine In',
            menuItems: 'Free',
            qty: 1,
            tax: 0,
            subtotal: 0,
            total: 0,
            paymentMethod: 'Voucher',
          ),
        ];

        final cashRevenue = getCashRevenue(transactions);
        // Expected: 27273 (Cash subtotal) + 10000 (Voucher+Cash net) = 37273
        expect(cashRevenue, 37273);
      },
    );
  });

  group('QRIS Revenue Aggregation Tests', () {
    test(
      'Mixed transactions should calculate QRIS revenue correctly (WITHOUT tax)',
      () {
        final transactions = [
          // QRIS payment: subtotal 45455
          TransactionRecord(
            trxId: 'TRX001',
            date: DateTime.now(),
            type: 'Take Away',
            menuItems: 'Sushi',
            qty: 1,
            tax: 4545,
            subtotal: 45455,
            total: 50000,
            paymentMethod: 'QRIS',
          ),
          // Cash payment: should NOT count as QRIS
          TransactionRecord(
            trxId: 'TRX002',
            date: DateTime.now(),
            type: 'Dine In',
            menuItems: 'Ramen',
            qty: 1,
            tax: 2727,
            subtotal: 27273,
            total: 30000,
            paymentMethod: 'Cash',
          ),
          // Voucher + QRIS: 15000 net
          TransactionRecord(
            trxId: 'TRX003',
            date: DateTime.now(),
            type: 'Take Away',
            menuItems: 'Tempura',
            qty: 1,
            tax: 4545,
            subtotal: 45455,
            total: 15000,
            paymentMethod: 'Voucher + QRIS',
            additionalPayment: 15000,
            changes: 0,
          ),
        ];

        final qrisRevenue = getQrisRevenue(transactions);
        // Expected: 45455 (QRIS subtotal) + 15000 (Voucher+QRIS net) = 60455
        expect(qrisRevenue, 60455);
      },
    );
  });

  group('Total Revenue Aggregation Tests', () {
    test(
      'Total revenue should sum all actual payments correctly (WITHOUT tax)',
      () {
        final transactions = [
          // Cash: subtotal 27273
          TransactionRecord(
            trxId: 'TRX001',
            date: DateTime.now(),
            type: 'Dine In',
            menuItems: 'Ramen',
            qty: 1,
            tax: 2727,
            subtotal: 27273,
            total: 30000,
            paymentMethod: 'Cash',
          ),
          // QRIS: subtotal 45455
          TransactionRecord(
            trxId: 'TRX002',
            date: DateTime.now(),
            type: 'Take Away',
            menuItems: 'Sushi',
            qty: 1,
            tax: 4545,
            subtotal: 45455,
            total: 50000,
            paymentMethod: 'QRIS',
          ),
          // Voucher + Cash: 10000 net
          TransactionRecord(
            trxId: 'TRX003',
            date: DateTime.now(),
            type: 'Dine In',
            menuItems: 'Gyudon',
            qty: 1,
            tax: 2727,
            subtotal: 27273,
            total: 10000,
            paymentMethod: 'Voucher + Cash',
            additionalPayment: 10000,
            changes: 0,
          ),
          // Pure Voucher: 0
          TransactionRecord(
            trxId: 'TRX004',
            date: DateTime.now(),
            type: 'Dine In',
            menuItems: 'Free',
            qty: 1,
            tax: 1818,
            subtotal: 18182,
            total: 0,
            paymentMethod: 'Voucher',
          ),
          // Discount 100%: 0
          TransactionRecord(
            trxId: 'TRX005',
            date: DateTime.now(),
            type: 'Dine In',
            menuItems: 'Promo',
            qty: 1,
            tax: 0,
            subtotal: 0,
            total: 0,
            paymentMethod: 'Discount 100%',
          ),
        ];

        final totalRevenue = getTotalRevenue(transactions);
        // Expected: 27273 + 45455 + 10000 + 0 + 0 = 82728
        expect(totalRevenue, 82728);
      },
    );
  });

  group('Tax (PB1) Calculation Tests', () {
    test('Regular payments should include full tax', () {
      final transactions = [
        TransactionRecord(
          trxId: 'TRX001',
          date: DateTime.now(),
          type: 'Dine In',
          menuItems: 'Ramen',
          qty: 1,
          tax: 2727,
          subtotal: 27273,
          total: 30000,
          paymentMethod: 'Cash',
        ),
        TransactionRecord(
          trxId: 'TRX002',
          date: DateTime.now(),
          type: 'Take Away',
          menuItems: 'Sushi',
          qty: 1,
          tax: 4545,
          subtotal: 45455,
          total: 50000,
          paymentMethod: 'QRIS',
        ),
      ];

      final totalTax = getTotalTax(transactions);
      // Expected: 2727 + 4545 = 7272
      expect(totalTax, 7272);
    });

    test('Voucher payments should have proportional tax', () {
      final transactions = [
        // Voucher + Cash: 10000 out of 30000 total
        // Tax proportion: 10000 / 30000 * 2727 = 909
        TransactionRecord(
          trxId: 'TRX001',
          date: DateTime.now(),
          type: 'Dine In',
          menuItems: 'Ramen',
          qty: 1,
          tax: 2727,
          subtotal: 27273,
          total: 30000, // Full price
          paymentMethod: 'Voucher + Cash',
          additionalPayment: 10000,
          changes: 0,
        ),
      ];

      final totalTax = getTotalTax(transactions);
      // Expected: 10000 / (27273 + 2727) * 2727 = 10000 / 30000 * 2727 ≈ 909
      expect(totalTax, closeTo(909, 1));
    });

    test('Pure voucher and discount 100% should have 0 tax', () {
      final transactions = [
        TransactionRecord(
          trxId: 'TRX001',
          date: DateTime.now(),
          type: 'Dine In',
          menuItems: 'Free',
          qty: 1,
          tax: 1818,
          subtotal: 18182,
          total: 0,
          paymentMethod: 'Voucher',
        ),
        TransactionRecord(
          trxId: 'TRX002',
          date: DateTime.now(),
          type: 'Dine In',
          menuItems: 'Promo',
          qty: 1,
          tax: 0,
          subtotal: 0,
          total: 0,
          paymentMethod: 'Discount 100%',
        ),
      ];

      final totalTax = getTotalTax(transactions);
      expect(totalTax, 0);
    });
  });
}
