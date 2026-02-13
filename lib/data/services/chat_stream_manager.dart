import 'dart:async';

/// Source de l'événement pour éviter les boucles infinies
enum EventSource {
  socket, // Provient du serveur via Socket
  orchestration, // Généré par l'orchestrateur interne
  storage, // Provient de la synchronisation Hive
  ui, // Émis par l'interface
}

/// Événement message unifié (privé, groupe, canal)
class MessageEvent {
  final String messageId;
  final String conversationId;
  final String senderId;
  final String? senderName;
  final String content;
  final String type; // "TEXT", "IMAGE", "FILE", "AUDIO", "VIDEO", etc.
  final String? subType; // Pour les messages système dans groupes
  final String status; // "sent", "delivered", "read"
  final DateTime timestamp;
  final Map<String, dynamic> metadata;
  final String context; // "private", "group", "channel"
  final EventSource source; // ← NOUVEAU: source de l'événement
  final bool isOrchestrated; // ← NOUVEAU: marqueur pour événements internes

  MessageEvent({
    required this.messageId,
    required this.conversationId,
    required this.senderId,
    this.senderName,
    required this.content,
    required this.type,
    this.subType,
    required this.status,
    required this.timestamp,
    required this.metadata,
    required this.context,
    this.source = EventSource.socket,
    this.isOrchestrated = false,
  });

  factory MessageEvent.fromJson(Map<String, dynamic> json, String context,
      {EventSource source = EventSource.socket}) {
    return MessageEvent(
      messageId: json['messageId'] ?? '',
      conversationId: json['conversationId'] ?? '',
      senderId: json['senderId'] ?? '',
      senderName: json['senderName'],
      content: json['content'] ?? '',
      type: json['type'] ?? 'TEXT',
      subType: json['subType'],
      status: json['status'] ?? 'sent',
      timestamp:
          DateTime.parse(json['timestamp'] ?? DateTime.now().toIso8601String()),
      metadata: json['metadata'] ?? {},
      context: context,
      source: source,
      isOrchestrated: json['isOrchestrated'] ?? false,
    );
  }
}

/// Événement changement de statut message
class MessageStatusEvent {
  final String messageId;
  final String userId;
  final String status; // "delivered", "read"
  final DateTime timestamp;
  final String? conversationId; // ID de la conversation (optionnel)

  MessageStatusEvent({
    required this.messageId,
    required this.userId,
    required this.status,
    required this.timestamp,
    this.conversationId,
  });

  factory MessageStatusEvent.fromJson(Map<String, dynamic> json) {
    return MessageStatusEvent(
      messageId: json['messageId'] ?? '',
      userId: json['userId'] ?? '',
      status: json['status'] ?? '',
      timestamp:
          DateTime.parse(json['timestamp'] ?? DateTime.now().toIso8601String()),
      conversationId: json['conversationId'] as String?,
    );
  }
}

/// Événement typing/frappe
class TypingEvent {
  final String conversationId;
  final String userId;
  final bool isTyping;
  final DateTime timestamp;

  TypingEvent({
    required this.conversationId,
    required this.userId,
    required this.isTyping,
    required this.timestamp,
  });

  factory TypingEvent.fromJson(Map<String, dynamic> json) {
    return TypingEvent(
      conversationId: json['conversationId'] ?? '',
      userId: json['userId'] ?? '',
      isTyping: json['isTyping'] ?? false,
      timestamp:
          DateTime.parse(json['timestamp'] ?? DateTime.now().toIso8601String()),
    );
  }
}

/// Événement conversation unifié
class ConversationEvent {
  final String conversationId;
  final String
      event; // "created", "updated", "participant_added", "participant_removed", "deleted"
  final String? userId;
  final Map<String, dynamic> data;
  final DateTime timestamp;

  ConversationEvent({
    required this.conversationId,
    required this.event,
    this.userId,
    required this.data,
    required this.timestamp,
  });

  factory ConversationEvent.fromJson(Map<String, dynamic> json) {
    DateTime timestamp;
    final timestampValue = json['timestamp'];

    if (timestampValue is int) {
      // Timestamp en millisecondes
      timestamp = DateTime.fromMillisecondsSinceEpoch(timestampValue);
    } else if (timestampValue is String) {
      // Format ISO 8601
      try {
        timestamp = DateTime.parse(timestampValue);
      } catch (e) {
        timestamp = DateTime.now();
      }
    } else {
      timestamp = DateTime.now();
    }

    return ConversationEvent(
      conversationId: json['conversationId'] ?? '',
      event: json['event'] ?? '',
      userId: json['userId'],
      data: json['data'] ?? {},
      timestamp: timestamp,
    );
  }
}

