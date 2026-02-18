import 'dart:convert';
import 'dart:io';
import 'package:dio/dio.dart';
import 'package:ngomna_chat/data/services/storage_service.dart';
import 'package:ngomna_chat/core/constants/app_url.dart';

class ApiService {
  static final String _baseUrl = AppUrl.apiBaseUrl; // Gateway URL (dynamique)

  late Dio _dio;
  late StorageService _storageService;
  static final ApiService _instance = ApiService._internal();

  factory ApiService() {
    return _instance;
  }

  ApiService._internal() {
    _storageService = StorageService();
    _dio = Dio(
      BaseOptions(
        baseUrl: _baseUrl,
        connectTimeout: const Duration(seconds: 30),
        receiveTimeout: const Duration(seconds: 30),
        sendTimeout: const Duration(seconds: 30),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      ),
    );

    // Add interceptors for auth
    _dio.interceptors.add(InterceptorsWrapper(
      onRequest: (options, handler) async {
        // Add authorization token if available
        final token = await _getToken();
        if (token != null && token.isNotEmpty) {
          options.headers['Authorization'] = 'Bearer $token';
        }
        return handler.next(options);
      },
      onError: (error, handler) async {
        // Handle 401 Unauthorized
        if (error.response?.statusCode == 401) {
          await _handleUnauthorized();
        }
        return handler.next(error);
      },
    ));
  }

  // GET: Proxy via Gateway
  Future<Map<String, dynamic>> get(String endpoint) async {
    try {
      final response = await _dio.get(endpoint);
      return response.data as Map<String, dynamic>;
    } on DioException catch (e) {
      throw _handleDioError(e, endpoint);
    }
  }

  // POST: Proxy via Gateway
  Future<Map<String, dynamic>> post(
    String endpoint,
    Map<String, dynamic> data,
  ) async {
    try {
      final response = await _dio.post(endpoint, data: data);
      return response.data as Map<String, dynamic>;
    } on DioException catch (e) {
      throw _handleDioError(e, endpoint);
    }
  }

  // PUT: Proxy via Gateway
  Future<Map<String, dynamic>> put(
    String endpoint,
    Map<String, dynamic> data,
  ) async {
    try {
      final response = await _dio.put(endpoint, data: data);
      return response.data as Map<String, dynamic>;
    } on DioException catch (e) {
      throw _handleDioError(e, endpoint);
    }
  }

  // DELETE: Proxy via Gateway
  Future<Map<String, dynamic>> delete(String endpoint) async {
    try {
      final response = await _dio.delete(endpoint);
      return response.data as Map<String, dynamic>;
    } on DioException catch (e) {
      throw _handleDioError(e, endpoint);
    }
  }

  // UPLOAD FILE: For chat-file-service via Gateway
  Future<Map<String, dynamic>> uploadFile({
    required String endpoint,
    required File file,
    required String fileName,
    Map<String, dynamic>? metadata,
    ProgressCallback? onSendProgress,
  }) async {
    try {
      final formData = FormData.fromMap({
        'file': await MultipartFile.fromFile(
          file.path,
          filename: fileName,
        ),
        if (metadata != null) 'metadata': jsonEncode(metadata),
      });

      final response = await _dio.post(
        endpoint,
        data: formData,
        onSendProgress: onSendProgress,
      );

      return response.data as Map<String, dynamic>;
    } on DioException catch (e) {
      throw _handleDioError(e, endpoint);
    }
  }

  // TOKEN MANAGEMENT
  Future<void> saveTokens({
    required String accessToken,
    required String refreshToken,
  }) async {
    await _storageService.saveTokens(
        accessToken: accessToken, refreshToken: refreshToken);
  }

  Future<String?> _getToken() async {
    return _storageService.getAccessToken();
  }

  Future<void> clearTokens() async {
    await _storageService.clearTokens();
  }

  Future<bool> isAuthenticated() async {
    final token = await _getToken();
    return token != null && token.isNotEmpty;
  }

