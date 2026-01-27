import 'package:ngomna_chat/data/services/api_service.dart';
import 'package:ngomna_chat/data/services/storage_service.dart';

class AuthRepository {
  final ApiService _apiService;
  final StorageService _storageService;

  AuthRepository(this._apiService, this._storageService);

  Future<void> authenticate(String matricule, String post) async {
    // Appel API
    final response = await _apiService.post('/auth/login', {
      'matricule': matricule,
      'post': post,
    });

    // Sauvegarder les données localement
    await _storageService.saveMatricule(matricule);
    await _storageService.savePost(post);
    await _storageService.saveToken(response['token']);
  }

  Future<bool> isAuthenticated() async {
    final token = await _storageService.getToken();
    return token != null;
  }
}
