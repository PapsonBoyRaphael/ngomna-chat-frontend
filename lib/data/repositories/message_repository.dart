import 'dart:async';
import 'dart:math';
import 'package:ngomna_chat/data/models/message_model.dart';
import 'package:ngomna_chat/data/services/socket_service.dart';
import 'package:ngomna_chat/data/services/api_service.dart';
import 'package:ngomna_chat/data/services/hive_service.dart';
import 'package:ngomna_chat/data/services/storage_service.dart';
import 'dart:io';

class MessageRepository {
  static MessageRepository? _instance;

  final SocketService _socketService;
  final ApiService _apiService;
  final HiveService _hiveService;

  SocketService get socketService => _socketService;

  // Cache local des messages par conversation
  final Map<String, List<Message>> _messagesCache = {};
  final Map<String, StreamController<List<Message>>> _messageStreams = {};

  // Cache pour les messages en cours d'envoi
  final Map<String, Completer<Message>> _pendingMessages = {};

  // Typing stream
  final _typingController = StreamController<String>.broadcast();
  Stream<String> get typingStream => _typingController.stream;

  bool _isMessageFromMe(Message message) {
    final user = StorageService().getUser();
    print('🔍 [MessageRepository._isMessageFromMe] Vérification message:');
    print('   - User trouvé: ${user != null}');
    if (user != null) {
      print('   - User matricule: "${user.matricule}"');
      print('   - User id: "${user.id}"');
    }
    print('   - Message senderId: "${message.senderId}"');
    print('   - Message senderMatricule: "${message.senderMatricule}"');
    print('   - Message isMe (avant): ${message.isMe}');
    print('   - Message temporaryId: ${message.temporaryId}');

    if (user == null) {
      print('   ❌ Utilisateur non trouvé!');
      return false;
    }

    // Le backend envoie le matricule comme senderId
    print(
        '   → Vérification: senderId "${message.senderId}" == matricule "${user.matricule}" ? ${message.senderId == user.matricule}');
    if (message.senderId.isNotEmpty && message.senderId == user.matricule) {
      print('   ✅ MATCH: senderId == matricule');
      return true;
    }

    // Fallback au senderMatricule
    print(
        '   → Vérification: senderMatricule "${message.senderMatricule}" == matricule "${user.matricule}" ? ${message.senderMatricule == user.matricule}');
    if (message.senderMatricule != null &&
        message.senderMatricule!.isNotEmpty &&
        message.senderMatricule == user.matricule) {
      print('   ✅ MATCH: senderMatricule == matricule');
      return true;
    }

    // Fallback à l'ID utilisateur

    if (message.senderId.isNotEmpty && message.senderId == user.id) {
      print('   ✅ MATCH: senderId == id');
      return true;
    }

    return false;
  }

  factory MessageRepository({
    required SocketService socketService,
    required ApiService apiService,
    required HiveService hiveService,
  }) {
    _instance ??= MessageRepository._internal(
      socketService: socketService,
      apiService: apiService,
      hiveService: hiveService,
    );
    return _instance!;
  }

  MessageRepository._internal({
    required SocketService socketService,
    required ApiService apiService,
    required HiveService hiveService,
  })  : _socketService = socketService,
        _apiService = apiService,
        _hiveService = hiveService {
    _setupSocketListeners();
  }

  /// Configurer les listeners Socket.IO
  void _setupSocketListeners() {
    // Nouveaux messages reçus
    _socketService.newMessageStream.listen(_handleNewMessage);

    // Confirmation d'envoi
    _socketService.messageSentStream.listen(_handleMessageSent);

    // Erreurs d'envoi
    _socketService.messageErrorStream.listen(_handleMessageError);

    // Messages chargés depuis le serveur
    _socketService.messagesLoadedStream.listen(_handleMessagesLoaded);

    // Typing
    _socketService.userTypingStream.listen((convId) {
      _typingController.add(convId);
    });
  }

