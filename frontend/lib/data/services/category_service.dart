import 'package:sagawa_pos_new/core/network/api_client.dart';
import 'package:sagawa_pos_new/core/network/api_config.dart';
import 'package:sagawa_pos_new/data/services/user_service.dart';

/// Service untuk mengambil kategori menu dari database
class CategoryService {
  static final ApiClient _api = ApiClient();

  /// Mapping kategori default per kemitraan dan subBrand
  /// Digunakan sebagai fallback jika API gagal
  static const Map<String, Map<String, List<String>>> _defaultCategories = {
    // RM Nusantara dengan sub-brands
    'rm nusantara': {
      'warnas': ['Paket Ayam Bakar', 'Paket Ayam Goreng', 'Menu Harian'],
      'masgaw': [
        'Paket Ayam Goreng',
        'Paket Ayam Bakar',
        'Ala Carte',
        'Aneka Nasi',
        'Minuman',
        'Ekstra Sambel',
      ],
      'masakan mas gawa': [
        'Paket Ayam Goreng',
        'Paket Ayam Bakar',
        'Ala Carte',
        'Aneka Nasi',
        'Minuman',
        'Ekstra Sambel',
      ],
    },
    // Kagawa Ricebowl
    'kagawa ricebowl': {
      '': ['Makanan'],
    },
    // Kagawa Coffee Corner
    'kagawa coffee corner': {
      '': ['Coffee', 'Donuts', 'Non-Coffee'],
    },
    // Coffee & Ricebowl Corner
    'coffee & ricebowl corner': {
      '': ['Makanan', 'Coffee', 'Donuts', 'Non-Coffee'],
    },
  };

  /// Normalize string untuk perbandingan
  static String _normalize(String s) {
    return s.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]'), '').trim();
  }

  /// Mendapatkan kategori dari API berdasarkan kemitraan dan subBrand user
  static Future<List<String>> getCategories() async {
    try {
      final user = await UserService.getUser();
      if (user == null) {
        print('DEBUG CategoryService: No user logged in');
        return ['Semua'];
      }

      final kemitraan = user.kemitraan;
      final subBrand = user.subBrand ?? '';

      print(
        'DEBUG CategoryService: Fetching categories for kemitraan=$kemitraan, subBrand=$subBrand',
      );

      // Build query params
      String queryParams = '';
      if (subBrand.isNotEmpty) {
        queryParams = '?subBrand=${Uri.encodeComponent(subBrand)}';
      } else if (kemitraan.isNotEmpty) {
        queryParams = '?kemitraan=${Uri.encodeComponent(kemitraan)}';
      }

      final response = await _api.get(
        '${ApiConfig.menuCategories}$queryParams',
      );

      if (response.statusCode == 200) {
        final data = response.data;
        List<String> categories = ['Semua']; // Always add "Semua" as first

        if (data != null && data['categories'] != null) {
          final apiCategories = List<String>.from(data['categories']);
          categories.addAll(apiCategories);
          print(
            'DEBUG CategoryService: Got ${apiCategories.length} categories from API',
          );
        }

        return categories;
      }
    } catch (e) {
      print('DEBUG CategoryService: Error fetching categories: $e');
    }

    // Fallback ke default categories
    return await _getDefaultCategories();
  }

  /// Mendapatkan kategori default berdasarkan kemitraan user
  static Future<List<String>> _getDefaultCategories() async {
    try {
      final user = await UserService.getUser();
      if (user == null) {
        return ['Semua'];
      }

      final kemitraan = _normalize(user.kemitraan);
      final subBrand = _normalize(user.subBrand ?? '');

      print(
        'DEBUG CategoryService: Using default categories for kemitraan=$kemitraan, subBrand=$subBrand',
      );

      // Cari kategori yang cocok
      for (final entry in _defaultCategories.entries) {
        final normalizedKey = _normalize(entry.key);
        if (kemitraan.contains(normalizedKey) ||
            normalizedKey.contains(kemitraan)) {
          final subBrandMap = entry.value;

          // Jika ada subBrand, cari yang cocok
          if (subBrand.isNotEmpty) {
            for (final subEntry in subBrandMap.entries) {
              final normalizedSubKey = _normalize(subEntry.key);
              if (subBrand.contains(normalizedSubKey) ||
                  normalizedSubKey.contains(subBrand)) {
                final categories = ['Semua', ...subEntry.value];
                print(
                  'DEBUG CategoryService: Found default categories: $categories',
                );
                return categories;
              }
            }
          }

          // Jika tidak ada subBrand atau tidak cocok, ambil yang pertama
          final firstCategories = subBrandMap.values.first;
          final categories = ['Semua', ...firstCategories];
          print('DEBUG CategoryService: Found default categories: $categories');
          return categories;
        }
      }
    } catch (e) {
      print('DEBUG CategoryService: Error getting default categories: $e');
    }

    return ['Semua'];
  }

  /// Mendapatkan icon untuk kategori
  static String getCategoryIcon(String category) {
    final normalized = _normalize(category);

    // Icon mapping
    if (normalized.contains('ayambakar')) return '🍗';
    if (normalized.contains('ayamgoreng')) return '🍗';
    if (normalized.contains('paket')) return '🍱';
    if (normalized.contains('alacarte')) return '🍽️';
    if (normalized.contains('anekanasi') || normalized.contains('nasi'))
      return '🍚';
    if (normalized.contains('minuman')) return '🥤';
    if (normalized.contains('coffee') || normalized.contains('kopi'))
      return '☕';
    if (normalized.contains('noncoffee')) return '🧋';
    if (normalized.contains('donut')) return '🍩';
    if (normalized.contains('makanan')) return '🍔';
    if (normalized.contains('sambel') || normalized.contains('sambal'))
      return '🌶️';
    if (normalized.contains('menu') && normalized.contains('harian'))
      return '📅';
    if (normalized.contains('semua')) return '📋';

    return '🍴';
  }
}
