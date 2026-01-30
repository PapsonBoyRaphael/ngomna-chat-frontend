import 'package:ngomna_chat/data/services/api_service.dart';
import 'package:ngomna_chat/data/services/storage_service.dart';
import 'package:ngomna_chat/data/models/user_model.dart';

class AuthRepository {
  final ApiService _apiService;
  final StorageService _storageService;

  AuthRepository({
    required ApiService apiService,
    required StorageService storageService,
  })  : _apiService = apiService,
        _storageService = storageService;

  /// Authentifie un utilisateur avec son matricule
  /// Endpoint: POST /api/auth/login
  /// Body: {"matricule": "12345"}
  Future<Map<String, dynamic>> login(String matricule) async {
    try {
      print('🔐 Tentative de connexion avec matricule: $matricule');

      final response = await _apiService.post(
        ApiEndpoints.login,
        {'matricule': matricule},
      );

      // La réponse contient: user, accessToken, refreshToken
      final userData = response['user'] as Map<String, dynamic>;
      final accessToken = response['accessToken'] as String;
      final refreshToken = response['refreshToken'] as String;

      // Convertir en modèle User
      final user = User.fromJson(userData);

      // Sauvegarder les tokens
      await _apiService.saveTokens(
        accessToken: accessToken,
        refreshToken: refreshToken,
      );

      // Sauvegarder l'utilisateur localement
      await _storageService.saveUser(user);

      await _storageService.saveMatricule(matricule);

      print('✅ Connexion réussie pour: ${user.nom} ${user.prenom}');
      return {
        'user': user,
        'accessToken': accessToken,
      };
    } catch (e) {
      print('❌ Erreur de connexion: $e');
      rethrow;
    }
  }

  /// Crée un nouvel utilisateur
  /// Endpoint: POST /api/auth/
  /// Body: {matricule, nom, prenom, ministere, sexe}
  Future<User> register({
    required String matricule,
    required String nom,
    required String prenom,
    required String ministere,
    required String sexe,
  }) async {
    try {
      print('📝 Enregistrement nouvel utilisateur: $matricule');

      final response = await _apiService.post(
        ApiEndpoints.register,
        {
          'matricule': matricule,
          'nom': nom,
          'prenom': prenom,
          'ministere': ministere,
          'sexe': sexe,
        },
      );

      final user = User.fromJson(response);
      print('✅ Utilisateur créé: ${user.nom} ${user.prenom}');
      return user;
    } catch (e) {
      print('❌ Erreur d\'enregistrement: $e');
      rethrow;
    }
  }

  /// Vérifie si l'utilisateur est authentifié
  Future<bool> isAuthenticated() async {
    try {
      final hasToken = await _apiService.isAuthenticated();

      if (!hasToken) {
        print('🔒 Pas de token JWT trouvé');
        return false;
      }

      // Optionnel: Vérifier la validité du token avec une requête
      // Ou simplement vérifier l'existence
      return true;
    } catch (e) {
      print('❌ Erreur vérification authentification: $e');
      return false;
    }
  }

  /// Déconnecte l'utilisateur
  Future<void> logout() async {
    try {
      // Optionnel: Appeler l'endpoint logout du backend si disponible
      // await _apiService.post(ApiEndpoints.logout, {});

      // Nettoyer localement
      await _apiService.clearTokens();
      await _storageService.clearUserData();

      print('👋 Utilisateur déconnecté');
    } catch (e) {
      print('⚠️ Erreur lors de la déconnexion: $e');
      // Nettoyer quand même localement en cas d'erreur
      await _apiService.clearTokens();
      await _storageService.clearUserData();
    }
  }

  /// Récupère l'utilisateur actuel depuis le stockage local
  Future<User?> getCurrentUser() async {
    try {
      return await _storageService.getUser();
    } catch (e) {
      print('❌ Erreur récupération utilisateur: $e');
      return null;
    }
  }

  /// Rafraîchit les informations de l'utilisateur depuis l'API
  Future<User> refreshUserProfile(String userId) async {
    try {
      print('🔄 Rafraîchissement profil utilisateur: $userId');

      final response = await _apiService.get(
        ApiEndpoints.userById(userId),
      );

      final user = User.fromJson(response);
      await _storageService.saveUser(user);

      print('✅ Profil rafraîchi: ${user.nom} ${user.prenom}');
      return user;
    } catch (e) {
      print('❌ Erreur rafraîchissement profil: $e');
      rethrow;
    }
  }

  /// Récupère un utilisateur par son matricule
  /// Endpoint: GET /api/auth/matricule/:matricule
  Future<User> getUserByMatricule(String matricule) async {
    try {
      final response = await _apiService.get(
        ApiEndpoints.userByMatricule(matricule),
      );
      return User.fromJson(response);
    } catch (e) {
      print('❌ Erreur récupération utilisateur par matricule: $e');
      rethrow;
    }
  }

  /// Récupère plusieurs utilisateurs par lot
  /// Endpoint: GET /api/auth/batch
  /// Body: {"userIds": ["id1", "id2"]}
  Future<List<User>> getUsersBatch(List<String> userIds) async {
    try {
      final response = await _apiService.post(
        ApiEndpoints.batchGetUsers,
        {'userIds': userIds},
      );

      final usersData = response as List<dynamic>;
      return usersData.map((data) => User.fromJson(data)).toList();
    } catch (e) {
      print('❌ Erreur récupération batch utilisateurs: $e');
      rethrow;
    }
  }

  /// Vérifie l'état de la gateway
  Future<Map<String, dynamic>> checkGatewayHealth() async {
    try {
      return await _apiService.checkGatewayHealth();
    } catch (e) {
      print('❌ Gateway indisponible: $e');
      rethrow;
    }
  }

  /// Gestion des erreurs spécifiques d'authentification
  String getErrorMessage(dynamic error) {
    if (error is ApiException) {
      switch (error.statusCode) {
        case 401:
          return 'Matricule incorrect ou utilisateur non trouvé';
        case 429:
          return 'Trop de tentatives de connexion. Veuillez patienter';
        case 503:
          return 'Service d\'authentification temporairement indisponible';
        default:
          return error.message;
      }
    }
    return 'Erreur de connexion. Vérifiez votre réseau';
  }
}
