import 'package:sagawa_pos_new/features/receipt/domain/models/receipt.dart';

/// Model untuk Order History
class OrderHistory {
  final String id;
  final String trxId;
  final DateTime date;
  final double totalAmount;
  final String status; // 'completed', 'cancelled'
  final Receipt receipt;

  OrderHistory({
    required this.id,
    required this.trxId,
    required this.date,
    required this.totalAmount,
    required this.status,
    required this.receipt,
  });

  /// Format tanggal untuk display (dd/MM/yyyy HH:mm)
  String get formattedDate {
    final day = date.day.toString().padLeft(2, '0');
    final month = date.month.toString().padLeft(2, '0');
    final year = date.year;
    final hour = date.hour.toString().padLeft(2, '0');
    final minute = date.minute.toString().padLeft(2, '0');
    return '$day/$month/$year $hour:$minute';
  }

  /// Format tanggal pendek (dd MMM yyyy)
  String get shortFormattedDate {
    const monthNames = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'Mei',
      'Jun',
      'Jul',
      'Agu',
      'Sep',
      'Oct',
      'Nov',
      'Des',
    ];
    final day = date.day.toString().padLeft(2, '0');
    final month = monthNames[date.month - 1];
    final year = date.year;
    return '$day $month $year';
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

  factory OrderHistory.fromJson(Map<String, dynamic> json) {
    return OrderHistory(
      id: json['id'] as String,
      trxId: json['trxId'] as String,
      date: DateTime.parse(json['date'] as String),
      totalAmount: (json['totalAmount'] as num).toDouble(),
      status: json['status'] as String,
      receipt: Receipt.fromJson(json['receipt'] as Map<String, dynamic>),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'trxId': trxId,
      'date': date.toIso8601String(),
      'totalAmount': totalAmount,
      'status': status,
      'receipt': receipt.toJson(),
    };
  }
}
