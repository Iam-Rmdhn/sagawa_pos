import 'package:sagawa_pos/features/order_history/domain/models/order_history.dart';


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

  String get transactionCountText {
    return '$transactionCount transaksi';
  }

  static List<GroupedOrderByDate> groupOrders(List<OrderHistory> orders) {
    final Map<String, List<OrderHistory>> groupedMap = {};

    for (final order in orders) {
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

    final List<GroupedOrderByDate> result = [];
    groupedMap.forEach((dateKey, orderList) {
      final date = DateTime.parse(dateKey);
      final totalAmount = orderList.fold<double>(
        0,
        (sum, order) => sum + order.receipt.subTotalFinal,
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

    result.sort((a, b) => b.date.compareTo(a.date));

    return result;
  }
}
