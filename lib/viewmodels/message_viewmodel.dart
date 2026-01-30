import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:ngomna_chat/data/models/message_model.dart';
import 'package:ngomna_chat/data/repositories/message_repository.dart';

class MessageViewModel extends ChangeNotifier {
  final MessageRepository _repository;

  // État par conversation
  final Map<String, ConversationState> _conversationStates = {};

  // Messages en cours d'envoi
  final Map<String, Message> _sendingMessages = {};

  // État global
  bool _isLoading = false;
  String? _error;
  String? _successMessage;

  // Typing indicators
  final Map<String, Set<String>> _typingUsers =
      {}; // conversationId -> Set<userId>
  final Map<String, Timer> _typingTimers = {};

  // Getters
  bool get isLoading => _isLoading;
  String? get error => _error;
  String? get successMessage => _successMessage;

  MessageViewModel(this._repository) {
    _setupTypingCleanup();
  }

  /// Récupérer l'état d'une conversation
  ConversationState? getConversationState(String conversationId) {
    return _conversationStates[conversationId];
  }

  /// Récupérer les messages d'une conversation
  List<Message> getMessages(String conversationId) {
    return _conversationStates[conversationId]?.messages ?? [];
  }

  /// Récupérer les utilisateurs en train d'écrire
  Set<String> getTypingUsers(String conversationId) {
    return _typingUsers[conversationId] ?? {};
  }

  /// Charger les messages d'une conversation
  Future<void> loadMessages(String conversationId,
      {bool forceRefresh = false}) async {
    if (!_conversationStates.containsKey(conversationId)) {
      _conversationStates[conversationId] = ConversationState(
        conversationId: conversationId,
        isLoading: true,
        hasError: false,
        errorMessage: null,
        messages: [],
        hasMore: true,
        page: 1,
        isRefreshing: false,
      );
    }

    final state = _conversationStates[conversationId]!;

    // Éviter les chargements multiples
    if (state.isLoading && !forceRefresh) return;

    if (forceRefresh) {
      state.isRefreshing = true;
      state.page = 1;
      state.hasMore = true;
    } else {
      state.isLoading = true;
    }

    state.hasError = false;
    state.errorMessage = null;
    notifyListeners();

    try {
      final messages = await _repository.getMessages(
        conversationId,
        page: state.page,
        limit: 50,
        forceRefresh: forceRefresh,
      );

      if (forceRefresh || state.page == 1) {
        state.messages = messages;
      } else {
        state.messages = [...state.messages, ...messages];
      }

      state.hasMore = messages.length ==
          50; // Si on a reçu le maximum, il y a peut-être plus
      state.page += 1;

      // S'abonner aux mises à jour temps réel
      _subscribeToConversation(conversationId);
    } catch (e) {
      state.hasError = true;
      state.errorMessage = e.toString();
      print('❌ Erreur chargement messages: $e');
    } finally {
      state.isLoading = false;
      state.isRefreshing = false;
      notifyListeners();
    }
  }

  /// S'abonner aux mises à jour d'une conversation
  void _subscribeToConversation(String conversationId) {
    // Écouter les nouveaux messages
    _repository.watchMessages(conversationId).listen((messages) {
      final state = _conversationStates[conversationId];
      if (state != null) {
        state.messages = messages;
        notifyListeners();
      }
    });
  }

  /// Envoyer un message texte
  Future<Message?> sendTextMessage({
    required String conversationId,
    required String content,
    required String senderId,
  }) async {
    if (content.trim().isEmpty) return null;

    // Créer le message localement (optimistic update)
    final message = Message.createNew(
      conversationId: conversationId,
      senderId: senderId,
      content: content.trim(),
      type: MessageType.text,
    );

    // Ajouter à l'état local immédiatement
    _addMessageToState(conversationId, message);

    // Enregistrer comme message en cours d'envoi
    _sendingMessages[message.temporaryId!] = message;

    try {
      // Envoyer via le repository
      final sentMessage = await _repository.sendMessage(
        conversationId: conversationId,
        content: content.trim(),
        senderId: senderId,
        type: MessageType.text,
      );

      // Remplacer le message temporaire par la version confirmée
      _replaceTemporaryMessage(
          conversationId, message.temporaryId!, sentMessage);

      // Retirer de la liste d'envoi
      _sendingMessages.remove(message.temporaryId);

      return sentMessage;
    } catch (e) {
      print('❌ Erreur envoi message: $e');

      // Marquer comme échec
      final failedMessage = message.copyWith(status: MessageStatus.failed);
      _updateMessageInState(conversationId, failedMessage);

      // Retirer de la liste d'envoi
      _sendingMessages.remove(message.temporaryId);

      _error = 'Échec d\'envoi du message';
      notifyListeners();

      return null;
    }
  }

