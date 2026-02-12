import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:provider/single_child_widget.dart';
import 'dart:async';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:ngomna_chat/data/models/chat_model.dart';
import 'package:ngomna_chat/data/models/message_model.dart';
import 'package:ngomna_chat/data/services/api_service.dart';
import 'package:ngomna_chat/data/services/storage_service.dart';
import 'package:ngomna_chat/data/services/socket_service.dart';
import 'package:ngomna_chat/data/services/path_service.dart';
import 'package:ngomna_chat/data/services/hive_service.dart';
import 'package:ngomna_chat/data/services/image_cache_service.dart';
import 'package:ngomna_chat/data/repositories/auth_repository.dart';
import 'package:ngomna_chat/data/repositories/broadcast_repository.dart';
import 'package:ngomna_chat/data/repositories/chat_repository.dart';
import 'package:ngomna_chat/data/repositories/chat_list_repository.dart';
import 'package:ngomna_chat/data/repositories/contact_repository.dart';
import 'package:ngomna_chat/data/repositories/group_chat_repository.dart';
import 'package:ngomna_chat/data/repositories/group_repository.dart';
import 'package:ngomna_chat/data/repositories/message_repository.dart';
import 'package:ngomna_chat/viewmodels/auth_viewmodel.dart';
import 'package:ngomna_chat/viewmodels/chat_list_viewmodel.dart';
import 'package:ngomna_chat/viewmodels/chat_viewmodel.dart';
import 'package:ngomna_chat/viewmodels/message_viewmodel.dart';

class AppProviders {
  static bool _initialized = false;

  static void _registerAdapterIfNeeded<T>(TypeAdapter<T> adapter) {
    if (!Hive.isAdapterRegistered(adapter.typeId)) {
      Hive.registerAdapter(adapter);
    }
  }

