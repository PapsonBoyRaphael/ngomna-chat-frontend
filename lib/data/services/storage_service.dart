import 'package:shared_preferences/shared_preferences.dart';

class StorageService {
  static const String _keyMatricule = 'matricule';
  static const String _keyPost = 'post';
  static const String _keyToken = 'token';

  Future<void> saveMatricule(String matricule) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyMatricule, matricule);
  }

  Future<void> savePost(String post) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyPost, post);
  }

  Future<void> saveToken(String token) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyToken, token);
  }

  Future<String?> getMatricule() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_keyMatricule);
  }

  Future<String?> getPost() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_keyPost);
  }

  Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_keyToken);
  }

  Future<void> clear() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
  }
}