  /// Envoyer un message avec fichier
  Future<Message?> sendFileMessage({
    required String conversationId,
    required String content,
    required String senderId,
    required String fileId,
    required String fileName,
    required int fileSize,
    required String mimeType,
    int? duration,
  }) async {
    final message = Message.createNew(
      conversationId: conversationId,
      senderId: senderId,
      content: content,
      type: _getMessageTypeFromMime(mimeType),
      fileId: fileId,
      fileName: fileName,
      fileSize: fileSize,
      mimeType: mimeType,
      duration: duration,
    );

    _addMessageToState(conversationId, message);
    _sendingMessages[message.temporaryId!] = message;

    try {
      final sentMessage = await _repository.sendMessage(
        conversationId: conversationId,
        content: content,
        senderId: senderId,
        type: _getMessageTypeFromMime(mimeType),
        fileId: fileId,
        fileName: fileName,
        fileSize: fileSize,
        mimeType: mimeType,
        duration: duration,
      );

      _replaceTemporaryMessage(
          conversationId, message.temporaryId!, sentMessage);
      _sendingMessages.remove(message.temporaryId);

      return sentMessage;
    } catch (e) {
      print('❌ Erreur envoi fichier: $e');

      final failedMessage = message.copyWith(status: MessageStatus.failed);
      _updateMessageInState(conversationId, failedMessage);
      _sendingMessages.remove(message.temporaryId);

      _error = 'Échec d\'envoi du fichier';
      notifyListeners();

      return null;
    }
  }

  /// Ajouter un message à l'état local
  void _addMessageToState(String conversationId, Message message) {
    if (!_conversationStates.containsKey(conversationId)) {
      _conversationStates[conversationId] = ConversationState(
        conversationId: conversationId,
        isLoading: false,
        hasError: false,
        errorMessage: null,
        messages: [],
        hasMore: true,
        page: 1,
        isRefreshing: false,
      );
    }

    final state = _conversationStates[conversationId]!;
    state.messages = [...state.messages, message];

    // Trier par timestamp
    state.messages.sort((a, b) => a.timestamp.compareTo(b.timestamp));

    notifyListeners();
  }

  /// Remplacer un message temporaire par la version confirmée
  void _replaceTemporaryMessage(
      String conversationId, String temporaryId, Message confirmedMessage) {
    final state = _conversationStates[conversationId];
    if (state == null) return;

    final index =
        state.messages.indexWhere((msg) => msg.temporaryId == temporaryId);
    if (index != -1) {
      state.messages[index] = confirmedMessage;
      notifyListeners();
    }
  }

  /// Mettre à jour un message dans l'état local
  void _updateMessageInState(String conversationId, Message updatedMessage) {
    final state = _conversationStates[conversationId];
    if (state == null) return;

    final index = state.messages.indexWhere((msg) =>
        msg.id == updatedMessage.id ||
        msg.temporaryId == updatedMessage.temporaryId);

    if (index != -1) {
      state.messages[index] = updatedMessage;
      notifyListeners();
    }
  }

  /// Marquer un message comme livré
  Future<void> markMessageDelivered(
      String conversationId, String messageId) async {
    try {
      await _repository.markMessageDelivered(messageId, conversationId);

      // Mettre à jour localement
      final state = _conversationStates[conversationId];
      if (state != null) {
        final index = state.messages.indexWhere((msg) => msg.id == messageId);
        if (index != -1) {
          final message = state.messages[index];
          if (message.status.index < MessageStatus.delivered.index) {
            state.messages[index] = message.markAsDelivered('');
            notifyListeners();
          }
        }
      }
    } catch (e) {
      print('❌ Erreur marquage livré: $e');
    }
  }

  /// Marquer un message comme lu
  Future<void> markMessageRead(String conversationId, String messageId) async {
    try {
      await _repository.markMessageRead(messageId, conversationId);

      // Mettre à jour localement
      final state = _conversationStates[conversationId];
      if (state != null) {
        final index = state.messages.indexWhere((msg) => msg.id == messageId);
        if (index != -1) {
          final message = state.messages[index];
          if (message.status.index < MessageStatus.read.index) {
            state.messages[index] = message.markAsRead('');
            notifyListeners();
          }
        }
      }
    } catch (e) {
      print('❌ Erreur marquage lu: $e');
    }
  }

