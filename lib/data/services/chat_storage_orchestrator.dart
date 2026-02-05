import 'dart:async';
import 'package:ngomna_chat/data/models/message_model.dart';
import 'package:ngomna_chat/data/models/chat_model.dart';
import 'package:ngomna_chat/data/services/chat_stream_manager.dart';
import 'package:ngomna_chat/data/services/hive_service.dart';

/// Orchestrateur de synchronisation entre Streams et Hive
///
/// Gère les dépendances bidirectionnelles:
/// - Streams → Hive: Sauvegarder les données
/// - Hive → Streams: Charger à la connexion
/// - Optimistic updates: UI immédiate + sync serveur
///
/// Pattern:
/// 1. UI émet une action (sendMessage)
/// 2. Optimistic update dans Hive (status: 'sending')
/// 3. Émettre via messageStream (UI se met à jour)
/// 4. Appel serveur asynchrone
/// 5. Mettre à jour Hive + émettre nouveau stream
class ChatStorageOrchestrator {
  final ChatStreamManager _streamManager;
  final HiveService _hiveService = HiveService();

  // Subscriptions pour cleanup
  final List<StreamSubscription> _subscriptions = [];
  bool _bindingsInitialized = false;

  ChatStorageOrchestrator(this._streamManager);

  /// Configure les bindings entre Streams et Hive
  /// À appeler une seule fois au démarrage
  void setupStreamToHiveBindings() {
    if (_bindingsInitialized) {
      return;
    }
    _bindingsInitialized = true;

    // BINDING 1: Messages → Hive
    _subscriptions.add(
      _streamManager.messageStream.listen(
        (messageEvent) async {
          // ✅ FILTRE CRITIQUE: Ignorer les événements qu'on a générés nous-mêmes
          if (messageEvent.isOrchestrated ||
              messageEvent.source == EventSource.orchestration) {
            return;
          }
          await _handleMessageEvent(messageEvent);
        },
        onError: (error) {},
      ),
    );

    // BINDING 2: Message Status → Hive
    _subscriptions.add(
      _streamManager.messageStatusStream.listen(
        (statusEvent) async {
          await _updateMessageStatusInHive(statusEvent);
        },
      ),
    );

    // BINDING 3: Conversation Events → Hive
    _subscriptions.add(
      _streamManager.conversationStream.listen(
        (convEvent) async {
          await _handleConversationEvent(convEvent);
        },
      ),
    );

    // BINDING 4: File Events → Hive
    _subscriptions.add(
      _streamManager.fileStream.listen(
        (fileEvent) async {
          await _cacheFileMetadata(fileEvent);
        },
      ),
    );
  }

  // ════════════════════════════════════════════════════════════════
  // HANDLER 1: Message Events → Hive
  // ════════════════════════════════════════════════════════════════

