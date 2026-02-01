class FinancialReport {
  final double dailyRevenue;
  final double weeklyRevenue;
  final double monthlyRevenue;
  final int dineInCount;
  final int takeAwayCount;
  final List<DailyRevenue> dailyRevenueList;
  final int totalOrders;
  final List<TransactionRecord> transactions;

  final double totalRevenue;
  final double cashRevenue;
  final double qrisRevenue;
  final double voucherRevenue;
  final double discountRevenue;
  final int cashCount;
  final int qrisCount;
  final int voucherCount;
  final int discountCount;

  final double totalTax;

  FinancialReport({
    required this.dailyRevenue,
    required this.weeklyRevenue,
    required this.monthlyRevenue,
    required this.dineInCount,
    required this.takeAwayCount,
    required this.dailyRevenueList,
    required this.totalOrders,
    this.transactions = const [],
    this.totalRevenue = 0,
    this.cashRevenue = 0,
    this.qrisRevenue = 0,
    this.voucherRevenue = 0,
    this.discountRevenue = 0,
    this.cashCount = 0,
    this.qrisCount = 0,
    this.voucherCount = 0,
    this.discountCount = 0,
    this.totalTax = 0,
  });

  double get dineInPercentage {
    final total = dineInCount + takeAwayCount;
    if (total == 0) return 0;
    return (dineInCount / total) * 100;
  }

  double get takeAwayPercentage {
    final total = dineInCount + takeAwayCount;
    if (total == 0) return 0;
    return (takeAwayCount / total) * 100;
  }

  static String formatCurrency(double value) {
    final formatter = value.toStringAsFixed(0);
    final parts = <String>[];
    var remaining = formatter;

    while (remaining.length > 3) {
      parts.insert(0, remaining.substring(remaining.length - 3));
      remaining = remaining.substring(0, remaining.length - 3);
    }
    if (remaining.isNotEmpty) {
      parts.insert(0, remaining);
    }

    return 'Rp ${parts.join('.')}';
  }

  static String formatShortCurrency(double value) {
    if (value >= 1000000) {
      return 'Rp ${(value / 1000000).toStringAsFixed(1)}jt';
    } else if (value >= 1000) {
      return 'Rp ${(value / 1000).toStringAsFixed(0)}rb';
    }
    return 'Rp ${value.toStringAsFixed(0)}';
  }

  static String formatNumberOnly(double value) {
    final formatter = value.toStringAsFixed(0);
    final parts = <String>[];
    var remaining = formatter;

    while (remaining.length > 3) {
      parts.insert(0, remaining.substring(remaining.length - 3));
      remaining = remaining.substring(0, remaining.length - 3);
    }
    if (remaining.isNotEmpty) {
      parts.insert(0, remaining);
    }

    return parts.join('.');
  }
}

class DailyRevenue {
  final DateTime date;
  final double revenue;
  final int orderCount;

  DailyRevenue({
    required this.date,
    required this.revenue,
    required this.orderCount,
  });

  String get shortDate {
    final day = date.day.toString().padLeft(2, '0');
    final month = date.month.toString().padLeft(2, '0');
    return '$day/$month';
  }

  String get dayName {
    const days = ['Sen', 'Sel', 'Rab', 'Kam', 'Jum', 'Sab', 'Min'];
    return days[date.weekday - 1];
  }
}

class TransactionRecord {
  final String trxId;
  final DateTime date;
  final String type;
  final String menuItems;
  final int qty;
  final double tax;
  final double subtotal;
  final double total;
  final String? _paymentMethod;

  final double? voucherAmount;
  final double? additionalPayment;
  final double? changes;

  final int? discountPercent;
  final double? discountAmount;

  TransactionRecord({
    required this.trxId,
    required this.date,
    required this.type,
    required this.menuItems,
    required this.qty,
    required this.tax,
    required this.subtotal,
    required this.total,
    String? paymentMethod,
    this.voucherAmount,
    this.additionalPayment,
    this.changes,
    this.discountPercent,
    this.discountAmount,
  }) : _paymentMethod = paymentMethod;

  String get paymentMethod => _paymentMethod ?? 'Cash';

