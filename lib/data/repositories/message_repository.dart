import 'dart:async';
import 'package:ngomna_chat/data/models/message_model.dart';
import 'package:ngomna_chat/data/services/socket_service.dart';
import 'package:ngomna_chat/data/services/api_service.dart';
import 'dart:io';

class MessageRepository {
  final SocketService _socketService;
  final ApiService _apiService;

  // Cache local des messages par conversation
  final Map<String, List<Message>> _messagesCache = {};
  final Map<String, StreamController<List<Message>>> _messageStreams = {};

  // Cache pour les messages en cours d'envoi
  final Map<String, Completer<Message>> _pendingMessages = {};

  MessageRepository({
    required SocketService socketService,
    required ApiService apiService,
  })  : _socketService = socketService,
        _apiService = apiService {
    _setupSocketListeners();
  }

  /// Configurer les listeners Socket.IO
  void _setupSocketListeners() {
    // Nouveaux messages reçus
    _socketService.messageStream.listen(_handleNewMessage);

    // Confirmation d'envoi
    _socketService.messageSentStream.listen(_handleMessageSent);

    // Erreurs d'envoi
    _socketService.messageErrorStream.listen(_handleMessageError);

    // Messages chargés depuis le serveur
    _socketService.messagesLoadedStream.listen(_handleMessagesLoaded);
  }

  /// Récupérer les messages d'une conversation
  /// Utilise Socket.IO pour les messages en temps réel
  Future<List<Message>> getMessages(
    String conversationId, {
    int page = 1,
    int limit = 50,
    bool forceRefresh = false,
  }) async {
    // Vérifier le cache
    if (!forceRefresh && _messagesCache.containsKey(conversationId)) {
      return _messagesCache[conversationId]!;
    }

    // Demander au serveur via Socket.IO
    await _socketService.getMessages(conversationId, page: page, limit: limit);

    // Attendre la réponse via le stream
    final completer = Completer<List<Message>>();
    final subscription = _socketService.messagesLoadedStream.listen((messages) {
      // Filtrer pour cette conversation
      final conversationMessages = messages
          .where((msg) => msg.conversationId == conversationId)
          .toList();

      if (conversationMessages.isNotEmpty) {
        _updateMessagesCache(conversationId, conversationMessages);
        completer.complete(conversationMessages);
      }
    });

    // Timeout après 10 secondes
    Timer(const Duration(seconds: 10), () {
      if (!completer.isCompleted) {
        subscription.cancel();
        completer.completeError(TimeoutException('Timeout loading messages'));
      }
    });

    return completer.future;
  }

  /// Stream des messages pour une conversation (mise à jour temps réel)
  Stream<List<Message>> watchMessages(String conversationId) {
    if (!_messageStreams.containsKey(conversationId)) {
      _messageStreams[conversationId] =
          StreamController<List<Message>>.broadcast();

      // Initialiser avec le cache si disponible
      if (_messagesCache.containsKey(conversationId)) {
        _messageStreams[conversationId]!.add(_messagesCache[conversationId]!);
      }
    }

    return _messageStreams[conversationId]!.stream;
  }

  /// Envoyer un message via Socket.IO
  Future<Message> sendMessage({
    required String conversationId,
    required String content,
    required String senderId,
    MessageType type = MessageType.text,
    String? fileId,
    String? fileName,
    int? fileSize,
    String? mimeType,
    int? duration,
  }) async {
    // Créer le message localement avec statut "sending"
    final message = Message.createNew(
      conversationId: conversationId,
      senderId: senderId,
      content: content,
      type: type,
      fileId: fileId,
      fileName: fileName,
      fileSize: fileSize,
      mimeType: mimeType,
      duration: duration,
    );

    // Ajouter au cache local immédiatement (optimistic update)
    _addMessageToCache(conversationId, message);

    // Créer un Completer pour attendre la confirmation du serveur
    final completer = Completer<Message>();
    _pendingMessages[message.temporaryId!] = completer;

    try {
      // Envoyer via Socket.IO
      await _socketService.sendMessage(message);

      // Attendre la confirmation (timeout après 30 secondes)
      final confirmedMessage = await completer.future.timeout(
        const Duration(seconds: 30),
        onTimeout: () {
          // Timeout - marquer comme échec
          return message.copyWith(status: MessageStatus.failed);
        },
      );

      return confirmedMessage;
    } catch (e) {
      print('❌ Erreur envoi message: $e');

      // Mettre à jour le statut en échec
      final failedMessage = message.copyWith(status: MessageStatus.failed);
      _updateMessageInCache(conversationId, failedMessage);

      rethrow;
    }
  }