  /// Traite les événements de messages et les sauvegarde dans Hive
  Future<void> _handleMessageEvent(MessageEvent event) async {
    try {
      switch (event.type) {
        // Messages standards - sauvegarder dans Hive
        case 'TEXT':
        case 'IMAGE':
        case 'FILE':
        case 'AUDIO':
        case 'VIDEO':
          await _saveMessageToHive(event);
          await _updateConversationLastMessage(event);
          break;

        // ────────────────────────────────────────────────────────────
        // Événement orchestré: Status Update
        // ────────────────────────────────────────────────────────────
        case 'STATUS_UPDATE':
          print('🔄 [StorageOrchestrator] STATUS_UPDATE - Mise à jour Hive');
          final existingMessage =
              await _hiveService.getMessageById(event.messageId);
          if (existingMessage != null) {
            final updated = existingMessage.copyWith(
              status: _mapEventStatusToMessageStatus(event.status),
            );
            await _hiveService.saveMessage(updated);
            print(
                '✅ [StorageOrchestrator] Message ${event.messageId} mis à jour');
          }
          break;

        // ────────────────────────────────────────────────────────────
        // Événement orchestré: Conversation Deleted
        // ────────────────────────────────────────────────────────────
        case 'CONVERSATION_DELETED':
          print(
              '🗑️ [StorageOrchestrator] CONVERSATION_DELETED - Nettoyage Hive');
          await _hiveService
              .deleteMessagesForConversation(event.conversationId);
          print(
              '✅ [StorageOrchestrator] Messages supprimés pour conversation ${event.conversationId}');
          break;

        // ────────────────────────────────────────────────────────────
        // Événement orchestré: Participant Removed
        // ────────────────────────────────────────────────────────────
        case 'PARTICIPANT_REMOVED':
          print(
              '👤 [StorageOrchestrator] PARTICIPANT_REMOVED - Restriction d\'accès');
          final messagesToRestrict = await _hiveService
              .getMessagesForConversation(event.conversationId);

          for (final message in messagesToRestrict) {
            final existingMetadata =
                message.metadata?.toJson() ?? <String, dynamic>{};
            final updated = message.copyWith(
              metadata: MessageMetadata.fromJson({
                ...existingMetadata,
                'restricted': true,
              }),
            );
            await _hiveService.saveMessage(updated);
          }
          print(
              '✅ [StorageOrchestrator] ${messagesToRestrict.length} messages restreints');
          break;

        // ────────────────────────────────────────────────────────────
        // Événement orchestré: Message Interaction
        // ────────────────────────────────────────────────────────────
        case 'MESSAGE_INTERACTION':
          print('⭐ [StorageOrchestrator] MESSAGE_INTERACTION - Mise à jour');
          final messageWithInteraction =
              await _hiveService.getMessageById(event.messageId);
          if (messageWithInteraction != null) {
            final existingMetadata =
                messageWithInteraction.metadata?.toJson() ??
                    <String, dynamic>{};
            final updated = messageWithInteraction.copyWith(
              metadata: MessageMetadata.fromJson({
                ...existingMetadata,
                'lastInteraction': event.metadata,
                'lastInteractionAt': event.timestamp.toIso8601String(),
              }),
            );
            await _hiveService.saveMessage(updated);
          }
          break;

        default:
          print('⚠️ [StorageOrchestrator] Type inconnu: ${event.type}');
      }
    } catch (e) {
      print('❌ [StorageOrchestrator] Erreur _handleMessageEvent: $e');
      rethrow;
    }
  }

  /// Sauvegarde un message dans Hive
  Future<void> _saveMessageToHive(MessageEvent event) async {
    try {
      final message = Message(
        id: event.messageId,
        conversationId: event.conversationId,
        senderId: event.senderId,
        senderName: event.senderName ?? '',
        content: event.content,
        type: _mapEventTypeToMessageType(event.type),
        status: _mapEventStatusToMessageStatus(event.status),
        createdAt: event.timestamp,
        receiverId: '', // Sera rempli selon le contexte
        metadata: event.metadata.isNotEmpty
            ? MessageMetadata.fromJson(event.metadata)
            : null,
      );
      await _hiveService.saveMessage(message);
    } catch (e) {
      print('❌ [StorageOrchestrator] Erreur save message: $e');
      rethrow;
    }
  }

  /// Met à jour le dernier message d'une conversation
  Future<void> _updateConversationLastMessage(MessageEvent event) async {
    try {
      final conversation = await _hiveService.getChatById(event.conversationId);

      if (conversation != null) {
        final updated = conversation.copyWith(
          lastMessage: LastMessage(
            content: event.content,
            type: _mapEventTypeToString(event.type),
            senderId: event.senderId,
            senderName: event.senderName,
            timestamp: event.timestamp,
            status: _mapEventStatusToMessageStatus(event.status),
          ),
          lastMessageAt: event.timestamp,
        );
        await _hiveService.saveChat(updated);
      }
    } catch (e) {
      print('❌ [StorageOrchestrator] Erreur update conversation: $e');
    }
  }

  // ════════════════════════════════════════════════════════════════
  // HANDLER 2: Message Status → Hive
  // ════════════════════════════════════════════════════════════════

  /// Met à jour le statut d'un message dans Hive
  Future<void> _updateMessageStatusInHive(MessageStatusEvent event) async {
    try {
      final message = await _hiveService.getMessageById(event.messageId);

      if (message != null) {
        final updated = message.copyWith(
          status: _mapEventStatusToMessageStatus(event.status),
        );

        await _hiveService.saveMessage(updated);

        if (event.status == 'read') {
          await _updateConversationLastRead(event.messageId, event.userId);
        }
      }
    } catch (e) {
      print('❌ [StorageOrchestrator] Erreur update status: $e');
      rethrow;
    }
  }