  /// Récupérer les messages d'une conversation
  /// Vérifie d'abord Hive, si vide émet getMessages via Socket.IO
  Future<List<Message>> getMessages(
    String conversationId, {
    int page = 1,
    int limit = 50,
    bool forceRefresh = false,
  }) async {
    print('📥 [MessageRepository] getMessages appelé pour: $conversationId');

    // Vérifier le cache en mémoire d'abord
    if (!forceRefresh && _messagesCache.containsKey(conversationId)) {
      print(
          '✅ [MessageRepository] Messages trouvés dans le cache mémoire: ${_messagesCache[conversationId]!.length}');
      return _messagesCache[conversationId]!;
    }

    // Vérifier Hive pour les messages en cache
    try {
      final cachedMessages = await _hiveService.getMessagesForConversation(
        conversationId,
        limit: limit,
        offset: (page - 1) * limit,
      );

      if (cachedMessages.isNotEmpty && !forceRefresh) {
        print(
            '💾 [MessageRepository] Messages trouvés dans Hive: ${cachedMessages.length}');
        print('📊 [MessageRepository] Contenu Hive AVANT normalisation:');
        for (var i = 0; i < cachedMessages.length; i++) {
          print(
              '   - [$i] id=${cachedMessages[i].id}, isMe=${cachedMessages[i].isMe}, senderId=${cachedMessages[i].senderId}');
        }
        _updateMessagesCache(conversationId, cachedMessages);
        final cacheAfter = _messagesCache[conversationId] ?? [];
        print(
            '📊 [MessageRepository] Contenu Cache APRÈS _updateMessagesCache:');
        for (var i = 0; i < cacheAfter.length; i++) {
          print(
              '   - [$i] id=${cacheAfter[i].id}, isMe=${cacheAfter[i].isMe}, senderId=${cacheAfter[i].senderId}');
        }
        return cacheAfter;
      } else {
        print('⚠️ [MessageRepository] Hive vide pour: $conversationId');
      }
    } catch (e) {
      print('❌ [MessageRepository] Erreur lors de la lecture Hive: $e');
    }

    // Hive vide ou forceRefresh → émettre l'event pour charger depuis le serveur
    print(
        '🌐 [MessageRepository] Émission event getMessages pour: $conversationId');
    await _socketService.getMessages(conversationId, page: page, limit: limit);

    // Retourner une liste vide en attendant que les messages arrivent via le listener
    print('⏳ [MessageRepository] En attente des messages du serveur...');
    return [];
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
    final normalizedMessage = message.copyWith(isMe: _isMessageFromMe(message));

    final conversationId = normalizedMessage.conversationId;

    print('📨 [MessageRepository._handleNewMessage] Nouveau message reçu:');
    print('   - conversationId: $conversationId');
    print('   - messageId: ${normalizedMessage.id}');
    print('   - senderId: ${normalizedMessage.senderId}');
    print('   - isMe (normalisé): ${normalizedMessage.isMe}');
    print(
        '   - content: ${normalizedMessage.content.substring(0, min(50, normalizedMessage.content.length))}...');

    // Vérifier si c'est un message qu'on a envoyé (via temporaryId)
    if (normalizedMessage.temporaryId != null &&
        _pendingMessages.containsKey(normalizedMessage.temporaryId)) {
      final completer = _pendingMessages[normalizedMessage.temporaryId!];
      if (!completer!.isCompleted) {
        completer.complete(normalizedMessage);
      }
      _pendingMessages.remove(normalizedMessage.temporaryId);
    }

    // Ajouter au cache et notifier les listeners
    _addMessageToCache(conversationId, normalizedMessage);

    // Marquer comme lu si ce n'est pas notre propre message
    if (!normalizedMessage.isMe && normalizedMessage.id.isNotEmpty) {
      print(
          '👁️ [MessageRepository] Marquage message comme read: ${normalizedMessage.id}');
      markMessageRead(normalizedMessage.id, conversationId);
    }
  }

