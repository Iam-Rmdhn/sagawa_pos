import 'package:intl/intl.dart';

/// Utility class untuk menangani waktu Indonesia
/// WIB (UTC+7), WITA (UTC+8), WIT (UTC+9)
class IndonesiaTime {
  // Timezone offsets
  static const int wibOffset = 7; // Jakarta, Bandung, Surabaya
  static const int witaOffset = 8; // Makassar, Bali, Pontianak
  static const int witOffset = 9; // Jayapura, Ambon

  // Default menggunakan WIB (Waktu Indonesia Barat)
  static int _currentOffset = wibOffset;

  /// Set timezone yang digunakan
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

  /// Get current offset
  static int get currentOffset => _currentOffset;

  /// Get current timezone label
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

  /// Mendapatkan waktu Indonesia saat ini
  /// Mengkonversi dari UTC ke timezone Indonesia yang dipilih
  static DateTime now() {
    final utcNow = DateTime.now().toUtc();
    return utcNow.add(Duration(hours: _currentOffset));
  }

  /// Konversi DateTime ke waktu Indonesia
  static DateTime toIndonesiaTime(DateTime dateTime) {
    // Jika sudah dalam UTC, langsung tambahkan offset
    if (dateTime.isUtc) {
      return dateTime.add(Duration(hours: _currentOffset));
    }
    // Jika local time, konversi ke UTC dulu lalu tambah offset Indonesia
    final utc = dateTime.toUtc();
    return utc.add(Duration(hours: _currentOffset));
  }

  /// Parse string tanggal dan konversi ke waktu Indonesia
  static DateTime? parseToIndonesiaTime(String dateString) {
    try {
      final parsed = DateTime.parse(dateString);
      return toIndonesiaTime(parsed);
    } catch (e) {
      return null;
    }
  }

  /// Format tanggal dengan format Indonesia
  static String formatDate(DateTime dateTime, {String pattern = 'dd/MM/yyyy'}) {
    return DateFormat(pattern, 'id_ID').format(dateTime);
  }

  /// Format waktu dengan format Indonesia
  static String formatTime(DateTime dateTime, {String pattern = 'HH:mm'}) {
    return DateFormat(pattern, 'id_ID').format(dateTime);
  }

  /// Format tanggal dan waktu lengkap
  static String formatDateTime(
    DateTime dateTime, {
    String pattern = 'dd/MM/yyyy HH:mm',
  }) {
    return DateFormat(pattern, 'id_ID').format(dateTime);
  }

  /// Format tanggal untuk display dengan nama hari
  static String formatDisplayDate(DateTime dateTime) {
    return DateFormat('EEEE, dd MMMM yyyy', 'id_ID').format(dateTime);
  }

  /// Format waktu pendek (untuk struk)
  static String formatShortDateTime(DateTime dateTime) {
    return DateFormat('dd/MM/yyyy HH:mm', 'id_ID').format(dateTime);
  }

  /// Mendapatkan awal hari (00:00:00) dalam waktu Indonesia
  static DateTime startOfDay([DateTime? date]) {
    final d = date ?? now();
    return DateTime(d.year, d.month, d.day);
  }

  /// Mendapatkan akhir hari (23:59:59) dalam waktu Indonesia
  static DateTime endOfDay([DateTime? date]) {
    final d = date ?? now();
    return DateTime(d.year, d.month, d.day, 23, 59, 59);
  }

  /// Mendapatkan awal minggu (Senin) dalam waktu Indonesia
  static DateTime startOfWeek([DateTime? date]) {
    final d = date ?? now();
    final weekday = d.weekday;
    return DateTime(
      d.year,
      d.month,
      d.day,
    ).subtract(Duration(days: weekday - 1));
  }

  /// Mendapatkan akhir minggu (Minggu) dalam waktu Indonesia
  static DateTime endOfWeek([DateTime? date]) {
    final start = startOfWeek(date);
    return start.add(
      const Duration(days: 6, hours: 23, minutes: 59, seconds: 59),
    );
  }

  /// Mendapatkan awal bulan dalam waktu Indonesia
  static DateTime startOfMonth([DateTime? date]) {
    final d = date ?? now();
    return DateTime(d.year, d.month, 1);
  }

  /// Mendapatkan akhir bulan dalam waktu Indonesia
  static DateTime endOfMonth([DateTime? date]) {
    final d = date ?? now();
    return DateTime(d.year, d.month + 1, 0, 23, 59, 59);
  }

  /// Cek apakah dua tanggal adalah hari yang sama
  static bool isSameDay(DateTime date1, DateTime date2) {
    return date1.year == date2.year &&
        date1.month == date2.month &&
        date1.day == date2.day;
  }

  /// Cek apakah tanggal adalah hari ini
  static bool isToday(DateTime date) {
    return isSameDay(date, now());
  }

  /// Cek apakah tanggal adalah kemarin
  static bool isYesterday(DateTime date) {
    final yesterday = now().subtract(const Duration(days: 1));
    return isSameDay(date, yesterday);
  }

  /// Get nama hari dalam bahasa Indonesia
  static String getDayName(DateTime date) {
    return DateFormat('EEEE', 'id_ID').format(date);
  }

  /// Get nama bulan dalam bahasa Indonesia
  static String getMonthName(DateTime date) {
    return DateFormat('MMMM', 'id_ID').format(date);
  }

  /// Get nama hari pendek dalam bahasa Indonesia
  static String getShortDayName(DateTime date) {
    const days = ['Sen', 'Sel', 'Rab', 'Kam', 'Jum', 'Sab', 'Min'];
    return days[date.weekday - 1];
  }

  /// Get nama bulan pendek dalam bahasa Indonesia
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

/// Enum untuk timezone Indonesia
enum IndonesiaTimezone {
  wib, // Waktu Indonesia Barat (UTC+7)
  wita, // Waktu Indonesia Tengah (UTC+8)
  wit, // Waktu Indonesia Timur (UTC+9)
}