  /// Met à jour le lastRead pour une conversation
  Future<void> _updateConversationLastRead(
    String messageId,
    String userId,
  ) async {
    try {
      final message = await _hiveService.getMessageById(messageId);

      if (message != null) {
        final conversation =
            await _hiveService.getChatById(message.conversationId);

        if (conversation != null) {
          // Mettre à jour le lastReadAt pour cet utilisateur dans userMetadata
          final updatedMetadata = conversation.userMetadata.map((meta) {
            if (meta.userId == userId) {
              return ParticipantMetadata(
                userId: meta.userId,
                unreadCount: 0, // Réinitialiser le compteur non-lu
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

          final updatedUnreadCounts = Map<String, int>.from(
            conversation.unreadCounts,
          )..[userId] = 0;

          final updated = conversation.copyWith(
            userMetadata: updatedMetadata,
            unreadCounts: updatedUnreadCounts,
          );

          await _hiveService.saveChat(updated);
          print(
              '🔍 [StorageOrchestrator] LastRead updated for user $userId in conversation ${message.conversationId}');
        }
      }
    } catch (e) {
      print('❌ [StorageOrchestrator] Erreur update lastRead: $e');
    }
  }

  // ════════════════════════════════════════════════════════════════
  // HANDLER 3: Conversation Events → Hive
  // ════════════════════════════════════════════════════════════════

  /// Traite les événements de conversation
  Future<void> _handleConversationEvent(ConversationEvent event) async {
    try {
      switch (event.event) {
        // ────────────────────────────────────────────────────────────
        // Nouvelle conversation créée
        // ────────────────────────────────────────────────────────────
        case 'created':
          await _saveConversationToHive(event);
          break;

        // ────────────────────────────────────────────────────────────
        // Conversation mise à jour (nom, photo, etc.)
        // ────────────────────────────────────────────────────────────
        case 'updated':
          final existing = await _hiveService.getChatById(event.conversationId);
          if (existing != null) {
            final incomingUserMetadata =
                _parseUserMetadata(event.data['userMetadata']);
            final incomingUnreadCounts = _parseUnreadCounts(
              event.data['unreadCounts'],
              fallbackFrom: incomingUserMetadata,
            );

            final updated = existing.copyWith(
              name: event.data['name'] ?? existing.name,
              description: event.data['description'] ?? existing.description,
              userMetadata: incomingUserMetadata.isNotEmpty
                  ? incomingUserMetadata
                  : existing.userMetadata,
              unreadCounts: incomingUnreadCounts.isNotEmpty
                  ? incomingUnreadCounts
                  : existing.unreadCounts,
              updatedAt: event.timestamp,
            );
            await _hiveService.saveChat(updated);
          }
          break;

        // ────────────────────────────────────────────────────────────
        // Conversation supprimée
        // ────────────────────────────────────────────────────────────
        case 'deleted':
          await _hiveService.deleteChat(event.conversationId);
          // Nettoyer aussi les messages de la conversation
          await _hiveService
              .deleteMessagesForConversation(event.conversationId);
          break;

        case 'participant_added':
          final conv = await _hiveService.getChatById(event.conversationId);
          if (conv != null) {
            final userId = event.data['participantId'] ?? event.userId;
            final participants = {
              ...conv.participants,
              if (userId != null) userId,
            }.toList();

            final incomingUserMetadata =
                _parseUserMetadata(event.data['userMetadata']);
            final incomingSingle = _parseSingleParticipant(
              event.data['participant'],
            );

            final updatedUserMetadata = incomingUserMetadata.isNotEmpty
                ? incomingUserMetadata
                : [
                    ...conv.userMetadata,
                    if (incomingSingle != null)
                      incomingSingle
                    else if (userId != null)
                      _fallbackParticipant(userId),
                  ];

            final updatedUnreadCounts = _parseUnreadCounts(
              event.data['unreadCounts'],
              fallbackFrom: updatedUserMetadata,
            );

            final updated = conv.copyWith(
              participants: List<String>.from(participants),
              userMetadata: updatedUserMetadata,
              unreadCounts: updatedUnreadCounts.isNotEmpty
                  ? updatedUnreadCounts
                  : conv.unreadCounts,
              updatedAt: event.timestamp,
            );
            await _hiveService.saveChat(updated);
          }
          break;

        // ────────────────────────────────────────────────────────────
        // Participant retiré
        // ────────────────────────────────────────────────────────────
        case 'participant_removed':
          final conv = await _hiveService.getChatById(event.conversationId);
          if (conv != null) {
            final userId = event.data['participantId'] ?? event.userId;
            final participants =
                conv.participants.where((p) => p != userId).toList();

            final updatedUserMetadata = userId == null
                ? conv.userMetadata
                : conv.userMetadata.where((m) => m.userId != userId).toList();

            final updatedUnreadCounts = Map<String, int>.from(
              conv.unreadCounts,
            )..remove(userId);

            final updated = conv.copyWith(
              participants: List<String>.from(participants),
              userMetadata: updatedUserMetadata,
              unreadCounts: updatedUnreadCounts,
              updatedAt: event.timestamp,
            );
            await _hiveService.saveChat(updated);
          }
          break;

        default:
      }
    } catch (e) {
      // Erreur gérée silencieusement
    }
  }

  /// Sauvegarde une conversation dans Hive
  Future<void> _saveConversationToHive(
    ConversationEvent event,
  ) async {
    try {
      // Déterminer le type de conversation selon le nombre de participants
      final participants = List<String>.from(event.data['participants'] ?? []);
      final chatType = participants.length == 2
          ? ChatType.personal // Conversation 1:1
          : ChatType.group; // Conversation groupe

      final userMetadata = _parseUserMetadata(event.data['userMetadata']);
      final unreadCounts = _parseUnreadCounts(
        event.data['unreadCounts'],
        fallbackFrom: userMetadata,
      );

      final conversation = Chat(
        id: event.conversationId,
        name: event.data['name'] ?? 'Unnamed',
        type: chatType,
        description: event.data['description'],
        participants: participants,
        createdBy: event.userId ?? '',
        userMetadata: userMetadata,
        unreadCounts: unreadCounts,
        lastMessage: null,
        lastMessageAt: event.timestamp,
        settings: ChatSettings(),
        metadata: ChatMetadata(
          stats: ChatStats(lastActivity: event.timestamp),
        ),
        integrations: ChatIntegrations(),
        createdAt: event.timestamp,
        updatedAt: event.timestamp,
      );

      await _hiveService.saveChat(conversation);
    } catch (e) {
      // Erreur gérée silencieusement
    }
  }

  // ════════════════════════════════════════════════════════════════
  // HANDLER 4: File Events → Hive (Métadonnées)
  // ════════════════════════════════════════════════════════════════

  /// Cache les métadonnées des fichiers
  Future<void> _cacheFileMetadata(FileEvent event) async {
    try {
      if (event.event == 'uploaded') {
        print('📁 [StorageOrchestrator] Fichier uploadé: ${event.fileName}');

        // Les métadonnées du fichier sont stockées dans les metadata du message
        // (Le message correspondant aura déjà été créé)
        print('✅ [StorageOrchestrator] Métadonnées fichier cachées');
      }
    } catch (e) {
      print('❌ [StorageOrchestrator] Erreur cache file: $e');
    }
  }

  // ════════════════════════════════════════════════════════════════
  // SYNCHRONISATION: Hive → Streams (au démarrage)
  // ════════════════════════════════════════════════════════════════

  /// Synchronise les données de Hive vers les streams au démarrage
  /// Chargement des messages non envoyés, conversations en cache, etc.
  Future<void> syncHiveToStreams() async {
    try {
      // S'assurer que les listeners sont prêts avant d'émettre depuis Hive
      setupStreamToHiveBindings();

      print('🔄 [StorageOrchestrator] Synchronisation Hive → Streams');

      // ────────────────────────────────────────────────────────────
      // 1. Charger les messages en attente
      // ────────────────────────────────────────────────────────────
      await _syncPendingMessages();

      // ────────────────────────────────────────────────────────────
      // 2. Charger les conversations en cache
      // ────────────────────────────────────────────────────────────
      await _syncCachedConversations();
    } catch (e) {
      print('[ERROR] Sync démarrage: $e');
      rethrow;
    }
  }

  /// Charge et réémet les messages en attente de Hive
  Future<void> _syncPendingMessages() async {
    try {
      // Récupérer tous les messages du cache
      final allMessages = await _hiveService.getAllMessages();

      // Filtrer les messages avec status 'sending' ou 'failed'
      final pendingMessages = allMessages
          .where((m) =>
              m.status == MessageStatus.sending ||
              m.status == MessageStatus.failed)
          .toList();

      print(
          '📨 [StorageOrchestrator] ${pendingMessages.length} messages en attente');

      // Réémettre chaque message en attente
      for (final message in pendingMessages) {
        _streamManager.emitMessage(MessageEvent(
          messageId: message.id,
          conversationId: message.conversationId,
          senderId: message.senderId,
          senderName: message.senderName,
          content: message.content,
          type: _mapMessageTypeToEventType(message.type),
          status: message.status.name.toLowerCase(),
          timestamp: message.createdAt,
          metadata: message.metadata?.toJson() ?? <String, dynamic>{},
          context: 'cached',
          source: EventSource.storage,
          isOrchestrated: true,
        ));
      }
    } catch (e) {
      print('[ERROR] Sync pending: $e');
    }
  }

  /// Charge et réémet les conversations en cache de Hive
  Future<void> _syncCachedConversations() async {
    try {
      // Récupérer toutes les conversations en cache
      final conversations = await _hiveService.getAllChats();

      for (final conversation in conversations) {
        // Réémettre via conversationStream avec le type spécial 'cached'
        _streamManager.emitConversation(ConversationEvent(
          conversationId: conversation.id,
          event: 'cached', // Type spécial pour indiquer que ça vient du cache
          data: {
            'name': conversation.name,
            'description': conversation.description,
            'participants': conversation.participants,
            'type': conversation.type.name,
          },
          timestamp: conversation.updatedAt,
        ));

        print(
            '📥 [StorageOrchestrator] Conversation ${conversation.name} (${conversation.id}) rée-cachée');
      }

      print(
          '📥 [StorageOrchestrator] ${conversations.length} conversations chargées du cache');
    } catch (e) {
      print('❌ [StorageOrchestrator] Erreur sync conversations: $e');
    }
  }

  // ════════════════════════════════════════════════════════════════
  // CONVERSIONS: Event Types ↔ Model Types
  // ════════════════════════════════════════════════════════════════

  MessageType _mapEventTypeToMessageType(String eventType) {
    return MessageType.values.firstWhere(
      (t) => t.name.toUpperCase() == eventType,
      orElse: () => MessageType.text,
    );
  }

  String _mapMessageTypeToEventType(MessageType type) {
    return type.name.toUpperCase();
  }

  MessageStatus _mapEventStatusToMessageStatus(String eventStatus) {
    return MessageStatus.values.firstWhere(
      (s) => s.name == eventStatus,
      orElse: () => MessageStatus.sent,
    );
  }

  List<ParticipantMetadata> _parseUserMetadata(dynamic raw) {
    if (raw is List) {
      return raw
          .whereType<Map>()
          .map((item) =>
              ParticipantMetadata.fromJson(Map<String, dynamic>.from(item)))
          .toList();
    }
    return [];
  }

  ParticipantMetadata? _parseSingleParticipant(dynamic raw) {
    if (raw is Map) {
      return ParticipantMetadata.fromJson(Map<String, dynamic>.from(raw));
    }
    return null;
  }

  ParticipantMetadata _fallbackParticipant(String userId) {
    return ParticipantMetadata(
      userId: userId,
      unreadCount: 0,
      lastReadAt: null,
      isMuted: false,
      isPinned: false,
      customName: null,
      notificationSettings: NotificationSettings(
        enabled: true,
        sound: true,
        vibration: true,
      ),
      nom: '',
      prenom: '',
      avatar: null,
      metadataId: '',
      sexe: null,
      departement: null,
      ministere: null,
    );
  }

  Map<String, int> _parseUnreadCounts(
    dynamic raw, {
    List<ParticipantMetadata>? fallbackFrom,
  }) {
    if (raw is Map) {
      return raw.map(
        (key, value) => MapEntry(
          key.toString(),
          value is int ? value : int.tryParse(value.toString()) ?? 0,
        ),
      );
    }

    if (fallbackFrom != null && fallbackFrom.isNotEmpty) {
      return {
        for (final meta in fallbackFrom) meta.userId: meta.unreadCount,
      };
    }

    return <String, int>{};
  }

  String _mapEventTypeToString(String eventType) {
    // Convertit le type d'événement en string pour LastMessage
    return eventType.toUpperCase();
  }

  // ════════════════════════════════════════════════════════════════
  // CLEANUP
  // ════════════════════════════════════════════════════════════════

  /// Ferme tous les boxes et annule les subscriptions
  Future<void> dispose() async {
    try {
      // Annuler toutes les subscriptions
      for (var subscription in _subscriptions) {
        await subscription.cancel();
      }
      _subscriptions.clear();

      // Les boxes sont gérées par HiveService - pas besoin de les fermer ici
    } catch (e) {
      print('[ERROR] Dispose: $e');
      rethrow;
    }
  }
}
