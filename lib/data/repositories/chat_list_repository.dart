import 'dart:async';
import 'package:ngomna_chat/data/models/chat_model.dart';
import 'package:ngomna_chat/data/models/message_model.dart';
import 'package:ngomna_chat/data/services/socket_service.dart';
import 'package:ngomna_chat/data/services/hive_service.dart';
import 'package:ngomna_chat/data/repositories/auth_repository.dart';

class ChatListRepository {
  static ChatListRepository? _instance;

  final SocketService _socketService;
  final HiveService _hiveService;

  // Cache local des conversations
  final Map<String, Chat> _chatsCache = {};
  final StreamController<List<Chat>> _conversationUpdateController =
      StreamController<List<Chat>>.broadcast();

  Stream<List<Chat>> get chatsStream => _conversationUpdateController.stream;

  factory ChatListRepository({
    required SocketService socketService,
    required HiveService hiveService,
  }) {
    _instance ??= ChatListRepository._internal(
      socketService: socketService,
      hiveService: hiveService,
    );
    return _instance!;
  }

  ChatListRepository._internal({
    required SocketService socketService,
    required HiveService hiveService,
  })  : _socketService = socketService,
        _hiveService = hiveService {
    _setupSocketListeners();
    _initializeConversations();
  }

  /// Initialiser avec le repository d'authentification pour écouter les changements
  Future<void> initializeWithAuth(AuthRepository authRepository) async {
    print('🔐 [ChatListRepository] Initialisation avec AuthRepository');

    // Écouter les changements d'authentification
    authRepository.onAuthStateChanged.listen((isAuthenticated) {
      print('🔄 [ChatListRepository] Changement auth: $isAuthenticated');
      if (isAuthenticated) {
        // L'utilisateur s'est authentifié, demander les conversations
        print(
            '📥 [ChatListRepository] Utilisateur authentifié, demande des conversations');
        _socketService.requestConversations();
      } else {
        // L'utilisateur s'est déconnecté, vider le cache
        print(
            '🧹 [ChatListRepository] Utilisateur déconnecté, vidage du cache');
        _chatsCache.clear();
        _conversationUpdateController.add([]);
      }
    });

    // Si déjà authentifié au moment de l'initialisation, demander immédiatement
    final alreadyAuthenticated = await authRepository.isAuthenticated();
    if (alreadyAuthenticated) {
      print(
          '📥 [ChatListRepository] Déjà authentifié, demande des conversations');
      _socketService.requestConversations();
    }
  }

  /// Initialiser les conversations au démarrage
  void _initializeConversations() {
    // Si le socket est déjà authentifié, demander les conversations
    if (_socketService.isAuthenticated) {
      print(
          '🔄 [ChatListRepository] Socket déjà authentifié, demande des conversations');
      _socketService.requestConversations();
    } else {
      print('⏳ [ChatListRepository] Socket pas encore authentifié, en attente');
    }
  }

  /// Configurer les listeners Socket.IO
  void _setupSocketListeners() {
    print('🔌 [ChatListRepository] Configuration des listeners Socket.IO');
    // Nouveaux messages reçus (pour mettre à jour les conversations)
    _socketService.newMessageStream.listen(_handleNewMessage);

    // Confirmations d'envoi de messages
    _socketService.messageSentStream.listen(_handleMessageSent);

    // Conversations mises à jour depuis le serveur
    _socketService.conversationUpdateStream.listen(_handleConversationsLoaded);
    print(
        '👂 [ChatListRepository] Listener conversationUpdateStream configuré');
  }

  /// Charger les conversations
  Future<List<Chat>> loadConversations({bool forceRefresh = false}) async {
    print('📥 [ChatListRepository] loadConversations appelé');

    // Vérifier le cache en mémoire d'abord
    if (!forceRefresh && _chatsCache.isNotEmpty) {
      print(
          '✅ [ChatListRepository] Conversations trouvées dans le cache: ${_chatsCache.length}');
      return _chatsCache.values.toList();
    }

    // Vérifier Hive pour les conversations en cache
    try {
      final cachedChats = await _hiveService.getAllChats();

      if (cachedChats.isNotEmpty && !forceRefresh) {
        print(
            '💾 [ChatListRepository] Conversations trouvées dans Hive: ${cachedChats.length}');
        _updateChatsCache(cachedChats);
        return cachedChats;
      }

      // Si pas de cache ou forceRefresh, retourner le cache vide
      // Les conversations seront chargées automatiquement via les streams Socket.IO
      print(
          '📭 [ChatListRepository] Pas de conversations en cache, en attente des données serveur');
      return cachedChats; // Retourne liste vide ou cache existant
    } catch (e) {
      print('❌ [ChatListRepository] Erreur loadConversations: $e');
      rethrow;
    }
  }