  bool get isVoucherPayment => paymentMethod.toLowerCase().contains('voucher');

  bool get isDiscountPayment =>
      paymentMethod.toLowerCase().contains('discount');

  double get totalPotongan {
    if (isVoucherPayment) {
      if (voucherAmount != null && voucherAmount! > 0) {
        return voucherAmount!;
      }

      if (tax > 0 && tax < (subtotal * 0.10)) {
        final subtotalAfterVoucher = tax / 0.10;
        final estimatedVoucher = subtotal - subtotalAfterVoucher;
        if (estimatedVoucher > 0 && estimatedVoucher <= subtotal) {
          return estimatedVoucher;
        }
      }

      if (total > 0 && total < (subtotal * 1.1)) {
        final subtotalAfterVoucher = total / 1.1;
        final estimatedVoucher = subtotal - subtotalAfterVoucher;
        if (estimatedVoucher > 0 && estimatedVoucher <= subtotal) {
          return estimatedVoucher;
        }
      }
      return 0.0;
    }
    if (isDiscountPayment) {
      if (discountAmount != null && discountAmount! > 0) {
        return discountAmount!;
      }

      if (discountPercent != null && discountPercent! > 0) {
        return (subtotal * discountPercent! / 100);
      }

      if (tax > 0 && tax < (subtotal * 0.10)) {
        final subtotalAfterDiscount = tax / 0.10;
        final estimatedDiscount = subtotal - subtotalAfterDiscount;
        if (estimatedDiscount > 0 && estimatedDiscount <= subtotal) {
          return estimatedDiscount;
        }
      }

      if (total > 0 && total < (subtotal * 1.1)) {
        final subtotalAfterDiscount = total / 1.1;
        final estimatedDiscount = subtotal - subtotalAfterDiscount;
        if (estimatedDiscount > 0 && estimatedDiscount <= subtotal) {
          return estimatedDiscount;
        }
      }
      return 0.0;
    }
    return 0.0;
  }

  double get subtotalSetelahPotongan {
    final result = subtotal - totalPotongan;
    return result > 0 ? result : 0.0;
  }

  double get calculatedTax {
    if (totalPotongan > 0) {
      return subtotalSetelahPotongan * 0.10;
    }
    return tax;
  }

  double get calculatedTotal {
    if (totalPotongan > 0) {
      return subtotalSetelahPotongan + calculatedTax;
    }
    return subtotal + tax;
  }

  String get formattedDate {
    final day = date.day.toString().padLeft(2, '0');
    final month = date.month.toString().padLeft(2, '0');
    final year = date.year;
    final hour = date.hour.toString().padLeft(2, '0');
    final minute = date.minute.toString().padLeft(2, '0');
    return '$day/$month/$year $hour:$minute';
  }

  String get shortFormattedDate {
    final day = date.day.toString().padLeft(2, '0');
    final month = date.month.toString().padLeft(2, '0');
    final year = date.year;
    final hour = date.hour.toString().padLeft(2, '0');
    final minute = date.minute.toString().padLeft(2, '0');
    return '$day/$month/$year $hour:$minute';
  }

  List<String> toCsvRow() {
    return [
      trxId,
      formattedDate,
      type,
      paymentMethod,
      menuItems,
      qty.toString(),
      tax.toStringAsFixed(0),
      subtotal.toStringAsFixed(0),
      total.toStringAsFixed(0),
    ];
  }

  static List<String> get csvHeaders => [
    'Trx ID',
    'Date',
    'Type',
    'Payment',
    'Menu',
    'Qty',
    'Tax',
    'Subtotal',
    'Total',
  ];
}

enum ReportPeriod { daily, weekly, monthly }

extension ReportPeriodExtension on ReportPeriod {
  String get label {
    switch (this) {
      case ReportPeriod.daily:
        return 'Harian';
      case ReportPeriod.weekly:
        return 'Mingguan';
      case ReportPeriod.monthly:
        return 'Bulanan';
    }
  }
}

enum TableFilter { daily, monthly }

extension TableFilterExtension on TableFilter {
  String get label {
    switch (this) {
      case TableFilter.daily:
        return 'Harian';
      case TableFilter.monthly:
        return 'Bulanan';
    }
  }
}
