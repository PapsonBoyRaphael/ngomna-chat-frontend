import 'dart:convert';
import 'package:hive/hive.dart';
import 'package:ngomna_chat/data/models/user_model.dart';

class StorageService {
  // Keys for Hive storage
  static const String _boxName = 'storageBox';
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

  late Box _box;

  /// Initialize Hive box
  Future<void> initialize() async {
    _box = await Hive.openBox(_boxName);
  }

  // 🔐 Token Management

  /// Save both access and refresh tokens
  Future<void> saveTokens({
    required String accessToken,
    required String refreshToken,
  }) async {
    await _box.put(_keyAccessToken, accessToken);
    await _box.put(_keyRefreshToken, refreshToken);
    await _box.put(_keyLastLogin, DateTime.now().toIso8601String());

    print('💾 Tokens sauvegardés');
  }

  /// Get access token
  String? getAccessToken() {
    return _box.get(_keyAccessToken);
  }

  /// Get refresh token
  String? getRefreshToken() {
    return _box.get(_keyRefreshToken);
  }

  /// Check if user has tokens (is logged in)
  bool hasTokens() {
    final accessToken = getAccessToken();
    return accessToken != null && accessToken.isNotEmpty;
  }

  /// Clear all tokens (logout)
  Future<void> clearTokens() async {
    await _box.delete(_keyAccessToken);
    await _box.delete(_keyRefreshToken);
  }

  // 👤 User Management

  /// Save complete user object
  Future<void> saveUser(User user) async {
    final userJson = user.toJson();
    await _box.put(_keyUserData, userJson);
  }

  /// Get saved user object
  User? getUser() {
    try {
      final userJson = _box.get(_keyUserData);
      if (userJson == null) return null;
      return User.fromJson(Map<String, dynamic>.from(userJson));
    } catch (e) {
      print('❌ Error parsing saved user: $e');
      return null;
    }
  }

  /// Update specific user fields
  Future<void> updateUserField(String field, dynamic value) async {
    try {
      final user = getUser();
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
    await _box.delete(_keyUserData);
    await _box.delete(_keyMatricule);
    await _box.delete(_keyLastLogin);
  }

  // 📝 Matricule Management (for backward compatibility)

  Future<void> saveMatricule(String matricule) async {
    await _box.put(_keyMatricule, matricule);
  }

  String? getMatricule() {
    return _box.get(_keyMatricule);
  }

  // ⚙️ App Settings

  /// Save app settings
  Future<void> saveSettings(Map<String, dynamic> settings) async {
    await _box.put(_keySettings, settings);
  }

  /// Get app settings
  Map<String, dynamic> getSettings() {
    final settings = _box.get(_keySettings);
    if (settings == null) {
      return {
        'notifications': true,
        'darkMode': false,
        'language': 'fr',
        'autoDownload': false,
      };
    }
    try {
      return Map<String, dynamic>.from(settings);
    } catch (e) {
      print('❌ Error parsing settings: $e');
      return {};
    }
  }

  /// Update specific setting
  Future<void> updateSetting(String key, dynamic value) async {
    final settings = getSettings();
    settings[key] = value;
    await saveSettings(settings);
  }

  // 🗑️ Clear all data (full logout/reset)

  Future<void> clearAll() async {
    await _box.clear();
  }

  /// Clear only authentication data (partial clear)
  Future<void> clearAuthData() async {
    await clearTokens();
    await clearUserData();
  }

  // ℹ️ Debug & Info

  Map<String, dynamic> getStorageInfo() {
    final keys = _box.keys;
    return {
      'totalKeys': keys.length,
      'hasAccessToken': getAccessToken() != null,
      'hasUserData': getUser() != null,
      'lastLogin': getLastLogin(),
    };
  }

  DateTime? getLastLogin() {
    final lastLoginStr = _box.get(_keyLastLogin);
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
  bool hasValidUserData() {
    final user = getUser();
    final token = getAccessToken();
    if (user == null || token == null) {
      return false;
    }
    return user.matricule != null && user.matricule!.isNotEmpty;
  }

  /// Dispose resources
  void dispose() {
    // SharedPreferences gère automatiquement la fermeture
    print('🧹 StorageService nettoyé');
  }
}
