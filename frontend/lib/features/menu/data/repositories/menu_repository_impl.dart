import 'package:sagawa_pos/core/network/api_client.dart';
import 'package:sagawa_pos/core/network/api_config.dart';
import 'package:sagawa_pos/features/menu/domain/models/menu_item.dart';
import 'package:sagawa_pos/features/menu/domain/repositories/menu_repository.dart';
import 'package:sagawa_pos/data/services/user_service.dart';
import 'package:sagawa_pos/features/profile/domain/models/user_model.dart';
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
      final UserModel? user = await UserService.getUser();
      final queryParameters = <String, dynamic>{};

      if (user != null) {
        if (user.kemitraan.trim().isNotEmpty) {
          queryParameters['kemitraan'] = user.kemitraan.trim();
        }
        if (user.hasSubBrand && (user.subBrand ?? '').trim().isNotEmpty) {
          queryParameters['subBrand'] = user.subBrand!.trim();
        }
      }

      final response = await _apiClient.get(
        ApiConfig.menu,
        queryParameters: queryParameters.isEmpty ? null : queryParameters,
      );
      final data = response.data;

      List items = [];
      if (data is List) {
        items = data;
      } else if (data is Map && data['data'] is List) {
        items = data['data'] as List;
      }

      if (user != null) {
        items = items.where((item) => _matchesPartnership(item, user)).toList();
      }

      final menuItems = items
          .map((e) => MenuItem.fromJson(e as Map<String, dynamic>))
          .toList();

      final savedState = await _loadMenuState();
      await _pruneMenuState(savedState, menuItems);

      return menuItems.map((item) {
        final savedItem = savedState[item.id];
        if (savedItem != null) {
          return item.copyWith(
            isEnabled: _parseBool(savedItem['isEnabled'], item.isEnabled),
            stock: _parseInt(savedItem['stock'], item.stock),
            isBestSeller: _parseBool(
              savedItem['isBestSeller'],
              item.isBestSeller,
            ),
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
      await _saveMenuItemState(item);
    } catch (e) {
      print('Error updating menu item: $e');
      rethrow;
    }
  }

  @override
  Future<void> updateMultipleMenuItems(List<MenuItem> items) async {
    try {
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

  Future<void> _pruneMenuState(
    Map<String, dynamic> savedState,
    List<MenuItem> remoteItems,
  ) async {
    final remoteIds = remoteItems.map((item) => item.id).toSet();
    if (remoteIds.isEmpty) return;

    final staleIds = savedState.keys
        .where((id) => !remoteIds.contains(id))
        .toList(growable: false);
    if (staleIds.isEmpty) return;

    for (final id in staleIds) {
      savedState.remove(id);
    }

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_menuStateKey, json.encode(savedState));
  }

  bool _matchesPartnership(dynamic item, UserModel user) {
    if (item is! Map) return false;

    String _normalize(String s) {
      return s.toLowerCase().replaceAll(RegExp(r"[^a-z0-9]+"), "").trim();
    }

    final itemKemitraan =
        (item['kemitraan'] ?? item['partnership'] ?? item['restaurant'] ?? '')
            .toString();
    final itemSubBrand =
        (item['subBrand'] ?? item['sub_brand'] ?? item['subbrand'] ?? '')
            .toString();

    if (user.hasSubBrand) {
      // Include items whose subBrand is empty (legacy/orphan docs) so they are
      // not silently dropped; otherwise require an exact subBrand match.
      if (itemSubBrand.isEmpty) return true;
      return _normalize(itemSubBrand) == _normalize(user.subBrand ?? '');
    }

    if (itemKemitraan.isEmpty) return false;
    final nItem = _normalize(itemKemitraan);
    final nUser = _normalize(user.kemitraan.toString());

    return nItem.contains(nUser) || nUser.contains(nItem);
  }

  int _parseInt(dynamic raw, int fallback) {
    if (raw == null) return fallback;
    if (raw is int) return raw;
    if (raw is double) return raw.toInt();
    return int.tryParse(raw.toString()) ?? fallback;
  }

  bool _parseBool(dynamic raw, bool fallback) {
    if (raw == null) return fallback;
    if (raw is bool) return raw;
    final value = raw.toString().trim().toLowerCase();
    if (const {'true', '1', 'yes', 'y', 'active', 'enabled'}.contains(value)) {
      return true;
    }
    if (const {
      'false',
      '0',
      'no',
      'n',
      'inactive',
      'disabled',
    }.contains(value)) {
      return false;
    }
    return fallback;
  }
}
