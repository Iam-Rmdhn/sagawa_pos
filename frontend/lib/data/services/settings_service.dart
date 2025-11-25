import 'package:shared_preferences/shared_preferences.dart';

/// Service untuk mengelola pengaturan aplikasi
class SettingsService {
  static const String _taxPrefsKey = 'tax_enabled';
  static const String _languagePrefsKey = 'app_language';
  static const String _locationPrefsKey = 'app_location';

  // Tax Settings
  /// Get tax enabled status
  static Future<bool> isTaxEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_taxPrefsKey) ?? false;
  }

  /// Set tax enabled status
  static Future<void> setTaxEnabled(bool enabled) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_taxPrefsKey, enabled);
  }

  /// Get tax rate (default 10%)
  static double getTaxRate() {
    return 0.10; // 10%
  }

  /// Calculate tax amount
  static double calculateTax(double amount) {
    return amount * getTaxRate();
  }

  /// Calculate total with tax
  static Future<double> calculateTotalWithTax(double subtotal) async {
    final taxEnabled = await isTaxEnabled();
    if (taxEnabled) {
      final tax = calculateTax(subtotal);
      return subtotal + tax;
    }
    return subtotal;
  }

  // Language Settings
  /// Get app language
  static Future<String> getLanguage() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_languagePrefsKey) ?? 'id'; // Default: Indonesian
  }

  /// Set app language
  static Future<void> setLanguage(String languageCode) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_languagePrefsKey, languageCode);
  }

  // Location Settings
  /// Get location
  static Future<String> getLocation() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_locationPrefsKey) ?? '';
  }

  /// Set location
  static Future<void> setLocation(String location) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_locationPrefsKey, location);
  }

  // Clear all settings
  static Future<void> clearAllSettings() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_taxPrefsKey);
    await prefs.remove(_languagePrefsKey);
    await prefs.remove(_locationPrefsKey);
  }
}
