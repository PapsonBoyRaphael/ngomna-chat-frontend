import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:provider/single_child_widget.dart';
import 'package:ngomna_chat/data/services/api_service.dart';
import 'package:ngomna_chat/data/services/storage_service.dart';
import 'package:ngomna_chat/data/services/socket_service.dart';
import 'package:ngomna_chat/data/services/path_service.dart';
import 'package:ngomna_chat/data/services/hive_service.dart';
import 'package:ngomna_chat/data/services/image_cache_service.dart';
import 'package:ngomna_chat/data/repositories/auth_repository.dart';
import 'package:ngomna_chat/data/repositories/chat_repository.dart';
import 'package:ngomna_chat/data/repositories/message_repository.dart';
import 'package:ngomna_chat/viewmodels/auth_viewmodel.dart';
import 'package:ngomna_chat/viewmodels/chat_list_viewmodel.dart';
import 'package:ngomna_chat/viewmodels/message_viewmodel.dart';

class AppProviders {
  /// Liste complète de tous les providers de l'application
  static List<SingleChildWidget> get allProviders => [
        // 🔧 Services (Singletons)
        Provider<ApiService>(
          create: (_) => ApiService(),
        ),
        Provider<StorageService>(
          create: (_) => StorageService(),
        ),
        Provider<SocketService>(
          create: (_) => SocketService(),
        ),
        Provider<PathService>(
          create: (_) => PathService(),
        ),
        Provider<HiveService>(
          create: (_) => HiveService(),
        ),
        Provider<ImageCacheService>(
          create: (_) => ImageCacheService(),
        ),

        // 📚 Repositories
        Provider<AuthRepository>(
          create: (context) => AuthRepository(
            apiService: context.read<ApiService>(),
            storageService: context.read<StorageService>(),
          ),
        ),
        Provider<MessageRepository>(
          create: (context) => MessageRepository(
            apiService: context.read<ApiService>(),
            socketService: context.read<SocketService>(),
          ),
        ),

        // 🧠 ViewModels (ChangeNotifier)
        ChangeNotifierProvider<AuthViewModel>(
          create: (context) => AuthViewModel(
            context.read<AuthRepository>(),
          ),
        ),
        ChangeNotifierProvider<ChatListViewModel>(
          create: (context) => ChatListViewModel(),
        ),
        // ChatViewModel est créé par conversation, pas globalement
        ChangeNotifierProvider<MessageViewModel>(
          create: (context) => MessageViewModel(
            context.read<MessageRepository>(),
          ),
        ),
      ];

  /// Providers pour les écrans d'authentification seulement
  static List<SingleChildWidget> get authProviders => [
        Provider<ApiService>(
          create: (_) => ApiService(),
        ),
        Provider<StorageService>(
          create: (_) => StorageService(),
        ),
        Provider<AuthRepository>(
          create: (context) => AuthRepository(
            apiService: context.read<ApiService>(),
            storageService: context.read<StorageService>(),
          ),
        ),
        ChangeNotifierProvider<AuthViewModel>(
          create: (context) => AuthViewModel(
            context.read<AuthRepository>(),
          ),
        ),
      ];

  /// Providers pour les écrans de chat seulement
  static List<SingleChildWidget> get chatProviders => [
        Provider<SocketService>(
          create: (_) => SocketService(),
        ),
        Provider<HiveService>(
          create: (_) => HiveService(),
        ),
        Provider<ChatRepository>(
          create: (context) =>
              ChatRepository(), // ChatRepository n'a pas de paramètres dans le constructeur actuel
        ),
        Provider<MessageRepository>(
          create: (context) => MessageRepository(
            socketService: context.read<SocketService>(),
            apiService: context.read<
                ApiService>(), // Corrigé : apiService au lieu de hiveService
          ),
        ),
        ChangeNotifierProvider<ChatListViewModel>(
          create: (_) => ChatListViewModel(),
        ),
        // ChatViewModel est créé par conversation
      ];

  /// Wrapper pour MultiProvider
  static Widget wrapWithProviders({
    required Widget child,
    List<SingleChildWidget>? providers,
    bool useAllProviders = true,
  }) {
    final providerList = providers ?? (useAllProviders ? allProviders : []);

    return MultiProvider(
      providers: providerList,
      child: child,
    );
  }

  /// Initialiser les services (appelé depuis main.dart)
  static Future<void> initializeServices() async {
    // Initialiser les services qui ont besoin d'async
    final storageService = StorageService();
    await storageService.initialize();

    final pathService = PathService();
    final hiveService = HiveService();

    // Ces initialisations se feront dans leurs constructeurs
    // ou via des méthodes d'initialisation spécifiques
    print('✅ Services initialisés');
  }

  /// Nettoyer les ressources (appelé à la fermeture)
  static Future<void> disposeServices() async {
    // Nettoyer les services si nécessaire
    // Ex: await Provider.of<SocketService>(context, listen: false).dispose();
    print('🧹 Services nettoyés');
  }
}