  /// Gérer un nouveau message reçu du serveur
  void _handleNewMessage(Message message) {
    final conversationId = message.conversationId;

    // Vérifier si c'est un message qu'on a envoyé (via temporaryId)
    if (message.temporaryId != null &&
        _pendingMessages.containsKey(message.temporaryId)) {
      final completer = _pendingMessages[message.temporaryId!];
      if (!completer!.isCompleted) {
        completer.complete(message);
      }
      _pendingMessages.remove(message.temporaryId);
    }

    // Ajouter au cache et notifier les listeners
    _addMessageToCache(conversationId, message);
  }

  /// Gérer la confirmation d'envoi d'un message
  void _handleMessageSent(MessageSentResponse response) {
    final temporaryId = response.temporaryId;

    // Trouver le message dans le cache via temporaryId
    for (final conversationId in _messagesCache.keys) {
      final messages = _messagesCache[conversationId]!;
      final index =
          messages.indexWhere((msg) => msg.temporaryId == temporaryId);

      if (index != -1) {
        // Mettre à jour avec l'ID permanent et le statut
        final updatedMessage = messages[index].copyWith(
          id: response.messageId,
          status: MessageStatus.sent,
        );

        _messagesCache[conversationId]![index] = updatedMessage;

        // Notifier les listeners
        if (_messageStreams.containsKey(conversationId)) {
          _messageStreams[conversationId]!.add(_messagesCache[conversationId]!);
        }

        // Compléter le Completer si présent
        if (_pendingMessages.containsKey(temporaryId)) {
          final completer = _pendingMessages[temporaryId];
          if (!completer!.isCompleted) {
            completer.complete(updatedMessage);
          }
          _pendingMessages.remove(temporaryId);
        }

        break;
      }
    }
  }

  /// Gérer une erreur d'envoi de message
  void _handleMessageError(MessageErrorResponse error) {
    print('❌ Erreur message: ${error.message} (${error.code})');

    // TODO: Trouver le message correspondant et le marquer comme échec
    // On pourrait utiliser le temporaryId si inclus dans l'erreur
  }

  /// Gérer les messages chargés depuis le serveur
  void _handleMessagesLoaded(List<Message> messages) {
    if (messages.isEmpty) return;

    // Grouper par conversationId
    final groupedMessages = <String, List<Message>>{};
    for (final message in messages) {
      groupedMessages
          .putIfAbsent(message.conversationId, () => [])
          .add(message);
    }

    // Mettre à jour chaque cache de conversation
    for (final entry in groupedMessages.entries) {
      _updateMessagesCache(entry.key, entry.value);
    }
  }

  /// Mettre à jour le cache des messages
  void _updateMessagesCache(String conversationId, List<Message> messages) {
    // Trier par timestamp (plus récent en dernier)
    messages.sort((a, b) => a.timestamp.compareTo(b.timestamp));

    _messagesCache[conversationId] = messages;

    // Notifier les listeners
    if (_messageStreams.containsKey(conversationId)) {
      _messageStreams[conversationId]!.add(messages);
    }
  }

  /// Ajouter un message au cache
  void _addMessageToCache(String conversationId, Message message) {
    final messages = _messagesCache.putIfAbsent(conversationId, () => []);
    messages.add(message);

    // Trier par timestamp
    messages.sort((a, b) => a.timestamp.compareTo(b.timestamp));

    // Notifier les listeners
    if (_messageStreams.containsKey(conversationId)) {
      _messageStreams[conversationId]!.add(messages);
    }
  }

