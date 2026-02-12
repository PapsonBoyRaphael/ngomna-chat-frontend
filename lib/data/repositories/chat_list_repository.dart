import 'dart:async';
import 'package:hive/hive.dart';
import 'package:ngomna_chat/data/models/chat_model.dart';
import 'package:ngomna_chat/data/models/message_model.dart';
import 'package:ngomna_chat/data/services/socket_service.dart';
import 'package:ngomna_chat/data/services/hive_service.dart';
import 'package:ngomna_chat/data/services/storage_service.dart';
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

    // Changements de statut des messages (pour mettre à jour les compteurs non lus)
    _socketService.messageStatusChangedStream
        .listen(_handleMessageStatusChanged);

    // Messages marqués comme lus (pour mettre à jour les compteurs non lus)
    _socketService.messageReadStream.listen(_handleMessageRead);

    // Conversations mises à jour depuis le serveur
    _socketService.conversationUpdateStream.listen(_handleConversationsLoaded);
    print(
        '👂 [ChatListRepository] Listener conversationUpdateStream configuré');

    // 🟢 Écouter les événements de présence
    _socketService.presenceUpdateStream.listen(_handlePresenceUpdate);
    print('👂 [ChatListRepository] Listener presenceUpdateStream configuré');

    // Écouter les événements de conversation depuis ChatStreamManager
    _socketService.streamManager.conversationStream
        .listen(_handleConversationEvent);
    print('👂 [ChatListRepository] Listener conversationStream configuré');

    // Écouter les nouveaux messages depuis ChatStreamManager
    _socketService.streamManager.messageStream.listen((event) {
      // Émettre les messages pour tous les contextes (private, group, channel)
      // mais pas les mises à jour de statut
      print(
          '🔍 [ChatListRepository] Événement ChatStreamManager reçu - type: ${event.type}, context: ${event.context}, source: ${event.source}');

      if (event.context == 'private' ||
          event.context == 'group' ||
          event.context == 'channel') {
        print(
            '📨 [ChatListRepository] Nouveau message depuis ChatStreamManager: ${event.messageId}');
        // Reconstruire la Map à partir de l'événement
        final messageData = {
          'messageId': event.messageId,
          'conversationId': event.conversationId,
          'senderId': event.senderId,
          'senderName': event.senderName,
          'content': event.content,
          'type': event.type,
          'status': event.status,
          'timestamp': event.timestamp.toIso8601String(),
          'metadata': event.metadata,
          'context': event.context,
        };
        _handleNewMessage(messageData);
      }
    });
    print('👂 [ChatListRepository] Listener messageStream configuré');
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
            '📌 [ChatListRepository] unreadCounts extraits de userMetadata (avant): $updatedUnreadCounts');

        // Incrémenter le unreadCount pour l'utilisateur courant si le message n'est pas de lui
        final currentUser = StorageService().getUser();
        print(
            '🔍 [ChatListRepository] Vérification utilisateur courant: currentUser=${currentUser?.matricule}, senderId=${message.senderId}');

        var updatedUserMetadata = chatFromHive.userMetadata;

        if (currentUser != null) {
          print(
              '✅ [ChatListRepository] currentUser trouvé: ${currentUser.matricule}');
          if (message.senderId != currentUser.matricule) {
            print(
                '✅ [ChatListRepository] Message de quelqu\'un d\'autre (${message.senderId}), incrémentant unreadCount');
            final currentCount =
                updatedUnreadCounts[currentUser.matricule] ?? 0;
            updatedUnreadCounts[currentUser.matricule] = currentCount + 1;
            print(
                '📈 [ChatListRepository] unreadCount incrémenté pour ${currentUser.matricule}: $currentCount -> ${currentCount + 1}');

            // Aussi mettre à jour userMetadata pour que le getter unreadCount retourne la bonne valeur
            updatedUserMetadata = chatFromHive.userMetadata.map((meta) {
              if (meta.userId == currentUser.matricule) {
                print(
                    '✅ [ChatListRepository] Mise à jour userMetadata unreadCount pour ${currentUser.matricule}: ${meta.unreadCount} -> ${currentCount + 1}');
                return ParticipantMetadata(
                  userId: meta.userId,
                  unreadCount: currentCount + 1,
                  lastReadAt: meta.lastReadAt,
                  isMuted: meta.isMuted,
                  isPinned: meta.isPinned,
                  customName: meta.customName,
                  notificationSettings: meta.notificationSettings,
                  nom: meta.nom,
                  prenom: meta.prenom,
                  avatar: meta.avatar,
                  metadataId: meta.metadataId,
                  sexe: meta.sexe,
                  departement: meta.departement,
                  ministere: meta.ministere,
                );
              }
              return meta;
            }).toList();
          } else {
            print(
                '⏭️ [ChatListRepository] Message de l\'utilisateur lui-même (${message.senderId}), pas d\'incrémentation');
          }
        } else {
          print(
              '❌ [ChatListRepository] currentUser est null, impossible d\'incrémenter unreadCount');
        }

        print(
            '📌 [ChatListRepository] unreadCounts mis à jour (après): $updatedUnreadCounts');

        final updatedChat = chatFromHive.copyWith(
          lastMessage: LastMessage(
            id: message.id,
            content: message.content,
            type: Message.messageTypeToString(message.type),
            senderId: message.senderId,
            senderName: message.senderName,
            timestamp: message.timestamp,
            status: message.status,
          ),
          lastMessageAt: message.timestamp,
          updatedAt: DateTime.now(),
          unreadCounts: updatedUnreadCounts,
          userMetadata: updatedUserMetadata,
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
          id: message.id,
          content: message.content,
          type: Message.messageTypeToString(message.type),
          senderId: message.senderId,
          senderName: message.senderName,
          timestamp: message.timestamp,
          status: message.status,
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
            print('✅ Conversation parsée: ${chat.id} (${chat.name})');

            // 🟢 Afficher les données de présence des participants
            print('   👥 Participants avec présence:');
            for (final metadata in chat.userMetadata) {
              final presence = metadata.presence;
              if (presence != null) {
                print(
                    '      - ${metadata.nom} ${metadata.prenom} (${metadata.userId}): '
                    '${presence.isOnline ? "🟢 EN LIGNE" : "🔴 HORS LIGNE"} '
                    '(status: ${presence.status}, lastActivity: ${presence.lastActivity})');
              } else {
                print(
                    '      - ${metadata.nom} ${metadata.prenom} (${metadata.userId}): ⚪ Pas de données de présence');
              }
            }

            // 🟢 Afficher les statistiques de présence globales
            final stats = chat.presenceStats;
            if (stats != null) {
              print(
                  '   📊 Stats présence: ${stats.onlineCount}/${stats.totalParticipants} en ligne');
              print('      - En ligne: ${stats.onlineParticipants.join(", ")}');
            } else {
              print('   📊 Stats présence: Non disponibles');
            }
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
      print(
          '🔍 [ChatListRepository] Début sauvegarde ${chats.length} conversations');
      print('🔧 Vérification adapters AVANT sauvegarde:');
      print('   - UserPresence (typeId 20): ${Hive.isAdapterRegistered(20)}');
      print('   - PresenceStats (typeId 21): ${Hive.isAdapterRegistered(21)}');

      for (final chat in chats) {
        await _hiveService.saveChat(chat);
      }
      print('💾 [ChatListRepository] Conversations sauvegardées dans Hive');
    } catch (e, stackTrace) {
      print('❌ [ChatListRepository] Erreur sauvegarde Hive: $e');
      print(
          '📍 StackTrace: ${stackTrace.toString().split('\n').take(5).join('\n')}');
    }
  }

  /// 🟢 Gérer les événements de présence utilisateur
  void _handlePresenceUpdate(Map<String, dynamic> eventData) {
    print('🟢 [ChatListRepository] Événement présence reçu');
    try {
      final type = eventData['type'] as String?;
      final data = eventData['data'];

      print('   - Type: $type');
      print('   - Data: $data');

      switch (type) {
        case 'update':
          // Un utilisateur a changé de statut (online/offline)
          if (data is Map<String, dynamic>) {
            final userId = data['userId'] as String?;
            final isOnline = data['isOnline'] as bool?;
            final status = data['status'] as String?;
            print(
                '   🔄 Mise à jour présence: userId=$userId, isOnline=$isOnline, status=$status');

            // TODO: Mettre à jour le statut de présence dans le cache des conversations
            _updateUserPresenceInCache(userId, isOnline, status);
          }
          break;

        case 'online_users':
          // Liste des utilisateurs en ligne dans une conversation
          if (data is Map<String, dynamic>) {
            final conversationId = data['conversationId'] as String?;
            final onlineUsers = data['onlineUsers'] as List?;
            print(
                '   👥 Utilisateurs en ligne dans $conversationId: ${onlineUsers?.length ?? 0}');

            // TODO: Mettre à jour la liste des utilisateurs en ligne
            _updateOnlineUsersInConversation(conversationId, onlineUsers);
          }
          break;

        case 'user_online':
          // 🆕 Un utilisateur vient de se connecter
          if (data is Map<String, dynamic>) {
            final userId = data['userId'] as String?;
            final matricule = data['matricule'] as String?;
            final timestamp = data['timestamp'];
            print(
                '   🟢 Utilisateur EN LIGNE: userId=$userId, matricule=$matricule');
            _updateUserPresenceInCache(userId ?? matricule, true, 'online');
          }
          break;

        case 'user_offline':
          // 🆕 Un utilisateur vient de se déconnecter
          if (data is Map<String, dynamic>) {
            final userId = data['userId'] as String?;
            final matricule = data['matricule'] as String?;
            final timestamp = data['timestamp'];
            print(
                '   🔴 Utilisateur HORS LIGNE: userId=$userId, matricule=$matricule');
            _updateUserPresenceInCache(userId ?? matricule, false, 'offline');
          }
          break;

        default:
          print('   ⚠️ Type d\'événement présence non géré: $type');
      }
    } catch (e, stackTrace) {
      print('❌ [ChatListRepository] Erreur _handlePresenceUpdate: $e');
      print(
          '📍 StackTrace: ${stackTrace.toString().split('\n').take(3).join('\n')}');
    }
  }

  /// Mettre à jour la présence d'un utilisateur dans le cache
  void _updateUserPresenceInCache(
      String? userId, bool? isOnline, String? status) {
    if (userId == null) return;

    print('🔄 [ChatListRepository] Mise à jour présence cache pour $userId');
    print('   - isOnline: $isOnline, status: $status');

    int updatedCount = 0;

    // Parcourir toutes les conversations et mettre à jour la présence
    for (final chatId in _chatsCache.keys.toList()) {
      final chat = _chatsCache[chatId]!;
      final participantIndex =
          chat.userMetadata.indexWhere((m) => m.userId == userId);

      if (participantIndex != -1) {
        print('   ✅ Utilisateur $userId trouvé dans conversation ${chat.id}');

        // Créer une nouvelle UserPresence
        final newPresence = UserPresence(
          isOnline: isOnline ?? false,
          status: status ?? (isOnline == true ? 'online' : 'offline'),
          lastActivity: DateTime.now(),
          disconnectedAt: isOnline == false ? DateTime.now() : null,
        );

        // Créer une copie du participant avec la nouvelle présence
        final updatedParticipant = chat.userMetadata[participantIndex].copyWith(
          presence: newPresence,
        );

        // Créer une nouvelle liste de userMetadata
        final updatedUserMetadata =
            List<ParticipantMetadata>.from(chat.userMetadata);
        updatedUserMetadata[participantIndex] = updatedParticipant;

        // Créer une nouvelle instance de Chat avec les métadonnées mises à jour
        final updatedChat = chat.copyWith(userMetadata: updatedUserMetadata);

        // Mettre à jour le cache
        _chatsCache[chatId] = updatedChat;
        updatedCount++;

        print(
            '   ✅ Présence mise à jour: ${updatedParticipant.userId} -> isOnline=${newPresence.isOnline}');
      }
    }

    print('📨 Conversations mises à jour: $updatedCount');

    // Notifier les listeners avec les données mises à jour
    _conversationUpdateController.add(_chatsCache.values.toList());
  }

  /// Mettre à jour la liste des utilisateurs en ligne dans une conversation
  void _updateOnlineUsersInConversation(
      String? conversationId, List? onlineUsers) {
    if (conversationId == null) return;

    print(
        '🔄 [ChatListRepository] Mise à jour utilisateurs en ligne pour $conversationId');
    print('   - Utilisateurs en ligne: $onlineUsers');

    final chat = _chatsCache[conversationId];
    if (chat != null) {
      print('   ✅ Conversation trouvée dans le cache');
      // TODO: Mettre à jour les presenceStats
    } else {
      print('   ⚠️ Conversation $conversationId non trouvée dans le cache');
    }
  }

  /// Gérer les événements de conversation depuis ChatStreamManager
  void _handleConversationEvent(dynamic eventData) {
    print('🔔 [ChatListRepository] Événement conversation reçu');
    try {
      if (eventData is Map<String, dynamic>) {
        final conversationId = eventData['conversationId'] as String?;
        final event = eventData['event'] as String?;
        final data = eventData['data'] as Map<String, dynamic>?;

        print('📋 Event: $event, ConversationId: $conversationId');

        if (conversationId == null || event == null) {
          print('⚠️ Événement incomplet ignoré');
          return;
        }

        switch (event) {
          case 'created':
            _handleConversationCreated(data);
            break;
          case 'updated':
            _handleConversationUpdated(conversationId, data);
            break;
          case 'deleted':
            _handleConversationDeleted(conversationId);
            break;
          case 'participant_added':
          case 'participant_removed':
            _handleConversationUpdated(conversationId, data);
            break;
          default:
            print('⚠️ Type d\'événement non géré: $event');
        }
      }
    } catch (e) {
      print('❌ [ChatListRepository] Erreur _handleConversationEvent: $e');
    }
  }

  /// Gérer la création d'une conversation
  void _handleConversationCreated(Map<String, dynamic>? data) {
    if (data == null) return;

    try {
      final chat = Chat.fromJson(data);
      _chatsCache[chat.id] = chat;
      _hiveService.saveChat(chat);
      _conversationUpdateController.add(_chatsCache.values.toList());
      print('✅ [ChatListRepository] Nouvelle conversation ajoutée: ${chat.id}');
    } catch (e) {
      print('❌ [ChatListRepository] Erreur _handleConversationCreated: $e');
    }
  }

  /// Gérer la mise à jour d'une conversation
  void _handleConversationUpdated(
      String conversationId, Map<String, dynamic>? data) {
    if (data == null) return;

    try {
      final chat = Chat.fromJson(data);
      _chatsCache[conversationId] = chat;
      _hiveService.saveChat(chat);
      _conversationUpdateController.add(_chatsCache.values.toList());
      print('✅ [ChatListRepository] Conversation mise à jour: $conversationId');
    } catch (e) {
      print('❌ [ChatListRepository] Erreur _handleConversationUpdated: $e');
    }
  }

  /// Gérer la suppression d'une conversation
  void _handleConversationDeleted(String conversationId) {
    try {
      _chatsCache.remove(conversationId);
      _hiveService.deleteChat(conversationId);
      _conversationUpdateController.add(_chatsCache.values.toList());
      print('✅ [ChatListRepository] Conversation supprimée: $conversationId');
    } catch (e) {
      print('❌ [ChatListRepository] Erreur _handleConversationDeleted: $e');
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

      print(
          '🔍 [ChatListRepository] Marquage comme lu - chatId: $chatId, userId: $userId');
      print(
          '📊 userMetadata avant: ${chat.userMetadata.map((m) => '${m.userId}:${m.unreadCount}').join(', ')}');

      // Mettre à jour le unreadCount dans userMetadata pour l'utilisateur actuel
      final updatedUserMetadata = chat.userMetadata.map((meta) {
        if (meta.userId == userId) {
          print(
              '✅ Trouvé userMetadata pour $userId, mise à jour unreadCount de ${meta.unreadCount} à 0');
          return ParticipantMetadata(
            userId: meta.userId,
            unreadCount: 0,
            lastReadAt: DateTime.now(),
            isMuted: meta.isMuted,
            isPinned: meta.isPinned,
            customName: meta.customName,
            notificationSettings: meta.notificationSettings,
            nom: meta.nom,
            prenom: meta.prenom,
            avatar: meta.avatar,
            metadataId: meta.metadataId,
            sexe: meta.sexe,
            departement: meta.departement,
            ministere: meta.ministere,
          );
        }
        return meta;
      }).toList();

      // Aussi mettre à jour unreadCounts pour compatibilité
      final updatedUnreadCounts = {...chat.unreadCounts, userId: 0};

      final updatedChat = chat.copyWith(
        userMetadata: updatedUserMetadata,
        unreadCounts: updatedUnreadCounts,
      );

      _chatsCache[chatId] = updatedChat;

      print(
          '📊 userMetadata après: ${updatedChat.userMetadata.map((m) => '${m.userId}:${m.unreadCount}').join(', ')}');

      // Sauvegarder dans Hive
      await _hiveService.saveChat(updatedChat);

      // Notifier les listeners
      _conversationUpdateController.add(_chatsCache.values.toList());
      print(
          '✅ [ChatListRepository] Conversation $chatId marquée comme lue pour $userId');
    } else {
      print(
          '⚠️ [ChatListRepository] Conversation $chatId introuvable dans le cache');
    }
  }

  /// Fermer les ressources
  void dispose() {
    _conversationUpdateController.close();
  }

  /// Gérer les changements de statut des messages
  void _handleMessageStatusChanged(Map<String, dynamic> data) {
    // Vérifier que l'utilisateur est authentifié avant de traiter l'événement
    if (!_socketService.isAuthenticated) {
      print(
          '⚠️ [ChatListRepository] Événement messageStatusChanged ignoré - utilisateur non authentifié');
      return;
    }

    final messageId = data['messageId'] as String?;
    final status = data['status'] as String?;
    final userId = data['userId'] as String?;
    final conversationId = data['conversationId'] as String?;

    if (messageId == null || status == null) {
      print('❌ Données invalides pour messageStatusChanged: $data');
      return;
    }

    print(
        '🔄 [ChatListRepository] Changement de statut reçu: $messageId -> $status pour user $userId');

    // Mettre à jour le lastMessage si c'est le message concerné
    _updateLastMessageStatus(messageId, status, conversationId);

    // Si le statut est "READ", mettre à jour les compteurs non lus
    if (status == 'READ' && userId != null) {
      _updateUnreadCountForUser(userId);
    }
  }

  /// Mettre à jour le statut du lastMessage dans le cache
  void _updateLastMessageStatus(
      String messageId, String status, String? conversationId) {
    final newStatus = Message.parseMessageStatus(status);
    int updatedCount = 0;

    // Si on a l'ID de conversation, on cherche directement
    if (conversationId != null && _chatsCache.containsKey(conversationId)) {
      final chat = _chatsCache[conversationId]!;
      if (chat.lastMessage != null && chat.lastMessage!.id == messageId) {
        final updatedLastMessage =
            chat.lastMessage!.copyWith(status: newStatus);
        final updatedChat = chat.copyWith(lastMessage: updatedLastMessage);
        _chatsCache[conversationId] = updatedChat;
        updatedCount++;
        print(
            '   ✅ LastMessage mis à jour dans conversation $conversationId: $status');
      }
    } else {
      // Sinon, parcourir toutes les conversations
      for (final chatId in _chatsCache.keys.toList()) {
        final chat = _chatsCache[chatId]!;
        if (chat.lastMessage != null && chat.lastMessage!.id == messageId) {
          final updatedLastMessage =
              chat.lastMessage!.copyWith(status: newStatus);
          final updatedChat = chat.copyWith(lastMessage: updatedLastMessage);
          _chatsCache[chatId] = updatedChat;
          updatedCount++;
          print(
              '   ✅ LastMessage mis à jour dans conversation $chatId: $status');
        }
      }
    }

    if (updatedCount > 0) {
      print('📨 LastMessage statut mis à jour: $updatedCount conversations');
      _conversationUpdateController.add(_chatsCache.values.toList());
    }
  }

  /// Gérer les messages marqués comme lus
  void _handleMessageRead(Map<String, dynamic> data) {
    // Vérifier que l'utilisateur est authentifié avant de traiter l'événement
    if (!_socketService.isAuthenticated) {
      print(
          '⚠️ [ChatListRepository] Événement messageRead ignoré - utilisateur non authentifié');
      return;
    }

    final messageId = data['messageId'] as String?;
    final status = data['status'] as String?;

    if (messageId == null || status != 'READ') {
      print('❌ Données invalides pour messageRead: $data');
      return;
    }

    print('📖 [ChatListRepository] Message marqué comme lu: $messageId');

    // Mettre à jour les compteurs non lus pour l'utilisateur actuel
    // (l'événement messageRead est envoyé à l'utilisateur qui a marqué le message comme lu)
    final currentUser = StorageService().getUser();
    if (currentUser != null) {
      _updateUnreadCountForUser(currentUser.matricule);
    }
  }

  /// Mettre à jour les compteurs non lus pour un utilisateur spécifique
  void _updateUnreadCountForUser(String userId) {
    print(
        '🔄 [ChatListRepository] Mise à jour des compteurs non lus pour user: $userId');

    // Pour chaque conversation, recalculer le nombre de messages non lus
    // Cette logique devrait être alignée avec celle du serveur
    bool hasUpdates = false;

    for (final chatId in _chatsCache.keys) {
      final chat = _chatsCache[chatId]!;

      // Le serveur devrait avoir mis à jour les userMetadata, mais comme on reçoit
      // l'événement, on peut décrémenter le compteur localement
      final currentCount = chat.unreadCounts[userId] ?? 0;
      if (currentCount > 0) {
        final updatedChat = chat.copyWith(
          unreadCounts: {...chat.unreadCounts, userId: currentCount - 1},
        );
        _chatsCache[chatId] = updatedChat;
        hasUpdates = true;
        print(
            '📉 [ChatListRepository] Compteur décrémenté pour $chatId: $currentCount -> ${currentCount - 1}');
      }
    }

    if (hasUpdates) {
      // Notifier les listeners avec les conversations mises à jour
      _conversationUpdateController.add(_chatsCache.values.toList());
      print(
          '📢 [ChatListRepository] Notifications envoyées pour mise à jour des compteurs');
    }
  }
}