  /// Marquer tous les messages d'une conversation comme lus
  Future<void> markAllAsRead(String conversationId) async {
    try {
      await _repository.markAllAsRead(conversationId);

      // Mettre à jour localement
      final state = _conversationStates[conversationId];
      if (state != null) {
        bool updated = false;
        for (int i = 0; i < state.messages.length; i++) {
          if (state.messages[i].status.index < MessageStatus.read.index) {
            state.messages[i] =
                state.messages[i].withStatus(MessageStatus.read);
            updated = true;
          }
        }

        if (updated) {
          notifyListeners();
        }
      }
    } catch (e) {
      print('❌ Erreur marquage tout lu: $e');
    }
  }

  /// Gestion des typing indicators

  /// Signaler que l'utilisateur commence à écrire
  void startTyping(String conversationId, String userId) {
    _typingUsers.putIfAbsent(conversationId, () => {}).add(userId);

    // Annuler le timer précédent
    _typingTimers[conversationId]?.cancel();

    // Informer le serveur
    _repository.startTyping(conversationId);

    notifyListeners();
  }

  /// Signaler que l'utilisateur arrête d'écrire
  void stopTyping(String conversationId, String userId) {
    _typingUsers[conversationId]?.remove(userId);

    // Informer le serveur
    _repository.stopTyping(conversationId);

    // Nettoyer si vide
    if (_typingUsers[conversationId]?.isEmpty ?? true) {
      _typingUsers.remove(conversationId);
    }

    notifyListeners();
  }

  /// Nettoyer automatiquement les typing indicators expirés
  void _setupTypingCleanup() {
    // Toutes les 10 secondes, nettoyer les typing indicators
    Timer.periodic(const Duration(seconds: 10), (timer) {
      bool changed = false;

      for (final conversationId in _typingUsers.keys.toList()) {
        if (_typingUsers[conversationId]!.isEmpty) {
          _typingUsers.remove(conversationId);
          changed = true;
        }
      }

      if (changed) {
        notifyListeners();
      }
    });
  }

  /// Gérer un utilisateur distant qui tape
  void onRemoteUserTyping(String conversationId, String userId) {
    _typingUsers.putIfAbsent(conversationId, () => {}).add(userId);

    // Nettoyer après 3 secondes
    Future.delayed(const Duration(seconds: 3), () {
      _typingUsers[conversationId]?.remove(userId);
      if (_typingUsers[conversationId]?.isEmpty ?? true) {
        _typingUsers.remove(conversationId);
      }
      notifyListeners();
    });

    notifyListeners();
  }

  /// Gérer un utilisateur distant qui arrête de taper
  void onRemoteUserStoppedTyping(String conversationId, String userId) {
    _typingUsers[conversationId]?.remove(userId);
    if (_typingUsers[conversationId]?.isEmpty ?? true) {
      _typingUsers.remove(conversationId);
    }
    notifyListeners();
  }

  /// Uploader un fichier
  Future<Map<String, dynamic>?> uploadFile({
    required String conversationId,
    required String filePath,
    required String fileName,
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final result = await _repository.uploadFile(
        conversationId: conversationId,
        filePath: filePath,
        fileName: fileName,
      );

      _successMessage = 'Fichier uploadé avec succès';
      return result;
    } catch (e) {
      _error = 'Échec de l\'upload du fichier: $e';
      return null;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Effacer les messages d'erreur/succès
  void clearMessages() {
    _error = null;
    _successMessage = null;
    notifyListeners();
  }

  /// Effacer l'état d'une conversation
  void clearConversationState(String conversationId) {
    _conversationStates.remove(conversationId);
    _typingUsers.remove(conversationId);
    _typingTimers[conversationId]?.cancel();
    _typingTimers.remove(conversationId);
  }

  /// Nettoyer toutes les ressources
  void dispose() {
    for (final timer in _typingTimers.values) {
      timer.cancel();
    }
    _typingTimers.clear();
    _conversationStates.clear();
    _typingUsers.clear();
    _sendingMessages.clear();
  }

  /// Helper: déterminer le type de message depuis le MIME type
  MessageType _getMessageTypeFromMime(String mimeType) {
    if (mimeType.startsWith('image/')) {
      return MessageType.image;
    } else if (mimeType.startsWith('audio/')) {
      return MessageType.audio;
    } else if (mimeType.startsWith('video/')) {
      return MessageType.video;
    } else {
      return MessageType.file;
    }
  }
}

/// État d'une conversation
class ConversationState {
  final String conversationId;
  bool isLoading;
  bool hasError;
  String? errorMessage;
  List<Message> messages;
  bool hasMore;
  int page;
  bool isRefreshing;

  ConversationState({
    required this.conversationId,
    required this.isLoading,
    required this.hasError,
    required this.errorMessage,
    required this.messages,
    required this.hasMore,
    required this.page,
    required this.isRefreshing,
  });
}
