import 'package:sagawa_pos_new/features/order_history/domain/models/order_history.dart';

/// Model untuk order yang dikelompokkan berdasarkan tanggal
class GroupedOrderByDate {
  final DateTime date;
  final int transactionCount;
  final double totalAmount;
  final List<OrderHistory> orders;

  GroupedOrderByDate({
    required this.date,
    required this.transactionCount,
    required this.totalAmount,
    required this.orders,
  });

  /// Format tanggal Indonesia (Senin, 2 Desember 2025)
  String get formattedDate {
    const dayNames = [
      'Senin',
      'Selasa',
      'Rabu',
      'Kamis',
      'Jumat',
      'Sabtu',
      'Minggu',
    ];
    const monthNames = [
      'Januari',
      'Februari',
      'Maret',
      'April',
      'Mei',
      'Juni',
      'Juli',
      'Agustus',
      'September',
      'Oktober',
      'November',
      'Desember',
    ];

    final dayName = dayNames[date.weekday - 1];
    final day = date.day;
    final monthName = monthNames[date.month - 1];
    final year = date.year;

    return '$dayName, $day $monthName $year';
  }

  /// Format tanggal pendek (Sabtu, 6 Desember 2025)
  String get shortFormattedDate {
    const dayNames = [
      'Senin',
      'Selasa',
      'Rabu',
      'Kamis',
      'Jumat',
      'Sabtu',
      'Minggu',
    ];
    const monthNames = [
      'Januari',
      'Februari',
      'Maret',
      'April',
      'Mei',
      'Juni',
      'Juli',
      'Agustus',
      'September',
      'Oktober',
      'November',
      'Desember',
    ];

    final dayName = dayNames[date.weekday - 1];
    final day = date.day;
    final monthName = monthNames[date.month - 1];
    final year = date.year;

    return '$dayName, $day $monthName $year';
  }

  /// Format amount dengan Rp
  String get formattedAmount {
    final formatter = totalAmount.toStringAsFixed(0);
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

  /// Text untuk jumlah transaksi
  String get transactionCountText {
    return '$transactionCount transaksi';
  }

  /// Group orders by date dari list OrderHistory
  static List<GroupedOrderByDate> groupOrders(List<OrderHistory> orders) {
    // Map untuk menyimpan orders berdasarkan tanggal
    final Map<String, List<OrderHistory>> groupedMap = {};

    for (final order in orders) {
      // Gunakan format YYYY-MM-DD sebagai key
      final dateKey = DateTime(
        order.date.year,
        order.date.month,
        order.date.day,
      ).toIso8601String().split('T')[0];

      if (!groupedMap.containsKey(dateKey)) {
        groupedMap[dateKey] = [];
      }
      groupedMap[dateKey]!.add(order);
    }

    // Convert map ke list GroupedOrderByDate
    final List<GroupedOrderByDate> result = [];
    groupedMap.forEach((dateKey, orderList) {
      final date = DateTime.parse(dateKey);
      final totalAmount = orderList.fold<double>(
        0,
        (sum, order) => sum + order.totalAmount,
      );

      result.add(
        GroupedOrderByDate(
          date: date,
          transactionCount: orderList.length,
          totalAmount: totalAmount,
          orders: orderList,
        ),
      );
    });

    // Sort descending (tanggal terbaru di atas)
    result.sort((a, b) => b.date.compareTo(a.date));

    return result;
  }
}
