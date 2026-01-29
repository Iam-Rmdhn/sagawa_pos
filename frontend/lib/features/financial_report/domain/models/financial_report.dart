/// Model untuk data laporan keuangan
class FinancialReport {
  final double dailyRevenue;
  final double weeklyRevenue;
  final double monthlyRevenue;
  final int dineInCount;
  final int takeAwayCount;
  final List<DailyRevenue> dailyRevenueList;
  final int totalOrders;
  final List<TransactionRecord> transactions;
  // Payment method stats
  final double totalRevenue; // Total pendapatan keseluruhan
  final double cashRevenue; // Pendapatan Cash + Voucher+Cash + Discount+Cash
  final double qrisRevenue; // Pendapatan QRIS + Voucher+QRIS + Discount+QRIS
  final double voucherRevenue; // Tidak digunakan (0)
  final double discountRevenue; // Tidak digunakan (0)
  final int cashCount;
  final int qrisCount;
  final int voucherCount;
  final int discountCount;
  // Tax stats
  final double totalTax; // Total PB1 dari semua transaksi

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

  /// Persentase Dine In
  double get dineInPercentage {
    final total = dineInCount + takeAwayCount;
    if (total == 0) return 0;
    return (dineInCount / total) * 100;
  }

  /// Persentase Take Away
  double get takeAwayPercentage {
    final total = dineInCount + takeAwayCount;
    if (total == 0) return 0;
    return (takeAwayCount / total) * 100;
  }

  /// Format currency
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

  /// Format currency untuk label chart (lebih pendek)
  static String formatShortCurrency(double value) {
    if (value >= 1000000) {
      return 'Rp ${(value / 1000000).toStringAsFixed(1)}jt';
    } else if (value >= 1000) {
      return 'Rp ${(value / 1000).toStringAsFixed(0)}rb';
    }
    return 'Rp ${value.toStringAsFixed(0)}';
  }

  /// Format number only (tanpa Rp, untuk tabel)
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

/// Model untuk revenue harian (untuk line chart)
class DailyRevenue {
  final DateTime date;
  final double revenue;
  final int orderCount;

  DailyRevenue({
    required this.date,
    required this.revenue,
    required this.orderCount,
  });

  /// Format tanggal pendek (dd/MM)
  String get shortDate {
    final day = date.day.toString().padLeft(2, '0');
    final month = date.month.toString().padLeft(2, '0');
    return '$day/$month';
  }

  /// Nama hari
  String get dayName {
    const days = ['Sen', 'Sel', 'Rab', 'Kam', 'Jum', 'Sab', 'Min'];
    return days[date.weekday - 1];
  }
}

/// Model untuk record transaksi (untuk tabel)
class TransactionRecord {
  final String trxId;
  final DateTime date;
  final String type;
  final String menuItems;
  final int qty;
  final double tax;
  final double subtotal;
  final double total;
  final String?
  _paymentMethod; // Cash, QRIS, Voucher, Voucher + Cash, Voucher + QRIS
  // Voucher fields for accurate revenue calculation
  final double? voucherAmount;
  final double? additionalPayment;
  final double? changes; // Kembalian
  // Discount fields for accurate revenue calculation
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

  /// Check if this is a voucher payment
  bool get isVoucherPayment => paymentMethod.toLowerCase().contains('voucher');

  /// Check if this is a discount payment
  bool get isDiscountPayment =>
      paymentMethod.toLowerCase().contains('discount');

  /// Get total potongan (voucher atau discount)
  /// Dengan fallback estimation jika voucherAmount tidak tersedia
  double get totalPotongan {
    if (isVoucherPayment) {
      // PRIORITAS 1: voucherAmount langsung dari data
      if (voucherAmount != null && voucherAmount! > 0) {
        return voucherAmount!;
      }
      // PRIORITAS 2: Estimasi dari tax yang tercatat
      // Jika tax < subtotal * 0.1, berarti ada potongan
      // tax = subtotalSetelahPotongan × 0.1
      // subtotalSetelahPotongan = tax / 0.1
      // potongan = subtotal - subtotalSetelahPotongan
      if (tax > 0 && tax < (subtotal * 0.10)) {
        final subtotalAfterVoucher = tax / 0.10;
        final estimatedVoucher = subtotal - subtotalAfterVoucher;
        if (estimatedVoucher > 0 && estimatedVoucher <= subtotal) {
          return estimatedVoucher;
        }
      }
      // PRIORITAS 3: Estimasi dari total (afterTax) jika tax tidak akurat
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
      // PRIORITAS 1: discountAmount langsung dari data
      if (discountAmount != null && discountAmount! > 0) {
        return discountAmount!;
      }
      // PRIORITAS 2: Hitung dari discountPercent jika tersedia
      if (discountPercent != null && discountPercent! > 0) {
        return (subtotal * discountPercent! / 100);
      }
      // PRIORITAS 3: Estimasi dari tax yang tercatat
      if (tax > 0 && tax < (subtotal * 0.10)) {
        final subtotalAfterDiscount = tax / 0.10;
        final estimatedDiscount = subtotal - subtotalAfterDiscount;
        if (estimatedDiscount > 0 && estimatedDiscount <= subtotal) {
          return estimatedDiscount;
        }
      }
      // PRIORITAS 4: Estimasi dari total (afterTax)
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

  /// Get subtotal setelah potongan
  double get subtotalSetelahPotongan {
    final result = subtotal - totalPotongan;
    return result > 0 ? result : 0.0;
  }

  /// Get calculated tax (10% dari subtotal setelah potongan)
  double get calculatedTax {
    if (totalPotongan > 0) {
      return subtotalSetelahPotongan * 0.10;
    }
    return tax;
  }

  /// Get calculated total (subtotal setelah potongan + tax)
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

  /// Convert to CSV row
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

  /// CSV Headers
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

/// Enum untuk periode filter
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

/// Enum untuk filter tabel transaksi
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
