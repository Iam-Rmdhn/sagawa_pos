import 'package:intl/intl.dart';

class CurrencyHelper {
  static String formatIDR(double amount) {
    final formatter = NumberFormat.currency(
      locale: 'id_ID',
      symbol: 'Rp ',
      decimalDigits: 0,
    );
    return formatter.format(amount);
  }

  static String formatNumber(double number) {
    final formatter = NumberFormat('#,##0', 'id_ID');
    return formatter.format(number);
  }
}

class DateHelper {
  static String formatDate(DateTime date) {
    return DateFormat('dd MMM yyyy', 'id_ID').format(date);
  }

  static String formatDateTime(DateTime date) {
    return DateFormat('dd MMM yyyy HH:mm', 'id_ID').format(date);
  }

  static String formatTime(DateTime date) {
    return DateFormat('HH:mm', 'id_ID').format(date);
  }

  static String timeAgo(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays > 365) {
      return '${(difference.inDays / 365).floor()} tahun lalu';
    } else if (difference.inDays > 30) {
      return '${(difference.inDays / 30).floor()} bulan lalu';
    } else if (difference.inDays > 0) {
      return '${difference.inDays} hari lalu';
    } else if (difference.inHours > 0) {
      return '${difference.inHours} jam lalu';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes} menit lalu';
    } else {
      return 'Baru saja';
    }
  }
}

class ValidationHelper {
  static bool isValidEmail(String email) {
    final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
    return emailRegex.hasMatch(email);
  }

  static bool isValidPhone(String phone) {
    final phoneRegex = RegExp(r'^(\+62|62|0)[0-9]{9,12}$');
    return phoneRegex.hasMatch(phone);
  }

  static bool isValidPrice(String price) {
    try {
      final value = double.parse(price);
      return value >= 0;
    } catch (e) {
      return false;
    }
  }

  static bool isValidStock(String stock) {
    try {
      final value = int.parse(stock);
      return value >= 0;
    } catch (e) {
      return false;
    }
  }
}