  /// Mettre à jour le cache des conversations
  void _updateChatsCache(List<Chat> chats) {
    _chatsCache.clear();
    for (final chat in chats) {
      _chatsCache[chat.id] = chat;
    }
    _conversationUpdateController.add(chats);
  }

  /// Gérer un nouveau message reçu
  Future<void> _handleNewMessage(dynamic messageData) async {
    try {
      print('🧩 [ChatListRepository] _handleNewMessage appelé');
      Message? message;

      if (messageData is Message) {
        message = messageData;
      } else if (messageData is Map<String, dynamic>) {
        message = Message.fromJson(messageData);
      }

      if (message == null || message.conversationId.isEmpty) {
        print('⚠️ [ChatListRepository] Format de message inattendu');
        return;
      }

      print(
          '📨 [ChatListRepository] Message: id=${message.id}, conversationId=${message.conversationId}, senderId=${message.senderId}, timestamp=${message.timestamp.toIso8601String()}');

      final conversationId = message.conversationId;

      // Récupérer la conversation depuis Hive (plus sûr)
      print('💾 [ChatListRepository] Lecture Hive pour $conversationId');
      final chatFromHive = await _hiveService.getChat(conversationId);

      if (chatFromHive != null) {
        print(
            '✅ [ChatListRepository] Conversation trouvée dans Hive: ${chatFromHive.id}');
        print(
            '   - lastMessageAt (avant): ${chatFromHive.lastMessageAt.toIso8601String()}');
        print('   - lastMessage (avant): ${chatFromHive.lastMessage?.content}');

        // Extraire unreadCounts depuis userMetadata (source de vérité)
        final Map<String, int> updatedUnreadCounts = {};
        for (final metadata in chatFromHive.userMetadata) {
          updatedUnreadCounts[metadata.userId] = metadata.unreadCount;
        }

        print(
            '📌 [ChatListRepository] unreadCounts extraits de userMetadata: $updatedUnreadCounts');

        final updatedChat = chatFromHive.copyWith(
          lastMessage: LastMessage(
            content: message.content,
            type: Message.messageTypeToString(message.type),
            senderId: message.senderId,
            senderName: message.senderName,
            timestamp: message.timestamp,
          ),
          lastMessageAt: message.timestamp,
          updatedAt: DateTime.now(),
          unreadCounts: updatedUnreadCounts,
        );

        print(
            '✅ [ChatListRepository] lastMessageAt (après): ${updatedChat.lastMessageAt.toIso8601String()}');
        print(
            '✅ [ChatListRepository] lastMessage (après): ${updatedChat.lastMessage?.content}');

        _chatsCache[conversationId] = updatedChat;
        print(
            '📡 [ChatListRepository] Stream chats mis à jour (${_chatsCache.length} chats)');
        _conversationUpdateController.add(_chatsCache.values.toList());
        print('💾 [ChatListRepository] Sauvegarde Hive de ${updatedChat.id}');
        await _hiveService.saveChat(updatedChat);
        print('💾 [ChatListRepository] Sauvegarde Hive terminée');
      } else {
        print('⚠️ [ChatListRepository] Conversation absente dans Hive, reload');
        // Si la conversation n'est pas encore en cache, recharger
        await loadConversations(forceRefresh: true);
      }
    } catch (e) {
      print('❌ [ChatListRepository] Erreur _handleNewMessage: $e');
    }
  }