/// Événement fichier
class FileEvent {
  final String fileId;
  final String event; // "uploaded", "downloaded", "deleted"
  final String fileName;
  final int fileSize;
  final DateTime timestamp;

  FileEvent({
    required this.fileId,
    required this.event,
    required this.fileName,
    required this.fileSize,
    required this.timestamp,
  });

  factory FileEvent.fromJson(Map<String, dynamic> json) {
    return FileEvent(
      fileId: json['fileId'] ?? '',
      event: json['event'] ?? '',
      fileName: json['fileName'] ?? '',
      fileSize: json['fileSize'] ?? 0,
      timestamp:
          DateTime.parse(json['timestamp'] ?? DateTime.now().toIso8601String()),
    );
  }
}

/// Événement interaction message (réaction, réponse)
class MessageInteractionEvent {
  final String messageId;
  final String userId;
  final String type; // "reaction", "reply"
  final Map<String, dynamic>
      data; // {reaction: "👍", action: "add"} ou {content: "..."}
  final DateTime timestamp;

  MessageInteractionEvent({
    required this.messageId,
    required this.userId,
    required this.type,
    required this.data,
    required this.timestamp,
  });

  factory MessageInteractionEvent.fromJson(Map<String, dynamic> json) {
    return MessageInteractionEvent(
      messageId: json['messageId'] ?? '',
      userId: json['userId'] ?? '',
      type: json['type'] ?? '',
      data: json['data'] ?? {},
      timestamp:
          DateTime.parse(json['timestamp'] ?? DateTime.now().toIso8601String()),
    );
  }
}

/// État de connexion
enum ConnectionState {
  disconnected,
  connecting,
  connected,
  authenticated,
  error,
}

/// Gestionnaire centralisé des streams Socket.IO
/// Aligné 1:1 avec la structure serveur
/// Inclut un orchestrateur pour gérer les dépendances entre streams
class ChatStreamManager {
  // 1. Messages (unifié: newMessage, message:group, message:channel)
  final _messageStreamController = StreamController<MessageEvent>.broadcast();
  Stream<MessageEvent> get messageStream => _messageStreamController.stream;

  // 2. Message Status (message:status, messageStatusChanged)
  final _messageStatusStreamController =
      StreamController<MessageStatusEvent>.broadcast();
  Stream<MessageStatusEvent> get messageStatusStream =>
      _messageStatusStreamController.stream;

  // 3. Typing (typing:event, userTyping, userStoppedTyping)
  final _typingStreamController = StreamController<TypingEvent>.broadcast();
  Stream<TypingEvent> get typingStream => _typingStreamController.stream;

  // 4. Conversation Events (conversation:event + spécifiques)
  final _conversationStreamController =
      StreamController<ConversationEvent>.broadcast();
  Stream<ConversationEvent> get conversationStream =>
      _conversationStreamController.stream;

  // 5. File Events
  final _fileStreamController = StreamController<FileEvent>.broadcast();
  Stream<FileEvent> get fileStream => _fileStreamController.stream;

  // 6. Message Interactions (reactions, replies)
  final _messageInteractionStreamController =
      StreamController<MessageInteractionEvent>.broadcast();
  Stream<MessageInteractionEvent> get messageInteractionStream =>
      _messageInteractionStreamController.stream;

  // 7. Connexion (interne au client)
  final _connectionStreamController =
      StreamController<ConnectionState>.broadcast();
  Stream<ConnectionState> get connectionStream =>
      _connectionStreamController.stream;

  // Subscriptions pour l'orchestration des dépendances
  final List<StreamSubscription> _orchestrationSubscriptions = [];

  // Constructeur - initialise l'orchestration des dépendances
  ChatStreamManager() {
    _setupStreamOrchestration();
  }