  /// Mettre à jour un message spécifique dans le cache
  void _updateMessageInCache(String conversationId, Message updatedMessage) {
    if (!_messagesCache.containsKey(conversationId)) return;

    final messages = _messagesCache[conversationId]!;
    final index = messages.indexWhere((msg) =>
        msg.id == updatedMessage.id ||
        msg.temporaryId == updatedMessage.temporaryId);

    if (index != -1) {
      messages[index] = updatedMessage;

      // Notifier les listeners
      if (_messageStreams.containsKey(conversationId)) {
        _messageStreams[conversationId]!.add(messages);
      }
    }
  }

  /// Marquer un message comme livré
  Future<void> markMessageDelivered(
      String messageId, String conversationId) async {
    // Mettre à jour localement
    if (_messagesCache.containsKey(conversationId)) {
      final messages = _messagesCache[conversationId]!;
      final index = messages.indexWhere((msg) => msg.id == messageId);

      if (index != -1) {
        final message = messages[index];
        if (message.status.index < MessageStatus.delivered.index) {
          final updatedMessage = message.withStatus(MessageStatus.delivered);
          messages[index] = updatedMessage;

          // Notifier les listeners
          if (_messageStreams.containsKey(conversationId)) {
            _messageStreams[conversationId]!.add(messages);
          }
        }
      }
    }

    // Informer le serveur via Socket.IO
    await _socketService.markMessageDelivered(messageId, conversationId);
  }

  /// Marquer un message comme lu
  Future<void> markMessageRead(String messageId, String conversationId) async {
    // Mettre à jour localement
    if (_messagesCache.containsKey(conversationId)) {
      final messages = _messagesCache[conversationId]!;
      final index = messages.indexWhere((msg) => msg.id == messageId);

      if (index != -1) {
        final message = messages[index];
        if (message.status.index < MessageStatus.read.index) {
          final updatedMessage = message.withStatus(MessageStatus.read);
          messages[index] = updatedMessage;

          // Notifier les listeners
          if (_messageStreams.containsKey(conversationId)) {
            _messageStreams[conversationId]!.add(messages);
          }
        }
      }
    }

    // Informer le serveur via Socket.IO
    await _socketService.markMessageRead(messageId, conversationId);
  }

  /// Marquer tous les messages d'une conversation comme lus
  Future<void> markAllAsRead(String conversationId) async {
    if (!_messagesCache.containsKey(conversationId)) return;

    final messages = _messagesCache[conversationId]!;
    bool updated = false;

    for (int i = 0; i < messages.length; i++) {
      if (messages[i].status.index < MessageStatus.read.index) {
        messages[i] = messages[i].withStatus(MessageStatus.read);
        updated = true;
      }
    }

    if (updated && _messageStreams.containsKey(conversationId)) {
      _messageStreams[conversationId]!.add(messages);
    }
  }

  /// Signaler que l'utilisateur tape
  Future<void> startTyping(String conversationId) async {
    await _socketService.startTyping(conversationId);
  }

  /// Signaler que l'utilisateur arrête de taper
  Future<void> stopTyping(String conversationId) async {
    await _socketService.stopTyping(conversationId);
  }

  /// Uploader un fichier via API HTTP
  Future<Map<String, dynamic>> uploadFile({
    required String filePath,
    required String fileName,
    required String conversationId,
  }) async {
    try {
      final file = File(filePath);

      return await _apiService.uploadFile(
        endpoint: ApiEndpoints.uploadFile,
        file: file,
        fileName: fileName,
        metadata: {
          'conversationId': conversationId,
          'uploadedAt': DateTime.now().toIso8601String(),
        },
      );
    } catch (e) {
      print('❌ Erreur upload fichier: $e');
      rethrow;
    }
  }

  /// Nettoyer les ressources
  void dispose() {
    for (final controller in _messageStreams.values) {
      controller.close();
    }
    _messageStreams.clear();
    _messagesCache.clear();
    _pendingMessages.clear();
  }
}