  // ERROR HANDLING
  Exception _handleDioError(DioException error, String endpoint) {
    if (error.response != null) {
      // Server responded with error
      final statusCode = error.response!.statusCode;
      final data = error.response!.data;

      String message = 'Erreur $statusCode';

      if (data is Map<String, dynamic> && data.containsKey('message')) {
        message = data['message'];
      } else if (data is String) {
        message = data;
      } else if (data is Map<String, dynamic> && data.containsKey('error')) {
        message = data['error'];
      }

      return ApiException(
        message: message,
        statusCode: statusCode,
        endpoint: endpoint,
      );
    } else if (error.type == DioExceptionType.connectionTimeout) {
      return ApiException(
        message: 'Timeout de connexion',
        endpoint: endpoint,
      );
    } else if (error.type == DioExceptionType.receiveTimeout) {
      return ApiException(
        message: 'Timeout de réponse',
        endpoint: endpoint,
      );
    } else if (error.type == DioExceptionType.connectionError) {
      return ApiException(
        message: 'Erreur de connexion. Vérifiez votre réseau',
        endpoint: endpoint,
      );
    } else if (error.type == DioExceptionType.badResponse) {
      return ApiException(
        message: 'Réponse invalide du serveur',
        endpoint: endpoint,
      );
    } else {
      return ApiException(
        message: 'Erreur inconnue: ${error.message}',
        endpoint: endpoint,
      );
    }
  }

  Future<void> _handleUnauthorized() async {
    // Clear tokens and notify app
    await clearTokens();
    // You might want to add an event bus or callback here
    // to notify the app to navigate to login screen
  }

  // Health check
  Future<Map<String, dynamic>> checkGatewayHealth() async {
    return await get('/api/health');
  }
}

// Custom exception class
class ApiException implements Exception {
  final String message;
  final int? statusCode;
  final String? endpoint;

  ApiException({
    required this.message,
    this.statusCode,
    this.endpoint,
  });

  @override
  String toString() {
    if (statusCode != null) {
      return 'API Error [$statusCode${endpoint != null ? ' @ $endpoint' : ''}]: $message';
    }
    return 'API Error${endpoint != null ? ' @ $endpoint' : ''}: $message';
  }
}

// 🔥 NOUVELLES CONSTANTES BASÉES SUR LA GATEWAY RÉELLE
class ApiEndpoints {
  // 🔐 Auth endpoints (via /api/auth proxy)
  static const String login = '/api/auth/login';
  static const String register = '/api/auth/'; // POST /api/auth/
  static const String getUserById = '/api/auth/'; // GET /api/auth/:id
  static const String getUserByMatricule =
      '/api/auth/matricule/'; // GET /api/auth/matricule/:matricule
  static const String updateUser = '/api/auth/'; // PUT /api/auth/:id
  static const String deleteUser = '/api/auth/'; // DELETE /api/auth/:id
  static const String getAllUsers = '/api/auth/all'; // GET /api/auth/all
  static const String batchGetUsers = '/api/auth/batch'; // GET /api/auth/batch

  // 👥 Users endpoints (alias pour auth service via /api/users proxy)
  static const String usersLogin = '/api/users/login';
  static const String usersRegister = '/api/users/';
  static const String usersAll = '/api/users/all';
  static const String usersBatch = '/api/users/batch';

  // 👁️ Visibility service
  static const String visibilityBase = '/api/visibility';

  // 💬 Chat & Files service
  static const String chatBase = '/api/chat';
  static const String uploadFile = '/api/chat/upload';

  // 🩺 Health check
  static const String health = '/api/health';

  // Helper methods for constructing URLs
  static String userById(String userId) => '/api/auth/$userId';
  static String userByMatricule(String matricule) =>
      '/api/auth/matricule/$matricule';
  static String updateUserById(String userId) => '/api/auth/$userId';
  static String deleteUserById(String userId) => '/api/auth/$userId';
}

// 📦 Response models for gateway
class GatewayHealthResponse {
  final String status;
  final String timestamp;
  final double uptime;
  final Map<String, dynamic> memory;
  final List<Map<String, dynamic>> services;

  GatewayHealthResponse({
    required this.status,
    required this.timestamp,
    required this.uptime,
    required this.memory,
    required this.services,
  });

  factory GatewayHealthResponse.fromJson(Map<String, dynamic> json) {
    return GatewayHealthResponse(
      status: json['status'],
      timestamp: json['timestamp'],
      uptime: json['uptime']?.toDouble() ?? 0.0,
      memory: Map<String, dynamic>.from(json['memory'] ?? {}),
      services: List<Map<String, dynamic>>.from(json['services'] ?? []),
    );
  }
}

/// Extension pour ajouter dispose à ApiService
extension ApiServiceDispose on ApiService {
  void dispose() {
    // Nettoyer les ressources Dio si nécessaire
    // Dio gère automatiquement la fermeture des connexions
    print('🧹 ApiService nettoyé');
  }
}