  /// Configure les dépendances entre streams de manière centralisée
  /// Pattern: Source unique → Transformations explicites
  void _setupStreamOrchestration() {
    // ════════════════════════════════════════════════════════════════
    // DÉPENDANCE 1: Message Status → Message Update (CRITIQUE)
    // Quand un message change de status (delivered, read), émettre
    // un événement de mise à jour pour notifier les UI
    // ════════════════════════════════════════════════════════════════
    _orchestrationSubscriptions.add(
      _messageStatusStreamController.stream.listen((statusEvent) {
        print(
            '🔄 [Orchestrator] Status change detected: ${statusEvent.messageId} -> ${statusEvent.status}');

        // Émettre un événement de message mis à jour
        // Les repositories/ViewModels peuvent écouter ce stream pour MAJ leur cache
        emitMessage(MessageEvent(
          messageId: statusEvent.messageId,
          conversationId: '', // Sera rempli par le repository
          senderId: statusEvent.userId,
          content: '',
          type: 'STATUS_UPDATE', // Type spécial pour indiquer une MAJ de status
          status: statusEvent.status,
          timestamp: statusEvent.timestamp,
          metadata: {'statusChange': true},
          context: 'status_update',
        ));
      }),
    );

    // ════════════════════════════════════════════════════════════════
    // DÉPENDANCE 2: Conversation Deleted → Clear Messages (IMPORTANT)
    // Quand une conversation est supprimée, notifier les messages
    // pour qu'ils nettoient leur cache
    // ════════════════════════════════════════════════════════════════
    _orchestrationSubscriptions.add(
      _conversationStreamController.stream.listen((convEvent) {
        if (convEvent.event == 'deleted') {
          print(
              '🗑️ [Orchestrator] Conversation deleted: ${convEvent.conversationId}');

          // Émettre un événement spécial pour nettoyer les messages
          emitMessage(MessageEvent(
            messageId:
                'conversation_deleted_${DateTime.now().millisecondsSinceEpoch}',
            conversationId: convEvent.conversationId,
            senderId: 'system',
            content: '',
            type: 'CONVERSATION_DELETED',
            status: 'system',
            timestamp: convEvent.timestamp,
            metadata: {'action': 'clear_cache'},
            context: 'system',
          ));

          // Nettoyer aussi les indicateurs de frappe
          emitTyping(TypingEvent(
            conversationId: convEvent.conversationId,
            userId: 'system',
            isTyping: false,
            timestamp: convEvent.timestamp,
          ));
        }

        // ════════════════════════════════════════════════════════════════
        // DÉPENDANCE 3: Participant Removed → Message Visibility (IMPORTANT)
        // Quand un utilisateur est retiré, marquer les messages comme inaccessibles
        // ════════════════════════════════════════════════════════════════
        if (convEvent.event == 'participant_removed') {
          print(
              '👤 [Orchestrator] Participant removed: ${convEvent.userId} from ${convEvent.conversationId}');

          // Émettre un événement de restriction d'accès
          emitMessage(MessageEvent(
            messageId:
                'participant_removed_${DateTime.now().millisecondsSinceEpoch}',
            conversationId: convEvent.conversationId,
            senderId: 'system',
            content: '',
            type: 'PARTICIPANT_REMOVED',
            status: 'system',
            timestamp: convEvent.timestamp,
            metadata: {
              'action': 'restrict_access',
              'removedUserId': convEvent.userId,
            },
            context: 'system',
          ));
        }

        // ════════════════════════════════════════════════════════════════
        // DÉPENDANCE 4: Conversation Updated → Refresh Messages
        // Quand les métadonnées de conversation changent (nom, photo, etc.)
        // ════════════════════════════════════════════════════════════════
        if (convEvent.event == 'updated') {
          print(
              '🔄 [Orchestrator] Conversation updated: ${convEvent.conversationId}');

          // Les messages peuvent avoir besoin de refraîchir leur affichage
          // (ex: nouveau nom de groupe dans l'en-tête)
          emitMessage(MessageEvent(
            messageId:
                'conversation_updated_${DateTime.now().millisecondsSinceEpoch}',
            conversationId: convEvent.conversationId,
            senderId: 'system',
            content: '',
            type: 'CONVERSATION_UPDATED',
            status: 'system',
            timestamp: convEvent.timestamp,
            metadata: convEvent.data,
            context: 'system',
          ));
        }
      }),
    );

    // ════════════════════════════════════════════════════════════════
    // DÉPENDANCE 5: File Event → Message Update (IMPORTANT)
    // Quand un fichier est uploadé avec succès, ajouter le message correspondant
    // ════════════════════════════════════════════════════════════════
    _orchestrationSubscriptions.add(
      _fileStreamController.stream.listen((fileEvent) {
        if (fileEvent.event == 'uploaded') {
          print(
              '📎 [Orchestrator] File uploaded successfully: ${fileEvent.fileId}');

          // Émettre un message de type fichier
          emitMessage(MessageEvent(
            messageId: 'file_${fileEvent.fileId}',
            conversationId: '', // Sera rempli depuis le contexte d'upload
            senderId: '', // Sera rempli depuis le contexte d'upload
            content: fileEvent.fileName,
            type: 'FILE',
            status: 'sent',
            timestamp: fileEvent.timestamp,
            metadata: {
              'fileId': fileEvent.fileId,
              'fileName': fileEvent.fileName,
              'fileSize': fileEvent.fileSize,
            },
            context: 'file',
          ));
        }
      }),
    );

    // ════════════════════════════════════════════════════════════════
    // DÉPENDANCE 6: Message Interaction → Message Update
    // Quand une réaction/réponse est ajoutée, mettre à jour le message
    // ════════════════════════════════════════════════════════════════
    _orchestrationSubscriptions.add(
      _messageInteractionStreamController.stream.listen((interactionEvent) {
        print(
            '⭐ [Orchestrator] Interaction on message: ${interactionEvent.messageId} (${interactionEvent.type})');

        // Notifier que le message a une nouvelle interaction
        emitMessage(MessageEvent(
          messageId: interactionEvent.messageId,
          conversationId: '', // Sera résolu par le repository
          senderId: interactionEvent.userId,
          content: '',
          type: 'MESSAGE_INTERACTION',
          status: 'system',
          timestamp: interactionEvent.timestamp,
          metadata: {
            'interactionType': interactionEvent.type,
            'interactionData': interactionEvent.data,
          },
          context: 'interaction',
        ));
      }),
    );

    print('🎯 [ChatStreamManager] Orchestration des dépendances configurée');
  }

