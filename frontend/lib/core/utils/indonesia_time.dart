import 'package:intl/intl.dart';
class IndonesiaTime {
  static const int wibOffset = 7; 
  static const int witaOffset = 8; 
  static const int witOffset = 9; 

  static int _currentOffset = wibOffset;

  static void setTimezone(IndonesiaTimezone timezone) {
    switch (timezone) {
      case IndonesiaTimezone.wib:
        _currentOffset = wibOffset;
        break;
      case IndonesiaTimezone.wita:
        _currentOffset = witaOffset;
        break;
      case IndonesiaTimezone.wit:
        _currentOffset = witOffset;
        break;
    }
  }
  static int get currentOffset => _currentOffset;
  static String get timezoneLabel {
    switch (_currentOffset) {
      case wibOffset:
        return 'WIB';
      case witaOffset:
        return 'WITA';
      case witOffset:
        return 'WIT';
      default:
        return 'WIB';
    }
  }

  static DateTime now() {   
    final utcNow = DateTime.now().toUtc();
    return DateTime(
      utcNow.year,
      utcNow.month,
      utcNow.day,
      utcNow.hour + _currentOffset,
      utcNow.minute,
      utcNow.second,
      utcNow.millisecond,
    );
  }

  static DateTime toIndonesiaTime(DateTime dateTime) {
    DateTime utcTime;
    if (dateTime.isUtc) {
      utcTime = dateTime;
    } else {
      utcTime = dateTime.toUtc();
    }
    return DateTime(
      utcTime.year,
      utcTime.month,
      utcTime.day,
      utcTime.hour + _currentOffset,
      utcTime.minute,
      utcTime.second,
      utcTime.millisecond,
    );
  }

  static DateTime toUtc(DateTime indonesiaTime) {
    return DateTime.utc(
      indonesiaTime.year,
      indonesiaTime.month,
      indonesiaTime.day,
      indonesiaTime.hour - _currentOffset,
      indonesiaTime.minute,
      indonesiaTime.second,
      indonesiaTime.millisecond,
    );
  }

  static DateTime? parseToIndonesiaTime(String dateString) {
    try {
      final parsed = DateTime.parse(dateString);
      return toIndonesiaTime(parsed);
    } catch (e) {
      return null;
    }
  }

  static DateTime? parseAsIndonesiaTime(String dateString) {
    try {
      return DateTime.parse(dateString);
    } catch (e) {
      return null;
    }
  }
  static String formatDate(DateTime dateTime, {String pattern = 'dd/MM/yyyy'}) {
    return DateFormat(pattern, 'id_ID').format(dateTime);
  }

  static String formatTime(DateTime dateTime, {String pattern = 'HH:mm'}) {
    return DateFormat(pattern, 'id_ID').format(dateTime);
  }

  static String formatDateTime(
    DateTime dateTime, {
    String pattern = 'dd/MM/yyyy HH:mm',
  }) {
    return DateFormat(pattern, 'id_ID').format(dateTime);
  }

  static String formatDisplayDate(DateTime dateTime) {
    return DateFormat('EEEE, dd MMMM yyyy', 'id_ID').format(dateTime);
  }

  static String formatShortDateTime(DateTime dateTime) {
    return DateFormat('dd/MM/yyyy HH:mm', 'id_ID').format(dateTime);
  }
  static DateTime startOfDay([DateTime? date]) {
    final d = date ?? now();
    return DateTime(d.year, d.month, d.day);
  }

  static DateTime endOfDay([DateTime? date]) {
    final d = date ?? now();
    return DateTime(d.year, d.month, d.day, 23, 59, 59);
  }

  static DateTime startOfWeek([DateTime? date]) {
    final d = date ?? now();
    final weekday = d.weekday;
    return DateTime(
      d.year,
      d.month,
      d.day,
    ).subtract(Duration(days: weekday - 1));
  }

  static DateTime endOfWeek([DateTime? date]) {
    final start = startOfWeek(date);
    return start.add(
      const Duration(days: 6, hours: 23, minutes: 59, seconds: 59),
    );
  }

  static DateTime startOfMonth([DateTime? date]) {
    final d = date ?? now();
    return DateTime(d.year, d.month, 1);
  }

  static DateTime endOfMonth([DateTime? date]) {
    final d = date ?? now();
    return DateTime(d.year, d.month + 1, 0, 23, 59, 59);
  }
  static bool isSameDay(DateTime date1, DateTime date2) {
    return date1.year == date2.year &&
        date1.month == date2.month &&
        date1.day == date2.day;
  }
  static bool isToday(DateTime date) {
    return isSameDay(date, now());
  }

  static bool isYesterday(DateTime date) {
    final yesterday = now().subtract(const Duration(days: 1));
    return isSameDay(date, yesterday);
  }

  static String getDayName(DateTime date) {
    return DateFormat('EEEE', 'id_ID').format(date);
  }

  static String getMonthName(DateTime date) {
    return DateFormat('MMMM', 'id_ID').format(date);
  }

  static String getShortDayName(DateTime date) {
    const days = ['Sen', 'Sel', 'Rab', 'Kam', 'Jum', 'Sab', 'Min'];
    return days[date.weekday - 1];
  }

  static String getShortMonthName(int month) {
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'Mei',
      'Jun',
      'Jul',
      'Agu',
      'Sep',
      'Okt',
      'Nov',
      'Des',
    ];
    return months[month - 1];
  }
}

enum IndonesiaTimezone {
  wib, 
  wita, 
  wit, 
}