  /// Gérer la confirmation d'envoi d'un message
  void _handleMessageSent(MessageSentResponse response) {
    print('📤 [MessageRepository._handleMessageSent] Confirmation reçue');
    print('   - temporaryId: ${response.temporaryId}');
    print('   - messageId: ${response.messageId}');

    final temporaryId = response.temporaryId;

    // Trouver le message dans le cache via temporaryId
    for (final conversationId in _messagesCache.keys) {
      final messages = _messagesCache[conversationId]!;
      final index =
          messages.indexWhere((msg) => msg.temporaryId == temporaryId);

      if (index != -1) {
        // Mettre à jour avec l'ID permanent et le statut
        print(
            '   ✅ Message trouvé dans le cache pour conversation: $conversationId');
        final updatedMessage = messages[index].copyWith(
          id: response.messageId,
          status: MessageStatus.sent,
          isMe: true,
        );
        print('   - Avant: isMe=${messages[index].isMe}');
        print('   - Après: isMe=${updatedMessage.isMe}');

        _messagesCache[conversationId]![index] = updatedMessage;

        // Sauvegarder dans Hive
        _hiveService.saveMessages(_messagesCache[conversationId]!);

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
  Future<void> _handleMessagesLoaded(List<Message> messages) async {
    print(
        '📨 [MessageRepository] Messages reçus du serveur: ${messages.length}');

    if (messages.isEmpty) {
      print('⚠️ [MessageRepository] Aucun message reçu');
      return;
    }

    // Grouper par conversationId
    final groupedMessages = <String, List<Message>>{};
    for (final message in messages) {
      groupedMessages
          .putIfAbsent(message.conversationId, () => [])
          .add(message);
    }

    print(
        '📊 [MessageRepository] Messages groupés par conversation: ${groupedMessages.keys.length} conversations');

    // Mettre à jour chaque cache de conversation avec merge
    for (final entry in groupedMessages.entries) {
      final convId = entry.key;
      final serverMsgs = entry.value
          .map((msg) => msg.copyWith(isMe: _isMessageFromMe(msg)))
          .toList();

      var localMsgs = _messagesCache[convId] ?? [];

      // Si le cache est vide, utiliser directement les messages du serveur
      if (localMsgs.isEmpty) {
        print(
            '✅ [MessageRepository] Cache vide pour $convId, utilisation directe des messages du serveur (${serverMsgs.length} messages)');
        localMsgs = serverMsgs;
      } else {
        // Merge : update existants, add nouveaux
        print(
            '🔄 [MessageRepository] Merge des messages pour $convId (local: ${localMsgs.length}, serveur: ${serverMsgs.length})');
        for (final serverMsg in serverMsgs) {
          print(
              '🔍 [MessageRepository] Vérification message serveur: id=${serverMsg.id}, temporaryId=${serverMsg.temporaryId}');
          final idx = localMsgs.indexWhere((m) =>
              m.id == serverMsg.id || m.temporaryId == serverMsg.temporaryId);
          if (idx != -1) {
            print(
                '🔄 [MessageRepository] Mise à jour message existant: id=${serverMsg.id}');
            localMsgs[idx] = serverMsg; // update status/id
          } else {
            print(
                '➕ [MessageRepository] Ajout nouveau message: id=${serverMsg.id}');
            localMsgs.add(serverMsg);
          }
        }
      }

      print(
          '💾 [MessageRepository] Sauvegarde de ${localMsgs.length} messages (merged) pour $convId');
      _updateMessagesCache(convId, localMsgs);
      _hiveService.saveMessages(localMsgs);
    }

    print('✅ [MessageRepository] Tous les messages sauvegardés');
  }

  /// Mettre à jour le cache des messages
  void _updateMessagesCache(String conversationId, List<Message> messages) {
    // Trier par timestamp (plus ancien en haut, plus récent en bas)
    messages.sort((a, b) => a.timestamp.compareTo(b.timestamp));

    // 🔧 Appliquer isMe APRÈS le tri mais AVANT la sauvegarde
    final normalizedMessages = messages
        .map(
            (msg) => msg.isMe ? msg : msg.copyWith(isMe: _isMessageFromMe(msg)))
        .toList();

    print(
        '📝 [MessageRepository._updateMessagesCache] AVANT normalisation: ${messages.length} messages');
    for (var i = 0; i < messages.length; i++) {
      print(
          '   - [$i] id=${messages[i].id}, isMe=${messages[i].isMe}, senderId=${messages[i].senderId}');
    }

    print(
        '📝 [MessageRepository._updateMessagesCache] APRÈS normalisation: ${normalizedMessages.length} messages');
    for (var i = 0; i < normalizedMessages.length; i++) {
      print(
          '   - [$i] id=${normalizedMessages[i].id}, isMe=${normalizedMessages[i].isMe}, senderId=${normalizedMessages[i].senderId}');
    }

    _messagesCache[conversationId] = normalizedMessages;

    // Notifier les listeners
    if (_messageStreams.containsKey(conversationId)) {
      _messageStreams[conversationId]!.add(normalizedMessages);
    }
  }

  /// Ajouter un message au cache
  void _addMessageToCache(String conversationId, Message message) {
    final messages = _messagesCache.putIfAbsent(conversationId, () => []);

    messages.add(message);

    // Trier par timestamp
    messages.sort((a, b) => a.timestamp.compareTo(b.timestamp));

    // 💾 Sauvegarder dans Hive
    _hiveService.saveMessages(messages);
    print(
        '💾 [MessageRepository] Message ajouté au cache ET sauvegardé dans Hive: ${message.id}');

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

  /// Vérifier si deux listes de messages sont égales
  bool _areListsEqual(List<Message> a, List<Message> b) {
    if (a.length != b.length) return false;
    for (int i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }

  /// Nettoyer les ressources
  void dispose() {
    for (final controller in _messageStreams.values) {
      controller.close();
    }
    _messageStreams.clear();
    _messagesCache.clear();
    _pendingMessages.clear();
    _typingController.close();
  }
}
