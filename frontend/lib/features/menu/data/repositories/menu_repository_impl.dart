import 'package:sagawa_pos_new/core/network/api_client.dart';
import 'package:sagawa_pos_new/core/network/api_config.dart';
import 'package:sagawa_pos_new/features/menu/domain/models/menu_item.dart';
import 'package:sagawa_pos_new/features/menu/domain/repositories/menu_repository.dart';
import 'package:sagawa_pos_new/data/services/user_service.dart';
import 'package:sagawa_pos_new/features/profile/domain/models/user_model.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

class MenuRepositoryImpl implements MenuRepository {
  final ApiClient _apiClient;
  static const String _menuStateKey = 'menu_state';

  MenuRepositoryImpl({ApiClient? apiClient})
    : _apiClient = apiClient ?? ApiClient();

  @override
  Future<List<MenuItem>> getMenuItems() async {
    try {
      final response = await _apiClient.get(ApiConfig.menu);
      final data = response.data;

      // Get current user for filtering
      final UserModel? user = await UserService.getUser();

      // Normalize items to list
      List items = [];
      if (data is List) {
        items = data;
      } else if (data is Map && data['data'] is List) {
        items = data['data'] as List;
      }

      // Filter by partnership if user exists
      if (user != null) {
        items = items.where((item) => _matchesPartnership(item, user)).toList();
      }

      // Map to MenuItem objects
      final menuItems = items
          .map((e) => MenuItem.fromJson(e as Map<String, dynamic>))
          .toList();

      // Load saved state from local storage
      final savedState = await _loadMenuState();

      // Merge with saved state
      return menuItems.map((item) {
        final savedItem = savedState[item.id];
        if (savedItem != null) {
          return item.copyWith(
            isEnabled: savedItem['isEnabled'] as bool? ?? item.isEnabled,
            stock: savedItem['stock'] as int? ?? item.stock,
            isBestSeller:
                savedItem['isBestSeller'] as bool? ?? item.isBestSeller,
          );
        }
        return item;
      }).toList();
    } catch (e) {
      print('Error fetching menu items: $e');
      rethrow;
    }
  }

  @override
  Future<void> updateMenuItem(MenuItem item) async {
    try {
      // Save to local storage only
      await _saveMenuItemState(item);
    } catch (e) {
      print('Error updating menu item: $e');
      rethrow;
    }
  }

  @override
  Future<void> updateMultipleMenuItems(List<MenuItem> items) async {
    try {
      // Save all items to local storage
      for (final item in items) {
        await _saveMenuItemState(item);
      }
    } catch (e) {
      print('Error updating multiple menu items: $e');
      rethrow;
    }
  }

  Future<Map<String, dynamic>> _loadMenuState() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final stateJson = prefs.getString(_menuStateKey);
      if (stateJson != null) {
        return json.decode(stateJson) as Map<String, dynamic>;
      }
    } catch (e) {
      print('Error loading menu state: $e');
    }
    return {};
  }

  Future<void> _saveMenuItemState(MenuItem item) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final currentState = await _loadMenuState();

      currentState[item.id] = {
        'isEnabled': item.isEnabled,
        'stock': item.stock,
        'isBestSeller': item.isBestSeller,
      };

      final encoded = json.encode(currentState);
      print(
        'DEBUG MenuRepository: Saving menu state for ${item.id}: stock=${item.stock}, isEnabled=${item.isEnabled}, isBestSeller=${item.isBestSeller}',
      );
      print('DEBUG MenuRepository: Full state JSON: $encoded');
      await prefs.setString(_menuStateKey, encoded);
      print('DEBUG MenuRepository: Save completed');
    } catch (e) {
      print('Error saving menu item state: $e');
      rethrow;
    }
  }

  bool _matchesPartnership(dynamic item, UserModel user) {
    if (item is! Map) return false;

    String _normalize(String s) {
      return s.toLowerCase().replaceAll(RegExp(r"[^a-z0-9]+"), "").trim();
    }

    final itemKemitraan = (item['kemitraan'] ?? item['partnership'] ?? '')
        .toString();
    final itemSubBrand =
        (item['subBrand'] ?? item['sub_brand'] ?? item['subbrand'] ?? '')
            .toString();

    // If user has subBrand -> match only by subBrand
    if (user.hasSubBrand) {
      if (itemSubBrand.isEmpty) return false;
      return _normalize(itemSubBrand) == _normalize(user.subBrand ?? '');
    }

    // Otherwise match by kemitraan
    if (itemKemitraan.isEmpty) return false;
    final nItem = _normalize(itemKemitraan);
    final nUser = _normalize(user.kemitraan.toString());

    return nItem.contains(nUser) || nUser.contains(nItem);
  }
}