  /// Liste complète de tous les providers de l'application
  static List<SingleChildWidget> get allProviders => [
        // 🔧 Services (Singletons)
        Provider<ApiService>(
          create: (_) => ApiService(),
          dispose: (_, service) => service.dispose(),
        ),
        Provider<StorageService>(
          create: (_) => StorageService(),
          dispose: (_, service) => service.dispose(),
        ),
        Provider<SocketService>(
          create: (_) => SocketService(),
          dispose: (_, service) => service.dispose(),
        ),
        Provider<PathService>(
          create: (_) => PathService(),
          dispose: (_, service) {}, // Pas de ressources à nettoyer
        ),
        Provider<HiveService>(
          create: (_) => HiveService(),
          dispose: (_, service) {}, // Pas de ressources à nettoyer
        ),
        Provider<ImageCacheService>(
          create: (_) => ImageCacheService(),
          dispose: (_, service) {}, // Pas de ressources à nettoyer
        ),

        // 📚 Repositories
        Provider<AuthRepository>(
          create: (context) => AuthRepository(
            apiService: context.read<ApiService>(),
            storageService: context.read<StorageService>(),
          ),
        ),
        Provider<BroadcastRepository>(
          create: (context) => BroadcastRepository(
            context.read<AuthRepository>(),
          ),
        ),
        Provider<ChatRepository>(
          create: (_) => ChatRepository(),
        ),
        Provider<ChatListRepository>(
          create: (context) => ChatListRepository(
            socketService: context.read<SocketService>(),
            hiveService: context.read<HiveService>(),
          ),
        ),
        Provider<ContactRepository>(
          create: (_) => ContactRepository(),
        ),
        Provider<GroupChatRepository>(
          create: (_) => GroupChatRepository(),
        ),
        Provider<GroupRepository>(
          create: (context) => GroupRepository(
            context.read<ApiService>(),
          ),
        ),
        Provider<MessageRepository>(
          create: (context) => MessageRepository(
            socketService: context.read<SocketService>(),
            apiService: context.read<ApiService>(),
            hiveService: context.read<HiveService>(),
          ),
        ),

        // 🧠 ViewModels (ChangeNotifier)
        ChangeNotifierProvider<AuthViewModel>(
          create: (context) => AuthViewModel(
            context.read<AuthRepository>(),
          ),
        ),
        ChangeNotifierProvider<ChatListViewModel>(
          create: (context) => ChatListViewModel(
            chatListRepository: context.read<ChatListRepository>(),
          ),
        ),
        // ChatViewModel est créé par conversation, pas globalement
        // MessageViewModel est créé par conversation, pas globalement
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
            apiService: context.read<ApiService>(),
            hiveService: context.read<HiveService>(),
          ),
        ),
        ChangeNotifierProvider<ChatListViewModel>(
          create: (context) => ChatListViewModel(
            chatListRepository: context.read<ChatListRepository>(),
          ),
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
    if (_initialized) return;

    try {
      // Initialiser Hive
      await Hive.initFlutter();

      // ⚠️ IMPORTANT : Enregistrer les adapters dans l'ordre des dépendances
      // Les types simples/primitifs AVANT les types composites qui les utilisent

      // 1️⃣ Enums et types simples d'abord
      _registerAdapterIfNeeded(ChatTypeAdapter());
      _registerAdapterIfNeeded(MessageTypeAdapter());
      _registerAdapterIfNeeded(MessageStatusAdapter());
      _registerAdapterIfNeeded(MessagePriorityAdapter());

      // 2️⃣ Types composites de niveau 1
      // Note: UserPresence et PresenceStats ne sont PAS persistées (données temps réel)
      _registerAdapterIfNeeded(NotificationSettingsAdapter());
      _registerAdapterIfNeeded(LastMessageAdapter());
      _registerAdapterIfNeeded(MessageMetadataAdapter());
      _registerAdapterIfNeeded(TechnicalMetadataAdapter());
      _registerAdapterIfNeeded(KafkaMetadataAdapter());
      _registerAdapterIfNeeded(RedisMetadataAdapter());
      _registerAdapterIfNeeded(DeliveryMetadataAdapter());
      _registerAdapterIfNeeded(ContentMetadataAdapter());
      _registerAdapterIfNeeded(AuditLogEntryAdapter());

      // 3️⃣ ParticipantMetadata (le champ presence n'a pas de @HiveField donc non persisté)
      _registerAdapterIfNeeded(ParticipantMetadataAdapter());

      // 5️⃣ Types composites de niveau 2
      _registerAdapterIfNeeded(ChatSettingsAdapter());
      _registerAdapterIfNeeded(ChatMetadataAdapter());
      _registerAdapterIfNeeded(ChatStatsAdapter());
      _registerAdapterIfNeeded(ChatIntegrationsAdapter());

      // 6️⃣ Types principaux (utilisent ParticipantMetadata, PresenceStats, etc.)
      _registerAdapterIfNeeded(ChatAdapter());
      _registerAdapterIfNeeded(MessageAdapter());

      // 🔍 Vérification des adapters de présence
      print('🔧 [AppProviders] Vérification adapters de présence:');
      print('   - UserPresence (typeId 20): ${Hive.isAdapterRegistered(20)}');
      print('   - PresenceStats (typeId 21): ${Hive.isAdapterRegistered(21)}');

      // Initialiser StorageService avec timeout
      final storageService = StorageService();
      await storageService.initialize().timeout(
            Duration(seconds: 10),
            onTimeout: () =>
                throw TimeoutException('StorageService initialization timeout'),
          );

      // Initialiser HiveService (pas d'async spécifique)
      final hiveService = HiveService();

      // Initialiser ImageCacheService (pas d'initialisation async spécifique)
      final imageCacheService = ImageCacheService();

      // Initialiser ApiService (singleton, déjà initialisé)
      final apiService = ApiService();

      _initialized = true;
      print('✅ Services et Hive initialisés avec succès');
    } catch (e) {
      print('❌ Erreur initialisation services: $e');
      rethrow;
    }
  }

  /// Nettoyer les ressources (appelé à la fermeture)
  static Future<void> disposeServices() async {
    // Nettoyer les services si nécessaire
    // Ex: await Provider.of<SocketService>(context, listen: false).dispose();
    print('🧹 Services nettoyés');
  }

  /// Initialiser les repositories après la construction des providers
  static Future<void> initializeRepositories(BuildContext context) async {
    try {
      print('🔄 Initialisation des repositories...');

      // Obtenir les instances des services et repositories
      final socketService = context.read<SocketService>();
      final chatListRepository = context.read<ChatListRepository>();
      final authRepository = context.read<AuthRepository>();

      // Connecter ChatListRepository aux changements d'authentification
      await chatListRepository.initializeWithAuth(authRepository);

      print('✅ Repositories initialisés avec succès');
    } catch (e) {
      print('❌ Erreur initialisation repositories: $e');
      rethrow;
    }
  }

  /// Factory pour créer des ViewModels spécifiques à une conversation
  static ChangeNotifierProvider<MessageViewModel> createMessageViewModel(
    String conversationId,
  ) {
    return ChangeNotifierProvider<MessageViewModel>(
      create: (context) => MessageViewModel(
        messageRepository: context.read<MessageRepository>(),
        conversationId: conversationId,
        authViewModel: context.read<AuthViewModel>(),
      ),
    );
  }

  static ChangeNotifierProvider<ChatViewModel> createChatViewModel(
    String chatId,
  ) {
    return ChangeNotifierProvider<ChatViewModel>(
      create: (context) => ChatViewModel(
        context.read<MessageRepository>(),
        context.read<AuthRepository>(),
        chatId,
      ),
    );
  }
}
