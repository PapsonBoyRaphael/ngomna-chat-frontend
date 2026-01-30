import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:ngomna_chat/data/models/user_model.dart';

class StorageService {
  // Keys for SharedPreferences
  static const String _keyAccessToken = 'access_token';
  static const String _keyRefreshToken = 'refresh_token';
  static const String _keyMatricule = 'matricule';
  static const String _keyUserData = 'user_data';
  static const String _keyLastLogin = 'last_login';
  static const String _keySettings = 'app_settings';

  // Singleton instance
  static final StorageService _instance = StorageService._internal();

  factory StorageService() {
    return _instance;
  }

  StorageService._internal();

  // 🔐 Token Management

  /// Save both access and refresh tokens
  Future<void> saveTokens({
    required String accessToken,
    required String refreshToken,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    await Future.wait([
      prefs.setString(_keyAccessToken, accessToken),
      prefs.setString(_keyRefreshToken, refreshToken),
      prefs.setString(_keyLastLogin, DateTime.now().toIso8601String()),
    ]);
  }

  /// Get access token
  Future<String?> getAccessToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_keyAccessToken);
  }

  /// Get refresh token
  Future<String?> getRefreshToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_keyRefreshToken);
  }

  /// Check if user has tokens (is logged in)
  Future<bool> hasTokens() async {
    final accessToken = await getAccessToken();
    return accessToken != null && accessToken.isNotEmpty;
  }

  /// Clear all tokens (logout)
  Future<void> clearTokens() async {
    final prefs = await SharedPreferences.getInstance();
    await Future.wait([
      prefs.remove(_keyAccessToken),
      prefs.remove(_keyRefreshToken),
    ]);
  }

  // 👤 User Management

  /// Save complete user object
  Future<void> saveUser(User user) async {
    final prefs = await SharedPreferences.getInstance();
    final userJson = jsonEncode(user.toJson());
    await prefs.setString(_keyUserData, userJson);
  }

  /// Get saved user object
  Future<User?> getUser() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final userJson = prefs.getString(_keyUserData);

      if (userJson == null) return null;

      final userMap = jsonDecode(userJson) as Map<String, dynamic>;
      return User.fromJson(userMap);
    } catch (e) {
      print('❌ Error parsing saved user: $e');
      return null;
    }
  }

  /// Update specific user fields
  Future<void> updateUserField(String field, dynamic value) async {
    try {
      final user = await getUser();
      if (user != null) {
        final updatedUser = user.copyWithField(field, value);
        await saveUser(updatedUser);
      }
    } catch (e) {
      print('❌ Error updating user field: $e');
    }
  }

  /// Clear user data
  Future<void> clearUserData() async {
    final prefs = await SharedPreferences.getInstance();
    await Future.wait([
      prefs.remove(_keyUserData),
      prefs.remove(_keyMatricule),
      prefs.remove(_keyLastLogin),
    ]);
  }

  // 📝 Matricule Management (for backward compatibility)

  Future<void> saveMatricule(String matricule) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyMatricule, matricule);
  }

  Future<String?> getMatricule() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_keyMatricule);
  }

  // ⚙️ App Settings

  /// Save app settings
  Future<void> saveSettings(Map<String, dynamic> settings) async {
    final prefs = await SharedPreferences.getInstance();
    final settingsJson = jsonEncode(settings);
    await prefs.setString(_keySettings, settingsJson);
  }

  /// Get app settings
  Future<Map<String, dynamic>> getSettings() async {
    final prefs = await SharedPreferences.getInstance();
    final settingsJson = prefs.getString(_keySettings);

    if (settingsJson == null) {
      return {
        'notifications': true,
        'darkMode': false,
        'language': 'fr',
        'autoDownload': false,
      };
    }

    try {
      return Map<String, dynamic>.from(jsonDecode(settingsJson));
    } catch (e) {
      print('❌ Error parsing settings: $e');
      return {};
    }
  }

  /// Update specific setting
  Future<void> updateSetting(String key, dynamic value) async {
    final settings = await getSettings();
    settings[key] = value;
    await saveSettings(settings);
  }

  // 🗑️ Clear all data (full logout/reset)

  Future<void> clearAll() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
  }

  /// Clear only authentication data (partial clear)
  Future<void> clearAuthData() async {
    await clearTokens();
    await clearUserData();
  }

  // ℹ️ Debug & Info

  Future<Map<String, dynamic>> getStorageInfo() async {
    final prefs = await SharedPreferences.getInstance();
    final keys = prefs.getKeys();

    final info = <String, dynamic>{
      'totalKeys': keys.length,
      'hasAccessToken': (await getAccessToken()) != null,
      'hasUserData': (await getUser()) != null,
      'lastLogin': await getLastLogin(),
    };

    return info;
  }

  Future<DateTime?> getLastLogin() async {
    final prefs = await SharedPreferences.getInstance();
    final lastLoginStr = prefs.getString(_keyLastLogin);

    if (lastLoginStr != null) {
      try {
        return DateTime.parse(lastLoginStr);
      } catch (e) {
        return null;
      }
    }
    return null;
  }

  /// Check if user data exists and is valid
  Future<bool> hasValidUserData() async {
    final user = await getUser();
    final token = await getAccessToken();

    if (user == null || token == null) {
      return false;
    }

    // Additional validation could be added here
    // e.g., check token expiry, user fields validity

    return user.matricule != null && user.matricule!.isNotEmpty;
  }
}
