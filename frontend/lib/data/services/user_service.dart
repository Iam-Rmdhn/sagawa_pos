import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sagawa_pos_new/features/profile/domain/models/user_model.dart';

class UserService {
  static const String _userKey = 'user_data';
  static const String _baseUrl = 'http://localhost:8080/api/v1';

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

  /// Update user data locally
  static Future<void> updateUser(UserModel user) async {
    await saveUser(user);
  }

  /// Update user profile to backend and local storage
  /// Returns the updated user model from backend, or null if failed
  static Future<UserModel?> updateProfileToBackend(UserModel user) async {
    try {
      final dio = Dio();
      dio.options.validateStatus = (status) => true;
      dio.options.connectTimeout = const Duration(seconds: 10);
      dio.options.receiveTimeout = const Duration(seconds: 10);

      final url = '$_baseUrl/kasir/${user.id}/profile';

      final response = await dio.put(
        url,
        data: {
          'username': user.username,
          'kemitraan': user.kemitraan,
          'outlet': user.outlet,
          'subBrand': user.subBrand ?? '',
          'profilePhotoData': user.profilePhotoData ?? '',
        },
        options: Options(headers: {'Content-Type': 'application/json'}),
      );

      if (response.statusCode == 200) {
        // Parse response and update local storage
        final data = response.data;
        UserModel updatedUser;

        if (data is Map<String, dynamic>) {
          if (data.containsKey('id')) {
            // Response contains the full user object
            updatedUser = UserModel.fromJson(data);
          } else {
            // Response contains just a message, use the input user
            updatedUser = user;
          }
        } else {
          updatedUser = user;
        }

        // Save to local storage
        await saveUser(updatedUser);
        return updatedUser;
      } else {
        print(
          'Failed to update profile: ${response.statusCode} - ${response.data}',
        );
        return null;
      }
    } catch (e) {
      print('Error updating profile to backend: $e');
      return null;
    }
  }
}