  /// Gérer la confirmation d'envoi de message
  Future<void> _handleMessageSent(dynamic response) async {
    print('📤 [ChatListRepository] Message envoyé confirmé');

    try {
      if (response is! MessageSentResponse) {
        print('⚠️ [ChatListRepository] Format message_sent inattendu');
        return;
      }

      final messageId = response.messageId;
      print('🔎 [ChatListRepository] messageId reçu: $messageId');

      // Attendre un court instant pour laisser Hive se mettre à jour
      await Future.delayed(const Duration(milliseconds: 200));

      final message = await _hiveService.getMessageById(messageId);
      if (message == null) {
        print(
            '⚠️ [ChatListRepository] Message introuvable dans Hive: $messageId');
        return;
      }

      final conversationId = message.conversationId;
      print(
          '✅ [ChatListRepository] Message trouvé: conv=$conversationId, content=${message.content}');

      final chatFromHive = await _hiveService.getChat(conversationId);
      if (chatFromHive == null) {
        print(
            '⚠️ [ChatListRepository] Conversation introuvable dans Hive: $conversationId');
        return;
      }

      final updatedChat = chatFromHive.copyWith(
        lastMessage: LastMessage(
          content: message.content,
          type: Message.messageTypeToString(message.type),
          senderId: message.senderId,
          senderName: message.senderName,
          timestamp: message.timestamp,
        ),
        lastMessageAt: message.timestamp,
        updatedAt: DateTime.now(),
      );

      _chatsCache[conversationId] = updatedChat;
      _conversationUpdateController.add(_chatsCache.values.toList());
      await _hiveService.saveChat(updatedChat);

      print(
          '✅ [ChatListRepository] lastMessage mis à jour pour $conversationId');
    } catch (e) {
      print('❌ [ChatListRepository] Erreur _handleMessageSent: $e');
    }
  }

  /// Gérer les conversations chargées depuis le serveur
  void _handleConversationsLoaded(Map<String, dynamic> data) {
    print('🚀 [ChatListRepository] _handleConversationsLoaded appelée');
    try {
      // Extraire les conversations des données
      List<Chat> chats = [];
      if (data['conversations'] is List) {
        final conversationsData = data['conversations'] as List;
        print('📋 Nombre de conversations reçues: ${conversationsData.length}');
        for (final convData in conversationsData) {
          try {
            final chat = Chat.fromJson(convData as Map<String, dynamic>);
            chats.add(chat);
            print('✅ Conversation parsée: ${chat.id}');
          } catch (e) {
            print('❌ Erreur conversion conversation: $e');
          }
        }
      } else {
        print('⚠️ Pas de clé "conversations" dans les données');
      }

      if (chats.isNotEmpty) {
        print('💾 Sauvegarde de ${chats.length} conversations dans Hive');
        _updateChatsCache(chats);
        _saveChatsToHive(chats);
      } else {
        print('⚠️ Aucune conversation valide trouvée');
      }
    } catch (e) {
      print('❌ [ChatListRepository] Erreur _handleConversationsLoaded: $e');
    }
  }

  /// Sauvegarder les conversations dans Hive
  Future<void> _saveChatsToHive(List<Chat> chats) async {
    try {
      for (final chat in chats) {
        await _hiveService.saveChat(chat);
      }
      print('💾 [ChatListRepository] Conversations sauvegardées dans Hive');
    } catch (e) {
      print('❌ [ChatListRepository] Erreur sauvegarde Hive: $e');
    }
  }

  /// Obtenir une conversation par ID
  Chat? getChatById(String chatId) {
    return _chatsCache[chatId];
  }

  /// Marquer une conversation comme lue
  Future<void> markChatAsRead(String chatId, String userId) async {
    if (_chatsCache.containsKey(chatId)) {
      final chat = _chatsCache[chatId]!;
      // Mettre à jour les unreadCounts
      final updatedChat = chat.copyWith(
        unreadCounts: {...chat.unreadCounts, userId: 0},
      );
      _chatsCache[chatId] = updatedChat;

      // Sauvegarder dans Hive
      await _hiveService.saveChat(updatedChat);

      // Notifier les listeners
      _conversationUpdateController.add(_chatsCache.values.toList());

      // Informer le serveur
      _socketService.markMessageRead(
          '', chatId); // TODO: Implémenter côté serveur
    }
  }

  /// Fermer les ressources
  void dispose() {
    _conversationUpdateController.close();
  }
}
