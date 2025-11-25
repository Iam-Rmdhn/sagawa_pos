import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sagawa_pos_new/features/profile/domain/models/user_model.dart';

class UserService {
  static const String _userKey = 'user_data';

  /// Save user data to SharedPreferences
  static Future<void> saveUser(UserModel user) async {
    final prefs = await SharedPreferences.getInstance();
    final userJson = jsonEncode(user.toJson());
    await prefs.setString(_userKey, userJson);
  }

  /// Get user data from SharedPreferences
  static Future<UserModel?> getUser() async {
    final prefs = await SharedPreferences.getInstance();
    final userJson = prefs.getString(_userKey);

    if (userJson == null || userJson.isEmpty) {
      return null;
    }

    try {
      final Map<String, dynamic> data = jsonDecode(userJson);
      return UserModel.fromJson(data);
    } catch (e) {
      print('Error parsing user data: $e');
      return null;
    }
  }

  /// Clear user data (for logout)
  static Future<void> clearUser() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_userKey);
  }

  /// Check if user is logged in
  static Future<bool> isLoggedIn() async {
    final user = await getUser();
    return user != null;
  }

  /// Update user data
  static Future<void> updateUser(UserModel user) async {
    await saveUser(user);
  }
}
