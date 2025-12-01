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

  FinancialReport({
    required this.dailyRevenue,
    required this.weeklyRevenue,
    required this.monthlyRevenue,
    required this.dineInCount,
    required this.takeAwayCount,
    required this.dailyRevenueList,
    required this.totalOrders,
    this.transactions = const [],
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

  TransactionRecord({
    required this.trxId,
    required this.date,
    required this.type,
    required this.menuItems,
    required this.qty,
    required this.tax,
    required this.subtotal,
    required this.total,
  });

  /// Format tanggal untuk display
  String get formattedDate {
    final day = date.day.toString().padLeft(2, '0');
    final month = date.month.toString().padLeft(2, '0');
    final year = date.year;
    final hour = date.hour.toString().padLeft(2, '0');
    final minute = date.minute.toString().padLeft(2, '0');
    return '$day/$month/$year $hour:$minute';
  }

  /// Format tanggal pendek
  String get shortFormattedDate {
    final day = date.day.toString().padLeft(2, '0');
    final month = date.month.toString().padLeft(2, '0');
    final year = date.year;
    return '$day/$month/$year';
  }

  /// Convert to CSV row
  List<String> toCsvRow() {
    return [
      trxId,
      formattedDate,
      type,
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