  // Getters pour les controllers
  StreamSink<MessageEvent> get _messageSink => _messageStreamController.sink;
  StreamSink<MessageStatusEvent> get _messageStatusSink =>
      _messageStatusStreamController.sink;
  StreamSink<TypingEvent> get _typingSink => _typingStreamController.sink;
  StreamSink<ConversationEvent> get _conversationSink =>
      _conversationStreamController.sink;
  StreamSink<FileEvent> get _fileSink => _fileStreamController.sink;
  StreamSink<MessageInteractionEvent> get _messageInteractionSink =>
      _messageInteractionStreamController.sink;
  StreamSink<ConnectionState> get _connectionSink =>
      _connectionStreamController.sink;

  // Méthodes d'émission
  void emitMessage(MessageEvent event) {
    print(
        '📨 [ChatStreamManager] Message émis: ${event.messageId} (${event.context})');
    _messageSink.add(event);
  }

  void emitMessageStatus(MessageStatusEvent event) {
    print(
        '📊 [ChatStreamManager] Statut message émis: ${event.messageId} -> ${event.status}');
    _messageStatusSink.add(event);
  }

  void emitTyping(TypingEvent event) {
    print(
        '⌨️ [ChatStreamManager] Typing émis: ${event.conversationId} (${event.isTyping})');
    _typingSink.add(event);
  }

  void emitConversation(ConversationEvent event) {
    print(
        '💬 [ChatStreamManager] Événement conversation émis: ${event.conversationId} (${event.event})');
    _conversationSink.add(event);
  }

  void emitFile(FileEvent event) {
    print('📁 [ChatStreamManager] Événement fichier émis: ${event.fileId}');
    _fileSink.add(event);
  }

  void emitMessageInteraction(MessageInteractionEvent event) {
    print(
        '⭐ [ChatStreamManager] Interaction message émise: ${event.messageId} (${event.type})');
    _messageInteractionSink.add(event);
  }

  void emitConnection(ConnectionState state) {
    print('🔌 [ChatStreamManager] État connexion: $state');
    _connectionSink.add(state);
  }

  // Fermeture des ressources
  void dispose() {
    // Annuler toutes les subscriptions d'orchestration en premier
    for (var subscription in _orchestrationSubscriptions) {
      subscription.cancel();
    }
    _orchestrationSubscriptions.clear();

    // Fermer tous les streams
    _messageStreamController.close();
    _messageStatusStreamController.close();
    _typingStreamController.close();
    _conversationStreamController.close();
    _fileStreamController.close();
    _messageInteractionStreamController.close();
    _connectionStreamController.close();
    print('🧹 ChatStreamManager fermé (orchestration + streams)');
  }
}
